Introdunction
-----------------
This project focuses on the dark circle and eye bag analysis on social media seflies. The major sources in this project folder are: social media search api that can grab selfie tagged posts from twitter, tumblr, and flickr; a iOS app designed for training data labeing; and a binary classification model, and prediction.

Directories
-----------------
data acquisition -rb

	-- training data processing
		
		- train.txt 

			This file contains all the training images' information, each line is in the format of (name&class&landmarks), where the landmarks is, in ruby, like: #{l_x}&#{l_y}&#{leftWidth}&#{leftHeight}&#{r_x}&#{r_y}&#{rightWidth}&#{rightHeight}, where l_x and l_y stands for left eye outer x and left eye bottom y coordinates respectively. 
		
		- faceProcessing.rb 

			This file query Face++ api to acquire the facial landmarks of each training image, and write all information into tran.txt

		- request.rb

			This file upload all training image to my server so the labeling App can obtain the images.

		- read.rb

			This file unzip the images data from color FERET database

		- ppm2png.m

			This script converts image from ppm format to png format

	-- search api

		- flickr.rb

			This file queries flickr search api to obtain all selfie tagged posts. Note that the flickr returns at most 4000 images even if the total amount of search result is enormous. 

		- tumblr.rb

			This file queries tumblr search api. More details can be found on Tumblr search api documentation webpage.

		- tweet.rb

			This file queries twitter search api. More details can be found on Twitter search api documentation webpage, but note that twitter api has rate limit, which is 450 reqs/15mins, and each request will return at most 100 JSON results.

	-- raw url#seflie

			All files under this sub-directory are the urls returned from Filckr, Twitter, and Tumblr search apis. However, even though the posts associated with those urls are tagged with selfie, they are not guaranteed to have human face at all.

binary classification app -swift
	
	-- Xcode project is included

model and prediction-matlab
	
	-- SVM training

		- SVMTraining.m

			This is a function script that trains the binary classification SVM model. More details can be found from the comments on the script.

	-- SVM predicting

		- SVMTesting.m

			This is a function script that processes the selfie urls, predict, and writes all results into the result.txt file.

	-- Others

		- ExtractFeature.m 

			This is a function script, it extracts the interest areas from given selfie. More details can be found from the comments on the script.

		- getFeatureVector.m

			This is a function script, it extracts the feature vector from given interest area patch. More details can be found from the comments on the script.

		- isContainFace.m

			This is a function script, it runs face detector from Matlab computer vision toolbox to do a preliminary face detection to prevent SVMTesting.m does trivial query to face++. More details can be found from the comments on the script.
	
		- AcquireFaceSampleInfo.m
			
			This is a function script queries face++ to obtain facial attributions and landmarks for feature extraction and create observation and related face object to SVMTesting.
	
	-- urls

		The files under this sub-directory are the same as the files under raw url#seflie.

	-- ScoreSVM.mat

		This is the completed posterior probability SVM model.

	-- VLFEATROOT

		This is a third party library that implemented the SIFT and DENSE SIFT algorithm, more details about its usage can be found at http://www.vlfeat.org

result

	- statistics.rb

		This file summarize the statistics from the predicted face objects

	- statistics.txt

		The statistical summary of faces detected from Twitter and Tumblr respectively

	- sum.txt

		The combined statistical summary of all faces detected from both Twitter and Tumblr

	- high_confidence.txt

		The faces that has higher than 95% prediction confidence. Each face is represented by JSON string





