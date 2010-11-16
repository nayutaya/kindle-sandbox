#! ruby -Ku
# coding: utf-8

require "cgi"
require "erb"
require "rubygems"
require "json"

json = ARGF.read
obj  = JSON.parse(json)

title        = obj["title"]
published    = obj["published"]
department   = obj["department"]
body_html    = obj["body_html"]
comment_html = obj["comment_html"]

template = File.open("template.xhtml.erb", "rb") { |file| file.read }

ns = Object.new
ns.instance_eval {
  @title    = CGI.escapeHTML(title)
  @body     = body_html
  @comments = comment_html
}
bind = ns.instance_eval { binding }

erb = ERB.new(template, nil, "-")
puts erb.result(bind)
