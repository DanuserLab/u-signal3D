function runUSignal3DmeshSurface()
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

%imageDirectory is for raw data
imageDirectory='/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/testData';
saveDirectory='/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/analysisPly';

imageList=[1];
%mesh name, mesh saved in another package as ply or obj and here is the
%input
meshFilename = 'surfacemesh.ply';
% meshFilename = 'surfacemesh.obj'; %
% set the parameters
pixelSizeXY=160.0990; %PI3K data
pixelSizeZ=160;
timeInterval=1;

%% run for each cell
for iCell=1:length(imageList)
    disp(['--------- Analysing Cell ' num2str(imageList(iCell))])
    imageName='1_CH00_000000.tif';
    imagePathCell = fullfile(imageDirectory,['Cell' num2str(imageList(iCell))]);
    savePathCell = fullfile(saveDirectory, ['Cell' num2str(imageList(iCell))]);
    
    %% phase1 >> create the mesh (from u-shape3D) first 4 processes
    % define the MD
    %case 1 - when I have two channels
    BFDataPath = [imageDirectory filesep 'Cell' num2str(imageList(iCell)) filesep imageName];
    ResultPath = [saveDirectory filesep 'Cell' num2str(imageList(iCell))];
    if ~isdir(ResultPath) mkdir(ResultPath); end
    MD = MovieData(BFDataPath, ResultPath);
    % case2 - for oneChannel folder
    % MD = makeMovieDataOneChannel(imagePathCell, savePathCell, pixelSizeXY, pixelSizeZ, timeInterval);
    
    % add a package
    MD.addPackage(uSignal3DPackage(MD)); % only for Initail script
    
    %skip the first two processes because mesh has been created before
    %% Process 1: Deconvolution3DProcess
    % % disp('===================================================================');
    % % disp('Running (1st) Deconvolution');
    % % disp('===================================================================');
    % % iPack = 1;
    % % step_ = 1;
    % % MD.getPackage(iPack).createDefaultProcess(step_)
    % % params = MD.getPackage(iPack).getProcess(step_).funParams_;
    % % params.deconMode = 'richLucy'; % Edit process parameter, tightness, from 0.5 to 0.6
    % % params.richLucyIter = 8;
    % % params.apoHeight=0;
    % % params.pathApoPSF = pathPSF;
    % % params.pathDeconPSF = pathPSF;
    % % params.ChannelIndex = 1; %analyze only channel1
    % % MD.getPackage(iPack).getProcess(step_).setPara(params);
    % % MD.save;
    % % params = MD.getPackage(iPack).getProcess(step_).funParams_
    % % MD.getPackage(iPack).getProcess(step_).run();
    % %
    % %
    % % %% Process 2: ComputeMIPProcess
    % % disp('===================================================================');
    % % disp('Running (2nd) Maximum Intensity Projection (MIP)');
    % % disp('===================================================================');
    % % iPack = 1;
    % % step_ = 2;
    % % MD.getPackage(iPack).createDefaultProcess(step_)
    % % params = MD.getPackage(iPack).getProcess(step_).funParams_;
    % % params.ChannelIndex = 1; %analyze only channel1
    % % MD.getPackage(iPack).getProcess(step_).setPara(params);
    % % MD.save;
    % % params = MD.getPackage(iPack).getProcess(step_).funParams_
    % % MD.getPackage(iPack).getProcess(step_).run();
    % %
    % %
    
    %% Process 3: Mesh3DProcess
    % we still need to run the mesh process to save the mesh as in input for
    % the next processes
    disp('===================================================================');
    disp('Running (3rd) Creating Mesh Surface');
    disp('===================================================================');
    iPack = 1;
    step_ = 3;
    MD.getPackage(iPack).createDefaultProcess(step_)
    params = MD.getPackage(iPack).getProcess(step_).funParams_;
    % params.smoothMeshMode = 'curvature';
    % params.scaleOtsu = 1;
    % params.imageGamma = 0.7;
    % params.smoothImageSize = 1.5;
    % params.insideErodeRadius = 7;
    params.meshMode ='readPlyFile';
    params.plyFilePath =[imageDirectory filesep 'Cell' num2str(imageList(iCell)) filesep meshFilename];
    params.useUndeconvolved = 1; % for not searching
    params.removeSmallComponents = 1;
    params.ChannelIndex = 1; %analyze only channel1
    MD.getPackage(iPack).getProcess(step_).setPara(params);
    MD.save;
    params = MD.getPackage(iPack).getProcess(step_).funParams_
    MD.getPackage(iPack).getProcess(step_).run();
    
    %% Process 4: Intensity3DProcess
    disp('===================================================================');
    disp('Running (4th) Measuring Intensity on Vertices');
    disp('===================================================================');
    iPack = 1;
    step_ = 4;
    MD.getPackage(iPack).createDefaultProcess(step_)
    params = MD.getPackage(iPack).getProcess(step_).funParams_;
    params.sampleRadius = [1 1];
    params.rmInsideBackground = [0 ];
    params.meanNormalization = [1 ]; %it doesn't exclude the second channel for line 273
    params.intensityMode = {'intensityInsideRawVertex','intensityInsideRawVertex'};
    params.ChannelIndex = 1; %analyze only channel1
    MD.getPackage(iPack).getProcess(step_).setPara(params); 
    MD.save;
    params = MD.getPackage(iPack).getProcess(step_).funParams_
    MD.getPackage(iPack).getProcess(step_).run();
    
    
    %% Process 5: LaplaceBeltrami3DProcess
    disp('===================================================================');
    disp('Running (5th) Computing Laplace-Beltrami Operator on Vertices');
    disp('===================================================================');
    iPack = 1;
    step_ = 5;
    MD.getPackage(iPack).createDefaultProcess(step_)
    params = MD.getPackage(iPack).getProcess(step_).funParams_;
    params.ChannelIndex = 1; %analyze only channel1
    params.nEigenvec = 100;
    MD.getPackage(iPack).getProcess(step_).setPara(params);
    MD.save;
    params = MD.getPackage(iPack).getProcess(step_).funParams_
    MD.getPackage(iPack).getProcess(step_).run();
    
    
    %% Step 6: EnergySpectra3DProcess
    disp('===================================================================');
    disp('Running (6th) Calculating energy spectra');
    disp('===================================================================');
    iPack = 1;
    step_ = 6;
    MD.getPackage(iPack).createDefaultProcess(step_)
    params = MD.getPackage(iPack).getProcess(step_).funParams_;
    params.ChannelIndex = 1; %analyze only channel1
    MD.getPackage(iPack).getProcess(step_).setPara(params);
    MD.save;
    params = MD.getPackage(iPack).getProcess(step_).funParams_
    MD.getPackage(iPack).getProcess(step_).run();
end
