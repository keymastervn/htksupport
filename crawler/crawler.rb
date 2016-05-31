require 'nokogiri'
require 'open-uri'
require 'rubygems'
require '../string_helper'

SOURCE = [
	"http://vnexpress.net",
	"http://tuoitre.vn",
	"http://news.zing.vn",
	"http://vietnamnet.vn",
	"http://kenh14.vn"
]

HREF_SKIP_SUFFIX = [
	".img", ".imfg", ".jpeg", ".jpg", ".png", ".rss",
	".css", ".js", "javascript", "document", "mailto:", "e.vnexpress.net",
	"video", "facebook", "google", "twitter", "adv", "pdf", "contact", "lienhe", "lien-he"
]

SENTENCE_SKIP_NOT_INCLUDE = [
	"@", "javascript", "Javascript", "Facebook", "Google", "Twitter", "FB", "facebook", "google",
	"®", "vnexpress", "VnExpress", "Tuoitre", "tuoitre", "kenh14", "zing", "vietnamnet",
	"browser", "-", "\"", "\'", "\n", "\(", "\)", "\/", "%", '“', '”', "&", "$", ":", "_"
]


$output = "crawl_result.txt"
SENTENCE_MIN_LENGTH = 25
MAXSIZE = 200_000_000 # 100MB of text
MAXSTACKCOUNT = 2000

$dict = {}
$new_word = []

$result = File.open($output, "w:UTF-8")

# In order to automatically add new word from the internet to Dict 
# (for unit standard, Nouns, strange phrases)
def prefetch_dict
	File.open(File.join("..", "dict", "vndict.txt"), "r").each do |line|
		$dict[line] = true
	end
end

def add_word_to_dict
	# TODO: replace new_dict.txt by vndict.dic
	f = File.open(File.join("..", "dict", "new_dict.dic"), "w+")
	$new_word.each {|word|
		next if word =~ /\d/ 
		f.write(word.to_telex)
	}
	f.close
end

class Crawler

	def initialize(link)
		@topsite = link
		@list_link = []
		@mutex = Mutex.new
		@queue = []
		@crawled_sites = {}
		@crawled_sentences = {}

		start_crawler
		start_fetchers
	end

	def queue
		@mutex.synchronize do
			@queue
		end
	end

	def start_crawler
		queue.push(@topsite)
	end

	def start_fetchers
		@fetcher_threads = []

		3.times {
			@fetcher_threads << Thread.new {
				loop do
					if url = queue.shift
						crawl(*url) if @crawled_sites[*url].nil?
					end

					next unless queue.empty?
					sleep 0.5
				end
			}
		}
		@fetcher_threads.each{|t| t.join}
	end

	def crawl(link)
		puts "crawl: #{link}"

		exit(true) if File.size($output) > MAXSIZE

		not_crawl_two_times(link)

		begin
			page = Nokogiri::HTML(open(link))
		rescue
			return
		end

		$result.write(get_sentence(page).join("\n"))

		get_child_link(page).each{ |child_link|
			queue.push(child_link)
		}
	end

	def get_sentence(page)
		sentences = []
		page.css('p').collect {|l|
			line = l.children.to_s.gsub(/<\/?[^>]*>/, "") # Remove HTML tags
			sentences += line.squeeze(" ").squeeze(".").split(".").collect {|sentence| 
				sentence_sanitize(sentence)
			}
		}

		@mutex.synchronize do
			sentences.collect {|s| s if @crawled_sentences[s].nil? }
			sentences.each {|s| @crawled_sentences[s] = true }
		end

		sentences.delete_if {|s| s.nil? || s.empty? }
	end

	def not_crawl_two_times(link)
		@mutex.synchronize do 
			@crawled_sites[link] = true
		end
	end

	def get_child_link(page)
		get_all_link_from_page(page).delete_if {|link|
			link.nil? || @crawled_sites[link] ||
			HREF_SKIP_SUFFIX.any? {|s| link.include? s} || 
			 !SOURCE.any? {|site| link.start_with? site}
		}
	end

	def get_all_link_from_page(page)
		hrefs = page.css('a').map(&:attributes["href"])

		hrefs.collect {|href|
			full_href(href.attributes["href"].value) if href.attributes["href"].respond_to?(:value) && 
																									href.attributes["href"].value.is_valid_url
		}
	end

	def full_href(string)
		return File.join(@topsite, string) if string.is_category
		return string
	end

	def sentence_sanitize(string)
		return nil if string.length < SENTENCE_MIN_LENGTH ||
									string =~ /\d/ || SENTENCE_SKIP_NOT_INCLUDE.any? {|s| string.include? s}
		return string.gsub("?", " ").gsub(" ", " ").gsub(","," ").squeeze(" ").strip
	end
end

threads = []
SOURCE.each do |site|
	threads << Thread.new do
		Crawler.new(site)
	end
end

threads.map(&:join)