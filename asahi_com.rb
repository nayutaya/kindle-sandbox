#! ruby -Ku
# coding: utf-8

require "uri"
require "rubygems"
require "log4r"

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

def main(argv)
  logger = create_logger
  http   = create_http_client(logger)

  original_url  = argv[0]

  article = AsahiCom.new(
    :url    => original_url,
    :http   => http,
    :logger => logger)

  parsed = article.parse

  require "pp"
  pp parsed
end

main(ARGV)
