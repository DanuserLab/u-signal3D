classdef MaskTransformationProcess < MaskProcessingProcess
    %A concrete process for processing masks using a transformation matrix
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
        function obj = MaskTransformationProcess(owner,varargin)
            
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
                super_args{2} = MaskTransformationProcess.getName;
                super_args{3} = @transformMovieMasks;
                if isempty(funParams)
                    funParams=MaskTransformationProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            
            obj = obj@MaskProcessingProcess(super_args{:});
            
        end
        function setTransformFilePath(obj,iChan,transformPath)
            
            %Make sure the specified channels are valid
            if ~obj.checkChanNum(iChan)
                error('The channel indices specified for transform files are invalid!')
            end
            
            %If only one transform path was input, convert to a cell
            if ~iscell(transformPath)
                transformPath = {transformPath};
            end
            if length(iChan) ~= length(transformPath)
                error('A sparate path must be specified for each channel!')
            end
            
            for j = 1:length(iChan)
                
                if exist(transformPath{j},'file')
                    obj.funParams_.TransformFilePaths(iChan(j)) = transformPath(j);
                else
                    error(['The transform file name specified for channel ' ...
                        num2str(iChan(j)) ' is not valid!!'])
                end
            end
            
        end
        
        function transforms = getTransformation(obj,iChan)
            
            %Loads and checks specified transformation(s).
            if ~ obj.checkChanNum(iChan)
                error('Invalid channel index!')
            end
            
            nChan = length(iChan);
            transforms = cell(1,nChan);
            
            for j = 1:nChan
                
                tmp = load(obj.funParams_.TransformFilePaths{iChan(j)});
                
                fNames = fieldnames(tmp);
                
                isXform = cellfun(@(x)(istransform(tmp.(x))),fNames);
                
                if ~any(isXform)
                    error(['The transform file specified for channel ' ...
                        num2str(iChan(j)) ...
                        '  does not contain a valid image transformation!']);
                elseif sum(isXform) > 1
                    error(['The transform file specified for channel ' ...
                        num2str(iChan(j)) ...
                        '  contains more than one valid image transformation!']);
                else
                    transforms{j} = tmp.(fNames{isXform});
                end
                
            end
        end
    end
    methods(Static)
        function name =getName()
            name = 'Mask Transformation';
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.ChannelIndex = 1:numel(owner.channels_); %Default is to transform masks for all channels
            funParams.SegProcessIndex = []; %No default...
            funParams.OutputDirectory = [outputDir filesep 'transformed_masks'];
            funParams.TransformFilePaths = cell(1,numel(owner.channels_));%No default...
            funParams.BatchMode = false;
        end
    end
end