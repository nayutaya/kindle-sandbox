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

articles = manifest["urls"].each_with_index.map { |url, index|
  article = AsahiCom.new(:url => url, :http => http).parse
  article.merge(
    "id"       => "text#{index + 1}",
    "filename" => "text/text#{index + 1}.xhtml")
}



mimetype        = File.open("template/mimetype",        "rb") { |file| file.read }
container_xml   = File.open("template/container.xml",   "rb") { |file| file.read }
content_opf_erb = File.open("template/content.opf.erb", "rb") { |file| file.read }
toc_ncx_erb     = File.open("template/toc.ncx.erb",     "rb") { |file| file.read }
asahi_com_xhtml_erb = File.open("template/asahi_com.xhtml.erb", "rb") { |file| file.read }
asahi_com_css   = File.open("template/asahi_com.css",   "rb") { |file| file.read }


env = Object.new.instance_eval {
  @uuid      = CGI.escapeHTML(uuid)
  @title     = CGI.escapeHTML(title)
  @author    = CGI.escapeHTML(author)
  @publisher = CGI.escapeHTML(publisher)
  @items     = articles.map { |article|
    {:id => article["id"], :href => article["filename"], :type => "application/xhtml+xml"}
  } + [
    {:id => "style1", :href => "styles/asahi_com.css", :type => "text/css"},
  ]
  @itemrefs  = articles.map { |article|
    {:idref => article["id"]}
  }
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
  @nav_points = articles.map { |article|
    {:label_text => article["title"], :content_src => article["filename"]}
  }
  binding
}
toc_ncx = ERB.new(toc_ncx_erb, nil, "-").result(env)

docs = articles.map { |article|
  env = Object.new.instance_eval {
    @title = CGI.escapeHTML(article["title"])
    @url   = CGI.escapeHTML(article["url"])
    @body  = article["body_html"]
    binding
  }
  {
    "filename" => "OEBPS/" + article["filename"],
    "xhtml"    => ERB.new(asahi_com_xhtml_erb, nil, "-").result(env),
  }
}

filename = "epub2.epub"
File.unlink(filename) if File.exist?(filename)
Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) { |zip|
  # FIXME: mimetypeは無圧縮でなければならない
  # FIXME: mimetypeはアーカイブの先頭に現れなければならない
  zip.get_output_stream("mimetype") { |io| io.write(mimetype) }
  zip.get_output_stream("META-INF/container.xml") { |io| io.write(container_xml) }
  zip.get_output_stream("OEBPS/content.opf") { |io| io.write(content_opf) }
  zip.get_output_stream("OEBPS/toc.ncx") { |io| io.write(toc_ncx) }
  docs.each { |doc|
    zip.get_output_stream(doc["filename"]) { |io| io.write(doc["xhtml"]) }
  }
  zip.get_output_stream("OEBPS/styles/asahi_com.css") { |io| io.write(asahi_com_css) }
}
