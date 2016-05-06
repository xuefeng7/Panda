%% this function takes a list of images and create class label for each 
% input and apply PCA on each input to get the coefficient for training
function [ SVMModel, Class ] = SVMTraining(file) % File list contains only path
    disp('processing data...')
    tic
    [features, Class] = ProcessSet(file);
    toc
    %data = imgVector;
    %[trainData, coeff] = ApplyPCA(featureVector, k); % N x K
    disp('training model...')
    SVMModel = fitcsvm(double(features), Class, 'KernelFunction', 'rbf', 'BoxConstrain', 10,...
        'Standardize', true, 'KernelScale', 'auto');
end

function [ Features, Class ] = ProcessSet( set )
    % Process set 
    Class = {}; % Class vector
    Features = []; % Feature matrix
    % read in file
    fid = fopen(set);
    tline = fgetl(fid);
    while ischar(tline)
        %tline = strjoin(tline);
        info = strsplit(tline, '&');
        % disp(info)
        path = strcat('output/', cell2mat(info(1)),''); % path of the image file
        Class = [Class; cell2mat(info(2))];
        % single and gray scale it
        img = im2single(imread(path));
        % extract bbouding boxes for interest areas
        left_bbox = [str2double(cell2mat(info(3))), str2double(cell2mat(info(4))), str2double(cell2mat(info(5))), ...
            str2double(cell2mat(info(6))) * 2.3];
        right_bbox = [str2double(cell2mat(info(7))), str2double(cell2mat(info(8))), str2double(cell2mat(info(9))), ...
            str2double(cell2mat(info(10))) * 2.3];
        % apply dense sift and concatenate two matrix into feature vector
        feature = ExtractFeature(img, left_bbox, right_bbox);
        Features = [Features; feature];
        tline = fgetl(fid);
    end
    fclose(fid);
%     for i = 1: numel(set)
%         % Image file name
%         path = strcat('Eyes/', set(i).name);
%         if isempty(strfind(path, 'neg'))
%             % Pos
%             Class = [Class; 'pos'];
%         else
%             % Neg
%             Class = [Class; 'neg'];
%         end
%         % Resize each image, so they agree on matrix dimension
%         img = imresize(imread(path), [25, 50]);
%         % Create double format gray-scale image
%         dImg = im2single(rgb2gray(img));
%         [~, d] = vl_dsift(dImg) ;
%         % Reshape to only one row
%         d = reshape(d.',1,[]);
%         % Add to imgVectors matrix
%         featureVector = [featureVector; d];
%     end
end

% function [ trainingData, coeff ] = ApplyPCA( imgVectors, k )
%     % Standardize the image vector matrix
%     %imgVectors = zscore(imgVectors);
%     %imgVectors = Normalize(imgVectors);
%     % Apply PCA for dimensionality reduction
%     [ coeff ] = pca(imgVectors, 'NumComponents', k);
%     % Normalize coeff
%     coeff = Normalize(coeff);
%     % Training data recovery
%     trainingData = imgVectors * coeff; % NxV * V*K
% end
