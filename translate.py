####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
#
####################################################################################
#
# GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
# tested on a Venu 2 device. The source code is provided at:
#            https://github.com/house-of-abbey/GarminHomeAssistant.
#
# J D Abbey & P A Abbey, 28 December 2022
#
#
# Description:
#
# Python script to automatically translate the strings.xml file to each supported
# language. Rewritten by krzys_h with the help of AI to use Gemini instead of
# Google Translate for more contextual translations.
#
# Requirements:
#   pip install google-genai beautifulsoup4 lxml
#
# Env:
#   export GEMINI_API_KEY="YOUR_API_KEY"
#
# To get your own API key, go to:
# https://aistudio.google.com/app/apikey
#
####################################################################################

import os
import json
from typing import Dict, List, Tuple

from google import genai
from bs4 import BeautifulSoup, Comment

# ---------------- Configuration ----------------

# Gemini model name
MODEL_NAME = "gemini-2.5-flash"

# Language definitions:
#  * Garmin IQ language three-letter mnemonic (used in resources-XXX folder),
#  * Unused Google mnemonic kept for reference,
#  * Human-readable language name for prompts
languages: List[Tuple[str, str, str]] = [
    ("ara", "ar", "Arabic"),
    ("bul", "bg", "Bulgarian"),
    ("zhs", "zh-CN", "Chinese (Simplified)"),
    ("zht", "zh-TW", "Chinese (Traditional)"),
    ("hrv", "hr", "Croatian"),
    ("ces", "cs", "Czech"),
    ("dan", "da", "Danish"),
    ("dut", "nl", "Dutch"),
    ("deu", "de", "German"),
    ("gre", "el", "Greek"),
    # ("eng", "en", "English"),
    ("est", "et", "Estonian"),
    ("fin", "fi", "Finnish"),
    ("fre", "fr", "French"),
    ("heb", "iw", "Hebrew"),
    ("hun", "hu", "Hungarian"),
    ("ind", "id", "Indonesian"),
    ("ita", "it", "Italian"),
    ("jpn", "ja", "Japanese"),
    ("kor", "ko", "Korean"),
    ("lav", "lv", "Latvian"),
    ("lit", "lt", "Lithuanian"),
    ("zsm", "ms", "Standard (Bahasa) Malay"),
    ("nob", "no", "Norwegian"),
    ("pol", "pl", "Polish"),
    ("por", "pt", "Portuguese"),
    ("ron", "ro", "Romanian"),
    # ("rus", "ru", "Russian"),
    ("slo", "sk", "Slovak"),
    ("slv", "sl", "Slovenian"),
    ("spa", "es", "Spanish"),
    ("swe", "sv", "Swedish"),
    ("tha", "th", "Thai"),
    ("tur", "tr", "Turkish"),
    ("ukr", "uk", "Ukrainian"),
    ("vie", "vi", "Vietnamese"),
]

exceptionIds: List[str] = ["AppName", "AppVersionTitle"]

# ---------------- Helpers ----------------

def load_xml_as_soup(path: str) -> BeautifulSoup:
    if not os.path.exists(path):
        return BeautifulSoup("", features="xml")
    with open(path, "r", encoding="utf-8") as f:
        return BeautifulSoup(f.read().replace("\r", ""), features="xml")

def extract_strings(soup: BeautifulSoup) -> Dict[str, str]:
    out = {}
    strings_node = soup.find(name="strings")
    if not strings_node:
        return out
    for s in strings_node.find_all(name="string"):
        sid = s.get("id")
        if not sid:
            continue
        value = s.string if s.string is not None else s.get_text()
        out[sid] = value if value is not None else ""
    return out

def extract_comments_in_order(soup: BeautifulSoup) -> List[str]:
    comments = []
    strings_node = soup.find(name="strings")
    if not strings_node:
        return comments
    for c in strings_node.find_all(string=lambda text: isinstance(text, Comment)):
        comments.append(str(c))
    return comments

def replace_comments_in_order(soup: BeautifulSoup, translated_comments: List[str]) -> None:
    strings_node = soup.find(name="strings")
    if not strings_node:
        return
    idx = 0
    for c in strings_node.find_all(string=lambda text: isinstance(text, Comment)):
        if idx < len(translated_comments):
            c.insert_before("  ")
            c.replace_with(Comment(translated_comments[idx]))
        idx += 1

def build_translation_prompt(
    language_name: str,
    english_full: Dict[str, str],
    existing_translations: Dict[str, str],
    to_translate: Dict[str, str],
    english_comments: List[str],
    existing_translated_comments: List[str],
    generator_comment_en: str,
) -> str:
    return f"""
You are a professional localizer for a smartwatch UI. Translate UI strings into {language_name}.

Rules:
- Preserve placeholders EXACTLY and do not translate them:
  - printf style: %s, %d, %f, %1$s, %2$d, etc.
  - brace placeholders: {{0}}, {{1}}, {{name}}, {{value}}
  - dollar placeholders: $1, $2
- Never translate app/product names; keep them unchanged, e.g., "Home Assistant".
- Do not change punctuation, spacing, or add extra punctuation unless natural in the target language.
- Keep any whitespace at the beginning or end of string unchanged.
- Keep meaning accurate and UI-appropriate (short, natural, consistent).
- Use consistent terminology aligned with existing translations for this language.
- Do NOT translate the string IDs themselves.

Comments handling:
- You are given comments from the English XML (in order) and the current translations (same order where available).
- If a given English comment has not changed since the last revision and a current translation exists at the same index, return the existing translation unchanged.
- If you believe an existing translation is already correct for the provided English, keep it unchanged; otherwise provide an improved translation.
- Also translate the generator comment line shown below. We will store both the English and translated lines inside a single XML comment.

Here are the complete English strings for context:
{json.dumps(english_full, ensure_ascii=False, indent=2)}

Here are existing translations for this language (do not modify these; use for terminology/style consistency):
{json.dumps(existing_translations, ensure_ascii=False, indent=2)}

Here are the ONLY strings that need new translations (translate the values):
{json.dumps(to_translate, ensure_ascii=False, indent=2)}

Comments to translate (same order as in the XML):
{json.dumps(english_comments, ensure_ascii=False, indent=2)}

Existing translated comments (same order; may be fewer items):
{json.dumps(existing_translated_comments, ensure_ascii=False, indent=2)}

Generator comment (English; translate this too):
{json.dumps(generator_comment_en, ensure_ascii=False)}

Return only valid JSON with this exact structure and nothing else (no markdown fences, no prose):
{{
  "translations": {{ "<STRING_ID>": "<translated string>", ... }},
  "translated_comments": ["<translated comment 1>", "<translated comment 2>", ...],
  "generator_comment_translated": "<translated generator comment line>"
}}
- "translations" must have exactly the keys provided in "to_translate".
- "translated_comments" must have the same number of items and order as the input comments list.
- For comments that should remain unchanged based on the rules above, return the existing translation verbatim.
""".strip()

# ---------------- Main translation logic ----------------

def translate_language(
    client: genai.Client,
    lang_tuple: Tuple[str, str, str],
    english_soup: BeautifulSoup,
    english_strings: Dict[str, str],
) -> None:
    garmin_code, _unused, language_name = lang_tuple

    # Ensure output directory exists
    out_dir = f"./resources-{garmin_code}/strings/"
    os.makedirs(out_dir, exist_ok=True)

    # Load previous translations and corrections
    prev_soup = load_xml_as_soup(os.path.join(out_dir, "strings.xml"))
    corrections_soup = load_xml_as_soup(os.path.join(out_dir, "corrections.xml"))

    prev_map = extract_strings(prev_soup)
    corrections_map = extract_strings(corrections_soup)

    # Build a fresh soup for this language from English source
    soup = BeautifulSoup(str(english_soup), features="xml")

    # Collect comments
    english_comments = extract_comments_in_order(english_soup)
    existing_translated_comments = extract_comments_in_order(prev_soup)

    # Detect any mention of Google Translate anywhere in the previous XML
    all_comments_text_prev = [
        str(c) for c in prev_soup.find_all(string=lambda t: isinstance(t, Comment))
    ]
    mentions_google_translate = any("google translate" in c.lower() for c in all_comments_text_prev)

    # Build generator comment English line (the translated line will be returned by the API)
    if mentions_google_translate:
        generator_comment_en = f"Generated by Google Translate and {MODEL_NAME} from English to {language_name}"
    else:
        generator_comment_en = f"Generated by {MODEL_NAME} from English to {language_name}"

    # Decide which strings need translation (not in corrections, not in previous)
    to_translate_map: Dict[str, str] = {}
    final_values: Dict[str, str] = {}

    for s in soup.find_all(name="string"):
        sid = s.get("id")
        if not sid:
            continue
        if sid in exceptionIds:
            # Keep English as-is for exception IDs
            final_values[sid] = s.get_text()
            continue

        if sid in corrections_map and corrections_map[sid] is not None:
            final_values[sid] = corrections_map[sid]
        elif sid in prev_map and prev_map[sid] is not None:
            final_values[sid] = prev_map[sid]
        else:
            to_translate_map[sid] = s.get_text()

    # If there are no new strings to translate, skip this language entirely
    if not to_translate_map:
        print(f"  Skipping {language_name}: no new strings to translate.")
        return

    # Prepare context (always include full English strings)
    english_context = english_strings
    existing_translations = {k: v for k, v in prev_map.items()}
    if corrections_map:
        existing_translations.update(corrections_map)

    # Translate all at once; force JSON output but do not enforce a schema
    prompt = build_translation_prompt(
        language_name=language_name,
        english_full=english_context,
        existing_translations=existing_translations,
        to_translate=to_translate_map,
        english_comments=english_comments,
        existing_translated_comments=existing_translated_comments,
        generator_comment_en=generator_comment_en,
    )

    config = genai.types.GenerateContentConfig(
        temperature=0,
        response_mime_type="application/json",
    )

    resp = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt,
        config=config,
    )

    data = getattr(resp, "parsed", None)
    if data is None:
        txt = getattr(resp, "text", None)
        if not txt:
            try:
                txt = resp.candidates[0].content.parts[0].text
            except Exception:
                txt = ""
        if not txt.strip():
            raise RuntimeError("Empty response from model; cannot parse translations.")
        data = json.loads(txt)

    translations = data.get("translations", {}) or {}
    for sid, translated in translations.items():
        if sid in to_translate_map:
            final_values[sid] = translated

    translated_comments_all: List[str] = data.get("translated_comments", []) or []
    generator_comment_translated: str = data.get("generator_comment_translated", "") or ""

    # Apply final values to the soup
    for s in soup.find_all(name="string"):
        sid = s.get("id")
        if not sid:
            continue
        if sid in final_values:
            val = final_values[sid]
            s.insert_before("  ")
            s.string = val

    # Replace comments with translated versions (order-preserving)
    if translated_comments_all:
        replace_comments_in_order(soup, translated_comments_all)

    # Insert the generator comment (English + translated) before <strings>
    strings_node = soup.find(name="strings")
    if strings_node:
        strings_node.insert_before("\n\n")
        combined = f"\n  {generator_comment_en}\n  {generator_comment_translated}\n"
        strings_node.insert_before(Comment(combined))
        strings_node.insert_before("\n\n")

    # Write output
    out_path = os.path.join(out_dir, "strings.xml")
    with open(out_path, "wb") as w:
        w.write(soup.encode("utf-8") + b"\n")

def main():
    # Init client
    client = genai.Client()

    # Load English source
    src_path = "./resources/strings/strings.xml"
    if not os.path.exists(src_path):
        raise FileNotFoundError(f"Missing source file: {src_path}")

    with open(src_path, "r", encoding="utf-8") as f:
        english_xml = f.read().replace("\r", "")
    english_soup = BeautifulSoup(english_xml, features="xml")
    english_strings = extract_strings(english_soup)

    total_langs = len(languages)
    for i, lang in enumerate(languages, start=1):
        print(f"{i} of {total_langs}: Translating English to {lang[2]}")
        try:
            translate_language(client, lang, english_soup, english_strings)
        except Exception as e:
            print(f"  Error translating {lang[2]}: {e}")

if __name__ == "__main__":
    main()
