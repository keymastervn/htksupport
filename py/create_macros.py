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
wf = codecs.open('hmm0/macros', mode="w", encoding='utf-8')
with codecs.open("hmm0/proto", encoding='utf-8') as f:
    for line in f:
        if i==3:
            break
        wf.writelines(line)
        i+=1


with codecs.open("hmm0/vFloors", encoding='utf-8') as f:
    for line in f:
        wf.writelines(line)

f.close()
