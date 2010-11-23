#! ruby -Ku
# coding: utf-8

require "uri"
require "rubygems"
require "log4r"
require "nokogiri"

$: << File.join(File.dirname(__FILE__), "..", "lib")
require "http/factory"
require "http/message_pack_store"

def create_http_client(logger)
  store = HttpClient::MessagePackStore.new(File.join(File.dirname(__FILE__), "..", "cache"))
  return HttpClient::Factory.create_client(
    :logger   => logger,
    :interval => 1.0,
    :store    => store)
end

def create_logger
  formatter = Log4r::PatternFormatter.new(:pattern => "%d [%l] %M", :date_pattern => "%H:%M:%S")
  outputter = Log4r::StderrOutputter.new("", :formatter => formatter)
  logger = Log4r::Logger.new($0)
  logger.add(outputter)
  logger.level = Log4r::DEBUG
  return logger
end


logger = create_logger
http   = create_http_client(logger)

url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101111/187322/?ref=rss"
src1 = http.get(url1)
#puts src1

doc = Nokogiri.HTML(src1)

body = doc.xpath('//*[@id="kiji"]')

body.xpath('./div[@class="bpbox_right"]/div[@class="bpimage_set"]').each { |div|
  puts "---"
  #p div
  p path = div.xpath('./div[@class="bpimage_image"]//img').first[:src]
  p url  = URI.join(url1, path).to_s
  p caption = div.xpath('./div[@class="bpimage_caption"]//text()').text.strip
}


=begin
File.open("out.html", "wb") { |file|
  file.puts(body.to_html)
}
=end
