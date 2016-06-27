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
import codecs
def get_phone_and_word_db():
    dic=dict();
    with codecs.open('basefile/basedict.txt', encoding='utf-8') as f:
        for line in f:
            stream=line.rstrip(' \r\n').split('=')
            dic[stream[0]]=stream[1:]

    return dic