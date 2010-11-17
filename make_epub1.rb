#! ruby -Ku
# coding: utf-8

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


mimetype      = File.open("template/mimetype", "rb") { |file| file.read }
container_xml = File.open("template/container.xml", "rb") { |file| file.read }
content_opf   = File.open("template/content.opf.erb", "rb") { |file| file.read }

require "cgi"
require "erb"


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

content_opf = ERB.new(content_opf, nil, "-").result(env)

=begin
  <item id="image1" href="images/image1.png" media-type="image/png"/>
  <item id="style1" href="styles/style1.css" media-type="text/css"/>
=end

puts "---"
puts content_opf

toc_ncx = <<END_OF_XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
 <head>
  <meta name="dtb:uid" content="#{uuid}"/>
  <meta name="dtb:depth" content="1"/>
  <meta name="dtb:totalPageCount" content="0"/>
  <meta name="dtb:maxPageNumber" content="0"/>
 </head>
 <docTitle>
  <text>#{title}</text>
 </docTitle>
 <docAuthor>
  <text>#{author}</text>
 </docAuthor>
 <navMap>
  <navPoint id="navPoint-1" playOrder="1">
   <navLabel>
    <text>contents</text>
   </navLabel>
   <content src="text/text1.xhtml"/>
  </navPoint>
 </navMap>
</ncx>
END_OF_XML

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
