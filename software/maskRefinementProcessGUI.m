function varargout = maskRefinementProcessGUI(varargin)
% MASKREFINEMENTPROCESSGUI M-file for maskRefinementProcessGUI.fig
%      MASKREFINEMENTPROCESSGUI, by itself, creates a new MASKREFINEMENTPROCESSGUI or raises the existing
%      singleton*.
%
%      H = MASKREFINEMENTPROCESSGUI returns the handle to a new MASKREFINEMENTPROCESSGUI or the handle to
%      the existing singleton*.
%
%      MASKREFINEMENTPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MASKREFINEMENTPROCESSGUI.M with the given input arguments.
%
%      MASKREFINEMENTPROCESSGUI('Property','Value',...) creates a new MASKREFINEMENTPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maskRefinementProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maskRefinementProcessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright (C) 2023, Danuser Lab - UTSouthwestern 
%
% This file is part of uSignal3DPackage.
% 
% uSignal3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% uSignal3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with uSignal3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% Edit the above text to modify the response to help maskRefinementProcessGUI

% Last Modified by GUIDE v2.5 08-Jun-2018 16:38:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @maskRefinementProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @maskRefinementProcessGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before maskRefinementProcessGUI is made visible.
function maskRefinementProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameters setup 
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

if funParams.MaskCleanUp
    if ~funParams.FillHoles
        set(handles.checkbox_fillholes, 'Value', 0)
    else
        set(handles.checkbox_fillholes, 'Value', 1)
    end
    if ~funParams.FillBoundaryHoles
        set(handles.checkbox_FillBoundaryHoles, 'Value', 0)
    else
        set(handles.checkbox_FillBoundaryHoles, 'Value', 1)
    end
    set(handles.edit_1, 'String',num2str(funParams.MinimumSize))
    set(handles.edit_2, 'String',num2str(funParams.ClosureRadius))
    set(handles.edit_3, 'String',num2str(funParams.ObjectNumber))
else
    set([handles.checkbox_cleanup handles.checkbox_fillholes], 'Value', 0);
    set(get(handles.uipanel_cleanup,'Children'),'Enable','off');
end

if funParams.EdgeRefinement
    set(handles.checkbox_edge, 'Value', 1)
    set(handles.text_para4, 'Enable', 'on');
    set(handles.text_para5, 'Enable', 'on');
    set(handles.text_para6, 'Enable', 'on');
    set(handles.edit_4, 'Enable', 'on', 'String',num2str(funParams.MaxEdgeAdjust));
    set(handles.edit_5, 'Enable', 'on', 'String',num2str(funParams.MaxEdgeGap));
    set(handles.edit_6, 'Enable', 'on', 'String',num2str(funParams.PreEdgeGrow));    
    
end
    
% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = maskRefinementProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% -------- Check user input --------

if isempty(get(handles.listbox_selectedChannels, 'String'))
   errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal') 
    return;
end

if get(handles.checkbox_cleanup, 'value')
    if isnan(str2double(get(handles.edit_1, 'String'))) ...
            || str2double(get(handles.edit_1, 'String')) < 0
        errordlg('Please provide a valid input for ''Minimus Size''.','Setting Error','modal');
        return;
    end 
    if isnan(str2double(get(handles.edit_2, 'String'))) ...
            || str2double(get(handles.edit_2, 'String')) < 0
        errordlg('Please provide a valid input for ''Closure Radius''.','Setting Error','modal');
        return;
    end
    if isnan(str2double(get(handles.edit_3, 'String'))) ...
            || str2double(get(handles.edit_3, 'String')) < 0
        errordlg('Please provide a valid input for ''Object Number''.','Setting Error','modal');
        return;
    end     
end

if get(handles.checkbox_edge, 'value')
    if isnan(str2double(get(handles.edit_4, 'String'))) ...
            || str2double(get(handles.edit_4, 'String')) < 0
        errordlg('Please provide a valid input for ''Maximum Adjust Distance''.','Setting Error','modal');
        return;
    end 
    if isnan(str2double(get(handles.edit_5, 'String'))) ...
            || str2double(get(handles.edit_5, 'String')) < 0
        errordlg('Please provide a valid input for ''Maximum Edge Gap''.','Setting Error','modal');
        return;
    end
    if isnan(str2double(get(handles.edit_6, 'String'))) ...
            || str2double(get(handles.edit_6, 'String')) < 0
        errordlg('Please provide a valid input for ''Radius of Growth''.','Setting Error','modal');
        return;
    end     
end

if ~get(handles.checkbox_cleanup, 'value') && ~get(handles.checkbox_edge, 'value')
    errordlg('Please select at least one option for mask refinement processing.')
    return;
end

% -------- Process Sanity check --------
% ( only check underlying data )

try
    userData.crtProc.sanityCheck;
catch ME

    errordlg([ME.message 'Please double check your data'],...
                'Setting Error','modal');
    return;
end

% Retrieve GUI-defined parameters
channelIndex = get (handles.listbox_selectedChannels, 'Userdata');
funParams.ChannelIndex = channelIndex;

if get(handles.checkbox_cleanup, 'Value')
    funParams.MaskCleanUp = true;
    funParams.MinimumSize = str2double(get(handles.edit_1, 'String'));
    funParams.ClosureRadius = str2double(get(handles.edit_2, 'String'));
    funParams.ObjectNumber = str2double(get(handles.edit_3, 'String'));
    if get(handles.checkbox_fillholes, 'Value')
        funParams.FillHoles = true;
    else
        funParams.FillHoles = false;
    end
    if get(handles.checkbox_FillBoundaryHoles, 'Value')
        funParams.FillBoundaryHoles = true;
    else
        funParams.FillBoundaryHoles = false;
    end
else
    funParams.MaskCleanUp = false;
end

if get(handles.checkbox_edge, 'Value')
    funParams.EdgeRefinement = true;
    funParams.MaxEdgeAdjust = str2double(get(handles.edit_4, 'String'));
    funParams.MaxEdgeGap = str2double(get(handles.edit_5, 'String'));
    funParams.PreEdgeGrow = str2double(get(handles.edit_6, 'String'));
else
    funParams.EdgeRefinement = false;
end

% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on button press in checkbox_cleanup.
function checkbox_cleanup_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_auto

if get(hObject, 'Value')
    set(get(handles.uipanel_cleanup,'Children'),'Enable','on');
else
    set(get(handles.uipanel_cleanup,'Children'),'Enable','off');
end


% --- Executes on button press in checkbox_edge.
function checkbox_edge_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_auto

if get(hObject, 'Value')
    set(get(handles.uipanel_edge,'Children'),'Enable','on');
else
    set(get(handles.uipanel_edge,'Children'),'Enable','off');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on button press in checkbox_FillBoundaryHoles.
function checkbox_FillBoundaryHoles_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_FillBoundaryHoles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_FillBoundaryHoles
