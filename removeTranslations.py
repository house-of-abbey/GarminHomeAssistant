####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
#
####################################################################################
#
# GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
# tested on a Venu 2 device. The source code is provided at:
#            https://github.com/house-of-abbey/GarminHomeAssistant
#
# J D Abbey & P A Abbey, 24 July 2025
#
#
# Description:
#
# Python script to remove all the translations of a specific id from the XML files.
#
# Usage:
#   python removeTranslations.py <id>
#
# Python installation:
#   pip install beautifulsoup4
# NB. For XML formatting:
#   pip install lxml
#
# References:
#  * https://www.crummy.com/software/BeautifulSoup/bs4/doc/
#  * https://realpython.com/beautiful-soup-web-scraper-python/
#  * https://www.crummy.com/software/BeautifulSoup/bs4/doc/#parsing-xml
#  * https://www.crummy.com/software/BeautifulSoup/bs4/doc/#xml
#
####################################################################################
import sys
# from bs4 import BeautifulSoup
import os

def remove_translations(file_path: str, translation_id: str) -> None:
    """
    Remove all translations of a specific id from the XML file.
    
    :param file_path: Path to the XML file.
    :param translation_id: The id of the translation to remove.
    """
    # Breaks the formatting
    # with open(file_path, "r", encoding="utf-8") as file:
    #     soup = BeautifulSoup(file, features="xml")

    # # Find all string elements with the specified id
    # strings_to_remove = soup.find_all("string", {"id": translation_id})

    # for string in strings_to_remove:
    #     string.decompose()  # Remove the string element

    # # Write the modified XML back to the file
    # with open(file_path, "wb") as file:
    #     file.write(soup.encode("utf-8") + b"\n")

    # Use standard string replace instead
    with open(file_path, "r", encoding="utf-8") as file:
        content = file.read()
    
    new = ""
    for line in content.splitlines():
        if not f'id="{translation_id}"' in line:
            new += line + "\n"

    with open(file_path, "w", encoding="utf-8") as file:
        file.write(new)

def main(translation_id: str) -> None:
    """
    Main function to process all XML files.
    
    :param translation_id: The id of the translation to remove.
    """
    xml_files = []
    for directory in os.listdir("."):
        if os.path.isdir(directory) and "resources-" in directory:
            xml_file_path = os.path.join(directory, "strings", "strings.xml")
            if os.path.exists(xml_file_path):
                xml_files.append(xml_file_path)

    for xml_file in xml_files:
        print(f"Processing file: {xml_file}")
        remove_translations(xml_file, translation_id)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python removeTranslations.py <id>")
        sys.exit(1)

    translation_id = sys.argv[1]
    main(translation_id)
