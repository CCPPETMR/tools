function [xDoc, hStruct] = explore_ismrmmrd
% See also explore_h5

fn = pref_uigetfile('explore_ismrmrd', 'filename') ;

dxml = h5read(fn,'/dataset/xml') ;
ddata = h5read(fn,'/dataset/data') ;
size(ddata)


xml = dxml{1} ;

tempfn = [tempname,'.xml'] ;

fid = fopen(tempfn,'w') ;
fprintf(fid, '%s', xml)
fclose(fid) ;
disp(['Written to file: ',tempfn])

xDoc = xmlread(tempfn) ;
hStruct = parseXML(tempfn) ;

expand_xml(hStruct)

% Note on Gadgetron



function expand_xml(struct)

switch struct.Name
   case '#text'
   otherwise
      disp([struct.Name])    
end

if ~isempty(struct.Data) 
    disp(strtrim(struct.Data))
end

nc = length(struct.Children) ;
for ic = 1:nc
    expand_xml(struct.Children(ic)) 
end





