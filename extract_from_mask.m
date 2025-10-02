function beta = extract_from_mask(varargin)
% Extract mean voxel_values specified by a mask image 
% extract_from_mask(p_img,p_mask, name)
% Input
%     p_img : full path of nifit image to extract values
%     p_mask : full path of mask image
%              mask image must be either 0/1 binary or 0/1/.../n intergers 
% Output 
%     beta : Extracted voxel values (i x n)
%             i: number of input image
%             n: number of masks in a mask image
%
% WARNING  
% If the image dimension of the mask image does not match to that of image 
% to extract, this program automatically resize the mask image. However, 
% the resize process may be less accurate when reslicing a 1-n integer mask.
% Using a binary (0/1) mask image is highly recommened, if a mask image
% with unmatched dimension is used.
%
% A part of this function uses resize_img.m
%  http://www0.cs.ucl.ac.uk/staff/g.ridgway/vbm/resize_img.m
%  
%
% Written by Yosuke Morishima 2nd of Oct, 2025
%

% Check input
switch nargin
    case 0
        p_img = spm_select(Inf,'image','Select imgage(s) to extract values');
        p_mask = spm_select(1,'image','Select mask image');
    case 1
        p_img = varargin{1};
        p_mask = spm_select(1,'image','Select mask image');
        
    case 2
        p_img = varargin{1};
        p_mask = varargin{2};
        
    otherwise
            error('Input was wrong')
end
        

vol_img=spm_vol(p_img);
vol_mask=spm_vol(p_mask);

Y_mask= spm_read_vols(vol_mask);
mask_ind=unique(Y_mask);
mask_ind(mask_ind==0)=[];

% Resize image dimension, bb-box, if mask image does not match to target images
if isequal(vol_img.dim,vol_mask.dim) + isequal(vol_img.mat(1:3,1:3),vol_mask.mat(1:3,1:3)) <2
    new_mask=zeros(vol_img.dim);
    for i = 1:length(mask_ind)
        tmp_vol=vol_mask;
        tmp_vol.fname=fullfile(fileparts(p_img),'tmp.nii');
        tmpY=zeros(vol_mask.dim);
        tmpY(Y_mask==mask_ind(i))=1;
        spm_write_vol(tmp_vol,tmpY);
        tmp_mask=mask_reslice(tmp_vol,vol_img);
        new_mask(find(tmp_mask))=mask_ind(i);
    end
    Y_mask=new_mask;
    spm_unlink(fullfile(fileparts(p_img),'tmp.nii'))
end

% Extract voxel values
beta = zeros(numel(vol_img),length(mask_ind));
for i = 1:length(mask_ind)
    [x, y, z]=ind2sub(size(Y_mask),find(Y_mask ==mask_ind(i)));
    tmp_XYZ = [x';y';z'];
    beta(:,i)=nanmean(spm_get_data(vol_img,tmp_XYZ),2);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_mat = mask_reslice(vol_input, vol_target)

voxsize = diag(vol_target.mat);
Voxdim = abs(voxsize(1:3));
bbstart = vol_target.mat*[1 1 1 1]';
bbend = vol_target.mat*[vol_target.dim 1]';
BB = sort([bbstart(1:3)';bbend(1:3)']);

% reslice images
voxdim = Voxdim;
bb = BB;
voxdim = voxdim(:)';
mn = bb(1,:);
mx = bb(2,:);

% voxel [1 1 1] of output should map to BB mn
% (the combination of matrices below first maps [1 1 1] to [0 0 0])
mat = spm_matrix([mn 0 0 0 voxdim])*spm_matrix([-1 -1 -1]);

% voxel-coords of BB mx gives number of voxels required
% (round up if more than a tenth of a voxel over)
imgdim = ceil(mat \ [mx 1]' - 0.1)';
img_mat=zeros(vol_target.dim);
for i = 1:imgdim(3)
    M = inv(spm_matrix([0 0 -i])*inv(mat)*vol_input.mat);
    img = spm_slice_vol(vol_input, M, imgdim(1:2), 1); % (linear interp)
    img = round(img);
    img(find(img)) = 1;
    img_mat(:,:,i)=img;        
end

% check LR flip
if mat(1,1) == -vol_input.mat(1,1)
    img_mat = img_mat(end:-1:1,:,:);
end
