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
# Python script to automatically resize the application icons from the original
# 48x48 pixel width to something more appropriate for different screen sizes.
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

output_dir_prefix = 'resources-icons-'
input_dir         = output_dir_prefix + '48'

Doub = 0
Sing = 1
Half = 2

# Original icons for 416x416 screen size with 48x48 icons
original = (96, 48, 24)

# Convert icons to different screen sizes by these parameters
lookup = {
  #   Doub Sing Half
  #      0   1   2
  454: (106, 53, 27),
#  416: ( 96, 48, 24),
  390: ( 90, 46, 23),
  360: ( 84, 42, 21),
  320: ( 74, 38, 19),
  280: ( 64, 32, 16),
  260: ( 60, 30, 15),
  240: ( 56, 28, 14),
  218: ( 50, 26, 13),
  208: ( 48, 24, 12),
  176: ( 42, 21, 11),
  156: ( 36, 18,  9)
}

# Delete all but the original 48x48 icon directories
for entry in os.listdir("."):
  if entry.startswith(output_dir_prefix) and entry != input_dir:
    shutil.rmtree(entry)

# (Re-)Create the resized icon directories
for screen_size, icon_sizes in lookup.items():
  output_dir = output_dir_prefix + str(icon_sizes[Sing])
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
        if (h == original[Doub]):
          svg.attrs["width"]  = lookup[screen_size][Doub]
          svg.attrs["height"] = lookup[screen_size][Doub]
        elif (h == original[Sing]):
          svg.attrs["width"]  = lookup[screen_size][Sing]
          svg.attrs["height"] = lookup[screen_size][Sing]
        elif (h == original[Half]):
          svg.attrs["width"]  = lookup[screen_size][Half]
          svg.attrs["height"] = lookup[screen_size][Half]
        with open(output_dir + "/" + entry, "wb") as o:
          o.write(svg.encode("utf-8") + b"\n")
    elif entry.endswith(".xml"):
      print("Create file:       ", entry.ljust(40) + " XML - Copy file")
      shutil.copyfile(input_dir + "/" + entry, output_dir + "/" + entry)
