function varargout = transformationProcessGUI(varargin)
% TRANSFORMATIONPROCESSGUI M-file for transformationProcessGUI.fig
%      TRANSFORMATIONPROCESSGUI, by itself, creates a new TRANSFORMATIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = TRANSFORMATIONPROCESSGUI returns the handle to a new TRANSFORMATIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      TRANSFORMATIONPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRANSFORMATIONPROCESSGUI.M with the given input arguments.
%
%      TRANSFORMATIONPROCESSGUI('Property','Value',...) creates a new TRANSFORMATIONPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before transformationProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to transformationProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help transformationProcessGUI

% Last Modified by GUIDE v2.5 17-Oct-2011 13:39:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @transformationProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @transformationProcessGUI_OutputFcn, ...
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


% --- Executes just before transformationProcessGUI is made visible.
function transformationProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

%  Parameter Setup
funParams = userData.crtProc.funParams_;

if any(~cellfun(@isempty, funParams.TransformFilePaths))
    set(handles.listbox_transform, 'String', ...
        funParams.TransformFilePaths(funParams.ChannelIndex))
end

set(handles.checkbox_mask, 'Value', funParams.TransformMasks)

% Choose default command line output for transformationProcessGUI
handles.output = hObject;

uicontrol(handles.pushbutton_done)
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = transformationProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)

delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
userData_main = get(userData.mainFig, 'UserData');

% -------- Check user input --------

channelIndex = get (handles.listbox_selectedChannels, 'Userdata');

if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one channel as input channel.','Setting Error','modal') 
    return;
end

fileName = get(handles.listbox_transform, 'String');
if isempty(fileName)
    errordlg('Please provide a MAT-file containing the data of transformation applied to the images.','Setting Error','modal') 
    return;  

elseif length(fileName) ~= length(channelIndex) && length(fileName) ~= 1
    errordlg('Please provide the same number of MAT files as the number of input channels.','Setting Error','modal') 
    return;      
end

tempFileName = unique(fileName);
for i = 1: length(tempFileName)
    try
        pre = whos('-file', fileName{i});  % - Exception: fail to access .mat file
    catch ME
        errordlg(ME.message,sprintf('MAT file:\n\n%s\n\ncan not be opened. Please verify the selected MAT file is valid', fileName{i}),'modal');
        return;
    end
end

% -------- Set parameter --------

funParams.ChannelIndex = channelIndex;
if length(fileName) == 1
    funParams.TransformFilePaths(channelIndex) = repmat(fileName(1), [1 length(channelIndex)]);
else
    funParams.TransformFilePaths(channelIndex) = fileName;
end
if get(handles.checkbox_mask, 'Value')
    funParams.TransformMasks = true;
else
    funParams.TransformMasks = false;
end

% Set parameters
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on button press in pushbutton_open.
function pushbutton_open_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
set(handles.listbox_transform, 'Value',1)

[filename, pathname] = uigetfile('*.mat','Select Movie Data MAT-file');
if ~any([filename,pathname])
    return;
end
try
    pre = whos('-file', [pathname filename]);  % - Exception: fail to access .mat file
catch ME
    errordlg(ME.message,'Selected MAT file can not be opened. Please verify you select the correct MAT file.','modal');
    return;
end

contents = get(handles.listbox_transform,'String');

% Add current formula to the listbox
contents{end+1} = [pathname filename];
set(handles.listbox_transform,'string',contents);

% Set user directory
sepDir = regexp(pathname, filesep, 'split');
dir = sepDir{1};
for i = 2: length(sepDir)-1
    dir = [dir filesep sepDir{i}];
end
userData.userDir = dir;

set(handles.figure1, 'Userdata', userData)

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% Notify the package GUI that the setting panel is closed
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


% --- Executes on button press in pushbutton_deletetransform.
function pushbutton_deletetransform_Callback(hObject, eventdata, handles)
% Call back function of 'delete' button
contents = get(handles.listbox_transform,'String');
% Return if list is empty
if isempty(contents)
    return;
end
num = get(handles.listbox_transform,'Value');

% Delete selected item
contents(num) = [ ];

% Refresh listbox
set(handles.listbox_transform,'String',contents);
% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (num>length(contents) && num>1)
    set(handles.listbox_transform,'Value',length(contents));
end

guidata(hObject, handles);


% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)
% call back of 'Up' button
id = get(handles.listbox_transform,'Value');
contents = get(handles.listbox_transform,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

set(handles.listbox_3, 'string', contents);
set(handles.listbox_3, 'value', id-1);

% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)

% Call back of 'Down' button
id = get(handles.listbox_transform,'Value');
contents = get(handles.listbox_transform,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

set(handles.listbox_3, 'string', contents);
set(handles.listbox_3, 'value', id+1);
