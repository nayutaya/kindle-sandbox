# coding: utf-8

require "digest/md5"
require "rubygems"
require "nokogiri"
require File.join(File.dirname(__FILE__), "article_parser")
require File.join(File.dirname(__FILE__), "article_formatter")

module AsahiCom
  module Article
    def self.get(http, url)
      curl    = self.get_canonical_url(http, url)
      src     = http.get(curl)
      article = AsahiCom::ArticleParser.extract(src, curl)

      article["images"].each { |image|
        image["file"]     = http.get(image["url"])
        image["filename"] =
          case image["url"]
          when /\.jpg$/i then Digest::MD5.hexdigest(image["url"]) + ".jpg"
          else raise("unknown type")
          end
      }

      article["file"]     = AsahiCom::ArticleFormatter.format(article)
      article["filename"] = Digest::MD5.hexdigest(article["url"]) + ".xhtml"

      return article
    end

    def self.get_canonical_url(http, url)
      src = http.get(url)
      doc = Nokogiri.HTML(src)
      return doc.xpath("/html/head/link[@rel='canonical']").first[:href]
    end
  end
end
