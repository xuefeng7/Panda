## This is the file that use Face++ Face detection Services API
## to obtain landmark points of face images
## and crop the interest objects (in this case eyes) store to cloud

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "mini_magick"
require 'simple_progressbar'

#Face++ API keys
$subscription_key = "-"
$subscription_secret = "-"
#Parse API keys
$appId = "-"
$appKey = "-"
#Faces class url
$faceUrl = "https://api.parse.com/1/classes/Faces"
#Face object query limit
$limit = 10000

### make post request to Face++ face detection server
## - param: image url
## - return: response data
def makeFaceDectectionPostRequest(url)
#create http POST request
#static Microsoft Face detection API url
uri = URI.parse("https://apius.faceplusplus.com/v2/detection/detect?url=#{url}&api_secret=#{$subscription_secret}&api_key=#{$subscription_key}&attribute=glass,gender,age,race")
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
### make post request to Face++ face landmarks detection server
## - param: face_id
## - return: response data
def makeFaceLandmarksGetRequest(face_id)
uri = URI.parse("https://apius.faceplusplus.com/v2/detection/landmark?&api_secret=#{$subscription_secret}&api_key=#{$subscription_key}&face_id=#{face_id}&type=25p")
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
### make get request to Parse server to obtain a list of face object
## - param: nil
## - return: response data
def makeFaceObjectGetRequest()
#make http GET request
constrain = URI::encode({:tag => "newn"}.to_json)
uri = URI.parse($faceUrl + "?limit=#{$limit}&skip=665&where=#{constrain}") #add query constrain
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
## - params: image, response data from Microsoft face detection server, image height, image width
## - return: cropped image 
def cropEyesFromFace(url, face, img_height, img_width)
	#open a image file from url
	image = MiniMagick::Image.open(url)
	## NOTE: the landmark points' x and y value
	## are in the scale of 0-100% of the image's width and height
	#get face landmarks, only one face in each training data
	frame = ""
	if face["result"].length > 0 then
		landmarks = face["result"][0]['landmark']
		## left eye
		eyeLeftOuter = landmarks["left_eye_left_corner"]["x"].to_f / 100.0 * img_width 	#get eyeLeftOuter
		eyeLeftInner = landmarks["left_eye_right_corner"]["x"].to_f / 100.0 * img_width 	#get eyeLeftInner
		eyeLeftTop = landmarks["left_eye_top"]["y"].to_f / 100.0 * img_height #get eyeLeftTop
		eyeLeftBottomY = landmarks["left_eye_bottom"]["y"].to_f / 100.0 * img_height	#get eyeLeftBottom
		eyeLeftBottomX = landmarks["left_eye_bottom"]["x"].to_f / 100.0 * img_width	#get eyeLeftBottom
		## right eye
		eyeRightOuter = landmarks["right_eye_right_corner"]["x"].to_f / 100.0 * img_width  #get eyeRightOuter
		eyeRightInner = landmarks["right_eye_left_corner"]["x"].to_f / 100.0 * img_width 	#get eyeRightInner
		eyeRightTop = landmarks["right_eye_top"]["y"].to_f / 100.0 * img_height	#get eyeRightTop
		eyeRightBottomY = landmarks["right_eye_bottom"]["y"].to_f / 100.0 * img_height	#get eyeRightBottom
		eyeRightBottomX = landmarks["right_eye_bottom"]["x"].to_f / 100.0 * img_width	#get eyeRightBottom
		#cropping pos elements
		#width = eyeRightOuter - eyeLeftOuter	#horizontal length
		#start_eyePos = [eyeLeftTop, eyeRightTop].min	# eye top in higher position
		#max_eyeHeight = [eyeLeftBottom - eyeLeftTop, eyeRightBottom - eyeRightTop].max #max eye height
		# give some losse to width and height
		#crop_str = "#{width + 10}x#{3.5 * max_eyeHeight}+#{eyeLeftOuter - 5}+#{start_eyePos}"
		#image.crop(crop_str)
		#max_width = [eyeleft]
		leftWidth = (eyeLeftInner - eyeLeftOuter).round
		leftHeight = (eyeLeftBottomY - eyeLeftTop).round
		rightWidth = (eyeRightOuter - eyeRightInner).round
		rightHeight = (eyeRightBottomY - eyeRightTop).round
		# the interest area below left eye 
		l_x = (eyeLeftBottomX - leftWidth / 2).round
		l_y = eyeLeftBottomY.round
		# the interest area below right eye 
		r_x = (eyeRightBottomX - rightWidth / 2).round
		r_y = eyeRightBottomY.round

		frame = "#{l_x}&#{l_y}&#{leftWidth}&#{leftHeight}&#{r_x}&#{r_y}&#{rightWidth}&#{rightHeight}"
	end
	#puts frame
	# only return frame descriptor
	return frame#[image, ] # return cropped image and frame info
end

option = 2

train = File.open('newn.txt','a+')
if option == 1 then
count = 0
train.each do |line|
	count += 1
end
puts count
else
# Parse responds with multiple Face objects
puts "requesting face objects...(query limit: #{$limit})"
faces = makeFaceObjectGetRequest() # JSON object list

puts "request face objects done."
puts "requesting face landmarks and cropping...(totoal: #{faces.length})"

  (0..(faces.length - 1)).each {|i|
  		face = faces[i]
		faceInfo = makeFaceDectectionPostRequest(face['picture']['url'])
		if faceInfo == [] && faceInfo["face"] == [] then
			#ignore
	    else
	    	faceId = faceInfo["face"][0]["face_id"]
			img_height = faceInfo["img_height"]
			img_width = faceInfo["img_width"]
			output = cropEyesFromFace(face['picture']['url'], makeFaceLandmarksGetRequest(faceId), img_height, img_width)
			# original file name xx_xx_xx.png, need to add class(ie.neg/pos)
			# rename = face['name'].split(".")[0] + "_" + "#{face['class']}.png"
			# output.write "Eyes/#{rename}"
			# show progress
			# progress i / faces.length
			# Microsoft face api rate limit 20 req/min, 3 sec per face
			# sleep 0.5
			if output != "" then
				info = "#{face['name']}&#{face['class']}&#{output}\n"
				train.puts(info)
			end
	    end
  }
puts "work done, yay!"
end

#[["00043_931230_fa.png","https://s3.amazonaws.com/avos-cloud-etos3zlqppdq/LnxaqUrgPWurz75qQleLLmzCnsCMors7WYV5cDIv.png"],["00043_931230_fb.png","https://s3.amazonaws.com/avos-cloud-etos3zlqppdq/EFRem8fgq5ImYYqMXK21vWXNgaqYjgD4TF8JYMVM.png"],["00043_931230_hl.png","https://s3.amazonaws.com/avos-cloud-etos3zlqppdq/tf1BTeNHlqXVaYAie7u3m5wcYnUVVsEWnrfEiqBc.png"],["00043_931230_pl.png","https://s3.amazonaws.com/avos-cloud-etos3zlqppdq/RDb9KSaez1Na4kLATU2vFbbPiUTUUaLvkJ4gcb8S.png"],["00043_931230_pr.png","https://s3.amazonaws.com/avos-cloud-etos3zlqppdq/fwc4W4OF3Bt2RyJKqTtwjp6EqrPsxeNija18yHBg.png"]]