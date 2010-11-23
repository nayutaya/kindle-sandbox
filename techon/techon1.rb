#! ruby -Ku
# coding: utf-8

require "rubygems"
require "log4r"

$: << File.join(File.dirname(__FILE__), "..", "lib")
require "http/factory"
require "http/message_pack_store"

require "techon"

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
url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101116/187415/?ref=rss"
url1 = "http://techon.nikkeibp.co.jp/article/TOPCOL/20101115/187385/?ref=rss"
url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101116/187442/?ref=rss"
src1 = http.get(url1)
#puts src1

require "pp"


puts "---"
pp title = TechOn::ArticlePageParser.extract_title(src1)

puts "---"
pp published_date = TechOn::ArticlePageParser.extract_published_date(src1)

puts "---"
pp author = TechOn::ArticlePageParser.extract_author(src1)

puts "---"
pp images = TechOn::ArticlePageParser.extract_images(src1, url1)

puts "---"
pp body_html = TechOn::ArticlePageParser.extract_body_html(src1, url1)

File.open("out.html", "wb") { |file|
  file.puts(body_html)
}
