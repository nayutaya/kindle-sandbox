# coding: utf-8

require "uri"
require "rubygems"
require "nokogiri"

module AsahiCom
  module ArticlePageParser
    def self.extract_title(src)
      doc = Nokogiri.HTML(src)
      return doc.xpath('//*[@id="HeadLine"]/h1[1]/text()').text.strip
    end

    def self.extract_published_time(src)
      doc  = Nokogiri.HTML(src)
      time = doc.xpath('//*[@id="HeadLine"]/div[@class="Utility"]/p[1]/text()').text.strip
      raise("invalid time") unless /\A(\d+)年(\d+)月(\d+)日(\d+)時(\d+)分\z/ =~ time
      return Time.local($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i)
    end
  end
end
