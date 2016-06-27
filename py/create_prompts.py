#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      Alex
#
# Created:     28/05/2014
# Copyright:   (c) Alex 2014
# Licence:     <your licence>
#-------------------------------------------------------------------------------

import sys
import glob
import codecs
import os
from base_dict import get_phone_and_word_db
if(len(sys.argv)!=3):
    sys.exit("create prompts need 3 arg")

[callfile, filepath, filesave]=sys.argv
filenames=glob.glob(filepath+"/*.txt")
dic=get_phone_and_word_db()
wf = codecs.open(filesave, mode="w", encoding='utf-8')
i=1
for filename in filenames:
    with codecs.open(filename, encoding='utf-8') as f:
        for line in f:
            stream=line.rstrip('\r\n').lower()
            li=list(stream)
            staindex=0
            curindex=1
            cur=text=li[0]
            telexip="";
            phoneip="";
            if len(li)==1:
                telexip=dic[stream][0]
                phoneip=dic[stream][1]
            else:
                while(staindex<len(li)):
                    text=''.join(li[staindex:curindex+1])
                    if text not in dic or curindex==len(li) :
                        telexip=''.join([telexip,dic[''.join(li[staindex:curindex])][0]])
                        staindex=curindex;
                    else:
                        cur=text
                    curindex+=1

            wf.writelines(" ".join(["*/"+os.path.splitext(os.path.basename(filename))[0]+".lab",telexip,'\n']))
            i=i+1
wf.close()
