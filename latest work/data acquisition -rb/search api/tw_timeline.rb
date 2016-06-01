require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"
require 'yaml'

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
$user_dic = YAML.load_file('user_dic.yml')
# Initialization
if $user_dic.class == FalseClass
	$user_dic = Hash.new
end

# Search timeline by keyword
def searchTimelineByKeyword()
	counter = 0
	users = File.open("twitter_tag=selfie.txt", 'r')
	users.each_line do |line|
		u_json = JSON.parse(line)
		if not $user_dic.has_key? u_json["user"]
			url = "https://api.twitter.com/1.1/statuses/user_timeline.json?"
			# User Id
			url = url + "user_id=" + u_json["user"]
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
			processTweets(JSON.parse(res.body),u_json["user"])
			puts "#{counter} users finished"
			counter += 1
		end
	end
	users.close
	puts "Search is done"
	File.open('user_dic.yml','w') do |file|
		file.write $user_dic.to_yaml
	end
	exit
end

def getTimelineByWindow()
	isFirstReq = true
	data = ""
	reqCounter = 0
	while true do
	#puts "req left: #{reqCounter}"
	searchTimelineByKeyword()
	puts "Search is done"
	end
end

# Filter out selfie
def processTweets(tweets,user_id)
	url_array = Array.new
	for tweet in tweets
		selfie = false
		if tweet.class == Hash
			if tweet.has_key? "entities" then
				if tweet["entities"].has_key? "hashtags" then
					for tags in tweet["entities"]["hashtags"]
						keyword = tags["text"].downcase
						if keyword.include? "selfie" or keyword.include? "me" or keyword.include? "photooftheday" or keyword.include? "picoftheday" or keyword.include? "happy" or keyword.include? "fun" or keyword.include? "smile" or keyword.include? "summer" or keyword.include? "friends" or keyword.include? "fashion"
							selfie = true
						end
					end
				end
			end
		end
		if tweet.class == Hash
			if tweet.has_key? "entities" then
				if tweet["entities"].has_key? "media" and selfie == true
					url = tweet["entities"]["media"][0]["media_url"]
					url_array << url
				end
			end
		end
	end
	if not url_array.empty?
		$user_dic[user_id] = url_array
	end
end

getTimelineByWindow()