### This file query social media Tumblr for certain tagged images
### Ideally, we will collect the url of the image

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

$stopStamp = "0" # if arg is "", stopId is 0
## helper method for numeric check
def is_number? string
  true if Float(string) rescue false
end

if ARGV.length != 1 
	puts "one arg is required"
	exit
else
	arg = ARGV[0]
	if is_number?(arg) && arg.length == 10 # size of time stamp
		$stopId = arg
	elsif arg.eql? ""
		# ignore
	else
		puts "invalid arg"
		exit
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
	File.write(f = "stopId.txt", File.read(f).gsub(/tumblr:\d{10}/,"tumblr:#{time_stamp}	#{date}"))
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
	end
end

puts "working..."
searchPostFor(100, "")
puts "done"

# last time stamp. 1380448836 tag: selfie  
# last time stamp.  		  tag: face 1428372518
# last time stamp.  		  tag: faces


# 4.24 first selfie max id: 1461513474 
# 4.25 first selfie max id: 1428372518 
# 4.26 1461698903