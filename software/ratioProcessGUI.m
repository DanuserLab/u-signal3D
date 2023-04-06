function varargout = ratioProcessGUI(varargin)
% RATIOPROCESSGUI M-file for ratioProcessGUI.fig
%      RATIOPROCESSGUI, by itself, creates a new RATIOPROCESSGUI or raises the existing
%      singleton*.
%
%      H = RATIOPROCESSGUI returns the handle to a new RATIOPROCESSGUI or the handle to
%      the existing singleton*.
%
%      RATIOPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RATIOPROCESSGUI.M with the given input arguments.
%
%      RATIOPROCESSGUI('Property','Value',...) creates a new RATIOPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ratioProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ratioProcessGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help ratioProcessGUI

% Last Modified by GUIDE v2.5 20-Oct-2011 14:28:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ratioProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ratioProcessGUI_OutputFcn, ...
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


% --- Executes just before ratioProcessGUI is made visible.
function ratioProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:});

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Channel setup
set([handles.listbox_input handles.listbox_mask],...
    'String', userData.MD.getChannelPaths(),...
    'Userdata', 1: length(userData.MD.channels_));

if ~isempty(funParams.ChannelIndex)
    set(handles.edit_nu_input, 'String',userData.MD.getChannelPaths(funParams.ChannelIndex(1)), ...
        'Userdata',funParams.ChannelIndex(1));
      
    set(handles.edit_de_input, 'String',userData.MD.getChannelPaths(funParams.ChannelIndex(2)), ...
        'Userdata',funParams.ChannelIndex(2));   
end

if ~isempty(funParams.MaskChannelIndex)
    set(handles.edit_nu_mask, 'String',userData.MD.getChannelPaths(funParams.MaskChannelIndex(1)), ...
        'Userdata',funParams.MaskChannelIndex(1));
   
    set(handles.edit_de_mask, 'String',userData.MD.getChannelPaths(funParams.MaskChannelIndex(2)), ...
        'Userdata',funParams.MaskChannelIndex(2));
end
    
% Parameter Setup
set(handles.checkbox_mask, 'Value', funParams.ApplyMasks)
if ~funParams.ApplyMasks
    set(get(handles.uipanel_mask,'Children'),'Enable','off');
end

% Choose default command line output for ratioProcessGUI
handles.output = hObject;

% Update user data and GUI data
set(handles.figure1, 'UserData', userData);
uicontrol(handles.pushbutton_done)
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ratioProcessGUI_OutputFcn(hObject, eventdata, handles) 
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
%Check user input
nuChannelIndex = get(handles.edit_nu_input, 'Userdata');
deChannelIndex = get(handles.edit_de_input, 'Userdata');

if isempty(nuChannelIndex)
    errordlg('Please select a channel as numerator ''Input channel''.','Setting Error','modal')
    return;
    
end

if isempty(deChannelIndex)
    errordlg('Please select a channel as denominator ''Input Channel''.','Setting Error','modal')
    return;
end

% if nuChannelIndex == deChannelIndex
%     errordlg('Numerator and denominator cannot be the same ''Input Channel''.','Setting Error','modal')
%     return;
% end

funParams.ChannelIndex = [nuChannelIndex deChannelIndex];


if get(handles.checkbox_mask, 'Value')
    nuMaskChannelIndex = get(handles.edit_nu_mask, 'Userdata');
    deMaskChannelIndex = get(handles.edit_de_mask, 'Userdata');

    if isempty(nuMaskChannelIndex)
        errordlg('Please select a channel as numerator ''Mask Channel''.','Setting Error','modal') 
        return;
    end

    if isempty(deMaskChannelIndex)
        errordlg('Please select a channel as denominator ''Mask Channel''.','Setting Error','modal')
        return;
    end
    
%     if nuMaskChannelIndex==deMaskChannelIndex
%         errordlg('Numerator and denominator cannot be the same ''Mask Channel''.','Setting Error','modal')
%         return;
%     end
    
    funParams.MaskChannelIndex = [nuMaskChannelIndex deMaskChannelIndex];
end

%  Process Sanity check ( only check underlying data )
try
    userData.crtProc.sanityCheck;
catch ME

    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% Set parameter
funParams.ApplyMasks = get(handles.checkbox_mask, 'Value');

processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on button press in pushbutton_nu_input.
function pushbutton_nu_input_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Numerator' button in input channel

contents1 = get(handles.listbox_input, 'String');
chanIndex = get(handles.listbox_input, 'Userdata');
id = get(handles.listbox_input, 'Value');

if isempty(contents1) || isempty(id)
   return;
% elseif strcmp( get(handles.edit_de_input, 'string'),  contents1{id})
%     return;
else
    set(handles.edit_nu_input, 'string', contents1{id}, 'Userdata', chanIndex(id));
end

% If numerator of mask channel is not set up. Set the same
% channel as the numerator of input channel
if get(handles.checkbox_mask, 'Value') && ...
        isempty(get(handles.edit_nu_mask, 'String')) 
   set(handles.edit_nu_mask, 'String', contents1{id}, 'Userdata', chanIndex(id)); 
end


% --- Executes on button press in checkbox_mask.
function checkbox_mask_Callback(hObject, eventdata, handles)
% Call back of 'Use Mask Channels' checkbox

if get(hObject, 'Value'), state= 'on'; else state ='off'; end
set(get(handles.uipanel_mask,'Children'),'Enable',state);

% --- Executes on button press in pushbutton_de_input.
function pushbutton_de_input_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Denominator' button in input channel

contents1 = get(handles.listbox_input, 'String');
chanIndex = get(handles.listbox_input, 'Userdata');

id = get(handles.listbox_input, 'Value');

if isempty(contents1) || isempty(id)
   return;
% elseif strcmp( get(handles.edit_nu_input, 'string'),  contents1{id})
%     return;
else
    set(handles.edit_de_input, 'string', contents1{id},'Userdata',chanIndex(id));
end

% If denominator of mask channel is not set up. Set the same
% channel as the denominator of input channel
if get(handles.checkbox_mask, 'Value') && ...
        isempty(get(handles.edit_de_mask, 'String')) 
   set(handles.edit_de_mask, 'String', contents1{id}, 'Userdata', chanIndex(id)); 
end


% --- Executes on button press in pushbutton_nu_mask.
function pushbutton_nu_mask_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Numerator' button in mask channel

contents1 = get(handles.listbox_mask, 'String');
chanIndex = get(handles.listbox_mask, 'userdata');
id = get(handles.listbox_mask, 'Value');

if isempty(contents1) || isempty(id)
   return;
% elseif strcmp( get(handles.edit_de_mask, 'string'),  contents1{id})
%     return;
else
    set(handles.edit_nu_mask, 'string', contents1{id}, 'Userdata', chanIndex(id));
end

% --- Executes on button press in pushbutton_de_mask.
function pushbutton_de_mask_Callback(hObject, eventdata, handles)
% call back function of 'Choose as Denominator' button in mask channel

contents1 = get(handles.listbox_mask, 'String');
chanIndex = get(handles.listbox_mask, 'Userdata');

id = get(handles.listbox_mask, 'Value');

if isempty(contents1) || isempty(id)
   return;
% elseif strcmp( get(handles.edit_nu_mask, 'string'),  contents1{id})
%     return;
else
    set(handles.edit_de_mask, 'string', contents1{id}, 'Userdata',chanIndex(id));
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
