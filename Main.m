%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                   %
%   SCRIPT TO GENERATE DEPTH MAP    %
%        FROM LYTRO IMAGES          %
%                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEBUG
% To make debug easier in case of problems, function to save the intermediate steps 
% are available. Just set DEBUG to true to save intermediate steps (lots of
% images)
DEBUG = false; % recommended = false
% if you don't want to save all images, but the persepctive views
% (elemental images) and the focal stack only (recommended), set to true
SAVE_ELEMENTAL_IMAGES_AND_FOCAL_STACK = true; % recommended = true
% if true, it saves a .txt with the parameters used (useful if you come
% back later and you want to know how results were created)
SAVE_PARAMETERS = true; % recommended = true


%% RESULTS FOLDER
% FOLDER WHERE STUFF WILL BE SAVED!!!
% if it does not exists, the program will create a folder and save there
folder_path = strcat(pwd, filesep, 'RESULTS', filesep);
[status,msg] = mkdir(folder_path);
if status == 0
    fprintf(msg);
    pause;
end

%% INPUT PATH
% path of the image taken as input
path = strcat(pwd, filesep, 'IMAGES', filesep, 'IMG_0955.LFR');

setupPaths();
compileCPPFiles();

%% PARAMETERS
% Here we need to set the parameters for the Lytro image
% we use LFToolbox from D.Dansereau et al. (2013)
% so we need a minimum and maximum value for the focal stack
% and a step (usually 0.1 step between -1 and +1 contains the focal planes)
% we can also run once the program and set SAVE_ELEMENTAL_IMAGES_AND_FOCAL_STACK
% to true to save the images and take a look at them to see if the values 
% were correct. Reducing the number of focal planes may help.
%
% We also provide a distance between views parameters
% we select three views horizontally and vertically (including central one always)
% and we can choose to pick views adjacent or far from each other to increase 
% the disparity. If disparity is too small, algorithm may be less accurate,
% because it was built for a disparity range around -30 to 30 pixels.
% The step_fs also accounts for this, so small step_fs means that you have lots of planes
% with less disparity, higher step_fs will result in higher disparities
% if the jump between views is too large, the views will have high noise (at least 
% if taken in normal condition with Lytro cameras without special correction)
% so usually a jump of one view is recommended
min_fs = -1;
max_fs = +1;
step_fs = 0.1;
jump_between_views = 1;



% for the depth estimation
window_size = 7; % window around the point
window_size_PP = 3; % high window size for post processing will smooth too much
eps = 1.0;
alpha_DFD = 0.9; % combine NCC and SAD (alpha*ncc+(1-alpha)*sad)
alpha_DFC = 0.7; % combine CENSUS and SAD (alpha*census+(1-alpha)*sad)
superpixel_type = 0; % 0 --> use slicmex , 1 --> use vl_slic
superpixels_size = 75; % approximate size of superpixel (for vl_slic)
superpixels_regularizer = 0.1; % for superpixel shape --> see SLIC in Matlab (for vl_slic)
sigma_sp = 9;
map_type = 1; % 0 = no map, 1 = DoG, 2 = ???
use_priors = true; % use priors map in the confidence computation
use_fail_pred = true; % use failure prediction in the multi-scale combination = weight the contributions based on edge direction
which_conf = 2;
which_depth = 0;
merging_strategy = 4;


% for cost volume
% DEFOCUS
gamma_DFD_s1 = 0.66; % regulates the contribution of downscaled image s1 - half size
gamma_DFD_s2 = 0.33; % regulates the contribution of downscaled image s2 - a quarter
beta_DFD = 0.1;    % regulates the contribution of superpixels
% CORRESPONDENCES
gamma_DFC_s1 = 0.66; % regulates the contribution of downscaled image s1 - half size
gamma_DFC_s2 = 0.33; % regulates the contribution of downscaled image s2 - a quarter
beta_DFC = 0.1;    % regulates the contribution of superpixels
dmin = min_fs / step_fs;
dmax = max_fs / step_fs;


% DEBUG
if DEBUG || SAVE_PARAMETERS
    save_parameters(folder_path, path, superpixels_size, ...
        window_size, alpha_DFD, alpha_DFC, gamma_DFD_s1, gamma_DFD_s2, beta_DFD, gamma_DFC_s1, ...
        gamma_DFC_s2, beta_DFC, superpixel_type, window_size_PP);
end

%% 1) read images
[fs, map, EIs] = create_fs_and_EIs_from_LFimage(path, min_fs, max_fs, step_fs, jump_between_views);
refocused_central_img = EIs(:,:,:,ceil(size(EIs,4)/2));
matte = ones(size(refocused_central_img,1), size(refocused_central_img, 2));

% DEBUG
if DEBUG || SAVE_ELEMENTAL_IMAGES_AND_FOCAL_STACK
    save_image(folder_path, fs, map, EIs);
end

%% 2) calculate superpixels
superpixels = calc_superpix(refocused_central_img, matte, superpixels_size, superpixels_regularizer, superpixel_type);

% DEBUG
if DEBUG
    save_superpixels(folder_path, superpixels, refocused_central_img);
end

%% 3) calculate priors for the multi-scale
priorsmap = calculate_priors(refocused_central_img, matte, map_type);

%% 4) calculate cost volume from defocus
dfD_cv = defocus_norm_cv(fs, refocused_central_img, window_size, alpha_DFD, gamma_DFD_s1, gamma_DFD_s2, priorsmap);

dfD_cv_smoothed = superpixels_contribution(dfD_cv, superpixels, refocused_central_img, matte, sigma_sp);
DFD = dfD_cv + beta_DFD.*dfD_cv_smoothed;

% DEBUG
if DEBUG
    save_depth_CV(folder_path, dfD_cv, 'depth_from_defocus_no_SP', matte);
    save_depth_CV(folder_path, DFD, 'depth_from_defocus', matte);
end

[depth_D, conf_D] = extract_depth_and_confidence(DFD, refocused_central_img, matte, which_depth, which_conf);

%% 5) calculate cost volume from correspondences

[cvc, depth_C, conf_C] = hex_stereo_matching_v2(EIs, refocused_central_img, window_size, alpha_DFC, dmin, dmax, matte, gamma_DFC_s1, gamma_DFC_s2, priorsmap, use_fail_pred);

cvc_sp = superpixels_contribution(cvc, superpixels, refocused_central_img, matte, sigma_sp);
cvc_tot = cvc + beta_DFC.*cvc_sp;

depth_C_inv = dmax - depth_C;

% DEBUG
if DEBUG
    %save_depth_CV(folder_path, DFC, 'depth_from_correspondences', matte);
    %save_depth_CV(folder_path, dfC_cv, 'depth_from_correspondences_no_SP', matte);
    save_depth_CV(folder_path, cvc_tot, 'depth_from_correspondences_hexfp', matte);
    save_depth_CV(folder_path, cvc, 'depth_from_correspondences_no_SP_hexfp', matte);
end

% DEBUG
if DEBUG
    save_final_depth(folder_path, depth_D, 'depth_DEFOCUS');
    save_final_depth(folder_path, depth_C, 'depth_CORRESPONDENCE');
    %save_final_depth(folder_path, depth_C_inv, 'depth_CORRESPONDENCE_INV');
    save_final_depth(folder_path, conf_D, 'confidence_DEFOCUS');
    save_final_depth(folder_path, conf_C, 'confidence_CORRESPONDENCE');
end

%% 6) merge the two volumes?
CVC = invert_volume(cvc_tot);
merged_vol = merge_volumes(DFD, cvc_tot, phi, conf_D, conf_C, matte, priorsmap, merging_strategy);

%% 7) refine depth map
%depth_C_inv = dmax - depth_C;
final_depth_MRF = refine_depth_MRF(depth_D, depth_C_inv, conf_D, conf_C, refocused_central_img, matte);
final_depth_GC = extract_depth(merged_vol, matte, refocused_central_img, 'gc');
final_depth_MGM = extract_depth(merged_vol, matte, refocused_central_img, 'mgm');
test_wta = extract_depth(merged_vol, matte, refocused_central_img, 'wta');

% DEBUG
if DEBUG
    save_final_depth(folder_path, final_depth_MRF, 'depth_combined_MRF');
    save_final_depth(folder_path, single(final_depth_GC), 'depth_combined_GC');
    save_final_depth(folder_path, final_depth_MGM, 'depth_combined_MGM');
end

%% 8) final post processing
final_depth_WMF = WMT(double(final_depth_GC), refocused_central_img);
final_depth_WMF_GF = guidedfilter_color(double(uint8(refocused_central_img)), double(final_depth_WMF), window_size_PP, 0.001);
final_depth_WMF_BF = jointBF(double(final_depth_WMF), ((refocused_central_img)), window_size_PP);

% DEBUG
if DEBUG
    save_final_depth(folder_path, final_depth_WMF_BF, 'final_depth_post_proc_BF');
    save_img_and_depth_jpg(folder_path, final_depth_WMF_BF, refocused_central_img, 'imgBF');
    save_final_depth(folder_path, final_depth_WMF, 'final_depth_post_proc');
    save_final_depth(folder_path, final_depth_WMF_GF, 'final_depth_post_proc_GF');
    save_img_and_depth_jpg(folder_path, final_depth_WMF, refocused_central_img, 'imgWMT');
    save_img_and_depth_jpg(folder_path, final_depth_WMF_GF, refocused_central_img, 'imgWMTGF');
    wta_wmf = WMT(double(test_wta), refocused_central_img);
    wta_wmf_bf = jointBF(double(wta_wmf), refocused_central_img, window_size_PP);
    save_img_and_depth_jpg(folder_path, wta_wmf_bf, refocused_central_img, 'imgwta');
end

% SAVE FINAL IMAGE ANYWAY
save_img_and_depth_jpg(folder_path, final_depth_WMF_GF, refocused_central_img, 'imgWMTGF');
