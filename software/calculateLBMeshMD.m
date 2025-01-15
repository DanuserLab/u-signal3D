function calculateLBMeshMD(movieDataOrProcess, varargin)
% calculateLBMeshMD wrapper function for calculateLBOperator
% to be executed by CalculateLaplaceBeltramiProcess.
% See also wrapFun_uSignal3D_QZ, wrapFun_uSignal3D
%
% INPUT
% movieDataOrProcess - either a MovieData (legacy)
%                      or a Process (new as of July 2016)
%
% param - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
% p.ChannelIndex       - index of the channel (multichannel image)
% 
% p.OutputDirectory    - directory where the energy will be saved
% 
% p.mesh3DProcessIndex - index of the previous run mesh3DProcess, which is used in this process
% 
% p.intensity3DProcessIndex - index of the previous run intensity3DProcess, which is used in this process
% 
% p.frameIndex         - index of the frame (time series image)
% 
% p.LBMode             - computing the Laplace-Beltrami(LB) algorithm for
%                       manifold ('cotan') and non-manifold mesh ('tufted')
% p.nEigenvec          - number of LB eigenvalues (it is limited to the
%                       number of mesh vertices) 
% p.calEigenProj       - a flag to calculate the eigenprojection of a
%                       data (fluorescent intensity) for mesh vertices
% p.reconstIntensity   - a flag to recreate data for the whole frequency 
%                       levels 
% p.useLBFilter        -a flag to recreate data for range of frequency levels  
% 
% p.reconstIntensity   -[minFreqIdx maxFreqIdx] minumum and maximum frequency
%                       index for reconstructing the intensity from LB outputs
%                       Default is [1 p.nEigenvec]
% 
% OUTPUT
% none (saved to p.OutputDirectory)
%
% Changes
% As of July 2016, the first argument could also be a Process. Use
% getOwnerAndProcess to simplify compatability.
%
% As of August 2016, the standard second argument should be the parameter
% structure
%
% Qiongjing (Jenny) Zou, July 2022
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
% 
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('MD', @(x) isa(x,'MovieData') || isa(x,'Process') && isa(x.getOwner(),'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get MovieData object and Process
[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess, 'CalculateLaplaceBeltramiProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in CalculateLaplaceBeltramiProcess

% Parameters: funParams = p;

% Sanity Checks
nChan = numel(movieData.channels_);
if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex), p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

if max(p.frameIndex) > movieData.nFrames_ || min(p.frameIndex)<1 || ~isequal(round(p.frameIndex), p.frameIndex)
    error('Invalid time index specified! Check frameIndex input!!')
end

% precondition / error checking

% The input triangle mesh takes mesh from Mesh3DProcess or ExternalMeshProcess % QZ TODO need to write ExternalMeshProcess, and their parent mesh process.
if isempty(p.mesh3DProcessIndex)
    
    p.mesh3DProcessIndex = movieData.getProcessIndex('Mesh3DProcess'); % if there is more than one Mesh3DProcess, popup menu will show up for user to choose
    
    if isempty(p.mesh3DProcessIndex)
        error("Mesh3DProcess needs to be done before run Calculate Laplace Beltrami process.")
    end 
else
    if ~isa(movieData.processes_{p.mesh3DProcessIndex},'Mesh3DProcess')
        error("Wrong Mesh3DProcess index provided!")
    end
end


if isempty(p.intensity3DProcessIndex)
    
    p.intensity3DProcessIndex = movieData.getProcessIndex('Intensity3DProcess'); % if there is more than one Intensity3DProcess, popup menu will show up for user to choose
    
    if isempty(p.intensity3DProcessIndex)
        error("Intensity3DProcess needs to be done before run Calculate Laplace Beltrami process.")
    end 
else
    if ~isa(movieData.processes_{p.intensity3DProcessIndex},'Intensity3DProcess')
        error("Wrong Intensity3DProcess index provided!")
    end
end

mesh3DProc = movieData.processes_{p.mesh3DProcessIndex};
intensity3DProc = movieData.processes_{p.intensity3DProcessIndex};

% logging input paths (bookkeeping)
inFilePaths = cell(2, numel(movieData.channels_));
for i = p.ChannelIndex
    inFilePaths{1,i} = mesh3DProc.outFilePaths_{1,i};
    inFilePaths{2,i} = intensity3DProc.outFilePaths_{1,i};
end
thisProc.setInFilePaths(inFilePaths);

% logging output paths.
mkClrDir(p.OutputDirectory);
outFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'ch' num2str(i)];
    outFilePaths{2,i} = [p.OutputDirectory]; % QZ if use external mesh file, this line does not need for saving .dae file
    mkClrDir(outFilePaths{1,i}); % no need to do mkClrDir(outFilePaths{2,i}) here.
end
thisProc.setOutFilePaths(outFilePaths);


%% Algorithm
% Edited from wrapFun_uSignal3D_QZ.m process 5 line 117 to 205
% we need surface and intensity for next processes, so for this wrap
% function, I load the surface and intensity which are results from the
% previous processes.
for c = p.ChannelIndex
    for t = p.frameIndex
        % QZ input for process 5:
        % load surface, QZ output from step 3 Mesh3DProcess
        surfaceStruct = load(fullfile(mesh3DProc.outFilePaths_{1,c}, ['surface_' num2str(c) '_' num2str(t) '.mat']));
        surface = surfaceStruct.surface;
        
        % load intensity, QZ output from step 4 Intensity3DProcess
        intensityStruct = load(fullfile(intensity3DProc.outFilePaths_{1,c}, ['intensity_' num2str(c) '_' num2str(t) '.mat']));
        vertexIntensities = intensityStruct.vertexIntensities;
        
        %%% Process 5: calculate LB
        fprintf('Process 5: calculating Laplace-Beltrami ... \n')
        %set parameters
        % check nonmanifold vertices to set the LB.method automatically
        V = is_vertex_nonmanifold(surface.faces);
        if ~isempty(find(V))
            warning('The tuftedMesh method should be used for calculating LB when mesh vertices are not manifold')
        end
        
        % determine a proper method for calculating LB if the LBMode is not
        % chosen
        if ~strcmp(p.LBMode,'cotan')
            if ~isempty(find(V))
                p.LBMode = 'tuftedMesh';
            else
                p.LBMode = 'cotan';
            end
        end
        
        %calculate the LB for a mesh
        [LB] = calculateLBOperator(surface,p.nEigenvec,p.LBMode);
        eigenvalue = LB.evals;
        eigenvector = LB.evecs;
        areaMatrix = LB.areaMatrix;
        dataName = ['laplacian_' num2str(c) '_' num2str(t) '.mat']; % QZ output 1
        parsave(fullfile(outFilePaths{1,c}, dataName), eigenvalue,eigenvector,areaMatrix); % (not a built-in function, parsave Meghan's fcn)
        %calculate the eigenprojection if it is needed
        if p.calEigenProj
            eigenprojection = calLBEigenprojection(eigenvector,areaMatrix,vertexIntensities.mean);
        end
        dataName = ['eigenprojection_' num2str(c) '_' num2str(t) '.mat']; % QZ output 2
        parsave(fullfile(outFilePaths{1,c}, dataName), eigenprojection); % (not a built-in function, parsave Meghan's fcn)
        
        % recosntructing signal
        if p.reconstIntensity
            [reconstructedIntensity, MSE_LBIntensity]=createLBIntensity(eigenvector,eigenprojection,vertexIntensities.mean);
            dataName = ['reconstructedIntensity' num2str(c) '_' num2str(t) '.mat']; % QZ output 3
            parsave(fullfile(outFilePaths{1,c}, dataName), reconstructedIntensity, MSE_LBIntensity); %
        end
        
        % filtering signal
        if p.useLBFilter
            %check if the maximum frequency index for filtering is smaller
            %than the number of eignenvector 
            if p.maxLBfrequencyIndex > p.nEigenvec 
                p.maxLBfrequencyIndex = p.nEigenvec;
            end 
                % filter out the intensity signal
                [filteredIntensity, MSE_LBIntensity]=createLBIntensity(eigenvector,eigenprojection,vertexIntensities.mean,p.maxLBfrequencyIndex);
            dataName = ['filteredIntensity' num2str(c) '_' num2str(t) '.mat']; % QZ output 4
            parsave(fullfile(outFilePaths{1,c}, dataName), filteredIntensity, MSE_LBIntensity); %
        end
        
    end
end

%%%% end of algorithm

disp('Finished Calculating Laplace-Beltrami!')

end