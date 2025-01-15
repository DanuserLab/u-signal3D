function varargout = deconvolution3DProcessGUI(varargin)
% Deconvolution3DProcessGUI M-file for Deconvolution3DProcessGUI.fig
%      Deconvolution3DProcessGUI, by itself, creates a new Deconvolution3DProcessGUI or raises the existing
%      singleton*.
%
%      H = Deconvolution3DProcessGUI returns the handle to a new Deconvolution3DProcessGUI or the handle to
%      the existing singleton*.
%
%      Deconvolution3DProcessGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in Deconvolution3DProcessGUI.M with the given input arguments.
%
%      Deconvolution3DProcessGUI('Property','Value',...) creates a new Deconvolution3DProcessGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Deconvolution3DProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Deconvolution3DProcessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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

% Edit the above text to modify the response to help Deconvolution3DProcessGUI

% Last Modified by GUIDE v2.5 30-Jul-2019 13:54:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @deconvolution3DProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @deconvolution3DProcessGUI_OutputFcn, ...
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


% --- Executes just before Deconvolution3DProcessGUI is made visible.
function deconvolution3DProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
funParams = userData.crtProc.funParams_;
%Remove the output directory as we don't want to replicate it to other
%movies if the "apply to all movies" box is checked. Ideally we would
%explicitly only replicate the parameters we set in this GUI but this is a
%quick fix. - HLE
if isfield(funParams,'OutputDirectory')
    funParams = rmfield(funParams,'OutputDirectory');
end

set(handles.popupmenu_CurrentChannel,'UserData',funParams);
% set(handles.popupmenu_deconMode, 'String', {'weiner','richLucy'})

% handles
handles.text_PSFpath.String = funParams.pathDeconPSF;
handles.text_apoPSFpath.String = funParams.pathApoPSF;
% handles.edit_computeMIP.Value = funParams.computeMIP;
handles.text_computeMIP.Visible = 'Off';
handles.edit_computeMIP.Visible = 'Off';

iChan = get(handles.popupmenu_CurrentChannel,'Value');
if isempty(iChan)
    iChan = 1;
    set(handles.popupmenu_CurrentChannel,'Value',1);
end

%Update channel parameter selection dropdown
popupmenu_CurrentChannel_Callback(hObject, eventdata, handles);
edit_weinerAuto_Callback(hObject, eventdata, handles);
popupmenu_deconMode_Callback(hObject, eventdata, handles);

% Update GUI user data
set(handles.figure1, 'UserData', userData);
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = deconvolution3DProcessGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(~, ~, handles)
% Delete figure
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, ~, handles)
% Notify the package GUI that the setting panel is closed
userData = get(handles.figure1, 'UserData');
if(isempty(userData)), userData = struct(); end;

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

% -------- Check user input --------

if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end

if isempty(get(handles.text_PSFpath, 'String')) || exist(get(handles.text_PSFpath, 'String'), 'file') ~= 2 
    errordlg('Please select a valid PSF file path.','Setting Error','modal')
    return;
end

%Save the currently set per-channel parameters
pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)


% Retrieve detection parameters
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

funParams.pathDeconPSF = handles.text_PSFpath.String;
funParams.pathApoPSF = handles.text_apoPSFpath.String;

% funParams.computeMIP = handles.edit_computeMIP.Value;
% Retrieve GUI-defined non-channel specific parameters

%Get selected image channels
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
if isempty(channelIndex)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = channelIndex;
funParams.channels = funParams.ChannelIndex;
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

function edit_weiner_Callback(hObject, eventdata, handles)
% hObject    handle to edit_weiner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_weiner as text
%        str2double(get(hObject,'String')) returns contents of edit_weiner as a double


% --- Executes during object creation, after setting all properties.
function edit_weiner_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_weiner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_computeMIP_Callback(hObject, eventdata, handles)
% hObject    handle to edit_computeMIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_computeMIP as text
%        str2double(get(hObject,'String')) returns contents of edit_computeMIP as a double


% --- Executes during object creation, after setting all properties.
function edit_computeMIP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_computeMIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_usePhotobleach_Callback(hObject, eventdata, handles)
% hObject    handle to edit_usePhotobleach (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_usePhotobleach as text
%        str2double(get(hObject,'String')) returns contents of edit_usePhotobleach as a double


% --- Executes during object creation, after setting all properties.
function edit_usePhotobleach_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_usePhotobleach (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popupmenu_CurrentChannel.
function popupmenu_CurrentChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_CurrentChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_CurrentChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_CurrentChannel
userData=get(handles.figure1,'UserData');
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

selChan = 1:numel(userData.MD.channels_);%For now just let them set parameters for all channels.
%selChan = get(handles.listbox_selectedChannels,'UserData');
chanStr = arrayfun(@(x)(['Channel ' num2str(x)]),selChan,'Unif',0);
set(handles.popupmenu_CurrentChannel,'String',chanStr);
iChan = get(handles.popupmenu_CurrentChannel,'Value');
%set(handles.popupmenu_CurrentChannel,'UserData',iChan);

% set(handles.popupmenu_deconMode, 'String', {'weiner','richLucy'},...
%      'Value', find(ismember(funParams.deconMode,{'weiner','richLucy'})))

% Set-up parameters
for i =1 : numel(funParams.PerChannelParams)
    paramName = funParams.PerChannelParams{i};
    if ~strcmp(paramName,'deconMode')
        parVal = funParams.(paramName)(iChan);
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
             set(handles.(['edit_' paramName]), 'Value', parVal);
        elseif iscell(funParams.(paramName))   
            set(handles.(['edit_' paramName]), 'String', parVal{:});
        else
            set(handles.(['edit_' paramName]), 'String', parVal);
        end
    elseif strcmp(paramName,'deconMode')
        parVal = funParams.(paramName)(iChan);
        set(handles.popupmenu_deconMode, 'String', Deconvolution3DProcess.validDeconMethods,...
        'Value', find(ismember(Deconvolution3DProcess.validDeconMethods,parVal)))
    end
end

% --- Executes during object creation, after setting all properties.
function popupmenu_CurrentChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_CurrentChannel (see GCBO) 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_saveChannelParams.
function pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_saveChannelParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get settings for the current channel before switching to another
iChan = get(handles.popupmenu_CurrentChannel,'Value');

%userData=get(handles.figure1,'UserData');
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

for i =1 : numel(funParams.PerChannelParams)
    paramName = funParams.PerChannelParams{i};
    if ~strcmp(paramName,'deconMode') 
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
            parVal = get(handles.(['edit_' paramName]), 'Value');
            funParams.(paramName)(iChan) = parVal;
        elseif iscell(funParams.(paramName))   
            parVal = get(handles.(['edit_' paramName]), 'String');
            funParams.(paramName)(iChan) = parVal;
        else
            parVal = get(handles.(['edit_' paramName]), 'String');
            funParams.(paramName)(iChan) = str2double(parVal);
        end
    elseif strcmp(paramName,'deconMode')
        strSet = handles.popupmenu_deconMode.String;
        val = handles.popupmenu_deconMode.Value;
        funParams.(paramName)(iChan) = strSet(val);
    end
end

set(handles.popupmenu_CurrentChannel,'UserData',funParams);

function edit_apoHeight_Callback(hObject, eventdata, handles)
% hObject    handle to edit_apoHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_apoHeight as text
%        str2double(get(hObject,'String')) returns contents of edit_apoHeight as a double


% --- Executes during object creation, after setting all properties.
function edit_apoHeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_apoHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_richLucyIter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_richLucyIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_richLucyIter as text
%        str2double(get(hObject,'String')) returns contents of edit_richLucyIter as a double

% --- Executes during object creation, after setting all properties.
function edit_richLucyIter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_richLucyIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function text_deconMode_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text_deconMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu_deconMode.
function popupmenu_deconMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_deconMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_deconMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_deconMode
strSet = handles.popupmenu_deconMode.String;
val = handles.popupmenu_deconMode.Value;
if strcmp('weiner',strSet(val))
    set(handles.edit_richLucyIter,'enable','off');
else
    set(handles.edit_richLucyIter,'enable','on');
end


% --- Executes on button press in pushbutton_PSF.
function pushbutton_PSF_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_PSF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.text_PSFpath.String,'dir') == 7
    [filePSF, pathDeconPSF] = uigetfile('*.mat',...
               'Select PSF .mat file',handles.text_PSFpath.String);
else
    [filePSF, pathDeconPSF] = uigetfile('*.mat',...
               'Select PSF .mat file');    
end

handles.text_PSFpath.String = fullfile(pathDeconPSF,filePSF);



% % --- Executes on button press in pushbutton_ApoPSF.
function pushbutton_apoPSF_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_PSF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.text_ApoPSFpath.String,'dir') == 7
    [filePSF, pathApoPSF] = uigetfile('*.mat',...
               'Select PSF .mat file',handles.text_ApoPSFpath.String);
else
    [filePSF, pathApoPSF] = uigetfile('*.mat',...
               'Select PSF .mat file');    
end

handles.text_ApoPSFpath.String = fullfile(pathApoPSF,filePSF);


% --- Executes on button press in edit_weinerAuto.
function edit_weinerAuto_Callback(hObject, eventdata, handles)
% hObject    handle to edit_weinerAuto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_weinerAuto
if logical(handles.edit_weinerAuto.Value) == true
    set(handles.edit_weiner,'enable','off');
else
    set(handles.edit_weiner,'enable','on');
end
