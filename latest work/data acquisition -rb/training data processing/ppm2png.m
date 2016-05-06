
clc; 
% 
 tline = fgets(fid);
 disp('converting and writing...');
 while ischar(tline)
     %get directory from tline
     dict = strsplit(tline,'_');
     %file path
     path = strcat('smaller/', dict{1}, '/', tline);
     %convert to png and write
     name = strsplit(tline,'.');
     output_path = strcat('output/',name{1},'.png');
     %write png
     imwrite(imread(path),output_path);
     tline = fgets(fid);
 end
% disp('task done');
% 
 fclose(fid);