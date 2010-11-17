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

  def self.extract_title(doc)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    return headline.xpath('./h1[1]/text()').text.strip
  end

  def self.extract_published(doc)
    headline = doc.xpath('//*[@id="HeadLine"]').first
    return headline.xpath('./div[@class="Utility"]/p/text()').text.strip
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
