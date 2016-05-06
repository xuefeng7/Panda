%% Read a list of testing images url and label them
% Output a (gender, age, race, location(optional), label) array
function SVMTesting( SVMModel )
    % skip the processed url
    skip = 3090;
    counter = 1;
    % file to write
    result = fopen('positive_1/dc_1.txt', 'a+');
    fpperror = fopen('positive_1/fperror_dc_1.txt','a+');
    mterror = fopen('positive_1/mterror_dc_1.txt','a+');
    % read file line by line
    % each line has a testing image url
    source = fopen('positive_1/positive_1.txt','r');
    url = fgetl(source);
    while ischar(url)
     if counter <= skip 
         url = fgetl(source);
         %disp(url)
         disp(counter)
         counter = counter + 1;
         continue
     end
     disp('---------------------------------------')
     disp(counter)
     disp(strcat('reading', '_', url, '...'))
     % if gif, only take the first frame
     if ~isempty(strfind(url, '.gif'))
%           try 
%               img = imread(url, 'frames', 1);
%           catch 
%               fprintf(mterror, strcat(url,'\n'));
%               continue
%           end
            url = fgetl(source);
            counter = counter + 1;
            continue
       else
         try 
             img = imread(url);
         catch 
             fprintf(mterror, strcat(url,'\n'));
             url = fgetl(source);
             counter = counter + 1;
             continue
         end
     end
     % check if the img contains at least one face
     if 1 == 1 %isContainFace(img)
         % disp('face is found from vision face detector')
         % [(struct: 1. feature vector; 2.attributes)]
         infoPacks = AcquireFaceSampleInfo(url, img);
         labels = []; % predicted label for each face in a url
         scores = []; % predicted score for each face in a url
         if isempty(infoPacks)
             % detection faliure, store url to error file for later
             % re-detect
             disp('error detection from face++ found')
             fprintf(fpperror, strcat(url,'\n'));
         else
             % detection succeed
             disp('reading faces...')
             for i = 1: numel(infoPacks)
                 pack = infoPacks(i);
                 % get feature vector
                 feature = pack.feature;
                 % predicate and assgin label
                 [label, score] = predict(SVMModel, feature);
                 try
                     if strcmp(label, 'neg')
                         % contains dc/eg
                         box = pack.box;
                         liaSkin = imcrop(img, box(1,:)); % interest area skin
                         lnSkin = imcrop(img, box(3,:)); % normal skin
                         riaskin = imcrop(img, box(2,:));
                         rnskin = imcrop(img, box(4,:));
                         aveDis = (distance(liaSkin,lnSkin) + distance(riaskin,rnskin)) / 2;
                         if aveDis > 8
                             %dark circle - subclass of dc/eb
                             label = {'neg_dc'};
                             disp('neg_dc found')
                         end
                     end
                 catch
                    %skip
                 end
                 
                 labels = [labels; label];
                 scores = [scores; score];
             end
                 content = URLJSONString(url, labels, scores, infoPacks);
                 fprintf(result, content);
         end  
     else
       % matlab vision detector found no face for input image
       disp('vision detector found no face')
       fprintf(mterror, strcat(url,'\n'));
     end
     % increment counter
     counter = counter + 1;
     % keep readin
     url = fgetl(source);
     disp('---------------------------------------')
    end
    % close files
    fclose(fpperror);
    fclose(mterror);
    fclose(result);
    fclose(source);
end
%% take the face information
% create corresponding JSON string
% Example:
% {"attributes": {"age": {"value": 15,"range": 5},"gender": {"value": "male","confidence": 99.8},
%"race":{"value":"asian","confidence": 99.8},
%"dark_cirlce_eyebag": {"value": "positive","confidence": 97}}}
function [ FaceJSON ] = FaceJSONString( label, score, attr )
    % if has dark circle or eyebag, it is positive sample
    % if has not, negative sample
    if strcmp(label, 'neg')
        label = 'positive';
        score = score(:,1);
    elseif strcmp(label, 'neg_dc')
        label = 'positive_dc';
        score = score(:,1);
    else
        label = 'negative';
        score = score(:,2);
    end
    FaceJSON = strcat('{"attribute":{"age":{"value":', num2str(attr.age.value), ',"range":', num2str(attr.age.range), ...
        '}, "gender":{"value":"', attr.gender.value, '","confidence":', num2str(attr.gender.confidence), ...
        '},"race":{"value":"',attr.race.value, '","confidence":', num2str(attr.race.confidence), ...
        '},"dark_cirlce_eyebag":{"value":"', label, '","confidence":', num2str(score * 100), ...
        '}, "glass":{"value":"', attr.glass.value, '","confidence":', num2str(attr.glass.confidence),'}}}');
end
%% create a JSON string for one url that may contain multiple faces
% ex: 
% {"face":[],
%   "url":"www.example.com"}
function [ UrlJSON ] = URLJSONString( url, labels, scores, infoPacks)
    FacesJSON = '';
    for i = 1:numel(labels)
        pack = infoPacks(i);
        face = FaceJSONString(labels(i,:), scores(i,:), pack.attributes);
        if i == numel(labels)
            % last array json obejct do not carray a comma
            FacesJSON = strcat(FacesJSON, face);
        else
            FacesJSON = strcat(FacesJSON, face, ',');
        end
    end
    UrlJSON = strcat('{"face":[', FacesJSON, '],"url":"', url, '"}\n');
end
