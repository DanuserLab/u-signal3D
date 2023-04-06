classdef BiosensorsPackage < Package
    % A concrete process for Biosensor Package
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
        function obj = BiosensorsPackage (owner,varargin)
            % Construntor of class MaskProcess
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieObject'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'BiosensorsPackage'];
            end
            % Call the superclass constructor
            obj = obj@Package(super_args{:});
            
        end
        
        function [status processExceptions] = sanityCheck(obj,varargin) % throws Exception Cell Array
            % Since a new 3rd process CropShadeCorrectROIProcess is added in Nov 2022, all hard coded index after process >=3 are updated +1. by Qiongjing (Jenny) Zou, Nov 2022
            nProcesses = length(obj.getProcessClassNames);
            
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.addRequired('obj');
            ip.addOptional('full',true, @(x) islogical(x));
            ip.addOptional('procID',1:nProcesses,@(x) (isvector(x) && ~any(x>nProcesses)) || strcmp(x,'all'));
            ip.parse(obj,varargin{:});
            full = ip.Results.full;
            procID = ip.Results.procID;
            if strcmp(procID,'all'), procID = 1:nProcesses;end
            
            [status processExceptions] = sanityCheck@Package(obj,full,procID);
            
            if ~full, return; end
            
            validProc = procID(~cellfun(@isempty,obj.processes_(procID)));
            for i = validProc
                parentIndex = obj.getParent(i);
                if length(parentIndex) > 1
                    switch i
                        case 7 %6
                            parentIndex = 2;
                        case 8 %7
                            parentIndex = 7; %6;
                        case 9 %8
                            parentIndex = 7; %6;
                        case 10 %9
                            parentIndex = 7; %6;
                        case 12 %1111
                            parentIndex = 10; %9;
                        otherwise
                            parentIndex = parentIndex(1);
                    end
                    
                end
                
                % Check if input channels are included in dependent
                % processes
                if  ~isempty(parentIndex) && ~isempty(obj.processes_{parentIndex})
                    tmp =setdiff(obj.processes_{i}.funParams_.ChannelIndex, ...
                        union(obj.processes_{parentIndex}.funParams_.ChannelIndex,...
                        find(obj.processes_{parentIndex}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        
                        if length(tmp) ==1
                            
                            ME = MException('lccb:input:fatal',...
                                'Input channel ''%s'' is not included in step %d. Please include this channel in %d step or change another input channel for the current step.',...
                                obj.owner_.channels_(tmp).channelPath_, parentIndex, parentIndex);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one input channels are not included in step %d. Please include these channels in %d step or change other input channels for the current step.',...
                                parentIndex, parentIndex);
                        end
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of mask channels in Background
                % Subtraction Process (step 7 in biosensors package)
                if i == 7 &&  ~isempty(obj.processes_{5})
                    tmp = setdiff(obj.processes_{i}.funParams_.MaskChannelIndex, ...
                        union(obj.processes_{5}.funParams_.ChannelIndex,...
                        find(obj.processes_{5}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The mask channel ''%s'' is not included in step 5 (Background Mask Creation). Please include this channel in step 5 or change to another channel that has mask.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one mask channels are not included in step 5 (Background Mask Creation). Please include these channels in step 5 or change to other channels that have masks.');
                        end
                        %                               processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of bleed channels in Bleedthrough
                % Correction Process (step 9 in biosensors package)
                if i == 9 && ~isempty(obj.processes_{7})
                    
                    validChannels = union(obj.processes_{7}.funParams_.ChannelIndex,...
                        find(obj.processes_{7}.checkChannelOutput));
                    correctionChannels = find(sum(obj.processes_{i}.funParams_.Coefficients,2)>0);
                    tmp = setdiff(correctionChannels,validChannels);
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The bleedthrough channel ''%s'' is not included in step 7 (Background Subtraction). Please include this channel in step 7 or change to another bleedthrough channel that is background-subtracted.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one bleedthrough channels are not included in step 7 (Background Subtraction). Please include these channels in step 7 or change to other bleedthrough channels that are background-subtracted.');
                        end
                        %                                 processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of mask channesl in Ratio Process
                % (step 10 in biosensors package)
                if i == 10 && ~isempty(obj.processes_{4})
                    tmp = setdiff(obj.processes_{i}.funParams_.MaskChannelIndex, ...
                        union(obj.processes_{4}.funParams_.ChannelIndex,...
                        find(obj.processes_{4}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The mask channel ''%s'' is not included in step 4 (Segmentation). Please include this channel in step 4 or change to another channel that has mask.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one mask channels are not included in step 4 (Segmentation). Please include these channels in step 4 or change to other channels that have masks.');
                        end
                        %                                 processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Photobleach and Output step:
                % Check if input channel (single channel) is the numerator of ratio channel
                if ismember(i,[11 12]) &&  ~isempty(obj.processes_{10})
                    hasPBoutput = obj.processes_{10}.checkChannelOutput;
                    
                    if obj.processes_{i}.funParams_.ChannelIndex ~= ...
                            obj.processes_{10}.funParams_.ChannelIndex(1) && ...
                            ~hasPBoutput(obj.processes_{i}.funParams_.ChannelIndex )
                        
                        ME = MException('lccb:input:fatal',...
                            'The input channel of current step must be the numerator of ratio channels. There can be multiple numerator channels generated by Ratioing step (step 10) in multiple times of processing.');
                        processExceptions{i} = [ME, processExceptions{i}];
                        
                    end
                end

                % Set the process index of CropShadeCorrectROIProcess
                % CropShadeCorrectROIProcess (3) is dependent on ShadeCorrectionProcess (2)
                if i == 3 && ~isempty(obj.processes_{2})                    
                    parseProcessParams(obj.processes_{i},...
                        struct('ProcessIndex',obj.owner_.getProcessIndex(obj.processes_{2})));
                end
                
                % Set the process index of segmentationProcess
                % SegmentationProcess (4) is dependent on ShadeCorrectionProcess (2)
                if i == 4 && ~isempty(obj.processes_{2}) && isempty(obj.processes_{3})                    
                    parseProcessParams(obj.processes_{i},...
                        struct('ProcessIndex',obj.owner_.getProcessIndex(obj.processes_{2})));
                end
                % If CropShadeCorrectROIProcess (3) run, use its output as input of SegmentationProcess (4):
                if i == 4 && ~isempty(obj.processes_{3})                    
                    parseProcessParams(obj.processes_{i},...
                        struct('ProcessIndex',obj.owner_.getProcessIndex(obj.processes_{3})));
                end
                
                % Set the process index of bleedthrough correction
                if i == 9 
                    processIndex=[];
                    for parentProcId = [7 8]
                        parentProc= obj.processes_{parentProcId};
                        if ~isempty(parentProc)
                            processIndex=horzcat(processIndex,...
                                obj.owner_.getProcessIndex(parentProc)); %#ok<AGROW>
                        end
                    end
                    parseProcessParams(obj.processes_{i},struct('ProcessIndex',processIndex));
                end                
            end
            
            % Hard-coded, when processing processes 2,4,8,10,  add mask
            % process to the processes' funParams_.SegProcessIndex
            %
            % If only segmentation process exists:
            %       funParams.SegProcessIndex = [SegmentationProcessIndex]
            %
            % If segmentation and maskrefinement processes both exist:
            %       funParams.SegProcessIndex = [MaskrefinementProcessIndex,  SegmentationProcessIndex]
            %
            
            for i = intersect(validProc, [5 6 8 10])
                if ~isempty(obj.processes_{4}) % Segmentation process
                    
                    segPI = find(cellfun(@(x)isequal(x, obj.processes_{4}), obj.owner_.processes_));
                    if length(segPI) > 1
                        error('User-defined: More than one identical Threshold processes exists in movie data''s process list.')
                    end
                    funParams.SegProcessIndex = segPI;
                    
                    % If mask transformation or ratioing process, find
                    % if any mask refinement is done
                    if i == 8 || i == 10 && ~isempty(obj.processes_{6})
                        segPI = find(cellfun(@(x)isequal(x, obj.processes_{6}), obj.owner_.processes_));
                        if length(segPI) > 1
                            error('User-defined: More than one identical MaskRefinement processes exists in movie data''s process list.')
                        end
                        funParams.SegProcessIndex = cat(2, funParams.SegProcessIndex, segPI);
                    end
                    
                    % if ratioing process, find if there is any mask
                    % refinement process
                    if i == 10
                        segPI=getProcessIndex(obj.owner_,'MaskTransformationProcess',Inf,0);
                        if ~isempty(segPI)
                            funParams.SegProcessIndex = cat(2, funParams.SegProcessIndex, segPI);
                        end
                    end
                else
                    funParams.SegProcessIndex = [];
                end
                parseProcessParams(obj.processes_{i},funParams);
            end
        end
        
    end
    methods (Static)
        
        function name = getName()
            name = 'Biosensors';
        end
        
        function m = getDependencyMatrix(i,j)
            
            m = [0 0 0 0 0 0 0 0 0 0 0 0;  %1  DarkCurrentCorrectionProcess
                 2 0 0 0 0 0 0 0 0 0 0 0;  %2  ShadeCorrectionProcess
                 0 1 0 0 0 0 0 0 0 0 0 0;  %3  CropShadeCorrectROIProcess % added Nov 2022 by Qiongjing (Jenny) Zou
                 0 1 2 0 0 0 0 0 0 0 0 0;  %4  SegmentationProcess % this step is dependent to step 2 and optional to step 3
                 0 0 0 1 0 0 0 0 0 0 0 0;  %5  BackgroundMasksProcess
                 0 0 0 1 0 0 0 0 0 0 0 0;  %6  MaskRefinementProcess
                 0 1 0 0 1 0 0 0 0 0 0 0;  %7  BackgroundSubtractionProcess
                 0 0 0 1 0 2 1 0 0 0 0 0;  %8  TransformationProcess
                 0 0 0 0 0 0 1 2 0 0 0 0;  %9  BleedthroughCorrectionProcess
                 0 0 0 1 0 2 1 2 2 0 0 0;  %10 RatioProcess
                 0 0 0 0 0 0 0 0 0 1 0 0;  %11 PhotobleachCorrectionProcess
                 0 0 0 0 0 0 0 0 0 1 2 0]; %12 OutputRatioProcess
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end
        
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = biosensorsPackageGUI(varargin{:});
        end
        function procConstr = getDefaultProcessConstructors(index)
            biosensorsConstr = {
                @DarkCurrentCorrectionProcess,...
                @ShadeCorrectionProcess,...
                @CropShadeCorrectROIProcess,...
                @ThresholdProcess,...
                @BackgroundMasksProcess,...
                @MaskRefinementProcess,...
                @BackgroundSubtractionProcess,...
                @TransformationProcess,...
                @BleedthroughCorrectionProcess,...
                @RatioProcess,...
                @PhotobleachCorrectionProcess,...
                @OutputRatioProcess...
                };
            if nargin==0, index=1:numel(biosensorsConstr); end
            procConstr=biosensorsConstr(index);
        end
        function classes = getProcessClassNames(index)
            biosensorsClasses = {
                'DarkCurrentCorrectionProcess',...
                'ShadeCorrectionProcess',...
                'CropShadeCorrectROIProcess',...
                'SegmentationProcess',...
                'BackgroundMasksProcess',...
                'MaskRefinementProcess',...
                'BackgroundSubtractionProcess',...
                'TransformationProcess',...
                'BleedthroughCorrectionProcess',...
                'RatioProcess',...
                'PhotobleachCorrectionProcess',...
                'OutputRatioProcess'};
            if nargin==0, index=1:numel(biosensorsClasses); end
            classes=biosensorsClasses(index);
        end
        
        function tools = getTools(index)
            biosensorsTools(1).name = 'Bleedthrough coefficient calculation';
            biosensorsTools(1).funHandle = @calculateBleedthroughGUI;
            biosensorsTools(2).name = 'Alignment/Registration Transform Creation';
            biosensorsTools(2).funHandle = @transformCreationGUI;
            if nargin==0, index=1:numel(biosensorsTools); end
            tools=biosensorsTools(index);
        end
    end
    
end