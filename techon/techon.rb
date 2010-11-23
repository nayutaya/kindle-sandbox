# coding: utf-8

require "uri"
require "rubygems"
require "nokogiri"

module TechOn
  module TechOn::ArticlePageParser
    def self.extract_title(src)
      doc   = Nokogiri.HTML(src)
      title = doc.xpath('//*[@id="kijiBox"]/h1/text()').text.strip
      return title
    end

    def self.extract_published_date(src)
      doc  = Nokogiri.HTML(src)
      date = doc.xpath('//*[@id="kijiBox"]/div[@class="topTitleMenu"]/div[@class="date"]/text()').text.strip
      return date
    end

    def self.extract_author(src)
      doc    = Nokogiri.HTML(src)
      author = doc.xpath('//*[@id="kijiBox"]/div[@class="topTitleMenu"]/div[@class="author"]/text()').text.strip
      return author
    end

    def self.extract_images(src, url)
      doc  = Nokogiri.HTML(src)
      divs = doc.xpath('//*[@id="kiji"]/div[@class="bpbox_right"]/div[@class="bpimage_set"]')
      return divs.map { |div|
        path    = div.xpath('./div[@class="bpimage_image"]//img').first[:src]
        url     = URI.join(url, path).to_s
        caption = div.xpath('./div[@class="bpimage_caption"]//text()').text.strip
        {"url" => url, "caption" => caption}
      }
    end

    def self.extract_body_html(src, url)
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
        path = anchor[:href].strip
        url  = URI.join(url, path).to_s
        anchor.set_attribute("href", url)
      }

      return body.to_xml(:indent => 0, :encoding => "UTF-8")
    end
  end
end
