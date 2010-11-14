#! ruby -Ku

require "open-uri"
require "uri"
require "rubygems"
require "log4r"
require "nokogiri"

$: << File.join(File.dirname(__FILE__), "lib")
require "http/factory"
require "http/message_pack_store"

def create_logger
  formatter = Log4r::PatternFormatter.new(:pattern => "%d [%l] %M", :date_pattern => "%H:%M:%S")
  outputter = Log4r::StderrOutputter.new("", :formatter => formatter)
  logger = Log4r::Logger.new($0)
  logger.add(outputter)
  logger.level = Log4r::DEBUG
  return logger
end

def get_canonical_url(src)
  doc = Nokogiri.HTML(src)
  url = doc.xpath("/html/head/link[@rel='canonical']").first[:href]
  return url
end


logger = create_logger
http   = HttpClient::Factory.create_client(
  :logger   => logger,
  :interval => 2.0,
  :store    => HttpClient::MessagePackStore.new(File.join(File.dirname(__FILE__), "cache")))

url = "http://slashdot.jp/hardware/10/11/14/0416243.shtml"
src = http.get(url)
p url2 = get_canonical_url(src)
#src2 = http.get(url2)

p uri = URI.parse(url2)


