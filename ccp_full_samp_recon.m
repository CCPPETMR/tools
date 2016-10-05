function CCP_full_samp_recon( varargin )
% CCP_full_samp_recon
%
% CCP_full_samp_recon
% CCP_full_samp_recon( filename )
%
% Based on demo1 from CCP mGadgetron
% xGadgetron/mGadgetron should be on your MATLAB path
% 
% See also pref_uigetfile

% Lower-level interface demo, creates and runs a chain of gadgets.

if ~exist('eshow','file') || ~exist('pref_uigetfile','file') || ...
        ~exist('mutilities.h','file')
    warning(['Need eshow, pref_uigetfile and mutilities.h on path'])
end

if ~libisloaded('mutilities')
    fprintf('loading mutilities library...\n')
    [notfound, warnings] = loadlibrary('mutilities');
end
if ~libisloaded('mgadgetron')
    fprintf('loading mgadgetron library...\n')
    [notfound, warnings] = loadlibrary('mgadgetron');
end

%libfunctions('mutilities')
%libfunctions('mgadgetron')

if nargin > 0
    h5_fn = varargin{1} ;
else
    h5_fn = '' ;
end

if ~exist(h5_fn,'file')
    disp(['Select input HDF5 ISMRMRD file'])
    h5_fn = pref_uigetfile('ccp','filename') ;
end

[pin,fin,ein] = fileparts(h5_fn) ;
defout = fullfile(pin,[fin,'_ccpout.h5']) ;
disp(['Select output h5 file (if file exists, data will be appended).'])
[fnout, pnout] = uiputfile('*.h5','Select output h5 file', defout) ;
fnout = fullfile(pnout, fnout) ;

try
    % define gadgets
    gadget1 = gadgetron.Gadget('RemoveROOversamplingGadget');
	gadget2 = gadgetron.Gadget('AcquisitionAccumulateTriggerGadget');
	gadget3 = gadgetron.Gadget('BucketToBufferGadget');
	gadget4 = gadgetron.Gadget('SimpleReconGadget');
	gadget5 = gadgetron.Gadget('ImageArraySplitGadget');
	gadget6 = gadgetron.Gadget('ExtractGadget');
    
    % set gadget parameters
    gadget2.set_property('trigger_dimension', 'repetition')
    gadget3.set_property('split_slices', 'true')
    
    % create reconstructor
    recon = gadgetron.ImagesReconstructor();

    % build gadget chain
    recon.add_gadget('g1', gadget1);
	recon.add_gadget('g2', gadget2);
	recon.add_gadget('g3', gadget3);
	recon.add_gadget('g4', gadget4);
	recon.add_gadget('g5', gadget5);
	recon.add_gadget('g6', gadget6);
    
    % define raw data source
    input_data = gadgetron.MR_Acquisitions(h5_fn);    
    recon.set_input(input_data)
    % perform reconstruction
    recon.process()
    % get reconstructed images
    images = recon.get_output();
    
    % plot reconstructed images
    for im = 1 : images.number()
        data = images.image_as_array(im);
        % figure('Name',['ccp im ',num2str(im)])
        eshow(data, 'Name',['ccp im ',num2str(im)]);
    end

    % write images to a new group in 'output1.h5'
    % named after the current date and time
    dstr = datestr(datetime) ;
    disp(['appending to file: ',fnout,' with datestr: ',dstr])
    images.write(fnout, dstr)

catch err
    % display error information
    fprintf('%s\n', err.message)
    fprintf('error id is %s\n', err.identifier)
end
