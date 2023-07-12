classdef  MeasureEnergySpectraProcess < DataProcessingProcess & NonSingularProcess
    % Process Class for measuring Energy Spectra
    % measureEnergyMeshMD.m is the wrapper function
    % MeasureEnergySpectraProcess is part of uSignal3D package
    %
    % Qiongjing (Jenny) Zou, July 2022
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
    
    methods (Access = public)
        function obj = MeasureEnergySpectraProcess(owner, varargin)
            
            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                super_args{1} = owner;
                super_args{2} = MeasureEnergySpectraProcess.getName;
                super_args{3} = @measureEnergyMeshMD;
                if isempty(funParams)
                    funParams = MeasureEnergySpectraProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@DataProcessingProcess(super_args{:});
            obj.funName_ = super_args{3};
            obj.funParams_ = super_args{4};
            
            obj.is3Dcompatible_ = true;
        end
    end
    
    methods (Static)
        function name = getName()
            name = 'Measure Energy Spectra';
        end
        
        function h = GUI(varargin)
            h = @noSettingsProcessGUI;
        end
        
        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.OutputDirectory = [outputDir  filesep 'Energy'];
            % funParams.OutputDirectory = [outputDir  filesep 'Morphology' filesep 'Analysis' filesep 'Energy']; % QZ TODO
            
            funParams.LB3DProcessIndex = [];
            funParams.frameIndex = 1:owner.nFrames_; % t, time index
            
            funParams.useNormalizedEnergy = 1;
        end
    end
end
