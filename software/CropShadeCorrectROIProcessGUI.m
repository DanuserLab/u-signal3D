function varargout = CropShadeCorrectROIProcessGUI(varargin)
%CROPSHADECORRECTROIPROCESSGUI MATLAB code file for CropShadeCorrectROIProcessGUI.fig
%      CROPSHADECORRECTROIPROCESSGUI, by itself, creates a new CROPSHADECORRECTROIPROCESSGUI or raises the existing
%      singleton*.
%
%      H = CROPSHADECORRECTROIPROCESSGUI returns the handle to a new CROPSHADECORRECTROIPROCESSGUI or the handle to
%      the existing singleton*.
%
%      CROPSHADECORRECTROIPROCESSGUI('Property','Value',...) creates a new CROPSHADECORRECTROIPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to CropShadeCorrectROIProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CROPSHADECORRECTROIPROCESSGUI('CALLBACK') and CROPSHADECORRECTROIPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CROPSHADECORRECTROIPROCESSGUI.M with the given input
%      arguments.
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

% Edit the above text to modify the response to help CropShadeCorrectROIProcessGUI

% Last Modified by GUIDE v2.5 22-Nov-2022 14:38:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CropShadeCorrectROIProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CropShadeCorrectROIProcessGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before CropShadeCorrectROIProcessGUI is made visible.
function CropShadeCorrectROIProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% set GUI with Parameters
set(handles.edit_cropROIpositions, 'String',num2str(funParams.cropROIpositions))
set(handles.edit_frameNumber, 'String',num2str(funParams.currentImg))



% Save the image directories and names (for cropping preview)
userData.nFrames = userData.MD.nFrames_;
userData.imRectHandle.isvalid=0;
userData.cropROI = [1 1 userData.MD.imSize_(end:-1:1)];
userData.previewFig=-1;

% Read the first image and update the sliders max value and steps
props = get(handles.listbox_selectedChannels, {'UserData','Value'});
userData.chanIndx = props{1}(props{2});
% set(handles.edit_frameNumber,'String',1); % already set above to funParams.currentImg
set(handles.slider_frameNumber,'Min',1,'Value',funParams.currentImg,'Max',userData.nFrames,...
    'SliderStep',[1/max(1,double(userData.nFrames-1))  10/max(1,double(userData.nFrames-1))]);
userData.imIndx=funParams.currentImg;

% displayed images for cropping is from raw images, but the actual cropping is done on the shade corrected images.
userData.imData=mat2gray(userData.MD.channels_(userData.chanIndx).loadImage(userData.imIndx));



% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = CropShadeCorrectROIProcessGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


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

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

%  Check user input --------
if isempty(get(handles.listbox_selectedChannels, 'String')) || ~isequal(numel(get(handles.listbox_selectedChannels, 'String')), 2)
    errordlg('Please select two input channels from ''Available Channels''.','Setting Error','modal')
    return;
end

if any(isnan(str2num(get(handles.edit_cropROIpositions, 'String')))) ...
    || any(str2num(get(handles.edit_cropROIpositions, 'String')) < 0) ...
    || isempty(get(handles.edit_cropROIpositions, 'String'))
  errordlg('Please provide a valid input for ''ROI positions''.','Setting Error','modal');
  return;
end

if isnan(str2double(get(handles.edit_frameNumber, 'String'))) ...
    || str2double(get(handles.edit_frameNumber, 'String')) < 0
  errordlg('Please provide a valid input for ''Current Image''.','Setting Error','modal');
  return;
end

%  Process Sanity check ( only check underlying data )
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
try
    userData.crtProc.sanityCheck;
catch ME
    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% Retrieve GUI-defined parameters
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
funParams.ChannelIndex = channelIndex;

funParams.cropROIpositions = round(cellfun(@str2num, regexp(get(handles.edit_cropROIpositions, 'String'), '\s+', 'split')));
funParams.currentImg = str2double(get(handles.edit_frameNumber, 'String'));

% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end





 % --- Executes on button press in checkbox_crop.
function update_data(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');

% Retrieve the channel index
props=get(handles.listbox_selectedChannels,{'UserData','Value'});
chanIndx = props{1}(props{2});
imIndx = get(handles.slider_frameNumber,'Value');

% Load a new image if either the image number or the channel has been changed
if (chanIndx~=userData.chanIndx) ||  (imIndx~=userData.imIndx)
    % Update image flag and dat
    userData.imData=mat2gray(userData.MD.channels_(chanIndx).loadImage(imIndx));
    userData.updateImage=1;
    userData.chanIndx=chanIndx;
    userData.imIndx=imIndx;
        
    % Update roi
    if userData.imRectHandle.isvalid
        userData.cropROI=getPosition(userData.imRectHandle);
    end    
else
    userData.updateImage=0;
end

% In case of crop previewing mode
if get(handles.checkbox_crop,'Value')
    % Create figure if non-existing or closed
    if ~isfield(userData, 'previewFig') || ~ishandle(userData.previewFig)
        userData.previewFig = figure('Name','Select the region to crop',...
            'DeleteFcn',@close_previewFig,'UserData',handles.figure1);
        userData.newFigure = 1;
    else
        figure(userData.previewFig);
        userData.newFigure = 0;
    end
    
    % Retrieve the image object handle
    imHandle =findobj(userData.previewFig,'Type','image');
    if userData.newFigure || userData.updateImage
        if isempty(imHandle)
            imHandle=imshow(userData.imData);
            axis off;
        else
            set(imHandle,'CData',userData.imData);
        end
    end
        
    if userData.imRectHandle.isvalid
        % Update the imrect position
        setPosition(userData.imRectHandle,userData.cropROI)
    else 
        % Create a new imrect object and store the handle
        userData.imRectHandle = imrect(get(imHandle,'Parent'),userData.cropROI);
        fcn = makeConstrainToRectFcn('imrect',get(imHandle,'XData'),get(imHandle,'YData'));
        setPositionConstraintFcn(userData.imRectHandle,fcn);
    end
else
    % Save the roi if applicable
    if userData.imRectHandle.isvalid 
        userData.cropROI=getPosition(userData.imRectHandle); 
    end
    % Close the figure if applicable
    if ishandle(userData.previewFig), delete(userData.previewFig); end
end
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);



function close_previewFig(hObject, eventdata)
handles = guidata(get(hObject,'UserData'));
set(handles.checkbox_crop,'Value',0);
update_data(handles.checkbox_crop, eventdata, handles);



% --- Executes on slider movement.
function frameNumberEdition_Callback(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');

% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_frameNumber')
    frameNumber = str2double(get(handles.edit_frameNumber, 'String'));
else
    frameNumber = get(handles.slider_frameNumber, 'Value');
end
frameNumber=round(frameNumber);

% Check the validity of the frame values
if isnan(frameNumber)
    warndlg('Please provide a valid frame value.','Setting Error','modal');
end
frameNumber = min(max(frameNumber,1),userData.nFrames);

% Store value
set(handles.slider_frameNumber,'Value',frameNumber);
set(handles.edit_frameNumber,'String',frameNumber);

% Save data and update graphics
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);
update_data(hObject,eventdata,handles);



% --- Executes on button press in pushbutton_crop.
function pushbutton_crop_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');

% Read cropROI if crop window is still visible
if userData.imRectHandle.isvalid
    userData.cropROI=getPosition(userData.imRectHandle);
end

% update crop ROI positions on GUI
set(handles.edit_cropROIpositions, 'String',num2str(round(userData.cropROI)))

% delete previewFig window
if isfield(userData, 'previewFig') && ishandle(userData.previewFig)
   delete(userData.previewFig) 
end



% --- Executes on key press with focus on pushbutton_crop and none of its controls.
function pushbutton_crop_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_crop, [], handles);
end