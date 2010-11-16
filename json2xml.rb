#! ruby -Ku
# coding: utf-8

require "cgi"
require "erb"
require "rubygems"
require "json"

json = ARGF.read
obj  = JSON.parse(json)

title         = obj["title"]
published     = obj["published"]
department    = obj["department"]
body_html     = obj["body_html"]
comments_html = obj["comments_html"]

template = File.open("template.xhtml.erb", "rb") { |file| file.read }

ns = Object.new
bind = ns.instance_eval {
  @title      = CGI.escapeHTML(title)
  @published  = CGI.escapeHTML(published)
  @department = CGI.escapeHTML(department)
  @body       = body_html
  @comments   = comments_html
  binding
}

erb = ERB.new(template, nil, "-")
puts erb.result(bind)
