function movieData = photobleachCorrectMovieRatios(movieData,paramsIn)
%PHOTOBLEACHCORRECTMOVIERATIOS applies a photobleach correction to ratio images for the input movie
% 
% movieData = photobleachCorrectMovieRatios(movieData)
% 
% movieData = photobleachCorrectMovieRatios(movieData,paramsIn)
%
% This function applies a photo-bleach correction to the ratio images in
% the input movie. Both the type of correction and the channel(s) to
% correct can be selected. 
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
%       sub-directory called "bleedthrough_corrected_images"
%
%       ('ChannelIndex'-> Positive integer scalar) The integer index of the
%       NUMERATOR of the ratio channel to perform photbleach correction on.
%       This index corresponds to the channel's location in the array
%       movieData.channels_. If not input, the user will be asked to select
%       from the movie's channels.
%
%       ('CorrectionType' -> character string) Character string describing
%       the photo-bleach correction method to use. The options are:
%
%           "RatioOfAverages" The average intensity of the images used to
%           make the ratios is calculated in each Frame. Then these averages
%           are ratioed, and a double-exponential is fit to the resulting
%           timeseries. 
%
%           "AverageOfRatios" The average masked value of the ratio images is
%           calculated in each frame, and then a double-exponential is fit to
%           this timeseries.
%
%           "RatioOfTotals" The total intensity of the images used to make
%           the ratios is calculated in each frame, and a double-eponential
%           is fit to the ratio of these values.
%           NOTE: In all cases, the correction is applied to the ratio images.
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
%   The corrected images are written to the directory specified by the
%   parameter OuptuDirectory, with each channel in a separate
%   sub-directory. They will be stored as double-precision .mat files.
%
% 
% Hunter Elliott
% 11/2009
% Revamped 6/2010
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

%%  --------- Parameters ------- %%

pString = 'photobleached_corrected_ratio_'; %The string to prepend before the corrected image directory & channel name
dName = 'photobleach_corrected_images_for_channel_'; %String for naming the directories for each corrected channel
fitFileName = 'photobleach_correction.mat'; %File name for saving fit results to
figName = 'photobleach correction fit.fig'; %Name for saving figure to file

%% ------ Input ------ %%


%Check that input object is a valid moviedata
assert(isa(movieData,'MovieData'),...
    'The first input argument must be a valid MovieData object!')

%Make sure there are enough frames
nImages = movieData.nFrames_;
assert(nImages > 4,...
    'Input movie must have AT LEAST 5 timepoints for photobleach correction!!!')    

if nargin < 2
    paramsIn = [];
end

%Make sure the movie has been ratioed
iRProc = movieData.getProcessIndex('RatioProcess',1,false);

assert(~isempty(iRProc),'The input movie has not been ratioed! Please perform ratioing prior to outputing ratio images!');
ratProc = movieData.processes_{iRProc};

%Get the indices of any previous photbleach correction processes from this
%function
iProc = movieData.getProcessIndex('PhotobleachCorrectionProcess',1,false);

%If the process doesn't exist, create it with default settings.
if isempty(iProc)
    iProc = numel(movieData.processes_)+1;
    movieData.addProcess(PhotobleachCorrectionProcess(movieData,movieData.outputDirectory_));                                                                                                 
end


%Parse input, store in parameter structure
p = parseProcessParams(movieData.processes_{iProc},paramsIn);

nChan = numel(movieData.channels_);

if isempty(p.ChannelIndex)
    if ~p.BatchMode
        p.ChannelIndex = selectMovieChannels(movieData,1,'Select the ratio channel to photobleach correct:');
    else
        error('In batch mode, you must specify the channel to photobleach correct!')
    end
end

assert(length(p.ChannelIndex) == 1,'You can only photobleach-correct one ratio channel at a time!');

if p.ChannelIndex > nChan || p.ChannelIndex < 1 || ~isequal(round(p.ChannelIndex),p.ChannelIndex)
    error('Invalid channel number specified! Check ChannelIndex input!!')
end


%% -------- Init -------- %%

disp('Starting photobleach correction...')

%Get input directories/image names
inFilePaths=cell(1,numel(movieData.channels_));
iNum = ratProc.funParams_.ChannelIndex(1);

ratDir = ratProc.outFilePaths_{1,iNum};
inFilePaths{1,iNum}=ratDir;

if any(strcmp(p.CorrectionType,{'RatioOfAverages', 'RatioOfTotals'}))
    
    % Get numerator input directory
    numDir = ratProc.inFilePaths_{1,iNum};
    numFileNames = ratProc.getInImageFileNames(iNum);
    inFilePaths{2,iNum}=numDir;
    
    % Get denumerator input directory
    iDenom = ratProc.funParams_.ChannelIndex(2);
    denomDir = ratProc.inFilePaths_{1,iDenom};
    denomFileNames = ratProc.getInImageFileNames(iDenom);
    inFilePaths{2,iDenom}=denomDir;
end

movieData.processes_{iProc}.setInFilePaths(inFilePaths);

%Set-up output directory
outDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex)];

%Set up output directory
mkClrDir(outDir);
movieData.processes_{iProc}.setOutImagePath(p.ChannelIndex,outDir);


nImTot = nImages*2;

%% ------- Calculate Intensity Vs. Time ----- %%
%Calculate the movie intensity vs. time in the needed channels

meanRat = zeros(1,nImages);
if any(strcmp(p.CorrectionType,{'RatioOfAverages', 'RatioOfTotals'}))
    meanNum = zeros(1,nImages);
    meanDenom = zeros(1,nImages);
    totalNum = zeros(1,nImages);
    totalDenom = zeros(1,nImages);
end

disp('Calculating average intensities...')

if ~p.BatchMode
    wtBar = waitbar(0,'Please wait, calculating intensity statistics...... ');        
end        



for iImage = 1:nImages
    currRat = ratProc.loadChannelOutput(iNum,iImage);
    meanRat(iImage) = mean(currRat(currRat(:) > 0));
    if any(strcmp(p.CorrectionType,{'RatioOfAverages', 'RatioOfTotals'}))
        currNum = double(imread([numDir filesep numFileNames{1}{iImage}]));
        meanNum(iImage) = mean(currNum(:));
        totalNum(iImage) = sum(currNum(:));
        currDenom = double(imread([denomDir filesep denomFileNames{1}{iImage}]));
        meanDenom(iImage) = mean(currDenom(:));
        totalDenom(iImage) = sum(currDenom(:));
    end
    
    if ~p.BatchMode && mod(iImage,5)
        %Update the waitbar occasionally to minimize slowdown
        waitbar(iImage / nImTot,wtBar)
    end                        
    
    
end




%% ----- Calculate Photobleach correction ----- %%

disp('Calculating fit...')


fitFun = @(b,x)(b(1) .* exp(b(2) .* x))+(b(3) .* exp(b(4) .* x));     %Double-exponential function for fitting
%Check if time was defined in moviedata
if ~isempty(movieData.timeInterval_)
    timePoints = (0:1:nImages-1) * movieData.timeInterval_;     %time data
else
    timePoints = (0:1:nImages-1);
end
bInit = [1 0 1 0]; %Initial guess for fit parameters.

 
switch p.CorrectionType


    case 'RatioOfAverages'

        fitData = meanNum ./ meanDenom;

    case 'AverageOfRatios' 

         fitData = meanRat;
         
    case 'RatioOfTotals'
        
        fitData = totalNum ./ totalDenom;

    otherwise

        error(['Invalid photobleach correction method!! "' p.CorrectionType '" is not a recognized method!'])
end


%Fit function to ratio timeseries
fitOptions = statset('Robust','on','MaxIter',500,'Display','off');
[bFit,resFit,jacFit,covFit,mseFit] = nlinfit(timePoints(:),fitData(:),fitFun,bInit,fitOptions);
%Get confidence intervals of fit and fit values
[fitValues,deltaFit] = nlpredci(fitFun,timePoints(:),bFit,resFit,'covar',covFit,'mse',mseFit);

%Check the fit jacobian
[dummy,R] = qr(jacFit,0); %#ok<ASGLU>
if ~p.BatchMode && condest(R) > 1/(eps(class(bFit)))^(1/2)        
    warndlg('WARNING: The photobleach correction fit is not very good. Please use extreme caution in interpreting ratio changes over time in the photobleach corrected ratios!')
end


%% ----- Apply photobleach correction to ratio images ----- %%


disp(['Applying photobleach correction method ' p.CorrectionType ' to ratio channel ' ratDir ])
disp(['Writing corrected images to channel ' outDir])

%Disable convert-to-integer warning
warning('off','MATLAB:intConvertNonIntVal');

if ~p.BatchMode        
    waitbar(nImages / nImTot,wtBar,'Please wait, applying photobleach correction ...');
end        

fString = ['%0' num2str(floor(log10(nImages))+1) '.f'];
numStr = @(frame) num2str(frame,fString);

ratMax = 0;
ratMin = Inf;

%Go through all the images and correct them
for iImage = 1:nImages
   
    %Load the image
    currRat = ratProc.loadChannelOutput(iNum,iImage);
    
    %Correct the image. We multiply by the average of the first ratio to
    %prevent normalization.
    currRat = currRat ./ fitValues(iImage) .* meanRat(1);
    
    ratMax = max(ratMax,nanmax(currRat(:)));
    ratMin = min(ratMin,nanmin(currRat(:)));
    
    %Write it back to file.    
    save([outDir filesep pString numStr(iImage)],'currRat');
    
    if ~p.BatchMode && mod(iImage,5)
        %Update the waitbar occasionally to minimize slowdown
        waitbar((iImage +nImages)/ nImTot,wtBar)
    end                        

end

% Save ratio limits
intensityLimits=cell(1,numel(movieData.channels_));
intensityLimits{p.ChannelIndex(1)}=[ratMin ratMax];
movieData.processes_{iProc}.setIntensityLimits(intensityLimits);


if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end


%% ------- Make and Save Figure ------- %%


disp('Making figures...')

if p.BatchMode
    fitFig = figure('Visible','off');
else
    fitFig = figure;
end

hold on
title('Photobleach Correction Fit')
if ~isempty(movieData.timeInterval_)
    xlabel('Time, seconds')
else
    xlabel('Frame Number')
end
ylabel(p.CorrectionType)
plot(timePoints,fitData)
plot(timePoints,fitValues,'r')
plot(timePoints,fitValues+deltaFit,'--r')
legend(p.CorrectionType,'Fit','Fit 95% C.I.')
plot(timePoints,fitValues-deltaFit,'--r')

hgsave(fitFig,[p.OutputDirectory filesep figName]);
%Log this file name in the parameter structure
p.figName = figName;
movieData.processes_{iProc}.setPara(p);


if ishandle(fitFig) %make sure user hasn't closed it.
    close(fitFig)
end


%% ----- Output/Finalization ---- %%

save([p.OutputDirectory filesep fitFileName],'fitData','fitValues',...
    'timePoints','covFit','mseFit','resFit','jacFit',...
    'fitFun','bFit');

%Log the correction in the movieData object and save it

movieData.processes_{iProc}.setDateTime;
movieData.save;


disp('Finished!')
