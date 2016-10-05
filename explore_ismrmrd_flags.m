function [ output_args ] = explore_ismrmrd_flags( varargin )
%EXPLORE_ISMRMRD_FLAGS Show summary of ISMRMRD flags
%  
% explore_ismrmrd_flags
% explore_ismrmrd_flags( filename )
%
% Requires ISMRMRD MATLAB files on path
%
% D.Atkinson@ucl.ac.uk
% See also EXPLORE_H5  

if nargin > 0
    if exist(varargin{1},'file')
        fn = varargin{1} ;
    else
        fn = pref_uigetfile('explore_ismrmrd_flags', 'filename') ;
    end
else
    fn = pref_uigetfile('explore_ismrmrd_flags', 'filename') ;
end
    

if exist(fn, 'file')
    dset = ismrmrd.Dataset(fn, 'dataset');
else
    return
end


D = dset.readAcquisition();

% This is how to check if a flag is set in the acquisition header
isNoise = D.head.flagIsSet('ACQ_IS_NOISE_MEASUREMENT');
ispci   = D.head.flagIsSet('ACQ_IS_PARALLEL_CALIBRATION_AND_IMAGING') ;
ispc   = D.head.flagIsSet('ACQ_IS_PARALLEL_CALIBRATION') ;
isfes1 = D.head.flagIsSet('ACQ_FIRST_IN_ENCODE_STEP1');
isfslc = D.head.flagIsSet('ACQ_FIRST_IN_SLICE') ;
isfrep = D.head.flagIsSet('ACQ_FIRST_IN_REPETITION') ;
            
            
hf = figure('Name','ISMRMRD flags');
set(hf,'DefaultAxesFontSize',14)
set(hf,'DefaultLineMarkerSize',14)
plot(isNoise*1.5,'ro','MarkerFaceColor',[1 0 0]), hold on
plot(ispci*2,'bx')
plot(ispc*3,'bo')
plot(isfes1,'mo')
plot(isfslc,'mx')
plot(isfrep,'kx')
plot(0,3.5)
plot(0,-0.25)

legend('noise','acs and im', 'acs','1st in enc step1', '1st in slce', '1st in rep')

xlabel('measurement number')
yticks([])
ylabel([])

end

