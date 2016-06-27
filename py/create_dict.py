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
import os, glob
from base_dict import get_phone_and_word_db

if(len(sys.argv)<2):
    sys.exit("create prompts need 3 arg")

[callfile, filesave, filepath ]=sys.argv
filenames=glob.glob(filepath+"/*.lab")
dic=get_phone_and_word_db()
totalli=[]
for filename in filenames:
	with codecs.open(filename, encoding='utf-8') as f:
		for line in f:
			stream=line.rstrip('\r\n').lower()
			li=stream.split(' ')
			for x in li:
				if x not in totalli:
					totalli.append(x)

i=1
mydict={}
a=[]
wf = codecs.open(filesave, mode="w", encoding='utf-8')
for stream in totalli:
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
                phoneip=' '.join([phoneip,dic[''.join(li[staindex:curindex])][1]])
                staindex=curindex;
            else:
                cur=text
            curindex+=1

##    wf.writelines(" ".join([telexip,phoneip.lstrip(' '),'sp','\n']))
    mydict[telexip]=" ".join([phoneip.lstrip(' '),'sp','\n'])
    a.append(telexip)
    i=i+1

##mydict['SENT-START']=" sil\n"
##mydict['SENT-END']=" sil\n"
##mydict['silence'] = " sil\n"
for key in sorted(mydict):
##    wf.write(key)
##    wf.write(mydict[key])
    wf.write(key)
    wf.write(" ")
    wf.write(mydict[key])
##    print "%s: %s" % (key, mydict[key])
wf.writelines("SENT-START [] sil\nSENT-END [] sil\nsilence sil\n")
wf.close()

