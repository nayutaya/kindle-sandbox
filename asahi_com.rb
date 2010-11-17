#! ruby -Ku
# coding: utf-8

require "uri"
require "rubygems"
require "log4r"
require "nokogiri"

$: << File.join(File.dirname(__FILE__), "lib")
require "http/factory"
require "http/message_pack_store"
require "lib/asahi_com"

def create_http_client(logger)
  store = HttpClient::MessagePackStore.new(File.join(File.dirname(__FILE__), "cache"))
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

def parse(src, url)
  doc = Nokogiri.HTML(src)

  $article.class.remove_unnecessary_elements(doc)

  return {
    "title"     => $article.class.extract_title(doc),
    "published" => $article.class.extract_published(doc),
    "images"    => $article.class.extract_images(doc, url),
    "body_html" => $article.class.extract_body_element(doc).to_xml(:indent => 0, :encoding => "UTF-8")
  }
end

def main(argv)
  logger = create_logger
  http   = create_http_client(logger)

  original_url  = argv[0]

  $article = AsahiCom.new(
    :url    => original_url,
    :http   => http,
    :logger => logger)

  canonical_url = $article.get_canonical_url
  canonical_src = $article.read_canonical_url

  parsed = parse(canonical_src, canonical_url)
  require "pp"
  pp parsed
end

main(ARGV)
