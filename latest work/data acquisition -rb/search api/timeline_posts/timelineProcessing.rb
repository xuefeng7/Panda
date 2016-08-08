### This file will query face++ api for each user and his/her time posts
### the query includes face detection, faceset creation, face adding, and face grouping
### there will be 10 api-key each of which will takes care of one fold of the timeline posts

### during the process, if any step causes the error (highly possible sever error)
### put the current user and its timeline aside to another file for collecting error case

require 'net/http'
require 'json'
require 'uri'
require "open-uri"
require "yaml"
require 'logger'

#/// File indexer
$fileIndex = 0
#/// Sever Auth
$api_key = ""
$api_secret = ""

#/// Read args from command line
if ARGV.size != 3 then
	raise "three args are required"
elsif ARGV[0] =~ /\A\d+\z/ ? false: true then
	raise "arg should ba an integer from 1 to 10"
elsif  ARGV[0].to_i > 10 ||  ARGV[0].to_i < 0 then
	raise "arg should ba an integer from 1 to 10"
else
	$fileIndex = ARGV[0]
	$api_key = ARGV[1]
	$api_secret =  ARGV[2]
end

#/// DEBUG
#// For $logging to both STDOUT and $Log file
#///

$log = Logger.new("| tee debug/debug_#{$fileIndex}.log")


$detectPrefix = "https://apius.faceplusplus.com/v2/detection/detect?"
$landmarkPrefix = "https://apius.faceplusplus.com/detection/landmark?"
$faceSetPrefix = "https://apius.faceplusplus.com/v2/faceset/"
$groupingPrefix = "https://apius.faceplusplus.com/v2/grouping/grouping?"
$sessionPrefix = "https://apius.faceplusplus.com/v2/info/get_session?api_secret=#{$api_secret}&api_key=#{$api_key}&"

$attribute = "gender,age,race,glass"

$faceAttrArray = Hash.new

$faceSetCurrentSize = 0

$faceSetMaxSize = 5
$faceSetSessions = []

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
def forceTodeleteFaceSet(id, session) # session is optional
	while true 
		if deleteFaceSet(id) ## when true, jump out of the while loop
			$faceSetCurrentSize -= 1
			# clear the session from the session array
			if session != "" then
				$faceSetSessions.delete(session)
			end
			$log.info "one session has been closed"
			break
		end
	end
end

## detect faces in each givne photo
def detectFace(path)
	
	# face detection
	dtUrl = $detectPrefix + "url=#{path}&api_key=#{$api_key}&api_secret=#{$api_secret}&attribute=#{$attribute}"
	dtResp = createAndSendHttpReq(dtUrl, 2)
	faces = dtResp["face"] # face array

	# temporarily record each facial attributions
	for face in faces
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
	return lmResBody["result"][0]["landmark"]
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
	 		landmark = faciaLandMark[face["face_id"]]
	 		photos << [srcUrl, landmark]
	 	end
	 	 timeLineFaces << [attributes, photos]
	 end
	 userTimeLine[userId] = timeLineFaces
	 # convert Hash to JSON and write to file
	 $result_1.puts userTimeLine.to_json
end

## Parse single face info to file
def parseFace(userId)
	faceId = $faceAttrArray.keys[0]
	attribute = $faceAttrArray[faceId][0]
	url = $faceAttrArray[faceId][1]
	landmark = faciaLandMark(faceId)
	userTimeLine = Hash.new
	userTimeLine[userId] = [[attribute, [url, landmark]]]
	$result_1.puts userTimeLine.to_json
end

## Check sessions
def sessionCheck()
	# check if results are available
	for session in faceSetSessions
		
		sessionUrl = $sessionPrefix + "session_id=#{session}"
		sessionRespBody =  createAndSendHttpReq(sessionUrl, 1)
		
		if sessionRespBody['status'] == 'SUCC' then
			$log.info "session status for #{userId} became to SUCC "
			# process the returned groupping result
			parseGroupingResult(sessionRespBody["result"], sessionRespBody["result"]["faceset_name"])
			# remove faceset, make sure no error happens
			# if error occurs, re-send the request until the set is deleted
			forceTodeleteFaceSet(sessionRespBody["result"]["faceset_name"], session)
		end
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
	for path in paths
		begin
			# no face might be detected
			# in this case, skip
			faces = detectFace(path)
			faceCount += faces.size
			if faces.size > 0 then
				addFaces(faces, userId)
			else
				#puts "no face has been detected for #{path}"
			end
		rescue
			#puts "no face has been detected for #{path}"
			next # skip to next
		end
	end

	## no faces has been detected from all paths
	if faceCount == 0 then
		# delete created faceset
		forceTodeleteFaceSet(userId, "")
		# skip to next user
		raise 'trivial error' # will be catched, and move to next user
	elsif faceCount == 1 then
		# write face info to file
		# only one face in faceAttrArray
		parseFace(userId)
		forceTodeleteFaceSet(userId, "")
		raise 'trivial error'
		# move to next user
	end
	## grouping, when faceCount > 2
	## - the groupping result will not be available synchronously, shall later query with session_id
	$log.info "sending grouping request"
	session_id = grouping(userId)
	$faceSetSessions << session_id
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
name = "timeline_#{$fileIndex}.yml"
src = YAML.load_file(name)
$log.info "YML file #{name} has been loaded"

count = 0
for user in src.keys
	count += 1
	$log.info "processing user No. #{count}"
	paths = src[user]
	begin
		processTimeLine(user, paths)
	rescue => error
		if error.message != "trivial error" then
			# record the error
			recordError($error_1, [user, paths, error.message, error.backtrace])
		else
			# skip
			$log.info "trivial error: move to the next user"
		end
		exit
		next
	end
	exit
end
## when program ends, 
## check if there is any session has not been closed
at_exit do
	sessionCheck()
end