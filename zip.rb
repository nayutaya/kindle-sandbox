#! ruby -Ku
# coding: utf-8

require "rubygems"
#require "zip/zipfilesystem"
require "zip/zip"

Zip::ZipFile.open("test.zip", Zip::ZipFile::CREATE) { |zip|
  zip.get_output_stream("mimetype") { |io|
    io.write("application/epub+zip")
  }
  zip.get_output_stream("foo/bar") { |io|
    io.write("baz")
  }
}
