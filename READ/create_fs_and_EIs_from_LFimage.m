function [fs, map, EIs] = create_fs_and_EIs_from_LFimage(path, min_fs, max_fs, step_fs, jump_between_views)

%% check if we already decoded the image
% if there is the decoded file, we use that
% otherwise we need LFToolbox to decode it
path_no_suffix = path(1:end-4);
path_decoded_mat = strcat(path_no_suffix, '__Decoded.mat');
res = exist(path_decoded_mat, 'file');
if res > 1
    load(path_decoded_mat)
else
    [LF, LFMetadata, WhiteImageMetadata, LensletGridModel, DecodeOptions] = ...
    LFLytroDecodeImage( path );
end


%% Here we should have our data, we need only LF (5D)
%% EIs
% structure that contains [h,w,rgb,EInumber]
h = size(LF(1,1,:,:,1),3);
w = size(LF(1,1,:,:,1),4);
EIs = zeros(h,w,3,9);
center_LF = floor(size(LF,1) / 2);
EIs(:,:,:,1) = squeeze(LF(center_LF-(jump_between_views+1), center_LF-(jump_between_views+1), :, :, 1:3));
EIs(:,:,:,2) = squeeze(LF(center_LF, center_LF-(jump_between_views+1), :, :, 1:3));
EIs(:,:,:,3) = squeeze(LF(center_LF+(jump_between_views+1), center_LF-(jump_between_views+1), :, :, 1:3));
EIs(:,:,:,4) = squeeze(LF(center_LF-(jump_between_views+1), center_LF, :, :, 1:3));
EIs(:,:,:,5) = squeeze(LF(center_LF, center_LF, :, :, 1:3));
EIs(:,:,:,6) = squeeze(LF(center_LF+(jump_between_views+1), center_LF, :, :, 1:3));
EIs(:,:,:,7) = squeeze(LF(center_LF-(jump_between_views+1), center_LF+(jump_between_views+1), :, :, 1:3));
EIs(:,:,:,8) = squeeze(LF(center_LF, center_LF+(jump_between_views+1), :, :, 1:3));
EIs(:,:,:,9) = squeeze(LF(center_LF+(jump_between_views+1), center_LF+(jump_between_views+1), :, :, 1:3));

%% FOCAL STACK
num_of_focal_planes = (max_fs - min_fs) / step_fs;
fs = zeros(h, w, 3, num_of_focal_planes);
int_correction = 1 / step_fs; % if we multiply i with this factor, we get the integer number of the iteration
for i=min_fs:step_fs:max_fs %-1:0.1:1
    integer_index = round((i-min_fs)*int_correction) + 1
    fs(:,:,integer_index) = LFFiltShiftSum(LF, i);
end