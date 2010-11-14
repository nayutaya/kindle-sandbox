#! ruby -Ku

require "open-uri"
require "uri"
require "cgi"
require "rubygems"
require "log4r"
require "nokogiri"

$: << File.join(File.dirname(__FILE__), "lib")
require "http/factory"
require "http/message_pack_store"

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

def get_canonical_url(src)
  doc = Nokogiri.HTML(src)
  url = doc.xpath("/html/head/link[@rel='canonical']").first[:href]
  return url
end

def parse_query(query)
  return query.split("&").
    map { |pair| raise unless /^(.+?)=(.+?)$/ =~ pair; [$1, $2] }.
    map { |key, value| [CGI.unescape(key), CGI.unescape(value)] }.
    inject({}) { |memo, (key, value)| memo[key] = value; memo }
end


logger = create_logger
http   = create_http_client(logger)

url = "http://slashdot.jp/hardware/10/11/14/0416243.shtml"
src = http.get(url)
p url2 = get_canonical_url(src)
#src2 = http.get(url2)

p uri = URI.parse(url2)
params = parse_query(uri.query)

exit

params2 = {
  "threshold"   => "1",
  "mode"        => "nested",
  "commentsort" => "0",
}
p params

params3 = params.merge(params2)

p query = params3.sort_by { |key, value| key }.
  map { |key, value| [CGI.escape(key), CGI.escape(value)] }.
  map { |key, value|  "#{key}=#{value}" }.
  join("&")

uri.query = query
p url4 = uri.to_s
p src4 = http.get(url4)
File.open("tmp.html", "wb") { |file| file.write(src4) }
