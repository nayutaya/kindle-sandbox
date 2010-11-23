# coding: utf-8

KINDLEGEN = "kindlegen"

rule ".azw" => ".epub" do |t|
  # MEMO: shメソッドではステータスコードが0以外でエラーと判定されてしまうため、systemメソッドを使う
  system(%|#{KINDLEGEN} "#{t.source}" -o "#{t.name}" -unicode|)
end
