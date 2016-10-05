function file_name = pref_uigetfile(group, pref, deffile)
% PREF_UIGETFILE Calls uigetfile using stored user preferences
% Stores file name so that subsequent calls to this function place the user
% in the same folder as before.
%
% file_name = pref_uigetfile(group, pref, deffile)
% file_name = pref_uigetfile(group, pref)
%
% David Atkinson   D.Atkinson@ucl.ac.uk
% See also UIGETDIR  UIGETFILE PREF_UIGETDIR
%

if nargin > 2 && exist(deffile,'file')
    % do nothing
else  
    % set deffile from preferences
    if ispref(group,pref)
        deffile = getpref(group, pref);
    else
        deffile = '' ;
    end
end
    
[fn,pn] = uigetfile('*','Select file',deffile) ;
    
if fn == 0
    warning(['No file specified'])
    file_name = [];
    return
else
    file_name = fullfile(pn,fn) ;
end


setpref(group, pref, file_name)

