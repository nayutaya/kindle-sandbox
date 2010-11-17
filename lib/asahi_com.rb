# coding: utf-8

require "rubygems"
require "nokogiri"

class AsahiCom
  def initialize(options)
    @url    = options.delete(:url)    || raise(ArgumentError)
    @http   = options.delete(:http)   || raise(ArgumentError)
    @logger = options.delete(:logger) || raise(ArgumentError)
  end

  def self.get_canonical_url_from_html(html)
    doc = Nokogiri.HTML(html)
    url = doc.xpath("/html/head/link[@rel='canonical']").first[:href]
    return url
  end

  def get_canonical_url_from_url(url)
    html = @http.get(url)
    return self.class.get_canonical_url_from_html(html)
  end

end
