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
# J D Abbey & P A Abbey, 29 December 2023
#
#
# Description:
#
# Python script to automatically resize the application launcher icon from the
# original 70x70 pixel width to something more appropriate for different screen
# sizes.
#
# Python installation:
#   pip install BeautifulSoup
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

from bs4 import BeautifulSoup, Comment
import os
import shutil

output_dir_prefix = 'resources-launcher-'
# Original icons for 416x416 screen size with 70x70 icons
input_dir         = output_dir_prefix + '70-70'

# Convert icons to different screen sizes by these parameters
lookup = [26, 30, 33, 35, 36, 38, 40, 52, 54, 56, 60, 61, 62, 65, 68, 80]

# Delete all but the original 70x70 icon directories
for entry in os.listdir("."):
  if entry.startswith(output_dir_prefix) and entry != input_dir:
    shutil.rmtree(entry)

# (Re-)Create the resized icon directories
for icon_size in lookup:
  output_dir = output_dir_prefix + str(icon_size) + "-" + str(icon_size)
  print("\nCreate directory:", output_dir)
  if os.path.exists(output_dir) and os.path.isdir(output_dir):
    shutil.rmtree(output_dir)
  os.makedirs(output_dir)
  for entry in os.listdir(input_dir):
    if entry.endswith(".svg"):
      print("Create file:       ", entry.ljust(40) + " SVG - Change file")
      with open(input_dir + "/" + entry, "r") as f:
        soup = BeautifulSoup(f.read(), features="xml")
        svg: BeautifulSoup = list(soup.children)[0]
        h = int(svg.attrs["height"])
        svg.attrs["width"]  = icon_size
        svg.attrs["height"] = icon_size
        with open(output_dir + "/" + entry, "wb") as o:
          o.write(svg.encode("utf-8"))
    elif entry.endswith(".xml"):
      print("Create file:       ", entry.ljust(40) + " XML - Copy file")
      shutil.copyfile(input_dir + "/" + entry, output_dir + "/" + entry)
