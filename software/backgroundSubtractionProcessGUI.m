function varargout = backgroundSubtractionProcessGUI(varargin)
% BACKGROUNDSUBTRACTIONPROCESSGUI M-file for backgroundSubtractionProcessGUI.fig
%      BACKGROUNDSUBTRACTIONPROCESSGUI, by itself, creates a new BACKGROUNDSUBTRACTIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = BACKGROUNDSUBTRACTIONPROCESSGUI returns the handle to a new BACKGROUNDSUBTRACTIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      BACKGROUNDSUBTRACTIONPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BACKGROUNDSUBTRACTIONPROCESSGUI.M with the given input arguments.
%
%      BACKGROUNDSUBTRACTIONPROCESSGUI('Property','Value',...) creates a new BACKGROUNDSUBTRACTIONPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before backgroundSubtractionProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to backgroundSubtractionProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help backgroundSubtractionProcessGUI

% Last Modified by GUIDE v2.5 20-Oct-2011 13:47:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @backgroundSubtractionProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @backgroundSubtractionProcessGUI_OutputFcn, ...
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


% --- Executes just before backgroundSubtractionProcessGUI is made visible.
function backgroundSubtractionProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% Set up available mask channels
set(handles.listbox_availableMaskChannels,'String',userData.MD.getChannelPaths(), ...
    'UserData',1:numel(userData.MD.channels_));

maskChannelIndex = funParams.MaskChannelIndex;

% Find any parent process
parentProc = userData.crtPackage.getParent(userData.procID);
if isempty(userData.crtPackage.processes_{userData.procID}) && ~isempty(parentProc)
    % Check existence of all parent processes
    emptyParentProc = any(cellfun(@isempty,userData.crtPackage.processes_(parentProc)));
    if ~emptyParentProc
        % Intersect channel index with channel index of parent processes
        parentChannelIndex = @(x) userData.crtPackage.processes_{x}.funParams_.ChannelIndex;
        for i = parentProc
            maskChannelIndex = intersect(maskChannelIndex,parentChannelIndex(i));
        end
    end
   
end

if ~isempty(maskChannelIndex)
    maskChannelString = userData.MD.getChannelPaths(maskChannelIndex);
else
    maskChannelString = {};
end

set(handles.listbox_selectedMaskChannels,'String',maskChannelString,...
    'UserData',maskChannelIndex);

% Choose default command line output for backgroundSubtractionProcessGUI
handles.output = hObject;

% Update user data and GUI data
set(handles.figure1, 'UserData', userData);
uicontrol(handles.pushbutton_done)
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = backgroundSubtractionProcessGUI_OutputFcn(hObject, eventdata, handles) 
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

% -------- Check user input --------

channelProps = get(handles.listbox_selectedChannels, {'Userdata','String'});
maskChannelProps = get(handles.listbox_selectedMaskChannels, {'Userdata','String'});
if isempty(channelProps{2})
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end

if numel(channelProps{2}) ~= numel(maskChannelProps{2})
    errordlg('Please provide the same number of mask channels as input channels.','Setting Error','modal')
    return;
end

% Process Sanity check  ( only check underlying data )
oldFunParams = userData.crtProc.funParams_;

funParams.MaskChannelIndex = maskChannelProps{1};
parseProcessParams(userData.crtProc,funParams);
 
try
    % Background Subtraction Process sanity check the mask channels
    userData.crtProc.sanityCheck;
catch ME
    errordlg([ME.message 'Please double check your data'],...
        'Setting Error','modal');
    userData.crtProc.setPara(oldFunParams);
    return;
end

% Set input channels
funParams.ChannelIndex = channelProps{1};

processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on button press in checkbox_mask_all.
function checkbox_mask_all_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_all
contents1 = get(handles.listbox_availableMaskChannels, 'String');

chanIndex1 = get(handles.listbox_availableMaskChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedMaskChannels, 'Userdata');

% Return if listbox1 is empty
if isempty(contents1)
    return;
end

switch get(hObject,'Value')
    case 1
        set(handles.listbox_selectedMaskChannels, 'String', contents1);
        chanIndex2 = chanIndex1;
    case 0
        set(handles.listbox_selectedMaskChannels, 'String', {}, 'Value',1);
        chanIndex2 = [ ];
end
set(handles.listbox_selectedMaskChannels, 'UserData', chanIndex2);


% --- Executes on button press in pushbutton_mask_select.
function pushbutton_mask_select_Callback(hObject, eventdata, handles)
% call back function of 'select' button

contents1 = get(handles.listbox_availableMaskChannels, 'String');
contents2 = get(handles.listbox_selectedMaskChannels, 'String');
id = get(handles.listbox_availableMaskChannels, 'Value');

% If channel has already been added, return;
chanIndex1 = get(handles.listbox_availableMaskChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedMaskChannels, 'Userdata');

for i = id

        contents2{end+1} = contents1{i};
        
        chanIndex2 = cat(2, chanIndex2, chanIndex1(i));

end

set(handles.listbox_selectedMaskChannels, 'String', contents2, 'Userdata', chanIndex2);



% --- Executes on button press in pushbutton_mask_delete.
function pushbutton_mask_delete_Callback(hObject, eventdata, handles)
% Call back function of 'delete' button
contents = get(handles.listbox_selectedMaskChannels,'String');
id = get(handles.listbox_selectedMaskChannels,'Value');

% Return if list is empty
if isempty(contents) || isempty(id)
    return;
end

% Delete selected item
contents(id) = [ ];

% Delete userdata
chanIndex2 = get(handles.listbox_selectedMaskChannels, 'Userdata');
chanIndex2(id) = [ ];
set(handles.listbox_selectedMaskChannels, 'Userdata', chanIndex2);

% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (id >length(contents) && id>1)
    set(handles.listbox_selectedMaskChannels,'Value',length(contents));
end
% Refresh listbox
set(handles.listbox_selectedMaskChannels,'String',contents);

% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)
% call back of 'Up' button

id = get(handles.listbox_selectedMaskChannels,'Value');
contents = get(handles.listbox_selectedMaskChannels,'String');


% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

chanIndex = get(handles.listbox_selectedMaskChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id-1);
chanIndex(id-1) = temp;

set(handles.listbox_selectedMaskChannels, 'String', contents, 'Userdata', chanIndex);
set(handles.listbox_selectedMaskChannels, 'value', id-1);


% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)
% Call back of 'Down' button

id = get(handles.listbox_selectedMaskChannels,'Value');
contents = get(handles.listbox_selectedMaskChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

chanIndex = get(handles.listbox_selectedMaskChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id+1);
chanIndex(id+1) = temp;

set(handles.listbox_selectedMaskChannels, 'string', contents, 'Userdata',chanIndex);
set(handles.listbox_selectedMaskChannels, 'value', id+1);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');

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
