function ccp_grappa
% CCP_GRAPPA Annotated demo for GRAPPA reconstruction
% 
% Code builds three gadget chains to do;
%   pre-processing of acquisition data (k-space),
%   reconstruction of undersampled data,
%   extraction of images.
%
% Usage:
%  Convert scanner raw data to ISMRMRD format e.g. by using the executable
%  siemens_to_ismrmrd. Example raw data is available from 
%  https://www.ccppetmr.ac.uk/downloads
%  Choose the GRAPPA dataset.
%
%  Ensure there is a listening Gadgetron - typically started in a terminal.
%
%  ccp_grappa
%
%
% Adapted by David Atkinson from original code by Evgueni Ovtchinnikov
% See also CCP_LIBLOAD


% load mutilities and mgadgetron libraries if not already loaded
ccp_libload

try
    % Set three groups of gadgets
    % First group is k-space (acquisition) processing
    gadget11 = gadgetron.Gadget('NoiseAdjustGadget');
    gadget12 = gadgetron.Gadget('AsymmetricEchoGadget');
    gadget13 = gadgetron.Gadget('RemoveROOversamplingGadget');
    % Second group is for the reconstruction 
    gadget21 = gadgetron.Gadget('AcquisitionAccumulateTriggerGadget');
    gadget22 = gadgetron.Gadget('BucketToBufferGadget');
    gadget23 = gadgetron.Gadget('PrepRefGadget');
    gadget24 = gadgetron.Gadget('CartesianGrappaGadget');
    gadget25 = gadgetron.Gadget('FOVAdjustmentGadget');
    gadget26 = gadgetron.Gadget('ScalingGadget');
    gadget27 = gadgetron.Gadget('ImageArraySplitGadget');
    % Third group is for output
    gadget31 = gadgetron.Gadget('ComplexToFloatGadget');
    gadget32 = gadgetron.Gadget('FloatToShortGadget');
    
    % get the filename for the input ISMRMRD h5 file
    filein = pref_uigetfile('ccp','filename');
    input_MRACQ = gadgetron.MR_Acquisitions(filein);

    % define a CCP gadgetron.AcquisitionsProcessor and process data
    acq_proc = gadgetron.AcquisitionsProcessor();
    acq_proc.add_gadget('g1', gadget11)
    acq_proc.add_gadget('g2', gadget12)
    acq_proc.add_gadget('g3', gadget13)
    fprintf('pre-processing acquisitions...\n')
    preprocessed_AcqCont = acq_proc.process(input_MRACQ);
    % The 'process' above invokes a call to the gadgetron chain.
    % The output preprocessed_AcqCont is a CCP gadgetron.AcquisitionsContainer

    % Alternative code is either:
    % 1)  preprocessed_AcqCont = gadgetron.MR_Acquisitions(filein); 
    %
    % or
    % 2)
    %
    %   prep_gadgets = [{'NoiseAdjustGadget'} {'AsymmetricEchoGadget'} ...
    %     {'RemoveROOversamplingGadget'}];
    %  preprocessed_AcqCont = input_MRACQ.process(prep_gadgets);
    
    % define reconstructor, here a gadgetron.ImagesReconstructor
    recon = gadgetron.ImagesReconstructor();
    recon.add_gadget('g1', gadget21)
    recon.add_gadget('g2', gadget22)
    recon.add_gadget('g3', gadget23)
    recon.add_gadget('g4', gadget24)
    recon.add_gadget('g5', gadget25)
    recon.add_gadget('g6', gadget26)
    recon.add_gadget('g7', gadget27)    

    % Alternative codes for the above either :
    %  1)  recon = gadgetron.MR_BasicGRAPPAReconstruction()
    %
    % or
    %
    %  2)
    %     gadgets = [...
    %         {'AcquisitionAccumulateTriggerGadget'}, ...
    %         {'BucketToBufferGadget'}, ...
    %         {'PrepRefGadget'}, ...
    %         {'CartesianGrappaGadget'}, ...
    %         {'FOVAdjustmentGadget'}, ...
    %         {'ScalingGadget'}, ...
    %         {'ImageArraySplitGadget'} ...
    %         ];
    %     recon = gadgetron.ImagesReconstructor(gadgets);

    
    % Set the preprocessed_data as input.
    recon.set_input(preprocessed_AcqCont)
    
    % perform the reconstruction. 'process' streams data to gadgetron
    fprintf('reconstructing images...\n')
    recon.process()
    
    % get reconstructed complex images and coil G-factors
    % complex_output is a CCP gadgetron.ImagesContainer
    complex_ImCont = recon.get_output();

    
    % Prepare to extract real images using a short gadget chain
    % Set a CCP gadgetron.ImagesProcessor (a gadget chain)
    img_proc = gadgetron.ImagesProcessor();
    img_proc.add_gadget('g1', gadget31)
    img_proc.add_gadget('g2', gadget32)
    
    % Notify of conversion to real?
    complex_ImCont.conversion_to_real(1)  
    
    % process 'complex_ImCont' to get 'output_ImCont' (another CCP
    % gadgetron.ImagesContainer )
    fprintf('processing images...\n')
    output_ImCont = img_proc.process(complex_ImCont);

    % plot reconstructed images and G-factors
    n = output_ImCont.number()/2;
    
    % Getting first output images in order to reserve space 
    data1  = output_ImCont.image_as_array(1);
    gdata1 = output_ImCont.image_as_array(2);
    
    data  = zeros(size(data1,1),  size(data1,2),n);
    gdata = zeros(size(gdata1,1), size(gdata1,2),n);
    
    for isl = 1:n
        data(:,:,isl)  = output_ImCont.image_as_array(2*isl - 1);
        gdata(:,:,isl) = output_ImCont.image_as_array(2*isl) ;
    end
    
    % display
    eshow(data,'Name','data')
    eshow(gdata,'Name','gfactor')
    

    % write images to a new h5 dataset group named 
    % after the current date and time
    [fn,pn] = uiputfile('*.h5', 'H5 output file', 'output6.h5') ;
    opfn = fullfile(pn,fn) ;
    
    disp(['Output will be appended to: ',opfn])
    
    output_ImCont.write(opfn, datestr(datetime))

catch err
    % display error information
    fprintf('%s\n', err.message)
    fprintf('error id is %s\n', err.identifier)
end
