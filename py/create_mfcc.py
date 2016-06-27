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
if(len(sys.argv)<3):
    sys.exit("create prompts need more than 2 arg")

[callfile, filesave,*filepaths]=sys.argv
wf = codecs.open(filesave, mode="w", encoding='utf-8')
for filepath in filepaths:

    filenames=glob.glob(filepath+"/*.wav")

    i=1
    for filename in filenames:
        print(filename)
        wf.writelines(' '.join([filename,"mfc\\"+os.path.splitext(os.path.basename(filename))[0]+".mfc"]))
        wf.writelines("\n")



