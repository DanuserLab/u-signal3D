function runPolkaDotOnMesh()
% runPolkaDotOnMesh - generates polka dot pattern on MV3 cells
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern
%
% This file is part of u-Signal3D package.
%
% Before running, please set the directories in the section below and put the analysis code on Matlab's path.
meshDirectory = '/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/testData';
saveDirectory = '/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/analysis';
meshfileName = 'surface_1_1.mat'; % filename of the mesh surface (contains faces & vertices)
imageList = [1 2 3];

%set the parameters for generating polkadot pattern
params.nDots = [256]; % number of dots
params.dottedArea= [ 0.3]; %fraction of dotted area from the entire cell surface
params.edgeMode = 'step'; % set to 'step for binary polka dots and 'smooth' for blurry ones
params.distMode= 'euclidean'; % distance method between dot centers.

for iCell = 1: length(imageList)
    disp(['---------Generating polka dot on Cell ' num2str(imageList(iCell))])
    % load the mesh surface
    cellmeshPath = [meshDirectory filesep 'Cell' num2str(imageList(iCell))];
    surface=load(fullfile(cellmeshPath,meshfileName)) % for parfor is necessary
    surface=surface.surface;
    
    %generating the polkadot on surface
    [ vertexIntensities.mean] = polkaDotMesh(surface, params.nDots, params.dottedArea, params.edgeMode, 0.1,params.distMode);
    cellsavePath =[saveDirectory filesep 'Cell' num2str(imageList(iCell))];
    
    %save the polkadot pattern
    if ~isdir(cellsavePath) mkdir(cellsavePath); end
    savename='polkadot.mat';
    parsave(fullfile(cellsavePath,savename),vertexIntensities);
    
    %visualize polkadot on mesh
    figure;
    plotMeshvertexIntensity(surface,vertextIntensities.mean)
    savename = 'polkadot.fig'
    saveas(gcf,fullfile(saveDirectory,savename));
    close(gcf)
end
