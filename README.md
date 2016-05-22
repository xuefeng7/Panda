![panda](https://github.com/xuefeng7/Panda/blob/master/logo.png "Panda")
# Project Panda
## Goal
  This project focuses on analyzing the periorbital hyperpigmentation and puffiness of faces on social media. The future work tends to establish a strong correlation between the periorbital hyperpigmentation and puffiness and sleeping condition.
## Current works
  The current works are employing multiple CV and data mining techniques and all the source files are included in this repository. Also, we have already analyzed the over 100,000 faces on Twitter and Tumblr, and more faces will be analyzed in the foreseeable future. The followings are the abstract and the brief introduction of this project.
### Abstract
  Periorbital Hyperpigmentation(POH) and Puffiness(PP) become more and more popular among modern people, and these two symptoms are two direct reflections of stress, sleep deprivation, and some modern diseases. Therefore, the POH and PP distribution among age, gender, and race would be insightful for those who intend to analyze the sleep condition, stress degree, and etc. In this project, we have used computer vision and data mining techniques to run the POH/PP analysis on over 150,000 selfies on Twitter and Tumblr. The outcome, in a nutshell, is among 100,000 detected faces, the POH/PP population increments with age, male POH/PP population is larger than that of female, and among Asian, Black and White, the Black race has the highest POH/PP population percentage.
### Introduction
  Periorbital Hyperpigmentation can be commonly found among people nowadays. From medical perspective, the appearance of POH is related to many factors such as stress, sleep deprivation, and etc[3]. Similary, Periorbital Puffiness (PP), sometimes refers to Periorbital Oedema, also indicates health related issues. Thus, it is pragmatic to study POH and PP populations to acquire insights on the distributions of such symptoms in accordance with age, gender, and race, and apply these distributions for certain medical purposes.
  <br>To find those distributions, computer vision combined with data mining techniques were utilized. We rst obtained the training faces from Color FERET databse, and applied dense sift as the feature extractor on the interest areas of each face. Then, SVM(support vector machine) was employed to classify the faces from with and without POH or PP.
  <br>Finally, over 150,000 sele-tagged posts on Twitter and Tumblr have been analyzed, and the result will be presented in the results section.
## Main Directories
1. Data acquisition(Ruby)
  <br>Include the ruby files for processing the facial images received from Color FERET database and searching selfies on Twitter, Tumbrl and Flickr. 
2. Binary classification app(Swift)
  <br>Include the Xcode project that implements the binary classification app, it can be used just like Tinder.
3. Model and prediction(Matlab)
  <br>Include the SVM training and predicting files.
