#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      Alex
#
# Created:     29/05/2014
# Copyright:   (c) Alex 2014
# Licence:     <your licence>
#-------------------------------------------------------------------------------
import codecs
import sys
import glob
import os

if(len(sys.argv)!=3):
    sys.exit("create prompts need 3 arg")

[callfile, filepath, filesave]=sys.argv

filenames=glob.glob(filepath+"/*.wav")
wf = codecs.open(filesave, mode="w", encoding='utf-8')
i=1
for filename in filenames:
    wf.writelines(' '.join(["mfc\\"+os.path.splitext(os.path.basename(filename))[0]+".mfc"]))
    wf.writelines("\n")