# coding: utf-8

KINDLEGEN = "kindlegen"

file "asahi.epub" => "asahi.yaml" do |t|
  ruby "make_asahi.rb"
end

file "techon.epub" => "techon.yaml" do |t|
  ruby "make_techon.rb"
end

file "slashdot.epub" => "slashdot.yaml" do |t|
  ruby "make_slashdot.rb"
end

rule ".azw" => ".epub" do |t|
  # MEMO: shメソッドではステータスコードが0以外でエラーと判定されてしまうため、systemメソッドを使う
  system(%|#{KINDLEGEN} "#{t.source}" -o "#{t.name}" -unicode|)
end
