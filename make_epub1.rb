#! ruby -Ku
# coding: utf-8

require "cgi"
require "erb"
require "rubygems"
require "uuid"
require "zip/zip"

=begin

ディレクトリ構成

/
  mimetype         固定ファイル名
  META-INF/        固定ディレクトリ名
    container.xml  固定ファイル名
  OEBPS/           任意ディレクトリ名
    content.opf    任意ファイル名
    toc.ncx        任意ファイル名
    text/          任意ディレクトリ名
      text#.xhtml  任意ファイル名
    images/        任意ディレクトリ名
      image#.jpg   任意ファイル名
    styles/        任意ディレクトリ名
      style#.css   任意ファイル名

=end

uuid   = UUID.new.generate
title  = "autogen " + Time.now.strftime("%Y%m%d%H%M%S")
author = "generator"
publisher = "publisher"


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

text1_xhtml = <<END_OF_XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja" xml:lang="ja">
 <head>
  <title>サンプル文書001</title>
 </head>
 <body>
  <h1>Hello, World!</h1>
  <p>こんにちはこんにちは！</p>
 </body>
</html>
END_OF_XML

File.unlink("out.epub")
Zip::ZipFile.open("out.epub", Zip::ZipFile::CREATE) { |zip|
  # FIXME: mimetypeは無圧縮でなければならない
  # FIXME: mimetypeはアーカイブの先頭に現れなければならない
  zip.get_output_stream("mimetype") { |io| io.write(mimetype) }
  zip.get_output_stream("META-INF/container.xml") { |io| io.write(container_xml) }
  zip.get_output_stream("OEBPS/content.opf") { |io| io.write(content_opf) }
  zip.get_output_stream("OEBPS/toc.ncx") { |io| io.write(toc_ncx) }
  zip.get_output_stream("OEBPS/text/text1.xhtml") { |io| io.write(text1_xhtml) }
}
