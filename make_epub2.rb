#! ruby -Ku
# coding: utf-8

require "cgi"
require "erb"
require "yaml"
require "rubygems"
require "uuid"
require "zip/zip"

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

logger = create_logger
http   = create_http_client(logger)

manifest = YAML.load_file("asahi1.yaml")
uuid      = manifest["uuid"]      || UUID.new.generate
title     = manifest["title"]     || Time.now.strftime("%Y-%m-%d %H:%M:%S")
author    = manifest["author"]    || "Unknown"
publisher = manifest["publisher"] || nil

p manifest
exit

article = AsahiCom.new(:url => "http://www.asahi.com/national/update/1116/TKY201011160485.html", :http => http).parse
asahi_com_xhtml_erb = File.open("template/asahi_com.xhtml.erb",     "rb") { |file| file.read }

env = Object.new.instance_eval {
  @title = CGI.escapeHTML(article["title"])
  @body  = article["body_html"]
  binding
}
asahi_com_xhtml = ERB.new(asahi_com_xhtml_erb, nil, "-").result(env)




mimetype        = File.open("template/mimetype",        "rb") { |file| file.read }
container_xml   = File.open("template/container.xml",   "rb") { |file| file.read }
content_opf_erb = File.open("template/content.opf.erb", "rb") { |file| file.read }
toc_ncx_erb     = File.open("template/toc.ncx.erb",     "rb") { |file| file.read }



env = Object.new.instance_eval {
  @uuid      = CGI.escapeHTML(uuid)
  @title     = CGI.escapeHTML(title)
  @author    = CGI.escapeHTML(author)
  @publisher = CGI.escapeHTML(publisher)
  @items     = [
    {:id => "text1", :href => "text/text1.xhtml", :type => "application/xhtml+xml"},
  ]
  @itemrefs  = [
    {:idref => "text1"},
  ]
  binding
}

content_opf = ERB.new(content_opf_erb, nil, "-").result(env)

=begin
  <item id="image1" href="images/image1.png" media-type="image/png"/>
  <item id="style1" href="styles/style1.css" media-type="text/css"/>
=end

env = Object.new.instance_eval {
  @uuid      = CGI.escapeHTML(uuid)
  @title     = CGI.escapeHTML(title)
  @author    = CGI.escapeHTML(author)
  @nav_points = [
    {:label_text => "contents", :content_src => "text/text1.xhtml"},
  ]
  binding
}
toc_ncx = ERB.new(toc_ncx_erb, nil, "-").result(env)

filename = "epub2.epub"
File.unlink(filename) if File.exist?(filename)
Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) { |zip|
  # FIXME: mimetypeは無圧縮でなければならない
  # FIXME: mimetypeはアーカイブの先頭に現れなければならない
  zip.get_output_stream("mimetype") { |io| io.write(mimetype) }
  zip.get_output_stream("META-INF/container.xml") { |io| io.write(container_xml) }
  zip.get_output_stream("OEBPS/content.opf") { |io| io.write(content_opf) }
  zip.get_output_stream("OEBPS/toc.ncx") { |io| io.write(toc_ncx) }
  zip.get_output_stream("OEBPS/text/text1.xhtml") { |io| io.write(asahi_com_xhtml) }
}
