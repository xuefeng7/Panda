require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require 'logger'

$faceUrl = "https://us-api.leancloud.cn/1/classes/Face"
$detectUrl = "https://apius.faceplusplus.com/v2/detection/detect?"
$landMarkUrl = "https://apius.faceplusplus.com/detection/landmark?"

$subscription_secret = "XXByJ2S115vEHTlK5hqKFCwnoFD2V_gg"
$subscription_key = "a9278032efdf15b8cbbecdf7fccb526b"

#where={"upvotes":{"$in":[1,3,5,7,9]}}
constrain = URI::encode({:fid => "00055"}.to_json)

uri = URI.parse($faceUrl + "?limit=1000&where=#{constrain}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
req = Net::HTTP::Get.new(uri.request_uri, initheader = {
	'X-LC-Id' => "etos3zLQpPdQaGEon0Cx4O7F-MdYXbMMI",
	'X-LC-Key' => "uwLztHjKrzrUueLLoCymQDAy",
	'Content-Type' => 'application/json'
})
resp = http.request(req) # actual request
result = JSON.parse(resp.body)["results"]

puts result
training = Hash.new

for face in result
	fid = face["fid"]
	pathes = face["pathes"]
	for path in pathes
		if path[0].include? "_fa_a." #or path[0].include? "_fa_a."
			training[fid] = path
		end
	end
end

def makeFaceDectectionPostRequest(url)
	#create http POST request
	#static Microsoft Face detection API url
	uri = URI.parse("#{$detectUrl}url=#{url}&api_secret=#{$subscription_secret}&api_key=#{$subscription_key}")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Post.new(uri.request_uri, initheader = {
		})
	req.body = {url: url}.to_json
	#send request
	res = http.request(req)
	#respond data jsonfy
	data = JSON.parse(res.body)
	return data
end

def makeFaceLandmarksGetRequest(face_id)
	uri = URI.parse("#{$landMarkUrl}&api_secret=#{$subscription_secret}&api_key=#{$subscription_key}&face_id=#{face_id}&type=25p")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	#init header
	req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		})
	#send request
	res = http.request(req)
	#respond data jsonfy
	data = JSON.parse(res.body)
	#puts data
	return data
end

#result = Hash.new

output = File.open("training_face_attributes.txt", "a+")

# log = Logger.new("| tee debug/debug_#{$fileIndex}.log")

for fid in training.keys 
	puts "processing fid: #{fid}"
	begin
	path = training[fid][1]
	detectRes = makeFaceDectectionPostRequest(path)
	puts detectRes
	face_id = detectRes["face"][0]["face_id"]
	img_width = detectRes["img_width"]
	img_height = detectRes["img_height"]
	url = detectRes["url"]
	landmarks = makeFaceLandmarksGetRequest(face_id)["result"][0]["landmark"]
	result = Hash.new
	result[fid] = { 'url' => url,
					'file_name' => training[fid][0],
					'img_width' => img_width, 
					'img_height' => img_height,
					'landmarks' => landmarks}
	output.puts result
	rescue
		puts "error occured for fid.#{fid}"
		next
	end
end

#output.puts result

# storedKeys = []
# results = File.open("training_face_attributes.txt", "r")
# results.each_line { 
# 	|line|  
# 		fid = eval(line).keys[0]
# 		storedKeys << fid
# }

# for face in result
# 	fid = face["fid"]
# 	if not storedKeys.include? fid
# 		puts fid
# 	end
# end