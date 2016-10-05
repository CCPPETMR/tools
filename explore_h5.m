function [fn, dsn] = explore_h5
% EXPLORE_H5 Explore HDF5 files for ISMRMRD
% Writes out information from the h5 file.
% Opens a listbox with any xml data detected.
%
%  [fn, dsn] = explore_h5
%
%  On completion, 
%     fn  is the name of the file read
%     dsn is a cell array of dataset names. Can be passed to h5read
%
% Example:
%  [fn, dsn] = explore_h5 ;
%  data = h5read(fn, dsn{1}) ;
%
% Does not require the ISMRMRD Matlab functions.
%
% David Atkinson. D.Atkinson@ucl.ac.uk  University College London
%
% See also explore_ismrmrd_flags
%

if nargout < 2
    disp(['Usually better called with 2 outputs:  [fn, dsn] = explore_h5 ;'])
end


fn = pref_uigetfile('explore_h5', 'filename') ;
if ~exist(fn,'file')
    return
end

info = h5info(fn) ;

disp(['Filename: ',info.Filename])

idstot = 0 ;
dsn = {};
ctext = {} ;

h5gview(info)

disp(' ')
for idsn = 1:idstot
    [pstr,dname] = fileparts(dsn{idsn}) ;
    
    switch dname
        case 'header'
            % Most likely an Image header (image or sorted k-space)
            hdr = h5read(fn,dsn{idsn}) ;
            disp(['Header for dsn{',num2str(idsn),'}: ',dsn{idsn}])
            disp_hdr(hdr) ;
        case 'data'
            data = h5read(fn,dsn{idsn}) ;
            if isstruct(data) && isfield(data,'head')
                % Acquisition Header
                disp(['head field within dsn{',num2str(idsn),'}: ',dsn{idsn}])
                disp_hdr(data.head)
            end
        case 'xml'
            hf = figure('Name',fn) ;
            
            c = uicontrol(hf,'Style','listbox', ...
                'String', h5read(fn, dsn{idsn}), ...
                'Units','normalized','Position',[0 0 1 1], ...
                'FontSize',16) ;
        otherwise
    end
end

disp([' '])
disp(['Dataset names:'])
for idsn = 1:length(dsn)
    disp(ctext{idsn})
end
disp(['  data = h5read(fn,dsn{ }) ;  % enter correct number in { } to read data'])

% ---------

    function h5gview(info)
        ngroup = length(info.Groups) ;
        nds = length(info.Datasets) ;
        
        disp([info.Name,' : ',num2str(ngroup),' gp, ',num2str(nds),' ds'])
        for ids = 1:nds
            idstot = idstot + 1;
            dsn{idstot} = [info.Name,'/',info.Datasets(ids).Name];
            ctext{idstot} = ['dsn{',num2str(idstot),'}:  ',dsn{idstot}, ...
                ' : [',num2str(info.Datasets(ids).Dataspace.Size),']'];
        end
        
        for igroup = 1:ngroup
            h5gview(info.Groups(igroup))
        end
    end

end

function disp_hdr(hdr,pre_str)
if nargin < 2
    pre_str = '' ;
end

hdr_name = fieldnames(hdr) ;
for iname = 1:length(hdr_name)
    vals = hdr.(hdr_name{iname}) ;
    if isstruct(vals)
        disp([' ',hdr_name{iname}])
        disp_hdr(vals,'    ') ; % idx
        disp([ ' ' ])
    else
        
        [ny nx] = size(vals) ;
        if nx> 1 && ny> 1
            vstr = ['[',num2str(ny),' ',num2str(nx),'], first ',num2str(vals(:,1)')] ;
        else
            if length(vals) < 11
                vstr = sprintf('%g ',vals) ;
            else
                vstr = ['[',num2str(length(vals)),']'] ;
                uq = unique(vals) ;
                if length(uq) == 1
                    vstr = [vstr,' all ',num2str(uq)];
                else
                    vstr = [vstr,', max: ',num2str(max(vals)),', min: ',...
                        num2str(min(vals))] ;
                end
            end
        end
        nmstr = sprintf('%30s : ',hdr_name{iname}) ;
        disp([pre_str,nmstr,vstr])
    end
end
disp(' ')
end


