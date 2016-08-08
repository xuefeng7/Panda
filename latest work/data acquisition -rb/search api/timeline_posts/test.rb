
require 'net/http'
require 'json'
require 'uri'
require "open-uri"

require "logger"

$api_key = "a9278032efdf15b8cbbecdf7fccb526b"
$api_secret = "XXByJ2S115vEHTlK5hqKFCwnoFD2V_gg"

$detectPrefix = "https://apius.faceplusplus.com/v2/detection/detect?"
$landmarkPrefix = "https://apius.faceplusplus.com/detection/landmark?"
$faceSetPrefix = "https://apius.faceplusplus.com/v2/faceset/"
$groupingPrefix = "https://apius.faceplusplus.com/v2/grouping/grouping?"
$sessionPrefix = "https://apius.faceplusplus.com/v2/info/get_session?api_secret=#{$api_secret}&api_key=#{$api_key}&"
## detect faces in each givne photo
$attribute = "gender,age,race,glass"

def detectFace(path)
	
	# face detection
	dtUrl = $detectPrefix + "url=#{path}&api_key=#{$api_key}&api_secret=#{$api_secret}&attribute=#{$attribute}"
	dtResp = createAndSendHttpReq(dtUrl, 2)
	faces = dtResp["face"] # face array

	return faces
end

## add faces to each faceset
def addFaces(faces, id)
	faceIds = ""
	for face in faces 
		faceIds += "#{face['face_id']},"
	end
	# remove last comma in faceIds
	faceIds = faceIds[0..-2]
	afUrl = $faceSetPrefix + "add_face?api_secret=#{$api_secret}&face_id=#{faceIds}&api_key=#{$api_key}&faceset_name=#{id}"
	afRes = createAndSendHttpReq(afUrl, 2)
	return afRes
end

## grouping
def grouping(id)
	gUrl = $groupingPrefix + "api_secret=#{$api_secret}&faceset_name=#{id}&api_key=#{$api_key}"
	gResp = createAndSendHttpReq(gUrl, 2)
	return gResp['session_id']
end

## parse grouping results
def parseGroupingResult(res, userId)
	 ## res contains two arrays, one for grouped and one for ungrouped
	 #[face1:[attributes, [[path1, [landmarks]],[path1, [landmarks]], ...], ],face2[...],...]
	 userTimeLine = Hash.new
	 timeLineFaces = []
	 grouped = res["group"]
	 ungrouped = res["ungrouped"] # only one in the group
	 # combine
	 for ungroup in ungrouped
	 	grouped << [ungroup]
	 end

	 for group in grouped # group contains all faces from the same person
	 	# get attribution of the face from one photo 
	 	# is enough to be representative
	 	attributes = $faceAttrArray[group[0]["face_id"]][0]
	 	photos = []
	 	for face in group # each face from same person
	 		srcUrl = $faceAttrArray[face["face_id"]][1]
	 		landmark = faciaLandMark[face["face_id"]]
	 		photos << [srcUrl, landmark]
	 	end
	 	 timeLineFaces << [attributes, photos]
	 end
	 userTimeLine[userId] = timeLineFaces
	 # convert Hash to JSON and write to file
	 $result_1.puts userTimeLine.to_json
end

def createAndSendHttpReq(url, type) # type 1 = GET, type 2 = POST
	
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	
	req = ""
	#init header
	if type == 1 then
		req = Net::HTTP::Get.new(uri.request_uri, initheader = {
		})
	elsif type == 2 then
		req = Net::HTTP::Post.new(uri.request_uri, initheader = {
		'Content-Type' => "application/json"
		})
	end
	
	begin 
		resp = http.request(req) # actual request
	rescue
		puts "http request error" # http error
	end
	
	return JSON.parse(resp.body)
end

def getSessionStatus(session)
	sessionUrl = $sessionPrefix + "session_id=#{session}"
	sessionRespBody =  createAndSendHttpReq(sessionUrl, 1)
	return sessionRespBody["result"]
end

# #addFaces(detectFace("http://pbs.twimg.com/media/Cjst3fvWkAAoQxh.jpg"), "38191574")
# res = getSessionStatus("118ea379dc6f40118bc5ef28aa0aa118")

# grouped = res["group"]
# ungrouped = res["ungrouped"] # only one in the group
# for ungroup in ungrouped
# 	grouped << [ungroup]
# end
# puts grouped.size

def deleteFaceSet(id)
	
	url = $faceSetPrefix + "delete?api_key=#{$api_key}&api_secret=#{$api_secret}&faceset_name=#{id}"
	resp = createAndSendHttpReq(url, 2)
	status = resp["success"]

	return status
end

# ids = ["2567650640","38191574","710205446615863296","720627998790037505"]
# for id in ids 
# 	puts deleteFaceSet(id)
# end

# rfile = File.open("timelineProcessing.rb", "a+")

# rfile.each_line { 
# 	|line| 
# 		if line.strip!.start_with?("puts") then
# 			line.gsub("puts", "log.info") 
# 		end 
# }


at_exit do
	for index in 0..10000
		puts index
		sleep 5
	end
end


