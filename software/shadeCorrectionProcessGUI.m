function varargout = shadeCorrectionProcessGUI(varargin)
% SHADECORRECTIONPROCESSGUI M-file for shadeCorrectionProcessGUI.fig
%      SHADECORRECTIONPROCESSGUI, by itself, creates a new SHADECORRECTIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = SHADECORRECTIONPROCESSGUI returns the handle to a new SHADECORRECTIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      SHADECORRECTIONPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHADECORRECTIONPROCESSGUI.M with the given input arguments.
%
%      SHADECORRECTIONPROCESSGUI('Property','Value',...) creates a new SHADECORRECTIONPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before shadeCorrectionProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to shadeCorrectionProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help shadeCorrectionProcessGUI

% Last Modified by GUIDE v2.5 20-Oct-2011 14:05:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @shadeCorrectionProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @shadeCorrectionProcessGUI_OutputFcn, ...
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


% --- Executes just before shadeCorrectionProcessGUI is made visible.
function shadeCorrectionProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

if ~all(cellfun(@isempty,userData.crtProc.inFilePaths_(2,:)));
    set(handles.listbox_shadeChannels, 'String', ...
        userData.crtProc.inFilePaths_(2,funParams.ChannelIndex ));
end

set(handles.checkbox_medianfilter, 'Value',funParams.MedianFilter);

if funParams.GaussFilterSigma >= 1
    set(handles.checkbox_gaussianfilter, 'Value', 1)
    set(handles.text_filters1, 'Enable','on');
    set(handles.edit_sigma, 'Enable','on',...
            'String',num2str(funParams.GaussFilterSigma))
end

set(handles.checkbox_normal, 'Value', logical(funParams.Normalize));

if ~funParams.Normalize
    set([handles.radiobutton_1 handles.radiobutton_2], 'Enable', 'off');
elseif funParams.Normalize == 2
    set(handles.radiobutton_2, 'Value', 1)
end

set(handles.listbox_shadeChannels, 'Value',1);

userData.userDir=userData.MD.outputDirectory_;


% Choose default command line output for shadeCorrectionProcessGUI
handles.output = hObject;

% Update user data and GUI data
set(handles.figure1, 'UserData', userData);
uicontrol(handles.pushbutton_done)
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = shadeCorrectionProcessGUI_OutputFcn(hObject, eventdata, handles) 
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

channelProps = get (handles.listbox_selectedChannels, {'Userdata','String'});
channelIndex=channelProps{1};
channelString=channelProps{2};
shadeChannels = get(handles.listbox_shadeChannels, 'String');

% Check user input
if isempty(channelString)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end

if numel(channelString) ~= numel(shadeChannels)
    errordlg('Please provide the same number of shade image channels as input channels.','Setting Error','modal')
    return;
end

if get(handles.checkbox_gaussianfilter, 'value')
    sigma = str2double(get(handles.edit_sigma, 'String'));
    if isnan(sigma) || sigma < 0
        errordlg('Please provide a valid input for ''Sigma''.','Setting Error','modal');
        return;
        
    elseif sigma < 1
        warndlg('''Sigma'' ought to be larger than 1 in Gaussian filtering','Setting Error','modal');
        return;
    end
else
    sigma=0;
end

% Save old process settings (for recovery if sanity check fails)
oldFunParams = userData.crtProc.funParams_;
oldShadeChannels = userData.crtProc.inFilePaths_(2,:);

% Apply new channel index and new shade images for sanity check
funParams.ChannelIndex = channelIndex; 
parseProcessParams(userData.crtProc, funParams);

%  Process Sanity check ( only check underlying data )
try
    userData.crtProc.setCorrectionImagePath(channelIndex, shadeChannels);
    userData.crtProc.sanityCheck();
catch ME
    errordlg(ME.message,'Setting Error','modal');
    if ~isempty(oldShadeChannels)
        userData.crtProc.setCorrectionImagePath(1:numel(oldShadeChannels), oldShadeChannels)
    end 
    userData.crtProc.setParameters(oldFunParams);
    return;
end

% Filter parametersprocessGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

funParams.MedianFilter = get(handles.checkbox_medianfilter, 'Value');
funParams.GaussFilterSigma = sigma;

% Normalize parameters
if ~get(handles.checkbox_normal, 'Value')
    funParams.Normalize = 0;
else
    if get(handles.radiobutton_1, 'Value')
        funParams.Normalize = 1;
    elseif get(handles.radiobutton_2, 'Value')
        funParams.Normalize = 2;
    end
end

% Set parameters
shadeSettingFcn =@(x) setCorrectionImagePath(x,channelIndex,shadeChannels);
processGUI_ApplyFcn(hObject, eventdata, handles,funParams,{shadeSettingFcn});


% --- Executes on button press in pushbutton_deletechannel.
function pushbutton_deletechannel_Callback(hObject, eventdata, handles)
% Call back function of 'delete' button
contents = get(handles.listbox_shadeChannels,'String');
% Return if list is empty
if isempty(contents)
    return;
end
num = get(handles.listbox_shadeChannels,'Value');

% Delete selected item
contents(num) = [ ];

% Refresh listbox
set(handles.listbox_shadeChannels,'String',contents);
% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (num>length(contents) && num>1)
    set(handles.listbox_shadeChannels,'Value',length(contents));
end

guidata(hObject, handles);

% --- Executes on button press in pushbutton_add.
function pushbutton_add_Callback(hObject, eventdata, handles)
% Call back of 'add' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

set(handles.listbox_shadeChannels, 'Value',1)

path = uigetdir(userData.userDir, 'Add Channels ...');
if path == 0
    return;
end
% Input validation function ...
% Get current list
contents = get(handles.listbox_shadeChannels,'String');

% Add current formula to the listbox
contents{end+1} = path;
set(handles.listbox_shadeChannels,'string',contents);

% Set user directory
sepDir = regexp(path, filesep, 'split');
dir = sepDir{1};
for i = 2: length(sepDir)-1
    dir = [dir filesep sepDir{i}];
end
userData.userDir = dir;

set(handles.figure1, 'Userdata', userData)
guidata(hObject, handles);

% --- Executes on button press in checkbox_gaussianfilter.
function checkbox_gaussianfilter_Callback(hObject, eventdata, handles)

if get(hObject, 'Value'), state='on'; else state='off'; end
set([handles.text_filters1 handles.edit_sigma], 'Enable',state);

% --- Executes on button press in checkbox_normal.
function checkbox_normal_Callback(hObject, eventdata, handles)

if get(hObject, 'Value'), state='on'; else state='off'; end
set([handles.radiobutton_1 handles.radiobutton_1], 'Enable',state);
   

% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)
% call back of 'Up' button

id = get(handles.listbox_shadeChannels,'Value');
contents = get(handles.listbox_shadeChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

set(handles.listbox_shadeChannels, 'string', contents);
set(handles.listbox_shadeChannels, 'value', id-1);

% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)
% Call back of 'Down' button

id = get(handles.listbox_shadeChannels,'Value');
contents = get(handles.listbox_shadeChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

set(handles.listbox_shadeChannels, 'string', contents);
set(handles.listbox_shadeChannels, 'value', id+1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

function uipanel_normalization_SelectionChangeFcn(hObject, eventdata)

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
