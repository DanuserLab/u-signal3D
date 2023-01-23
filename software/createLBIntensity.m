function [reconstructedIntensity MSE_LBIntensity]=createLBIntensity(eigenvector,eigenprojection,originalIntensity,maxEvecIdx)
% createLBIntensity - create signal(intensity) from the Laplacian-Beltrami 
% operator's eigenvectors  
%
%INPUT 
% eigenvector        LB eigenvectors
% eigenprojection    LB eigenprojection for a given signal   
% maxEvecIdx         maximum frequency index of LB eigenvector for recreating
%                    the signal
%  
%OUTPUT
% reconstructedIntensity   reconstructed signal 
% MSE_LBIntensity          mean square error between original signal and
%                          reconstruced signal
%required 
% laplacian code: /extern/
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

% cretaed by Hanieh Mazloom-Farsibaf - Danuser lab 2021

if ~exist('maxEvecIdx','var')
    maxEvecIdx = size(eigenvector,2);
end 

reconstructedIntensity=zeros(size(eigenvector,1),1);
for ii=1:maxEvecIdx
    reconstructedIntensity=eigenprojection(ii).*eigenvector(:,ii)+reconstructedIntensity;
    MSE_LBIntensity(ii,1)=sum(abs(reconstructedIntensity-originalIntensity))/sum(originalIntensity);
end 