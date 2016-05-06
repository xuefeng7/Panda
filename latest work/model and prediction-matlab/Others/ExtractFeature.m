%% This function crop out the interests areas from input image
function [ feature ] = ExtractFeature( img, left_bbox, right_bbox )
    % get interest areas
    if size(img, 3) == 3 
        % rgb image, conver to gray scale
        img = rgb2gray(img);
    end
    left_area = im2single(imresize(imcrop(img, left_bbox), [20, 30])); % left
    right_area = im2single(imresize(imcrop(img, right_bbox), [20, 30])); % right
    feature = getFeatureVector(left_area, right_area);
end

