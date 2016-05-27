require 'optparse'
require 'ostruct'
require './htk'
require './string_helper'

class Parser
  def self.parse(args)

    # We set default values here.
    htkrunner = HTKSupport.new
    options = OpenStruct.new
    options.library = []
    options.inplace = false
    options.encoding = "utf8"
    options.transfer_type = :auto
    options.verbose = false
    options.flag = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: main.rb [options]"

      opts.on("-path", "--path=FULL_PATH_FILE", "Nhap dia chi day du file can thuc thi") do |v|
        options.file_path = v
      end

      opts.on("--mkdir", "Tao prerequisite folder de phong HTK bao loi") do 
        htkrunner.make_dirs
      end

      opts.on("-d", "--dict", "Tao dict tu filepath vocabulary") do
        htkrunner.get_dict
      end

      opts.on("-im", "--gen-initial-monophone", "Tao monophone tu dict, phai co san dict tu truoc") do
        htkrunner.get_monophone_from_dict
      end

      opts.on("--monophones", "Tao monophone0, monophone1 tu prompt") do
        htkrunner.generate_monophones
      end

      opts.on("-p", "--prompt", "Tao prompt file") do
        options.do_create_prompt = true
      end

			opts.on("-t text", "--text=TEXTTOSAY", "Tieng noi can thu") do |t|
        options.text = t
      end

      opts.on("--mlf", "Tao label file cho prompt file") do
        htkrunner.make_master_label_file
      end

      opts.on("--labelfiles", "Tao label file cho training wave") do
        htkrunner.make_training_label_file
      end

      opts.on("--correct-wintri", String,
          "Replace */MSaaaaabb_1100.lab to /User/abc/.../MSaaaaabb_1100.lab" ) do |opt|
        htkrunner.correct_wintri
      end

			opts.on("-a", "--action=TRAIN_OR_TEST_OR_LISTWAVMFC", "Xac dinh train hoac test hoac tao listwavmfc khi tao file scp") do |t|
        options.action = t
      end

      opts.on("-s", "--MfccFiles", "Khoi tao cac file scp") do
        options.do_create_scp_files = true
      end 

      opts.on("-g", "--grammar", "Tao gram monoword") do
        htkrunner.make_grammar_file
      end

      opts.on("-w", "--wlist", "Tao word list") do 
        htkrunner.make_word_list
      end

      opts.on("-ma", "--macro", "Tao macro tu vFloor cua folder") do 
        options.do_create_macro = true
      end

      opts.on("--sp2hmmdef=arg1[,...]", "Them sp vao hmmdef tu source_path (args1) sang dest_path (args2)") do |input|
        source = input.split(",")[0]
        dest = input.split(",")[1]
        htkrunner.add_short_pause_to_hmmdef(source, dest)
      end

      opts.on("--f", "Flag") do 
        options.flag = true
      end

      opts.on("--make-mktri-hed", "Tao mktri.hed de nhai mo hinh monophone thanh triphone") do 
        htkrunner.make_mktri_hed
      end

      opts.on("--make-tree-hed=THRESHOLD", Integer, "Khoi tao tree-hed theo monophones") do |threshold|
        htkrunner.make_tree_hed(threshold)
      end

      opts.on("--clean-full-list", "Don dep triphones khong su dung trong phones/fulllist") do
        htkrunner.clean_fulllist
      end

      opts.on("--clean-scp-files", "Xoa scp_files/* ") do 
        htkrunner.clean_scp_files
      end

      opts.on("--what-to-train=NUMBER", Integer, "Liet ke tu xuat hien nhieu hon 2 lan trong train_wav va de nghi") do |number|
        options.recommend_training = true
        options.number_to_train = number
      end

      opts.on("--make-testwords-mlf", "Tao file testwords.mlf chua toan bo noi dung nhu words.mlf nhung cua test") do 
        htkrunner.make_testwords
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    return options
  end
end

options = Parser.parse(ARGV)

runner = HTKSupport.new

if options.do_create_prompt
	runner.make_prompt_file(options.file_path.to_s, options.text.to_s) 
end

if options.do_create_scp_files
	raise "Vui long nhap --path hoac --act neu con thieu" if (options.file_path.nil? ||
	 options.action.nil?)

	runner.make_mfcc_files(options.file_path.to_s, options.action.to_s)
end

if options.do_create_macro
  raise "Vui long nhap --path" if options.file_path.nil?
  runner.make_macro(options.file_path.to_s)
  runner.make_hmmdef(options.file_path.to_s)
end

if options.recommend_training
  runner.recommend_training(options.number_to_train, options.flag)
end