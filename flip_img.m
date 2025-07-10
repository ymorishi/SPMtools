function flip_img(imnames)
%  flip_img -- flip RL of LR images
% flip_img(imnames)
%
% Written by Yosuke Morishima, Apr 1st, 2022

spm_defaults;

% prompt for missing arguments
if ( ~exist('imnames','var') || isempty(char(imnames)) )
   imnames = spm_select(inf, 'image', 'Choose images to resize');
end

% reslice images one-by-one
vols = spm_vol(imnames);
spm_progress_bar('Init',length(vols),'Flipping...','images completed');
for i= 1:length(vols)
    Y = spm_read_vols(vols(i));
    Y = Y(end:-1:1,:,:);
    vols(i).mat(1,:)= -vols(i).mat(1,:);
    if mod(vols(i).mat(1,4),2)==0 && vols(i).mat(1,4)==vols(i).dim(1)/2
        vols(i).mat(1,4)=vol(i).dim(1)-vols(i).mat(1,4)+1;
    end
    spm_write_vol(vols(i),Y);
    spm_progress_bar('Set', i)
end
spm_progress_bar('Clear');

disp('Done.')

