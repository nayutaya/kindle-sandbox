# coding: utf-8

KINDLEGEN = "kindlegen"

file "asahi.epub" => "asahi1.yaml" do |t|
  ruby "make_asahi.rb"
end

file "techon.epub" => "techon1.yaml" do |t|
  ruby "make_techon.rb"
end

rule ".azw" => ".epub" do |t|
  # MEMO: shメソッドではステータスコードが0以外でエラーと判定されてしまうため、systemメソッドを使う
  system(%|#{KINDLEGEN} "#{t.source}" -o "#{t.name}" -unicode|)
end
