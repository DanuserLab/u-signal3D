function [MeanLevelEnergy SumLevelEnergy MaxLevelEnergy]=calEnergyLevel(...
    EnergyDirichletSpectrum,MaxLevel)
% calEnergyLevel - calculates the energy spectra per level for a signal on
% 3Dsurface in Laplace-Beltrami space
%
%INPUT
% EnergyDirichletSpectrum   energy specra for each LB eigenvalue 
% MaxLevel                  maximum level of the energy spectra (default =100)
% radius       a radius of a sphere for averaging the intensity around each
%              vertex (in pixels)
%OUPUT
% vertexIntensities     a vertex with mean field to emphasize we used "mean"
%                       of intensity within a sphere with a given radius on
%                       each vertex
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

% created by Hanieh Mazloom-Farsibaf - Danuser lab 2021
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
% EnergyDirichletSpectrum energy spectrum (N x 1)
% MaxLevel                maximum level required to calculate the energy (Default=100)
if ~exist('MaxLevel','var')
    MaxLevel=100; 
end

NN=[1:2:2*MaxLevel+1]'; %number of index per level
LevelEnd=cumsum(NN); %define the 
Ind=find(LevelEnd < length(EnergyDirichletSpectrum));
% calculate the energy level
MeanLevelEnergy(1,:)=EnergyDirichletSpectrum(1);
SumLevelEnergy(1,:)=EnergyDirichletSpectrum(1);
MaxLevelEnergy(1,:)=EnergyDirichletSpectrum(1);

for ll=2:Ind(end)
    EStart=LevelEnd(ll-1)+1;
    EEnd=LevelEnd(ll);
    MeanLevelEnergy(ll,1)= mean(EnergyDirichletSpectrum(EStart:EEnd));
       SumLevelEnergy(ll,1)= sum(EnergyDirichletSpectrum(EStart:EEnd));
       MaxLevelEnergy(ll,1)= max(EnergyDirichletSpectrum(EStart:EEnd));

end
