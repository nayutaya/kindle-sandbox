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
require "slashdot.jp/article"

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

manifest = YAML.load_file("slashdot.yaml")
uuid      = manifest["uuid"]      || UUID.new.generate
title     = manifest["title"]     || Time.now.strftime("%Y-%m-%d %H:%M:%S")
author    = manifest["author"]    || "Unknown"
publisher = manifest["publisher"] || nil
urls      = manifest["urls"].split(/\s+/)

articles = urls.each_with_index.map { |url, index|
  article = Slashdot::Article.get(http, url)
  article["id"] = "text#{index + 1}"
  article
}.sort_by { |article| article["published_time"] }


mimetype        = File.open("template/mimetype",        "rb") { |file| file.read }
container_xml   = File.open("template/container.xml",   "rb") { |file| file.read }
content_opf_erb = File.open("template/content.opf.erb", "rb") { |file| file.read }
toc_ncx_erb     = File.open("template/toc.ncx.erb",     "rb") { |file| file.read }
toc_xhtml_erb   = File.open("template/toc.xhtml.erb",   "rb") { |file| file.read }

opf_items = [
  {:id => "toc", :href => "toc.xhtml", :type => "application/xhtml+xml"},
]
articles.each { |article|
  opf_items << {:id => article["id"], :href => article["filename"], :type => article["type"]}
}

opf_itemrefs = [{:idref => "toc"}]
opf_itemrefs += articles.map { |article| {:idref => article["id"]} }

env = Object.new.instance_eval {
  @uuid      = CGI.escapeHTML(uuid)
  @title     = CGI.escapeHTML(title)
  @author    = CGI.escapeHTML(author)
  @publisher = CGI.escapeHTML(publisher)
  @items     = opf_items
  @itemrefs  = opf_itemrefs
  binding
}
content_opf = ERB.new(content_opf_erb, nil, "-").result(env)


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

env = Object.new.instance_eval {
  @articles = articles.map { |article|
    [CGI.escapeHTML(article["title"]), CGI.escapeHTML(article["filename"])]
  }
  binding
}
toc_xhtml = ERB.new(toc_xhtml_erb, nil, "-").result(env)


filename = "slashdot.epub"
File.unlink(filename) if File.exist?(filename)
Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) { |zip|
  # FIXME: mimetypeは無圧縮でなければならない
  # FIXME: mimetypeはアーカイブの先頭に現れなければならない
  zip.get_output_stream("mimetype") { |io| io.write(mimetype) }
  zip.get_output_stream("META-INF/container.xml") { |io| io.write(container_xml) }
  zip.get_output_stream("OEBPS/content.opf") { |io| io.write(content_opf) }
  zip.get_output_stream("OEBPS/toc.ncx") { |io| io.write(toc_ncx) }
  zip.get_output_stream("OEBPS/toc.xhtml") { |io| io.write(toc_xhtml) }
  articles.each { |article|
    zip.get_output_stream("OEBPS/" + article["filename"]) { |io| io.write(article["file"]) }
  }
}
