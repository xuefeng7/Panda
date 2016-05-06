%% This function takes an image and query face++ server
% to obtain face landmarks and cropped out the eyes to return
function [ info ] = AcquireFaceSampleInfo( url, image )
    % send request to face++
    api_key = '&api_key=2ca7f036e1c5e15e5d6d0d85b13da721';
    api_secret = '&api_secret=X-L2kZIOEkcw77_lHPB-bNZBJpupclOF';
    attribute = '&attribute=glass%2Cgender%2Cage%2Crace';
    uri = strcat('https://apius.faceplusplus.com/v2/detection/detect?url=', url, api_secret, api_key, attribute);
    option = weboptions('Timeout', 30); % query timeout
    try
        face_data = webread(uri, option);
    catch
        warning('face++ face detection http response status code is not 200=OK');
        info = []; 
        return 
    end
    disp('success face detection is responsed from face++')
    face_count = numel(face_data.face);
    if face_count ~= 0 
        img_height = face_data.img_height;
        img_width = face_data.img_width;
        samplePack = []; %the given image may contain more than one face
        for i = 1:face_count
            %ignore sunglass
            glassType = face_data.face(i).attribute.glass(1).value; % none, normal is acceptable
            if strcmp(glassType,'None') || strcmp(glassType,'Normal')
                face_id = strcat('face_id=', face_data.face(i).face_id);
                attr = face_data.face(i).attribute;
                disp('success face landmarks is responsed from face++')
                landmarkURI = strcat('https://apius.faceplusplus.com/v2/detection/landmark?',face_id, api_secret, api_key, '&type=25p');
                try
                    landmark_data = webread(landmarkURI, option);
                catch
                    warning('face++ face landmarks http response status code is not 200=OK');
                    info = [];
                    return
                end
                [lbbox, rbbox, lnbbox, rnbbox] = Box(landmark_data.result.landmark, img_height, img_width);
                feature = ExtractFeature(image, lbbox, rbbox);
                % create face struct
                face = struct('feature', double(feature), 'attributes', attr, 'box',[lbbox; rbbox; lnbbox; rnbbox]);
                samplePack = [samplePack, face];
            end
        end
        %return value
        info = samplePack;
    else
    % due to detection failure
    info = [];
    end
end
%% this function gets the bounding box of the interest area
% this function also gets a piece of normal skin in order to compare the color diff
% between normak skin and the interest area skin.
function [ lbbox, rbbox, lnbbox, rnbbox ] = Box( landmark, img_height, img_width )
    leftEyeOuter = landmark.left_eye_left_corner.x / 100.0 * img_width; %left eye outer x
    leftEyeInner = landmark.left_eye_right_corner.x / 100.0 * img_width; %left eye inner x 
    rightEyeOuter = landmark.right_eye_right_corner.x / 100.0 * img_width; %right eye outer x
    rightEyeInner = landmark.right_eye_left_corner.x / 100.0 * img_width; %right eye inner x
    leftEyeTop = landmark.left_eye_top.y / 100.0 * img_height; % left eye top y
    rightEyeTop = landmark.right_eye_top.y / 100.0 * img_height; % right eye top y
    leftEyeBottomX = landmark.left_eye_bottom.x / 100.0 * img_width; % left eye bottom x
    leftEyeBottomY = landmark.left_eye_bottom.y / 100.0 * img_height; % left eye bottom y
    rightEyeBottomX = landmark.right_eye_bottom.x / 100.0 * img_width; % right eye bottom x
    rightEyeBottomY = landmark.right_eye_bottom.y / 100.0 * img_height; % right eye bottom y
    
    left_width = leftEyeInner - leftEyeOuter;
    left_height = leftEyeBottomY - leftEyeTop;
    right_width = rightEyeOuter - rightEyeInner;
    right_height = rightEyeBottomY - rightEyeTop;
    l_x = round(leftEyeBottomX - left_width / 2);
    r_x = round(rightEyeBottomX - right_width / 2);
    % left area bounding box
    lbbox = [l_x, round(leftEyeBottomY), round(left_width), round(left_height) * 2.3];
    % left normal skin bounding box
    lnbbox = [l_x, round(leftEyeBottomY) + round(left_height) * 2.3, round(left_width), round(left_height)];
    % right area bounding box
    rbbox = [r_x, round(rightEyeBottomY), round(right_width), round(right_height) * 2.3];
    % right normal skin bounding box
    rnbbox = [r_x, round(rightEyeBottomY) + round(right_height) * 2.3, round(right_width), round(right_height)];
    
end

