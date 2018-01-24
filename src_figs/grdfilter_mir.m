function varargout = grdfilter_mir(varargin)
% Helper window to select filtering parameters to be sent to grdfilter_m MEX

%	Copyright (c) 2004-2018 by J. Luis
%
% 	This program is part of Mirone and is free software; you can redistribute
% 	it and/or modify it under the terms of the GNU Lesser General Public
% 	License as published by the Free Software Foundation; either
% 	version 2.1 of the License, or any later version.
% 
% 	This program is distributed in the hope that it will be useful,
% 	but WITHOUT ANY WARRANTY; without even the implied warranty of
% 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% 	Lesser General Public License for more details.
%
%	Contact info: w3.ualg.pt/~jluis/mirone
% ------------------------------------------------------------------------

% $Id: grdfilter_mir.m 10217 2018-01-24 21:33:46Z j $

	if isempty(varargin)
        errordlg('GRDFILTER: wrong number of arguments.','Error'),		return
	end
	
	handMir = varargin{1};
	
	if (handMir.no_file)
		errordlg('GRDFILTER: You didn''t even load a file. What are you expecting then?','ERROR')
		return
	end
	if (~handMir.validGrid)
		errordlg('GRDFILTER: This operation is deffined only for images derived from DEM grids.','ERROR')
		return
	end
 
	hObject = figure('Vis','off');
	grdfilter_mir_LayoutFcn(hObject);
	handles = guihandles(hObject);
	move2side(handMir.figure1, hObject)

	handles.Z = getappdata(handMir.figure1,'dem_z');

	if (isempty(handles.Z))
        errordlg('GRDFILTER: Grid was not saved in memory. Increase "Grid max size" and start over.','ERROR')
        delete(hObject);    return
	end

	if (handMir.have_nans)
		set(handles.checkbox_NaNs,'Vis','on','Val',1)
	end
	
	handles.command = cell(5,1);
	handles.command{1} = '-Fb';
	if (handMir.geog)
		handles.command{4} = '-D1';
		set(handles.popup_Option_D,'Value',2)
	else
		handles.command{4} = '-D0';
	end

	handles.x_min = [];             handles.x_max = [];
	handles.y_min = [];             handles.y_max = [];
	handles.x_inc = [];             handles.y_inc = [];
	handles.dms_xinc = 0;           handles.dms_yinc = 0;

	%-----------
	% Fill in the grid limits boxes with calling fig values and save some limiting value
	head = handMir.head;
	set(handles.edit_x_min,'String',sprintf('%.8g',head(1)))
	set(handles.edit_x_max,'String',sprintf('%.8g',head(2)))
	set(handles.edit_y_min,'String',sprintf('%.8g',head(3)))
	set(handles.edit_y_max,'String',sprintf('%.8g',head(4)))
	handles.x_min = head(1);            handles.x_max = head(2);
	handles.y_min = head(3);            handles.y_max = head(4);
	handles.x_min_or = head(1);         handles.x_max_or = head(2);
	handles.y_min_or = head(3);         handles.y_max_or = head(4);
	handles.head = head;
	[m,n] = size(handles.Z);
	handles.nr_or = m;                  handles.nc_or = n;
	handles.one_or_zero = ~head(7);
    handles.path_data = handMir.path_data;  % For the about_box()
    handles.hMirFig = handMir.figure1;

	% Fill in the x,y_inc and nrow,ncol boxes
	set(handles.edit_Nrows,'String',sprintf('%d',handles.nr_or))
	set(handles.edit_Ncols,'String',sprintf('%d',handles.nc_or))
	set(handles.edit_y_inc,'String',sprintf('%.12g',head(9)))
	set(handles.edit_x_inc,'String',sprintf('%.12g',head(8)))
	handles.x_inc = head(8);        handles.y_inc = head(9);
	handles.x_inc_or = head(8);     handles.y_inc_or = head(9);

	%----------- Give a Pro look (3D) to the frame box  ---------
	new_frame3D(hObject, handles.text8, handles.frame1)
	
	guidata(hObject, handles);
	
	set(hObject,'Visible','on');
	if (nargout),   varargout{1} = hObject;     end

	% Add this figure handle to the carra�as list
	plugedWin = getappdata(handMir.figure1,'dependentFigs');
	plugedWin = [plugedWin hObject];
	setappdata(handMir.figure1,'dependentFigs',plugedWin);

% -------------------------------------------------------------------------------------
function edit_x_min_CB(hObject, handles)
	dim_funs('xMin', hObject, handles)

% -------------------------------------------------------------------------------------
function edit_x_max_CB(hObject, handles)
	dim_funs('xMax', hObject, handles)

% --------------------------------------------------------------------
function edit_y_min_CB(hObject, handles)
	dim_funs('yMin', hObject, handles)

% --------------------------------------------------------------------
function edit_y_max_CB(hObject, handles)
	dim_funs('yMax', hObject, handles)

% --------------------------------------------------------------------
function edit_x_inc_CB(hObject, handles)
	dim_funs('xInc', hObject, handles)

% --------------------------------------------------------------------
function edit_Ncols_CB(hObject, handles)
	dim_funs('nCols', hObject, handles)

% --------------------------------------------------------------------
function edit_y_inc_CB(hObject, handles)
	dim_funs('yInc', hObject, handles)

% --------------------------------------------------------------------
function edit_Nrows_CB(hObject, handles)
	dim_funs('nRows', hObject, handles)

% -------------------------------------------------------------------------------------
function pushbutton_Help_R_F_T_CB(hObject, handles)
message = {'Min and Max, of "X Direction" and "Y Direction" specify the Region of'
    'interest. To specify boundaries in degrees and minutes [and seconds],'
    'use the dd:mm[:ss.xx] format.'
    '"Spacing" sets the grid size for grid output. You may choose different'
    'spacings for X and Y. Also here you can use the dd:mm[:ss.xx] format.'
    'In "#of lines" it is offered the easyeast way of controling the grid'
    'dimensions (lines & columns).'
    '"Toggle grid registration" Toggle the node registration for the output grid so'
    'as to become the opposite of the input grid [Default gives the same registration as the input grid].'};
helpdlg(message,'Help on Grid Line Geometry');

% -------------------------------------------------------------------------------------
function popup_FilterType_CB(hObject, handles)
	val = get(hObject,'Value');		str = get(hObject, 'String');
	switch str{val};
		case 'boxcar',				handles.command{1} = '-Fb';
		case 'cosine arc',			handles.command{1} = '-Fc';
		case 'gaussian',			handles.command{1} = '-Fg';
		case 'median',				handles.command{1} = '-Fm';
		case 'maximum likelihood',	handles.command{1} = '-Fp';
	end
	guidata(hObject, handles);

% -------------------------------------------------------------------------------------
function edit_FilterWidth_CB(hObject, handles)
	xx = get(hObject,'String');
	if ~isempty(xx)    handles.command{2} = xx;
	else    handles.command{2} = []; end
	guidata(hObject,handles)

% -------------------------------------------------------------------------------------
function pushbutton_Help_FilterType_CB(hObject, handles)
	message = ['Choose one only of for boxcar, cosine arch, gaussian, median, or maximum likelihood ' ...
               'probability (a mode estimator) filter and specify full width.'];
	helpdlg(message,'Help -F option');

% -------------------------------------------------------------------------------------
function popup_Option_D_CB(hObject, handles)
	val = get(hObject,'Value');     str = get(hObject, 'String');
	switch str{val};
		case '0',        handles.command{4} = '-D0';
		case '1',        handles.command{4} = '-D1';
		case '2',        handles.command{4} = '-D2';
		case '3',        handles.command{4} = '-D3';
		case '4',        handles.command{4} = '-D4'; 
	end
	guidata(hObject, handles);

% -------------------------------------------------------------------------------------
function pushbutton_Help_Option_D_CB(hObject, handles)
message = {'Distance flag tells how grid (x,y) relates to filter width as follows:'
			' '
			'flag = 0: grid (x,y) same units as width, Cartesian distances.'
			'flag = 1: grid (x,y) in degrees, width  in  kilometers, Cartesian distances.'
			'flag  =  2:  grid (x,y) in degrees, width in km, dx scaled by cos(middle y), Cartesian distances.'
			' '
			'The above options are fastest  because  they  allow'
			'weight  matrix  to be computed only once.  The next'
			'two  options  are  slower  because  they  recompute'
			'weights for each East-West scan line.'
			' '
			'flag  =  3:  grid (x,y) in degrees, width in km, dx scaled by cosine(y), Cartesian distance calculation.'
			'flag  =  4:  grid  (x,y)  in  degrees, width in km, Spherical distance calculation.'};
helpdlg(message,'Help Distance flag');

% --------------------------------------------------------------------------------
function push_Compute_CB(hObject, handles)
	opt_R = ' ';    opt_I = ' ';
	x_min = get(handles.edit_x_min,'String');   x_max = get(handles.edit_x_max,'String');
	y_min = get(handles.edit_y_min,'String');   y_max = get(handles.edit_y_max,'String');
	if isempty(x_min) || isempty(x_max) || isempty(y_min) || isempty(y_max)
        errordlg('One or more grid limits are empty. Open your yes.','Error');    return
	end

	x_inc = get(handles.edit_x_inc,'String');   y_inc = get(handles.edit_y_inc,'String');
	if (isempty(x_inc) || isempty(y_inc))
        errordlg('One or two grid increments are empty. Open your yes.','Error');    return
	end

	nx = str2double(get(handles.edit_Ncols,'String'));
	ny = str2double(get(handles.edit_Nrows,'String'));
	if (isnan(nx) || isnan(ny))      % I think this was already tested, but ...
		errordlg('One (or two) of the grid dimensions are not valid. Do your best.','Error');   return
	end

	if isempty(handles.command{2})
		errordlg('Must specify a Filter width','Error');    return
	end

	% See if grid limits were changed
	if ( (abs(handles.x_min-handles.x_min_or) > 1e-5) || (abs(handles.x_max-handles.x_max_or) > 1e-5) || ...
            (abs(handles.y_min-handles.y_min_or) > 1e-5) || (abs(handles.y_max-handles.y_max_or) > 1e-5))
		opt_R = sprintf('-R%.12g/%.12g/%.12g/%.12g', handles.x_min, handles.x_max, handles.y_min, handles.y_max);
	end

	% See if grid increments were changed
	if ( (abs(handles.x_inc-handles.x_inc_or) > 1e-6) || (abs(handles.y_inc-handles.y_inc_or) > 1e-6) )
		opt_I = sprintf('-I%.12g/%.12g',handles.x_inc, handles.y_inc);
	end

	opt_F = [handles.command{1} handles.command{2}];
	opt_D = handles.command{4};

	set(handles.figure1,'pointer','watch')
	set(handles.hMirFig,'pointer','watch')
	head = handles.head;
	if ( strcmp(opt_R,' ') && strcmp(opt_I,' '))
		Z = c_grdfilter(handles.Z,head,opt_F,opt_D);
	elseif ( strcmp(opt_R,' ') && ~strcmp(opt_I,' '))
		[Z,head] = c_grdfilter(handles.Z,head,opt_I,opt_F,opt_D);
	elseif ( ~strcmp(opt_R,' ') && strcmp(opt_I,' '))
		[Z,head] = c_grdfilter(handles.Z,head,opt_R,opt_F,opt_D);
	else
		errordlg('Bad number of options (My fault also that didn''t guess all possible nonsenses).','Error');
		return
	end
	set(handles.figure1,'pointer','arrow')
	set(handles.hMirFig,'pointer','arrow')
	
	% Repaint NaNs. Temporary until this option is coded in the MEX file
	if ( get(handles.checkbox_NaNs,'Val') && isequal(size(handles.Z), size(Z)) )
		ind = isnan(handles.Z);
		Z(ind) = NaN;
	end

	[ny,nx] = size(Z);
	zMinMax = grdutils(Z,'-L');
	tmp.head = [head(1:4) zMinMax(1:2)' head(7:9)];
	tmp.X = linspace(head(1),head(2),nx);       tmp.Y = linspace(head(3),head(4),ny);
	tmp.name = 'Filtered grid';
	%tmp.cmap = get(handles.hMirFig, 'colormap');
	mirone(Z,tmp);
	figure(handles.figure1)         % Don't let this figure forgotten behind the newly created one

% --------------------------------------------------------------------
function Menu_Help_CB(hObject, handles)
message = ['grdfilter will filter a .grd file in the time domain using ' ...
		'a boxcar, cosine arch, gaussian, median,  or  mode  filter ' ...
		'and  computing  distances  using  Cartesian  or  Spherical ' ...
		'geometries.  The output .grd file can optionally be gener- ' ...
		'ated  as  a  sub-Region  of  the  input  and/or with a new ' ...
		'Increment. In this way, one may have "extra space" in the ' ...
		'input data so that the edges will not be used and the out- ' ...
		'put can be within one-half-width of the input  edges.  If ' ...
		'the  filter  is low-pass, then the output may be less fre- ' ...
		'quently sampled than the input.'];
helpdlg(message,'Help on grdfilter');

% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata)
	if isequal(get(hObject,'CurrentKey'),'escape')
		delete(hObject);
	end

% --- Creates and returns a handle to the GUI figure. 
function grdfilter_mir_LayoutFcn(h1)

set(h1,'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'KeyPressFcn',@figure1_KeyPressFcn,...
'MenuBar','none',...
'Name','Grdfilter',...
'NumberTitle','off',...
'Position',[267 371 411 186],...
'RendererMode','manual',...
'Resize','off',...
'Tag','figure1');

uicontrol('Parent',h1,'Position',[10 78 390 97],'Enable','inactive','Style','frame','Tag','frame1');

uicontrol('Parent',h1, 'Position',[30 168 121 15],...
'Enable','inactive',...
'String','Griding Line Geometry',...
'Style','text',...
'Tag','text8');

uicontrol('Parent',h1, 'Position',[77 136 80 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Style','edit',...
'Tag','edit_x_min');

uicontrol('Parent',h1, 'Position',[163 136 80 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Style','edit',...
'Tag','edit_x_max');

uicontrol('Parent',h1, 'Position',[77 110 80 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Style','edit',...
'Tag','edit_y_min');

uicontrol('Parent',h1, 'Position',[163 110 80 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Style','edit',...
'Tag','edit_y_max');

uicontrol('Parent',h1, 'Position',[22 140 55 15],...
'Enable','inactive',...
'HorizontalAlignment','left',...
'String','X Direction',...
'Style','text');

uicontrol('Parent',h1, 'Position',[21 114 55 15],...
'Enable','inactive',...
'HorizontalAlignment','left',...
'String','Y Direction',...
'Style','text');

uicontrol('Parent',h1, 'Position',[183 157 41 13],...
'Enable','inactive',...
'String','Max',...
'Style','text');

uicontrol('Parent',h1, 'Position',[99 157 41 13],...
'Enable','inactive',...
'String','Min',...
'Style','text');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Position',[248 136 71 21],...
'Style','edit',...
'Tooltip','DX grid spacing',...
'Tag','edit_x_inc');

uicontrol('Parent',h1, 'Position',[248 110 71 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','left',...
'Style','edit',...
'Tooltip','DY grid spacing',...
'Tag','edit_y_inc');

uicontrol('Parent',h1, 'Position',[324 136 65 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','center',...
'Style','edit',...
'Tooltip','Number of columns in the grid',...
'Tag','edit_Ncols');

uicontrol('Parent',h1, 'Position',[324 110 65 21],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','center',...
'Style','edit',...
'Tooltip','Number of rows in the grid',...
'Tag','edit_Nrows');

uicontrol('Parent',h1, 'Position',[265 159 41 13],...
'Enable','inactive',...
'String','Spacing',...
'Style','text');

uicontrol('Parent',h1, 'Position',[332 159 51 13],...
'Enable','inactive',...
'String','# of lines',...
'Style','text');

uicontrol('Parent',h1, 'Position',[327 85 61 18],...
'BackgroundColor',[0.831372559071 0.815686285496 0.7843137383461],...
'Callback',@grdfilter_mir_uiCB,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'String','?',...
'Tag','pushbutton_Help_R_F_T');

uicontrol('Parent',h1, 'Position',[20 36 122 22],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','right',...
'String',{'boxcar'; 'cosine arch'; 'gaussian'; 'median'; 'maximum likelihood'},...
'Style','popupmenu',...
'Value',1,...
'Tag','popup_FilterType');

uicontrol('Parent',h1, 'Position',[142 37 47 23],...
'BackgroundColor',[1 0.49 0.49],...
'Callback',@grdfilter_mir_uiCB,...
'HorizontalAlignment','center',...
'Style','edit',...
'Tooltip','specify filter full width',...
'Tag','edit_FilterWidth');

uicontrol('Parent',h1, 'Position',[190 36 21 23],...
'Callback',@grdfilter_mir_uiCB,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'String','?',...
'Tag','pushbutton_Help_FilterType');

uicontrol('Parent',h1, 'Position',[280 38 72 22],...
'BackgroundColor',[1 1 1],...
'Callback',@grdfilter_mir_uiCB,...
'String',{  '0'; '1'; '2'; '3'; '4' },...
'Style','popupmenu',...
'Tooltip','You better read the help availabe on box aside',...
'Value',1,...
'Tag','popup_Option_D');

uicontrol('Parent',h1, 'Position',[359 38 21 23],...
'Callback',@grdfilter_mir_uiCB,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'String','?',...
'Tag','pushbutton_Help_Option_D');

uicontrol('Parent',h1, 'Position',[20 11 90 15],...
'String','Protect NaNs',...
'Style','checkbox',...
'Vis', 'off', ...
'Tooltip','If checked do not let the soothing eat the NaNs inside the filter radius',...
'Tag','checkbox_NaNs');

uimenu('Parent',h1,...
'Callback',@grdfilter_mir_uiCB,...
'Label','Help',...
'Tag','Menu_Help');

uicontrol('Parent',h1, 'Position',[295 6 105 21],...
'Callback',@grdfilter_mir_uiCB,...
'FontWeight','bold',...
'String','Compute',...
'Tooltip','Write the command line into the script file',...
'Tag','push_Compute');

uicontrol('Parent',h1, 'Position',[53 60 47 15],...
'Enable','inactive',...
'HorizontalAlignment','left',...
'String','Filter type',...
'Style','text');

uicontrol('Parent',h1, 'Position',[144 59 53 15],...
'Enable','inactive',...
'HorizontalAlignment','left',...
'String','Filter width',...
'Style','text');

uicontrol('Parent',h1, 'Position',[283 61 63 15],...
'Enable','inactive',...
'HorizontalAlignment','left',...
'String','Distance flag',...
'Style','text');

function grdfilter_mir_uiCB(hObject, eventdata)
% This function is executed by the callback and than the handles is allways updated.
	feval([get(hObject,'Tag') '_CB'],hObject, guidata(hObject));
