classdef MaskRefinementProcess < MaskProcessingProcess
    %Class definition for post processing using refineMovieMasks.m
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
    
    
    methods(Access = public)        
        function obj = MaskRefinementProcess(owner,varargin)
            
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
                super_args{2} = MaskRefinementProcess.getName;
                super_args{3} = @refineMovieMasks;                               
                if isempty(funParams)                                       
                    funParams = MaskRefinementProcess.getDefaultParams(owner,outputDir);                               
                end
                super_args{4} = funParams;                    
            end
            
            obj = obj@MaskProcessingProcess(super_args{:});
        end                  
    end
    methods(Static)
        function name =getName()
            name = 'Mask Refinement';
        end
        function h = GUI()
            h= @maskRefinementProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:});
            outputDir=ip.Results.outputDir;
            
            % Define default process parameters
            funParams.ChannelIndex = 1:numel(owner.channels_);
            funParams.SegProcessIndex = []; %No default.
            funParams.OutputDirectory = [outputDir  filesep 'refined_masks'];
            funParams.MaskCleanUp = true;
            funParams.MinimumSize = 10;
            funParams.ClosureRadius = 3;
            funParams.OpeningRadius = 0;
            funParams.ObjectNumber = 1; %only 1 object per mask
            funParams.FillHoles = true;
            funParams.FillBoundaryHoles = true; % if true, if the mask boundary touches two adjacent edges of the image, the hole in between will be filled.
            funParams.SuppressBorder = false;
            funParams.EdgeRefinement = false; %This off by default because it sort of sucks, and is slow.
            funParams.MaxEdgeAdjust = []; %Use refineMaskEdges.m function defaults for these settings
            funParams.MaxEdgeGap = [];
            funParams.PreEdgeGrow = [];
            funParams.BatchMode = false;
        end
    end
end
    