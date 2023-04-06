classdef RatioProcess < DoubleProcessingProcess
    
    %A class for creating ratios by dividing one channel by another using
    %ratioMovie.m
    %
    %Hunter Elliott,
    %6/2010
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
        
        function obj = RatioProcess(owner,outputDir,funParams,...                                              
                                    inImagePaths,outImagePaths)
            
                                
            
            super_args{1} = owner;
            super_args{2} = RatioProcess.getName;
            super_args{3} = @ratioMovie;                
            
            if nargin < 3 || isempty(funParams)
                if nargin <2, outputDir = owner.outputDirectory_; end
                funParams=RatioProcess.getDefaultParams(owner,outputDir);                
            end
            
            super_args{4} = funParams;    
                
            if nargin > 3
                super_args{5} = inImagePaths;
            end
            if nargin > 4
                super_args{6} = outImagePaths;
            end
                                                        
            obj = obj@DoubleProcessingProcess(super_args{:});
        end

                
    end
    methods(Static)
        function name =getName()
            name = 'Ratioing';
        end
        function h =GUI()
            h = @ratioProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory =  [outputDir  filesep 'ratio_images'];
            funParams.ChannelIndex = [];
            funParams.ApplyMasks = true;
            funParams.SegProcessIndex = []; %No default
            funParams.MaskChannelIndex = [];
            funParams.BatchMode = false;
        end
    end

end
        
        