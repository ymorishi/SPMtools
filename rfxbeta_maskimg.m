function [beta coordinate]= rfxbeta_maskimg(varargin)
%
%  beta = rfxbeta_maskimg(image_path,SPMmat,ROIspec)
%    extract local maxima of beta value from RFX analysis
%
%  INPUT
%    image_path: path of mask image(s)
%    SPMmat: SPM (as variable form)
%    ROIspec: 0 = mean, 1 = sum, 2 = local maxima;
%  OUTPUT
%    beta	  -beta estimates of ROI
%    coordinate - XYZmm coordinate of extracted beta estimates
%
%_______________________________________________________________________
%
%  @ Written by Yosuke Morishima, Apr 4th 2011  @
%  @ Updated Nov 14th 2013 @

if nargin < 1
    image_path = spm_select(inf,'image','Select mask image(s)');
else
    image_path = varargin{1};
end
nroi = size(image_path,1);

if nargin < 2
    fullmatname = spm_select(1,'mat','Select SPM.mat');
    load(fullmatname)
else
    spm_in = varargin{2};
    if ischar(spm_in)
        load(spm_in)
    else
        SPM=spm_in;
    end
end

% define ROI id and
% check dimension match between mask and RFX image
Y = spm_read_vols(spm_vol(SPM.xY.P{1}));
for i = 1:nroi
    vol = spm_vol(deblank(image_path(i,:)));
    Y_input = spm_read_vols(vol);
    
    if ~sum(size(Y_input)-size(Y))
        ROI_id{i} = find(Y_input);
    else
        fprintf('Error: mask image dimension is not matched')
        break
    end          
end

if nargin < 3
    ROIspec = spm_input('mean, sum or local maxima',1,'mean|sum|local max',[0 1 2]);
else
    ROIspec = varargin{3};
end

numimg = length(SPM.xY.P);
beta = zeros(numimg,nroi);
coordinate = zeros(numimg,3,nroi);



for sub = 1:numimg
    % get voxel
    vol = spm_vol(SPM.xY.P{sub});
    [Y XYZ]= spm_read_vols(vol);
    for i = 1:nroi
        switch ROIspec
            case 0 % mean
                beta(sub,i) = nanmean(Y(ROI_id{i}));
        	    coordinate(sub,:,i) = mean(XYZ(:,ROI_id{i}),2)';
            case 1 % sum
                beta(sub,i) = nansum(Y(ROI_id{i}));
        	    coordinate(sub,:,i) = mean(XYZ(:,ROI_id{i}),2)';
            case 2 % local maxima
                [beta(sub,i)  maxind] = max(Y(ROI_id{i}));
                coordinate(sub,:,i) = XYZ(:,ROI_id{i}(maxind))';
        end
    end
end
