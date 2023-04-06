function cropShadeCorrectROI(movieDataOrProcess, varargin)
% cropShadeCorrectROI wrapper function for CropShadeCorrectROIProcess
%
% INPUT
% movieDataOrProcess - either a MovieData (legacy)
%                      or a Process (new as of July 2016)
%
% param - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
%
% OUTPUT
% none (saved to p.OutputDirectory)
%
% Changes
% As of July 2016, the first argument could also be a Process. Use
% getOwnerAndProcess to simplify compatability.
%
% As of August 2016, the standard second argument should be the parameter
% structure
%
% Qiongjing (Jenny) Zou, Nov 2022
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


%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('movieDataOrProcess', @isProcessOrMovieData);
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get MovieData object and Process
[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess,'CropShadeCorrectROIProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in CropShadeCorrectROIProcess

% Parameters:

% Sanity Checks
nChan = numel(movieData.channels_);
if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex), p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

% precondition / error checking
% check if ShadeCorrectionProcess was run
if isempty(p.ProcessIndex)
    iShadeCorrectProc = movieData.getProcessIndex('ShadeCorrectionProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iShadeCorrectProc)
        error('ShadeCorrectionProcess needs to be done before run this process.')
    end
elseif isa(movieData.processes_{p.ProcessIndex},'ShadeCorrectionProcess')
    iShadeCorrectProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid ShadeCorrectionProcess! Check input!')
end

% check crop ROI positions
if p.cropROIpositions(1) < 0 || p.cropROIpositions(1) > movieData.imSize_(2) || p.cropROIpositions(2) < 0 || ...
        p.cropROIpositions(2) > movieData.imSize_(1) || ...
        p.cropROIpositions(3) < 0 || p.cropROIpositions(4) < 0
    error('Invalid crop RIO positions! Check input!')
end


% logging input paths (bookkeeping)
% Set up the input directories (input images)
inFilePaths = cell(1,numel(movieData.channels_));
for i = p.ChannelIndex
    % if isempty(iShadeCorrectProc)
    %     inFilePaths{1,i} = movieData.getChannelPaths{i};
    % else
       inFilePaths{1,i} = movieData.processes_{iShadeCorrectProc}.outFilePaths_{1,i}; 
    % end
end
thisProc.setInFilePaths(inFilePaths);


% logging output paths.
% only masksOutDir are set in outFilePaths_, other output are saved but not logged here.
dName = 'crop_ROI_images_for_channel_';%String for naming the mask directories for each channel
outFilePaths = cell(1, numel(movieData.channels_));
mkClrDir(p.OutputDirectory);
for iChan = p.ChannelIndex
    % Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(iChan)];
    outFilePaths{1,iChan} = currDir;
    mkClrDir(outFilePaths{1,iChan});
end
thisProc.setOutFilePaths(outFilePaths);


%% Algorithm
% also see cropMovie.m, imcrop.m
tic

cropROI = p.cropROIpositions;
cropTOI = 1 : movieData.nFrames_;

% if isempty(iShadeCorrectProc) % use raw images
%     imageFileNames = movieData.getImageFileNames();
% else
    % use images from previous proc
    imageFileNames = cell(1,numel(movieData.channels_));
    for i = p.ChannelIndex
        imageFiles = imDir(inFilePaths{1, i}, true);
        imageFileNames{i} = arrayfun(@(x) x.name, imageFiles, 'unif', 0);
    end
% end

% Create new channel directory names for image writing
newImDirs = outFilePaths(1,:);
outImage = @(chan,frame) [newImDirs{chan} filesep imageFileNames{chan}{frame}];

for i = p.ChannelIndex
    disp('Cropping channel:')
    disp(inFilePaths{i});
    disp('Results will be saved under:')
    disp(outFilePaths{1,i});
    
    for j= 1:numel(cropTOI)
        tj=cropTOI(j);
        % if isempty(iShadeCorrectProc) % use raw images
        %     % Read original image
        %     I = movieData.getChannel(i).loadImage(tj); % this is the way to read image for all MD.Reader,
        % else
            % Read images from previous proc
            I = imread(fullfile(inFilePaths{i}, imageFileNames{1,i}{tj}));
        % end
        % crop it and save it
        imwrite(imcrop(I,cropROI), outImage(i,j));
    end
end


toc
% %%%% end of algorithm

disp('Finished Cropping ROI of Shade Corrected Movie!')

end % end of wrapper fcn
