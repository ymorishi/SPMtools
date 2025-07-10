function [beta coordinate]= rfxbeta_localmax(varargin)
%
%  [beta coordinate] = rfxbeta_localmax(roi,SPMmat,ROIspec,ROIsize)
%
%  extract local maxima of beta value from RFX analysis
%
%  INPUT:
%  roi: n x 3 matrix
%  SPMmat: SPM (as variable form)
%  ROIspec: 0 = peak, 1 = local max, 2 = roi mean
%  ROIsize: (positive integer) = within X mm from the coordinate
%  
%  OUTPUT
%    beta	  -beta estimates of ROI
%    coordinate - XYZmm coordinate of extracted beta estimates
%_______________________________________________________________________
%
%  @ Written by Yosuke Morishima, Aug 5th 2011 @
%  @ Updated Oct 20th 2011 @
%  @ Updated Nov 5th 2014 @




if nargin < 1
    nroi = spm_input('How many ROIs?',1,'i',[],1);
    for i = 1:nroi
        ROI{i} = spm_input(sprintf('%d coordinate[x y z]',i),[],'r',[],3);
    end
else
    coordinate = varargin{1}
    if size(coordinate,1)~=3
        coordinate = coordinate'
    end
    nroi = size(coordinate,2);
    for i = 1:nroi
        ROI{i} = coordinate(:,i);
    end
end

if nargin < 2
    fullmatname = spm_select(1,'mat','Select SPM.mat');
    load(fullmatname)
else
    SPM = varargin{2};
end

if nargin < 3
    ROIspec = spm_input('Type of ROI',1,'peak|local max|roi mean',[0 1 2]);
else
    ROIspec = varargin{3};
end

if nargin < 4 
    if ROIspec > 0
        ROIsize = spm_input('X mm from peak',[],'i',[],1);
    end
elseif nargin ==4
    if ROIspec > 0
        ROIsize = varargin{4};
    else
        error('input is worng')
    end
elseif nargin > 4
    error('input is worng')
end

numimg = length(SPM.xY.P);
P = SPM.xY.P;

beta = zeros(numimg,nroi);
coordinate = zeros(numimg,3,nroi);


%define ROI id
for i = 1:nroi
    xyz = ROI{i};
    if size(xyz,2) ==3
        xyz = xyz';
    end
    vol = spm_vol(P{1});
    [Y XYZ]= spm_read_vols(vol,0);
    dist = XYZ - repmat(xyz,[1 size(XYZ,2)]);
    distsq = sqrt(dist(1,:).^2+dist(2,:).^2+dist(3,:).^2);
    if ROIspec > 0
        ROI_id{i} = find(distsq<=ROIsize);
    else
        ROI_id{i} = find(distsq == min(distsq));
    end
end
for sub = 1:numimg
    % get voxel
    vol = spm_vol(SPM.xY.P{sub});
    [Y XYZ] = spm_read_vols(vol);
    for i = 1:nroi
        switch ROIspec
		case 0 % peak
            [beta(sub,i)  maxind] = max(Y(ROI_id{i}));
            coordinate(sub,:,i) = XYZ(:,ROI_id{i}(maxind))';
		case 1 % local maxima
            [beta(sub,i)  maxind] = max(Y(ROI_id{i}));
            coordinate(sub,:,i) = XYZ(:,ROI_id{i}(maxind))';
		case 2 % roi mean
            beta(sub,i) = nanmean(Y(ROI_id{i}));
		    coordinate(sub,:,i) = mean(XYZ(:,ROI_id{i}),2)';
        end
    end
end


