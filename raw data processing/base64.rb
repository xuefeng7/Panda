require "base64"

files = `ls`.split("\n")
puts "working..."
out_file1 = File.new("base64.txt", "w")
#out_file2 = File.new("base64_two.txt", "w")
count = 0
fs = []

for f in files
		encode = Base64.encode64(open(f).to_a.join)
		count = count + 1
		#image object pack name@encode
		pack = f + "@" + encode+ "%"
		fs << pack
end
puts "work done #{count}"

#check and remove duplicates
fs = fs.uniq

for pack in fs
	out_file1.puts(pack)
end