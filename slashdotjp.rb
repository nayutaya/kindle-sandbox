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

def build_query(params)
  return params.
    sort_by { |key, value| key }.
    map { |key, value| [CGI.escape(key), CGI.escape(value)] }.
    map { |key, value|  "#{key}=#{value}" }.
    join("&")
end

def merge_query(url, params)
  uri = URI.parse(url)
  uri.query = build_query(parse_query(uri.query).merge(params))
  return uri.to_s
end

def remove_unnecessary_elements(doc)
  doc.xpath("//comment()").remove
  doc.xpath("//script").remove
  doc.xpath("//noscript").remove
  doc.xpath("//text()").
    select { |node| node.to_s.strip.empty? }.
    each   { |node| node.remove }
end

def extract_information(doc)
  details = doc.xpath("//*[@id='articles']//div[@class='details']/node()").map { |node|
    case
    when node.text?                         then node.text.gsub(/\s+/, " ").strip
    when node.element? && node.name == "a"  then node.text.strip
    when node.element? && node.name == "br" then "\n"
    else raise("unexcepted node")
    end
  }.join("")

  return {
    :title           => doc.xpath("//*[@id='articles']//div[@class='title']/h3/a/text()").text.strip,
    :published       => details.split(/\n/)[0],
    :department      => details.split(/\n/)[1],
    :body_element    => doc.xpath("//*[@id='articles']//div[@class='intro']"),
    :comment_element => doc.xpath("//*[@id='commentlisting']"),
  }
end

def remove_unnecessary_comment_elements(doc)
  doc.xpath("//*[@id='roothiddens']").remove
  doc.xpath("//*[@id='commentlisting']//div[@class='commentstatus']").remove
  doc.xpath("//*[@id='commentlisting']//div[@class='commentSub']").remove
  doc.xpath("//*[@id='commentlisting']//a[@class='user_journal_display']").each { |node| node.parent.remove }
end

def adjust_comment_title_elements(doc)
  doc.xpath("//*[@id='commentlisting']//h4/a").each { |node|
    text = node.text.strip
    node.replace(Nokogiri::XML::Text.new(text, doc))
  }
  doc.xpath("//*[@id='commentlisting']//h4/span").each { |node|
    text = node.text.strip
    elem = Nokogiri::XML::Element.new("span", doc)
    elem.add_child(Nokogiri::XML::Text.new(text, doc))
    node.replace(elem)
  }
  doc.xpath("//*[@id='commentlisting']//h4").each { |node|
    node.children.each { |child|
      node.parent.add_child(child)
    }
    node.remove
  }
end

def adjust_comment_body_elements(doc)
  doc.xpath("//*[@id='commentlisting']//div[@class='details']//a").each { |node|
    text = node.text.strip
    node.replace(Nokogiri::XML::Text.new(text, doc))
  }
  doc.xpath("//*[@id='commentlisting']//li/b/a").each { |node|
    text = node.text.strip
    node.replace(Nokogiri::XML::Text.new(text, doc))
  }
end

def remove_id_attributes(doc)
  doc.xpath("//*").each { |node|
    node.remove_attribute("id")
  }
end


logger = create_logger
http   = create_http_client(logger)

url1 = "http://slashdot.jp/hardware/10/11/14/0416243.shtml"
src1 = http.get(url1)
url2 = get_canonical_url(src1)
url3 = merge_query(url2,
  "threshold"   => "1",      # 閾値: 1
  "mode"        => "nested", # ネストする
  "commentsort" => "0")      # 古い順
src3 = http.get(url3)
#File.open("tmp.html", "wb") { |file| file.write(src3) }

doc = Nokogiri.HTML(src3)

remove_unnecessary_elements(doc)
remove_unnecessary_comment_elements(doc)
adjust_comment_title_elements(doc)
adjust_comment_body_elements(doc)
info = extract_information(doc)
p info
remove_id_attributes(doc)


File.open("out.html", "wb") { |file|
  file.puts("<html><body>")
  file.puts(info[:comment_element].to_html)
#  puts(comments.to_html)
  file.puts("</body></html>")
}
