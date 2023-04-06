function movieData = darkCurrentCorrectMovie(movieData,paramsIn)

% movieData = darkCurrentCorrectMovie(movieData)
% 
% movieData = darkCurrentCorrectMovie(movieData,paramsIn)
% 
% This function performs dark-current correction on the input movie. This
% is accomplished by subtracting a "dark-current image" from each image in
% the channels to be corrected. The dark current image is an image taken
% with no light incident on the camera. If multiple dark-current images are
% taken, they will be averaged together. This is highly recommended.
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
%       ('OutputDirectory' -> character string) Optional. A character
%       string specifying the directory to save the corrected images to.
%       Corrected images for different channels will be saved as
%       sub-directories of this directory. If not input, the corrected
%       images will be saved to the same directory as the movieData, in a
%       sub-directory called "dark_current_corrected"
%
%       ('ChannelIndex'-> Positive integer scalar or vector) The integer
%       indices of the channel(s) to perform dark-current correction on.
%       This index corresponds to the channel's location in the array
%       movieData.channels_. If not input, all channels will be corrected.
%   
%       ('DarkImageDirectories' -> Cell array of character strings)
%       This cell array contains directories for dark-current images which
%       should be used to correct the raw images. Must contain one valid
%       directory for each channel specified by ChannelIndex.
%       Optional. If not input, the user will be asked to select a folder
%       for each channel.
%
%       ('MedianFilter' - True/False)
%       If true, the final (averaged) dark correction image will be median
%       filtered with a 3x3 neighborhood.
%       Optional. Default is true.
%
%       ('GaussFilterSigma' -> Positive scalar, >= 1.0)
%       This specifies the sigma (in pixels) of the gaussian filter to
%       apply to the final (averaged) dark correction image. If less than
%       one, no gaussian filtering is performed.
%       Optional. Default is no filtering.
%
%       ('BatchMode' -> True/False)
%       If this option value is set to true, all graphical output is
%       suppressed.
%
%   
% Output:
%
%   movieData - the updated movieData object with the correction
%   parameters, paths etc. stored in it, in the field movieData.processes_.
%
%   The corrected images are written to the directory specified by the
%   parameter OuptuDirectory, with each channel in a separate
%   sub-directory. They will be stored as bit-packed .tif files. 
%
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

%% ------ Parameters ------- %%


pString = 'dark_current_corrected_'; %The string to prepend before the dark-corrected image directory & channel name
saveName = 'dark_current_correction_image_for_channel_'; %File name for saving processed/avged dark current images. Actual file name will have channel number appended.
dName = 'dark_current_corrected_images_for_channel_';%String for naming the directories for each corrected channel


%% ----------- Input ------------ %%


%Check that input object is a valid moviedata
if ~isa(movieData,'MovieData')
    error('The first input argument must be a valid MovieData object!')
end

if nargin < 2
    paramsIn = [];
end


%Get the indices of any previous dark current correction processes from this function                                                                              
iProc = find(cellfun(@(x)(isa(x,'DarkCurrentCorrectionProcess')),movieData.processes_),1);                          

%If the process doesn't exist, create it with default settings.
if isempty(iProc)
    iProc = numel(movieData.processes_)+1;
    movieData.addProcess(DarkCurrentCorrectionProcess(movieData,movieData.outputDirectory_));                                                                                                 
end

nChan = numel(movieData.channels_);


%Parse input, store in parameter structure
p = parseProcessParams(movieData.processes_{iProc},paramsIn);

if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex),p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

nChanCorr = length(p.ChannelIndex);

%If not specified, get the directories for each set of dark-current images.
if isempty(p.DarkImageDirectories)
    
    %Check if the paths have been specified before
    if all(cellfun(@isempty,movieData.processes_{iProc}.inFilePaths_(2,:)))      
        if ~p.BatchMode
            %If not, ask the user.
            stPath = pwd;
            p.DarkImageDirectories = cell(1,nChanCorr);

            for j = 1:nChanCorr

                p.DarkImageDirectories{j} = uigetdir(stPath,['Select the directory with dark-current images for channel ' num2str(p.ChannelIndex(j))]);

                if p.DarkImageDirectories{j} ~= 0
                    stPath = p.DarkImageDirectories{j};
                    movieData.processes_{iProc}.setCorrectionImagePath(p.ChannelIndex(j),p.DarkImageDirectories{j});            
                else
                    p.DarkImageDirectories{j} = [];            
                end
            end    
        else
            error('In batch mode, the correction image directories must be specified!')
        end
    else
        %Use the existing paths
        disp('Using previously specified correction image directories...')
        p.DarkImageDirectories = movieData.processes_{iProc}.inFilePaths_(2,p.ChannelIndex);        
    end
else
    movieData.processes_{iProc}.setCorrectionImagePath(p.ChannelIndex,p.DarkImageDirectories) 
end

%Check how many directories were specified
iDarkDir = find(cellfun(@(x)(~isempty(x)),p.DarkImageDirectories));

if length(iDarkDir) < nChanCorr
    error('You must specify a dark current correction image directory for each channel you are correcting!')    
end

%Get the dark current image file names.
darkImNames = movieData.processes_{iProc}.getCorrectionImageFileNames(p.ChannelIndex);


%Set up the directories for corrected images as sub-directories of the
%output directory, and specify the directories for the images to be
%corrected in the movieData.
for j = 1:nChanCorr;
    
    %Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex(j))];    
    
    %Check/create directory 
    mkClrDir(currDir);    
    
    %Save this in the process object
    movieData.processes_{iProc}.setOutImagePath(p.ChannelIndex(j),currDir); 
    
end
    
% Set the path of the processed correction image
outFilePaths=movieData.processes_{iProc}.outFilePaths_;
for j = 1:nChanCorr;
    outFilePaths{2,p.ChannelIndex(j)} = [p.OutputDirectory filesep saveName ...
        num2str(p.ChannelIndex(j)) '.mat'];
end
movieData.processes_{iProc}.setOutFilePaths(outFilePaths);


%% ------------ Init ---------- %%


%Create gaussian filter, if needed
disp('Starting dark current correction...')

%Get image file names for needed channels - this correction is always applied
%to raw data.

nImages = movieData.nFrames_;
nImTot = nImages * nChanCorr;

%% ----------- Get and Process Dark Current Correction Images ------------- %%
%Loads, averages, and filters the dark current correction images

disp('Loading and processing correction image(s)...')

%Go through each requested channel and process the dark current correction
darkIm = cell(1,nChanCorr);
for iChan = 1:nChanCorr
    
    % ---- Average the dark images --- %        
    
    nDarkIm = length(darkImNames{iChan});
    
    for iImage = 1:nDarkIm
        
        currIm = imread([p.DarkImageDirectories{iDarkDir(iChan)} ...
            filesep darkImNames{iDarkDir(iChan)}{iImage}]);
        
        if iImage == 1
           darkIm{iChan} = zeros(size(currIm));
        end
        
        %Average the images together
        darkIm{iChan} = darkIm{iChan} + double(currIm) ./ nDarkIm;                
               
        
    end
    
    %---Filter the averaged dark image---%
    
    %Median filter
    if p.MedianFilter
        %Add a border to prevent distortion        
        darkIm{iChan} = medfilt2(darkIm{iChan},'symmetric'); %Uses default 3x3 neighborhood        
    end
    
    %Gaussian filter
    if p.GaussFilterSigma >= 1
        darkIm{iChan} = filterGauss2D(darkIm{iChan},p.GaussFilterSigma);        
    end
        
    
end



%% -------------- Apply dark Correction ------------%%
%Applies the dark correction from above to each selected channel

disp('Applying dark current correction to images...')


if ~p.BatchMode
    wtBar = waitbar(0,['Please wait, correcting channel ' num2str(p.ChannelIndex(1)) ' ...']);        
end        



%Go through each image and apply the appropriate dark current correction
for iChan = 1:nChanCorr
    
    
    outDir = movieData.processes_{iProc}.outFilePaths_{1,p.ChannelIndex(iChan)};    
    corrDir = movieData.processes_{iProc}.inFilePaths_{2,p.ChannelIndex(iChan)};
   
    if ~p.BatchMode        
        waitbar((iChan-1)*nImages / nImTot,wtBar,['Please wait, correcting channel ' num2str(p.ChannelIndex(iChan)) ' ...']);        
    end        

    
    disp(['Dark-current correcting channel ' num2str(p.ChannelIndex(iChan)) '...'])
    disp(['Using correction images in ' corrDir])
    disp(['Correcting images from channel ' num2str(p.ChannelIndex(iChan)) ', resulting images will be stored in ' outDir])    
    
    
    for iImage = 1:nImages
    
        %Load the image to be corrected        
        currIm = movieData.channels_(p.ChannelIndex(iChan)).loadImage(iImage);
        
        %Check it's class
        ogClass = class(currIm);
    
        %Correct it
        currIm = double(currIm) - darkIm{iChan};
        
        if min(currIm(:)) < 1
            %Make sure that the correction makes sense...
            warning('BIOSENSORS:dkCorrect:badDarkCorr',...
                'Dark current correction resulted in non-positive image values! Check correction images...')            
        end
        
        %Cast to original class
        currIm = cast(currIm,ogClass);
                        
        %Write it to disk        
        imwrite(currIm,[outDir filesep pString num2str(iImage,['%0' num2str(floor(log10(nImages))+1) '.f']) '.tif' ]);
        
        if ~p.BatchMode && mod(iImage,5)
            %Update the waitbar occasionally to minimize slowdown
            waitbar((iImage + (iChan-1)*nImages) / nImTot,wtBar)
        end                        
         
    end
end

if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end



%% ------------- Output ------- %%

disp('Saving results...')


%Save the averaged/filtered dark current images
for i = 1:nChanCorr
    outCorrPath = movieData.processes_{iProc}.outFilePaths_{2,p.ChannelIndex(i)}; 
    processedDarkImage = darkIm{i}; %#ok<NASGU> %Get this element of save array because the save function sucks.
    save(outCorrPath,'processedDarkImage');
end

%Log the correction in the movieData object and save it

movieData.processes_{iProc}.setDateTime;
movieData.save;

disp('Finished Correcting!')























