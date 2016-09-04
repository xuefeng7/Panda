### This file intends to divide all users into 10 folds

require 'yaml'

$srcUrls = [] # store all unique urls

puts "loading..."
posts = YAML.load_file('user_dic.yml')
puts "YML file has been loaded"

totalCount = 0
foldSize = posts.size / 10
fileCount = 1
idCount = 0

dstFile = File.open("timeline_posts/timeline_#{fileCount}.yml", 'a+')
dstYMLFile = YAML::load_file("timeline_posts/timeline_#{fileCount}.yml")
dstYMLFile = Hash.new

for ids in posts.keys
	
	totalCount += 1
	puts "processing user No.#{totalCount}"
	
	urls = posts["#{ids}"]
	uniqueUrl = []
	# Make sure to remove all retweet caused duplicates
	for url in urls
		if $srcUrls.include? url
			#retweet ignore
		else
			#new tweet
			$srcUrls << url
			uniqueUrl << url
		end
	end
	
	dstYMLFile["#{ids}"] = uniqueUrl
	
	if idCount == foldSize then
		dstFile.write dstYMLFile.to_yaml
		puts "tasks for file #{fileCount} have been done"
		fileCount += 1
		dstFile = File.open("timeline_posts/timeline_#{fileCount}.yml", 'a+')
		dstYMLFile = YAML::load_file("timeline_posts/timeline_#{fileCount}.yml")
		dstYMLFile = Hash.new
		idCount = 0
	end
	idCount += 1
end