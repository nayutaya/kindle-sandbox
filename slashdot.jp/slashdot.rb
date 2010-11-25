#! ruby -Ku
# coding: utf-8

require "pp"
require "rubygems"
require "log4r"

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

require "cgi"
require "uri"
require "nokogiri"

module Slashdot
  module Article
    def self.get_canonical_url(http, url)
      src = http.get(url)
      doc = Nokogiri.HTML(src)
      return doc.xpath("/html/head/link[@rel='canonical']").first[:href]
    end

    def self.get_commented_url(url)
      return self.merge_query(url,
        "threshold"   => "1",      # 閾値: 1
        "mode"        => "nested", # ネストする
        "commentsort" => "0")      # 古い順
    end

    def self.parse_query(query)
      return query.split("&").
        map { |pair| raise unless /^(.+?)=(.+?)$/ =~ pair; [$1, $2] }.
        map { |key, value| [CGI.unescape(key), CGI.unescape(value)] }.
        inject({}) { |memo, (key, value)| memo[key] = value; memo }
    end

    def self.build_query(params)
      return params.
        sort_by { |key, value| key }.
        map { |key, value| [CGI.escape(key), CGI.escape(value)] }.
        map { |key, value|  "#{key}=#{value}" }.
        join("&")
    end

    def self.merge_query(url, params)
      uri = URI.parse(url)
      uri.query = self.build_query(self.parse_query(uri.query).merge(params))
      return uri.to_s
    end
  end
end

require "article_parser"
require "article_formatter"



url = "http://slashdot.jp/it/article.pl?sid=10/09/06/2337200"
#url = "http://slashdot.jp/interview/06/01/12/0510208.shtml"

p canonical_url = Slashdot::Article.get_canonical_url(http, url)
p commented_url = Slashdot::Article.get_commented_url(canonical_url)

src = http.get(commented_url)

require "pp"
pp article = Slashdot::ArticleParser.extract(src, url)

xhtml = Slashdot::ArticleFormatter.format(article)

puts "---"
puts Slashdot::ArticleFormatter.format_comments(article["comments"])


File.open("out.html", "wb") { |file|
  file.write(xhtml)
}
