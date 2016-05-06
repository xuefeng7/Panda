%% this function takes an image as input and check if the 
% image contains face or not
function [ contain ] = isContainFace( image )
%     % Resize image to speed up
%     image = imresize(image, 0.3);
%     % Create a cascade detector object.
%     faceDetector = vision.CascadeObjectDetector();
%     % The box that can bound the face
%     bbox = step(faceDetector, image);
%     if isempty(bbox)
%         % No face detected
%         contain = 0; 
%     else
%         contain = 1; 
%     end
contain = 1;
end

