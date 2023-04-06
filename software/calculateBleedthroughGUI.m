function varargout = calculateBleedthroughGUI(varargin)
% CALCULATEBLEEDTHROUGHGUI M-file for calculateBleedthroughGUI.fig
%      CALCULATEBLEEDTHROUGHGUI, by itself, creates a new CALCULATEBLEEDTHROUGHGUI or raises the existing
%      singleton*.
%
%      H = CALCULATEBLEEDTHROUGHGUI returns the handle to a new CALCULATEBLEEDTHROUGHGUI or the handle to
%      the existing singleton*.
%
%      CALCULATEBLEEDTHROUGHGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALCULATEBLEEDTHROUGHGUI.M with the given input arguments.
%
%      CALCULATEBLEEDTHROUGHGUI('Property','Value',...) creates a new CALCULATEBLEEDTHROUGHGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before calculateBleedthroughGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to calculateBleedthroughGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help calculateBleedthroughGUI

% Last Modified by GUIDE v2.5 05-Apr-2011 15:32:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @calculateBleedthroughGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @calculateBleedthroughGUI_OutputFcn, ...
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


% --- Executes just before calculateBleedthroughGUI is made visible.
function calculateBleedthroughGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% Available tools 
% UserData data:
%       userData.mainFig - handle of main figure
%       userData.handles_main - 'handles' of main figure
%
%       userData.questIconData - help icon image information
%       userData.colormap - color map information
%

set(handles.text_copyright, 'String', getLCCBCopyright())

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
handles.output = hObject;

% Get main figure handle and process id
t = find(strcmp(varargin,'mainFig'));
userData.mainFig = varargin{t+1};
userData.handles_main = guidata(userData.mainFig);

% Get current package and process
userData_main = get(userData.mainFig, 'UserData');

% Get icon infomation
userData.questIconData = userData_main.questIconData;
userData.colormap = userData_main.colormap;


% -----------------------Channel Setup--------------------------

set(handles.listbox_input, 'String', {userData_main.MD(userData_main.id).channels_.channelPath_},...
        'Userdata', 1: length(userData_main.MD(userData_main.id).channels_));
set(handles.listbox_mask, 'String', {userData_main.MD(userData_main.id).channels_.channelPath_},...
        'Userdata', 1: length(userData_main.MD(userData_main.id).channels_));  
    
% ----------------------Set up help icon------------------------

% Set up help icon
set(hObject,'colormap',userData.colormap);
% Set up package help. Package icon is tagged as '0'
axes(handles.axes_help);
Img = image(userData.questIconData); 
set(gca, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'),...
    'visible','off','YDir','reverse');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn,...
    'UserData', struct('class',mfilename))

% ----------------------------------------------------------------

% Update user data and GUI data
set(handles.figure1, 'UserData', userData);

uicontrol(handles.pushbutton_done)
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = calculateBleedthroughGUI_OutputFcn(hObject, eventdata, handles) 
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
if isempty(get(handles.edit_fluorophore_input, 'String'))
	errordlg('Please select a channel as fluorophore channel ''Input channel''.','Setting Error','modal') 
    return;
else
    if strcmp(get(handles.edit_fluorophore_input, 'String'), ...
                            get(handles.edit_bleedthrough_input, 'String'))
        errordlg('Fluorophore and bleedthrough cannot be the same ''Input Channel''.','Setting Error','modal') 
        return;
    end
end

if isempty(get(handles.edit_bleedthrough_input, 'String'))
   errordlg('Please select a channel as bleedthrough channel ''Input Channel''.','Setting Error','modal') 
    return;
end

if isempty(get(handles.edit_fluorophore_mask, 'String'))
    errordlg('Please select a channel as fluorophore mask ''Mask Channel''.','Setting Error','modal') 
    return;
end

if isempty(get(handles.edit_bleedthrough_mask, 'String'))
    errordlg('Please select a channel as bleedthrough mask ''Mask Channel''.','Setting Error','modal') 
    return;
end


% Calculate bleedthrough coefficient for current movies

channelIndex = [get(handles.edit_fluorophore_input, 'Userdata'), get(handles.edit_bleedthrough_input, 'Userdata')];
maskChannelIndex = [ get(handles.edit_fluorophore_mask, 'Userdata'), get(handles.edit_bleedthrough_mask, 'Userdata')];
calculateMovieBleedthrough(userData_main.MD(userData_main.id),...
   'FluorophoreChannel',channelIndex(1),...
   'BleedthroughChannel',channelIndex(2),...
   'FluorophoreMaskChannel',maskChannelIndex(1),...
   'BleedthroughMaskChannel',maskChannelIndex(2));

% Save user data
set(userData.mainFig, 'UserData', userData_main)

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);
delete(handles.figure1);


% --- Executes on button press in pushbutton_fluorophore_input.
function pushbutton_fluorophore_input_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Numerator' button in input channel

contents1 = get(handles.listbox_input, 'String');
chanIndex = get(handles.listbox_input, 'Userdata');
id = get(handles.listbox_input, 'Value');

if isempty(contents1) || isempty(id)
   return;
else
    set(handles.edit_fluorophore_input, 'string', contents1{id}, 'Userdata', chanIndex(id));
end

% If mask channel is not set up. Set the same
% channel as the numerator of input channel
if isempty(get(handles.edit_fluorophore_mask, 'String')) 
   set(handles.edit_fluorophore_mask, 'String', contents1{id}, 'Userdata', chanIndex(id)); 
end

% --- Executes on button press in pushbutton_bleedthrough_input.
function pushbutton_bleedthrough_input_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Denominator' button in input channel

contents1 = get(handles.listbox_input, 'String');
chanIndex = get(handles.listbox_input, 'Userdata');

id = get(handles.listbox_input, 'Value');

if isempty(contents1) || isempty(id)
   return;
else
    set(handles.edit_bleedthrough_input, 'string', contents1{id},'Userdata',chanIndex(id));
end

% If denominator of mask channel is not set up. Set the same
% channel as the denominator of input channel
if isempty(get(handles.edit_bleedthrough_mask, 'String')) 
   set(handles.edit_bleedthrough_mask, 'String', contents1{id}, 'Userdata', chanIndex(id)); 
end


% --- Executes on button press in pushbutton_fluorophore_mask.
function pushbutton_fluorophore_mask_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Numerator' button in mask channel

contents1 = get(handles.listbox_mask, 'String');
chanIndex = get(handles.listbox_mask, 'userdata');
id = get(handles.listbox_mask, 'Value');

if isempty(contents1) || isempty(id)
   return;
else
    set(handles.edit_fluorophore_mask, 'string', contents1{id}, 'Userdata', chanIndex(id));
end


% --- Executes on button press in pushbutton_bleedthrough_mask.
function pushbutton_bleedthrough_mask_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Denominator' button in mask channel

contents1 = get(handles.listbox_mask, 'String');
chanIndex = get(handles.listbox_mask, 'Userdata');

id = get(handles.listbox_mask, 'Value');

if isempty(contents1) || isempty(id)
   return;
else
    set(handles.edit_bleedthrough_mask, 'string', contents1{id}, 'Userdata',chanIndex(id));
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
