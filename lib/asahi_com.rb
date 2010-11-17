# coding: utf-8

require "rubygems"
require "nokogiri"

class AsahiCom
  def initialize(options)
    @url    = options.delete(:url)    || raise(ArgumentError)
    @http   = options.delete(:http)   || raise(ArgumentError)
    @logger = options.delete(:logger) || raise(ArgumentError)
  end

  def self.extract_canonical_url(html)
    doc = Nokogiri.HTML(html)
    url = doc.xpath("/html/head/link[@rel='canonical']").first[:href]
    return url
  end

  def self.remove_unnecessary_elements(doc)
    doc.xpath("//comment()").remove
    doc.xpath("//script").remove
    doc.xpath("//noscript").remove
    doc.xpath("//text()").
      select { |node| node.text.strip.empty? }.
      each   { |node| node.remove }
  end

  def self.extract_title(doc)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    return headline.xpath('./h1[1]/text()').text.strip
  end

  def self.extract_published(doc)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    return headline.xpath('./div[@class="Utility"]/p/text()').text.strip
  end

  def self.extract_images(doc, url)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    return headline.xpath('.//div[@class="ThmbCol"]/p').map { |parag|
      path = parag.xpath('.//img').first[:src]
      {
        "url"     => URI.join(url, path).to_s,
        "caption" => parag.xpath('./small').text.strip,
      }
    }
  end

  def self.extract_body_element(doc)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    body     = headline.xpath('.//div[@class="BodyTxt"]').first
    # 本文のdiv要素をクリーンアップ
    body.remove_attribute("class")
    # 本文内のp要素をクリーンアップ
    body.xpath('.//p/text()').each { |node|
      text = node.text.strip.sub(/^　/, "")
      node.replace(Nokogiri::XML::Text.new(text, doc))
    }
    return body
  end

  def read_original_url
    @_original_html ||= @http.get(@url)
    return @_original_html
  end

  def get_canonical_url
    @_canonical_url ||= self.class.extract_canonical_url(self.read_original_url)
    return @_canonical_url
  end

  def read_canonical_url
    @_canonical_html ||= @http.get(self.get_canonical_url)
    return @_canonical_html
  end
end
