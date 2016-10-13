function [scores] = predictResult(imgUrl, dimension, landmarks)
% this function takes the picture of the selfie and facial landmarks  
% extract the features of the interest areas and pass them into 
% pertained model to predict component scores, and then with 
% component scores, we compute the final score that indicate the fatigue
% level, then return all the scores
try
    image = imread(imgUrl);
catch
    scores = -1;
    return; % score is null
end
% successfully get the image data
bbox = constructLocators(landmarks, dimension);
% extract the features
features = getFeatureVector(image, bbox);
% take each feature, time it with corresponding pca coeff
% apply the pcaed feature vector to corresponding model
% and get the results
% features = {eye, eyebt, check, mouth}
pcaed_eye_feature = features{1} * eye_coeff;
pcaed_eyebt_feature = features{2} * eyebt_coeff;
pcaed_mouth_feature = features{3} * mouth_coeff;
pcaed_check_feature = features{4} * check_coeff;
% predicting by models {dc, se, he, re, ge, wks, dcm, ps}
ratings = {};
for modelIdx = 1: 8
    model = models{modelIdx};
    if modelIdx == 1 % dc, need to use eyebt
        response = predict(model, pcaed_eyebt_feature);
    elseif modelIdx == 7 % dcm, need to use mouth
        response = predict(model, pcaed_mouth_feature);
    elseif modelIdx == 8 % ps, need to use check
        response = predict(model, pcaed_check_feature);
    else % otherwise, use eye
        response = predict(model, pcaed_eye_feature);
    end
    ratings = {ratings; response};
end
    % compute the overall fatigue level
    scores = struct('rating',ratings,'overall', computeOverallScore(ratings));
end

function [bbox] = constructLocators(landmarks, dimension)
% This function takes landmarks of a face
% get interest crop marks and construct a locator struct 
    % locator struct example: 
    %{"left_eye":{"top":320.10495743999996,"bottom":340.88703744,"left":137.0112,"right":205.26080000000002},
    %"right_eye":{"top":315.08991744,"bottom":337.75616256,"left":279.4176,"right":348.01536},
    %"mouth":{"top":465.21471743999996,"bottom":497.90208000000007,"left":182.64704,"right":307.6608},
    %"left_eye_bag":{"top":340.88703744,"bottom":364.01663999999994,"left":137.0112,"right":205.26080000000002},
    %"right_eye_bag":{"top":337.75616256,"bottom":362.45120255999996,"left":279.4176,"right":348.01536},
    %"pale_skin":{"top":364.01663999999994,"bottom":426.18048,"left":107.038464,"right":169.43104}}
    width = dimension(1);
    height = dimension(2);
    % left eye marks
    left_eye_marks = struct('top', landmarks.left_eye_top.y / 100.0 * height, ...
     'bottom', landmarks.left_eye_bottom.y / 100.0 * height, ...
     'left', landmarks.left_eye_left_corner.x / 100.0 * width, ...
     'right', landmarks.left_eye_right_corner.x / 100.0 * width);
    % right eye marks
    right_eye_marks = struct('top', landmarks.right_eye_top.y / 100.0 * height, ...
     'bottom', landmarks.right_eye_bottom.y / 100.0 * height, ...
     'left', landmarks.right_eye_left_corner.x / 100.0 * width, ...
     'right', landmarks.right_eye_right_corner.x / 100.0 * width);
    % mouth marks
    mouth_marks = struct('top', landmarks.mouth_upper_lip_top.y / 100.0 * height, ...
     'bottom', landmarks.mouth_upper_lip_bottom.y / 100.0 * height, ...
     'left', landmarks.mouth_left_corner.x / 100.0 * width, ...
     'right', landmarks.mouth_right_corner.x / 100.0 * width);
    left_eyebt_marks = struct('top', landmarks.mouth_upper_lip_top.y / 100.0 * height, ...
     'bottom', landmarks.mouth_upper_lip_bottom.y / 100.0 * height, ...
     'left', landmarks.mouth_left_corner.x / 100.0 * width, ...
     'right', landmarks.mouth_right_corner.x / 100.0 * width);
    right_eyebt_marks = struct('top', landmarks.mouth_upper_lip_top.y / 100.0 * height, ...
     'bottom', landmarks.mouth_upper_lip_bottom.y / 100.0 * height, ...
     'left', landmarks.mouth_left_corner.x / 100.0 * width, ...
     'right', landmarks.mouth_right_corner.x / 100.0 * width);
    pale_skin_marks = struct('top', ((landmarks.left_eye_bottom.y)/2 + (landmarks.nose_tip.y)/2) / 100* height, ...
        'bottom', ((landmarks.nose_tip.y)/2 + (landmarks.mouth_upper_lip_top.y)/2)/ 100 * height, ...
        'left', landmarks.left_eyebrow_left_corner.x / 100 * width, ...
        'right', landmarks.left_eye_pupil.x / 100 * width);
    locator = struct('left_eye', left_eye_marks, 'right_eye', right_eye_marks, ...
        'mouth', mouth_marks, ...
        'left_eye_bag',left_eyebt_marks,'right_eye_bag',right_eyebt_marks, ...
        'pale_skin', pale_skin_marks);
    % and send it bbox generator to obtain bbox
     bbox = getBBoxFromLocators(locator);
end

function [features] = getFeatureVector(image, bbox)
% this function takes image and a bbox
% crop the interest areas and apply dense sift on them
% bbox = {left_eye_box, right_eye_box, left_eye_bottom_box, right_eye_bottom_box, ...
% check_box, mouth_box};
    features = {};
    % eye features [left_eye, right_eye]
    [~, left_eye_d] = vl_phow(im2single(imresize(imcrop(image, bbox{1}), [30, 45])));
    [~, right_eye_d] = vl_phow(im2single(imresize(imcrop(image, bbox{2}), [30, 45])));
    features = {features; [reshape(left_eye_d.',1,[]), reshape(right_eye_d.',1,[])]};
    % eyebt features [left_eye_bt, right_eye_bt]
    [~, left_eyebt_d] = vl_phow(im2single(imresize(imcrop(image, bbox{3}), [30, 45])));
    [~, right_eyebt_d] = vl_phow(im2single(imresize(imcrop(image, bbox{4}), [30, 45])));
    features = {features; [reshape(left_eyebt_d.',1,[]), reshape(right_eyebt_d.',1,[])]};
    % check features
    [~, check_d] = vl_phow(im2single(imresize(imcrop(image, bbox{5}), [30, 30])));
    features = {features; reshape(check_d.',1,[])};
    % mouth feature
    [~, mouth_d] = vl_phow(im2single(imresize(imcrop(image, bbox{5}), [30, 45])));
    features = {features; reshape(mouth_d.',1,[])};
end

function [overall] = computeOverallScore(ratings)
% takes eight ratings and compute the overall score through
% f(x1, x2, x3, ..., x8) = 
    %[r, ~] = size(feature);
end

