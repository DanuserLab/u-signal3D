function varargout = imageViewer(movieData,varargin)
%IMAGEVIEWER displays images from the input movie
%
% imageViewer(movieData)
%
% imageViewer(movieData,'OptionName',optionvalue,...)
%
% figHan = imageViewer(movieData)
%
%
% Displays an image from the input movie data at the specified frame number
% and channe, or if multiple channels are specified, displays an overlay of
% these channels (up to 3). If no frame number or channel is specified, the
% first image in the first channel is displayed.
%
% Input:
%
%   movieData - the MovieData object describing the movie to view an image
%   from, as created using setupMovieDataGUI.m
%
%   'OptionName',optionValue - A string with an option name followed by the
%   value for that option.
%
%   Possible Option Names:
%
%       ('OptionName' -> possible values)
%
%       ('ChannelIndex' -> positive integer scalar or vector) The index of
%       the channel(s) to display image(s) from. This index corresponds to
%       the channel's location in the array movieData.channels_.
%       Optional. If not specified, channel 1 is displayed.
%
%       ('Frame' -> positive integer)
%       This option specifies the frame number of the image to display.
%       Optional. Default is to display frame 1.
%
%       ('ColorMap' -> matlab colormap)
%       This option specifies a matlab built-in colormap such as jet or
%       cool to use when displaying the image.
%       NOTE: When displaying multiple channels, this option has no effect.
%       Optional. Default is gray.
%
%       ('Saturate' -> Positive scalar >= 0 and < 1) This specifies the
%       fraction of the intensity values to allow to appear saturated in
%       the displayed image. That is, if it is set to 0 the color scale
%       will cover the entire range of the ratio values, from maximum to
%       minimum (no saturation). If it is set to .05, then 95% of the data
%       will fit between the max and min of the color scale, but values
%       outside this range will be saturated. Smaller values for this
%       parameter will make small variations in intensity areas easier to
%       see, but will saturate very bright/dim areas. Default is 0 (no
%       saturation).
%
%       ('AxesHandle' -> axes handle)
%       The handle of the axes to display the image on.
%       Optional. If not specified, a new figure is created.
%
%       ('ProcessIndex' -> Positive integer scalar)
%       This specifies the index of the image processing process to display
%       output from in the array movieData.processes_; This must be the
%       index of a valide ImageProcessingProcess (or child), which has
%       output images for the channels specified by ChannelIndex.
%
%       ('SegProcessIndex' -> Positive integer scalar) This specifies the
%       index of the segmentation process to display masks from, **if the
%       mask overlay is enabled - see below**. This is only necessary if
%       more than one segmentatin process exists. If not specified, and
%       more than one segmentation process exists, the user will be asked.
%
%       ('Overlay' -> character array)
%       A string containing the name of something to overlay on the image.
%       Optional. If not specified, nothing is overlain.
%
%         Possible overlay options are:
%
%           'Mask' - Overlays the outline of the mask for the displayed
%                    image. See SegProcessIndex option above.
%
%           'Windows' - If the movie has been windowed using
%                       getMovieWindows.m then the windows for the
%                       specified frame will be overlain on the image.
%
%           'Protrusion' - If the movie has had protrusion vectors
%                          calculated using getMovieProtrusion.m, the
%                          vectors for the specified frame will be
%                          overlain on the image.
%
%           'Windows+Protrusion' - 'Windows' and 'Protrusion' together.
%
%       ('Tool'->true/false) If true, the imtool.m function will be used to
%       display the image instead of imshow. This allows viewing pixel
%       values, adjustment of contrast etc.
%       Optional. Default is false.
%
% Output:
%
%   The requested images will be displayed along with any requested
%   overlay.
%
%   figHandle - the handle to the figure the images were displayed on.
%
%
% Hunter Elliott
% Revamped 1/2010
% Rerevamped 6/2010 ;)
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

%% ----- Parameters ------ %%

colStr = {'r','g','b'}; %The color to use for overlays.


%% ----------------- Input -------------- %%

if nargin < 1
    error('Must input a movieData structure!')
end

%Check the movieData
if ~isa(movieData,'MovieData')
    error('The first input must be a valid MovieData object! Check input!')
end

%Parse the optional inputs
[iChan,iFrame,cMap,satAmt,axHandle,iProc,iSegProc,overlayName,useTool] = parseInput(varargin);

%----Defaults----%

if isempty(iChan)
    iChan = 1; %Default is to use first channel.
    nChan = 1;
else
    nChan = length(iChan);
end

nChanTot = numel(movieData.channels_);

if ~isnumeric(iChan) || max(iChan) > nChanTot || ...
        min(iChan) < 1 || ~isequal(round(iChan),iChan)
    error('Invalid channel indices! Please check the iChan option!')
end

if isempty(satAmt)
    satAmt = 0;
elseif satAmt < 0 || satAmt >= 1 || numel(satAmt) ~= 1
    error('Invalid saturation parameter! Must be a single value greater than or equal to zero and less than 1!');
end

if nChan > 3
    error('ImageViewer.m can only display up to 3 channels simultaneously! Please specify fewer channels!')
end

if isempty(iFrame)
    iFrame = 1;%Default is to display first frame
elseif ~isnumeric(iFrame) || round(iFrame) ~= iFrame || any(iFrame > movieData.nFrames_)
    error('Invalid frame number specified! Check the "Frame" option!')
end

if isempty(useTool)
    useTool = false;
end

%If no handle given, create figure
if ~useTool
    if isempty(axHandle)
        figHandle = figure;
        handleInput = false;
    elseif ishandle(axHandle)
        %If axes handle given, get the figure handle for it
        figHandle = get(axHandle,'Parent');
        cla(axHandle);
        handleInput = true;
    else
        error('Specified axes handle is not a valid handle!')
    end
end


%% --------- Init ------- %%

%Load the image(s) to display

currImage = cell(1,nChan);
%Check the process
if ~isempty(iProc)
    nProc = numel(movieData.processes_);
    if iProc <= nProc && iProc > 0 && round(iProc) == iProc
        
        %Make sure that the process is an ImageProcessingProcess
        if ~isa(movieData.processes_{iProc},'ImageProcessingProcess')
            error('The process specified by ProcessIndex is not an ImageProcessingProcess!')
        end
        %Check which channels have been processed
        if ~all(movieData.processes_{iProc}.checkChannelOutput(iChan))
            error('The channels specified by ChannelIndex have not all been processed successfully by the process specified by ProcessIndex! Please check input!')
        end
    else
        error('Invalid process index specified! Please check the ProcessIndex option!')
    end
    
    for j = 1:nChan
        %load the image(s)
        currImage{j} = movieData.processes_{iProc}.loadOutImage(iChan(j),iFrame);
    end
    
else
    %Use the raw data as the image directories
    imDirs = movieData.getChannelPaths(iChan);
    imNames = movieData.getImageFileNames(iChan);
    
    %Load the image(s).
    for j = 1:nChan
        %load the image
        currImage{j} = imread([imDirs{j} filesep imNames{j}{iFrame}]);
    end
    
end

%% ------- Scale Image ------- %%
%Scales muliple channels to similar ranges, and saturates some pixels if
%saturation is enabled.

for j = 1:nChan
    
    if satAmt > 0
        
        %Find the max and minimum values to saturate at. we exclude zero
        %values from the distribution in case the image has been background
        %subtracted or masked
        [pdf,binX] = hist(double(currImage{j}(currImage{j}~=0)),1e4);
        cdf = cumsum(pdf) ./ sum(pdf);
        minVal = binX(find(cdf>(satAmt/2),1,'first'));
        maxVal = binX(find(cdf>=(1-(satAmt/2)),1,'first'));
        
        %We have to saturate it ourselves, because this is general to RGB
        %and because imadjust.m fucks with all the values, not just the
        %saturated ones.
        currImage{j}(currImage{j}(:)>maxVal) = maxVal;
        currImage{j}(currImage{j}(:)<minVal) = minVal;
        
    end
    
end

if nChan > 1
    
    temp = zeros([size(currImage{1}) 3]);
    for j = 1:nChan
        %We need to scale between 0 and 1 for RGB display
        temp(:,:,j) = mat2gray(currImage{j});
    end
    currImage = temp;
else
    currImage = currImage{1};
end

%% -------- Draw the image ---------%%

%Make sure we are (still) on the correct figure & axes
if ~useTool
    figure(figHandle)
    if ~isempty(axHandle)
        set(figHandle,'CurrentAxes',axHandle)
    end
end

%Display the image
if useTool
    imtool(currImage,[])
elseif ~handleInput
    %If we created a figure, size it to fit the image.
    imshow(currImage,[])
else
    %If the user input it, use their image size
    imagesc(currImage);
    axis image, axis off, colormap gray
    set(axHandle, 'Units', 'normalized', 'Position', [0 0 1 1]);
end

%If the axes didn't exist before, get it's handle now
if isempty(axHandle) && ~useTool
    axHandle = get(figHandle,'CurrentAxes');
end

%If requested, change the colormap
if ~isempty(cMap)
    if any(isnan(currImage))
        c = colormap(cMap);
        cMap = [0 0 0; c];
    end
    colormap(cMap)%NOTE: This has no effect when displaying multiple channels
end


%% ---Draw the overlays---- %%

if ~useTool
    
    %Draw the channel name
    arrayfun(@(x)(text(20,20*x,['Channel ' num2str(iChan(x))],'color',colStr{x},'interpreter','none')),1:nChan);
    
    %Draw the frame number, or time in seconds if available
    if ~isempty(movieData.timeInterval_)
        text(20,80,[num2str((iFrame-1)*movieData.timeInterval_) ' / ' ...
            num2str((movieData.nFrames_-1)*movieData.timeInterval_) ' s' ],'color',colStr{1},'FontSize',12)
    else
        text(20,80,[num2str(iFrame) ' / ' num2str(movieData.nFrames_)],...
            'color',colStr{1},'FontSize',12)
    end
end

if ~useTool && ~isempty(overlayName)
    %Get the current axes and turn hold on
    hold(axHandle,'on')
    
    switch overlayName
        
        case 'Mask'
            
            if isempty(iSegProc)
                %Find the segmentation process
                iSegProc = movieData.getProcessIndex('MaskProcess',1,1);
                
                %Make sure the specified process is a valid segmentation
                %process
            elseif ~isa(movieData.processes_{iSegProc},'MaskProcess')
                error('The process specified by SegProcessIndex is not a valid MaskProcess!')
            end
            
            if isempty(iSegProc)
                error('Cannot display masks: MovieData does not have any MaskProcesses Please create masks first!');
            end
            
            %Check if the specific channels have masks/are okay
            hasMasks = movieData.processes_{iSegProc}.checkChannelOutput(iChan);
            
            for j = 1:nChan
                if hasMasks(j)
                    
                    maskNames = movieData.processes_{iSegProc}.getOutMaskFileNames(iChan(j));
                    
                    %Load the mask
                    currMask = imread([ ...
                        movieData.processes_{iSegProc}.outFilePaths_{iChan(j)},...
                        filesep maskNames{1}{iFrame}]);
                    
                    %Convert the mask into a boundary
                    maskBounds = bwboundaries(currMask);
                    
                    %Plot the boundar(ies)
                    cellfun(@(x)(plot(x(:,2),x(:,1),colStr{j})),maskBounds);
                else
                    disp('No valid masks for specified channel(s)! Check movieData.masks and mask directory/files!')
                end
            end
            
        case 'Windows'
            
            iWinProc = movieData.getProcessIndex('WindowingProcess',1,1);
            
            if isempty(iWinProc) || ~movieData.processes_{iWinProc}.checkChannelOutput;
                error('The window overlay cannot be displayed because the movieData does not have a valid WindowingProcess! Please run windowing !')
            end
            wins = movieData.processes_{iWinProc}.loadChannelOutput(iFrame);
            plotWindows(wins,{'r','FaceAlpha',.3','EdgeColor','y'});
            
        case 'Protrusion'
            
            iProtProc = movieData.getProcessIndex('ProtrusionProcess',1,1);
            if isempty(iProtProc) || ~movieData.processes_{iProtProc}.checkChannelOutput
                error('The protrusion overlay cannot be displayed because the movieData does not have a valid ProtrusionProcess!')
            end
            if iFrame == movieData.nFrames_
                warning('MovieManagement:ImageViewer:noProtrusion',...
                    'Last frame does not have protrusion vectors, can''t display protrusion overlay.')
            else
                prots = movieData.processes_{iProtProc}.loadChannelOutput;
                plot(prots.smoothedEdge{iFrame}(:,1),prots.smoothedEdge{iFrame}(:,2),'y')
                quiver(prots.smoothedEdge{iFrame}(:,1),prots.smoothedEdge{iFrame}(:,2),...
                    prots.protrusion{iFrame}(:,1),prots.protrusion{iFrame}(:,2),0);
            end
            
        case 'Windows+Protrusion'
            
            iWinProc = movieData.getProcessIndex('WindowingProcess',1,1);
            
            if isempty(iWinProc) || ~movieData.processes_{iWinProc}.checkChannelOutput;
                error('The window overlay cannot be displayed because the movieData does not have a valid WindowingProcess! Please run windowing !')
            end
            wins = movieData.processes_{iWinProc}.loadChannelOutput(iFrame);
            plotWindows(wins,{'r','FaceAlpha',.3','EdgeColor','y'},3);
            
            iProtProc = movieData.getProcessIndex('ProtrusionProcess',1,1);
            if isempty(iProtProc) || ~movieData.processes_{iProtProc}.checkChannelOutput
                error('The protrusion overlay cannot be displayed because the movieData does not have a valid ProtrusionProcess!')
            end
            if iFrame == movieData.nFrames_
                warning('MovieManagement:ImageViewer:noProtrusion',...
                    'Last frame does not have protrusion vectors, can''t display protrusion overlay.')
            else
                prots = movieData.processes_{iProtProc}.loadChannelOutput;
                plot(prots.smoothedEdge{iFrame}(:,1),prots.smoothedEdge{iFrame}(:,2),'b')
                quiver(prots.smoothedEdge{iFrame}(:,1),prots.smoothedEdge{iFrame}(:,2),...
                    prots.protrusion{iFrame}(:,1),prots.protrusion{iFrame}(:,2),0);
            end
            
        otherwise
            
            disp(['"' overlayName '" is not a recognized overlay type!'])
            
    end
elseif useTool && ~isempty(overlayName)
    error('Overlays are not allowed with the imtool is used for display! Disable the "Tool" option!')
end

if nargout > 0
    varargout{1} = figHandle;
end

function [iChan,iFrame,cMap,satAmt,axHan,iProc,iSegProc,overlayName,useTool] = parseInput(argArray)

iChan = [];
iFrame = [];
cMap = [];
satAmt = [];
axHan = [];
iProc = [];
iSegProc = [];
overlayName = [];
useTool = [];

if isempty(argArray)
    return
end

nArg = length(argArray);

%Make sure there is an even number of arguments corresponding to
%optionName/value pairs
if mod(nArg,2) ~= 0
    error('Inputs must be as optionName / value pairs!')
end

for i = 1:2:nArg
    
    
    switch argArray{i}
        
        
        case 'ChannelIndex'
            iChan = argArray{i+1};
            
        case 'Frame'
            iFrame = argArray{i+1};
            
        case 'ColorMap'
            cMap = argArray{i+1};
            
        case 'Saturate'
            satAmt = argArray{i+1};
            
        case 'AxesHandle'
            axHan = argArray{i+1};
            
        case 'ProcessIndex'
            iProc = argArray{i+1};
            
        case 'Overlay'
            overlayName = argArray{i+1};
            
        case 'SegProcessIndex'
            iSegProc = argArray{i+1};
            
        case 'Tool'
            useTool = argArray{i+1};
            
        otherwise
            
            error(['"' argArray{i} '" is not a valid option name! Please check input!'])
    end
end
