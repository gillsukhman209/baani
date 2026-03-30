#!/usr/bin/env python3
"""
One-time script to fetch all banis from BaniDB and generate
simple English + Punjabi translations via OpenAI GPT-4o-mini.
Outputs a single translations.json to bundle in the app.
"""

import json
import time
import sys
import os
import requests

API_KEY = os.environ.get("OPENAI_API_KEY", "")
BANIDB_BASE = "https://api.banidb.com/v2"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"

# Our curated bani IDs
BANI_IDS = [2, 4, 6, 9, 10, 21, 23, 31, 90, 3, 36, 27, 24]

SYSTEM_PROMPT = """You translate Gurbani lines for young Sikh diaspora users (18-35, Western countries).

Return ONLY a JSON object with two keys, no other text:
{"english": "...", "punjabi": "..."}

For the "english" value:
- Simple, modern English a friend would use
- No theology words like "Personified", "Primal", "Undying", "Immaculate"
- Use: "The Creator", "God", "always existed", "never dies" etc.
- Keep it SHORT — same length as the original line
- Just the translation, no explanations

For the "punjabi" value:
- Modern spoken Punjabi in Gurmukhi script
- The kind of Punjabi a young person in Canada/UK would understand
- Not the archaic Gurbani Punjabi — everyday conversational Punjabi
- Keep it the same length as the English

Examples:
Input: "Creative Being Personified. No Fear. No Hatred."
Output: {"english": "The Creator of everything. Without fear. Without hate.", "punjabi": "ਸਭ ਕੁਝ ਬਣਾਉਣ ਵਾਲਾ। ਬਿਨਾ ਡਰ। ਬਿਨਾ ਨਫ਼ਰਤ।"}

Input: "True In The Primal Beginning. True Throughout The Ages."
Output: {"english": "True since before time began. True through every era.", "punjabi": "ਸਮੇਂ ਤੋਂ ਪਹਿਲਾਂ ਤੋਂ ਸੱਚ। ਹਰ ਯੁੱਗ ਵਿੱਚ ਸੱਚ।"}"""


def fetch_bani(bani_id):
    """Fetch a bani from BaniDB API."""
    url = f"{BANIDB_BASE}/banis/{bani_id}"
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    return resp.json()


def translate_line(scholar_translation, gurmukhi):
    """Call GPT to get simple English + Punjabi translation."""
    if not scholar_translation.strip():
        return None

    user_msg = f"Translate this Gurbani line:\nEnglish (scholarly): {scholar_translation}\nGurmukhi: {gurmukhi}"

    payload = {
        "model": "gpt-4o-mini",
        "max_tokens": 250,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_msg},
        ],
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }

    for attempt in range(3):
        try:
            resp = requests.post(OPENAI_URL, json=payload, headers=headers, timeout=30)
            if resp.status_code == 429:
                wait = 5 * (attempt + 1)
                print(f"    Rate limited, waiting {wait}s...")
                time.sleep(wait)
                continue
            resp.raise_for_status()
            data = resp.json()
            content = data["choices"][0]["message"]["content"].strip()

            # Parse JSON response
            try:
                parsed = json.loads(content)
                return {
                    "english": parsed.get("english", content),
                    "punjabi": parsed.get("punjabi", ""),
                }
            except json.JSONDecodeError:
                # Fallback: treat as English only
                return {"english": content, "punjabi": ""}

        except Exception as e:
            if attempt < 2:
                time.sleep(2)
                continue
            print(f"    FAILED after 3 attempts: {e}")
            return None

    return None


def process_bani(bani_id):
    """Fetch a bani and translate all its lines."""
    print(f"\nFetching bani {bani_id} from BaniDB...")
    data = fetch_bani(bani_id)
    verses = data.get("verses", [])
    print(f"  Got {len(verses)} verses")

    # Build section info
    section_number = 0
    last_paragraph = None
    content_pauri_count = 0
    header_count = 0

    lines = []

    for verse in verses:
        paragraph = verse.get("paragraph", 0) or 0
        header = verse.get("header", 0)
        v = verse.get("verse", {})

        if paragraph != last_paragraph:
            section_number += 1
            last_paragraph = paragraph
            if header == 1:
                header_count += 1
            else:
                content_pauri_count += 1

        if header == 1:
            section_title = "Salutation" if header_count == 1 else ""
        else:
            section_title = f"Pauri {content_pauri_count}"

        verse_id = v.get("verseId", 0)
        verse_text = v.get("verse", {})
        transliteration_obj = v.get("transliteration", {}) or {}
        translation_obj = v.get("translation", {}) or {}
        en_translation = (translation_obj.get("en", {}) or {}).get("bdb", "") or ""
        translit = transliteration_obj.get("en") or transliteration_obj.get("english", "") or ""

        line_data = {
            "verseId": verse_id,
            "baniID": bani_id,
            "lineNo": v.get("lineNo", 0) or 0,
            "gurmukhi": verse_text.get("gurmukhi", ""),
            "unicode": verse_text.get("unicode", ""),
            "transliteration": translit,
            "translation": en_translation,
            "pauriNumber": section_number,
            "sectionTitle": section_title,
            "simpleTranslation": None,
            "punjabiTranslation": None,
        }

        lines.append(line_data)

    # Now translate each line
    total = len(lines)
    for i, line in enumerate(lines):
        scholar = line["translation"]
        if not scholar.strip():
            print(f"  [{i+1}/{total}] Skipping empty translation")
            continue

        print(f"  [{i+1}/{total}] Translating: {line['unicode'][:40]}...")
        result = translate_line(scholar, line["unicode"])
        if result:
            line["simpleTranslation"] = result["english"]
            line["punjabiTranslation"] = result["punjabi"]

        # Small delay between calls
        if i < total - 1:
            time.sleep(0.3)

    return lines


def main():
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "gurbani",
        "BundledTranslations.json",
    )

    # Check for existing progress file
    progress_path = output_path + ".progress"
    all_lines = []
    completed_banis = set()

    if os.path.exists(progress_path):
        with open(progress_path, "r") as f:
            progress = json.load(f)
            all_lines = progress.get("lines", [])
            completed_banis = set(progress.get("completed_banis", []))
            print(f"Resuming from progress file. {len(completed_banis)} banis already done.")

    for bani_id in BANI_IDS:
        if bani_id in completed_banis:
            print(f"\nSkipping bani {bani_id} (already done)")
            continue

        lines = process_bani(bani_id)
        all_lines.extend(lines)
        completed_banis.add(bani_id)

        # Save progress after each bani
        with open(progress_path, "w") as f:
            json.dump({"lines": all_lines, "completed_banis": list(completed_banis)}, f)
        print(f"  Saved progress ({len(all_lines)} total lines)")

    # Write final output
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(all_lines, f, ensure_ascii=False, indent=2)

    # Clean up progress file
    if os.path.exists(progress_path):
        os.remove(progress_path)

    print(f"\nDone! {len(all_lines)} lines written to {output_path}")

    # Stats
    has_simple = sum(1 for l in all_lines if l.get("simpleTranslation"))
    has_punjabi = sum(1 for l in all_lines if l.get("punjabiTranslation"))
    print(f"  Simple English: {has_simple}/{len(all_lines)}")
    print(f"  Punjabi: {has_punjabi}/{len(all_lines)}")


if __name__ == "__main__":
    main()
