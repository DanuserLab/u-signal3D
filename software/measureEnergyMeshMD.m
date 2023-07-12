function measureEnergyMeshMD(movieDataOrProcess, varargin)
% measureEnergyMeshMD wrapper function for calDirichletEnergySpectrum and calEnergyLevel
% to be executed by MeasureEnergySpectraProcess.
% See also wrapFun_uSignal3D_QZ, wrapFun_uSignal3D
%
% INPUT
% movieDataOrProcess - either a MovieData (legacy)
%                      or a Process (new as of July 2016)
%
% params - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
% p.ChannelIndex       - index of the channel (multichannel image)
% 
% p.OutputDirectory    - directory where the energy will be saved
% 
% p.LB3DProcessIndex  - index of the previous run CalculateLaplaceBeltramiProcess, which is used in this process
% 
% p.frameIndex         - index of the frame (time series image)
% 
% p.useNormalizedEnergy- flag for normalizing the energy to 1 for comparing
%                        multiple cells
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


%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('MD', @(x) isa(x,'MovieData') || isa(x,'Process') && isa(x.getOwner(),'MovieData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get MovieData object and Process
[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess, 'MeasureEnergySpectraProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in MeasureEnergySpectraProcess

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
if isempty(p.LB3DProcessIndex)
    
    p.LB3DProcessIndex = movieData.getProcessIndex('CalculateLaplaceBeltramiProcess'); % if there is more than one CalculateLaplaceBeltramiProcess, popup menu will show up for user to choose
    
    if isempty(p.LB3DProcessIndex)
        error("Intensity3DProcess needs to be done before run Calculate Laplace Beltrami process.")
    end
else
    if ~isa(movieData.processes_{p.LB3DProcessIndex},'CalculateLaplaceBeltramiProcess')
        error("Wrong CalculateLaplaceBeltramiProcess index provided!")
    end
end

calLBProc = movieData.processes_{p.LB3DProcessIndex};

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    inFilePaths{1,i} = calLBProc.outFilePaths_{1,i};
end
thisProc.setInFilePaths(inFilePaths);

% logging output paths.
mkClrDir(p.OutputDirectory);
outFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'ch' num2str(i)];
    mkClrDir(outFilePaths{1,i});
end
thisProc.setOutFilePaths(outFilePaths);


%% Algorithm
% Edited from wrapFun_uSignal3D_QZ.m process 5 line 210 to 241

for c = p.ChannelIndex
    for t = p.frameIndex
        fprintf('Process 6: measuring the energy spectra ... \n');
        
       %calculate the energy density spectrum
        % QZ inputs are eigenprojection, eigenvalue from proc5
        %load eigenProjection
        sEigenProj = load(fullfile(calLBProc.outFilePaths_{1,c}, ['eigenprojection_' num2str(c) '_' num2str(t) '.mat']), 'eigenprojection');
        eigenprojection = sEigenProj.eigenprojection;

        %load Laplace-Beltrami eigenvalues 
        sEigenValue = load(fullfile(calLBProc.outFilePaths_{1,c}, ['laplacian_' num2str(c) '_' num2str(t) '.mat']), 'eigenvalue');
        eigenvalue = sEigenValue.eigenvalue
        
        %calculate the energy spectrum across frequency indices
        [DirichletEnergy] = calDirichletEnergySpectrum(eigenprojection,eigenvalue);
        
        %calculate the mean/Sum/Max of energy spectrum for each frequency
        %level
        [MeanLevelEnergy, SumLevelEnergy, MaxLevelEnergy] = calEnergyLevel(DirichletEnergy);
        
        % normalized the energy spectra of frequency level 
        if p.useNormalizedEnergy
            MeanLevelEnergyNormalized=MeanLevelEnergy/sum(MeanLevelEnergy);
            SumLevelEnergyNormalized=SumLevelEnergy/sum(SumLevelEnergy);
            MaxLevelEnergyNormalized= MaxLevelEnergy/sum(MaxLevelEnergy);
        end
        
        %save energy spectra across frequency indices
        dataName = ['energySpectra_' num2str(c) '_' num2str(t) '.mat']; % QZ output 1
        parsave(fullfile(outFilePaths{1,c}, dataName), DirichletEnergy); % (not a built-in function)
        
        %save energy spectra across frequency levels
        dataName = ['energyLevel_' num2str(c) '_' num2str(t) '.mat']; % QZ output 2
        parsave(fullfile(outFilePaths{1,c}, dataName), MeanLevelEnergy, ...
            SumLevelEnergy,MaxLevelEnergy,MeanLevelEnergyNormalized, ...
            SumLevelEnergyNormalized,MaxLevelEnergyNormalized); % (not a built-in function)
        
        %save the energy level for mean of energy 
        figureHandle{t} = figure;
        saveName = ['energyLevel_' num2str(c) '_' num2str(t) '.fig'];
       
        %define the x axes as the frequency level based on the number of
        %desired levels
        if p.useNormalizedEnergy
            frequencyLevel = [0:length(MeanLevelEnergyNormalized)-1]';
            plot(frequencyLevel,MeanLevelEnergyNormalized,'.-');
            yaxes = 'Mean energy density';
        else
            frequencyLevel = [0:length(MeanLevelEnergy)-1]';
            plot(frequencyLevel,MeanLevelEnergy,'.-');
            yaxes = 'Mean energy';
        end 
        xlabel('Frequency level')
        ylabel(yaxes)
        title ('Energy Spectra')
        saveas(figureHandle{t},fullfile(outFilePaths{t,c},saveName),'tiffn')
    end
    
end

%%%% end of algorithm

disp('Finished Measuring Energy Spectra!')

end