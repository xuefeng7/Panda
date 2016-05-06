### Process the JSON string and summarize the statistics
### read a file, each line of the file is a json string

require 'json'

$total_selfie = 0 # src sum
$total_face = 0 # face sum

$most_face = 0 # selfie contains most # of faces
$most_face_url = "" # selfie contains most # of face url
$youngest_face = 100 # youngest face age
$youngest_face_url = "" # youngest face url
$oldest_face = 0 # oldest face age
$oldest_face_url = "" # oldest face url
## statistics corresponding to selfies
$s_gender = [0, 0] # gender distribution [male, female]
$s_race = [0, 0, 0] # race distribution [Asian, Black, White]
$s_race_gender = [[0,0], [0,0], [0,0]]
$s_glass = [0, 0] # normal glass distribution [with, without]
$s_age = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # age distribution [0-10, 10-20,20-30,...,90-100]
$s_age_gender = [[0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0]] # age distribution [0-10, 10-20,20-30,...,90-100]
$s_age_race = [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
## statistics corresponding to dark circle/eye bag on faces
$f_gender = [0, 0] # [male(dc/eb), female(dc/eb)]
$f_age = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # age distribution [0-10, 10-20,20-30,...,90-100]
$f_race = [0, 0, 0] # race distribution [Asian(dc/eb), Black(dc/eb), White(dc/eb)]
$f_race_gender = [[0,0], [0,0], [0,0]]
$f_age_gender = [[0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0], [0,0]] # age distribution [0-10(dc/eb), 10-20,20-30,...,90-100]
$f_age_race = [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]
$f_glass = [0, 0] # normal glass distribution [with(dc/eb), without(dc/eb)]

$hp_level = 0 # positive sample with highest confidence
$hp_level_url = "" 
$hp_leve_set = [] # positive confidence > 95
$hn_level = 0 # negative sample with highest confidence
$hn_level_url = ""
$hn_leve_set = [] # negative confidence > 95
## read file line by line
## - param: filename
## - return: nil 
def processFile(filename)
	File.open("#{filename}.txt", "r").each { 
		|line|  
			# increase total source
			$total_selfie += 1
			# source object
			begin
				srcObject = JSON.parse(line)
			rescue
				puts line
				puts filename
				exit
			end
			# get face array
			faces = srcObject["face"]
			# get url
			url = srcObject["url"]
			# increase total face
			$total_face += faces.length
			if faces.length > $most_face then
				$most_face = faces.length
				$most_face_url = srcObject["url"]
			end
			processSelfie(faces, url)
	}
end

## read and process json string
## - param: json string
## - return: json object
def processSelfie(faces, url)

	for face in faces
		# get attributes of each face
		attribute = face["attribute"]
		gender = attribute["gender"]["value"] # get gender
		age = attribute["age"]["value"].to_i # get age
		race = attribute["race"]["value"] # get race
		glass = attribute["glass"]["value"] # get glass
		dceb = attribute["dark_cirlce_eyebag"]["value"] # get dc/eb prediction result
		# selfie with only one face
		if faces.length == 1 then
			if dceb.eql? "positive"	then
				if attribute["dark_cirlce_eyebag"]["confidence"] > 95 then
					$hp_leve_set << [face, url]
				end
				if $hp_level < attribute["dark_cirlce_eyebag"]["confidence"] then
					$hp_level = attribute["dark_cirlce_eyebag"]["confidence"]
					$hp_level_url = url
				end
			else
				if attribute["dark_cirlce_eyebag"]["confidence"] > 95 then
					$hn_leve_set << [face, url]
				end
				if $hn_level < attribute["dark_cirlce_eyebag"]["confidence"] then
					$hn_level = attribute["dark_cirlce_eyebag"]["confidence"]
					$hn_level_url = url
				end
			end	
		end
		## summarize
		# age
		# find youngest
		if $youngest_face > age then
			$youngest_face = age
			$youngest_face_url = url
		end
		# find oldest
		if $oldest_face < age then 
			$oldest_face = age
			$oldest_face_url = url
		end
		$s_age[age / 10] += 1
		checkDCEB(dceb, (age / 10), age, gender)
		# gender
		if gender.eql? "Male" then
			$s_gender[0] += 1 # increase male
			$s_age_gender[age / 10][0] += 1
		else
			$s_gender[1] += 1 # increase female
			$s_age_gender[age / 10][1] += 1
		end
		checkDCEB(dceb, gender, age, gender)
		# race
		if race.eql? "Asian" then
			$s_race[0] += 1
			$s_age_race[age / 10][0] += 1
			# gender distribution in race
			if gender.eql? "Male" then
				$s_race_gender[0][0] += 1
			else
				$s_race_gender[0][1] += 1
			end
		elsif race.eql? "Black"
			$s_race[1] += 1
			$s_age_race[age / 10][1] += 1
			if gender.eql? "Male" then
				$s_race_gender[1][0] += 1
			else
				$s_race_gender[1][1] += 1
			end
		else
			$s_race[2] += 1
			$s_age_race[age / 10][2] += 1
			if gender.eql? "Male" then
				$s_race_gender[2][0] += 1
			else
				$s_race_gender[2][1] += 1
			end
		end
		checkDCEB(dceb, race, age, gender)
		# glass condition
		if glass.eql? "None" then
			$s_glass[1] += 1
		else
			$s_glass[0] += 1 # with glass
		end
		checkDCEB(dceb, glass, age, gender)
 	end
end

## check if the face is a positive sample, and
## increase counter accordingly
## - param: face dceb
## - return: nil  
def checkDCEB(dceb, attribute, age, gender) 
	# positive sample
	if dceb.eql? "positive" then
		case attribute
			when "Male"
				$f_gender[0] += 1
				$f_age_gender[age / 10][0] += 1
			when "Female"
				$f_gender[1] += 1
				$f_age_gender[age / 10][1] += 1
			when "Asian"
				$f_race[0] += 1
				$f_age_race[age / 10][0] += 1
				if gender.eql? "Male" then
					$f_race_gender[0][0] += 1
				else
					$f_race_gender[0][1] += 1
				end
			when "Black"
				$f_race[1] += 1
				$f_age_race[age / 10][1] += 1
				if gender.eql? "Male" then
					$f_race_gender[1][0] += 1
				else
					$f_race_gender[1][1] += 1
				end
			when "White"
				$f_race[2] += 1
				$f_age_race[age / 10][2] += 1
				if gender.eql? "Male" then
					$f_race_gender[2][0] += 1
				else
					$f_race_gender[2][1] += 1
				end
			when 0..9 # age interval index
				$f_age[attribute] += 1
			when "None" # galss
				$f_glass[1] += 1
			when "Normal"
				$f_glass[0] += 1
			else
				# default, skip
		end
	end
end

filenames = ["tumblr"] # file to process

for name in filenames

	processFile(name) # read file
	output = File.new("statistics.txt", "a+") # prepare output file
	## Printing
	## selfie statistics
	output.puts "#{name}:"
	output.puts "---------------------"
	output.puts "total selfies: #{$total_selfie}"
	output.puts "total faces: #{$total_face}"
	output.puts "selfie has most faces: #{$most_face}"
	output.puts "url: #{$most_face_url}"
	output.puts "youngest face: #{$youngest_face}"
	output.puts "url: #{$youngest_face_url}"
	output.puts "oldest face: #{$oldest_face}; url:#{$oldest_face_url}"
	output.puts "url: #{$oldest_face_url}"
	output.puts "male:#{$s_gender[0]}; female:#{$s_gender[1]}"
	# age loop
	for ageIndex in 0..10
		output.puts "#{ageIndex}: #{$s_age[ageIndex]} [#{$s_age_gender[ageIndex][0]} #{$s_age_gender[ageIndex][1]}] [#{$s_age_race[ageIndex][0]} #{$s_age_race[ageIndex][1]} #{$s_age_race[ageIndex][2]}]"
	end
	output.puts "Asian:#{$s_race[0]}; [male:#{$s_race_gender[0][0]}, female:#{$s_race_gender[0][1]}]"
	output.puts "Black:#{$s_race[1]}; [male:#{$s_race_gender[1][0]}, female:#{$s_race_gender[1][1]}]" 
	output.puts "White:#{$s_race[2]}; [male:#{$s_race_gender[2][0]}, female:#{$s_race_gender[2][1]}]"
	output.puts "Glass:#{$s_glass[0]}; Non-glass: #{$s_glass[1]}"
	## dceb statistics
	output.puts "---------------------"
	output.puts "positive sample with highest confidence: #{$hp_level}"
	output.puts "url: #{$hp_level_url}"
	output.puts "negative sample with highest confidence: #{$hn_level}"
	output.puts "url: #{$hn_level_url}"
	output.puts "male:#{$f_gender[0]}; female:#{$f_gender[1]}"
	# age loop
	for ageIndex in 0..10
		output.puts "#{ageIndex}: #{$f_age[ageIndex]} [#{$f_age_gender[ageIndex][0]} #{$f_age_gender[ageIndex][1]}] [#{$f_age_race[ageIndex][0]} #{$f_age_race[ageIndex][1]} #{$f_age_race[ageIndex][2]}]"
	end
	output.puts "Asian:#{$f_race[0]}; [male:#{$f_race_gender[0][0]}, female:#{$f_race_gender[0][1]}]"
	output.puts "Black:#{$f_race[1]}; [male:#{$f_race_gender[1][0]}, female:#{$f_race_gender[1][1]}]" 
	output.puts "White:#{$f_race[2]}; [male:#{$f_race_gender[2][0]}, female:#{$f_race_gender[2][1]}]"
	output.puts "Glass:#{$f_glass[0]}; Non-glass: #{$f_glass[1]}"
	# EOF
	output.puts '#######################################'
end

high_confidence_file = File.new("high_confidence.txt", "a+") # prepare output file
high_confidence_file.puts "Positive(#{$hp_leve_set.length})"
for set in $hp_leve_set
	high_confidence_file.puts [set[0], set[1]]
end
high_confidence_file.puts '######################################'
high_confidence_file.puts "Negative(#{$hn_leve_set.length})"
for set in $hn_leve_set
	high_confidence_file.puts [set[0], set[1]]
end