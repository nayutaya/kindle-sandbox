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

title  = "autogen " + Time.now.strftime("%Y%m%d%H%M%S")
author = "generator"
uuid   = UUID.new.generate


mimetype = "application/epub+zip"

puts "---"
puts mimetype

container_xml = <<END_OF_XML
<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
 <rootfiles>
  <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
 </rootfiles>
</container>
END_OF_XML

puts "---"
puts container_xml

content_opf = <<END_OF_XML
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="BookID">
 <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
  <dc:language>ja</dc:language>
  <dc:identifier id="BookID" opf:scheme="UUID">urn:uuid:#{uuid}</dc:identifier>
  <dc:title>#{title}</dc:title>
  <dc:creator opf:role="aut">#{author}</dc:creator>
  <dc:publisher>publisher</dc:publisher>
  <dc:date opf:event="publication">2010-03-27</dc:date>
 </metadata>
 <manifest>
  <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
  <item id="text1" href="text/text1.xhtml" media-type="application/xhtml+xml"/>
<!--
  <item id="image1" href="images/image1.png" media-type="image/png"/>
  <item id="style1" href="styles/style1.css" media-type="text/css"/>
-->
 </manifest>
 <spine toc="ncx">
  <itemref idref="text1"/>
 </spine>
</package>
END_OF_XML

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

Zip::ZipFile.open("out.epub", Zip::ZipFile::CREATE) { |zip|
  # FIXME: mimetypeは無圧縮でなければならない
  # FIXME: mimetypeはアーカイブの先頭に現れなければならない
  zip.get_output_stream("mimetype") { |io| io.write(mimetype) }
  zip.get_output_stream("META-INF/container.xml") { |io| io.write(container_xml) }
  zip.get_output_stream("OEBPS/content.opf") { |io| io.write(content_opf) }
  zip.get_output_stream("OEBPS/toc.ncx") { |io| io.write(toc_ncx) }
  zip.get_output_stream("OEBPS/text/text1.xhtml") { |io| io.write(text1_xhtml) }
}
