classdef ImageCorrectionProcess < ImageProcessingProcess
    
    %A class for performing corrections on images using other "correction"
    %images.
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
        
        function obj = ImageCorrectionProcess(owner,name,funName,funParams,...                                              
                                              inImagePaths,outImagePaths,...
                                              correctionImagePaths)
            
            if nargin == 0
                super_args = {};
            else
                                
                super_args{1} = owner;
                super_args{2} = name;
                if nargin > 2
                    super_args{3} = funName;                
                end
                if nargin > 3                    
                    super_args{4} = funParams;                                    
                end                                
                
                if nargin > 4
                    super_args{5} = inImagePaths;
                end
                if nargin > 5
                    super_args{6} = outImagePaths;
                end
                                
            end
            
            obj = obj@ImageProcessingProcess(super_args{:});
            
            if nargin > 6
                obj.inFilePaths_(2,:) = correctionImagePaths;
            else
                obj.inFilePaths_(2,:) = cell(1,numel(owner.channels_));
            end
            
        end                 
        
        function setCorrectionImagePath(obj, iChan, imagePaths)
            % Register the correction image paths for the input channels

            % Input check
            assert(all(obj.checkChanNum(iChan)), 'lccb:set:fatal',...
                'Invalid image channel number for correction image path!\n\n');
            nChan = length(iChan);
            if ~iscell(imagePaths)
                imagePaths = {imagePaths};
            end
            assert(numel(imagePaths) == nChan, 'lccb:set:fatal',...
                ['You must specify one image path for each correction image'...
                 ' channel!']);
            isValidDir = @(x) exist(x,'dir') && numel(imDir(x)) > 0;
            for j = 1:nChan
                assert(isempty(imagePaths{j}) || isValidDir(imagePaths{j}),...
                    ['The correction image path specified for channel '...
                     num2str(iChan(j)) ' is not a valid image-containing'...
                     ' directory!']);
                obj.inFilePaths_{2, iChan(j)} = imagePaths{j};
            end
        end
        
        function fileNames = getCorrectionImageFileNames(obj,iChan)
            if obj.checkChanNum(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.inFilePaths_(2,iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if any(nIm == 0)
                    error('No images in one or more correction channels!')
                end                
            else
                error('lccb:set:fatal','Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
        end
        
        function setOutImagePath(obj,chanNum,imagePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n'); 
            end
            
            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1:nChan
               if ~exist(imagePath{j},'dir')
                   error('lccb:set:fatal',...
                       ['The directory specified for channel ' ...
                       num2str(chanNum(j)) ' is invalid!']) 
               else
                   obj.outFilePaths_{1,chanNum(j)} = imagePath{j};                
               end
            end
            
            
        end   
        function h = draw(obj,iChan,varargin)
             
            outputList = obj.getDrawableOutput();
            drawAvgCorrImage = any(strcmpi('avgCorrImage',varargin));
            
            if drawAvgCorrImage
                % Input check
                ip =inputParser;
                ip.addRequired('iChan',@(x) ismember(x,1:numel(obj.owner_.channels_)));
                ip.addParamValue('output',[],@ischar);
                ip.KeepUnmatched = true;
                ip.parse(iChan,varargin{:})
                
                % Load average corrected image
                s = load(obj.outFilePaths_{2,iChan});
                tmpFields=fieldnames(s);
                data=s.(tmpFields{1});
                
                iOutput= find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));
                if ~isempty(outputList(iOutput).formatData),
                    data=outputList(iOutput).formatData(data);
                end
            
                try
                    assert(~isempty(obj.displayMethod_{iOutput,iChan}));
                catch ME
                    obj.displayMethod_{iOutput,iChan}=...
                        outputList(iOutput).defaultDisplayMethod(iChan);
                end
                
                % Delegate to the corresponding method
                tag = ['process' num2str(obj.getIndex) '_channel' num2str(iChan) '_output' num2str(iOutput)];
                drawArgs=reshape([fieldnames(ip.Unmatched) struct2cell(ip.Unmatched)]',...
                    2*numel(fieldnames(ip.Unmatched)),1);
                h=obj.displayMethod_{iOutput,iChan}.draw(data,tag,drawArgs{:});
            else
                h=draw@ImageProcessingProcess(obj,iChan,varargin{1},varargin{2:end});
            end
        end
        
        function output = getDrawableOutput(obj)
            output = ImageProcessingProcess.getDrawableOutput();
            output(end+1).name='Averaged correction images';
            output(end).var='avgCorrImage';
            output(end).formatData=[];
            output(end).type='graph';
            output(end).defaultDisplayMethod=@(x) ImageDisplay('Colormap','jet',...
                'Colorbar','on','CLim',obj.getCorrectionLimits(x));
        end
        
    end
    
    methods (Access=protected)
        function limits = getCorrectionLimits(obj,iChan)
            s = load(obj.outFilePaths_{2,iChan});
            tmpFields=fieldnames(s);
            data=s.(tmpFields{1});
            limits=[min(data(:)) max(data(:))];
        end
    end
end
