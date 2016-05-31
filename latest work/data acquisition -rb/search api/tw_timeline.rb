require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

# Authen
consumer_key = "yBH5FlKN8vU79EMWNJtJkjcvI"
consumer_secret = "tHiu4tP1h5WCZRrOVMkhLBY1gJSHzaT7kfUtIE3FF03mhUO7wY"
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


$tweets = File.open("timeline.txt", 'a+')

# Search timeline by keyword
def searchTimelineByKeyword()
	url = "https://api.twitter.com/1.1/statuses/user_timeline.json?"
	# User Id
	url = url + "user_id=25666128"
	uri = URI.parse(url + "&count=3200")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		'Authorization' => "Bearer " + $access_token
		})
	res = http.request(req)
	if res.code == 409 then
		#no quota
		exit 
	end
	return JSON.parse(res.body)
end

def getTimelineByWindow()
	isFirstReq = true
	data = ""
	reqCounter = 0
	while true do
	#puts "req left: #{reqCounter}"
	data = searchTimelineByKeyword()
	puts "Search is done"
	processTweets(data)
	sleep 2
	end
end

# Filter out selfie
def processTweets(tweets)
	counter = 0
	for tweet in tweets
		selfie = false
		if tweet["entities"].has_key? "hashtags" then
			for tags in tweet["entities"]["hashtags"]
				keyword = tags["text"].downcase
				if keyword.include? "selfie" or keyword.include? "me" or keyword.include? "photooftheday" or keyword.include? "picoftheday" or keyword.include? "happy" or keyword.include? "fun" or keyword.include? "smile" or keyword.include? "summer" or keyword.include? "friends" or keyword.include? "fashion"
					selfie = true
				end
			end
		end
		if tweet["entities"].has_key? "media" and selfie == true
			url = tweet["entities"]["media"][0]["media_url"]
			$tweets.write(url)
			$tweets.write("\n")
		end
	end
	exit
end

getTimelineByWindow()