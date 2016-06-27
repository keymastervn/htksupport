import os
import shutil
for i in range(16):
	path=os.getcwd()+'\hmm'+str(i)
	if os.path.exists(path):
		shutil.rmtree(path)
	os.makedirs(path)

path=os.getcwd()+'\mfc'
if os.path.exists(path):
	shutil.rmtree(path)
os.makedirs(path)
path=os.getcwd()+'\createfile'
if os.path.exists(path):
	shutil.rmtree(path)
os.makedirs(path)
		