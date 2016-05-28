### This file query social media Twitter for certain tagged images
### Ideally, we will collect the url and location(optional) of the image

## HOW TO RUN THIS FILE
## When you first run this script, set input command line arg to ""
## Otherwise, set the arg to be "stopId", where you can find in a separate file named stopId.txt
## More specifically, the twitter api will return the posts in recent 15 days, but once you triggered the 
## the first search among a 15-day, you don't want to obtain the duplicate posts in your second or third search 
## in order to achieve this, we need to set the stopId, where the stopId is the first line of
## number(ie. maxId) in the std ouput.
## if there has no more post within a search, the std ouput text will notify you such situation.

## NOTE THAT
## getTweetsByWindow will do multiple searches in a given amount of window(15 mins), e.g getTweetsByWindow(4,"") 
## stands for 60 mins.
## the max_id will be automatically found and be used for the next search.
## The only thing that you should do is set the stopId for each run of this script. 

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

### Note, first request shall contains the count of the tweets
### and the low_id should be tracked. For the subsequent request, 
### specify the low_id as the max_id for request, so no duplicates tweets will be retreieved.

$stopId = "0" # if arg is "", stopId is 0
## helper method for numeric check
def is_number? string
  true if Float(string) rescue false
end

if ARGV.length != 1 
	puts "one arg is required"
	exit
else
	arg = ARGV[0]
	if is_number?(arg) && arg.length == 18 # size of maxId
		$stopId = arg
	elsif arg.eql? ""
		# ignore
	else
		puts "invalid arg"
		exit
	end
end

#Twitter api keys
consumer_key = "yBH5FlKN8vU79EMWNJtJkjcvI"
consumer_secret = "tHiu4tP1h5WCZRrOVMkhLBY1gJSHzaT7kfUtIE3FF03mhUO7wY"
#URL encode the consumer key and the consumer secret according to RFC 1738. 
#Note that at the time of writing, this will not actually change the consumer key and secret, 
#but this step should still be performed in case the format of those values changes in the future.
url_encoded_ck = consumer_key.force_encoding('ASCII-8BIT')
url_encoded_cs = consumer_secret.force_encoding('ASCII-8BIT')

key = URI::encode(url_encoded_ck) + ":" + URI::encode(url_encoded_cs)
key_base64 = Base64.strict_encode64(key)
#Exchange bearer token form Twitter server
uri = URI.parse("https://api.twitter.com/oauth2/token")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
#init header
req = Net::HTTP::Post.new(uri.request_uri, initheader = {
	'Authorization' => "Basic " + key_base64,
	'Content-Type' => "application/x-www-form-urlencoded;charset=UTF-8"
	})
req.body = "grant_type=client_credentials"
#send request
res = http.request(req)
#obtain access token from response body
$access_token = JSON.parse(res.body)['access_token']
#txt file that stores all resulting image url
$tweets = File.open("twitter_tag=selfie.txt", 'a+')
# record the running total of effective tweets acqureied
$counter = 0

### record the current search maxId
## - param: maxId
## - return: nil
def recordMaxId(max_id)
	#$stopIdFile.each_line { |line| $stopIdFile.replace_puts('blah') if line =~ /twitter:/}
	time = Time.new
	date = "#{time.day}/#{time.month}/#{time.year}"
	File.write(f = "stopId.txt", File.read(f).gsub(/twitter:\d{18}/,"twitter:#{max_id}	#{date}"))
end

### rate limit: 450 reqs/15mins
### max results per page: 100

### Making search by twitter search Api using 
## - param: keyword, media type (e.g image), geolocation (ie. 37.781157,-122.398720,1mi), max_id
## - return: tweets 
def searchTweetByKeyword(keyword, type, geo_str, max_id)
	puts "max_id.#{max_id}, running total.#{$counter}"
	url = "https://api.twitter.com/1.1/search/tweets.json?q="
	#geo location check
	if geo_str != "" then
		#%23#{keyword}+filter:#{type}
		url = url + "&geocode=#{geo_str}&%23#{keyword}+filter:#{type}"
	else
		url = url + "%23#{keyword}+filter:#{type}"	
	end
	
	#max_id check
	if max_id != "" then
		url = url + "&max_id=#{max_id}"
	end
	uri = URI.parse(url + "&count=100")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		'Authorization' => "Bearer " + $access_token
		})
	res = http.request(req)
	#puts res.body
	if res.code == 409 then
		#no quota
		exit 
	end
	return JSON.parse(res.body)["statuses"]
end

### Compute the low id as the max_id for next request
## - param: data
## - return: low id for current request
$IdCounter = 0
def getMaxId(tweets)
	ids = []
	for tweet in tweets
		ids << tweet["id"].to_i
	end
	maxId = ids.min
	$IdCounter += 1
	if $IdCounter == 1
		# record the first max id
		recordMaxId(maxId)
	end
	return maxId
end
### Process received tweets and write all collcted info into text file
## - param: data
## - return: nil 
def processTweets(tweets)
	if tweets.length == 0 then
		#no more tweets
		puts "no more tweets"
		exit
	end
	for tweet in tweets
		if tweet["entities"].has_key? "media" then
			$counter += 1
			$tweets.write("{\"url\":\"#{tweet["entities"]["media"][0]["media_url"]}\",\"user\":\"#{tweet["user"]["id"]}\"}\n")
		end
	end
end
### specify the amount of tweets desired to obtain
### each request will obtain 100 tweets, 450reqs/15mins = 1 req/2sec
### rate limit is described per 15 mins window
## - params: amount
## - return: nil

#$geo = "40.7144,-74.006,50mi"
$geo = ""
def getTweetsByWindow(window, max_id) #i.e 5 windows = 75 mins
	keyword = "selfie"
	type = "images"
	isFirstReq = true
	data = ""
	reqCounter = 0
	while true do
	#puts "req left: #{reqCounter}"
	if isFirstReq then
		# first request, no max_id is specified or user specified
		data = searchTweetByKeyword(keyword, type, $geo, max_id)
		isFirstReq = false
		reqCounter += 1
	else
		maxId = getMaxId(data)
		if maxId.to_i <= $stopId.to_i then
		 	puts "stop id is encountered"
			exit
		end
		data = searchTweetByKeyword(keyword, type, $geo, maxId)
		reqCounter += 1
	end
	processTweets(data)
	# if reqCounter == 10 * window then
	# 	#break the loop
	# 	break
	# end
	sleep 2
	end
end

puts "working..."
# if no max id, enter ""
getTweetsByWindow(4, "")
puts "done"

#last max id for tage selfie: 723593669471834112
# 4.23 first max id 723883477368713217 tag=selfie
# 4.23				723928574487613441 tag=face
# 4.24 first max id 724261120362557441  tag = selfie    
# 4.25 first max id 724633074613383169  tag = selfie 
# 4.26 725041380586835968 tag = selfie
# 4.27 725315663447863296
