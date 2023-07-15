classdef  CalculateLaplaceBeltramiProcess < DataProcessingProcess & NonSingularProcess
    % Process Class for calculating Laplace-Beltrami
    % calculateLBMeshMD.m is the wrapper function
    % CalculateLaplaceBeltramiProcess is part of uSignal3D package
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
        function obj = CalculateLaplaceBeltramiProcess(owner, varargin)
            
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
                super_args{2} = CalculateLaplaceBeltramiProcess.getName;
                super_args{3} = @calculateLBMeshMD;
                if isempty(funParams)
                    funParams = CalculateLaplaceBeltramiProcess.getDefaultParams(owner,outputDir);
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
            name = 'Calculate Laplace Beltrami';
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
            funParams.OutputDirectory = [outputDir  filesep 'Laplacian'];
            % funParams.OutputDirectory = [outputDir  filesep 'Morphology' filesep 'Analysis' filesep 'Laplacian']; % QZ TODO
            
            funParams.mesh3DProcessIndex = []; % QZ TODO may need to rename to meshProcessIndex, if a external mesh process written.
            % QZ does not work, commented out funParams.externalMeshFilePat
            % funParams.externalMeshFilePath = []; % Added parameter, to give option to use external mesh instead of from mesh3DProcess's output.
            %                                      % must be the whole path including file name as *_c_t.mat, such as surface_1_1.mat.
            funParams.intensity3DProcessIndex = [];
            funParams.frameIndex = 1:owner.nFrames_; % t, time index
            
            funParams.LBMode = 'cotan'; % will check nonmanifold vertices to set the LB.method automatically to be 'tuftedMesh' or 'cotan'.
            funParams.nEigenvec = 1000; % put 1000 as default now
            funParams.calEigenProj = 1; %flag for calculating eigenprojection
            funParams.reconstIntensity = 1; %flag for recosntructing signal
            funParams.useLBFilter = 1; %flag to denoise (filter out) the signal
            funParams.maxLBfrequencyIndex = 100; %maximum frequency index for filtering the signal
        end
    end
end
