# Useful tools for SPM

## Tools to extract beta estimates from group-level (2nd level/RFX) SPM
### rfxbeta_localmax.m
Extracting beta estimates

Specify group level (RFX) SPM.mat file then extract beta estimate from 
  - a single coordinate specified
  - searching individual local maxima within X mm from a peak coordinate specified
  - mean of voxels within X mm from a peak coordinate specified
  
### rfxbeta_manySPMlocalmax.m
Same as "rfxbeta_localmax.m", but you can specify multiple group level SPM files

### rfxbeta_maskimg.m
Extracting beta estimates
Specify group level (RFX) SPM.mat file then extract beta estimate from 
  - mask image specified

## A tool to extract values of voxles defined by a mask image
### extract_from_mask.m
The voxel space of mask image (bounding box or voxel size) is not necessary to match to images to extract
Using a part of Ged Ridgway's "resize_img.m" to resize the mask image 


## Nifty image viewer with FSLeye's movie like functionality
### nifti4d_viewer.m
Display nifti 4D image like a gif movie together with frame-wise displacement computed from rp_.txt

## NIFTI image manipulation
### flip_img.m
Flip LR-RL format (convert from SPM to FSL or FSL to SPM)

### nifti_vol_slice.m
Slice 4D Nifti images (volume level)
  Similar to FSLROI in FSL

