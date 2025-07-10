function nifti_vol_slice(varargin)

% small tool to remove volumes, similar to fslroi in FSL
% Input:
%   fname:      filename to remove volumes
%   v_range:    volume range to include
%   prefix:     prefix for output (default 'f')
% 
% Written by Yosuke Morishma, Feb 10th, 2024


switch nargin
    case 0
        fname=spm_select(1,[],'Specify 4D file to cut',[],[],'^.*\.nii$');
        n_vol=numel(spm_vol(fname));
        v_range=spm_input(sprintf('Volumes to Include: 1:%d',n_vol),1);
        prefix = 'f';
        
    case 1
        fname=varargin{1};
        n_vol=numel(spm_vol(fname));
        v_range=spm_input(sprintf('Volumes to Include: 1:%d',n_vol),1);
        prefix = 'f';
        
    case 2
        fname=varargin{1};
        v_range= varargin{2};              
        prefix = 'f';
        
    case 3
        fname=varargin{1};
        v_range= varargin{2};              
        prefix = varargin{3};
        
    otherwise
        error('Too many inputs')        
end

[pth,f,ext]=fileparts(fname);
new_fname=fullfile(pth,[prefix,f ,ext]);

vol = spm_vol(fname);
vol=vol(v_range);
try
    Y = spm_read_vols(vol);
catch
    for i = 1:length(v_range)
        Y(:,:,:,i) = spm_read_vols(vol(i));
    end
end


for i = 1:length(v_range)
    vol(i).n=[i 1];
    vol(i).fname=new_fname;
    spm_write_vol(vol(i),Y(:,:,:,i));
end




    
    








