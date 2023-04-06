function movieData = transformMovieMasks(movieDataOrProcess,paramsIn)
%TRANSFORMMOVIEMASKS Spatially transforms the masks of the input movie
% 
% movieData = transformMovieMasks(movieData)
% 
% movieData = transformMovieMasks(movieData,paramsIn)
% 
% 
% This function performs a spatial transformation on the masks of the
% selected channels of the input movie.
% 
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
%       ('OutputDirectory' -> character string)
%       Optional. A character string specifying the directory to save the
%       masks to. Masks for different channels will be saved as
%       sub-directories of this directory.
%       If not input, the masks will be saved to the same directory as the
%       movieData, in a sub-directory called "masks"
%
%       ('ChannelIndex'-> Positive integer scalar or vector) The integer
%       indices of the channel(s) to perform mask transformation on. This
%       index corresponds to the channel's location in the array
%       movieData.channels_. If not input, the user will be asked to select
%       from the available channels
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
%       ('TransformFilePaths' -> Cell array of Character strings) A cell
%       array specifying The FULL path and filename of the .mat file
%       containing the transform to apply to the images in each channel.
%       Should contain one element for each channel to be transformed. The
%       transform should be of the format used by imtransform.m. If not
%       input, the user will be asked to locate a file containing a
%       transform for each channel, UNLESS batchmode is enabled, in which
%       case an error will be generated.
%
%       ('BatchMode' -> True/False)
%       If this option value is set to true, all graphical output and user
%       interaction is suppressed.
%
% 
% Output:
% 
%   movieData - The modified movieData object, with the mask transform
%   logged in it, including all parameters used.
% 
%   The transformed masks will be written to a sub-directory of the
%   OutputDirectory.
% 
% 
% Hunter Elliott 
% 6/2010
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

dName = 'xformed_masks_for_channel_';%String for naming the mask directories for each channel
pString = 'xformed_mask_'; %Prefix for saving masks to file


%% ----------- Input --------- %%

if nargin < 1 || ~isProcessOrMovieData(movieDataOrProcess)
    error('The first input argument must be a valid MovieData object!')
end
if nargin < 2
    paramsIn = [];
end

% Get MovieData object and Process
[movieData, proc, iProc] = getOwnerAndProcess(movieDataOrProcess,'MaskTransformationProcess',true);

%Parse input, store in parameter structure
p = parseProcessParams(proc,paramsIn);
nChanX = numel(p.ChannelIndex);

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
        segProcList =  movieData.getProcessIndex('MaskProcess',Inf,0);
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
hasMasks = false(nChanX,nProc);
%Check every specified process for masks
for j = 1:nProc

    %Make sure the specified process is a MaskProcess
    if ~isa(movieData.processes_{p.SegProcessIndex(j)},'MaskProcess')
        error(['The process specified by SegProcessIndex(' num2str(j) ') is not a MaskProcess!'])
    end

    %Check which channels have masks from this process
    hasMasks(:,j) = movieData.processes_{p.SegProcessIndex(j)}.checkChannelOutput(p.ChannelIndex);        

end


%Check if transform files have been specified, and if not, get them
for j = 1:nChanX
    
    if isempty(p.TransformFilePaths{p.ChannelIndex(j)})
        [currFile,currPath] = uigetfile('*.mat',...
            ['Please select the transformation file for channel ' ...
            num2str(p.ChannelIndex(j)) ':']);
        
        if currFile == 0
            error('You must specify a transformation file to continue!')
        end        
        p.TransformFilePaths{p.ChannelIndex(j)} = [currPath currFile];                    
    end
    %This method will check validity of file....
    movieData.processes_{iProc}.setTransformFilePath(p.ChannelIndex(j),...
                                                p.TransformFilePaths{p.ChannelIndex(j)});        
end

%Make sure all the selected channels have foreground masks.
if any(~sum(hasMasks,2))
    warning('biosensors:transformMasks:noFGmasks',...
        'Cannot transform masks because some channels do not have foreground masks! Please segment these channels before transforming masks!')
end


%% ----------- Init ----------- %%


%Load the transformations
xForms = movieData.processes_{iProc}.getTransformation(p.ChannelIndex);


%Get original image size. Mask pixels that are transformed out of this
%area will be omitted to preserve this size
n = movieData.imSize_(1);
m = movieData.imSize_(2);

nImages = movieData.nFrames_;   
nImTot = nImages * nChanX;

%Set up the input / output directories
outMaskDirs = cell(1,nChanX);
maskDirs = cell(1,nChanX);
maskNames = cell(1,nChanX);

% Reinitialize outFilePaths
movieData.getProcess(iProc).setOutFilePaths(cell(1, numel(movieData.channels_)));
for j = 1:nChanX;
    
    %Get the most recent seg process with masks for this channel
    iP = p.SegProcessIndex(find(hasMasks(j,:),1,'last'));
    
    movieData.getProcess(iProc).setInMaskPath(p.ChannelIndex(j),...
        movieData.getProcess(iP).outFilePaths_(p.ChannelIndex(j)));
    
    maskDirs(j) = movieData.getProcess(iP).outFilePaths_(p.ChannelIndex(j));
    maskNames(j) = movieData.getProcess(iP).getOutMaskFileNames(p.ChannelIndex(j));
    
    %Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex(j))];    
        
    %Check/create directory
    mkClrDir(currDir)               
    
    %Save this in the process object
    movieData.getProcess(iProc).setOutMaskPath(p.ChannelIndex(j),currDir);
    outMaskDirs{j} = currDir;
   
end


%% ---------------- Mask Transformation --------------- %%


if ~p.BatchMode
    wtBar = waitbar(0,['Please wait, transforming masks for channel ' num2str(p.ChannelIndex(1)) ' ...']);     
end        


disp('Starting mask transformation...')

for iChan = 1:nChanX

    disp(['Transforming masks for channel ' num2str(p.ChannelIndex(iChan)) '...']);
    disp(['Using masks from ' maskDirs{iChan}])
    
    if ~p.BatchMode        
        waitbar((iChan-1)*nImages / nImTot,wtBar,['Please wait, transforming masks for channel ' num2str(p.ChannelIndex(iChan)) ' ...']);        
    end                
            
    for iImage = 1:nImages;
        
        %Load the mask for this frame/channel
        currMask = imread([maskDirs{iChan} filesep maskNames{iChan}{iImage}]);        
        
        %Apply the transformation
        currMask = imtransform(currMask,xForms{iChan},'XData',[1 m],'YData',[1 n],'FillValues',0);
 
        if ~p.BatchMode && mod(iImage,5)
            %Update the waitbar occasionally to minimize slowdown
            waitbar((iImage + (iChan-1)*nImages) / nImTot,wtBar)
        end
        
        %Write the refined mask to file, over-writing the previous mask.
        imwrite(currMask,[outMaskDirs{j} filesep pString maskNames{iChan}{iImage}]);
     
        
    end
   
end

if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end


%% ------ Finalize ------ %%


%Store parameters/settings in movieData structure

movieData.processes_{iProc}.setDateTime;
movieData.save; %Save the new movieData to disk

disp('Finished transforming masks!')

