# coding: utf-8

require "digest/md5"
require File.join(File.dirname(__FILE__), "article_parser")
require File.join(File.dirname(__FILE__), "article_formatter")

module TechOn
  module Article
    def self.get(http, url)
      curl    = self.get_canonical_url(url)
      src     = http.get(curl)
      article = TechOn::ArticleParser.extract(src, curl)

      article["images"].each { |image|
        image["file"]     = http.get(image["url"])
        image["filename"] =
          case image["url"]
          when /\.jpg$/i then Digest::MD5.hexdigest(image["url"]) + ".jpg"
          else raise("unknown type")
          end
      }

      article["file"]     = TechOn::ArticleFormatter.format(article)
      article["filename"] = Digest::MD5.hexdigest(article["url"]) + ".xhtml"

      return article
    end

    def self.get_canonical_url(url)
      return $1 if /\A(.+)\?ref=rss\z/ =~ url
      return url
    end
  end
end
