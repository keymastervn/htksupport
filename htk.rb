require 'file-tail'
require 'fileutils'
require 'os'
require 'open3'
require 'yaml'

class HTKSupport

	SINGLEWORD = 2
	SENTENCE = 3

	def initialize
		if File.exists?("config.yml")
			config = YAML.load_file("config.yml")
			@level = config["practice_level"]
			@dict = {}
		end
	end

	# TODO: Add to Makefile step as well as main.rb
	def config(practice_level = SINGLEWORD)

		raise "Invalid level" if ![SINGLEWORD, SENTENCE].include?(practice_level)

		f = File.open("config.yml", "w")
		f.write("practice_level: #{practice_level}\n")
		f.close
	end

	def make_dirs
		[ 
			"dict",
			"grammar",
			"mlf",
			"phones",
			"scp_files",
			"test_wav",
			"train_wav",
			"wdnet",
			"hmm/hmm0",
			"hmm/hmm1",
			"hmm/hmm2",
			"hmm/hmm3",
			"hmm/hmm4",
			"hmm/hmm5",
			"hmm/hmm6",
			"hmm/hmm7",
			"hmm/hmm8",
			"hmm/hmm9",
			"hmm/hmm10",
			"hmm/hmm11",
			"hmm/hmm12",
			"hmm/hmm13",
			"hmm/hmm14",
			"hmm/hmm15",
			"BAD",
			"LM"
		].each {|dir| FileUtils.mkdir_p dir}
	end

	def clean_scp_files
		File.delete(File.join("scp_files", "mfcc_test.scp")) if File.exists? File.join("scp_files", "mfcc_test.scp")
		File.delete(File.join("scp_files", "mfcc_train.scp")) if File.exists? File.join("scp_files", "mfcc_train.scp")
		File.delete(File.join("scp_files", "test.scp")) if File.exists? File.join("scp_files", "test.scp")
		File.delete(File.join("scp_files", "train.scp")) if File.exists? File.join("scp_files", "train.scp")
	end

	def get_dict(from_training_lab = false)
		master_string = []
		if !from_training_lab
			File.open(File.join("dict","vndict.txt"), "r:UTF-8").each do |line|
				# terminal end of line character
				line.chomp!
				line = line.to_telex
				line = line.with_pause
				master_string << line
			end
		else
			word_hash = {}
			Dir.entries("train_wav").select {|f| f.end_with? ".txt"}.each do |file|
				File.open(File.join("train_wav", file)).read.chomp.squeeze(" ").split(" ").each { |word|
					word_hash[word] = true
				}
			end
			word_hash.each_key do |word|
				master_string << word.to_telex.with_pause
			end
		end

		# sort string alphabetically
		master_string.sort_by!(&:downcase)
		master_string << "SENT-START   []   sil" if @level == SENTENCE
		master_string << "SENT-END   []   sil" if @level == SENTENCE
		master_string << "silence     sil"

		File.write(File.join("dict","vndict.dic"), master_string.join("\r\n") + "\r\n")
	end

	def get_monophone_from_dict
		hash_monophone = {}
		master_string = []

		File.open(File.join("dict","vndict.dic"), 'r').each do |line|
			line.chomp!
			# next if line.start_with?("SENT")

			phonetic = line.split("   ").reject { |c| c.empty? }[1]

			phonetic.split(" ").each {|sound| hash_monophone[sound] = ""}
		end

		hash_monophone.each_key do |key|
			master_string << key
		end

		# For SENTENCE-TRAINING
		# master_string << "sil" if !master_string.include? "sil"

		master_string = master_string.join("\n")
	  
	  File.write(File.join("phones","monophones"), master_string)
	end

	def generate_monophones

		m = File.read(File.join("phones","monophones"))
		m0 = File.open(File.join("phones","monophones0"), "w")
		m1 = File.open(File.join("phones","monophones1"), "w")

		m0.write(m.split("\n").delete_if{|word| word.eql?("sp") }.join("\n") << "\n")
		m1.write(m << "\n")

		m0.close
		m1.close
	end

	# ex: filename1, hôm nay trời đẹp quá
	def make_prompt_file(full_path_filename, text)
		master_string = []
		full_path_filename = File.expand_path full_path_filename
		f = File.open("prompt_file.train", "w")
		if !text.empty? && !full_path_filename.empty?
			text.split(" ").each do |word|
				master_string << word.get_converted_prefix
			end

			master_string = full_path_filename + "\t" + master_string.join(" ") + "\n"
			f.write(master_string)

		elsif text.empty? && File.directory?(full_path_filename)
			puts "Auto make prompt in dir, input names should be in convention. Ex: MS11.txt - MS11.wav"

			folder_path = full_path_filename
			
			Dir.entries(folder_path).select {|_f| _f.end_with? ".wav"}.each do |file|
				another_master_string = []
				wav_f = File.join(folder_path,file)
				txt_f = wav_f.gsub(File.extname(wav_f), ".lab")

				File.exists?(txt_f) ? nil : (txt_f = wav_f.gsub(File.extname(wav_f), ".txt")) 

				File.open(txt_f, "r").each do |line|
					line.chomp.squeeze(" ").split(" ").each {|word| another_master_string << word.get_converted_prefix}
				end

				f.write(txt_f + "\t" + another_master_string.join(" ") + "\n")
			end
		else
			raise "Please input text or file_name to make prompt"
		end

		f.close
	end

	def make_training_label_file
		raise "Please correct the training folder in your config" if !File.directory?("train_wav")

		Dir.entries("train_wav").select {|f| f.end_with? ".txt"}.each do |file|
			current_master_string = []
			File.open(File.join("train_wav", file)).read.chomp.squeeze(" ").split(" ").each { |word|
				current_master_string << word.get_converted_prefix
			}

			file_path = File.join("train_wav", File.basename(file, ".*") + '.lab')

			lab_file = File.new(file_path, "w")
			lab_file.write(current_master_string.join(" ") + "\r\n")
			lab_file.close
		end
	end

	def make_master_label_file
		raise "Make prompt_file.train before making label files" if !File.exist?("prompt_file.train")
		master_string = []
		master_string << "#!MLF!#"
		File.open("prompt_file.train", "r+").each do |line|
			line.chomp!
			x = LabelFile.new(line)
			master_string << x.generate_object_in_text
		end

		master_string = master_string.join("\n") + "\n"
		File.write(File.join("mlf","words.mlf"), master_string)
	end

	def make_mfcc_files(full_path_filename, flag)
		path = full_path_filename.gsub("\\", "/")
		mfcc_train_mapping_file = File.open(File.join("scp_files","mfcc_train.scp"), "a+")
		mfcc_test_mapping_file = File.open(File.join("scp_files","mfcc_test.scp"), "a+")
		test_file = File.open(File.join("scp_files","test.scp"), "a+")
		train_file = File.open(File.join("scp_files","train.scp"), "a+")

		case flag.upcase 
		when 'MakeWavMfc4Train'.upcase
			raise "Please input the true folder_path in argv: -path" if !File.directory?(full_path_filename)
			Dir.entries(full_path_filename).select {|f| f.end_with? ".wav"}.each do |file|
				mfcc_file = File.join(Dir.pwd, 'train_wav', File.basename(file, ".*") + '.mfc')
				mfcc_train_mapping_file.write(File.join(File.expand_path(full_path_filename), file) + "\t" + mfcc_file + "\n")
				train_file.write(mfcc_file + "\n")
			end
		when 'MakeWavMfc4Test'.upcase
			raise "Please input the true folder_path in argv: -path" if !File.directory?(full_path_filename)
			Dir.entries(full_path_filename).select {|f| f.end_with? ".wav"}.each do |file|
				mfcc_file = File.join(Dir.pwd, 'test_wav', File.basename(file, ".*") + '.mfc')
				mfcc_test_mapping_file.write(File.join(File.expand_path(full_path_filename), file) + "\t" + mfcc_file + "\n")
				test_file.write(mfcc_file + "\n")
			end
		when 'Train'.upcase
			file_name_no_extension = File.basename(path, ".*")
			mfcc_file = File.join(Dir.pwd, 'train_wav', file_name_no_extension + '.mfc')
			mfcc_train_mapping_file.write("#{full_path_filename}\t#{mfcc_file}\n");
			train_file.write(mfcc_file + "\n")
		when 'Test'.upcase
			file_name_no_extension = File.basename(path, ".*")
			mfcc_file = File.join(Dir.pwd, 'test_wav', file_name_no_extension + '.mfc')
			mfcc_test_mapping_file.write("#{full_path_filename}\t#{mfcc_file}\n");
			test_file.write(mfcc_file + "\n")
		end
		mfcc_train_mapping_file.close
		mfcc_test_mapping_file.close
		test_file.close
		train_file.close
	end

	def prefetch_dict
		File.open(File.join("dict", "vndict.dic"), "r").each do |line|
			line.chomp!
			@dict[line.split("   ", 2).first] = true
		end
	end

	def make_grammar_file
		prefetch_dict

		case @level
		when SINGLEWORD
			structure = "(<$word>)"
		when SENTENCE
			structure = "( SENT-START <$word> SENT-END )"
		end

		words = {}
		master_string = []
		grammar_file = File.open(File.join("grammar","gram.txt"), "w")
		Dir.entries("train_wav").select {|f| f.end_with? ".lab"}.each do |file|
			File.open(File.join("train_wav", file), "r").each do |line|
				line.chomp.gsub(/[:,?.!]/, " ")
					.squeeze(" ")
					.split(" ")
					.each {|word| words[word] = true}
			end
		end
		
		words.each_key do |key|
			if @dict[key].nil?

				puts "The word '#{key}' is not available for dictionary yet."
				print "Do you want to add this word to grammar or not? Y/N: "
				while user_input = gets.chomp
					case user_input.upcase
					when "Y"
						master_string << key
						puts "Added '#{key}'' to grammar"
						break
					else
						puts "Skipped '#{key}'"
						break
					end
				end
			else
				master_string << key
			end
		end

		grammar_file.write(
			["$word = #{master_string.join(" | ")};",
			"",
			structure].join("\n")
			)
		
		grammar_file.close
	end

	def make_word_list
		words = {}
		master_string = []
		raise "Tao prompts test truoc khi tao wlist" if !File.exist?("prompts")
		File.open("prompts", "r").each do |line|
			line.chomp.squeeze(" ").split(" ").each {|word| words[word] = "" if !word.include?(".")}
		end

		words.each_key do |key|
			master_string << key
		end

		wlist = File.open("wlist", "w")

		wlist.write(master_string.join("\n"))
		wlist.close
	end

	def make_macro(folder_path)
		raise "Vui long nhap -path la folder" if !File.directory?(folder_path)

		macro_file = File.open(File.join(folder_path, "macros"), "w")
		vfloor_file = File.read(File.join(folder_path, "vFloors"))

		macro_file.write("~o\n<STREAMINFO> 1 39\n<VECSIZE> 39<NULLD><MFCC_D_A_0><DIAGC>\n" << vfloor_file)
		macro_file.close
	end

	def make_hmmdef(folder_path)
		raise "Vui long nhap -path la folder" if !File.directory?(folder_path)
		raise "Vui long tao monophone0" if !File.exists?(File.join("phones","monophones0"))

		master_string = []
		proto_string = ""
		proto_file = File.open(File.join(folder_path, "proto")).to_a
		monophone = File.open(File.join("phones", "monophones0")).to_a
		(4..(proto_file.size)).each { |index|
			proto_string += proto_file[index].to_s
		}

		monophone.each {|phone| 
			phone.chomp!

			master_string << "~h \"#{phone}\"\n" + proto_string
		}
		hmmdef_file = File.open(File.join(folder_path, "hmmdefs"), "w")
		hmmdef_file.write(master_string.join(""))
	end

	def padd_short_pause_to_hmmdef(source_path, dest_path)

		raise "Source path khong chua hmmdefs hoac macros" if 
		 !File.exists?(File.join(source_path,"hmmdefs")) ||
		 !File.exists?(File.join(source_path,"macros"))

		sil_was_here = false
		start_capture = false
		master_string = []
		sp_hmmdef_file = File.open(File.join(source_path,"hmmdefs"), "r")
		dp_hmmdef_file = File.open(File.join(dest_path,"hmmdefs"), "w")
		
		sp_hmmdef_file.each do |line|
			line.chomp!

			if line =~ /sil/
				sil_was_here = true
				master_string << "~h \"sp\""
				master_string << "<BEGINHMM>"
				master_string << "<NUMSTATES> 3"
				master_string << "<STATE> 2"
			end

			if line =~ /<STATE> 3/ && sil_was_here
				start_capture = true
				next
			end

			if line =~ /<STATE> 4/ && sil_was_here
				start_capture = false
				break
			end

			if start_capture
				master_string << line
			end
		end

		master_string << "<TRANSP> 3"
		master_string << " 0.000000e+00 5.000000e-01 5.000000e-01"
		master_string << " 0.000000e+00 5.000000e-01 5.000000e-01"
		master_string << " 0.000000e+00 0.000000e+00 0.000000e+00"
		master_string << "<ENDHMM>"

		dp_hmmdef_file.write(File.open(File.join(source_path,"hmmdefs")).read + master_string.join("\n") + "\n")

		sp_hmmdef_file.close
		dp_hmmdef_file.close
		
		# Copy macros file from source to dest
		FileUtils.cp File.join(source_path,"macros"), dest_path
	end

	# TODO fix sil => SENT in wintri if level = 3
	def correct_wintri
		raise "Vui long tao wintri truoc khi correct" if !File.exists?(File.join("mlf","wintri.mlf"))
		master_string = []
		path = File.join(Dir.pwd, "mlf")
		training_path = File.join(Dir.pwd, "train_wav")

		File.open(File.join(path, "wintri.mlf"), "r") do |file|
			file.each do |line|
				line.chomp!
		    if (line=~/.lab/)
		    	full_path = File.join(training_path, File.basename(line.gsub("\"", "")))
		      line = "\"" + full_path + "\""
		    end
		    master_string << line
		  end
		end

		File.open(File.join(path, "wintri.mlf"), "w").write(master_string.join("\n") + "\n")
	end

	def make_mktri_hed

		monophone_path = File.join("phones", "monophones1")
		raise "Vui long tao monophones1 truoc khi tao mktri.hed" if !File.exists?(monophone_path)
		master_string = []

		master_string << "CL phones/triphones1"
		File.open(monophone_path, "r").each_line do |line|
			line.chomp!
			if !line.empty? 
				master_string << "TI T_#{line} {(*-#{line}+*,#{line}+*,*-#{line}).transP}"
			end
		end

		f = File.open(File.join("ins", "mktri.hed"), "w")
		f.write(master_string.join("\n") + "\n")
		f.close
	end

	def make_tree_hed(threshold)
		raise "Vui long tao monophones0 truoc khi tao tree.hed" if !File.exists?(File.join(Dir.pwd, "phones", "monophones0"))
		thresh_hold = threshold.to_i
		monophone_path = File.join(Dir.pwd, "phones", "monophones1")
		master_string = []
		tree_hed_file = File.new(File.join(Dir.pwd, "ins", "tree.hed"), "w")

		# Include some headers
		master_string << "RO 20 stats"
		master_string << "TR 0"

		# QS left
		File.open(monophone_path, "r").each_line do |line|
			line.chomp!
			master_string << "QS \"l_#{line}\" {#{line}-*}"
		end

		# new line
		master_string << ""

		# QS right
		File.open(monophone_path, "r").each_line do |line|
			line.chomp!
			master_string << "QS \"r_#{line}\" {*+#{line}}"
		end

		master_string << "TR 2"

		# TB Threshold _2_
		(2..4).each {|t| 
			File.open(monophone_path,"r").each_line do |line|
				line.chomp!
				master_string << "TB #{thresh_hold} \"st_#{line}_#{t}_\" {(\"#{line}\",\"*-#{line}+*\",\"#{line}+*\",\"*-#{line}\").state[#{t}]}"
			end
			master_string << "" if t != 4
		}

		master_string << "TR 1"
		master_string << "AU \"phones/fulllist\""
		master_string << "CO \"tiedlist\""
		master_string << "ST \"trees\""
		tree_hed_file.write(master_string.join("\n"))
	end

	def clean_fulllist
		hhed_modded = File.join("BAD", "HHEd_LINUX") if OS.linux?
		hhed_modded = File.join("BAD", "HHEd_WINDOWS") if OS.windows?
		hhed_modded = File.join("BAD", "HHEd_MAC") if OS.mac?

		full_list_file = File.read(File.join("phones", "fulllist"))
		bad_proto = File.open(File.join("BAD", "badproto.txt"),"w")

		puts "#{Time.now} It will be taking so long"
		stdin, stdout, stderr, wait_thr = Open3.popen3(hhed_modded, "-B", "-H", "hmm/hmm12/macros", "-H", "hmm/hmm12/hmmdefs", "-M",
		 "hmm/hmm13", "ins/tree.hed", "phones/triphones1")

		stdout.gets(nil).split("\n").each do |line|
			bad_proto.write(line + "\n")
			removeable = line.split(":").last
			full_list_file.gsub!("\n" + removeable + "\n", "\n")
		end

		bad_proto.close

		puts "#{Time.now} Done sanitize errors"
		
		full_list_file.squeeze!("\n")
		full_list_file = full_list_file.split("\n").uniq.join("\n")

		puts "#{Time.now} Done fixing errors"
		
		f = File.open(File.join("phones", "fulllist"), "w")
		f.write(full_list_file)
		f.close
	end

	def recommend_training(number, file_show = false)
		skipped_files = []
		output = []
		suggested_words = []
		hash_words = {}
		hash_files = {}
		Dir.entries("train_wav").select {|f| f.end_with? ".lab"}.each do |file|
			File.open(File.join("train_wav", file)).read.chomp.squeeze(" ").split(" ").each { |word|
				s = word.get_converted_prefix
				hash_words[s].nil? ? 
					hash_words[s] = 1 :
					hash_words[s] += 1

				hash_files[s].nil? ?
					hash_files[s] = [file] :
					hash_files[s] << file
			}
		end

		while (output.size < number)
			key, _ = hash_words.max_by{|k, v| v}

			hash_files[key].each {|file|
				next if skipped_files.include? file
				if !suggested_words.include? key
					txt = file_show ? "#{file}\t#{key}\t\t#{hash_words[key]} times\t#{hash_files[key].join(",")}" : "#{file}\t#{key}\t\t#{hash_words[key]} times"
					output << txt if output.size < number
					suggested_words << key
					skipped_files += hash_files[key]
				end

				# crawl another words in file
				File.open(File.join("train_wav", file)).read.chomp.squeeze(" ").split(" ").each { |word|
					s = word.get_converted_prefix
					if !suggested_words.include?(s) && hash_words[s] > 1
						txt = file_show ? "#{file}\t#{word}\t\t#{hash_words[word]} times\t#{hash_files[word].join(",")}" : "#{file}\t#{word}\t\t#{hash_words[word]} times"
						output << txt if output.size < number
						suggested_words << s
						skipped_files += hash_files[word]
						hash_words.delete(word)
						hash_files.delete(word)
					end
				}
				skipped_files << file
			}

			hash_words.delete(key)
			hash_files.delete(key)
		end

		puts output.join("\n")
		puts "Reach #{output.size} words"
	end

	def make_testwords
		raise "Chua tao file phone.wav bang audacity trong testing" if Dir.glob(File.join("test_wav", "*")).empty?

		# make lab file by the way
		if @level == SINGLEWORD
			File.new(File.join("test_wav",file).gsub(".wav", ".lab"), "w").write(word + "\n")
		end

		master_string = []
		testwords = File.open(File.join("mlf", "testwords.mlf"),"w")
		master_string << "#!MLF!#"
		Dir.entries("test_wav").select {|_f| _f.end_with? ".lab"}.each do |file|
			word = File.read(File.join("test_wav", file))
			master_string << "\"" + File.expand_path(File.join("test_wav",file.gsub(".lab", ".wav"))) + "\""
			master_string << word
			master_string << "."
		end

		testwords.write(master_string.join("\n") + "\n")

		testwords.close
	end

	# TODO: Parse prompts file in corpus to *label file
	def parse_prompts(prompts_path, destination = 'train_wav')
		# Parse a Corpus Prompt and make Label file to specific destination
		# Remember u have to copy all the files training corpus to train_wav
		raise "File does not exists" if !File.exists?(prompts_path)

		convert_wrong = {}
		File.open(File.join("dict", "vnabbre_synonym_misspell.txt"), "r:UTF-8").each do |line|
			line.chomp!
			prefix = line.split("\t").first
			suffix = line.split("\t").last
			convert_wrong[prefix] = suffix
			# suffix = line.split("\t").last.split(" ").map {|word| word.get_converted_suffix}.join(" sp ")
			# master_string << prefix + " " * (16-prefix.length) + suffix + " sp"
		end

		File.open(prompts_path, "r").each {|line|
			line.chomp!
			file, text = line.split(" ", 2)
			IO.write(
				File.join(destination, file << ".lab"), 
				text.uni_downcase.split(" ").map {|word|
					convert_wrong[word].nil? ? word.get_converted_prefix : convert_wrong[word].get_converted_prefix
				}.join(" "),
				0,
				{mode: "w"}
			)

			IO.write(
				File.join(destination, file.gsub(".lab", ".txt")), 
				text.uni_downcase.split(" ").map {|word|
					convert_wrong[word].nil? ? word : convert_wrong[word]
				}.join(" "),
				0,
				{mode: "w"}
			)
		}
	end

	def format_crawled_data(file_path = '/', to_file)
		# input: Hôm nay trời nắng vãi
		# output: <s> hoom nay trowfi nawsng vaxi </s>
		h_map = File.open(File.join("dict", "vnabbre_synonym_misspell.txt"))
						.read
						.split("\n")
						.map {|pkg| pkg.uni_downcase.split("\t") }
						.to_h

		f = File.new(to_file, "w")
		File.open(file_path, "r:UTF-8").each {|line|
			line.chomp!
			begin
				line = line.uni_downcase.squeeze(" ").split(" ").map {|word| 
					word = h_map[word] if !h_map[word].nil?
					word.get_converted_prefix}.join(" ")
				f.write(["<s>", line, "</s>"].join(" ") + "\n")
			rescue
				next
			end
		}
		f.close
	end
end

class LabelFile
	attr_accessor(:file_dir, :texts)

	FOOTER = "." 

	def initialize(prompt_line)
		comp = prompt_line.split("\t")
		self.file_dir = "\"#{comp[0]}\"".gsub(".wav", ".lab")
		self.texts = comp[1].chomp.gsub(" ", "\n")
	end

	def generate_object_in_text
		[self.file_dir, self.texts, FOOTER].join("\n")
	end
end