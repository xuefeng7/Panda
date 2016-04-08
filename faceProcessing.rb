## This is the file that use Microsoft Cognitive Services API
## to obtain landmark points of face images
## and crop the interest objects (in this case eyes) store to cloud

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "mini_magick"

#Microsoft API keys
$subscription_key = "-"
#Parse API keys
$appId = "-"
$appKey = "-"
#Faces class url
$faceUrl = "https://api.parse.com/1/classes/Faces"
#Face object query limit
$limit = 1

### make post request to Microsoft face detection server
## - param: image url
## - return: response data
def makeFaceDectectionPostRequest(url)
#create http POST request
#static Microsoft Face detection API url
uri = URI.parse("https://api.projectoxford.ai/face/v1.0/detect?returnFaceId=true&returnFaceLandmarks=true")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
#init header
req = Net::HTTP::Post.new(uri.request_uri, initheader = {
	'Ocp-Apim-Subscription-Key' => $subscription_key,
	'Content-Type' => 'application/json'
	})
req.body = {url: url}.to_json
#send request
res = http.request(req)
#respond data jsonfy
data = JSON.parse(res.body)
return data
end

### make get request to Parse server to obtain a list of face object
## - param: nil
## - return: response data
def makeFaceObjectGetRequest()
#make http GET request
uri = URI.parse($faceUrl + "?limit=#{$limit}") #add query constrain
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
#return face JSON object
return data['results']
end

### given face landmark points, crop out the eyes outline 
## - params: image, response data from Microsoft face detection server
## - return: 
def cropEyesFromFace(url, face)
	#open a image file from url
	image = MiniMagick::Image.open(url)
	#get face landmarks, only one face in each training data
	landmarks = face[0]['faceLandmarks']
	## left eye
	eyeLeftOuter = landmarks["eyeLeftOuter"]	#get eyeLeftOuter
	eyeLeftTop = landmarks["eyeLeftTop"]	#get eyeLeftTop
	eyeLeftBottom = landmarks["eyeLeftBottom"]	#get eyeLeftBottom
	## right eye
	eyeRightOuter = landmarks["eyeRightOuter"] #get eyeRightOuter
	eyeRightTop = landmarks["eyeRightTop"]	#get eyeRightTop
	eyeRightBottom = landmarks["eyeRightBottom"]	#get eyeRightBottom
	#cropping pos elements
	width = eyeRightOuter["x"].to_f - eyeLeftOuter["x"].to_f	#horizontal length
	start_eyePos = [eyeLeftTop["y"].to_f, eyeRightTop["y"].to_f].min	# eye top in higher position
	max_eyeHeight = [eyeLeftBottom["y"].to_f - eyeLeftTop["y"].to_f, eyeRightBottom["y"].to_f - eyeRightTop["y"].to_f].max #max eye height
	# give some losse to width and height
	crop_str = "#{width + 10}x#{3.5 * max_eyeHeight}+#{eyeLeftOuter["x"].to_f - 5}+#{start_eyePos}"
	image.crop(crop_str)
	return image # return cropped image
end

# Parse responds with multiple Face objects
puts "requesting face objects...(query limit: #{$limit})"
faces = makeFaceObjectGetRequest() # JSON object list

puts "request face objects done."
puts "requesting face landmarks and cropping...(totoal: #{faces.length})"
for face in faces
	faceMarks = makeFaceDectectionPostRequest(face['picture']['url'])
	output = cropEyesFromFace(face['picture']['url'], faceMarks)
	#original file name xx_xx_xx.png, need to add class(ie.neg/pos)
	rename = face['name'].split(".")[0] + "_" + "#{face['class']}.png"
	output.write "Eyes/#{rename}"
	#Microsoft face api rate limit 20 req/min, 3 sec per face
	sleep 3.5
end
puts "work done, yay!"