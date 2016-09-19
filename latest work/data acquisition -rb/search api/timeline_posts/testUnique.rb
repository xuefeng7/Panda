require "yaml"

src = YAML.load_file("users_dict_serie_2.yml")

unique = Hash.new

total = 0
checked = 0
uni = 0

for i in 1...10
	compare = YAML.load_file("timeline_#{i}.yml")
	for user in compare 
		for url in user[1]
			total += 1
			unique[url] = ""
		end
	end 
end
puts total
puts unique.size

# compare the new file with unique
for user in src 
	if user[1].size != 0
		for url in user[1]
			if unique.key? url then
				# encounter repeat
				checked += 1 
			else
				uni += 1
				unique[url] = ""
			end
		end
	end
end

puts checked
puts uni