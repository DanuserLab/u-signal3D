classdef PhotobleachCorrectionProcess < DoubleProcessingProcess
    
    %A class for performing photobleach correction on ratio images.
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
        
        function obj = PhotobleachCorrectionProcess(owner,outputDir,funParams)
                                              
            if nargin == 0
                super_args = {};
            else                
                
                super_args{1} = owner;
                super_args{2} = PhotobleachCorrectionProcess.getName;
                super_args{3} = @photobleachCorrectMovieRatios;                               
                
                if nargin < 3 || isempty(funParams)   
                    if nargin <2, outputDir = owner.outputDirectory_; end
                    funParams=PhotobleachCorrectionProcess.getDefaultParams(owner,outputDir);                                                                                                
                end
                
                super_args{4} = funParams;    
                                
            end
            obj = obj@DoubleProcessingProcess(super_args{:});
        end
        
        function h=draw(obj,varargin)
            % Function to draw process output
            
            outputList = obj.getDrawableOutput();
            drawFit = any(strcmpi('fit',varargin));
            
            if drawFit
                ip = inputParser;
                data=[obj.funParams_.OutputDirectory  filesep obj.funParams_.figName];
                iOutput= 2;
                if ~isempty(outputList(iOutput).formatData),
                    data=outputList(iOutput).formatData(data);
                end
                try
                    assert(~isempty(obj.displayMethod_{iOutput,1}));
                catch ME
                    obj.displayMethod_{iOutput,1}=...
                        outputList(iOutput).defaultDisplayMethod();
                end
                
                % Delegate to the corresponding method
                tag = ['process' num2str(obj.getIndex) '_output' num2str(iOutput)];
                drawArgs=reshape([fieldnames(ip.Unmatched) struct2cell(ip.Unmatched)]',...
                    2*numel(fieldnames(ip.Unmatched)),1);
                h=obj.displayMethod_{iOutput}.draw(data,tag,drawArgs{:});
            else
                h=draw@DoubleProcessingProcess(obj,varargin{1},varargin{2},...
                    varargin{3:end});
            end
        end
        
        function output = getDrawableOutput(obj)
            output = getDrawableOutput@DoubleProcessingProcess(obj);
            output(2).name='Photobleach correction fit';
            output(2).var='fit';
            output(2).formatData=[];
            output(2).type='movieGraph';
            output(2).defaultDisplayMethod=@FigFileDisplay;
        end
        
        
    end
    methods(Static)
        function name =getName()
            name = 'Photobleach Correction';
        end
        function h = GUI()
            h= @photobleachCorrectionProcessGUI;
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory = [outputDir  filesep 'photobleach_corrected_images'];
            funParams.ChannelIndex = [];%No default
            funParams.CorrectionType = 'RatioOfAverages';
            funParams.BatchMode = false;
        end
    end
    
end                                   
            