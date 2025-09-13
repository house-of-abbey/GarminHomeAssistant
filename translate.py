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
import sys
import re
import json
import argparse
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
    improve_mode: bool,
) -> str:
    if improve_mode:
        existing_header = "Here are previous translations for this language (you may reuse them or improve them; keep unchanged if already correct):"
        items_header = "Here are the strings to review and output FINAL translations for (provide a value for every key; if keeping the existing translation, repeat it verbatim):"
        mode_rules = """
Improve mode rules:
- You are revising existing translations for a smartwatch UI.
- For each string:
  - If the English source text changed in meaning, update the translation accordingly.
  - If the existing translation has grammar or style issues, or you are certain a different translation is a better fit (more natural, concise, and consistent with UI), provide an improved translation.
  - If the existing translation is already accurate, natural, and consistent, you may keep it unchanged by returning the same text.
""".strip()
    else:
        existing_header = "Here are existing translations for this language (do not modify these; use for terminology/style consistency):"
        items_header = "Here are the ONLY strings that need new translations (translate the values):"
        mode_rules = ""

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
{("\n" + mode_rules) if mode_rules else ""}

Comments handling:
- You are given comments from the English XML (in order) and the current translations (same order where available).
- If a given English comment has not changed since the last revision and a current translation exists at the same index, return the existing translation unchanged.
- If you believe an existing translation is already correct for the provided English, keep it unchanged; otherwise provide an improved translation.
- Also translate the generator comment line shown below. We will store both the English and translated lines inside a single XML comment.

Here are the complete English strings for context:
{json.dumps(english_full, ensure_ascii=False, indent=2)}

{existing_header}
{json.dumps(existing_translations, ensure_ascii=False, indent=2)}

{items_header}
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

# ---------------- Language selection helper ----------------

def select_languages_from_arg(spec: str, verbose: bool = False) -> List[Tuple[str, str, str]]:
    """
    Parse a language selection spec and return the list of language tuples to process.

    Accepted selectors (case-insensitive, comma or whitespace separated):
    - Garmin 3-letter codes (e.g., 'deu, fre, spa')
    - 2-letter codes from the tuple (e.g., 'de, fr, es', 'zh-cn', 'zh-tw', 'iw')
    - Language names (e.g., 'German, French, Spanish')
    - '*' or 'all' to select all languages

    Unknown selectors are ignored with a warning.
    """
    if not spec:
        return languages

    tokens = [t for t in re.split(r"[,\s]+", spec.strip()) if t]
    if not tokens:
        return languages

    # If any token is '*' or 'all', select all
    lowered = [t.lower() for t in tokens]
    if any(t in ("*", "all") for t in lowered):
        return languages

    # Build lookup maps
    by_garmin: Dict[str, Tuple[str, str, str]] = {}
    by_google: Dict[str, Tuple[str, str, str]] = {}
    by_name: Dict[str, Tuple[str, str, str]] = {}
    for trip in languages:
        gar, g2, name = trip
        if isinstance(gar, str):
            by_garmin[gar.lower()] = trip
        if isinstance(g2, str):
            by_google[g2.lower()] = trip
        if isinstance(name, str):
            by_name[name.lower()] = trip

    selected_codes = set()
    unknown = []

    for t in lowered:
        t_norm = t.replace("_", "-")
        if t_norm in by_garmin:
            selected_codes.add(by_garmin[t_norm][0].lower())
        elif t_norm in by_google:
            selected_codes.add(by_google[t_norm][0].lower())
        elif t_norm in by_name:
            selected_codes.add(by_name[t_norm][0].lower())
        else:
            unknown.append(t)

    if unknown and verbose:
        print(f"Warning: unknown language selectors ignored: {', '.join(sorted(set(unknown)))}")

    # Preserve original order from 'languages'
    selected = [trip for trip in languages if trip[0].lower() in selected_codes]
    return selected

# ---------------- Main translation logic ----------------

def translate_language(
    client: genai.Client,
    lang_tuple: Tuple[str, str, str],
    english_soup: BeautifulSoup,
    english_strings: Dict[str, str],
    verbose: bool = False,
    improve: bool = False,
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

    # Decide which strings need translation
    to_translate_map: Dict[str, str] = {}
    final_values: Dict[str, str] = {}

    for s in soup.find_all(name="string"):
        sid = s.get("id")
        if not sid:
            continue

        # Always keep English as-is for exception IDs
        if sid in exceptionIds:
            final_values[sid] = s.get_text()
            continue

        # Respect corrections.xml as authoritative
        if sid in corrections_map and corrections_map[sid] is not None:
            final_values[sid] = corrections_map[sid]
            continue

        if improve:
            # Improve mode: reprocess all remaining strings
            to_translate_map[sid] = s.get_text()
        else:
            # Normal mode: translate only new strings
            if sid in prev_map and prev_map[sid] is not None:
                final_values[sid] = prev_map[sid]
            else:
                to_translate_map[sid] = s.get_text()

    # If there are no strings to translate (e.g., all covered by corrections), skip
    if not to_translate_map:
        reason = "no strings to translate (all covered by corrections or exceptions)"
        if not improve:
            reason = "no new strings to translate."
        print(f"  Skipping {language_name}: {reason}")
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
        improve_mode=improve,
    )

    if verbose:
        print(prompt)

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

    if verbose:
        print(data)

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
    parser = argparse.ArgumentParser(description="Translate Garmin IQ strings.xml using Gemini.")
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose debug output (prints prompts and responses)"
    )
    parser.add_argument(
        "-i", "--improve",
        action="store_true",
        help="Improve mode: re-run all strings through translation for potential improvements"
    )
    parser.add_argument(
        "-l", "--langs",
        type=str,
        default=None,
        help="Limit processed languages. Accepts comma/space separated Garmin codes (e.g., 'deu, fre'), "
             "2-letter codes (e.g., 'de fr'), or names (e.g., 'German French'). Use '*' or 'all' for all."
    )
    args = parser.parse_args()

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

    # Determine which languages to process
    selected_languages = select_languages_from_arg(args.langs, verbose=args.verbose)
    if not selected_languages:
        print("No valid languages selected. Nothing to do.")
        sys.exit(0)

    if args.verbose and args.langs:
        pretty = ", ".join([f"{name} ({code})" for code, _g, name in selected_languages])
        print(f"Selected languages: {pretty}")

    total_langs = len(selected_languages)
    for i, lang in enumerate(selected_languages, start=1):
        print(f"{i} of {total_langs}: Translating English to {lang[2]}" + (" [improve]" if args.improve else ""))
        try:
            translate_language(
                client=client,
                lang_tuple=lang,
                english_soup=english_soup,
                english_strings=english_strings,
                verbose=args.verbose,
                improve=args.improve,
            )
        except Exception as e:
            print(f"  Error translating {lang[2]}: {e}")

if __name__ == "__main__":
    main()
