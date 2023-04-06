function varargout = bleedthroughCorrectionProcessGUI(varargin)
% BLEEDTHROUGHCORRECTIONPROCESSGUI M-file for bleedthroughCorrectionProcessGUI.fig
%      BLEEDTHROUGHCORRECTIONPROCESSGUI, by itself, creates a new BLEEDTHROUGHCORRECTIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = BLEEDTHROUGHCORRECTIONPROCESSGUI returns the handle to a new BLEEDTHROUGHCORRECTIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      BLEEDTHROUGHCORRECTIONPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BLEEDTHROUGHCORRECTIONPROCESSGUI.M with the given input arguments.
%
%      BLEEDTHROUGHCORRECTIONPROCESSGUI('Property','Value',...) creates a new BLEEDTHROUGHCORRECTIONPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before bleedthroughCorrectionProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to bleedthroughCorrectionProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help bleedthroughCorrectionProcessGUI

% Last Modified by GUIDE v2.5 20-Mar-2012 17:08:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @bleedthroughCorrectionProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @bleedthroughCorrectionProcessGUI_OutputFcn, ...
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


% --- Executes just before bleedthroughCorrectionProcessGUI is made visible.
function bleedthroughCorrectionProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',0);

% ---------------------- Channel Setup -------------------------
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Set up available input channels
set(handles.listbox_availableChannels, 'String', userData.MD.getChannelPaths,...
        'Userdata', 1: length(userData.MD.channels_));
    
% Set up input channel (one channel)
if ~isempty(funParams.ChannelIndex)
    set(handles.edit_channel, 'String', ...
        {userData.MD.channels_(funParams.ChannelIndex).channelPath_} , ...
        'Userdata', funParams.ChannelIndex )
end

if ~isempty(funParams.ChannelIndex)
    set(handles.listbox_availableChannels, 'Value', funParams.ChannelIndex)
end
    
set(handles.uitable_Coefficients,'Data',horzcat(userData.MD.getChannelPaths',...
    num2cell(funParams.Coefficients)));
%num2cell(funParams.Coefficients))
% Set up bleed channels
% set(handles.listbox_mask1, 'String', {userData.MD.channels_.channelPath_},...
%         'Userdata', 1: length(userData.MD.channels_));    

% 
% %  Parameter Setup 
% strBleedCoef = cell(1,length(funParams.BleedCoefficients));
% 
% for i = 1:length(funParams.BleedCoefficients)
%     strBleedCoef{i} = funParams.BleedCoefficients(i);
% end
% 
% set(handles.listbox_coef1, 'String', strBleedCoef)


% Choose default command line output for bleedthroughCorrectionProcessGUI
handles.output = hObject;

uicontrol(handles.pushbutton_done)
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = bleedthroughCorrectionProcessGUI_OutputFcn(hObject, eventdata, handles) 
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

% -------- Check user input --------
channelIndex = get(handles.edit_channel, 'Userdata');
if isempty(channelIndex)
    errordlg('Please select a channel as input channel.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = channelIndex;

% Get coefficients
data= get(handles.uitable_Coefficients,'Data');
if ~all(cellfun(@isscalar,data(:,2:end)))
    errordlg('Please enter valid coefficients.','Setting Error','modal')
    return;
end
coefficients=cell2mat(data(:,2:end));
if ~all(coefficients>=0)
    errordlg('Please enter valid coefficients.','Setting Error','modal')
    return;
end

if any(coefficients(:,1)>0 & coefficients(:,2)>0)
    errordlg('The same channel cannot be  used for bleed-through and cross-talk correction.',...
        'Setting Error','modal')
    return;
end
funParams.Coefficients = coefficients;

% Set parameters
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on selection change in listbox_availableChannels.
function listbox_availableChannels_Callback(hObject, eventdata, handles)

props = get(hObject, {'String','UserData'});
if isempty(props{1}), return; end

id = get(hObject, 'Value');
if isempty(id), return; end

set(handles.edit_channel, 'String', props{1}{id}, 'UserData',props{2}(id));


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
