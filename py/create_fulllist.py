#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      Alex
#
# Created:     30/05/2014
# Copyright:   (c) Alex 2014
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import codecs
import sys
import glob
import os
if(len(sys.argv)<3):
    sys.exit("create prompts need more than 2 arg")

[callfile, fileopen,filesave]=sys.argv
triphone=[]
with codecs.open(fileopen, encoding='utf-8') as f:
    for line in f:
        triphone.append( line.rstrip('\r\n'))


wf = codecs.open(filesave, mode="w", encoding='utf-8')
for x in triphone:
    wf.write(x+'\n')
for x in triphone:
    for y in triphone:
        wf.write(x+"+"+y+'\n')
        wf.write(x+"-"+y+'\n')
##for x in triphone:
##    for y in triphone:
##        if x!="sil" or y!= "sil":
##            for z in triphone:
##                wf.write(x+"-"+y+"+"+z+'\n')
for x in triphone:
    for y in triphone:
        for z in triphone:
            wf.write(x+"-"+y+"+"+z+'\n')

wf.close()




