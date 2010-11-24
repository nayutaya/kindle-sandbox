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

url = "http://www.asahi.com/business/update/1124/TKY201011240065.html"
url = "http://www.asahi.com/business/update/1124/TKY201011240058.html"
src = http.get(url)

#p src

require "pp"
=begin
pp title = AsahiCom::ArticleParser.extract_title(src)
pp published_time = AsahiCom::ArticleParser.extract_published_time(src)
pp images = AsahiCom::ArticleParser.extract_images(src, url)
pp body   = AsahiCom::ArticleParser.extract_body(src)
=end
pp article = AsahiCom::ArticleParser.extract(src, url)
