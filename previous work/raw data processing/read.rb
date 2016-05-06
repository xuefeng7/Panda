directories = `ls`.split("\n")

out_file = File.new("file_names.txt", "w")
for dic in directories 
	if dic != "read.rb" then
		# Dir.chdir(dic) do
		# 	files = `ls`.split("\n")
		# 	for file in files
		# 		out_file.puts(file)
		# 		`sudo bunzip2 #{file}`
		# 	end
		# end
		files = Dir.entries(dic)
		out_file.puts(files[2])
		# for f in files
		# 	if f != "." && f != ".."
		# 		out_file.puts(f)
		# 	end
		# end
	end
end
out_file.close