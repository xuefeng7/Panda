%% read predicting subjects in
% load necessary pca coeffs and models

fid = fopen('result_1.txt');
tline = fgetl(fid);
count = 0;
while ischar(tline)
    count = count + 1;
    subject = loadjson(tline);
    fields = fieldnames(subject);
    faces = subject.(fields{1});
    [~, c1] = size(faces);
    for i = 1: c1
        face = faces{i};
        attributes = face{1}; %[age, gender, glass, race, smiling]
        person = struct('attribute', attributes); % a unique person
        faces = {}; % all faces about the same person
        photos = face{2};
        [~, c2] = size(photos);
        for j = 1: c2
            photo = photos{j};
            url = photo{1}{1};
            dimension = photo{1}{2}; %[width, height]
            landmarks = photo{2};
            scores = predictResult(url, dimension, landmarks);
            if scores == -1 % obtain image by url failed with error
                continue
            end
            % wrap up the face information
            cropmarks = struct('left_eye_top',landmarks.left_eye_top,...
                'right_eye_top',landmarks.right_eye_top, ...
                'mouth_lower_lip_bottom',landmarks.mouth_lower_lip_bottom);
            src = struct('url', url, 'cropmarks', cropmarks);
            ratings = struct('components',scores.rating, 'overall', scores.overall);
            faces = {faces; struct('src', src, 'rating', ratings)};
        end
        [person(:).faces] = faces;
        % remove all whitespace from json string
        % and archive it.
        fprintf(output, '%s', regexprep(savejson('', person), '[\t\n\s]', ''));
    end
%     tline = fgetl(fid);
%     if count == 2
%         break
%     end
end