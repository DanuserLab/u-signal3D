classdef BleedthroughCorrectionProcess < ImageCorrectionProcess   
    %A class for performing bleedthrough correction on images.
    %
    %Hunter Elliott, 5/2010
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
        
        function obj = BleedthroughCorrectionProcess(owner,outputDir,funParams)
                                              
            if nargin == 0
                super_args = {};
            else                       
                super_args{1} = owner;
                super_args{2} = BleedthroughCorrectionProcess.getName;
                super_args{3} = @bleedthroughCorrectMovie;                               
                if nargin<2, outputDir = owner.outputDirectory_; end
                if nargin < 3 || isempty(funParams) 
                    funParams=BleedthroughCorrectionProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;    
            end
            
            obj = obj@ImageCorrectionProcess(super_args{:});
        end   
        
    end
    methods (Static)
        function name =getName()
            name = 'Bleedthrough/Crosstalk Correction';
        end
        function h = GUI()
            h= @bleedthroughCorrectionProcessGUI;
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory = [outputDir  filesep 'bleedthrough_corrected_images'];
            funParams.ChannelIndex = [];%No default
            funParams.ProcessIndex = [];%No default
            funParams.Coefficients = zeros(numel(owner.channels_),2);%No default
            funParams.BatchMode = false;      
        end
    end
end                                           