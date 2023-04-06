classdef CropShadeCorrectROIProcess < ImageProcessingProcess & NonSingularProcess
    % A concrete process cropping output from Shade Correction process
    % see cropShadeCorrectROI.m
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

    % Qiongjing (Jenny) Zou, Nov 2022
    
    methods
        function obj = CropShadeCorrectROIProcess(owner,varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = CropShadeCorrectROIProcess.getName;
                super_args{3} = @cropShadeCorrectROI;
                if isempty(funParams)
                    funParams=CropShadeCorrectROIProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            
            obj = obj@ImageProcessingProcess(super_args{:});
        end
        
    end
    methods (Static)
        function name = getName()
            name = 'Cropping Shade Corrected Movie';
        end
        function h = GUI()
            h = @CropShadeCorrectROIProcessGUI; % also see cropMovieGUI
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner', @(x) isa(x,'MovieData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'CropROI'];
            funParams.ProcessIndex = []; %Default is to use raw images % this will be auto-set to ShadeCorrectionProcess in BiosensorsPackage, see sanityCheck in BiosensorsPackage.

            funParams.cropROIpositions = []; % [xmin ymin width height]
            funParams.currentImg = 1; % image selected for cropping ROI on GUI, does not affact algorithm

        end
    end
end