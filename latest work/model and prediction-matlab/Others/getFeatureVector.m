%% this function takes two bouding boxes
% which bound the interest areas of
% left and right interest areas respectively
% and apply dense sift on these two areas to get
% two set of features, and then concatenates them into a vector
function [ feature ] = getFeatureVector( area1, area2 )
    [~, d1] = vl_dsift(area1) ;
    [~, d2] = vl_dsift(area2) ;
    % hogd1 = vl_hog(area1, 8);
    % hogd2 = vl_hog(area2, 8);
    % reshape and concatenation
    d1 = reshape(d1.',1,[]);
    d2 = reshape(d2.',1,[]);
    %hd1 = reshape(hogd1, [1, size(hogd1,1)*size(hogd1,2)*size(hogd1,3)]);
    %hd2 = reshape(hogd2, [1, size(hogd2,1)*size(hogd2,2)*size(hogd2,3)]);
    feature = [d1, d2];
end
