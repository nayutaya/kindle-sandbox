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

def extract_title(src)
  doc = Nokogiri.HTML(src)
  return doc.xpath('//*[@id="articles"]//div[@class="title"]/h3/a/text()').text.strip
end

def extract_published_time(src)
  doc = Nokogiri.HTML(src)
  details = doc.xpath('//*[@id="articles"]//div[@class="details"]').text.strip
  raise unless /(\d+)年(\d+)月(\d+)日 (\d+)時(\d+)分の掲載/ =~ details
  return Time.local($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i)
end

def extract_editor(src)
  doc = Nokogiri.HTML(src)
  return doc.xpath('//*[@id="articles"]//div[@class="details"]/a/text()').text.strip
end

def extract_department(src)
  doc = Nokogiri.HTML(src)
  details = doc.xpath('//*[@id="articles"]//div[@class="details"]').text.strip
  return details.split(/\s+/).last
end

def extract_body(src)
  doc = Nokogiri.HTML(src)

  # 全体の不要な要素を削除
  doc.xpath("//comment()").remove
  doc.xpath("//script").remove
  doc.xpath("//noscript").remove
  doc.xpath("//text()").
    select { |node| node.text.strip.empty? }.
    each   { |node| node.remove }

  intro = doc.xpath('//*[@id="articles"]//div[@class="intro"]').first
  intro.remove_attribute("class")
  full = doc.xpath('//*[@id="articles"]//div[@class="full"]').first
  full.remove_attribute("class") if full

  body  = intro.to_xml(:indent => 0, :encoding => "UTF-8")
  body += full.to_xml(:indent => 0, :encoding => "UTF-8") if full

  return body
end

def extract_comment(src)
  doc = Nokogiri.HTML(src)

  # 全体の不要な要素を削除
  doc.xpath("//comment()").remove
  doc.xpath("//script").remove
  doc.xpath("//noscript").remove
  doc.xpath("//text()").
    select { |node| node.text.strip.empty? }.
    each   { |node| node.remove }

  comments = doc.xpath('//*[@id="commentlisting"]')
  # 不要なli要素を削除
  comments.xpath('./li[@class="hide"]').remove
  # [コメントを書く]、[親コメント]などのリンクを削除
  comments.xpath('.//span[@class="nbutton"]').remove
  # [n 個のコメント が現在のしきい値以下です。]を削除
  comments.xpath('./li/b').each { |item| item.parent.remove }

  comments.xpath('./li').each { |item|
puts "---"
#p item
p title    = item.xpath('./div/div/div[@class="title"]/h4/a/text()').text.strip
p score    = item.xpath('./div/div/div[@class="title"]/h4/span//text()').text.strip.slice(1..-2)
p username = item.xpath('./div/div/div[@class="details"]//text()').first.text.strip
p otherdetails = item.xpath('./div/div/div[@class="details"]/span[@class="otherdetails"]/text()').text.strip
  raise unless /(\d+)年(\d+)月(\d+)日 (\d+)時(\d+)分/ =~ otherdetails
p time = Time.local($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i)
puts body = item.xpath('./div/div[@class="commentBody"]/div').to_xml(:indent => 0, :encoding => "UTF-8")

  }

  return comments.to_xml(:indent => 0, :encoding => "UTF-8")
end




url = "http://slashdot.jp/it/article.pl?sid=10/09/06/2337200"
#url = "http://slashdot.jp/interview/06/01/12/0510208.shtml"

p canonical_url = Slashdot::Article.get_canonical_url(http, url)
p commented_url = Slashdot::Article.get_commented_url(canonical_url)

src = http.get(commented_url)

p title          = extract_title(src)
p published_time = extract_published_time(src)
p editor         = extract_editor(src)
p department     = extract_department(src)
puts "---"
puts body           = extract_body(src)
puts "---"
puts comment        = extract_comment(src)

File.open("out.html", "wb") { |file|
  file.write(src)
}
