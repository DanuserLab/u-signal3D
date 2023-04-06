function varargout = photobleachCorrectionProcessGUI(varargin)
% photobleachCorrectionProcessGUI M-file for photobleachCorrectionProcessGUI.fig
%      photobleachCorrectionProcessGUI, by itself, creates a new photobleachCorrectionProcessGUI or raises the existing
%      singleton*.
%
%      H = photobleachCorrectionProcessGUI returns the handle to a new photobleachCorrectionProcessGUI or the handle to
%      the existing singleton*.
%
%      photobleachCorrectionProcessGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in photobleachCorrectionProcessGUI.M with the given input arguments.
%
%      photobleachCorrectionProcessGUI('Property','Value',...) creates a new photobleachCorrectionProcessGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before photobleachCorrectionProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to photobleachCorrectionProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help photobleachCorrectionProcessGUI

% Last Modified by GUIDE v2.5 24-Aug-2010 11:17:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @photobleachCorrectionProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @photobleachCorrectionProcessGUI_OutputFcn, ...
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


% --- Executes just before photobleachCorrectionProcessGUI is made visible.
function photobleachCorrectionProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',0);

% Channel Setup--------------------------

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Set up available input channels
set(handles.listbox_input1, 'String', {userData.MD.channels_.channelPath_},...
        'Userdata', 1: length(userData.MD.channels_));
    
% Set up input channel (one channel)
if ~isempty(funParams.ChannelIndex)
    set(handles.edit_dir, 'String', ...
        {userData.MD.channels_(funParams.ChannelIndex).channelPath_}, ...
        'Userdata', funParams.ChannelIndex )
    set(handles.listbox_input1, 'Value', funParams.ChannelIndex(1))
    
else % If ratio process is setup, use the numerator of ratioing process
    
    temp = cellfun(@(x)isa(x, 'RatioProcess'), userData.crtPackage.processes_);
    
    % If ratio process exist and has a numerator
    if any(temp) && ~isempty(userData.crtPackage.processes_{temp}.funParams_.ChannelIndex)
        nu = userData.crtPackage.processes_{temp}.funParams_.ChannelIndex(1);
        
        set(handles.edit_dir, 'String',{userData.MD.channels_(nu).channelPath_}, ...
            'Userdata', nu )
        set(handles.listbox_input1, 'Value', nu)        
    end
    
end


% ---------------------- Parameter Setup -------------------------

switch funParams.CorrectionType
    case 'RatioOfAverages'
        set(handles.radiobutton_1, 'Value', 1);
    case 'AverageOfRatios'
        set(handles.radiobutton_2, 'Value', 1);
    case 'RatioOfTotals'
        set(handles.radiobutton_3, 'Value', 1);
end

% Set callback function of radio button group uipanel_1
set(handles.uipanel_2, 'SelectionChangeFcn', @uipanel_2_SelectionChangeFcn);

% Choose default command line output for photobleachCorrectionProcessGUI
handles.output = hObject;

uicontrol(handles.pushbutton_done)
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = photobleachCorrectionProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% Delete figure
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
userData_main = get(userData.mainFig, 'UserData');

% -------- Check user input --------

channelIndex = get (handles.edit_dir, 'Userdata');

if isempty(channelIndex)
    errordlg('Please select at least one channel as input channel.','Setting Error','modal') 
    return;
end
% -------- Process Sanity check --------
% ( only check underlying data )

try
    userData.crtProc.sanityCheck;
catch ME

    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% -------- Set parameter --------

funParams.ChannelIndex = channelIndex;

if get(handles.radiobutton_1, 'Value')
    funParams.CorrectionType = 'RatioOfAverages';
elseif get(handles.radiobutton_2, 'Value')
    funParams.CorrectionType = 'AverageOfRatios';
elseif get(handles.radiobutton_3, 'Value')
    funParams.CorrectionType = 'RatioOfTotals';
end

% Set parameters
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

function uipanel_2_SelectionChangeFcn(hObject, eventdata)



% --- Executes on selection change in listbox_input1.
function listbox_input1_Callback(hObject, eventdata, handles)
contents1 = get(hObject, 'String');
chanIndex = get(hObject, 'Userdata');

id = get(hObject, 'Value');

if isempty(contents1) || isempty(id)
   return;
else
    set(handles.edit_dir, 'string', contents1{id}, 'Userdata',chanIndex(id));
end

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
