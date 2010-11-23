#! ruby -Ku
# coding: utf-8

require "pp"
require "rubygems"
require "log4r"

$: << File.join(File.dirname(__FILE__), "..", "lib")
require "http/factory"
require "http/message_pack_store"

require "article"

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
#puts src1




article = TechOn::Article.get(http, url1)

puts "---"
pp article

File.open("out.html", "wb") { |file|
  file.puts(article["file"])
}

article["images"].each { |image|
  File.open(image["filename"], "wb") { |file|
    file.write(image["file"])
  }
}
