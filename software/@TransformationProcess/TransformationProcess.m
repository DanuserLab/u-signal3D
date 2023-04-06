classdef TransformationProcess < ImageProcessingProcess
    
    %A class for applying spatial transformations to images using
    %transformMovie.m
    %
    %Hunter Elliott, 5/2010
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
    
    
    methods (Access = public)
        
        
        function obj = TransformationProcess(owner,outputDir,funParams,...
                inImagePaths,outImagePaths,...
                transformFilePath)
            
            if nargin == 0
                super_args = {};
            else
                
                super_args{1} = owner;
                super_args{2} = TransformationProcess.getName;
                super_args{3} = @transformMovie;
                
                if nargin < 3 || isempty(funParams)
                    if nargin <2, outputDir = owner.outputDirectory_; end
                    funParams=TransformationProcess.getDefaultParams(owner,outputDir);
                    
                end
                
                super_args{4} = funParams;
                
                if nargin > 3
                    super_args{5} = inImagePaths;
                end
                if nargin > 4
                    super_args{6} = outImagePaths;
                end
                
            end
            
            obj = obj@ImageProcessingProcess(super_args{:});
            
            if nargin > 5
                setTransformFilePath(transformFilePath);
            end
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
                    obj.funParams_.TransformFilePaths{iChan(j)} = transformPath{j};
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
        function h = resultDisplay(obj)
            
            %Overrides the default result display so the transformed image can be
            %compared to the other channels.
            
            
            %Now Give the user the option to compare the alignment between
            %two channels
            
            %Find out which channel(s) have been transformed
            hasX = obj.checkChannelOutput;
            iHasX = find(hasX);
            if numel(iHasX) > 1
                chanList = arrayfun(@(x)(['Channel ' num2str(x)]),...
                    iHasX,'UniformOutput',false);
                
                iXchan = listdlg('ListString',chanList,'ListSize',[500 500],...
                    'SelectionMode','single',...
                    'PromptString','Select a transformed channel to view:');
                
                if isempty(iXchan)
                    h = 1000;%Return SOMETHING so charles' gui doesn't go nuts
                    return
                else
                    iXchan = iHasX(iXchan);
                end
            elseif numel(iHasX) == 1
                iXchan = iHasX;
            else
                error('There are no transformed channels to view!')
            end
            
            
            chanList = arrayfun(@(x)(['Channel ' num2str(x)]),...
                1:numel(obj.owner_.channels_),'UniformOutput',false);
            
            iComp = listdlg('ListString',chanList,'ListSize',[500 500],...
                'SelectionMode','single',...
                'PromptString','Select a channel to compare transformed channel to:');
            
            if isempty(iComp)
                h = 1000;
                return
            end
            
            nIm = obj.owner_.nFrames_;
            
            %Load and display the images.
            if isa(obj.owner_.getReader,'BioFormatsReader')
                compIm1 = obj.owner_.getReader.loadImage(iComp,1);
            else
                compDir = obj.owner_.channels_(iComp).channelPath_;
                compName = obj.owner_.getImageFileNames(iComp);
                compIm1 = imread([compDir filesep compName{1}{1}]);
            end
            
            xDir = obj.outFilePaths_{1,iXchan};
            xName = obj.getOutImageFileNames(iXchan);
            xIm1 = imread([xDir filesep xName{1}{1}]);
            
            h = fsFigure(.75);
            
            if nIm > 1
                if isa(obj.owner_.getReader,'BioFormatsReader')
                    compIm2 =  obj.owner_.getReader.loadImage(iComp,nIm);
                else
                    compIm2 = imread([compDir filesep compName{1}{end}]);
                end
                xIm2 = imread([xDir filesep xName{1}{end}]);
                subplot(1,2,1)
            end
            image(cat(3,mat2gray(xIm1),mat2gray(compIm1),zeros(size(compIm1))));
            axis image,axis off
            title({'Transformed image (Red) and comparison image (green)','Overlay of frame 1'})
            if nIm > 1
                subplot(1,2,2)
                image(cat(3,mat2gray(xIm2),mat2gray(compIm2),zeros(size(compIm1))));
                title(['Overlay of frame ' num2str(nIm)])
                axis image,axis off
            end
            
        end
        
        function sanityCheck(obj)
            sanityCheck@ImageProcessingProcess(obj);
            % Performs additional check on the existence of transformation
            % files
            transformFilePaths = obj.funParams_.TransformFilePaths;
            validTransformFiles = ~cellfun(@isempty,transformFilePaths);

            for i=find(validTransformFiles)
                if ~exist(transformFilePaths{i},'file') 
                    error('lccb:set:fatal', ...
                        ['The specified transformation file:\n\n ',transformFilePaths{i}, ...
                        '\n\ndoes not exist. Please double check your path.'])
                end
            end
        end
        
        
    end
    methods(Static)
        function name =getName()
            name = 'Transformation';
        end
        function h = GUI()
            h= @transformationProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory = ...
                [outputDir  filesep 'transformed_images'];
            funParams.ChannelIndex = 1 : numel(owner.channels_);
            funParams.TransformFilePaths = cell(1,numel(owner.channels_));%No default...
            funParams.TransformMasks = true;
            funParams.SegProcessIndex = []; %No Default
            funParams.BatchMode = false;
        end
    end
end