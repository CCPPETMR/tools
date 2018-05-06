function varargout = eshow(varargin)
%ESHOW viewing tool for 2D, 3D, rgb and complex data
%    FIG = ESHOW launch dshow GUI.
%    ESHOW(A)                    display data A, vdims defaults to [1 1 1]
%    ESHOW(A, vdims)  vdims is a vector of pixel sizes [row col slice ...]            
%    ESHOW(A,'window name')
%    ESHOW(A,vdims,'window name')
%    ESHOW(A, param, val, ...)    parameter value pairs
%                                 'vdim', 'name', 'isrgb'
%
%    ESHOW('callback_name', ...) invoke the named callback.
%
% Now accepts 2D or 3D rgb. 
%  e.g. eshow(A,'isrgb',1)  where the last dimension of A has size 3.
%
% Key presses
%  R or r    - redraws and reslices at current cross-hair position
%  1         - set point 1 for 3 point plane definition
%  2         - set point 2
%  3         - set point 3
%  p         - reslice using 3 point plane definition
%  n         - define plane by points 1,2 and the normal
%  m         - montage 
%  v         - movie
%  l         - toggles locking of window levels.
%  t         - time. Plot of 3rd diemnsion at current cross-hair. Use r
%              first.
%  d         - toggles dynamic time plot.
%  f         - fix dynamic plot line so not deleted
%  k         - mIP
%  c         - Cross-section, centred at P3 with plane normal P2-P1
%  
% D.Atkinson@ucl.ac.uk  
% $Id: eshow.m 3698 2010-08-18 14:27:51Z da $
%


if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
    catch ME
		ME
	end

elseif numel(varargin{1}) > 1

    % old style input or param val pairs?
  % Is there a control figure?
  %  NO - create one
  
  % data input
  % open a figure
  % set its UserData
  %
  % call fig_draw
  
  isrgb = 0 ;
  
  if nargin == 1
    varname = inputname(1) ;
    vdim = [1 1 1];
  elseif nargin == 2 && ischar(varargin{2})
    varname = varargin{2} ;
    vdim = [1 1 1] ;
  elseif nargin >= 3
      if ischar(varargin{2})
          % param val pairs
          vdim = [ 1 1 1] ;
          varname = inputname(1) ;
          for ipv = 2:2:nargin
              param = varargin{ipv};
              val   = varargin{1+ipv};
              switch param
                  case 'vdim'
                      vdim = val ;
                  case {'name', 'Name'}
                      varname = val ;
                  case 'isrgb'
                      isrgb = val ;
                  case 'geom'
                      vdim(1) = val(1).PixelSpacing_HW(1) ;
                      vdim(2) = val(1).PixelSpacing_HW(2) ;
                      vdim(3) = val(1).SliceThickness ;
              end
          end
      else
        varname = varargin{3} ;
        vdim = varargin{2} ;
      end
  elseif nargin ==2 && ~ischar(varargin{2})
    varname = inputname(1) ;
    vdim = varargin{2} ;
  end
  
  if isstruct(vdim)
      vdim = vdim.vdims ;
  end
  
  cfig = eshow ;
  set(cfig,'Name','Control Pane');
  
  Y=1; X=2; Z=3 ;
  
  if length(vdim) == 2
    vdim(3) = 1 ;
  elseif length(vdim) == 4
    vdim = vdim(1:3) ;
  end
  
  UD.dat = varargin{1} ;
  if strcmp(class(UD.dat),'uint8') == 1 || ...
            strcmp(class(UD.dat),'uint16') == 1
    UD.dat = double(UD.dat) ;
  end
  if isrgb
      if ndims(UD.dat) > 4
          error('rgb data cannot have more than 4 dimensions')
      end
      szuddat = size(UD.dat) ;
      if szuddat(end) ~= 3
          error('rgb must have last dim size 3')
      end
  end
  if ndims(UD.dat)>3 && ~isrgb
	  if ndims(squeeze(UD.dat))<=3
		  warning(['Squeezing input data'])
		  UD.dat = squeeze(UD.dat) ;
	  else
		  error(['Cannot display data with these dimensions.'])
	  end
  end
  
  if ndims(UD.dat) == 4 && isrgb
      if size(UD.dat,3) == 1
          UD.dat = squeeze(UD.dat) ;
      end
  end
  
  if isrgb
      UD.coord = ceil( (size(UD.dat)+1)/2) ; 
      if size(UD.dat,4) == 1
          UD.coord(Z) = 1 ;
      end
  else
      UD.coord = ceil( (size(UD.dat)+1)/2) ;
      if size(UD.dat,3) == 1
          UD.coord(Z) = 1 ;
      end
  end
  
  UD.vdim = vdim ;
  if isrgb
    UD.dtype = 'rgb' ;
    UD.pop1 = 5 ;
  else
      if isreal(UD.dat)
          UD.dtype = 'real' ;
          UD.pop1 = 3 ;
      else
        UD.dtype = 'modulus' ;
        UD.pop1 = 1 ;
      end
  end
  
  UD.dspmin = min(min(min(min(abs(UD.dat))))) ;
  UD.dspmax = max(max(max(max(abs(UD.dat))))) ;
  UD.datmin = UD.dspmin;
  UD.datmax = UD.dspmax ;
  UD.gamma = 1 ;
  UD.cfig = cfig ;
  UD.cursor = 'on' ;
  UD.dplot = false ; 
  UD.hheld = [] ;
 
  
  UD.pop2 = 1 ;
  UD.pop3 = 1 ;
  UD.lock = -1 ; 
  UD.isrgb = isrgb ;
  
  hf = figure ;
  if verLessThan('matlab','8.4.0')
      hf_number = hf ;
  else
      hf_number = hf.Number ;
  end
  
  if ~isempty(varname)
      labtxt = [' (',varname,')'];
  else
      labtxt = '' ;
  end
  disp([' Opened figure number: ',num2str(hf_number),labtxt])
  set(hf,'Name',varname) ;
  set(hf,'UserData',UD) ;
  set(hf,'Tag','eshowfig') ;
  
  hcfig = guihandles(cfig) ;
  set(hcfig.edit1,'String',num2str(hf_number)) ;
  figure(cfig) % bring control figure forward
  
  if ~isrgb
      % remove rgb from popupmenu1
     strs = get(hcfig.popupmenu1,'String') ;
     strs = strs(1:4,1) ;
     set(hcfig.popupmenu1,'String',strs) ; 
  end 

  % fake an entry to active figure box, this also updates popupmenu
  eshow('edit1_Callback',hcfig.edit1,[],hcfig)   
end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.



% --------------------------------------------------------------------
function varargout = popupmenu1_Callback(h, eventdata, handles, varargin)
% popupmenu1_Callback datatype
strs = get(handles.popupmenu1,'String') ;
val =  get(handles.popupmenu1,'Value')  ;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;
UD.dtype = strs{val} ;
UD.pop1 = val ;

UD = dat_up(handles,UD) ;

set(fig,'UserData',UD) ;

fig_draw(fig,UD) ;

% --------------------------------------------------------------------
function varargout = popupmenu2_Callback(h, eventdata, handles, varargin)
% cursor on/off
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

UD.pop2 = get(h,'Value') ;
if get(h,'Value') == 1
  UD.cursor = 'on' ;
else
  UD.cursor = 'off' ;
end

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
%unction varargout = popupmenu3_Callback(h, eventdata, handles, varargin)

%isp('popupmenu3 callback not implemented yet')


% --------------------------------------------------------------------
function varargout = edit2_Callback(h, eventdata, handles, varargin)
% edit2_Callback Display maximum

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

dspmax = str2num(get(h,'String')) ;
UD.dspmax = dspmax ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit3_Callback(h, eventdata, handles, varargin)
% edit3_Callback Display minumum

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

dspmin = str2num(get(h,'String')) ;
UD.dspmin = dspmin ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit4_Callback(h, eventdata, handles, varargin)
% edit4_Callback Gamma

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

gamma = str2num(get(h,'String')) ;
UD.gamma = gamma ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;


% --------------------------------------------------------------------
function varargout = pushbutton1_Callback(h, eventdata, handles, varargin)
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

UD.dspmax = UD.datmax ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;

set(handles.edit2,'String',UD.dspmax)


% --------------------------------------------------------------------
function varargout = pushbutton2_Callback(h, eventdata, handles, varargin)
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

UD.dspmin = UD.datmin ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;

set(handles.edit3,'String',UD.dspmin)



% --------------------------------------------------------------------
function varargout = pushbutton3_Callback(h, eventdata, handles, varargin)
% decrease gamma
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;
UD.gamma = UD.gamma - 0.1 ;
if UD.gamma < 0.1
    UD.gamma = 0.1 ;
end
set(fig,'UserData',UD)
fig_draw(fig,UD) ;

set(handles.edit4,'String',num2str(UD.gamma))

% --------------------------------------------------------------------
function varargout = pushbutton4_Callback(h, eventdata, handles, varargin)
% increase gamma
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;
UD.gamma = UD.gamma + 0.1 ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;

set(handles.edit4,'String',num2str(UD.gamma))


% --------------------------------------------------------------------
function varargout = slider1_Callback(h, eventdata, handles, varargin)
% slider1_Callback X coord
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

val = round(get(h,'Value')) ;
UD.coord(X) = val ;
set(handles.edit5,'String',num2str(val)) ;

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit5_Callback(h, eventdata, handles, varargin)
% cursor x value
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

vals = get(h,'String') ;
UD.coord(X) = str2num(vals) ;

set(handles.slider1,'Value',str2num(vals))

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = slider2_Callback(h, eventdata, handles, varargin)
% slider2_Callback Y coord
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

val = round(get(h,'Value')) ;
UD.coord(Y) = val ;
set(handles.edit6,'String',num2str(val)) ;

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit6_Callback(h, eventdata, handles, varargin)
% cursor y value
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

vals = get(h,'String') ;
UD.coord(Y) = str2num(vals) ;

set(handles.slider2,'Value',str2num(vals))

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = slider3_Callback(h, eventdata, handles, varargin)
% slider2_Callback Z coord
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

val = round(get(h,'Value')) ;
UD.coord(Z) = val ;
set(handles.edit7,'String',num2str(val)) ;

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit7_Callback(h, eventdata, handles, varargin)
% cursor z value
Y=1; X=2; Z=3;

fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;

vals = get(h,'String') ;
UD.coord(Z) = str2num(vals) ;

set(handles.slider3,'Value',str2num(vals))

set(fig,'UserData',UD) ;
fig_draw(fig,UD) ;



% --------------------------------------------------------------------
function varargout = edit8_Callback(h, eventdata, handles, varargin)
disp('edit8 Callback not implemented yet')


% --------------------------------------------------------------------
function UD = fig_draw(fig, UD)
% Given the figure handle, gets all the parameters and draws the
% figure in that window.

Y = 1 ; X = 2 ; Z = 3 ;

figure(fig)

if nargin < 2
  UD = get(fig, 'UserData' ) ; 
end

dat = UD.dat ;
vdim = UD.vdim ;
coord = UD.coord ;

[ny nx nz nc] = size(dat) ;
if UD.isrgb
    if nc == 1
        nz = 1 ; nc = 3 ;
    end
end

mindim = min(vdim) ;
scvdims = vdim / mindim ;
  
nwy = round(ny * scvdims(Y)) ;
nwx = round(nx * scvdims(X)) ;
nwz = round(nz * scvdims(Z)) ;

scvdims = [nwy/ny nwx/nx nwz/nz] ; % 
  
if UD.isrgb
    
    if ndims(dat)== 4
        Ixy = squeeze(dat(:,:,coord(Z),:)) ;
        Iyz = squeeze(dat(:,coord(X),:,:)) ;
        Ixz = squeeze(dat(coord(Y),:,:,:)) ;
        Ixz = rotn90(Ixz) ;
        Ixz = flip(Ixz,1) ;
    else
        Ixy = squeeze(dat(:,:,:)) ;
        Iyz = dat(:,coord(X), :) ;
        Ixz = dat(coord(Y),:,:) ;
    end 
    window = zeros(nwy+nwz, nwx+nwz, 3) ;
    window(1:nwy,1:nwx,:) = imresize(Ixy, [nwy nwx]) ;
    window(nwy+1:nwy+nwz , 1:nwx, :) = imresize(Ixz,[nwz nwx]) ;
    window(1:nwy , nwx+1 : nwx+nwz,:) = imresize(Iyz, [nwy nwz]) ;
else
  Ixy = squeeze(dat(:,:,coord(Z))) ;
  if ndims(dat) == 3
    Iyz = squeeze(dat(:,coord(X),:)) ;
    Ixz = squeeze(dat(coord(Y),:,:)) ;
    Ixz = rot90(Ixz) ;
    Ixz = flipud(Ixz) ;
  else
    Iyz = dat(:,coord(X)) ;
    Ixz = dat(coord(Y),:) ;
  end
  window = zeros(nwy+nwz, nwx+nwz) ;
  window(1:nwy,1:nwx) = imresize(Ixy, [nwy nwx]) ;
  window(nwy+1:nwy+nwz , 1:nwx) = imresize(Ixz,[nwz nwx]) ;
  window(1:nwy , nwx+1 : nwx+nwz) = imresize(Iyz, [nwy nwz]) ;
  
end

UD.nwx = nwx ; UD.nwy = nwy ; UD.nwz = nwz ;
UD.scvdims = scvdims ;
set(fig,'UserData',UD) ;

if strcmp(class(window), 'uint8') == 1
  dat = double(window) ;
end

bdpref = iptgetpref('Imshowborder') ;
% truesize in 7.0 but not in 7.01
prefs = iptgetpref ;


if isfield(prefs,'ImshowTruesize')
    ts = 'ImshowTruesize' ;
    ts_val = 'manual' ;
else
    ts = 'ImshowInitialMagnification' ;
    ts_val = 'fit' ;
end

tspref = iptgetpref(ts) ;

switch UD.dtype
  case 'modulus'
    dw = abs(window) ;
  case 'real'
    dw = real(window) ;
  case 'phase'
    dw = angle(window) ;
  case 'imaginary'
    dw = imag(window) ;
  case 'rgb'
    dw = window ;
  otherwise
    error([ 'Unknown data type.'])
end

iptsetpref('Imshowborder','tight')
iptsetpref(ts,ts_val) 

if UD.isrgb
    imshow(mat2gray(dw, [UD.dspmin UD.dspmax]).^UD.gamma)
else
    aw = mat2gray(dw, [double(UD.dspmin) double(UD.dspmax)]) ;
    if islogical(aw)
      imshow(aw)
    else
        aw_adj = imadjust(aw, [],[], UD.gamma) ;
        aw_full = imlincomb((double(UD.dspmax)-double(UD.dspmin)), aw_adj, double(UD.dspmin)) ;
        imshow(aw_full,[])
    end
end

iptsetpref(ts,tspref) ;
iptsetpref('Imshowborder',bdpref) ;

% newc = (oldc-0.5)*scvdims(C) + 0.5

hl = line([nwx+0.5 nwx+0.5], [0.5 nwy+nwz+0.5]) ;
set(hl,'Color','red') 
hl = line([0.5 nwx+nwz+0.5], [ nwy+0.5 nwy+0.5]) ;
set(hl,'Color','red') 

switch UD.cursor
  case 'on'
    line([0.5 nx*scvdims(X)+0.5], ...
	       repmat((UD.coord(Y)-0.5)*scvdims(Y)+0.5,[1 2])) ; 
    line(repmat((UD.coord(X)-0.5)*scvdims(X)+0.5,[1 2]), ...
	[0.5 ny*scvdims(Y)+0.5]) ; 
    % more to add here
    
    line([ 0.5 nwx+0.5], ...
	repmat((UD.coord(Z)-0.5)*scvdims(Z)+0.5+nwy , [1 2])) ;
    line(repmat((UD.coord(X)-0.5)*scvdims(X)+0.5,[1 2]), ...
	[nwy+0.5 nwz+nwy+0.5])
    
    line(repmat((UD.coord(Z)-0.5)*scvdims(Z)+0.5+nwx , [1 2]), ...
	[0.5 nwy+0.5])
    
    line([nwx+0.5 nwx+nwz+0.5],...
	repmat((UD.coord(Y)-0.5)*scvdims(Y)+0.5,[1 2])) ;
end

drawnow

%--------------------------------------------------------------

function UD = dat_up(handles,UD)
switch UD.dtype
  case 'modulus'
    datmax = max(max(max(abs(UD.dat)))) ;
    datmin = min(min(min(abs(UD.dat)))) ;   
  case 'phase'
    datmax = max(max(max(angle(UD.dat)))) ;
    datmin = min(min(min(angle(UD.dat)))) ;
  case 'real'
    datmax=  max(max(max(real(UD.dat)))); 
    datmin = min(min(min(real(UD.dat)))) ;
  case 'imaginary'
    datmax = max(max(max(imag(UD.dat)))) ;
    datmin = min(min(min(imag(UD.dat)))) ;
  case 'rgb'
    datmax =  max(max(max(max(UD.dat)))) ; 
    datmin =  min(min(min(min(UD.dat)))) ;   
end
if UD.lock == -1 
  UD.dspmax = datmax ;
  UD.dspmin = datmin ;

  UD.datmin = datmin ;
  UD.datmax = datmax ;
end

set(handles.text13,'String',num2str(datmax))
set(handles.text14,'String',num2str(datmin))

set(handles.edit2,'String',UD.dspmax)
set(handles.edit3,'String',UD.dspmin)
set(handles.edit4,'String',UD.gamma)


%---------------------------------------------------------
function motion
% MOTION (dshow)
%
 
Y = 1; X = 2 ; Z = 3 ;
 
dfig = gcbf ;
UD = get(dfig,'UserData') ;
if ~ishandle(UD.cfig)
    % assume control fig was accidentally closed
    hfo = findobj(0,'Name','Control Pane');
    if length(hfo) > 1
        warning(['more than 1 control pane'])
    elseif isempty(hfo)
        cfig = eshow;
        UD.cfig = cfig;
        hcfig = guihandles(cfig) ;
    else
        UD.cfig = hfo ;
        hcfig = guihandles(UD.cfig) ;
    end
    set(dfig,'UserData',UD) ;
else
  hcfig = guihandles(UD.cfig) ;
end

if verLessThan('matlab','8.4.0')
    dfig_number = dfig ;
    pointer = 'fullcrosshair' ;
else
    dfig_number = dfig.Number ;
    pointer = 'crosshair' ;
end
  
if str2num(get(hcfig.edit1,'String'))~= dfig_number
  set(dfig,'Pointer','arrow')
  return
end

currP = get(findobj(dfig,'type','axes'),'CurrentPoint') ;
xp = currP(1,1) ;  
yp = currP(1,2) ;


nwx = UD.nwx ; nwy = UD.nwy ; nwz = UD.nwz ;
scvdims = UD.scvdims ;

sflag = 0 ;
if xp > 0.5 && xp < nwx+nwz+0.5 && yp > 0.5 && yp < nwy+nwz+0.5
  if xp > nwx+0.5 && yp < nwy+0.5 % top RH sector (YZ)
    xc = UD.coord(X) ;
    yc = round((yp-0.5)/scvdims(Y) + 0.5) ; 
    zc = round(((xp-nwx)-0.5)/scvdims(Z) + 0.5) ; 
    
    sflag = 1 ;
  elseif xp<nwx+0.5 && yp<nwy+0.5 % top LH sector (XY)
    xc = round((xp-0.5)/scvdims(X) + 0.5) ;
    yc = round((yp-0.5)/scvdims(Y) + 0.5) ;
    zc = UD.coord(Z) ;
    sflag = 1 ;
  elseif xp<nwx+0.5 && yp>nwy+0.5 % bottom LH sector (XZ)
    xc =  round((xp-0.5)/scvdims(X) + 0.5) ; 
    yc = UD.coord(Y) ;
    zc = round(((yp-nwy)-0.5)/scvdims(Z) + 0.5) ; 
    sflag = 1 ;
  end

end

if sflag == 1
  set(dfig,'Pointer',pointer)
  xs = num2str(xc) ;
  ys = num2str(yc) ;
  zs = num2str(zc) ;  
  dat = UD.dat ;
  vc = dat(yc,xc,zc) ;
  switch UD.dtype
    case 'modulus'
      vs = num2str(abs(vc)) ;
    case 'real'
      vs = num2str(real(vc)) ;
    case 'imaginary'
      vs = num2str(imag(vc)) ;
    case 'phase'
      vs = num2str(angle(vc)) ;
    case 'rgb'
        if ndims(dat)==4
            rcol = dat(yc,xc,zc,:) ;
        else
            rcol = dat(yc,xc,:) ;
        end
      vs = [num2str(rcol(1),'%4.2f'),' ',num2str(rcol(2),'%4.2f'), ...
          ' ',num2str(rcol(3),'%4.2f')];
  end
  
  % update dynamic plot
  if UD.dplot
        switch UD.dtype
            case 'modulus'
              dp = abs(dat(yc,xc,:)) ;
            case 'real'
              dp = real(dat(yc,xc,:)) ;
            case 'imaginary'
              dp = imag(dat(yc,xc,:)) ;
            case 'phase'
              dp = angle(dat(yc,xc,:)) ; 
            case 'rgb'
              % cannot plot rgb curve
        end
         
        currfh = gcf ;
        figure(UD.dpfh) ; 
        ylabel(UD.dtype)
        xlabel('3rd dim index')
        
        hp = plot(squeeze(dp)) ;
        legend(['(',ys,', ',xs,')'])
        
        figure(currfh) ;
        drawnow
        set(dfig,'UserData', UD) 
  end % end dplot
else
  set(dfig,'Pointer','arrow')
  xs = ' ' ; ys = ' ' ; zs = ' ' ; vs = ' ' ;
end

set(hcfig.text20,'String',xs)
set(hcfig.text21,'String',ys)
set(hcfig.text22,'String',zs)
set(hcfig.text23,'String',vs)


%-------------------------------------------
function keyp
% KEYP (dshow)

dfig = gcbf ;
UD = get(dfig,'UserData') ;
handles = guihandles(UD.cfig) ;
if verLessThan('matlab','8.4.0')
    dfig_number = dfig ;
else
    dfig_number = dfig.Number ;
end

dfig_name = get(dfig,'Name') ;

if str2num(get(handles.edit1,'String'))~=dfig_number
    set(dfig,'Pointer','arrow')
    return
end
        

X = 2; Y =1 ; Z = 3 ;
currc = get(dfig,'CurrentCharacter') ;
switch currc
    case '?'
        helptxt = { 'r re-slice', ...
            'up/down arrows to change slice', ...
            '1 2 3  set points to define a plane', ...
            'p plane display', ...
            'n normal plane', ...
            'c cross-section with normal P1-P2, centred at P3', ...
            'l lock toggle for window contrast',...
            'm montage',...
            'v movie',...
            't time plot (use r first)'} ;
        helpdlg(helptxt,'eshow help')
        
    case char(30) % up arrow
        UD.coord(Z) = str2num(get(handles.text22,'String')) ;
        UD.coord(Z) = max(1,UD.coord(Z) -1) ;
        UD = fig_draw(dfig,UD) ;
        set(dfig,'UserData',UD)
        set(handles.slider3,'Value',UD.coord(Z))
        set(handles.edit7,'String',num2str(UD.coord(Z)))
        set(handles.text22,'String',num2str(UD.coord(Z)))
    case char(31) % down arrow
        UD.coord(Z) = str2num(get(handles.text22,'String')) ;
        UD.coord(Z) = min(size(UD.dat,3),UD.coord(Z) + 1) ;
        UD = fig_draw(dfig,UD) ;
        set(dfig,'UserData',UD)
        set(handles.slider3,'Value',UD.coord(Z))
        set(handles.edit7,'String',num2str(UD.coord(Z)))
        set(handles.text22,'String',num2str(UD.coord(Z)))
    case {'t','T'}
        cX = str2num(get(handles.edit5,'String')) ;
        cY = str2num(get(handles.edit6,'String')) ;
        figure('Name',['Profile from Fig ',num2str(dfig_number),' at (',...
            num2str(cX),', ',num2str(cY),')'])
        switch UD.dtype
            case 'modulus'
                dw = abs(UD.dat) ;
            case 'real'
                dw = real(UD.dat) ;
            case 'phase'
                dw = angle(UD.dat) ;
            case 'imaginary'
                dw = imag(UD.dat) ;
            case 'rgb'
                dw = UD.dat ;
        end
        plot(squeeze(dw(cY,cX,:,:)))
    case {'d','D'} % interactive dynamic plot
        if UD.dplot % toggle dplot
            UD.dplot = false ;
        else
            UD.dplot = true ;
        end
        
        if UD.dplot
            dpfh = figure('Name',['Dynamic profiles from Fig ',num2str(dfig_number)]) ;
            UD.dpfh = dpfh ; % store handle
            
            grid on
        end
        set(dfig,'UserData',UD)
        %plotting is in the motion function
    case {'f','F'}
        currf = gcf ;
        if isempty(UD.hheld)
            hheld = figure('Name',['Dynamic plots']) ;
            hold on , grid on
            UD.hheld = hheld ;
        end
        xc = str2num(get(handles.text20,'String')) ;
        yc = str2num(get(handles.text21,'String')) ;
        
        dat = UD.dat ;
        switch UD.dtype
            case 'modulus'
              dp = abs(dat(yc,xc,:)) ;
            case 'real'
              dp = real(dat(yc,xc,:)) ;
            case 'imaginary'
              dp = imag(dat(yc,xc,:)) ;
            case 'phase'
              dp = angle(dat(yc,xc,:)) ; 
            case 'rgb'
              % cannot plot rgb curve
        end
        figure(UD.hheld)
        plot(squeeze(dp))
        figure(currf)
        set(dfig,'UserData',UD)
        
  case { 'R','r'}
    UD.coord(X) = str2num(get(handles.text20,'String')) ;
    UD.coord(Y) = str2num(get(handles.text21,'String')) ;
    UD.coord(Z) = str2num(get(handles.text22,'String')) ;
     
    UD = fig_draw(dfig,UD) ;
    set(dfig,'UserData',UD)
    set(handles.slider1,'Value',UD.coord(X)) 
    set(handles.slider2,'Value',UD.coord(Y))
    set(handles.slider3,'Value',UD.coord(Z))
  
    set(handles.edit5,'String',num2str(UD.coord(X)))
    set(handles.edit6,'String',num2str(UD.coord(Y)))
    set(handles.edit7,'String',num2str(UD.coord(Z)))

  case '1'
    UD.p1 = [str2num(get(handles.text21,'String')) ...
	     str2num(get(handles.text20,'String')) ...
	     str2num(get(handles.text22,'String')) ] ;
    set(dfig,'UserData',UD)
  case '2'
    UD.p2 = [str2num(get(handles.text21,'String')) ...
	     str2num(get(handles.text20,'String')) ...
	     str2num(get(handles.text22,'String')) ] ;
    set(dfig,'UserData',UD)
  case '3'
    UD.p3 = [str2num(get(handles.text21,'String')) ...
	     str2num(get(handles.text20,'String')) ...
	     str2num(get(handles.text22,'String')) ] ;
    set(dfig,'UserData',UD)
    
 case 'p' % 3 point plane
  % UD.p1 etc contain the value of the coord string when key press,
  % convert from pixel number to mm
    p1 = (UD.p1 -0.5) .*UD.scvdims + 0.5 ;
    p2 = (UD.p2 -0.5) .*UD.scvdims + 0.5 ;
    p3 = (UD.p3 -0.5) .*UD.scvdims + 0.5 ;
     
    pcent = p1 ;
    plane.points = [p1 ; p2 ; p3] ;
    disp([' Plane points: ',num2str([ p1 ]) ])
    disp(['               ',num2str([ p2 ]) ])
    disp(['               ',num2str([ p3 ]) ])
    
    
    plane_show(pcent, plane, UD) 
    
 case 'c' % Cross-section plane
  % UD.p1 etc contain the value of the coord string when key press,
  % convert from pixel number to mm
    p1 = (UD.p1 -0.5) .*UD.scvdims + 0.5 ;
    p2 = (UD.p2 -0.5) .*UD.scvdims + 0.5 ;
    p3 = (UD.p3 -0.5) .*UD.scvdims + 0.5 ;
     
    pcent = p3 ;
    plane.normal = p2 - p1 ;
    
    plane_show(pcent, plane, UD) 
    
    case {'m','v'} % montage or movie the 3D data
        switch UD.dtype
            case 'modulus'
                dw = abs(UD.dat) ;
            case 'real'
                dw = real(UD.dat) ;
            case 'phase'
                dw = angle(UD.dat) ;
            case 'imaginary'
                dw = imag(UD.dat) ;
            case 'rgb'
                dw = UD.dat ;
        end
        
        aw = mat2gray(dw, [double(UD.dspmin) double(UD.dspmax)]) ;
        [ny nx nz nc] = size(aw) ;
        if UD.isrgb && nc==1
            nz = 1 ; nc = 3 ;
        end
	
	if ~islogical(aw) 
        if ~UD.isrgb
          for iw = 1:nz
	        aw(:,:,iw) = imadjust(aw(:,:,iw),[],[],UD.gamma) ;
          end
        else
            aw = aw.^UD.gamma ;
        end
	end
	
    hf=figure('name',['derived from fig ', num2str(dfig_number),'  ',dfig_name]) ;
    set(gcf,'Color',[0 0 0]) 
	ha = axes('Position',[0 0 1 1],'Color',[0 0 0]) ;
	
	drawnow
	iptsetpref('Imshowborder','tight')
	prefs = iptgetpref ;

	if isfield(prefs,'ImshowTruesize')
	  ts = 'ImshowTruesize' ;
          ts_val = 'manual' ;
       else
          ts = 'ImshowInitialMagnification' ;
          ts_val = 'fit' ;
        end
	iptsetpref(ts,ts_val) 
	
	switch currc
	 case 'm'
         if UD.isrgb
             aw = permute(aw,[1 2 4 3]) ;
             montage(aw)
         else
	       aw = reshape(aw,[ny nx 1 nz]) ;
	       montage(aw)
         end
	 case 'v'
	  sf = min([ floor(600/ny) floor(800/nx)]);
	  if verLessThan('matlab','8.4.0')
          aw = flip(aw,1) ; % dont' understand why, but otherwise movie is upside down
      end
      if UD.isrgb
          for iw = 1:nz
              iim = imresize(squeeze(aw(:,:,iw,:)),sf*[ny nx]) ;
              iim(find(iim>1))=1;
              iim(find(iim<0))=0;
              M(iw) = im2frame(iim) ;
          end
      else
        for iw = 1:nz
          % seems that imresize can push value over 1, hence another
          % mat2gray
	    [iim,map] = gray2ind(mat2gray(imresize(aw(:,:,iw),sf*[ny nx]))) ;
        
	      M(iw) = im2frame(iim, map) ;
        end
      end
	  
      [h,w] = size(M(1).cdata) ;
      set(hf,'Position',[150 150 w h]);
	  movie(hf, M,20,6,[0 0 0 0])
  end
	
  case {'l','L'}  % Lock display ranges
    UD.lock = UD.lock *-1 ;
    set(dfig,'UserData',UD)
    case {'k'} % mIP
       disp('mIP code here')
        
    
   case 'n'   % Plane is defined by P1 P2 and the normal to
              % the current plane
    p1 = (UD.p1 -0.5) .*UD.scvdims + 0.5 ;
    p2 = (UD.p2 -0.5) .*UD.scvdims + 0.5 ;
    
   
    currP = get(findobj(dfig,'type','axes'),'CurrentPoint') ;
    xp = currP(1,1) ;  
    yp = currP(1,2) ;

    nwx = UD.nwx ; nwy = UD.nwy ; nwz = UD.nwz ;

    sflag = 0 ;
    if xp > 0.5 && xp < nwx+nwz+0.5 && yp > 0.5 && yp < nwy+nwz+0.5
      if xp > nwx+0.5 & yp < nwy+0.5 % top RH sector (YZ)
        plane.v2u = [0 1 0] ;
	sflag = 1 ;
      elseif xp<nwx+0.5 & yp<nwy+0.5 % top LH sector (XY)
        plane.v2u = [0 0 1] ;
	sflag = 1 ;
      elseif xp<nwx+0.5 & yp>nwy+0.5 % bottom LH sector (XZ)
        plane.v2u = [1 0 0] ;
	sflag = 1 ;
      end
    end
    
    if sflag ==1
      plane.v1u = p1-p2;
      plane_show(p1, plane, UD)
    end
    
end


%--------------------------------------------------------
function plane_show(pcent, plane,UD)
% PLANE_SHOW (dshow)

X = 2; Y = 1; Z = 3;

plane = plane_process(plane) ;  % generates normal
plann.normal = plane.normal ;
planorth = plane_process(plann) ; % generates perp v1u and v2u
    
mindim = min(UD.scvdims) ;
maxn = max(size(UD.dat)) ;
    
xp = [-maxn:maxn]*mindim ;
yp = [-maxn:maxn]*mindim ;
    
[XG,YG] = meshgrid(xp, yp) ;
[py px] = size(XG) ;
    
XG = XG(:) ;
YG = YG(:) ;
    
planec = repmat(pcent,[py*px 1]) + XG*planorth.v1u + YG*planorth.v2u ;
    
clear XG YG
    
    
[XV, YV, ZV] = meshgrid([1:size(UD.dat,X)]*UD.scvdims(X) , ...
	                [1:size(UD.dat,Y)]*UD.scvdims(Y) , ...
			[1:size(UD.dat,Z)]*UD.scvdims(Z)) ;
    
planev = interp3(XV, YV, ZV, UD.dat, planec(:,X), planec(:,Y), ...
	              planec(:,Z),'cubic') ;
     
planev = NaN2zero(planev) ;
     
eshow(reshape(planev,[py px])) 


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4

val = get(hObject,'Value') ;
str = get(hObject,'String') ;

fig = sscanf(str{val},'Fig: %d%s') ;
set(handles.edit1,'String',num2str(fig(1))) ;

eshow('edit1_Callback', handles.edit1, eventdata, handles)






% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of
%        edit1 as a double

% copied from old edit1, (was edit9)

Y=1; X=2; Z=3;

figstr = get(hObject,'String') ;
fig = str2num(figstr) ;

set(fig,'WindowButtonMotionFcn','eshow(''motion'')') ;
set(fig,'KeyPressFcn','eshow(''keyp'')') ;

UD = get(fig, 'UserData') ;
UD = dat_up(handles,UD) ;
UD = fig_draw(fig,UD) ;

% update the control figure
[ny nx nz nc] = size(UD.dat) ;
if UD.isrgb && nc ==1
    nz = 1 ;
end
if nx > 1
  set(handles.slider1,'Max',nx,'SliderStep',[1/(nx-1) max(0.1,1/(nx-1)) ],'Value', ...
		    UD.coord(X)) 
  set(handles.slider1,'Visible','on')
else
  set(handles.slider1,'Visible','off')
end

if ny > 1
  set(handles.slider2,'Max',ny,'SliderStep',[1/(ny-1) max(0.1,1/(ny-1)) ],'Value',UD.coord(Y))
  set(handles.slider2,'Visible','on')
else
  set(handles.slider2,'Visible','off')
end

if nz > 1
  set(handles.slider3,'Max',nz,'SliderStep',[1/(nz-1) max(0.1,1/(nz-1)) ],'Value',UD.coord(Z))
  set(handles.slider3,'Visible','on')
else
  set(handles.slider3,'Visible','off')
end


set(handles.edit5,'String',num2str(UD.coord(X)))
set(handles.edit6,'String',num2str(UD.coord(Y)))
set(handles.edit7,'String',num2str(UD.coord(Z)))

set(handles.popupmenu1,'Value',UD.pop1)
set(handles.popupmenu2,'Value',UD.pop2)
%set(handles.popupmenu3,'Value',UD.pop3)


%hfigs = findobj(0,'Tag','eshowfig') ;
hfigs = findobj(groot,'Tag','eshowfig') ;

if length(hfigs)==0
	warning(' There are no eshow figs open')
end

hfigs_num = zeros(size(hfigs)) ;

for ifig = 1:length(hfigs)
  name = get(hfigs(ifig),'Name') ;
  if verLessThan('matlab','8.4.0')
      hfigs_num(ifig) = hfigs(ifig) ;
  else
      hfigs_num(ifig) = hfigs(ifig).Number ;
  end 
  st{ifig} = ['Fig: ',num2str(hfigs_num(ifig)),' ',name];
end

set(handles.popupmenu4,'String',st) ;
val = find(hfigs_num==fig) ;
set(handles.popupmenu4,'value',val) ;



% --- Executes on button press in pushbutton_openimcontrast.
function pushbutton_openimcontrast_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_openimcontrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fig = str2num(get(handles.edit1,'String')) ;
imcontrast(fig)


% --- Executes on button press in pushbutton_imcontrastmaxmin.
function pushbutton_imcontrastmaxmin_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_imcontrastmaxmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fig = str2num(get(handles.edit1,'String')) ;
UD = get(fig,'UserData') ;
figure(fig)

CLim = get(gca,'CLim') ;
set(handles.edit2,'String',num2str(CLim(2))) 
set(handles.edit3,'String',num2str(CLim(1)))
UD.dspmin = CLim(1) ;
UD.dspmax = CLim(2) ;
set(fig,'UserData',UD)
fig_draw(fig,UD) ;

