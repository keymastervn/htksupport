require 'sqlite3'
require 'audio-playback'
require 'ruby-audio'
require 'tmpdir'
require './string_helper'

include RubyAudio

class TXT2Speech

	def initialize
		current = Time.now
		day = current.day
		month = current.month
		year = current.year
		hour = current.hour
		min = current.min
		sec = current.sec
		hour > 12 ? (hour = hour - 12; meridan = "chiều") : (meridan = "sáng")
		@input = VietnameseSpeaker.timestandard(year,month,day,hour,min,sec,meridan)
		@db_instance = DBExec.new
		@speaker = SoundCutter.new
	end

	def action
		@db_instance.create_db
		arr = get_system_time_in_telex

		arr.each_with_index {|txt, i|
			i - 1 < 0 ? previous_word = nil : previous_word = arr[i-1]
			current_word = txt
			i + 1 < arr.length ? next_word = arr[i+1] : next_word = nil

			file, occur_from, occur_to = @db_instance.query_db(previous_word, current_word, next_word)
			@speaker.create_snippet_then_play(file, occur_from, occur_to)
		}
	end

	def get_system_time_in_telex
		# will be an array
		@input.split(" ").map {|item| item.get_converted_prefix}
	end

end

class DBExec
	DBNAME = "speech.db"
	TABLENAME = "speech_patterns"

	def initialize
		@alignment = File.open(File.join("mlf", "aligned.mlf"))
		@db = SQLite3::Database.new DBNAME
	end

	def data_existed?
		count = @db.execute("select count(1) from #{TABLENAME}").first.first
		if count > 0
			return true
		end
		return false
	rescue
		return false
	end

	def create_db
		return if data_existed?
		create_schema
		save_alignment_info
	end

	def create_schema
		@db.execute <<-SQL
			CREATE TABLE IF NOT EXISTS #{TABLENAME} 
			(
				filename text,
				previous_word text,
				word text,
				next_word text,
				occur_from text,
				occur_to text
			)
		SQL
	end

	def save_alignment_info
		@filename = nil
		@word = nil
		@next_word = nil
		@previous_word = nil
		@occur_from = nil
		@occur_to = nil

		@alignment.each do |line|
			line.chomp!

			next if line == '#!MLF!#' ||
						  line == "."

			linefeed = line.split(" ")

			next if linefeed.last == "SENT-END" && @word == nil

			if linefeed.size == 1
				@filename = linefeed.first.gsub(".lab", ".wav").gsub(/^"|"$/, '')
				@word = nil
				@next_word = nil
				@previous_word = nil
				@occur_from = nil
				@occur_to = nil
				next
			end

			if linefeed.last == "SENT-END" && @word
				@occur_to = linefeed.first
				@next_word = nil
				insert_speech_to_db(@filename, @word, @next_word, @previous_word, @occur_from, @occur_to)
				@previous_word = @word
				next
			end

			if linefeed.size == 4
				if @word
					@next_word = linefeed.last
					@occur_to = linefeed.first
					insert_speech_to_db(@filename, @word, @next_word, @previous_word, @occur_from, @occur_to)
					@previous_word = @word
				end

				@word = linefeed.last
				@occur_from = linefeed.first
			end

		end
	end

	def query_db(previous_word, word, next_word)
		raise "DB is not found" if !File.exists? DBNAME

		# query 3 tu truoc
		result = @db.execute(
			"SELECT filename, occur_from, occur_to 
			FROM #{TABLENAME}
			WHERE previous_word = ? AND word = ? AND next_word = ?
			LIMIT 1",
			[previous_word.to_s, word.to_s, next_word.to_s]
		).first

		# query tu dung truoc va tu hien tai
		result = @db.execute(
			"SELECT filename, occur_from, occur_to 
			FROM #{TABLENAME}
			WHERE previous_word = ? AND word = ?
			LIMIT 1",
			[previous_word.to_s, word.to_s]
		).first unless result.present?

		# query tu dung sau va tu hien tai
		result = @db.execute(
			"SELECT filename, occur_from, occur_to 
			FROM #{TABLENAME}
			WHERE word = ? AND next_word = ?
			LIMIT 1",
			[word.to_s, next_word.to_s]
		).first unless result.present?

		# query chi mot tu khong quan tam dung truoc hay dung sau
		result = @db.execute(
			"SELECT filename, occur_from, occur_to 
			FROM #{TABLENAME}
			WHERE word = ?
			LIMIT 1",
			[word.to_s]
		).first unless result.present?

		raise "No word found in aligned.mlf: #{word.to_s}" unless result.present?

		return result
	end

	def insert_speech_to_db(filename, word, next_word, previous_word, occur_from, occur_to)
		# puts "Item: #{filename} |#{previous_word}| |#{word}| |#{next_word}| #{occur_from} #{occur_to}"

		@db.execute(
			"INSERT INTO #{TABLENAME} (filename, previous_word, word, next_word, occur_from, occur_to)
			VALUES (?, ?, ?, ?, ?, ?)",
			[filename.to_s, previous_word.to_s, word.to_s, next_word.to_s, occur_from.to_s, occur_to.to_s]
		)
	end
end

class VietnameseSpeaker
	HASH = {
		1 => "một",
		2 => "hai",
		3 => "ba",
		4 => "bốn",
		5 => "năm",
		6 => "sáu",
		7 => "bảy",
		8 => "tám",
		9 => "chín",
		0 => "không"
	}

	def self.timestandard(year, month, day, hour, min, sec, meridan)
		return ["bây giờ là",
						"#{self.numstandard(hour)} giờ",
						"#{self.numstandard(min)} phút",
						"#{self.numstandard(sec)} giây",
						"#{meridan}",
						"ngày #{self.numstandard(day)}",
						"tháng #{self.numstandard(month)}",
						"năm #{self.numstandard(year)}"
						].join(" ")
	end

	def self.numstandard(int, odd = nil)
		# 2015 = hai nghin khong tram muoi lam
		# return if over 9999
		raise "DayTime number is too high: #{int}" if int > 9999

		if int < 100
			unit = int % 10
			tenth = int / 10

			if odd && tenth == 0 
				return "lẻ " + HASH[unit]
			end

			if unit == 0
				case tenth
				when 0 
					return HASH[tenth]
				when 1
					return "mười"
				else
					return HASH[tenth] + " mươi"
				end
			end

			if unit == 5
				case tenth
				when 0
					return HASH[unit]
				when 1
					return "mười lăm"
				else
					return HASH[tenth] + " lăm"
				end
			end

			if tenth == 1
				return "mười " + HASH[unit]
			end

			if tenth == 0
				return HASH[unit]
			end

			return [HASH[tenth], HASH[unit]].join(" ")
		elsif int < 1000
			# hundred
			hundredth = int / 100
			the_rest = int % 100
			return [HASH[hundredth], "trăm", numstandard(the_rest, true)].join(" ")
		elsif int < 10000
			# thousand
			thousandth = int / 1000
			the_rest = int % 1000
			return [HASH[thousandth], "nghìn", numstandard(the_rest, true)].join(" ")
		end
	end
end

class SoundCutter
	# increase latency between words | default 0
	SHORT_PAUSE_BUFFER = 0.03

	def initialize
		puts "Chon thiet bi playback truoc khi phat ra am thanh"
		@output = AudioPlayback::Device::Output.gets
		@os_temp_dir = Dir.tmpdir()
	end

	def create_snippet_then_play(file, occur_from, occur_to)
		first_seen = occur_from.to_i / 10_000_000.to_f
		last_seen = occur_to.to_i / 10_000_000.to_f + SHORT_PAUSE_BUFFER

		duration = last_seen - first_seen

		sound_original_comp = file
		sound_original_extn = File.extname sound_original_comp
		# grab the base filename for later
		sound_original_name = File.basename sound_original_comp, sound_original_extn
		Sound.open(sound_original_comp) do |snd|
			info = snd.info

			# pick first_seen as starting point in the file
			snip_time_begin = first_seen

			# create a buffer as big as the snippet
			bytes_to_read = (info.samplerate * duration).to_i

			buf = Buffer.new("float", bytes_to_read, info.channels)
			# seek to where the snippet begins and grab the audio

			snd.seek(info.samplerate * snip_time_begin)
			snd.read(buf, bytes_to_read)

			# create new file's name from original to tmp dir
			sndsnip_name = File.join(@os_temp_dir, sound_original_name + "_snippet.wav")

			# write the new snippet to a file
			out = Sound.open(sndsnip_name, "w", info.clone)
			out.write(buf)

			# play snippet
			@playback = AudioPlayback.play(sndsnip_name, :output_device => @output)
			@playback.block
		end
	end
end