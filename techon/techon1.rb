#! ruby -Ku
# coding: utf-8

require "pp"
require "rubygems"
require "log4r"

$: << File.join(File.dirname(__FILE__), "..", "lib")
require "http/factory"
require "http/message_pack_store"

require "article_page_parser"

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


require "erb"

filename = File.join(File.dirname(__FILE__), "template.xhtml.erb")
template = File.open(filename, "rb") { |file| file.read }

env = Object.new
env.extend(ERB::Util)
env.instance_eval {
  @url            = "http://foo.bar.baz/"
  @title          = "てすと"
  @published_time = Time.now
  @author         = "さくしゃ"
  @images         = []
  @body           = "foo <b>bar</b> baz"
}
erb = ERB.new(template, nil, "-")
erb.filename = filename
xhtml = erb.result(env.instance_eval { binding })

puts xhtml

exit(1)


logger = create_logger
http   = create_http_client(logger)

url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101111/187322/?ref=rss"
url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101116/187415/?ref=rss"
url1 = "http://techon.nikkeibp.co.jp/article/TOPCOL/20101115/187385/?ref=rss"
url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101116/187442/?ref=rss"
src1 = http.get(url1)
#puts src1


puts "---"
pp article = TechOn::ArticlePageParser.extract(src1, url1)

File.open("out.html", "wb") { |file|
  file.puts(article["body"])
}
