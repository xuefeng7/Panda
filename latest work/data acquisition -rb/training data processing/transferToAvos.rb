## Transfer app data from Parse to AVOSCloud

require 'net/http'
require 'json'
require 'uri'
require "open-uri"

# Parse - old database
$appId = "yIXHt9rTdw2TZ5ozblwc1dpJwqnIGOhUwwZ39GoV"
$appKey = "3pbyqwZIOotJmlfFKL1vFt2jzYUOurJ3xPd2irhX"
# AVOS - new database
$avosAppId = "etos3zLQpPdQaGEon0Cx4O7F-MdYXbMMI"
$avosAppKey = "uwLztHjKrzrUueLLoCymQDAy"
$avosAddress = "https://us-api.leancloud.cn/1.1"
#Faces class url
$faceUrl = "https://api.parse.com/1/classes/Faces"


def obtainDataFromParse() 
	uri = URI.parse($faceUrl + "?limit=1000&&skip=1000")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		'X-Parse-Application-Id' => $appId,
		'X-Parse-REST-API-Key' => $appKey,
		'Content-Type' => 'application/json'
		})
	#send request
	res = http.request(req)
	data = JSON.parse(res.body)

	return data["results"]
end

def uploadDataToAVOS(face) 
	# name
	name = face['name']
	# class
	_class = face['class']
	
	# picture path
	picPath = face['picture']['url'] 

	uri = URI.parse($avosAddress + "/classes/Face")
	http = Net::HTTP.new(uri.host, uri.port)

	fileUri = URI.parse($avosAddress + "/files/#{name}")
	fileHttp = Net::HTTP.new(fileUri.host, fileUri.port)
	
	http.use_ssl = true
	fileHttp.use_ssl = true

	## upload pic
	pcReq = Net::HTTP::Post.new(fileUri.request_uri, initheader = {
		'X-LC-Id' => $avosAppId,
		'X-LC-Key' => $avosAppKey,
		'Content-Type' => 'image/jpg'
		})
	pcReq.body = open(picPath).read
	pcRes = fileHttp.request(pcReq)
	puts pcRes.body
	## get returned url, create object and relate it with the pic
	obReq = Net::HTTP::Post.new(uri.request_uri, initheader = {
		'X-LC-Id' => $avosAppId,
		'X-LC-Key' => $avosAppKey,
		'Content-Type' => 'application/json'
		})
	obReq.body = {
		name: name,
		class: _class,
		picture: {
			'id' => JSON.parse(pcRes.body)["objectId"],
			'__type' => "File"
		}
	}.to_json
	obRes = http.request(obReq)
end

def transferDataToAVOS()
	faces = obtainDataFromParse()
	puts faces.size
	for face in faces 
		#uploadDataToAVOS(face)
		#exit
		File.open("images/#{face['name']}", 'wb') do |fo|
  			fo.write open(face['picture']['url']).read 
		end
	end
end

#transferDataToAVOS()
filenames = `ls`

for name in filenames
	if name.include? ".png"
		#{}`lean upload #{name}` 
		puts name
	end
end
