### This file will query face++ api for each user and his/her time posts
### the query includes face detection, faceset creation, face adding, and face grouping
### there will be 10 api-key each of which will takes care of one fold of the timeline posts

### during the process, if any step causes the error (highly possible sever error)
### put the current user and its timeline aside to another file for collecting error case
require 'net/http/post/multipart'
require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "yaml"
require 'logger'

#/// File indexer
$fileIndex = 0
#/// Line skip
$skipLine = 0
#/// Sever Auth
$api_key = ""
$api_secret = ""

#/// Read args from command line
if ARGV.size != 4 then
	raise "four args are required"
elsif ARGV[0] =~ /\A\d+\z/ ? false: true then
	raise "arg should ba an integer from 1 to 10"
elsif  ARGV[0].to_i > 10 ||  ARGV[0].to_i < 0 then
	raise "arg should ba an integer from 1 to 10"
else
	$fileIndex = ARGV[0]
	$api_key = ARGV[1]
	$api_secret =  ARGV[2]
	$skipLine = ARGV[3]
end
# sleep time
$delay = 0.05

#/// DEBUG
#// For $logging to both STDOUT and $Log file
#///

$log = Logger.new("| tee debug/debug_#{$fileIndex}.log")


$detectPrefix = "https://apius.faceplusplus.com/v2/detection/detect?"
$landmarkPrefix = "https://apius.faceplusplus.com/detection/landmark?"
$faceSetPrefix = "https://apius.faceplusplus.com/v2/faceset/"
$groupingPrefix = "https://apius.faceplusplus.com/v2/grouping/grouping?"
$sessionPrefix = "https://apius.faceplusplus.com/v2/info/get_session?api_secret=#{$api_secret}&api_key=#{$api_key}&"

$attribute = "gender,age,race,glass,smiling"

$faceAttrArray = Hash.new #[faceId: attr]

$faceSetCurrentSize = 0

$faceSetMaxSize = 5
$faceSetSessions = Hash.new #[userId: session]

$result_1 = File.open("Faces/result_#{$fileIndex}.txt", "a+")
$error_1 =  File.open("Error/error_#{$fileIndex}.txt", "a+")

#///
#// Timeline post and face processing methods
#///

## for each user, use their id to create a faceset
def createFaceSet(id)

	url = $faceSetPrefix + "create?api_key=#{$api_key}&api_secret=#{$api_secret}&faceset_name=#{id}"
	resp = createAndSendHttpReq(url, 2)
	
	return resp["faceset_id"]
end

## delete faceset
def deleteFaceSet(id)
	
	url = $faceSetPrefix + "delete?api_key=#{$api_key}&api_secret=#{$api_secret}&faceset_name=#{id}"
	resp = createAndSendHttpReq(url, 2)
	status = resp["success"]

	return status
end

## run loop to force deleteface succeed 
def forceToDeleteFaceSet(id, session) # session is optional
	
	if id == "" then
		id = $faceSetSessions.key(session)
	end

	while true
		if deleteFaceSet(id) ## when true, jump out of the while loop
			$faceSetCurrentSize -= 1
			# clear the session from the session array
			if session != "" then
				$faceSetSessions.delete(id)
			end
			$log.info "one session has been closed"
			break
		end
		sleep $delay
	end
end

## detect faces in each givne photo
def detectFace(path)
	
	# face detection
	dtUrl = $detectPrefix + "url=#{path}&api_key=#{$api_key}&api_secret=#{$api_secret}&attribute=#{$attribute}"
	# open("temp_image_#{$fileIndex}.jpg", 'wb') do |file|
 #  		file << open(path).read
 #  	end
	#binaryData = File.binread 
	dtResp = createAndSendHttpReq(dtUrl, 2)
	# `rm temp_image_#{$fileIndex}.jpg`
	#puts dtResp
	faces = dtResp["face"] # face array
	size = [dtResp['img_width'], dtResp['img_height']]
	path = [path, size]
	# temporarily record each facial attributions
	if faces.size <= 0 then
		return []
	end

	for face in faces
		#puts "#{face['face_id']}: local-#{path} ** face++-#{dtResp['url']}"
		$faceAttrArray[face["face_id"]] = [face["attribute"], path]
	end

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

## get facial landmarks for each face
def faciaLandMark(faceId)
	# face landmarks
	lmUrl = $landmarkPrefix + "api_key=#{$api_key}&api_secret=#{$api_secret}&face_id=#{faceId}&type=25p"
	lmResBody = createAndSendHttpReq(lmUrl, 1)
	# prune the landmarks
	fullLandMarks = lmResBody["result"][0]["landmark"]
	
	return fullLandMarks#pruneLandMarks(fullLandMarks)
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
	 	for face in group # each face from the same person
	 		srcUrl = $faceAttrArray[face["face_id"]][1]
	 		landmark = faciaLandMark(face["face_id"])
	 		photos << [srcUrl, landmark]
	 		# clear parsed face
			$faceAttrArray.delete(face["face_id"])
	 	end
	 	 timeLineFaces << [attributes, photos]
	 end
	 userTimeLine[userId] = timeLineFaces
	 # convert Hash to JSON and write to file
	 $result_1.puts userTimeLine.to_json
end

## prune the landmarks for only keep useful data
# def pruneLandMarks(landmark)
# 	prunedLandmark = Hash.new
# 	# only need 8 pts
# 	# left_eye_bottom
# 	prunedLandmark["left_eye_bottom"] = landmark["left_eye_bottom"]
# 	# left_eye_top
# 	prunedLandmark["left_eye_top"] = landmark["left_eye_top"]
# 	# left_eye_left_corner
# 	prunedLandmark["left_eye_left_corner"] = landmark["left_eye_left_corner"]
# 	# left_eye_right_corner
# 	prunedLandmark["left_eye_right_corner"] = landmark["left_eye_right_corner"]
# 	# right_eye_bottom
# 	prunedLandmark["right_eye_bottom"] = landmark["right_eye_bottom"]
# 	# right_eye_top
# 	prunedLandmark["right_eye_top"] = landmark["right_eye_top"]
# 	# right_eye_left_corner
# 	prunedLandmark["right_eye_left_corner"] = landmark["right_eye_left_corner"]
# 	# right_eye_right_corner
# 	prunedLandmark["right_eye_right_corner"] = landmark["right_eye_right_corner"]
# 	return prunedLandmark
# end

## Parse single face info to file
def parseFace(userId, faceId)
	attribute = $faceAttrArray[faceId][0]
	url = $faceAttrArray[faceId][1]
	landmark = faciaLandMark(faceId)
	userTimeLine = Hash.new
	userTimeLine[userId] = [[attribute, [url, landmark]]]
	$result_1.puts userTimeLine.to_json
	# clear parsed face
	$faceAttrArray.delete(faceId)
end

## Check sessions
def sessionCheck()
	# check if results are available
	for key in $faceSetSessions.keys

		session = $faceSetSessions[key]
		sessionUrl = $sessionPrefix + "session_id=#{session}"
		sessionRespBody =  createAndSendHttpReq(sessionUrl, 1)
		
		if sessionRespBody['status'] == 'SUCC' then
			$log.info "one session status has became to SUCC"
			# process the returned groupping result
			#puts sessionRespBody["result"]
			parseGroupingResult(sessionRespBody["result"], key)
			# remove faceset, make sure no error happens
			# if error occurs, re-send the request until the set is deleted
			forceToDeleteFaceSet("", session)
		end
	sleep $delay
	end
end

## combine all processing methods
def processTimeLine(userId, paths)

	# create a faceset first
	$log.info "creating face set with id: #{userId}"
	createFaceSet(userId)
	$faceSetCurrentSize += 1 # increment faceset amount
	$log.info "faceset has been created"
	# detect faces for each path
	$log.info "detecting faces for paths"
	faceCount = 0
	faceIds = [] # temporarily hold all face ids for each user
	for path in paths
		#begin
			# no face might be detected
			# in this case, skip
			begin
				faces = detectFace(path) # placeholder filled
			rescue
				next
			end
			faceCount += faces.size
			if faces.size > 0 then
				for face in faces 
					faceIds << face["face_id"]
				end
				addFaces(faces, userId)
			else
				#puts "no face has been detected for #{path}"
			end
			sleep $delay
		#rescue
			#puts "no face has been detected for #{path}"
		#	next # skip to next
		#end
	end

	## no faces has been detected from all paths
	if faceCount == 0 then
		# delete created faceset
		forceToDeleteFaceSet(userId, "")
		# skip to next user
		raise 'trivial error' # will be catched, and move to next user
	elsif faceCount == 1 then
		# write face info to file
		# only one face in faceAttrArray
		parseFace(userId, faceIds[0])
		forceToDeleteFaceSet(userId, "")
		raise 'trivial error'
		# move to next user
	end
	## grouping, when faceCount > 2
	## - the groupping result will not be available synchronously, shall later query with session_id
	$log.info "sending grouping request"
	session_id = grouping(userId)
	$faceSetSessions[userId] = session_id

	## max faceset number has been reached
	## run loop wait to remove faceset
	while $faceSetCurrentSize >= $faceSetMaxSize 
		$log.info "faceset max size has been reached, loop to wait"
		sessionCheck()
	end
end

#///
##// Utility methods
#///

## create http resquest and return response
## catch possible error
def createAndSendHttpReq(url, type) # type 1 = GET, type 2 = POST, type 3 = POST binary file
	
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
	elsif type == 3 then
		# need to upload the bitmap file
		resp = ""
		begin
			File.open("temp_image_#{$fileIndex}.jpg") do |jpg|
		  		req = Net::HTTP::Post::Multipart.new uri.path,
		    		"img" => UploadIO.new(jpg, "image/jpeg", "image.jpg"),
		    		"api_key" => $api_key,
		    		"api_secret" => $api_secret
		  		resp = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
		    		http.request(req)
	  			end
			end
			return JSON.parse(resp.body)
		rescue
			$log.info "http request error for detecting" # http error
		end
	end
	
	begin 
		resp = http.request(req) # actual request
	rescue
		$log.info "http request error" # http error
	end

	return JSON.parse(resp.body)
end

def recordError(eFile, eDict) # eInfo = [id, paths]
	error = Hash.new
	error[eDict[0]] = [eDict[2], eDict[1]]
	eFile.puts error.to_json
end

#/// read src from yml files
$log.info "loading..."
name = "err_#{$fileIndex}.yml"
src = YAML.load_file(name)
$log.info "YML file #{name} has been loaded"

count = 0
for user in src.keys
	count += 1
	if count <= $skipLine.to_i then
		next
	end 
	$log.info "processing user No. #{count}"
	paths = src[user]
	begin
		processTimeLine(user, paths)
	rescue => error
		if error.message != "trivial error" then
			# record the error
			recordError($error_1, [user, paths, error.message, error.backtrace])
			# force to delete the faceset by userId
			forceToDeleteFaceSet(user, "")
		else
			# skip
			$log.info "trivial error: move to the next user"
		end
		next
	end
end
## when program ends, 
## check if there is any session has not been closed
at_exit do
	while $faceSetSessions.size > 0
		sessionCheck()
	end
end 
