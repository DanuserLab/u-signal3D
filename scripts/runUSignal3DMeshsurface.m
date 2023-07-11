function runUSignal3DMeshsurface()

%imageDirectory is for raw data
meshDirectory ='/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/raw';
intensityDirectory ='/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/raw';
saveDirectory='/project/bioinformatics/Danuser_lab/3Dmorphogenesis/analysis/Hanieh/SpectralDecomposition/Examples/Example2/analysis';

imageList=[1];

%% run for each cell
for iCell=1:length(imageList)
    disp(['--------- Analysing Cell ' num2str(imageList(iCell))])
    imageName='1_CH00_000000.tif'; %filename of channel 1
    imagePathCell = fullfile(imageDirectory,['Cell' num2str(imageList(iCell))]);
    savePathCell = fullfile(saveDirectory, ['Cell' num2str(imageList(iCell))]);
    
    %% phase1 >> create the mesh (from u-shape3D) first 4 processes
    % define the MD
    %case 1 - for two channels
    BFDataPath = [imageDirectory filesep 'Cell' num2str(imageList(iCell)) filesep imageName];
    ResultPath = [saveDirectory  filesep 'Cell' num2str(imageList(iCell))];
    if ~isdir(ResultPath) mkdir(ResultPath); end 
    MD = MovieData(BFDataPath, ResultPath);
    
    % add the uSignal3D package
    MD.addPackage(uSignal3DPackage(MD)); 
    
%% Process 1: Deconvolution3DProcess
disp('===================================================================');
disp('Running (1st) Deconvolution');
disp('===================================================================');
iPack = 1; % package one for MD
step_ = 1; % process one of package one
MD.getPackage(iPack).createDefaultProcess(step_)
%assign the params from default value of the package
params = MD.getPackage(iPack).getProcess(step_).funParams_;
%set the parameters
params.deconMode = 'richLucy'; 
params.richLucyIter = 8;
params.apoHeight=0;
params.pathApoPSF = pathPSF;
params.pathDeconPSF = pathPSF;
params.ChannelIndex = 1; %analyze only channel1
%set the params for the package/process(step_)
MD.getPackage(iPack).getProcess(step_).setPara(params);
MD.save;
% params = MD.getPackage(iPack).getProcess(step_).funParams_
MD.getPackage(iPack).getProcess(step_).run(); % run the process


%% Process 2: ComputeMIPProcess
disp('===================================================================');
disp('Running (2nd) Maximum Intensity Projection (MIP)');
disp('===================================================================');
iPack = 1;
step_ = 2;
MD.getPackage(iPack).createDefaultProcess(step_)
params = MD.getPackage(iPack).getProcess(step_).funParams_;
params.ChannelIndex = 1; %analyze only channel1
MD.getPackage(iPack).getProcess(step_).setPara(params);
MD.save;
% params = MD.getPackage(iPack).getProcess(step_).funParams_
MD.getPackage(iPack).getProcess(step_).run();


%% Process 3: Mesh3DProcess
disp('===================================================================');
disp('Running (3rd) Creating Mesh Surface');
disp('===================================================================');
iPack = 1;
step_ = 3;
MD.getPackage(iPack).createDefaultProcess(step_)
params = MD.getPackage(iPack).getProcess(step_).funParams_;
params.smoothMeshMode = 'curvature';
params.scaleOtsu = 1;
params.imageGamma = 0.7;
params.smoothImageSize = 1.5;
params.insideErodeRadius = 7;
params.meshMode ='twoLevelSurface';
params.removeSmallComponents = 1;
params.ChannelIndex = 1; %analyze only channel1
MD.getPackage(iPack).getProcess(step_).setPara(params);
MD.save;
% params = MD.getPackage(iPack).getProcess(step_).funParams_
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
% params = MD.getPackage(iPack).getProcess(step_).funParams_
MD.getPackage(iPack).getProcess(step_).run();


%% Process 5: LaplaceBeltrami3DProcess
disp('===================================================================');
disp('Running (5th) Computing Laplace-Beltrami Operator on Vertices');
disp('===================================================================');
iPack = 1;
step_ = 5;

MD.getPackage(iPack).createDefaultProcess(step_)
params = MD.getProcess(step_).funParams_;
params.ChannelIndex = 1; %analyze only channel1
MD.getProcess(step_).setPara(params);
MD.save;
% params = MD.getProcess(step_).funParams_
MD.getProcess(step_).run();


%% Step 6: EnergySpectra3DProcess
disp('===================================================================');
disp('Running (6th) Calculating energy spectra');
disp('===================================================================');
iPack = 1;
step_ = 6;

MD.getPackage(iPack).createDefaultProcess(step_)
params = MD.getProcess(step_).funParams_;
params.ChannelIndex = 1; %analyze only channel1
MD.getProcess(step_).setPara(params);
MD.save;
% params = MD.getProcess(step_).funParams_
MD.getProcess(step_).run();
end 