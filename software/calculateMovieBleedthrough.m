function movieData = calculateMovieBleedthrough(movieData,varargin)
%CALCULATEMOVIEBLEEDTHROUGH calculates bleedthrough coefficients using the input movie 
% 
% movieData = calculateMovieBleedthrough(movieData)
% 
% movieData =
% calculateMovieBleedthrough(movieData,'OptionName',optionValue,...)
% 
% This function calculates average bleedthgough coefficients based on the
% input movie. This movie should have one channel (A) with a fluorophore
% and illumination and filters specific to this fluorophore, and another
% channel (B) imaged with it's own illumination and filters, but with no
% fluorophore. The bleedthrough of the fluorophore in channel A to the
% image in channel B will then be calculated. This allows, in a later
% experiment, the image in channel B to be corrected for this bleedthrough.
% This calculation requires that the movie have been segmented already, as
% only areas within the cell(s) will be used for coefficient calculation.
% 
% Since time information is not needed in bleedthrough calculations, this
% function assumes that each image in the movie is of different cell(s),
% and therefore calculates a separate coefficient for each frame. The
% average of all the coefficients should then be used in later corrections.
%
% **NOTE** It is required that you use fully-corrected, images for both
% channels used in this calculation!! This means that all channels used
% must AT LEAST have been background subtracted. It is strongly recommended
% that a transformation also be applied if dual-camera acquisition is used.
% Also, be sure that none of your images have saturated areas, as this will
% cause error in the calculated coefficient.
%
% Input:
% 
%   movieData - The MovieData object describing the movie, as created with
%   setupMovieDataGUI.m
% 
%   'OptionName',optionValue - A string with an option name followed by the
%   value for that option.
% 
%   Possible Option Names:
%
%       ('OptionName' -> possible values)
%
%       ('FluorophoreChannel'->Integer scalar) The index of the channel
%       which has a fluorophore (channel A above) in the input movie. This
%       index is the location of the channel in the field
%       movieData.channelDirectory
%       If not input, the user is asked.
% 
%       ('BleedthroughChannel'->Integer scalar) The index of the channel
%       which has NO fluorophore (channel B above) in the input movie. This
%       index is the location of the channel in the field
%       movieData.channelDirectory
%       If not input, the user is asked.
%
%       ('FluorophoreMaskChannel'->Integer scalar) Thin index of the
%       channel the use masks from for the fluorophore channel. Default is
%       to use masks from the fluorophore channel itself.
%
%       ('BleedthroughMaskChannel'->Integer scalar) Thin index of the
%       channel the use masks from for the bleedthrough channel. Default is
%       to use masks from the bleed channel itself.
% 
% 
% Output:
% 
%   movieData - the modified MovieData object with the bleedthrough
%   calculation and coefficients logged in it. 
% 
%   Additionally, the BT coefficients will be written to file in the
%   movie's outputDirectory.
%
% Hunter Elliott 
% 2/2010
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

%% -------- Parameters ------- %%

dName = 'Bleedthrough_Coefficients'; %Directory to save results to(As sub-directory of movie's output directory)
fName = 'bleedthrough_calc';  %File name to save results as


%% ---------- Input ---------- %%

if nargin < 1 || ~isa(movieData,'MovieData')
    error('The first input must be a valid MovieData object!')
end

[fChan,bChan,fMaskChan,bMaskChan] = parseInput(varargin);

% --- Defaults ---- %

if isempty(fChan)
    fChan = selectMovieChannels(movieData,0,'Please select the channel WITH a fluorophore:');
end
if isempty(bChan)
    bChan = selectMovieChannels(movieData,0,'Please select the channel WITHOUT a fluorophore:');
end

if isempty(fMaskChan)
    fMaskChan = selectMovieChannels(movieData,0,'Select a channel to use masks from for the channel WITH a fluorophore:');
end
if isempty(bMaskChan)
    bMaskChan = selectMovieChannels(movieData,0,'Select a channel to use masks from for the channel WITHOUT a fluorophore:');
end


%% ----- Init ----- %%


nImages = movieData.nFrames_;
iChans = [fChan bChan];
iMaskChans = [fMaskChan bMaskChan];

%First, make sure that at least the background subtraction has been done.
iBSProc = movieData.getProcessIndex('BackgroundSubtractionProcess',1,1);
if isempty(iBSProc)
    error('The input movie has not been background subtracted! Please perform background subtraction prior to bleedthrough calculation!')    
end
%Check that all channels have been background subtracted
if ~all(movieData.processes_{iBSProc}.checkChannelOutput(iChans));
    error('Specified channels have not been background subtracted! Please perform background subtraction first!');
end
%Check if either of the channels have been transformed.
iXFProc = movieData.getProcessIndex('TransformationProcess',1,1);
if ~isempty(iXFProc)
    %Check which channels have been transformed
    hasXF = movieData.processes_{iXFProc}.checkChannelOutput(iChans);       
else
    hasXF = false(1,2);
end
%Assign the processes to use as input for the channels
iInProc = zeros(2,1);
iInProc(hasXF) = iXFProc;
iInProc(~hasXF) = iBSProc;

%Get the image directories and file names
imNames = cell(1,2);
imDirs = cell(1,2);
for j = 1:2
    imNames{j} = movieData.processes_{iInProc(j)}.getOutImageFileNames(iChans(j));
    imNames{j} = imNames{j}{1};
    imDirs{j} = movieData.processes_{iInProc(j)}.outFilePaths_{1,iChans(j)};        
end

%Check segmentation processes
if isempty(movieData.getProcessIndex('MaskProcess',Inf,0))
    error('The movie must have been segmented! Please segment movie first!')
end

h = msgbox('After you click OK, when the next window pops up, select the segmentation process to use masks from for the channel WITH a fluorophore','modal');
uiwait(h);
iSegProc(1) = movieData.getProcessIndex('MaskProcess',1,1);
%Check the specified mask channels
if ~movieData.processes_{iSegProc(1)}.checkChannelOutput(iMaskChans(1))
    error('Specified mask channels do not have valid masks! Check channels & masks!')
end

h = msgbox('After you click OK, when the next window pops up, select the segmentation process to use masks from for the channel WITHOUT a fluorophore','modal');
uiwait(h);
iSegProc(2) = movieData.getProcessIndex('MaskProcess',1,1);
%Check the specified mask channels
if ~movieData.processes_{iSegProc(2)}.checkChannelOutput(iMaskChans(2))
    error('Specified mask channels do not have valid masks! Check channels & masks!')
end


%Get mask directories and file names
mNames = cell(1,2);
mDirs = cell(1,2);
for j = 1:2
    mNames{j} = movieData.processes_{iSegProc(j)}.getOutMaskFileNames(iMaskChans(j));
    mNames{j} = mNames{j}{1};
    mDirs{j} = movieData.processes_{iSegProc(j)}.outFilePaths_{iMaskChans(j)};            
end

%Get camera bit depth, to check for saturation
%TEMP - OR ADD SAT AREA MASKING ??? OR JUST REQ. GOOD DATA QUALITY???


%% ----- Bleedthrough Coeficient Calculation ----- %%

%Init arrays for fit results
fitCoef = zeros(nImages,2);
fitStats = struct('R',cell(nImages,1),...
                  'df',cell(nImages,1),...
               'normr',cell(nImages,1),...
               'Rsquared',cell(nImages,1));

%Make figure for showing all lines           
allFig = figure;

nByn = ceil(sqrt(nImages));%Determine size of sub-plot array


disp(['Calculating bleedthrough of channel "' imDirs{1}  ...
      '" into channel "' imDirs{2} '"..']);

for iImage = 1:nImages
    
    %Load the images and masks
    fImage = double(imread([imDirs{1} filesep imNames{1}{iImage}]));
    fMask = imread([mDirs{1} filesep mNames{1}{iImage}]);    
    bImage = double(imread([imDirs{2} filesep imNames{2}{iImage}]));
    bMask = imread([mDirs{2} filesep mNames{2}{iImage}]);    
    
    %Combine the masks
    combMask = bMask & fMask;
        
    %Fit a line to the current images
    [fitCoef(iImage,:),tmp] = polyfit(fImage(combMask(:)),...
                                                   bImage(combMask(:)),1);                                                   
    %Calculate R^2 for this fit
    lFun = @(x)(x * fitCoef(iImage,1) + fitCoef(iImage,2));
    tmp.Rsquared = 1 - sum((bImage(:) - lFun(fImage(:))) .^2) / ...
                       sum((bImage(:) - mean(bImage(:))) .^2);
    
    fitStats(iImage) = tmp; %Allow extra field for Rsquared                                                   
                                               
    %switch to the current sub-plot
    subplot(nByn,nByn,iImage)
                                               
    %Plot the values from this image in their own color
    plot(fImage(combMask(:)),bImage(combMask(:)),'.');
    hold on
    title({['Image #' num2str(iImage) ' Y = ' num2str(fitCoef(iImage,1))...
        'x + ' num2str(fitCoef(iImage,2))], ['R Squared = ' num2str(fitStats(iImage).Rsquared)]})        
    xlabel('Fluorphore Channel Intensity')
    ylabel('Bleedthrough Channel Intensity')
   
    %Overlay the line fit
    plot(xlim,xlim .* fitCoef(iImage,1) + fitCoef(iImage,2),'--r')
    
    legend('Intensity Values','Linear Fit');    
                                               
end


%Get the average slope and intercept
avgCoef = mean(fitCoef(:,1)); 
stdCoef = std(fitCoef(:,1));



%% ---- Output ----- %%


%Finish and save the figure
figure(allFig)
outDir = [movieData.outputDirectory_ filesep dName];
if ~exist(outDir,'dir')
    mkdir(outDir);
end
hgsave(allFig,[outDir filesep 'bleedthrough plot.fig'])

%Save the results

%Modify the filename to reflect the channels used.
fileName = [fName '_channel_' num2str(fChan) '_to_channel_' ...
            num2str(bChan) '.mat'];
save([movieData.outputDirectory_ filesep fileName],'avgCoef','stdCoef','fitCoef','fitStats')

disp(['Calculated bleedthrough coefficient: ' num2str(avgCoef) ' +/- ' num2str(stdCoef)])


disp('Finished with bleedthrough calculation!')



function [fChan,bChan,fMaskChan,bMaskChan] = parseInput(argArray)



%Init output
fChan = [];
bChan = [];
fMaskChan = [];
bMaskChan = [];


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

        case 'FluorophoreChannel'
           fChan = argArray{i+1};

        case 'BleedthroughChannel'

           bChan = argArray{i+1};
           
        case 'FluorophoreMaskChannel'
            
            fMaskChan = argArray{i+1};
            
        case 'BleedthroughMaskChannel'
            
            bMaskChan = argArray{i+1};
       
       otherwise

           error(['"' argArray{i} '" is not a valid option name! Please check input!'])
    end    
end
