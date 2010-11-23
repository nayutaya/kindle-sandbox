# coding: utf-8

require "erb"

module TechOn
  module ArticleFormatter
    def self.format(article)
      filename = File.join(File.dirname(__FILE__), "template.xhtml.erb")
      template = File.open(filename, "rb") { |file| file.read }

      env = Object.new
      env.extend(ERB::Util)
      env.instance_eval {
        @url            = "http://foo.bar.baz/"
        @title          = "てすと"
        @published_time = Time.now
        @author         = "さくしゃ"
        @images         = []
        @body           = "foo <b>bar</b> baz"
      }

      erb = ERB.new(template, nil, "-")
      erb.filename = filename

      return erb.result(env.instance_eval { binding })
    end
  end
end
