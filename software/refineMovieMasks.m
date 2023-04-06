function movieData = refineMovieMasks(movieDataOrProcess,paramsIn)
% REFINEMOVIEMASKS Performs post-processing to improve masks for an input movie.
% 
% movieData = refineMovieMasks(movieData)
% 
% movieData = refineMovieMasks(movieData,paramsIn)
% 
% 
% This function performs several post-processing steps to refine the masks
% for the input movie. The available post-processing steps are listed
% below.
% 
% Input:
% 
%   movieData - The movieData object describing the movie, as created using
%   setupMovieDataGUI.m
% 
%   paramsIn - Structure with inputs for optional parameters. The
%   parameters should be stored as fields in the structure, with the field
%   names and possible values as described below:
% 
%   Possible Parameter Structure Field Names:
%       ('FieldName' -> possible values)
%
%       ('ChannelIndex'-> Positive integer scalar or vector) 
%       The integer indices of the channel(s) to perform mask refinement
%       on. This index corresponds to the channel's location in
%       the array movieData.channels_. If not input, the user
%       will be asked to select from the available channels
%
%       ('SegProcessIndex' -> Positive integer scalar or vector) Optional.
%       This specifies MaskProcess(s) to use masks from by its
%       index in the array movieData.processes_; For each channel, masks
%       will be used from the last process specified which has valid masks
%       for that channel. That is if SegProcessIndex = [1 4] and both
%       processes 1 and 4 have masks for a given channel, then the masks
%       from process 4 will be used. If not input, and multiple
%       MaskProcesses are present, the user will be asked to select
%       one, unless batch mode is enabled in which case an error will be
%       generated.
%
%       ('OutputDirectory' -> character string)
%       Optional. A character string specifying the directory to save the
%       masks to. Masks for different channels will be saved as
%       sub-directories of this directory.
%       If not input, the masks will be saved to the same directory as the
%       movieData, in a sub-directory called "masks"
%
%       ('MaskCleanUp' -> True/False)
%       If true, various operations will be performed to clean up the
%       mask. The operations are listed below, and will be performed in the
%       order they are listed.
%       Optional. Default is True.
%
%       These operations include:
%
%           Clean-up Methods/Parameters:
%
%           ('MinimumSize' -> Positive integer scalar)
%           Any objects in the mask whose area is below this size (in
%           pixels) will be removed via morphological area opening.
%           Optional. Default is 10 pixels. Set to 0 to keep all objects.
%        
%           ('ClosureRadius' -> non-negative integer scalar)
%           If this is parameter greater than zero, the mask will be closed
%           using a disk-shaped structuring element of this radius. This
%           has the effect of connecting previously un-connected components
%           in the mask if they are within 2x this distance of one another.
%           Optional. Default is 3 pixels.
%
%           ('ObjectNumber -> Positive integer scalar)
%           Only this number of the largest objects in the mask will be
%           kept. That is, if this number is 2, only the two largest
%           objects will be kept. This step is performed AFTER the edge
%           refinement (if enabled)
%           Optional. Default is 1. Set to Inf to keep all objects.
%
%           ('FillHoles -> True/False)
%           If true, any holes in any objects in the mask will be filled
%           in.
%           Optional. Default is true.
%          
%           ('FillBoundaryHoles' -> True/False)
%           If true, if the mask is touching the image boundary on adjacent edges of the 
%           image, the hole in between the two image-edge-touching boundaries (e.g., in the corner) 
%           will be filled. 
%           If fasle, this space will not be filled.
%           Optional. Default is true.
%            
%           ('OpeningRadius -> non-negative integer scalar)
%           If this parameter is greater than zero, the mask will be eroded
%           then dilated using a disk-shaped structuring element of this radius. This
%           has the effect of removing spikes in the mask.
%           Optional. Default: 0, meaning do not perform.
%
%           ('SuppressBorder' -> True/False)
%           If true, mask pixels at the image border will always be false.
%           This prevents any mask objects from touching the image border.
%           Optional. Default is false.
%
%       ('EdgeRefinement' -> True/False)
%       If true, edge detection will be used to refine the position of the
%       mask edge to the nearest detected edge in the image. This will be
%       done after any of the cleanup procedures listed above.
%       Optional. Default is False.
% 
%           Edge Refinement Parameters:
%
%           NOTE: For descriptions and default values, see refineMaskEdges.m           
%           
%           ('MaxEdgeAdjust' -> Positive Integer scalar)
%           
%           ('MaxEdgeGap' -> Positive integer scalar)
% 
%           ('PreEdgeGrow' -> Positive integer scalar)
%
%       ('BatchMode' -> True/False)
%       If this option value is set to true, all graphical output and user
%       interaction is suppressed.
%
% 
% Output:
% 
%   movieData - The modified movieData object, with the mask refinement
%   logged in it, including all parameters used.
% 
%   The refined masks will be written to sub-directories of the specified
%   output directory.
% 
% 
% Hunter Elliott 
% 1/2010
% Andrew R. Jamieson 6/2018 - Updated boundary hole filling behaviour
%
%% -------- Parameters ---------- %%
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

dName = 'refined_masks_for_channel_';%String for naming the mask directories for each channel
pString = 'refined_'; %Prefix for saving masks to file

%% ----------- Input --------- %%

if nargin < 1 || ~isProcessOrMovieData(movieDataOrProcess)
    error('The first input argument must be a valid MovieData object!')
end
if nargin < 2
    paramsIn = [];
end


% Get MovieData object and Process
[movieData, proc,iProc] = getOwnerAndProcess(movieDataOrProcess,'MaskRefinementProcess',true);

nChan = numel(movieData.channels_);


%Parse input, store in parameter structure
p = parseProcessParams(proc,paramsIn);


%----Param Check-----%

if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex),p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

nChanThresh = length(p.ChannelIndex);


if isempty(p.SegProcessIndex)    
    if p.BatchMode
        %If batch mode, just get all the seg processes
        p.SegProcessIndex = movieData.getProcessIndex('MaskProcess',Inf,0);            
        p.SegProcessIndex(p.SegProcessIndex == iProc) = [];
        if numel(p.SegProcessIndex) > 1
            error('In batch mode you must specify the SegProcessIndex if more than one MaskProcess is available!')
        end            
    else        
        %We need to exclude this function's process, and ask user if more
        %than one
        segProcList =  movieData.getProcessIndex('MaskProcess',Inf,true);
        segProcList(segProcList == iProc) = []; %Don't count this process
        iSegProc=1;
        if numel(segProcList) > 1
            procNames = cellfun(@(x)(x.getName),...
                        movieData.processes_(segProcList),'UniformOutput',false);
            iSegProc = listdlg('ListString',procNames,...
                               'SelectionMode','multiple',...
                               'ListSize',[400 400],...
                               'PromptString','Select the segmentation process(es) to use:');
            
        end
        p.SegProcessIndex = segProcList(iSegProc);        
    end
end

if isempty(p.SegProcessIndex) 
    error('This function requires that the input movie has already been segmented and that a valid MaskProcesses be specified!')
end

nProc = numel(p.SegProcessIndex);
hasMasks = false(nChanThresh,nProc);
%Check every specified process for masks
for j = 1:nProc

    %Make sure the specified process is a MaskProcess
    if ~isa(movieData.processes_{p.SegProcessIndex(j)},'MaskProcess')
        error(['The process specified by SegProcessIndex(' num2str(j) ') is not a MaskProcess!'])
    end

    %Check which channels have masks from this process
    hasMasks(:,j) = movieData.processes_{p.SegProcessIndex(j)}.checkChannelOutput(p.ChannelIndex);        

end


if p.ClosureRadius < 0 || ~isequal(round(p.ClosureRadius),p.ClosureRadius)
    error('The closure radius must be a non-negative integer!!')
end


%Make sure all the selected channels have foreground masks.
if any(~sum(hasMasks,2))
    warning('biosensors:refineMasks:noFGmasks',...
        'Cannot refine masks because some channels do not have foreground masks! Please segment these channels before refining masks!')
end


if ~(p.MaskCleanUp || p.EdgeRefinement)
    error('You must enable mask cleanup and/or edge refinement! Otherwise this function has nothing to do!')
end


%% ----------- Init ----------- %%



if p.EdgeRefinement %Images are only needed for edge-refinement
    imageNames = movieData.getImageFileNames(p.ChannelIndex);
end

if p.ClosureRadius > 0 %If closure is to be performed, create the structuring element
    seClose = strel('disk',p.ClosureRadius(1),0);
end

if p.OpeningRadius > 0
    seOpen = strel('disk',p.OpeningRadius(1),0);
end


nImages = movieData.nFrames_;
nImTot = nImages * nChanThresh;

%Set up the input and mask directories
inMaskDir = cell(1,nChanThresh);
outMaskDir = cell(1,nChanThresh);
maskNames = cell(1,nChanThresh);
for j = 1:nChanThresh;    
    
    %Get the most recent seg process with masks for this channel
    iP = p.SegProcessIndex(find(hasMasks(j,:),1,'last'));    
    maskNames(j) = movieData.processes_{iP}.getOutMaskFileNames(p.ChannelIndex(j));
    inMaskDir(j) = movieData.processes_{iP}.outFilePaths_(p.ChannelIndex(j));
    
    %Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex(j))];
        
    %Check/create directory
    mkClrDir(currDir)               
    
    %Save this in the process object
    movieData.processes_{iProc}.setOutMaskPath(p.ChannelIndex(j),currDir);
    movieData.processes_{iProc}.setInMaskPath(p.ChannelIndex(j),inMaskDir{j});
    outMaskDir{j} = currDir;
end


%% ---------------- Mask Refinement --------------- %%


if ~p.BatchMode && feature('ShowFigureWindows')
    wtBar = waitbar(0,['Please wait, refining masks for channel ' num2str(p.ChannelIndex(1)) ' ...']);     
else
    wtBar = -1;
end        

if p.EdgeRefinement
    currImDir = movieData.getChannelPaths(p.ChannelIndex);
end
    

disp('Starting mask refinement...')

for iChan = 1:nChanThresh

    disp(['Refining masks for channel ' num2str(p.ChannelIndex(iChan)) '...']);
    disp(['Using masks from ' inMaskDir{iChan} ', storing results in ' outMaskDir{iChan}])
    if p.EdgeRefinement
        disp(['For edge refinment, using images from ' currImDir{iChan}])
    end
    
    if ishandle(wtBar)       
        waitbar((iChan-1)*nImages / nImTot,wtBar,['Please wait, refining masks for channel ' num2str(p.ChannelIndex(iChan)) ' ...']);        
    end        
    
    
    
  
    for iImage = 1:nImages;
        
        %Load the mask for this frame/channel
        currMask = imread([inMaskDir{iChan} filesep maskNames{iChan}{iImage}]);        
        
        % ----- Mask Clean Up ------ %
        
        if p.MaskCleanUp

            %Remove objects that are too small
            if p.MinimumSize > 0
                currMask = bwareaopen(currMask,p.MinimumSize);
            end            
            
            %Perform initial closure operation
            if p.ClosureRadius > 0
                currMask = imclose(currMask,seClose);            
            end            
            
            %Perform initial opening operation
            if p.OpeningRadius > 0
                currMask = imopen(currMask,seOpen);
            end
            
        end
        
        
        % --------- Mask Edge-Refinement ------ %
        if p.EdgeRefinement
            
            %Load the current image
            currImage = imread([currImDir{iChan} filesep imageNames{iChan}{iImage}]);
            
            %Call the edge-refinement function
            currMask = refineMaskEdges(currMask,currImage,...
                p.MaxEdgeAdjust,p.MaxEdgeGap,p.PreEdgeGrow);
            
            
        end
        % ---------- Object Selection -------- %
        
        %Keep only the largest objects
        if p.MaskCleanUp && ~isinf(p.ObjectNumber)
                
            %Label all objects in the mask
            labelMask = bwlabel(currMask);

            %Get their area
            obAreas = regionprops(labelMask,'Area');       %#ok<MRPBW>

            %First, check that there are objects to remove
            if length(obAreas) > p.ObjectNumber 
                obAreas = [obAreas.Area];
                %Sort by area
                [dummy,iSort] = sort(obAreas,'descend'); %#ok<ASGLU>
                %Keep only the largest requested number
                currMask = false(size(currMask));
                for i = 1:p.ObjectNumber
                    currMask = currMask | labelMask == iSort(i);
                end
            end
        end
        
        % ------ Hole-Filling ----- %
        if p.FillHoles
            % If the mask touches the image border, we want to close holes
            % which are on the image border. We do this by adding a border
            % of ones on the sides where the mask touches. (if FillBoundaryHoles is True)
            if p.FillBoundaryHoles && any([currMask(1,:) currMask(end,:) currMask(:,1)' currMask(:,end)'])                
%                 m = movieData.imSize_(1);
%                 n = movieData.imSize_(2); 
                [m, n] = size(currMask); % make it work for cropped images
                %Add a border of 1s
                tmpIm = vertcat(true(1,n+2),[true(m,1) ...
                                currMask true(m,1)],true(1,n+2));
                %Find holes - the largest "hole" is considered to be the
                %background and ignored.
                cc = bwconncomp(~tmpIm,4);                                
                holeAreas = cellfun(@(x)(numel(x)),cc.PixelIdxList);
                [~,iBiggest] = max(holeAreas);                                
                tmpIm = imfill(tmpIm,'holes');
                tmpIm(cc.PixelIdxList{iBiggest}) = false;
                currMask = tmpIm(2:end-1,2:end-1);
             else                        
                % Check if touching border, if so, add zeros all around first, then fill holes
                % to prevent filling in holes along boundary.
                if any([currMask(1,:) currMask(end,:) currMask(:,1)' currMask(:,end)'])
                    %Add a border of 1s
%                     m = movieData.imSize_(1);
%                     n = movieData.imSize_(2);
                    [m, n] = size(currMask); % make it work for cropped images
                    tmpIm = vertcat(false(1,n+2),[false(m,1) ...
                                currMask false(m,1)],false(1,n+2));

                    tmpIm = imfill(tmpIm,'holes');
                    currMask = tmpIm(2:end-1,2:end-1);
                else               
                    currMask = imfill(currMask,'holes');
                end
             end
        end
        
        if p.SuppressBorder
            
            %Sets all mask pixels on the image border to false. Prevents
            %other analysis routines from complaining when cells/mask
            %objects touch the image border.
            currMask([1 end],:) = false;
            currMask(:,[1 end]) = false;
            
        end
        
        %Write the refined mask to file
        imwrite(currMask,[outMaskDir{iChan} filesep pString maskNames{iChan}{iImage}], 'Compression','none'); % fixed issue of ImageJ cannot open compressed mask. - Qiongjing (Jenny) Zou, Jan 2023
        
        if ishandle(wtBar) && mod(iImage,5)
            %Update the waitbar occasionally to minimize slowdown
            waitbar((iImage + (iChan-1)*nImages) / nImTot,wtBar)
        end                 
        
    end
   
end

if ishandle(wtBar)
    close(wtBar)
end


%% ------ Finalize ------ %%


%Store parameters/settings in movieData structure

movieData.processes_{iProc}.setDateTime;
movieData.save; %Save the new movieData to disk

disp('Finished refining masks!')

