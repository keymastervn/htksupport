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
from base_dict import get_phone_and_word_db

if(len(sys.argv)!=3):
    sys.exit("create prompts need 3 arg")

[callfile, filepath, filesave]=sys.argv

dic=get_phone_and_word_db()
filenames=glob.glob(filepath+"/*.txt")
dic=get_phone_and_word_db()
wf = codecs.open(filesave, mode="w", encoding='utf-8')
for filename in filenames:
    with codecs.open(filename, encoding='utf-8') as f:
        for line in f:
            stream=line.rstrip('\r\n').lower()
            wf.write("<s> ")
            wf.write(''.join([dic[x][0] for x in stream]))
            wf.write(" </s>")
            wf.write("\n")

wf.close()