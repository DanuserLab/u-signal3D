function makeMovieMovie(movieData,varargin)
%MAKEMOVIEMOVIE create .avi or .mov (quicktime) movie of images for the input movie, with optional overlays
%
%   makeMovieMovie(movieData)
%   makeMovieMovie(movieData,'OptionName1',optionValue1,'OptionName2',optionValue2,...)
%
%   This function creates a .avi or .mov (quicktime) file from images in
%   the input movie. The images can be from a single channel or 2-3
%   channels as an RGB overlay. Additionally, certain image analysis
%   results can be overlain on each frame in the output movie. This
%   function uses the function imageViewer.m for image and image overlay
%   display.
% 
%   This function unifies and replaces a bunch of other confusing, shitty
%   functions which served similar purposes such as:
%       makeMaskMovie.m
%       makeActivityMovie.m
%       makeWindowTestingMovie.m
%       makeWindowOverlay.m
%       ....
%
% Input:
% 
%   movieData - The MovieData object describing the movie to make a .avi or
%   .mov from, as created using movieSelectorGUI.m
% 
%   'OptionName',optionValue - A string with an option name followed by the
%   value for that option. 
%
%     Possible option name/value pairs:
%
%       ('ConstantScale' -> true/false) If true, the display range (color axis
%       limits) selected for the first image will be used throughout the
%       movie. If false, the range will be selected sparately for each
%       frame.
%       *NOTE*: This option currently only works when a single channel is
%       displayed.
%
%       ('ColorBar' -> true/false) If true, a bar showing the color scale
%       (that is the value associated with each color in the movie) will be
%       displayed. Optional. Default is false (no color bar).
%       NOTE: This option will always be disabled (false) when more than
%       one channel is displayed.
%
%       ('FileName'-> Character array) String specifying file name to save
%       movie as.
%       Optional. Default is "activityMovie"
%
%       ('AxesHandle' -> scalar axis handle) Specifies the axes handle to
%       display the images on. The size of these axes will determine the
%       size of the output movie.
%
%       ('MakeAvi' -> Logical scalar) If true, the movie will be saved as .avi.
%       Optional. Default is false.
%
%       ('MakeMov' -> Logical scalar) If true, movie will be saved as .mov.
%       Optional. Default is true.             
%
%       **NOTE** Additional options and possible values are all described
%       in the help for imageViewer.m. This includes channel specification,
%       image overlays, colormaps etc.
%
%
% Output:  
%   
%   Each frame of the selected channel(s) will be displayed sequentially,
%   along with any selected overlays. These frames will all be then saved
%   to a .avi and/or .mov file in the movie's specified outputDirectory,
%   with the filename specified by the FileName option
% 
%
%
% Hunter Elliott
% 9/2010
%
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

%% ------------- Input -------------- %%

if nargin < 1 || ~isa(movieData,'MovieData')
    error('The first input must be a valid MovieData object!')
end

[constRange,cBar,fName,makeAvi,makeMov,imviewArgs] = parseInput(varargin);


% ---- Defaults ---- %

if isempty(constRange)
    constRange = false;
end
if isempty(cBar)
    cBar = false;
end
if isempty(fName)
    fName = 'activityMovie';
end
if isempty(makeAvi)
    makeAvi = false;
end
if isempty(makeMov)
    makeMov = true;
end


%% ------------- Init ----------------- %%

nImages = movieData.nFrames_;

%Check if protrusion overlay was requested and disable warning
if any(strcmp('Protrusion',imviewArgs))
    warning('off','MovieManagement:ImageViewer:noProtrusion');
end

%If the user didn't specify an axes handle, we need to pass one to avoid
%creating new figures for each frame
if ~any(strcmp('AxesHandle',imviewArgs))
    figHan = figure;
    axHan = gca;
    imviewArgs = [imviewArgs {'AxesHandle',axHan}];
end

%% ------ Movie Making ----- %%


for iImage = 1:nImages
       
    
    figHan = imageViewer(movieData,'Frame',iImage,imviewArgs{:});
                       
        
    if constRange
        if iImage == 1
            clim = caxis;
            imviewArgs(end+1:end+2) = {'Saturate',0}; %Disable saturation after first frame if constant scale is enabled.
        else
            caxis(clim);
        end
    end
    
    if cBar
        %Display a color scale bar
        colorbar
    end
    
    if makeMov        
        if iImage == 1
            MakeQTMovie('start',[movieData.outputDirectory_ filesep fName '.mov'])
            MakeQTMovie('quality',.9)
        end   
        MakeQTMovie('addfigure')    
    end
    
    if makeAvi
        movieFrames(iImage) = getframe(figHan);  %#ok<AGROW> You don't have to initialize with getframe. I promise ;)
    end
    
end



%% ----- Finalization ---- %%

if makeMov
    MakeQTMovie('finish')
end
if makeAvi
    v = VideoWriter([movieData.outputDirectory_ filesep fName '.avi']);
    open(v);
    writeVideo(v, movieFrames);
    close(v);
end


if ishandle(figHan)%Make sure the user hasn't closed it already.
    close(figHan);
end

%Re-enable the warning for protrusion
if any(strcmp('Protrusion',imviewArgs))
    warning('on','MovieManagement:ImageViewer:noProtrusion');
end


function [constRange,cBar,fName,makeAvi,makeMov,imviewArgs] = parseInput(argArray)
%Sub-function for parsing variable input arguments



%-----Defaults-----%
constRange = [];
cBar = [];
fName = [];
makeAvi = [];
makeMov = [];
imviewArgs = {};

if isempty(argArray)
    return
end

nArg = length(argArray);


%Make sure there is an even number of arguments corresponding to
%optionName/value pairs
if mod(nArg,2) ~= 0
    error('Inputs must be as optionName/ value pairs!')
end

for i = 1:2:nArg
    
   switch argArray{i}                     
                         
       
       case 'ConstantScale'
           
           constRange = argArray{i+1};
           
       case 'ColorBar'
           cBar = argArray{i+1};
           
       case 'FileName'
           fName = argArray{i+1};
           
       case 'MakeAvi'
           makeAvi = argArray{i+1};
           
       case 'MakeMov'
           makeMov = argArray{i+1};
           
           
       otherwise
                  
           imviewArgs  = [imviewArgs argArray{i:i+1}]; %#ok<AGROW>
           
   end
               
      
   
end
