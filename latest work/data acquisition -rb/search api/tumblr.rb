### This file query social media Tumblr for certain tagged images
### Ideally, we will collect the url of the image

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

$stopStamp = "0" # if arg is "", stopId is 0
## read stop id from text
File.open("/Users/Sonny/Desktop/Panda/latest\ work/data\ acquisition\ -rb/search\ api/stopId.txt").each do |line|
		#only read the first line for twitter
		if line.include? "tumblr"
			comp = line.split(" ")
			$stopId = (comp[0].split(":"))[1]
		end
end

# tumblr api key
$api_key = "RhCH9qrKIjJrFEBVEZLSzY8YIEc7DMVdyFFIxzsTwUO4BobCVb"
#txt file that stores all resulting image url
$posts = File.open("tumblr.txt", 'a+')
#totoal posts acquired
$counter = 0

### record the current search maxId
## - param: maxId
## - return: nil
def recordMaxId(time_stamp)
	#$stopIdFile.each_line { |line| $stopIdFile.replace_puts('blah') if line =~ /twitter:/}
	time = Time.new
	date = "#{time.day}/#{time.month}/#{time.year}"
	File.write(f = "/Users/Sonny/Desktop/Panda/latest\ work/data\ acquisition\ -rb/search\ api/stopId.txt", File.read(f).gsub(/tumblr:\d{10}(.)*/,"tumblr:#{time_stamp}	#{date}"))
end

### Search posts from Tumblr
### Each request returns 20 results
## - params: tag 
## - return: response data
def searchPostByTag(tag, timestamp)
	url = ""
	if timestamp == "" then
		url = "https://api.tumblr.com/v2/tagged?tag=#{tag}&api_key=#{$api_key}"
	else
		url = "https://api.tumblr.com/v2/tagged?tag=#{tag}&api_key=#{$api_key}&before=#{timestamp}"
	end
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		#'Content-Type' => "application/json"
		})
	#send request
	res = http.request(req)
	puts "timeStamp.#{timestamp}, running totoal.#{$counter}"
	return JSON.parse(res.body)["response"]
end
### Process posts responsed from Tumblr server
## - params: posts
## - return: nil
def processPosts(posts)
	if posts.length == 0 then
		puts "no more posts"
		exit
	end
	# check type, if not photo, skip
	for post in posts 
		if validPostFormat(post) then
			#obtain url
			$counter += 1
			url = post["photos"][0]["alt_sizes"][2]["url"] #get image with wdith 400
			blogId = post["id"]
			$posts.write("{\"url\":\"#{url}\", \"blog_Id\":\"#{blogId}\"}" + "\n")
		end
	end
end

def validPostFormat(post)
	return post["photos"] && post["photos"][0]["alt_sizes"] && post["photos"][0]["alt_sizes"][2] && post["type"] == "photo" && post["photos"][0]["alt_sizes"][2]["url"]
end
### Find the min timestamp as next request's query param (pagination)
## - params: posts
## - return: timestamp
$stampCounter = 0
def getMinTimeStamp(posts)
	stamps = []
	for post in posts
		stamps << post["timestamp"].to_i
	end
	stamp = stamps.min
	$stampCounter += 1
	if $stampCounter == 1
		# record the first max id
		recordMaxId(stamp)
	end
	return stamp
end

def searchPostFor(sec, timestamp)
	tag = "face"
	posts = ""
	isFirstSearch = true
	sec_step = sec / 0.1 #measure step by seconds
	while sec_step >= 0 do
		begin
			if isFirstSearch then
				#no need to add timestamp param
				posts = searchPostByTag(tag, timestamp)
				isFirstSearch = false
			else
				timeStamp = getMinTimeStamp(posts)
				if timeStamp > $stopStamp.to_i then
					posts = searchPostByTag(tag, timeStamp)
				else
					puts "stop id encountered"
					exit
				end
			end
			processPosts(posts)
			sec_step -= 1
			sleep 0.05
		rescue
			next
		end
	end
end

puts "working..."
searchPostFor(100, "")
puts "done"
