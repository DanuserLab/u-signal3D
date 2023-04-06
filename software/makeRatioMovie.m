function makeRatioMovie(movieData,varargin)
%MAKERATIOMOVIE makes a .avi or .mov from the biosensor ratio images in the input movie 
% 
% makeRatioMovie();
% makeRatioMovie(movieData);
% makeRatioMovie(movieData,'OptionName1',optionValue1,'OptionName2',optionValue2,...)
%
% This function creates and saves a .avi or quicktime (.mov) movie from the
% ratio images for the input movie. It assumes that the input movie has
% been successfully processed with the biosensor processing package
% (biosensorsPackageGUI.m) By default, the images will be displayed with
% the "jet" colormap - with red being high activity and blue being low
% activity. Also by default, the color scale will adjusted to cover the
% full range of values for each image, and a color scale will be displayed
% next to the images.
% 
% 
%  NOTE: This function is actually just a wrapper for the more-general
%  function "makeMovieMovie.m". See this function for more advanced
%  options for movie-making.
%
% Input:
% 
%   movieData - A valid MovieData object for a movie which has been
%   processed using the biosensor processing package
%   (biosensorsPackageGUI). Optional. If not input, the user will be asked
%   to click on the the movieData file.
%
%   'OptionName',optionValue - A string with an option name followed by the
%   value for that option. 
%
%     Possible option name/value pairs:
%
%       ('Saturate' -> Positive scalar >= 0 and < 1) This specifies the
%       fraction of the ratio values to allow to appear saturated in the
%       color scale. That is, if it is set to 0 the color scale will cover
%       the entire range of the ratio values, from maximum to minimum (no
%       saturation). If it is set to .05, then 95% of the data will fit
%       between the max and min of the color scale, but values outside this
%       range will be saturated. Smaller values for this parameter will
%       make small variations in the ratios easier to see, but will
%       saturate very active/inactive areas. Default is 0 (no saturation).
%
%       ('ConstantScale' -> true/false) If true, the color scale used for
%       the first image will be used throughout the movie. If false, the
%       range will be selected sparately for each frame.
%
%       ('ColorBar' -> true/false) If true, a bar showing the color scale
%       (that is the ratio value associated with each color in the movie)
%       will be displayed. Optional. Default is true.
%
%       ('MakeAvi' -> Logical scalar) If true, the movie will be saved as .avi.
%       Optional. Default is false.
%
%       ('MakeMov' -> Logical scalar) If true, movie will be saved as .mov.
%       Optional. Default is true.             
%
% Output:
% 
%   Each ratio image will be displayed on the screen sequentially, and then
%   the movie will be saved to a file at the location specified by the
%   movie's outputDirectory (movieData.outputDirectory_) with the name
%   "ratioMovie.avi" and/or "ratioMovie.mov"
%
%
% Hunter Elliott
% 10/2010
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

%% -------------- Input ------------- %%

%If the user didn't input a movieData, ask them to select the file
%containing it.
if nargin < 1 || isempty(movieData)
    
   [mdFileName,mdPath] = uigetfile('movieData.mat','Select the movieData to use:');   
   
   if mdFileName == 0
       error('You must specify a valid movieData.mat file to make a ratio movie!')
   end
   %Load and check the movieData file
   mdFile = load([mdPath filesep mdFileName]);
   fieldNames = fieldnames(mdFile);
   if numel(fNames) > 1 || ~isa(mdFile.(fieldNames{1}),'MovieData')
       error('Invalid movieData file! Check the file contents please - must contain only 1 valid MovieData object!')
   end
   
   movieData = mdFile.(fieldNames{1});   
    
elseif ~isa(movieData,'MovieData')
    error('Invalid MovieData object! First input must be empty or a valid MovieData object!');
end

%Check that the movie has been processed successfully
iRatProc = movieData.getProcessIndex('RatioProcess',1,1);
if isempty(iRatProc)
    error('The input movieData has not been successfully ratioed! Please check processing!')
end

%Get the ratio numerator channel
iNumChan = find(cellfun(@(x)(~isempty(x)),movieData.processes_{iRatProc}.outFilePaths_));

%Check if photobleach correction has been done
iPbProc = movieData.getProcessIndex('PhotobleachCorrectionProcess',1,1);
if isempty(iPbProc) || ~movieData.processes_{iPbProc}.checkChannelOutput(iNumChan)
    disp('No valid photobleach correction found - using un-corrected ratio images.')
    iProc = iRatProc;
else
    iProc = iPbProc;
end


%% ------------ Make Movie! ----------- %%

%Create argument array for call to makeMovieMovie.m Later arguments will
%override earlier arguments, so the user can override any of these.
argArray = {'FileName','ratioMovie',...
            'ProcessIndex',iProc,...
            'ChannelIndex',iNumChan,...
            'ColorMap','jet',...
            'ColorBar',true};
        
if nargin > 1
    argArray = [argArray varargin];
end   

%Call makeMovieMovie to do the actual movie-making
makeMovieMovie(movieData,argArray{:});


