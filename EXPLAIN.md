# HTK

Pre steps:
    Step 1 - Task Grammar
    Step 2 - Pronunciation Dictionnary
    Step 3 - Recording the data
    Step 4 - Creating the Transcription Files
    Step 5 - Coding the (Audio) Data

# Prequisite
- Make folder tree for HTK: ruby main.rb --mkdir
- Make dictionary: ruby main.rb -d
  (if errors related to not found in dict blah blah, please insert NEW WORD to dict/vndict.txt then remake dict)
- Make training label file: ruby main.rb --labelfiles
	+ Convert from .txt to .lab which would compatiable to dictionary
- Make gram-momoword.txt: ruby main.rb -g
- Make wdnet: HParse grammar/gram-monoword.txt wdnet/wdnet.txt
- Make prompt: HSGen -l -n 10 wdnet/wdnet.txt dict/vndict.dic > prompts
(can increase 10 up to 300 depending on your training)
- Make wlist: ruby main.rb -w
- Make monophone: 
	+ Step 1: make initial monophone
ruby main.rb -im
	+ Step 2: make 2 monophones with sp and sil
ruby main.rb --monophones
- Move recording data to train_wav (*Including *.txt and *.wav files)

# Prepare test data before training
(because you won't input test data to train, you have to do this first)
- make testing_suggestion
(if you need detail - word with file storing it - to get confidence) ruby main.rb --what-to-train=100 -f 

# Training
- Make prompt_file for training: ruby main.rb -p --path='train_wav'
	* prompt_file.train is out
- Make words.mlf (master label file): ruby main.rb --mlf
- Make phone0.mlf (phonetic): HLEd -d dict/vndict.dic -i mlf/phones0.mlf ins/mkphones0.led mlf/words.mlf
- Make phone1.mlf (phonetic): HLEd -d dict/vndict.dic -i mlf/phones1.mlf ins/mkphones1.led mlf/words.mlf
- Prepare list conversion from wav to mfcc: ruby main.rb -s --path="train_wav" --act='MakeWavMfc4Train'
	* train.scp is auto generated in scp_files folder as well 
	* Because HERest is suck, mfc file and wav file should be stored in the same folder
- Make mfcc_files base on list conversion: HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_train.scp

	- HMM for enhance training
		- make hmm0, hmm1, hmm2, ... under hmm folder
		- make proto + vfloor file: HCompV -C cfg/HCompV.cfg -f 0.01 -m -S scp_files/train.scp -M hmm/hmm0 hmm/proto.template
		- make macro file + hmmdefs: ruby main.rb -macro --path="hmm/hmm0"
		- Re-estimate mean and variance in hmm0 to hmm1:
			HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm0/macros -H hmm/hmm0/hmmdefs -M hmm/hmm1 phones/monophones0
		- then in hmm1 and hmm2:
			HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm1/macros -H hmm/hmm1/hmmdefs -M hmm/hmm2 phones/monophones0
			HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm2/macros -H hmm/hmm2/hmmdefs -M hmm/hmm3 phones/monophones0
		- Add sp to hmmdefs and cp macros from another hmm (should be from hmm3 after all):
			ruby main.rb --sp2hmmdef=hmm/hmm3,hmm/hmm4 (TODO FIX)
		- Transform sil in hmm5 - append sp to sil:
			HHEd -H hmm/hmm4/macros -H hmm/hmm4/hmmdefs -M hmm/hmm5 ins/sil.hed phones/monophones1
		- then form hmm6 and hmm7 - remember from this time we use phones1 and monophones1 because we are training words with sp:
		  HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm5/macros -H hmm/hmm5/hmmdefs -M hmm/hmm6 phones/monophones1
		  HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm6/macros -H hmm/hmm6/hmmdefs -M hmm/hmm7 phones/monophones1
		- Realigning the traning data:
			+ copy phone1.mlf to aligned.mlf
				cp mlf/phones1.mlf mlf/aligned.mlf
			+ form hmm7 (you have to make .lab file in prequisite step):
				HVite -o SWT -b silence -a -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -i mlf/aligned.mlf -m -t 250.0 -y lab -I mlf/words.mlf -S scp_files/train.scp dict/vndict.dic phones/monophones1
			+ re-assign aligned (because aligned.mlf is suck - words are missing from aligned when compare to words.mlf):
				cp mlf/phones1.mlf mlf/aligned.mlf
		- then form hmm8 and hmm9:
			HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -M hmm/hmm8 phones/monophones1
			HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm8/macros -H hmm/hmm8/hmmdefs -M hmm/hmm9 phones/monophones1
	- Create Tied-state triphones:
		- Make triphone from monophone:
			HLEd -n phones/triphones1 -l '*' -i mlf/wintri.mlf ins/mktri.led mlf/aligned.mlf
		- Because of the path result in wintri.mlf is */xxxx.lab may be wrong, we have to correct em:
			ruby main.rb --correct-wintri
		- Make ins/mktri.hed:
			ruby main.rb --make-mktri-hed
		- Replicate hmm9 monophones to triphone in hmm10:
			HHEd -B -H hmm/hmm9/macros -H hmm/hmm9/hmmdefs -M hmm/hmm10 ins/mktri.hed phones/monophones1
		- then form hmm11 and hmm12 based on hmm10:
			HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm10/macros -H hmm/hmm10/hmmdefs -M hmm/hmm11 phones/triphones1
			HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm11/macros -H hmm/hmm11/hmmdefs -M hmm/hmm12 phones/triphones1
		- Create tied-state triphones:
			- Create FULLLIST:
				perl pl/mkFullList.pl phones/monophones0 phones/fulllist
			- Create TREE.HED with threshold by 40: 
				ruby main.rb --make-tree-hed=40
			- Tied:
				HHEd -B -H hmm/hmm12/macros -H hmm/hmm12/hmmdefs -M hmm/hmm13 ins/tree.hed phones/triphones1 > log.txt
				
				(attention: ERROR [+2662]  FindProtoModel: no proto for OW-GH+AR in hSet) => Mean that you have to
				remove OW-GH+AR from fulllist by hand - same for the others triphone)
				
				* If you are experiencing many [2662] errors, the below command is for removing unused triphones in unlist.

				Do remember to *RE-RUN* last HHEd to re-tied:

				ruby main.rb --clean-full-list (my BAD/HHEd_LINUX is in 32bit, you should install some libraries if your machine is in 64bit - tell google-sama)

				* Source file modded HHEd to rebuild is here: https://gist.github.com/keymastervn/3ba7c99c598e2c9a396fb69e74f3cfcc
			- Create HMM14, HMM15:
				HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm13/macros -H hmm/hmm13/hmmdefs -M hmm/hmm14 tiedlist
				HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm14/macros -H hmm/hmm14/hmmdefs -M hmm/hmm15 tiedlist

# Evaluation:

(remember you've cut wav files into word.wav in step prepare test data)

- Make scp_files for test_wav files:
	ruby main.rb -s --path="test_wav" --act='MakeWavMfc4Test'
- Make testwords.mlf file for a same scenario when training with words.mlf - use for evaluating:
	ruby main.rb --make-testwords-mlf
- Make mfcc files for test_wav files:
	HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_test.scp
- Recogniting:
	HVite -C cfg/Hvite.cfg -H hmm/hmm15/macros -H hmm/hmm15/hmmdefs -S scp_files/test.scp -i recout.mlf -w wdnet/wdnet.txt dict/vndict.dic tiedlist
- Format result:
	HResults -I mlf/testwords.mlf tiedlist recout.mlf > result.txt
