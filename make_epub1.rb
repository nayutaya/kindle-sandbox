#! ruby -Ku
# coding: utf-8

=begin

ディレクトリ構成

/
  mimetype         固定ファイル名
  META-INF/        固定ディレクトリ名
    container.xml  固定ファイル名
  OEBPS/           任意ディレクトリ名
    content.opf    任意ファイル名
    toc.ncx        任意ファイル名
    texts/         任意ディレクトリ名
      text#.xhtml  任意ファイル名
    images/        任意ディレクトリ名
      image#.jpg   任意ファイル名
    styles/        任意ディレクトリ名
      style#.css   任意ファイル名

=end

container_xml = <<END_OF_XML
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
 <rootfiles>
  <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml" />
 </rootfiles>
</container>
END_OF_XML

p container_xml

=begin
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="BookID">
 <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
  <dc:title>Design Sample!!!</dc:title>
  <dc:creator opf:role="aut">Yuya Kato!!!</dc:creator>
  <dc:language>ja</dc:language>
  <dc:identifier id="BookID" opf:scheme="UUID">urn:uuid:3574e515-9d78-4fc8-a728-2e55db905413!!!</dc:identifier>
 </metadata>
 <manifest>
  <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
  <item id="text1" href="texts/text1.xhtml" media-type="application/xhtml+xml" />
  <item id="image1" href="images/image1.png" media-type="image/png" />
  <item id="style1" href="styles/style1.css" media-type="text/css" />
 </manifest>
 <spine toc="ncx">
  <itemref idref="text1" />
 </spine>
</package>
=end
