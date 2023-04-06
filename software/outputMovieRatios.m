function movieData = outputMovieRatios(movieData,paramsIn)
%OUTPUTMOVIERATIOS writes the ratio images to .tif files
% 
% movieData = outputMovieRatios(movieData)
% 
% movieData = outputMovieRatios(movieData,paramsIn)
%
% This function converts the ratio images for a selected channel (which are
% floating point, double-precision images) into integer-valued .tif images,
% and saves them to a specified output directory.
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
%       string specifying the directory to output the ratio images to. If
%       not input, the corrected images will be saved to the same directory
%       as the movieData, in a sub-directory called "ratio_tiffs"
%
%       ('ChannelIndex'-> Positive integer scalar) The integer index of the
%       NUMERATOR of the ratio channel to perform photbleach correction on.
%       This index corresponds to the channel's location in the array
%       movieData.channels_. If not input, the user will be asked to select
%       from the movie's channels.
%
%       ('ScaleFactor'-> Positive scalar)
%       This specifies the value to multiply the original ratios by when
%       converting them to .tif images. It is recommended that this number
%       be at least 1000 or higher to avoid rounding error in the resulting
%       .tif images.
%
%       ('BatchMode' -> True/False) If true, all graphical outputs and user
%       interaction is suppressed. 
% 
%
%
% Output:
%
%   movieData - the updated movieData object with the correction
%   parameters, paths etc. stored in it, in the field movieData.processes_.
%
%   The ouput images are written to the directory specified by the
%   parameter OuptuDirectory, in a sub-directory. They will be stored as
%   bit-packed .tif files. 
%
% 
% Hunter Elliott
% 6/2010
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

%% ------ Input ------ %%

%Check that input object is a valid moviedata
if ~isa(movieData,'MovieData')
    error('The first input argument must be a valid MovieData object!')
end

if nargin < 2
    paramsIn = [];
end

%Make sure the movie has been ratioed
iRProc = movieData.getProcessIndex('RatioProcess',1,false);

assert(~isempty(iRProc),'The input movie has not been ratioed! Please perform ratioing prior to outputing ratio images!');

%Look for previous output processes
iProc = movieData.getProcessIndex('OutputRatioProcess',1,false);

%If the process doesn't exist, create it with default settings.
if isempty(iProc)
    iProc = numel(movieData.processes_)+1;
    movieData.addProcess(OutputRatioProcess(movieData,movieData.outputDirectory_));                                                                                                 
end


%Parse input, store in parameter structure
p = parseProcessParams(movieData.processes_{iProc},paramsIn);


if isempty(p.ChannelIndex)
    if ~p.BatchMode
        p.ChannelIndex = selectMovieChannels(movieData,1,'Select the ratio channel to output:');
    else
        error('In batch mode, you must specify the channel to output!')
    end
end

%Check if the movie has a photbleach correction processes 
iPBProc = movieData.getProcessIndex('PhotobleachCorrectionProcess',1,false);

if isempty(iPBProc)
    hasPB = false;
else
    hasPB = movieData.processes_{iPBProc}.checkChannelOutput(p.ChannelIndex);
end

assert(length(p.ChannelIndex) == 1,'You can only output one ratio channel at a time!')

%% -------- Init -------- %%

disp('Starting ratio output ...')


%Set up input and output directories
if hasPB
    inProc = movieData.processes_{iPBProc};
else
    inProc = movieData.processes_{iRProc};
end

% Log input directory
inDir = inProc.outFilePaths_{1,p.ChannelIndex};
inNames = inProc.getOutImageFileNames(p.ChannelIndex);
inFilePaths = cell(1,numel(movieData.channels_));
inFilePaths{p.ChannelIndex}=inDir;
movieData.processes_{iProc}.setInFilePaths(inFilePaths);

% Log output directory
outDir = p.OutputDirectory;
mkClrDir(outDir);
movieData.processes_{iProc}.setOutImagePath(p.ChannelIndex,outDir);


nImages = movieData.nFrames_;

%% ------- Output -------- %%
%Writes the ratio images to file.

disp(['Outputing ratio images for channel ' inDir ])
disp(['Writing ratio .tiff images to folder ' outDir])

%Disable convert-to-integer warning
warning('off','MATLAB:intConvertNonIntVal');

if ~p.BatchMode        
    wtBar = waitbar(0,'Please wait, writing ratios to .tif images...');
end        

ratMax = 0;
ratMin = Inf;
%Go through all the images and correct them
for iImage = 1:nImages
   
    %Load the image
    currRat= inProc.loadChannelOutput(p.ChannelIndex,iImage);
    
    %Scale the image
    currRat = currRat .* p.ScaleFactor;
    
    ratMax = max(ratMax,nanmax(currRat(:)));
    ratMin = min(ratMin,nanmin(currRat(:)));
    
    %Write it back to file.    
    imwrite(uint16(currRat),[outDir filesep inNames{1}{iImage}(1:end-4) '.tif'],...
        'Compression','none'); %Disable compression to ensure compatibility
    
    if ~p.BatchMode && mod(iImage,5)
        %Update the waitbar occasionally to minimize slowdown
        waitbar(iImage / nImages,wtBar)
    end                        

end

% Save ratio limits
intensityLimits=cell(1,numel(movieData.channels_));
intensityLimits{p.ChannelIndex(1)}=[ratMin ratMax];
movieData.processes_{iProc}.setIntensityLimits(intensityLimits);

if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end


if p.MakeMovie
    % Create a cell array of parameter/value from the funParams
    % structure
    movieFields=fieldnames(p.MovieOptions)';
    movieValues=struct2cell(p.MovieOptions)';
    movieOptions = vertcat(movieFields,movieValues);
    movieOptions = reshape(movieOptions,1,numel(movieFields)*2);
    
    % Call the movie creation routine
    makeRatioMovie(movieData,movieOptions{:});
end

%% ----- Finalization ---- %%


%Log the output in the movieData object and save it

movieData.processes_{iProc}.setDateTime;
movieData.save;


disp('Finished!')




