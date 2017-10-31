import os
import xml.etree.ElementTree as ET
from textgrid import TextGrid

textgrid_dir = r'E:\Data\AudioBNCTextGrids_raw'

bnc_xml_dir = r'E:\Data\BNC\Texts'

for f in os.listdir(textgrid_dir):
    path = os.path.join(textgrid_dir, f)
    tg = TextGrid()
    tg.read(path)
    print(tg)
    error