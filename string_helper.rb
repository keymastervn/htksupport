require 'active_support/all'
require 'uri'

class String
	CHARMAPTELEX = {
		"Á" => "AS",
		"À" => "AF",
		"Ả" => "AR",
		"Ã" => "AX",
		"Ạ" => "AJ",
		"Ă" => "AW",
		"Ắ" => "AWS",
		"Ằ" => "AWF",
		"Ẳ" => "AWR",
		"Ẵ" => "AWX",
		"Ặ" => "AWJ",
		"Â" => "AA",
		"Ấ" => "AAS",
		"Ầ" => "AAF",
		"Ẩ" => "AAR",
		"Ẫ" => "AAX",
		"Ậ" => "AAJ",
		"Đ" => "DD",
		"É" => "ES",
		"È" => "EF",
		"Ẻ" => "ER",
		"Ẽ" => "EX",
		"Ẹ" => "EJ",
		"Ê" => "EE",
		"Ế" => "EES",
		"Ề" => "EEF",
		"Ể" => "EER",
		"Ễ" => "EEX",
		"Ệ" => "EEJ",
		"Í" => "IS",
		"Ì" => "IF",
		"Ỉ" => "IR",
		"Ĩ" => "IX",
		"Ị" => "IJ",
		"Ơ" => "OW",
		"Ó" => "OS",
		"Ò" => "OF",
		"Ỏ" => "OR",
		"Õ" => "OX",
		"Ọ" => "OJ",
		"Ô" => "OO",
		"Ố" => "OOS",
		"Ồ" => "OOF",
		"Ổ" => "OOR",
		"Ỗ" => "OOX",
		"Ộ" => "OOJ",
		"Ớ" => "OWS",
		"Ờ" => "OWF",
		"Ở" => "OWR",
		"Ỡ" => "OWX",
		"Ợ" => "OWJ",
		"Ư" => "UW",
		"Ú" => "US",
		"Ù" => "UF",
		"Ủ" => "UR",
		"Ũ" => "UX",
		"Ụ" => "UJ",
		"Ứ" => "UWS",
		"Ừ" => "UWF",
		"Ử" => "UWR",
		"Ữ" => "UWX",
		"Ự" => "UWJ",
		"Ý" => "YS",
		"Ỳ" => "YF",
		"Ỷ" => "YR",
		"Ỹ" => "YX",
		"Ỵ" => "YJ" 
	}
  # nGh nG gH cH pH kH tH nH tR qU 
  MULTICOSONANT = {
  	'G' => ['N'], 
  	'H' => ['G', 'C', 'P', 'K', 'T', 'N'],
  	'R' => ['T'],
  	'U' => ['Q']
  }

  def uni_downcase
  	self.mb_chars.downcase.wrapped_string
  end

  def uni_upcase
  	self.mb_chars.upcase.wrapped_string
  end

  def get_converted_suffix
  	suffix = []
		self.split("").each {|c|

			# unicode upcase
			c = c.mb_chars.upcase.wrapped_string
			if MULTICOSONANT.has_key?(c) && !suffix.empty?
				postword = suffix.last
				if MULTICOSONANT[c].include?(postword)
					suffix[-1] = postword + c.upcase 
				else
					suffix << c
				end

		  elsif !CHARMAPTELEX[c].nil?
				suffix << CHARMAPTELEX[c]
			else
				suffix << c
			end
		}
		# TR OW F I
		suffix = suffix.join(" ").downcase
		suffix
  end

  def get_converted_prefix
  	get_converted_suffix.tr('^A-Za-z0-9', '')
  end

	# to telex to do transform TRỜI to "TROWFI<tab>TR OW F I sp"
	def to_telex
		suffix = get_converted_suffix

		# TROWFI
		prefix = suffix.tr('^A-Za-z0-9', '')

		# TROWFI<tab>TR OW F I sp
		prefix + " " * (16-prefix.length) + suffix
	end

	def with_pause
		self + " sp"
	end

	def to_vni
		# TODO: implement when in need
	end

	# crawler check page is category or not
	def is_category
		self.start_with?("/")
	end

	def is_valid_url
		return true if self =~ URI::regexp || self.is_category
		return false
	end
end