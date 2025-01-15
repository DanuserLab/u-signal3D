function [reconstructedIntensity MSE_LBIntensity]=createLBIntensity(eigenvector,eigenprojection,originalIntensity,FrequencyRange)
% createLBIntensity - create signal(intensity) from the Laplacian-Beltrami 
% operator's eigenvectors. It calculates the data defined for given
% frequency levels or as defualt for the whole frequency levels.
%
%INPUT 
% eigenvector        LB eigenvectors
% eigenprojection    LB eigenprojection for a given signal  
% originalIntensity  original data defined at mesh vertices (for error)
% FrequencyRange     [min max] frequency index of LB eigenvector for recreating
%                    the signal, (Default = [1 number of mesh vertex])
%  
%OUTPUT
% reconstructedIntensity   reconstructed signal 
% MSE_LBIntensity          mean square error between original signal and
%                          reconstruced signal
%required 
% laplacian code: /extern/
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

% cretaed by Hanieh Mazloom-Farsibaf - Danuser lab 2021

if ~exist('maxEvecIdx','var')
    FrequencyRange = [1 size(eigenvector,2)];
end 

% if only maximum is given, assign the minimum level as the first level
if length(FrequencyRange) == 1
    FrequencyRange = [1 FrequencyRange];
end

%initialize the reconstructed data and Mean Square error 
reconstructedIntensity = zeros(size(eigenvector,1),1);
MSE_LBIntensity = nan(FrequencyRange(2)-FrequencyRange(1)+1,1);

% recreate the data between given frequency levels
for iFreq = FrequencyRange(1):FrequencyRange(2)
    reconstructedIntensity = eigenprojection(iFreq).*eigenvector(:,iFreq)+reconstructedIntensity;
    %calculate the error between the original data and reconstructed data 
    if exist('originalIntensity','var')
        MSE_LBIntensity(iFreq,1) = sum(abs(reconstructedIntensity-originalIntensity))/sum(originalIntensity);
    else 
        MSE_LBIntensity = [];
    end  
end 