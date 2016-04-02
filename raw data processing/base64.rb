require "base64"

files = `ls`.split("\n")
puts "working..."
out_file1 = File.new("base64_one.txt", "w")
out_file2 = File.new("base64_two.txt", "w")
count = 0
for f in files
	encode = Base64.encode64(open(f).to_a.join)
	count = count + 1
	#image object pack name@encode
	pack = f + "@" + encode
	if count < 492 then
		out_file1.puts(pack)
	else
		out_file2.puts(pack)
	end
end
puts "work done"