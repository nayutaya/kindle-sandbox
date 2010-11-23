# coding: utf-8

KINDLEGEN = "kindlegen"

rule ".azw" => ".epub" do |t|
  sh %|#{KINDLEGEN} "#{t.prerequisites.first}" -o "#{t.name}" -unicode|
end
