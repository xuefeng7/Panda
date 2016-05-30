require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

# Setting up initial ID
$stopId = "0" 
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
# record the running total of effective tweets acqureied
$counter = 0

# Update Stop Id
def recordMaxId(max_id)
	time = Time.new
	date = "#{time.day}/#{time.month}/#{time.year}"
	File.write(f = "timeline_stopId.txt", File.read(f).gsub(/twitter:\d{18}/,"twitter:#{max_id}	#{date}"))
end

# Search timeline by keyword
def searchTimelineByKeyword(keyword, type, geo_str, max_id)
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
	#puts res.body
	return JSON.parse(res.body)["statuses"]
end