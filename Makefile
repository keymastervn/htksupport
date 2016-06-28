practice_word:
	ruby main.rb --config --level=2

practice_sentence:
	ruby main.rb --config --level=3

prequisite:
	ruby main.rb --mkdir
	ruby main.rb --clean-scp-files
	ruby main.rb -d
	ruby main.rb --labelfiles
	ruby main.rb --grammar
	HParse grammar/gram.txt wdnet/wdnet.txt
	HSGen -l -n 10 wdnet/wdnet.txt dict/vndict.dic > prompts
	ruby main.rb -w
	ruby main.rb -im
	ruby main.rb --monophones

testing_suggestion:
	@echo "Separate files to words for testing"
	@echo "1. Remove output file from training => to testing"
	@echo "2. Use Audacity (or anything alike) to split file into [word].wav then copy to test_wav "
	@echo "3. Naming convention of [word].wav: words HIFNH => HIFNH.wav | words trowfi => trowfi.wav"
	@echo "==========================8<=========================="
	ruby main.rb --what-to-train=100
	@echo "==========================8<=========================="

training:
	@echo "Training hmm"
	ruby main.rb -p --path='train_wav'
	ruby main.rb --mlf
	HLEd -d dict/vndict.dic -i mlf/phones0.mlf ins/mkphones0.led mlf/words.mlf
	HLEd -d dict/vndict.dic -i mlf/phones1.mlf ins/mkphones1.led mlf/words.mlf
	ruby main.rb -s --path="train_wav" --act='MakeWavMfc4Train'
	HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_train.scp
	HCompV -C cfg/HCompV.cfg -f 0.01 -m -S scp_files/train.scp -M hmm/hmm0 hmm/proto.template
	ruby main.rb -macro --path="hmm/hmm0"
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm0/macros -H hmm/hmm0/hmmdefs -M hmm/hmm1 phones/monophones0
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm1/macros -H hmm/hmm1/hmmdefs -M hmm/hmm2 phones/monophones0
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm2/macros -H hmm/hmm2/hmmdefs -M hmm/hmm3 phones/monophones0
	ruby main.rb --sp2hmmdef=hmm/hmm3,hmm/hmm4
	HHEd -H hmm/hmm4/macros -H hmm/hmm4/hmmdefs -M hmm/hmm5 ins/sil.hed phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm5/macros -H hmm/hmm5/hmmdefs -M hmm/hmm6 phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm6/macros -H hmm/hmm6/hmmdefs -M hmm/hmm7 phones/monophones1
	cp mlf/phones1.mlf mlf/aligned.mlf
	HVite -o SWT -b silence -a -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -i mlf/aligned.mlf -m -t 250.0 -y lab -I mlf/words.mlf -S scp_files/train.scp dict/vndict.dic phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -M hmm/hmm8 phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm8/macros -H hmm/hmm8/hmmdefs -M hmm/hmm9 phones/monophones1
	@echo "Tied tri-phone"
	HLEd -n phones/triphones1 -i mlf/wintri.mlf ins/mktri.led mlf/aligned.mlf

	ruby main.rb --make-mktri-hed
	HHEd -B -H hmm/hmm9/macros -H hmm/hmm9/hmmdefs -M hmm/hmm10 ins/mktri.hed phones/monophones1
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm10/macros -H hmm/hmm10/hmmdefs -M hmm/hmm11 phones/triphones1
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm11/macros -H hmm/hmm11/hmmdefs -M hmm/hmm12 phones/triphones1
	perl pl/mkFullList.pl phones/monophones0 phones/fulllist
	ruby main.rb --make-tree-hed=40

	ruby main.rb --clean-full-list
	HHEd -B -H hmm/hmm12/macros -H hmm/hmm12/hmmdefs -M hmm/hmm13 ins/tree.hed phones/triphones1 > log.txt
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm13/macros -H hmm/hmm13/hmmdefs -M hmm/hmm14 tiedlist
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm14/macros -H hmm/hmm14/hmmdefs -M hmm/hmm15 tiedlist

training_sentence:
	@echo "Training hmm-sentence"
	@echo "Overriding many things"
	ruby main.rb -d --f
	ruby main.rb -p --path='train_wav'
	HDMan -m -w wlist -n phones/monophones -l dict.log dict/vndict.log dict/vndict.dic
	perl pl/mkMonophones.pl phones/monophones phones/monophones0 phones/monophones1
	ruby main.rb --mlf

	HLEd -d dict/vndict.dic -i mlf/phones0.mlf ins/mkphones0_sentence.led mlf/words.mlf
	HLEd -d dict/vndict.dic -i mlf/phones1.mlf ins/mkphones1_sentence.led mlf/words.mlf
	ruby main.rb -s --path="train_wav" --act='MakeWavMfc4Train'
	HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_train.scp
	HCompV -C cfg/HCompV.cfg -f 0.01 -m -S scp_files/train.scp -M hmm/hmm0 hmm/proto.template
	ruby main.rb -macro --path="hmm/hmm0"
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm0/macros -H hmm/hmm0/hmmdefs -M hmm/hmm1 phones/monophones0
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm1/macros -H hmm/hmm1/hmmdefs -M hmm/hmm2 phones/monophones0
	HERest -C cfg/HERest.cfg -I mlf/phones0.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm2/macros -H hmm/hmm2/hmmdefs -M hmm/hmm3 phones/monophones0
	# ruby main.rb --sp2hmmdef=hmm/hmm3,hmm/hmm4
	perl pl/makesp.pl hmm/hmm3/hmmdefs hmm/hmm4/hmmdefs hmm/hmm3/macros hmm/hmm4/macros
	HHEd -H hmm/hmm4/macros -H hmm/hmm4/hmmdefs -M hmm/hmm5 ins/sil.hed phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm5/macros -H hmm/hmm5/hmmdefs -M hmm/hmm6 phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/phones1.mlf -t 250.0 150.0 1000.0 -S scp_files/train.scp -H hmm/hmm6/macros -H hmm/hmm6/hmmdefs -M hmm/hmm7 phones/monophones1

	cp mlf/phones1.mlf mlf/aligned.mlf
	HVite -o SWT -b silence -a -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -i mlf/aligned.mlf -m -y lab -I mlf/words.mlf -S scp_files/train.scp dict/vndict.dic phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm7/macros -H hmm/hmm7/hmmdefs -M hmm/hmm8 phones/monophones1
	HERest -C cfg/HERest.cfg -I mlf/aligned.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm8/macros -H hmm/hmm8/hmmdefs -M hmm/hmm9 phones/monophones1
	@echo "Tied tri-phone"
	HLEd -n phones/triphones1 -i mlf/wintri.mlf ins/mktri.led mlf/aligned.mlf

	# ruby main.rb --make-mktri-hed
	perl pl/mkTriHed.pl phones/monophones1 phones/triphones1 ins/mktri.hed
	HHEd -B -H hmm/hmm9/macros -H hmm/hmm9/hmmdefs -M hmm/hmm10 ins/mktri.hed phones/monophones1
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm10/macros -H hmm/hmm10/hmmdefs -M hmm/hmm11 phones/triphones1
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats -S scp_files/train.scp -H hmm/hmm11/macros -H hmm/hmm11/hmmdefs -M hmm/hmm12 phones/triphones1
	# perl pl/mkFullList.pl phones/monophones1 phones/fulllist
	python py/create_fulllist.py phones/monophones1 fulllist
	# perl pl/mkTree.pl 350 phones/monophones1 ins/tree.hed
	ruby main.rb --make-tree-hed=350

	ruby main.rb --clean-full-list
	HHEd -B -H hmm/hmm12/macros -H hmm/hmm12/hmmdefs -M hmm/hmm13 ins/tree.hed phones/triphones1
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm13/macros -H hmm/hmm13/hmmdefs -M hmm/hmm14 tiedlist
	HERest -B -C cfg/HERest.cfg -I mlf/wintri.mlf -t 250.0 150.0 1000.0 -s stats  -S scp_files/train.scp -H hmm/hmm14/macros -H hmm/hmm14/hmmdefs -M hmm/hmm15 tiedlist

testing:
	ruby main.rb -s --path="test_wav" --act='MakeWavMfc4Test'
	ruby main.rb --make-testwords-mlf
	HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_test.scp
	HVite -C cfg/Hvite.cfg -H hmm/hmm15/macros -H hmm/hmm15/hmmdefs -S scp_files/test.scp -i recout.mlf -w wdnet/wdnet.txt dict/vndict.dic tiedlist
	HResults -I mlf/testwords.mlf tiedlist recout.mlf > result.txt

testing_sentence:
	ruby main.rb -s --path="test_wav" --act='MakeWavMfc4Test'
	ruby main.rb --make-testwords-mlf
	HCopy -T 1 -C cfg/HCopy.cfg -S scp_files/mfcc_test.scp
	LNewMap -f WFC languageModel LM/empty.wmap
	LGPrep -T 1 -a 1000000 -b 2000000 -n 3 -d LM LM/empty.wmap wordmap.txt
	# WINDOWS ATTENTION: replace LM/gram.* for each gram.no listed in your LM. EG: LM/gram.0 LM/gram.1 ...
	LBuild -T 1 -c 2 0 -c 3 0 -n 3 LM/wmap LM/lmModel LM/gram.*
	LPlex -n 3 -t LM/lmModel wordmap-corpus.txt
	HDecode -H hmm/hmm15/macros -H hmm/hmm15/hmmdefs -S scp_files/test.scp -t 220.0 220.0 -C cfg/config.hdecode -i recout.mlf -w LM/lmModel -p 0.0 -s 5.0 dict/vndict.dic tiedlist
	HResults -I mlf/testwords.mlf tiedlist recout.mlf > result.txt

crawl:
	cd crawler && ruby crawler.rb && cd .. 

evaluation:
	LNewMap LM empty.wmap
	ruby main.rb --cc --path=crawler/crawl_result.txt --topath=wordmap.txt

