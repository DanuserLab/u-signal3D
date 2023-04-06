function movieData = createMovieBackgroundMasks(movieDataOrProcess,paramsIn)
%CREATEMOVIEBACKGROUNDMASKS creates background masks by growing the foreground masks
%                                               
% movieData = createMovieBackgroundMasks(movieData);                                              
%
% movieData = createMovieBackgroundMasks(movieData,paramsIn)
% 
% This function uses the (already created) image masks to generate
% background masks. This is accomplished by "growing" the masks (dilation).
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
%       movieData, in a sub-directory called "BackgroundMasks"
%
%       ('ChannelIndex' -> Positive integer scalar or vector)
%       The integer index of the channels to create background masks from.
%       These channels must have already been segmented. 
%       Optional. If not input, background masks are created for all
%       channels which have foreground masks.
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
%       ('GrowthRadius' - positive integer scalar)
%       The radius (in pixels) to grow the foreground masks to
%       produce the background masks.
%       Optional. Default is 20 pixels.
% 
%       ('BatchMode'- True/False Scalar) If true, graphical output and user
%       interaction is supressed (i.e. progress bars, dialog and question
%       boxes etc.)
%
%
% Output:
%
%   movieData - the updated movieData structure with the background mask
%   creation logged in it.
%
%
% Additionally, the masks are written to the movie's analysis directory in
% a sub-folder called "backgroundMasks"
%
%
% Hunter Elliott, 11/2009
%
%% ----- Parameters ----- %%
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

pString = 'bkgrnd_'; %Prefix for saving masks to file

%% ------------ Input ----------- %%

if nargin < 1 || ~isProcessOrMovieData(movieDataOrProcess)
    error('The first input argument must be a valid MovieData or Process object!')
end
if nargin < 2
    paramsIn = [];
end


% Get MovieData object and Process
[movieData, proc, iProc] = getOwnerAndProcess(movieDataOrProcess,'BackgroundMasksProcess',true);

nChan = numel(movieData.channels_);

%Parse input, store in parameter structure
p = parseProcessParams(proc,paramsIn);

%----Param Check-----%

if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex),p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end
   
nChanBack = numel(p.ChannelIndex);

%Make sure the move has been segmented
if isempty(p.SegProcessIndex)    
    if p.BatchMode
        %If batch mode, just get all the seg processes excluding this one        
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
hasMasks = false(nChanBack,nProc);
%Check every specified process for masks
for j = 1:nProc

    %Make sure the specified process is a MaskProcess
    if ~isa(movieData.processes_{p.SegProcessIndex(j)},'MaskProcess')
        error(['The process specified by SegProcessIndex(' num2str(j) ') is not a MaskProcess!'])
    end

    %Check which channels have masks from this process
    hasMasks(:,j) = movieData.processes_{p.SegProcessIndex(j)}.checkChannelOutput(p.ChannelIndex);        

end



%Make sure all the selected channels have foreground masks.
if any(~sum(hasMasks,2))
    warning('biosensors:backgroundMasks:noFGmasks',...
        'Cannot create background masks because some channels do not have foreground masks! Please segment these channels before creating background masks!')
end

if p.GrowthRadius ~= round(p.GrowthRadius) || p.GrowthRadius < 0
    error('Input variable p.GrowthRadius must be a positive integer!')
end


%% ------------ Init --------------%%



%Set up the input and output mask
for j = 1:nChanBack;
    
    %Get the most recent seg process with masks for this channel
    iP = p.SegProcessIndex(find(hasMasks(j,:),1,'last'));
    
    movieData.processes_{iProc}.setInMaskPath(p.ChannelIndex(j),...
        movieData.processes_{iP}.outFilePaths_(p.ChannelIndex(j)));
    
    %Create string for current directory
    currDir = [p.OutputDirectory filesep 'BackgroundMasks_channel_' num2str(p.ChannelIndex(j))];    
    
    %Check/create directory
    mkClrDir(currDir);
    
    %Save this in the process object
    movieData.processes_{iProc}.setOutMaskPath(p.ChannelIndex(j),currDir);   
    
end

if p.GrowthRadius > 0
    growDisk = strel('disk',p.GrowthRadius);
end


%% ------- Background mask creation -------------%%

disp('Starting background mask creation...')


maskFileNames = movieData.processes_{iProc}.getInMaskFileNames(p.ChannelIndex);
maskDirs = movieData.processes_{iProc}.inFilePaths_(p.ChannelIndex);

nMasks = movieData.nFrames_;
nMaskTot = nMasks * nChanBack;

if ~p.BatchMode
    wtBar = waitbar(0,['Please wait, creating background masks for channel ' num2str(p.ChannelIndex(1)) ' ...']);        
end    

for iChan = 1:nChanBack
        
    
    currBkgrndMaskDir = movieData.processes_{iProc}.outFilePaths_{p.ChannelIndex(iChan)};                  
    
    
    disp(['Creating background masks for channel ' num2str(p.ChannelIndex(iChan)) '...']);
    disp(['Using masks from directory ' maskDirs{iChan} ' results will be stored in ' currBkgrndMaskDir])

    if ~p.BatchMode        
        waitbar((iChan-1)*nMasks / nMaskTot,wtBar,['Please wait, creating background masks for channel ' num2str(p.ChannelIndex(iChan)) ' ...']);        
    end        

    
    for iMask = 1:nMasks
        
        %Load the current foreground mask
        currMask = imread([maskDirs{iChan} filesep maskFileNames{iChan}{iMask}]);
        
        
        if p.GrowthRadius > 0
            %Grow and invert this mask to create the background mask
            backgroundMask = ~imdilate(currMask,growDisk);
        else
            backgroundMask = ~currMask;
        end
        
        %Write it to file        
        imwrite(backgroundMask,[currBkgrndMaskDir filesep ...
            pString maskFileNames{iChan}{iMask}], 'Compression','none'); % fixed issue of ImageJ cannot open compressed mask. - Qiongjing (Jenny) Zou, Jan 2023

        if ~p.BatchMode && mod(iMask,5)
            %Update the waitbar occasionally to minimize slowdown
            waitbar((iMask + (iChan-1)*nMasks) / nMaskTot,wtBar)
        end                
        
    end
end

if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end

%% ------ Log processing in moviedata and save ---- %%

movieData.processes_{iProc}.setDateTime;
movieData.save; %Save the new movieData to disk


disp('Finished creating background masks!')




