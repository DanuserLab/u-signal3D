classdef uSignal3DPackage < Package
    % The main class of the u-Signal3D Package
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
    
    methods
        function obj = uSignal3DPackage(owner,varargin)
            % Constructor of class uSignal3DPackage
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'uSignal3DPackage'];
            end
                 
            % Call the superclass constructor
            obj = obj@Package(super_args{:});        
        end
        
        function [status, processExceptions] = sanityCheck(obj, varargin) % throws Exception Cell Array
            
            % %% TODO - add more to sanitycheck
            % disp('TODO: SanityCheck!');
            missingMetadataMsg = ['Missing %s! The %s is necessary to analyze '...
            '3D Cells. Please edit the movie and fill the %s.'];
            errorMsg = @(x) sprintf(missingMetadataMsg, x, x, x);
            
            assert(obj.owner_.is3D, errorMsg('MovieData is not 3D!'));
            assert(~isempty(obj.owner_.pixelSize_), errorMsg('pixel size not defined!'));
            assert(~isempty(obj.owner_.pixelSizeZ_), errorMsg('pixel Z size defined!'));
            [status, processExceptions] = sanityCheck@Package(obj, varargin{:});

        end
        
        % function index = getProcessIndexByName(obj, name)
        %     index = find(cellfun(@(x) strcmp(x,name), obj.getProcessClassNames()));
        % end
             
        % function status = hasProcessByName(obj, name)
        %     status = max(cellfun(@(x) strcmp(class(x),name), obj.processes_));
        % end
    end
    
    methods (Static)
        
        function name = getName()
            name = 'U-Signal 3D';
        end

        function m = getDependencyMatrix(i,j)
            %    1  2  3  4  5  6 {processes}
            m = [0  0  0  0  0  0 ;  % 1 Deconvolution3DProcess
                 2  0  0  0  0  0 ;  % 2 ComputeMIPProcess   
                 2  0  0  0  0  0 ;  % 3 Mesh3DProcess
                 2  0  1  0  0  0 ;  % 4 Intensity3DProcess
                 2  0  0  1  0  0 ;  % 5 CalculateLaplaceBeltramiProcess
                 2  0  0  0  1  0 ]; % 6 MeasureEnergySpectraProcess             
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end

        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = uSignal3DPackageGUI(varargin{:});
        end

        function procConstr = getDefaultProcessConstructors(index)
            procConstr = {
                @Deconvolution3DProcess,...
                @ComputeMIPProcess,...
                @Mesh3DProcess, ...
                @Intensity3DProcess, ...
                @CalculateLaplaceBeltramiProcess , ...
                @MeasureEnergySpectraProcess};
              
            if nargin == 0, index = 1 : numel(procConstr); end
            procConstr = procConstr(index);
        end

        function classes = getProcessClassNames(index)
            classes = {
                'Deconvolution3DProcess',...
                'ComputeMIPProcess',...
                'Mesh3DProcess',...
                'Intensity3DProcess', ...
                'CalculateLaplaceBeltramiProcess', ...
                'MeasureEnergySpectraProcess'};         
            if nargin == 0, index = 1 : numel(classes); end
            classes = classes(index);
        end
    end  
end
