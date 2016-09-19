### This file intends to divide all users into 10 folds

require 'yaml'

urls = Hash.new

count = 0
repeat = 0

for idx in 1...10
	file = YAML.load_file("timeline_posts_test/timeline_#{idx}.yml")
	for id in file.keys
		for path in file[id]
			if urls.key? path 
				repeat += 1
			else
				urls[path] = ""
				count += 1
			end
		end
	end
end

puts count
puts repeat

count = 0
repeat = 0

newfile =  YAML.load_file("timeline_posts/users_dict_serie_2.yml")
dstFile = File.open("timeline_posts/timeline_serie_2.yml", 'a+')
#dstYMLFile = YAML::load_file("timeline_posts/timeline_serie_2.yml")
dstYMLFile = Hash.new

for id in newfile.keys
	pathes = []
	for path in newfile[id]
		if urls.key? path 

		else
			pathes << path
			urls[path] = ""
		end
	end
	if pathes != nil and pathes.size > 0 then
		dstYMLFile["#{id}"] = pathes
	end
end
dstFile.write dstYMLFile.to_yaml

# $srcUrls = Hash.new # store all unique urls

# # puts "loading..."
# # posts = YAML.load_file('user_dic.yml')
# # puts "YML file has been loaded"

# totalCount = 0
# foldSize = posts.size / 10
# fileCount = 1
# idCount = 0

# dstFile = File.open("timeline_posts_test/timeline_#{fileCount}.yml", 'a+')
# dstYMLFile = YAML::load_file("timeline_posts_test/timeline_#{fileCount}.yml")
# dstYMLFile = Hash.new

# for ids in posts.keys
# 	totalCount += 1
# 	# puts "processing user No.#{totalCount}"
# 	urls = posts["#{ids}"]
# 	uniqueUrl = []
# 	# Make sure to remove all retweet caused duplicates
# 	for url in urls
# 		if $srcUrls.key? url
# 			#retweet ignore
# 		else
# 			#new tweet
# 			$srcUrls[url] = "" 
# 			uniqueUrl << url
# 		end
# 	end
	
# 	dstYMLFile["#{ids}"] = uniqueUrl
	
# 	if idCount == foldSize then
# 		dstFile.write dstYMLFile.to_yaml
# 		puts "tasks for file #{fileCount} have been done"
# 		fileCount += 1
# 		dstFile = File.open("timeline_posts_test/timeline_#{fileCount}.yml", 'a+')
# 		dstYMLFile = YAML::load_file("timeline_posts_test/timeline_#{fileCount}.yml")
# 		dstYMLFile = Hash.new
# 		idCount = 0
# 	end
# 	idCount += 1
# end
