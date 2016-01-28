function varargout = surface_options(varargin)
% Helper window to surface options

%	Copyright (c) 2004-2013 by J. Luis
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
% --------------------------------------------------------------------

% $Id: surface_options.m 3896 2013-03-06 23:18:01Z j $

hObject = figure('Tag','figure1','Visible','off');
surface_options_LayoutFcn(hObject);
handles = guihandles(hObject);
move2side(hObject,'right')
 
handles.command = cell(30,1);

if ~isempty(varargin)
    old_cmd = varargin{1};
end

if ~isempty(old_cmd)        % Decode old command and initialize corresponding boxes
    [tok,rem] = strtok(varargin{1});
    tmp{1} = tok;         i = 2;
    while (rem)
        [tok,rem] = strtok(rem);
        tmp{i} = tok;     i = i + 1;
    end
    for i=1:length(tmp)
        switch tmp{i}(2)
            case 'A'
                handles.command{5} = [' ' tmp{i}];
                set(handles.edit_aspect,'String',tmp{i}(3:end))
            case 'C'
                handles.command{7} = [' ' tmp{i}];
                set(handles.edit_convergence,'String',tmp{i}(3:end))
            case 'L'
                if ( strcmp(tmp{i}(3),'l') )
                    handles.command{9} = [' ' tmp{i}];
                    set(handles.edit_lowerLim,'String',tmp{i}(4:end))
                elseif ( strcmp(tmp{i}(3),'u') )
                    handles.command{11} = [' ' tmp{i}];
                    set(handles.edit_upperLim,'String',tmp{i}(4:end))
                end
            case 'N'
                handles.command{13} = [' ' tmp{i}];
                set(handles.edit_MaxIterations,'String',tmp{i}(3:end))
            case 'S'
                handles.command{17} = [' ' tmp{i}];
                set(handles.edit_SearchRadius,'String',tmp{i}(3:end))
            case 'T'
                if ( strcmp(tmp{i}(end),'i') )
                    handles.command{19} = [' ' tmp{i}];
                    set(handles.edit_InternalTension,'String',tmp{i}(3:end-1))
                elseif ( strcmp(tmp{i}(end),'b') )
                    handles.command{21} = [' ' tmp{i}];
                    set(handles.edit_BoundTension,'String',tmp{i}(3:end-1))
                end
            case 'Z'
                handles.command{23} = [' ' tmp{i}];
                set(handles.edit_OverRelaxation,'String',tmp{i}(3:end))
        end
    end
    set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
end

handles.output = hObject;
guidata(hObject, handles);
set(hObject,'Visible','on');

% UIWAIT makes surface_options wait for user response (see UIRESUME)
uiwait(handles.figure1);
handles = guidata(hObject);
varargout{1} = handles.output;
delete(handles.figure1);

function edit_aspect_CB(hObject, handles)
	handles.command{5} = [' -A' get(hObject,'String')];
	set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
	guidata(hObject, handles);

function push_help_A_CB(hObject, handles)
message = {'Aspect ratio. If desired, grid anisotropy can be added to the equations.'
           'Enter aspect_ratio, where dy = dx / aspect_ratio relates the grid'
           'dimensions. [Default = 1 assumes isotropic grid.]'};
helpdlg(message,'Help -A option');

function edit_convergence_CB(hObject, handles)
	handles.command{7} = [' -C' get(hObject,'String')];
	set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
	guidata(hObject, handles);

function push_help_C_CB(hObject, handles)
message = {'Convergence limit. Iteration is assumed to have converged when the'
           'maximum absolute change in any grid value is less than convergence_limit.'
           '(Units same as data z units). [Default is scaled to 0.1 percent of typical'
           'gradient in input data.]'};
helpdlg(message,'Help -C option');

function edit_lowerLim_CB(hObject, handles)
handles.command{9} = [' -Ll' get(hObject,'String')];
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);
      
function push_help_Ll_CB(hObject, handles)
message = {'Impose limits on the output solution. lower sets the lower bound.'
           'lower can be the name of a grdfile with lower bound values, a fixed'
           'value, d to set to minimum input value, or u for unconstrained [Default].'};
helpdlg(message,'Help -Ll option');

function edit_upperLim_CB(hObject, handles)
handles.command{11} = [' -Lu' get(hObject,'String')];
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_Lu_CB(hObject, handles)
message = {'Impose limits on the output solution. upper sets the upper bound.'
           'upper can be the name of a grdfile with upper bound values, a fixed'
           'value, d to set to minimum input value, or u for unconstrained [Default].'};
helpdlg(message,'Help -Lu option');

function edit_MaxIterations_CB(hObject, handles)
handles.command{13} = [' -N' get(hObject,'String')];
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_N_CB(hObject, handles)
message = {'Number of iterations. Iteration will cease when convergence_limit is'
            'reached or when number of iterations reaches max_iterations. [Default is 250.]'};
helpdlg(message,'Help -N option');

function checkbox_SuggestGridDim_CB(hObject, handles)
tmp = get(hObject,'Value');
if tmp
    handles.command{15} = ' -Q';
else
    handles.command{15} = '';
end
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_Q_CB(hObject, handles)
message = {'Suggest grid dimensions which have a highly composite greatest common'
           'factor. This allows surface to use several intermediate steps in the'
           'solution, yielding faster run times and better results. The sizes suggested'
           'by -Q can be achieved by altering -R and/or -I. You can recover the -R and'
           ' -I you want later by using grdsample or grdcut on the output of surface.'};
helpdlg(message,'Help -Q option');

function edit_SearchRadius_CB(hObject, handles)
handles.command{17} = [' -S' get(hObject,'String')];
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_S_CB(hObject, handles)
message = {'Search radius. Enter search_radius in same units as x,y data; append m to'
           'indicate minutes. This is used to initialize the grid before the first'
           'iteration; it is not worth the time unless the grid lattice is prime and'
           'cannot have regional stages. [Default = 0.0 and no search is made.]'};
helpdlg(message,'Help -S option');

function edit_InternalTension_CB(hObject, handles)
xx = get(hObject,'String');
if isnan(str2double(xx))        % If nonsense
    set(hObject,'String','0');  handles.command{19} = '';
    set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
    guidata(hObject, handles);
    return
end
if str2double(xx) < 0
    handles.command{19} = '';    set(hObject,'String','0')
elseif str2double(xx) > 1
    handles.command{19} = ' -T1i';    set(hObject,'String','1')
else
    handles.command{19} = [' -T' get(hObject,'String') 'i'];
end
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function edit_BoundTension_CB(hObject, handles)
xx = get(hObject,'String');
if isnan(str2double(xx))        % If nonsense
    set(hObject,'String','0');  handles.command{21} = '';
    set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
    guidata(hObject, handles);
    return
end
if str2double(xx) < 0
    handles.command{21} = '';    set(hObject,'String','0')
elseif str2double(xx) > 1
    handles.command{21} = ' -T1b';    set(hObject,'String','1')
else
    handles.command{21} = [' -T' get(hObject,'String') 'b'];
end
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_T_CB(hObject, handles)
message = {'Tension factor[s]. These must be between 0 and 1. Tension may be used in'
           'the interior solution (where it suppresses spurious oscillations)'
           'and in the boundary conditions (where it tends to flatten'
           'the solution approaching the edges). Using zero for both values results'
           'in a minimum curvature surface with free edges, i.e. a natural bicubic'
           'spline. Use -Ttension_factori to set interior tension, and -Ttension_factorb'
           'to set boundary tension. If you do not append i or b, both will be set to'
           'the same value. [Default = 0 for both gives minimum curvature solution.]'};
helpdlg(message,'Help -T option');

function edit_OverRelaxation_CB(hObject, handles)
handles.command{23} = [' -Z' get(hObject,'String')];
set(handles.edit_ShowCommand, 'String', [handles.command{5:end}]);
guidata(hObject, handles);

function push_help_Z_CB(hObject, handles)
message = {'Over-relaxation factor. This parameter is used to accelerate the'
           'convergence; it is a number between 1 and 2. A value of 1 iterates'
           'the equations exactly, and will always assure stable convergence.'
           'Larger values overestimate the incremental changes during convergence,'
           'and will reach a solution more rapidly but may become unstable.'
           'If you use a large value for this factor, it is a good idea to monitor'
           'each iteration with the -Vl option. [Default = 1.4 converges quickly'
           'and is almost always stable.]'};
helpdlg(message,'Help -Z option');

function push_Cancel_CB(hObject, handles)
	handles.output = '';        % User gave up, return nothing
	guidata(hObject, handles);
	uiresume(handles.figure1);

function push_OK_CB(hObject, handles)
	handles.output = get(handles.edit_ShowCommand, 'String');
	guidata(hObject,handles)
	uiresume(handles.figure1);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, evt)
	handles = guidata(hObject);
	if (exist('OCTAVE_VERSION','builtin'))		% To know if we are running under Octave
		do_uiresume = ( isprop(hObject, '__uiwait_state__') && strcmp(get(hObject, '__uiwait_state__'), 'active') );
	else
		do_uiresume = strcmp(get(hObject, 'waitstatus'), 'waiting');
	end
	if (do_uiresume)		% The GUI is still in UIWAIT, us UIRESUME
		handles.output = [];		% User gave up, return nothing
		guidata(hObject, handles);	uiresume(hObject);
	else					% The GUI is no longer waiting, just close it
		delete(handles.figure1);
	end

% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, evt)
% Check for "escape"
	handles = guidata(hObject);
	if isequal(get(hObject,'CurrentKey'),'escape')
		handles.output = '';    % User said no by hitting escape
		guidata(hObject, handles);
		uiresume(handles.figure1);
	end

% --- Creates and returns a handle to the GUI figure. 
function surface_options_LayoutFcn(h1)

set(h1,'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'KeyPressFcn',@figure1_KeyPressFcn,...
'CloseRequestFcn',@figure1_CloseRequestFcn,...
'MenuBar','none',...
'Name','surface_options',...
'NumberTitle','off',...
'Position',[266 266 237 344],...
'RendererMode','manual',...
'Resize','off',...
'Tag','figure1');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_aspect_CB'},...
'HorizontalAlignment','left',...
'Position',[10 317 47 21],...
'String','1',...
'Style','edit',...
'Tag','edit_aspect');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 319 65 16],...
'String','Aspect ratio',...
'Style','text',...
'Tag','text_AspectRatio');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_convergence_CB'},...
'HorizontalAlignment','left',...
'Position',[10 291 47 21],...
'Style','edit',...
'Tag','edit_convergence');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 293 90 16],...
'String','Convergence limit',...
'Style','text',...
'Tag','text_ConvLimit');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_lowerLim_CB'},...
'HorizontalAlignment','left',...
'Position',[10 266 47 21],...
'Style','edit',...
'Tag','edit_lowerLim');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 268 50 16],...
'String','Lower limit',...
'Style','text',...
'Tag','text_LowerLimit');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_upperLim_CB'},...
'HorizontalAlignment','left',...
'Position',[10 240 47 21],...
'Style','edit',...
'Tag','edit_upperLim');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 243 50 16],...
'String','Upper limit',...
'Style','text',...
'Tag','text_UpperLimit');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_MaxIterations_CB'},...
'HorizontalAlignment','left',...
'Position',[10 214 47 21],...
'String','250',...
'Style','edit',...
'Tag','edit_MaxIterations');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 216 75 16],...
'String','Max iterations',...
'Style','text',...
'Tag','text_MaxIterations');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'checkbox_SuggestGridDim_CB'},...
'Position',[10 192 135 21],...
'String','Suggest grid dimensions',...
'Style','checkbox',...
'Tag','checkbox_SuggestGridDim');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_SearchRadius_CB'},...
'HorizontalAlignment','left',...
'Position',[10 172 47 21],...
'String','0.0',...
'Style','edit',...
'Tag','edit_SearchRadius');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 173 75 16],...
'String','Search radius',...
'Style','text',...
'Tag','text_SearchRad');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_InternalTension_CB'},...
'HorizontalAlignment','left',...
'Position',[10 147 47 21],...
'String','0',...
'Style','edit',...
'Tag','edit_InternalTension');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_BoundTension_CB'},...
'HorizontalAlignment','left',...
'Position',[10 119 47 21],...
'String','0',...
'Style','edit',...
'Tag','edit_BoundTension');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 122 88 15],...
'String','Boundary Tension',...
'Style','text',...
'Tag','text_Tension');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',{@surface_options_uiCB,h1,'edit_OverRelaxation_CB'},...
'HorizontalAlignment','left',...
'Position',[10 93 47 21],...
'String','1.4',...
'Style','edit',...
'Tag','edit_OverRelaxation');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 95 84 16],...
'String','Relaxation Factor',...
'Style','text',...
'Tag','text_OverRelaxation');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Enable','inactive',...
'Position',[10 66 91 22],...
'String','-f (inactive)',...
'Style','popupmenu',...
'Value',1,...
'Tag','popup_FormatInput');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 319 15 16],...
'String','-A',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 294 15 16],...
'String','-C',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 266 25 21],...
'String','-Ll',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 241 25 21],...
'String','-Lu',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 218 15 16],...
'String','-N',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 194 15 16],...
'String','-Q',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 174 15 16],...
'String','-S',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[167 136 15 17],...
'String','-T',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[168 96 15 16],...
'String','-Z',...
'Style','text');

uicontrol('Parent',h1,...
'FontSize',10,...
'FontWeight','bold',...
'HorizontalAlignment','left',...
'Position',[166 66 25 21],...
'String','-f',...
'Style','text');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'HorizontalAlignment','left',...
'Position',[10 36 220 21],...
'Style','edit',...
'Tag','edit_ShowCommand');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_Cancel_CB'},...
'Position',[92 6 66 23],...
'String','Cancel',...
'Tag','push_Cancel');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_OK_CB'},...
'Position',[166 6 65 23],...
'String','OK',...
'Tag','push_OK');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_A_CB'},...
'Position',[201 320 30 18],...
'String','Help',...
'Tag','push_help_A');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_C_CB'},...
'Position',[201 294 30 18],...
'String','Help',...
'Tag','push_help_C');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_Ll_CB'},...
'Position',[201 268 30 18],...
'String','Help',...
'Tag','push_help_Ll');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_Lu_CB'},...
'Position',[201 242 30 18],...
'String','Help',...
'Tag','push_help_Lu');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_N_CB'},...
'Position',[201 217 30 18],...
'String','Help',...
'Tag','push_help_N');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_Q_CB'},...
'Position',[201 195 30 18],...
'String','Help',...
'Tag','push_help_Q');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_S_CB'},...
'Position',[201 174 30 18],...
'String','Help',...
'Tag','push_help_S');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_T_CB'},...
'Position',[201 136 30 18],...
'String','Help',...
'Tag','push_help_T');

uicontrol('Parent',h1,...
'Call',{@surface_options_uiCB,h1,'push_help_Z_CB'},...
'Position',[201 95 30 18],...
'String','Help',...
'Tag','push_help_Z');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[62 150 88 15],...
'String','Internal Tension',...
'Style','text');

function surface_options_uiCB(hObject, eventdata, h1, callback_name)
% This function is executed by the callback and than the handles is allways updated.
	feval(callback_name,hObject,guidata(h1));
