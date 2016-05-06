
clc;
close all;
run('VLFEATROOT/toolbox/vl_setup');

%% Create Model
tic
%[ SVMModel, Class ] = SVMTraining('test/train_2137.txt');
toc
disp('cross validating...')
tic
%CVSVMModel = crossval(SVMModel);
%classLoss = kfoldLoss(CVSVMModel);
toc
disp('fit posterior...')
%disp(classLoss)
% compact model
%CompactSVMModel = compact(SVMModel);
% predicting 
%ScoreSVMModel = fitPosterior(SVMModel);
%[~, svm_score] = resubPredict(ScoreSVMModel);
%[x_svm, y_svm, ~, aucsvm] = perfcurve(Class, svm_score(:,1),'neg');
%figure, plot(x_svm, y_svm);
tic
disp('predicting...')
SVMTesting(ScoreSVMModel)
disp('prediction done')
% toc
% % 
% %result = [];
% correct = 0;
% fid = fopen('test/test.txt');
% tline = fgetl(fid);
% scores =[];
% trueLabel = [];
% disp('labeing test set...')
% tic
% while ischar(tline)
%     
%      info = strsplit(tline, '&');
%   %  disp(info)
%      path = strcat('output/', cell2mat(info(1)),''); % path of the image file
%      disp(path)
%   %   Class = [Class; cell2mat(info(2))];
%      % single and gray scale it
%      img = im2single(imread(path));
%      % extract bbouding boxes for interest areas
%      left_bbox = [str2double(cell2mat(info(3))), str2double(cell2mat(info(4))), str2double(cell2mat(info(5))), ...
%             str2double(cell2mat(info(6))) * 2.3];
%      right_bbox = [str2double(cell2mat(info(7))), str2double(cell2mat(info(8))), str2double(cell2mat(info(9))), ...
%             str2double(cell2mat(info(10))) * 2.3];
%      % apply dense sift concatenate two matrix into feature vector
%      feature = ExtractFeature(img, left_bbox, right_bbox);
%      [label, score] = predict(ScoreSVMModel, double(feature));
%      scores = [scores; score];
%      trueLabel = [trueLabel; cell2mat(info(2))];
%      if strcmp(label, cell2mat(info(2)))
%          correct = correct + 1;
%      end
%      %result = [result, struct(info(2), predict(SVMModel, double(feature)))];
%      tline = fgetl(fid);
% end
% toc
% fclose(fid);
% [x, y, ~, auc] = perfcurve(trueLabel, scores(:,1), 'neg'); 
% figure, plot(x,y);
%[tpr, tnr, roc_info]  = vl_roc(trueLabel, scores(:,2));
%[mr, fa] = vl_det(trueLabel, scores(:,2));
%[rc, pr, pr_info] = vl_pr(trueLabel, scores(:,2)) ;
%disp(classLoss)
 %for i = 1: numel(tests)
 %path = strcat('test/output/', tests(i).name);
% % Resize each image, so they agree on matrix dimension
 %img = imresize(imread(path), [25, 50]);
% % Create double format gray-scale image
 %dImg = im2single(rgb2gray(img));
 % Reshape to only one row
 %[~, d] =  vl_dsift(dImg);
% %dImg = reshape(dImg.',1,[]);
% d = reshape(d.',1,[]);
 % Get feature vector
 % d = Normalize(d);
 %fv = dImg * coeff;
 %label = struct('name', tests(i).name ,'label', predict(SVMModel, double(d)));
 %result = [result; label];
 %end
%[correct, error] = Analytics(result);
%disp(correct)

