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
i=0
printstr=""
with codecs.open("hmm0/proto", encoding='utf-8') as f:
    for line in f:
        if i==1 or line[0:10] == '<BEGINHMM>':
            printstr=''.join([printstr,line])
            i=1

        if line=='<ENDHMM>':
            break
wf = codecs.open('hmm0/hmmdefs', mode="w", encoding='utf-8')
with codecs.open("createfile\monophones0", encoding='utf-8') as f:
    for line in f:
        wf.writelines(" ".join(["~h",line]))
        wf.writelines(printstr)

f.close()
