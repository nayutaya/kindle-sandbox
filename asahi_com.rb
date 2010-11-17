#! ruby -Ku
# coding: utf-8

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

  require "pp"

  pp AsahiCom.new(
    :url    => "http://www.asahi.com/national/update/1116/TKY201011160485.html",
    :http   => http).parse
  pp AsahiCom.new(
    :url    => "http://www.asahi.com/national/update/1115/OSK201011150139.html",
    :http   => http).parse
  pp AsahiCom.new(
    :url    => "http://www.asahi.com/national/update/1117/SEB201011170005.html",
    :http   => http).parse
end

main(ARGV)
