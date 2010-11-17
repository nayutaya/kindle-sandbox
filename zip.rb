#! ruby -Ku
# coding: utf-8

require "rubygems"
#require "zip/zipfilesystem"
require "zip/zip"

Zip::ZipFile.open("test.zip", Zip::ZipFile::CREATE) { |zip|
  #zip.add("mimetype", "hoge")
  zip.get_output_stream("mimetype") { |io|
p io
    io.write("application/epub+zip")
  }
}
