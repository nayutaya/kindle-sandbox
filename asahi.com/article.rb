# coding: utf-8

require "digest/md5"
require "rubygems"
require "nokogiri"
require File.join(File.dirname(__FILE__), "article_parser")
require File.join(File.dirname(__FILE__), "article_formatter")

module AsahiCom
  module Article
    def self.get(http, url)
      canonical_url = self.get_canonical_url(http, url)
      page_urls     = self.get_multiple_page_urls(http, canonical_url)

      articles = page_urls.map { |page_url|
        src = http.get(page_url)
        ArticleParser.extract(src, page_url)
      }

      (articles[1..-1] || []).each { |article|
        articles[0]["body"] << "<hr/>" << article["body"]
      }

      article = articles.first
      article["images"].each { |image|
        filename, type =
          case image["url"]
          when /\.jpg$/i then [Digest::MD5.hexdigest(image["url"]) + ".jpg", "image/jpeg"]
          else raise("unknown type")
          end
        image["file"]     = http.get(image["url"])
        image["filename"] = filename
        image["type"]     = type
      }

      article["file"]     = ArticleFormatter.format(article)
      article["filename"] = Digest::MD5.hexdigest(article["url"]) + ".xhtml"
      article["type"]     = "application/xhtml+xml"

      return article
    end

    def self.get_canonical_url(http, url)
      src = http.get(url)
      doc = Nokogiri.HTML(src)
      return doc.xpath("/html/head/link[@rel='canonical']").first[:href]
    end

    def self.get_multiple_page_urls(http, url)
      src = http.get(url)
      doc = Nokogiri.HTML(src)

      urls = [url]
      doc.xpath('//*[@id="HeadLine"]/div/ol/li').each { |item|
        anchor = item.xpath('./a').first
        path = anchor[:href] if anchor
        url  = URI.join(url, path).to_s if path
        urls << url if url
      }

      return urls.uniq
    end
  end
end
