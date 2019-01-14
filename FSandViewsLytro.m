%% READ LYTRO IMAGE RAW AND LENSLET
addpath(genpath('Blacks'));
addpath(genpath('Cameras'));
addpath(genpath('Images'));
addpath(genpath('/data1/palmieri/Lytro/LFToolbox0.4'));

InputFname = '/data1/palmieri/Valencia/Code/LytroPreProc/Left.lfp';
[LFP, LFMetadata, WhiteImageMetadata, LensletGridModel, DecodeOptions] = ...
    LFLytroDecodeImage( InputFname );

%% VIEWS
h = size(LFP(1,1,:,:,1),3);
w = size(LFP(1,1,:,:,1),4);
views3x3 = zeros(h*3, w*3, 3);
views3x3(1:h,1:w,:) = squeeze(LFP(7,7,:,:,1:3));
views3x3(1:h,w+1:2*w,:) = squeeze(LFP(7,8,:,:,1:3));
views3x3(1:h,2*w+1:3*w,:) = squeeze(LFP(7,9,:,:,1:3));
views3x3(h+1:2*h,1:w,:) = squeeze(LFP(7,8,:,:,1:3));
views3x3(h+1:2*h,w+1:2*w,:) = squeeze(LFP(8,8,:,:,1:3));
views3x3(h+1:2*h,2*w+1:3*w,:) = squeeze(LFP(9,8,:,:,1:3));
views3x3(2*h+1:3*h,1:w,:) = squeeze(LFP(7,9,:,:,1:3));
views3x3(2*h+1:3*h,w+1:2*w,:) = squeeze(LFP(8,9,:,:,1:3));
views3x3(2*h+1:3*h,2*w+1:3*w,:) = squeeze(LFP(9,9,:,:,1:3));
imagesc(views3x3)

%% FOCAL STACK
for i=-1:0.1:1
    fs(:,:,int(i*10)) = LFFiltShiftSum(LFP, i);
end
