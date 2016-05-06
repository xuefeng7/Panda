### This file query social media Flickr for certain tagged images
### Ideally, we will collect the url of the image

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "base64"

# Flickr api key
$api_key = "13f9d43db5b22f6a8138efbbdb2e5d71"
#txt file that stores all resulting image url
$posts = File.open("flickr_tag={selfie&face}.txt", 'a')
$counter = 0
### Search posts from Flickr
### Each request returns 20 results
## - params: tag, page number, loc_str(optional)
## - return: response data
def searchPostByTag(tag, page, loc_str)
	if loc_str == "" then
		url = "https://api.flickr.com/services/rest/?&method=flickr.photos.search&tags=#{tag},face,faces&format=json&extras=url_m&nojsoncallback=1&page=#{page}&api_key="
	else
		url = "https://api.flickr.com/services/rest/?&method=flickr.photos.search&tags=#{tag}&format=json&extras=url_m&nojsoncallback=1&page=#{page}&api_key="
	end
	uri = URI.parse(url + $api_key)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		#'Content-Type' => "application/json"
		})
	#send request
	res = http.request(req)
	return JSON.parse(res.body)["photos"]
end
### Process photos responsed from Tumblr server
## - params: photos
## - return: nil
def processPhotos(photos)
	for photo in photos
		if photo["url_m"] then
			$counter += 1
			$posts.write(photo["url_m"] + "\n")
		end
	end
end

def searchPostWithPageLimit(limit) #if limit < 100, 100 will be obtained
	# make first request to get photos info
	# initialQuery = searchPostByTag("selfie","1","")
	# pages = initialQuery["pages"].to_i
	# puts "total pages: #{pages}"
	# if pages < limit then
	# 	limit = pages
	# end
	#start collecting photo urls
	for i in 2400..limit
		puts "reading page.#{i}, running totoal.#{$counter}"
		photos = searchPostByTag("selfie", "#{i}","")
		puts photos
		processPhotos(photos["photo"])
	end
end

puts "working..."
searchPostWithPageLimit(2420)
puts "done"