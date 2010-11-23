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
url1 = "http://techon.nikkeibp.co.jp/article/NEWS/20101116/187415/?ref=rss"
src1 = http.get(url1)
#puts src1

def extract_title(src)
  doc   = Nokogiri.HTML(src)
  title = doc.xpath('//*[@id="kijiBox"]/h1/text()').text.strip
  return title
end

def extract_body_html(src, url)
  doc = Nokogiri.HTML(src)

  # 全体の不要な要素を削除
  doc.xpath("//comment()").remove
  doc.xpath("//script").remove
  doc.xpath("//noscript").remove
  doc.xpath("//text()").
    select { |node| node.text.strip.empty? }.
    each   { |node| node.remove }

  # 本文のdiv要素を取得
  body = doc.xpath('//div[@id="kiji"]').first
  # 本文の不要なid属性を削除
  body.remove_attribute("id")
  # 本文内の不要なdiv要素を削除
  body.xpath('./div[@class="bpbox_right"]').remove
  # 本文内のp要素をクリーンアップ
  body.xpath('.//p/text()').each { |node|
    text = node.text.strip.sub(/^　/, "")
    node.replace(Nokogiri::XML::Text.new(text, doc))
  }
  # 本文内の相対リンクをURLに置換
  body.xpath('.//a').each { |anchor|
    path = anchor[:href]
    url  = URI.join(url, path).to_s
    anchor.set_attribute("href", url)
  }

  return body.to_xml(:indent => 0, :encoding => "UTF-8")
end

def extract_images(src, url)
  doc  = Nokogiri.HTML(src)
  divs = doc.xpath('//*[@id="kiji"]/div[@class="bpbox_right"]/div[@class="bpimage_set"]')
  return divs.map { |div|
    path    = div.xpath('./div[@class="bpimage_image"]//img').first[:src]
    url     = URI.join(url, path).to_s
    caption = div.xpath('./div[@class="bpimage_caption"]//text()').text.strip
    {"url" => url, "caption" => caption}
  }
end


require "pp"


puts "---"
pp title = extract_title(src1)

puts "---"
pp images = extract_images(src1, url1)

puts "---"
pp body_html = extract_body_html(src1, url1)



File.open("out.html", "wb") { |file|
  file.puts(body_html)
}
