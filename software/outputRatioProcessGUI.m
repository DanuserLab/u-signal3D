function varargout = outputRatioProcessGUI(varargin)
% OUTPUTRATIOPROCESSGUI M-file for outputRatioProcessGUI.fig
%      OUTPUTRATIOPROCESSGUI, by itself, creates a new OUTPUTRATIOPROCESSGUI or raises the existing
%      singleton*.
%
%      H = OUTPUTRATIOPROCESSGUI returns the handle to a new OUTPUTRATIOPROCESSGUI or the handle to
%      the existing singleton*.
%
%      OUTPUTRATIOPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OUTPUTRATIOPROCESSGUI.M with the given input arguments.
%
%      OUTPUTRATIOPROCESSGUI('Property','Value',...) creates a new OUTPUTRATIOPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before outputRatioProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to outputRatioProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help outputRatioProcessGUI

% Last Modified by GUIDE v2.5 07-May-2011 12:45:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @outputRatioProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @outputRatioProcessGUI_OutputFcn, ...
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


% --- Executes just before outputRatioProcessGUI is made visible.
function outputRatioProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Set up available input channels
set(handles.listbox_input1, 'String', userData.MD.getChannelPaths(),...
        'Userdata', 1:numel(userData.MD.channels_));
    
% Set up input channel (one channel)
if ~isempty(funParams.ChannelIndex)
    set(handles.edit_dir, 'String', userData.MD.getChannelPaths(funParams.ChannelIndex),...
        'Userdata', funParams.ChannelIndex )
    set(handles.listbox_input1, 'Value', funParams.ChannelIndex(1))
elseif ~isempty(userData.crtPackage.processes_{9})
    % If ratio process exist and has a numerator
    channelIndex= userData.crtPackage.processes_{9}.funParams_.ChannelIndex;
    if ~isempty(channelIndex)
        set(handles.edit_dir, 'String',userData.MD.getChannelPaths(channelIndex(1)), ...
            'Userdata',channelIndex(1));
        set(handles.listbox_input1, 'Value', channelIndex(1));
    end
end

    
% Parameter Setup
set(handles.edit_factor, 'String', num2str(funParams.ScaleFactor))
set(handles.edit_path, 'String', funParams.OutputDirectory)

% Set movie options
set(handles.checkbox_MakeMovie,'Value',funParams.MakeMovie);
if funParams.MakeMovie
    set(get(handles.uipanel_MovieOptions,'Children'),'Enable','on');
else
    set(get(handles.uipanel_MovieOptions,'Children'),'Enable','off');
end

booleanMovieOptions= {'ConstantScale','ColorBar','MakeAvi','MakeMov'}; 
for i=booleanMovieOptions
    set(handles.(['checkbox_' i{:}]), 'Value', funParams.MovieOptions.(i{:}))
end
set(handles.edit_Saturate, 'String', num2str(funParams.MovieOptions.Saturate))
set(handles.slider_Saturate, 'Value', funParams.MovieOptions.Saturate)

% Choose default command line output for outputRatioProcessGUI
handles.output = hObject;

% Update user data and GUI data
set(hObject, 'UserData', userData);
uicontrol(handles.pushbutton_done);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = outputRatioProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(~, ~, handles)

delete(handles.figure1);

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
% -------- Check user input --------
channelIndex = get (handles.edit_dir, 'Userdata');
outputDir = get(handles.edit_path, 'String');

if isempty(channelIndex)
    errordlg('Please select a channel as ratio channel.','Setting Error','modal')
    return;
end
if isempty(outputDir)
    errordlg('Please select a path to save .tiff file output.','Setting Error','modal')
    return;
end

scaleFactor=str2double(get(handles.edit_factor, 'String'));
if isnan(scaleFactor)  || scaleFactor< 0
    errordlg('Please provide a valid input for ''Scale Factor''.','Setting Error','modal');
    return;
end

%  Process Sanity check (only check underlying data )
outFunParams.OutputDirectory = outputDir;
parseProcessParams(userData.crtProc,outFunParams);
 
try
    userData.crtProc.sanityCheck;
catch ME

    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% Set parameter
funParams.ChannelIndex = channelIndex;
funParams.ScaleFactor = scaleFactor;

funParams.MakeMovie = get(handles.checkbox_MakeMovie,'Value');
booleanMovieOptions= {'ConstantScale','ColorBar','MakeAvi','MakeMov'};
for i=booleanMovieOptions
    funParams.MovieOptions.(i{:})= get(handles.(['checkbox_' i{:}]), 'Value');
end
funParams.MovieOptions.Saturate = get(handles.slider_Saturate, 'Value');

processGUI_ApplyFcn(hObject, eventdata, handles,funParams);



% --- Executes on button press in pushbutton_output.
function pushbutton_output_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
pathname = uigetdir(userData.MD.outputDirectory_);
if isequal(pathname,0) ,return; end
set(handles.edit_path, 'String', pathname);

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

function edit_Saturate_Callback(hObject, eventdata, handles)

value =str2double(get(hObject,'String'));
if isnan(value) || value < get(handles.edit_Saturate,'Min')
    value = get(handles.edit_Saturate,'Min');
elseif value > get(handles.edit_Saturate,'Max')
    value = get(handles.edit_Saturate,'Max');
end
set(handles.slider_Saturate,'Value',value);


% --- Executes on slider movement.
function slider_Saturate_Callback(hObject, ~, handles)

set(handles.edit_Saturate,'String',get(hObject,'Value'));

% --- Executes on button press in checkbox_MakeMovie.
function checkbox_MakeMovie_Callback(hObject, ~, handles)

if get(hObject,'Value')
    set(get(handles.uipanel_MovieOptions,'Children'),'Enable','on');
else
    set(get(handles.uipanel_MovieOptions,'Children'),'Enable','off');
end
