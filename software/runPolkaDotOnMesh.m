function runPolkaDotOnMesh()
% runPolkaDotOnMesh - generates polka dot pattern on MV3 cells
%
% Before running, please set the directories in the section below and put the analysis code on Matlab's path.
%
% Copyright (C) 2026, Danuser Lab - UTSouthwestern 
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
meshDirectory = '/Downloads/uSignal3DExamplesData/Example3/testData';
saveDirectory = '/Downloads/uSignal3DExamplesData/Example3/testData'; 
meshfileName = 'surface_1_1.mat'; % filename of the mesh surface (contains faces & vertices)
imageList = [1];

%set the parameters for generating polkadot pattern
params.nDots = [16]; % number of dots
params.dottedArea= [ 0.3]; %fraction of dotted area from the entire cell surface
params.edgeMode = 'step'; % set to 'step for binary polka dots and 'smooth' for blurry ones
params.distMode= 'euclidean'; % distance method between dot centers.
params.edgeRange = 0.1; % needed for gray pattern (edgeMode = 'smooth')

%iteration for cell list
for iCell = 1: length(imageList)
    disp(['---------Generating polka dot on Cell ' num2str(imageList(iCell))])
    % load the mesh surface
    cellmeshPath = [meshDirectory filesep 'Cell' num2str(imageList(iCell))];
    surface=load(fullfile(cellmeshPath,meshfileName)) % for parfor is necessary
    surface=surface.surface;
    
    %generating the polkadot on surface
    [ vertexIntensities.mean] = polkaDotMesh(surface, params.nDots, params.dottedArea, params.edgeMode, params.edgeRange,params.distMode);
    cellsavePath =[saveDirectory filesep 'Cell' num2str(imageList(iCell))];
    
    %save the polkadot pattern
    if ~isdir(cellsavePath) mkdir(cellsavePath); end
    savename='polkadot.mat';
    parsave(fullfile(cellsavePath,savename),vertexIntensities);
    
    %visualize polkadot on mesh
    figure;
    plotMeshvertexIntensity(surface,vertexIntensities.mean)
    savename = 'polkadot.fig'
    saveas(gcf,fullfile(cellsavePath,savename));
    close(gcf)
end
