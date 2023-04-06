function movieData = transformMovie(movieData,paramsIn)

% movieData = transformMovie(movieData)
%
% movieData = transformMovie(movieData,paramsIn)
%
% This function performs a spatial transformation on the selected channels
% of the input movie and writes the transformed images to a new channel in
% the movie. The transformation should be saved as a .mat file.
%
%
% Input:
%
%   movieData - The MovieData object describing the movie, as created using
%   setupMovieDataGUI.m
%
%   paramsIn - Structure with inputs for optional parameters. The
%   parameters should be stored as fields in the structure, with the field
%   names and possible values as described below:
%
%   Possible Parameter Structure Field Names:
%       ('FieldName' -> possible values)
%
%       ('OutputDirectory' -> character string) Optional. A character
%       string specifying the directory to save the corrected images to.
%       Corrected images for different channels will be saved as
%       sub-directories of this directory. If not input, the corrected
%       images will be saved to the same directory as the movieData, in a
%       sub-directory called "transformed_images"
%
%       ('ChannelIndex'-> Positive integer scalar) The integer index of the
%       channel to perform spatial transformation on. This index
%       corresponds to the channel's location in the array
%       movieData.channels_. If not input, all channels will be
%       transformed.
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
%       ('TransformMasks' -> True/False)
%       If true, the masks for a given channel will also be transformed,
%       and saved to a mask directory for the output channel(s). If true,
%       the specified channels MUST have masks. Default is true.
%
%       If masks are transformed, these additional options apply:
%
%               ('SegProcessIndex' -> Positive integer scalar or vector)
%               Optional. This specifies MaskProcess(s) to use
%               masks from by its index in the array movieData.processes_;
%               If input as a vector, masks will be used from the process
%               specified by the first element, and if not available for a
%               specific channel, then from the next process etc. If not
%               input, and multiple MaskProcesses are present, the
%               user will be asked to select one, unless batch mode is
%               enabled in which case there will be an error.
%
%       ('BatchMode' -> True/False)
%       If this option value is set to true, all graphical output is
%       suppressed. Default is false.
%
%
% Output:
%
%   movieData - The updated MovieData object, with the parameters and
%   directories for the transformation stored in it as a process object.
%
%   The transformed images will be written to the folder specified by
%   OutputDirectory.
%
% Hunter Elliott
% 11/2009
% Revamped 5/2010
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

%% ------ Parameters ----%%

pString = 'xf_image_'; %The string to prepend before the transformed image directory & channel name
dName = 'transformed_images_for_channel_';%String for naming the directories for each corrected channel

%% ------- Input ------- %%

%Check that input object is a valid moviedata
if ~isa(movieData,'MovieData')
    error('The first input argument must be a valid MovieData object!')
end

if movieData.is3D
    warning('transformMovie:threeDimensionalMovie','This function currently only supports 2D transforms, applying same transform to each z plane.');
end

if nargin < 2
    paramsIn = [];
end

%Get the indices of any previous tranformation correction processes
iProc = movieData.getProcessIndex('TransformationProcess', 1, false);

%If the process doesn't exist, create it with default settings.
if isempty(iProc)
    iProc = numel(movieData.processes_)+1;
    movieData.addProcess(TransformationProcess(movieData,movieData.outputDirectory_));
end

transfProc = movieData.getProcess(iProc);

p = parseProcessParams(transfProc,paramsIn);

%Make sure the movie has been background-subtracted
iBSProc = movieData.getProcessIndex('BackgroundSubtractionProcess', 1, false);

if ~isempty(iBSProc)
    %Check that all channels have been background subtracted
    hasBS = movieData.getProcess(iBSProc).checkChannelOutput();
    assert(all(hasBS(p.ChannelIndex)),...
        'Every channel selected for transformation must have been background subtracted! Please perform background subtraction first, or check the ChannelIndex parameter!');
    assert(~movieData.is3D,'Currently only transformation of raw images is supported for 3D movies!')
end

nChanCorr = length(p.ChannelIndex);

% Reinitialize inFilePaths and outFilePaths
transfProc.setInFilePaths(cell(1,numel(movieData.channels_)));
transfProc.setOutFilePaths(cell(1,numel(movieData.channels_)));

%Set up the input /output directories for each channel
for j = 1:nChanCorr
    
    if ~isempty(iBSProc)
        inDir = movieData.getProcess(iBSProc).outFilePaths_{1,p.ChannelIndex(j)};
    else
        inDir = movieData.channels_(p.ChannelIndex(j)).channelPath_;
    end
    transfProc.setInImagePath(p.ChannelIndex(j),inDir);
       
    
    %The output is a sub-dir of the directory specified by OutputDirectory
    currDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex(j))];
    
    %Check/set up directory
    mkClrDir(currDir);
    
    transfProc.setOutImagePath(p.ChannelIndex(j),currDir);
end

%Check if transform files have been specified, and if not, get them
if ~iscell(p.TransformFilePaths)
    %If only a single path was entered, it doesn't have to be a cella rray
    p.TransformFilePaths = {p.TransformFilePaths};
end

for j = 1:nChanCorr
    
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
    transfProc.setTransformFilePath(p.ChannelIndex(j),p.TransformFilePaths{p.ChannelIndex(j)});
end


%% ------- Init ------ %%

disp('Loading transformation...')

%Get the actual transformations for each channel
xForms = transfProc.getTransformation(p.ChannelIndex);
%inNames = transfProc.getInImageFileNames(p.ChannelIndex);

%Get original image size. Image pixels that are transformed out of this
%area will be omitted to preserve this size
if ~isempty(iBSProc) % make it work for cropped images
    dinfo = dir(inDir);
    imInfo = imfinfo(fullfile(dinfo(end).folder,dinfo(end).name));
    n = imInfo.Height;
    m = imInfo.Width;
else
    n = movieData.imSize_(1);
    m = movieData.imSize_(2);
end
nFrames = movieData.nFrames_;
nPlanes = movieData.zSize_;
if isempty(nPlanes)
    nPlanes = 1;
end
nImTot = nFrames * nChanCorr * nPlanes;

fString = ['%0' num2str(ceil(log10(nFrames))+1) '.0f'];%Format string for zero-padding

%% ------- Spatial Transformation ------ %%
%Transform all images in requested channels and write them to a new
%directory.


disp('Transforming images....')

if ~p.BatchMode
    wtBar = waitbar(0,['Please wait, transforming correcting channel ' num2str(p.ChannelIndex(1)) ' ...']);
end

for iChan = 1:nChanCorr
    
    %Get directories for readability
    inDir  = transfProc.inFilePaths_{1,p.ChannelIndex(iChan)};
    outDir = transfProc.outFilePaths_{1,p.ChannelIndex(iChan)};
    
    disp(['Transforming images for channel ' num2str(p.ChannelIndex(iChan))])
    disp(['Transforming images from ' inDir ', results will be stored in ' outDir]);
    disp(['Using transform file : ' p.TransformFilePaths{p.ChannelIndex(iChan)}]);
    
    if ~p.BatchMode
        waitbar((iChan-1)*nFrames / nImTot,wtBar,['Please wait, transforming channel ' num2str(p.ChannelIndex(iChan)) ' ...']);
    end        
    
    for iFrame = 1:nFrames
        
        for iPlane = 1:nPlanes
        
            if isempty(iBSProc)
                currIm = movieData.channels_(p.ChannelIndex(iChan)).loadImage(iFrame,iPlane);
            else                
                currIm = movieData.processes_{iBSProc}.loadChannelOutput(p.ChannelIndex(iChan),iFrame);%TEMP - that this currently won't work with 3D movies! (error thrown above to cover this case)
            end

            currIm = imtransform(currIm,xForms{iChan},'XData',[1 m],'YData',[1 n],'FillValues',0);
                        
            imName = [outDir filesep pString num2str(iFrame,fString) '.tif'];
            
            if iPlane == 1
                imwrite(currIm,imName);            
            else
                imwrite(currIm,imName,'WriteMode','append');
            end
            
            if ~p.BatchMode && (mod(iFrame,5) || (nPlanes> 1 && mod(nPlanes,5)))
                %Update the waitbar occasionally to minimize slowdown
                waitbar( sub2ind([nPlanes,nFrames,nChanCorr],iPlane,iFrame,iChan) / nImTot,wtBar)
            end
        end
    end
end

if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end



%% ------- Mask Transformation ----- %%

if p.TransformMasks
    
    %Get the indices of any previous mask transformation processes
    iMaskTransfProc = movieData.getProcessIndex('MaskTransformationProcess',1,0);
    
    %If the process doesn't exist, create it
    if isempty(iMaskTransfProc)
        iMaskTransfProc = numel(movieData.processes_)+1;
        movieData.addProcess(MaskTransformationProcess(movieData,p.OutputDirectory));
    end
    maskTransfProc = movieData.processes_{iMaskTransfProc};
    
    %Set up the parameters for mask transformation
    maskTransfParams.ChannelIndex = p.ChannelIndex;
    maskTransfParams.TransformFilePaths = p.TransformFilePaths;
    maskTransfParams.SegProcessIndex = p.SegProcessIndex;
    maskTransfParams.BatchMode = p.BatchMode;
    
    
    parseProcessParams(maskTransfProc,maskTransfParams);
    maskTransfProc.run;
    
end

disp('Finished!')

