function varargout = transformCreationGUI(varargin)
% TRANSFORMCREATIONGUI M-file for transformCreationGUI.fig
%      TRANSFORMCREATIONGUI, by itself, creates a new TRANSFORMCREATIONGUI or raises the existing
%      singleton*.
%
%      H = TRANSFORMCREATIONGUI returns the handle to a new TRANSFORMCREATIONGUI or the handle to
%      the existing singleton*.
%
%      TRANSFORMCREATIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRANSFORMCREATIONGUI.M with the given input arguments.
%
%      TRANSFORMCREATIONGUI('Property','Value',...) creates a new TRANSFORMCREATIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before transformCreationGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to transformCreationGUI_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help transformCreationGUI

% Last Modified by GUIDE v2.5 30-Mar-2011 20:53:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @transformCreationGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @transformCreationGUI_OutputFcn, ...
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


% --- Executes just before transformCreationGUI is made visible.
function transformCreationGUI_OpeningFcn(hObject, eventdata, handles, varargin)
%
% transformCreationGUI('mainFig', handles.figure1) - call from movieSelector
% Useful tools:
%
% User Data:
% 
% userData.initXformFig - handles of initial transform result figure
% userData.XformFig - handles of initial transform result figure
% userData.iconHelpFig - handle of help dialog
%
%
%

set(handles.text_copyright, 'String', getLCCBCopyright());

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
% Choose default command line output for transformCreationGUI
handles.output = hObject;

% Set userData default values
userData.defaultPath ='';
userData.inImage =[];
userData.baseImage =[];
userData.initXform = [];
userData.beadRad = [];

% Load help icon from dialogicons.mat
userData = loadLCCBIcons(userData);
supermap(1,:) = get(hObject,'color');

userData.colormap = supermap;

axes(handles.axes_help);
Img = image(userData.questIconData);
set(hObject,'colormap',supermap);
set(gca, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'),...
    'visible','off');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn,...
    'UserData', struct('class', mfilename))

set(handles.text_status,'String','','Visible','on')

% Update handles structure
set(handles.figure1,'UserData',userData)
guidata(hObject, handles);

update_buttons(hObject, handles)
% UIWAIT makes transformCreationGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = transformCreationGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

userData = get(handles.figure1,'UserData');
if isempty(userData), userData = struct(); end

[saveName,saveDir] = uiputfile('*.mat','Save your transform:');      
if ~isequal(saveDir,0) && ~isequal(saveName,0)
    save([saveDir saveName],'-struct','userData','xForm');
end

% % Delete current window
% delete(handles.figure1)

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% Delete help window if loaded
if isfield(userData, 'iconHelpFig') && ishandle(userData.iconHelpFig)
   delete(userData.iconHelpFig) 
end


% --- Executes on button press in pushbutton_select_image.
function pushbutton_select_image_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_select_baseImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% Determine the type of image for the pushbutton tag
pushbuttonTag=get(hObject,'Tag');
imageTag = pushbuttonTag(length('pushbutton_select_')+1:end);
imageName = regexprep(imageTag,'([A-Z])',' ${lower($1)}');

% Launch the file selector and test the user output
[filename,filepath] = uigetfile({'*.tif';'*.TIF';'*.tiff';'*.TIFF'},...
                           ['Select the ' imageName ' file:'],userData.defaultPath);
if isequal(filename,0), return; end

%Attempt to load it
try
    userData.(imageTag) = imread([filepath filesep filename]);
catch ME
    errordlg(['Could not load ' imageName '! Error: ' ME.message])
end
userData.defaultPath = filepath;

% Update the edit controls
imageEditTag=['edit_' imageTag];
set(handles.(imageEditTag),'String',[filepath filename])

set(handles.figure1,'UserData',userData);
guidata(hObject, handles);
update_buttons(hObject, handles)

% --- Executes on button press in checkbox_doRefine.
function checkbox_doRefine_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_doRefine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_doRefine
update_buttons(hObject, handles)


% --- Executes on button press in pushbutton_select_initXform.
function pushbutton_select_initXform_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_select_initXform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

[filename,pathname] = uigetfile({'*.mat'},...
                           'Select the initial transformation file:',userData.defaultPath);
if isequal(filename,0)
    error('You must specify an input MAT file to continue!')
end

%Attempt to load it
try
    vars = whos('-file', [pathname filename]);  % - Exception: fail to access .mat file
catch ME
    errordlg('lccb:transformCreation',ME.message,'Fail to open MAT file.','modal');
    return;
end

% Check the existence of structures in the MAT file
structVars = vars( logical(strcmp({vars(:).class},'struct')) );
if isempty(structVars)
    errordlg('No imagetransform is found in selected MAT-file.',...
            'MAT File Error','modal');
    return
end

% Load the first structure and save it
S=load([pathname filename],'-mat',structVars(1).name);
userData.initXform=S.(structVars(1).name);

% Check initXform is a valid transform
if ~istransform(userData.initXform)
    userData.initXform=[];
    errordlg('The selected MAT-file is not a valid transformation.',...
            'MAT File Error','modal');
end

set(handles.edit_initXform,'String',[pathname filename]);
set(handles.figure1,'UserData',userData);
guidata(hObject, handles);

update_buttons(hObject, handles)

function edit_beadRad_Callback(hObject, eventdata, handles)
% hObject    handle to edit_beadRad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_beadRad as text
%        str2double(get(hObject,'String')) returns contents of edit_beadRad as a double
userData = get(handles.figure1,'UserData');
if isempty(userData), userData = struct(); end
beadRad=str2double(get(hObject,'String'));
if isnan(beadRad) || beadRad < 1
    errordlg('Invalid bead radius! Need bead radius to perform detection!');
    userData.beadRad=[];    
else
    userData.beadRad=beadRad;
end
set(handles.figure1,'UserData',userData);
guidata(hObject, handles);

update_buttons(hObject, handles)

% --- Executes when selected object is changed in uipanel_initTransform.
function uipanel_initTransform_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel_initTransform 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
update_buttons(hObject, handles)

% --- Executes on selection change in popupmenu_initXformMethod.
function popupmenu_initXformMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_initXformMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_initXformMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_initXformMethod
update_buttons(hObject, handles)

function update_buttons(hObject, handles)
% This function is called whenever a uicontrol is modified. It updates the
% various states of the GUI components.

%% Load all the button/popup-menu states and store them in userData
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
userData.doInit = get(handles.radiobutton_doInit,'Value');
userData.useInitXform = get(handles.radiobutton_initXform,'Value');
userData.doRefine = get(handles.checkbox_doRefine,'Value');
props = get(handles.popupmenu_initXformMethod,{'String','Value'});
userData.initXformMethod =props{1}{props{2}};
xFormTypes= get(handles.popupmenu_xFormType,'String');
userData.xFormType = xFormTypes{get(handles.popupmenu_xFormType,'Value')};
 
%% Enable/disable uipanels based on the selection of the radiobuttons
% Set the state of the initial calculation panel
if userData.doInit
    set(get(handles.uipanel_doInit,'Children'),'Enable','on')
    if strcmp(userData.initXformMethod,'Spot Detection')
        set(handles.edit_beadRad,'Enable','on')
    else
        set(handles.edit_beadRad,'Enable','off')
    end
else
    set(get(handles.uipanel_doInit,'Children'),'Enable','off')
end

% Set the state of the initial transformation loading panel
if get(handles.radiobutton_initXform,'Value')
    set(get(handles.uipanel_initXform,'Children'),'Enable','on')
else
    set(get(handles.uipanel_initXform,'Children'),'Enable','off')
end

%% Check if transformation can be calculated
% Check existence of base and input image
imCheck = ~(isempty(userData.inImage) || isempty(userData.baseImage));
% Check either refine or generate initial transformation is selected
opCheck= userData.doInit || userData.doRefine;
% Check initial transformation is loaded if using an external file
initXformCheck= ~userData.useInitXform || (userData.useInitXform && ~isempty(userData.initXform));
% Check the bead radius parameter is set up if using the spot detection
% method
doInitCheck= ~(userData.doInit && strcmp(userData.initXformMethod,'Spot Detection') && isempty(userData.beadRad));

% Set the state of the calculate pushbutton
if imCheck && opCheck && initXformCheck && doInitCheck
    set(handles.pushbutton_calculate,'Enable','on')
else
    set(handles.pushbutton_calculate,'Enable','off')
end

set(handles.figure1,'UserData',userData);
guidata(hObject, handles);

% --- Executes on button press in pushbutton_calculate.
function pushbutton_calculate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_calculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

%% ------------- Initial Transformation ----------- %%
    
if userData.doInit
          
    switch userData.initXformMethod
        
        %Let the user manually click on both pictures to produce initial
        %transformation
        case 'Manually'
            
            %Let the user know whats going on
            waitHan = msgbox('After you click "Ok", you will be shown both of the images you want to align. You must click on several points (Called control points) in both images, so that the two images can be aligned based on these points. The more points you click, the better the resulting transform will be! The minimum # of pairs of points for projective transforms is 4 and for polynomial it is 10. Try to spread the points out evenly over the image area, as this will also improve the resulting transformation. Simply close the control-point selection window when you are finished to continue generating the transform.');
            uiwait(waitHan);            
            
            %Call this but scale the images first because it displays to
            %the whole range            
            [cpIn,cpBase]= cpselect(mat2gray(userData.inImage),mat2gray(userData.baseImage),'Wait',true);
               
            if ~isempty(cpIn) && ~isempty(cpBase)
                set(handles.text_status,'String','Please wait, calculating initial transform...');
                if strcmp(userData.xFormType,'polynomial')
                    %Use second-order polynomial
                    userData.initXform = cp2tform(cpIn,cpBase,userData.xFormType,2);
                else
                    userData.initXform = cp2tform(cpIn,cpBase,userData.xFormType);
                end
            end
        case 'Spot Detection'
                    
            set(handles.text_status,'String','Please wait, calculating initial transform...');
            drawnow
            try
                
                %Call the bead-alignment routine
                userData.initXform = getTransformFromBeadImages(userData.baseImage,userData.inImage,userData.xFormType,userData.beadRad,1);
            catch em
                errordlg(['The bead-detection based alignment failed! Try manual-alignment or different images! Error : ' em.message])
                set(handles.text_status,'String','')
                return
            end
            
            
        otherwise
            disp('No initial transform used!')          
    
    end
    
    set(handles.text_status,'String','')
    %Show the pre- and post-initial transform alignment, if one was created
    if isfield(userData, 'initXformFig') && ishandle(userData.initXformFig)
        delete(userData.initXformFig) 
    end
    
    userData.initXformFig = fsFigure(.75);
    if ~isempty(userData.initXform)
        subplot(1,2,1)
    end
    image(cat(3,mat2gray(userData.baseImage),mat2gray(userData.inImage),zeros(size(userData.baseImage))));
    hold on,axis image,axis off
    title('Overlay, before any transformation. Red: base, Green: Input')    
    if ~isempty(userData.initXform)
        subplot(1,2,2)        
        xIn = imtransform(userData.inImage,userData.initXform,'XData',[1 size(userData.baseImage,2)],...
                                            'YData',[1 size(userData.baseImage,1)]);
        image(cat(3,mat2gray(userData.baseImage),mat2gray(xIn),zeros(size(userData.baseImage))));
        hold on,axis image,axis off
        title('Overlay, after initial transformation');
    end
    drawnow
    
end


%% ------------- Transformation Refinement ------------ %%

if userData.doRefine
    set(handles.text_status,'String','Please wait, refining initial transform...') 
    drawnow;
    warndlg('The refinement process may take several minutes to complete. Please be patient.','modal');

    if ~isempty(userData.initXform)
        %If possible, use the initial transformation as initial guess for
        %refinement
        
        switch userData.xFormType
            
            case 'projective'
                userData.xForm = findOptimalXform(userData.baseImage,userData.inImage,0,userData.xFormType,userData.initXform.tdata.T);    
                
            case 'polynomial'
                userData.xForm = findOptimalXform(userData.baseImage,userData.inImage,0,userData.xFormType,userData.initXform.tdata);    
                
            otherwise
                error(['"' userData.xFormType '" is not a supported transform type!'])
        end
                
    else
        userData.xForm = findOptimalXform(userData.baseImage,userData.inImage,0,userData.xFormType);            
    end
    
else        
    userData.xForm = userData.initXform;
end

set(handles.text_status,'String','')

if isempty(userData.xForm)
    errordlg('The transform refinement failed! Try: a different initial guess, different images, different transform type. Sorry!')
else

    %Show the pre- and post-final transform alignment, if one was created
    if isfield(userData, 'initXformFig') && ishandle(userData.initXformFig)
        delete(userData.initXformFig) 
    end
    userData.initXformFig = fsFigure(.75);
    xIn = imtransform(userData.inImage,userData.xForm,'XData',[1 size(userData.baseImage,2)],...
                                    'YData',[1 size(userData.baseImage,1)]);
    image(cat(3,mat2gray(userData.baseImage),mat2gray(xIn),zeros(size(userData.baseImage))));
    hold on,axis image,axis off
    title('Overlay, after refined transformation');
end
set(handles.figure1,'UserData',userData);
guidata(hObject, handles);

    
