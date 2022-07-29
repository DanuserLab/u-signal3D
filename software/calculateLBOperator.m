function [LB]=calculateLBOperator(surface,nEigenvec,LBMode)
% calculateLBOperator - calculates the Laplacian-Beltrami operator on a 
% triangle mesh 
%
%INPUT 
% surface   structure with two fields: faces and verices for a triangle
%               mesh
% nEigenvec number of evecs for calculating LB operator (Default = 100)
% LBMode    LB methods {'coton', 'tufted'} (Default = 'coton')     
%
%OUTPUT
% LB        structure with these fields: {evals, evecs, areaMatrix}
%required 
% laplacian cotan code:
% laplacian tufted code:https://github.com/nmwsharp/nonmanifold-laplacian
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
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

%set default for parameters
if ~exist('nEigenvec','var')
    nEigenvec=100;
end 
if ~exist('LBMode','var')
    LBMode='coton';
end 

%calculate the LB on mesh
switch LBMode
    case 'cotan'
C1 = [surface.vertices(:,1) surface.vertices(:,2) surface.vertices(:,3)];
A = vertexAreas(C1, surface.faces); % compute the diagonal (lumped) area matrix
W = cotWeights(C1, surface.faces); % compute the contangent Laplacian matrix
A = A / sum(sum(A)); % Normalize the area (for scale invariance)
[e, v] = eigs(W, A, nEigenvec, -1e-6); % compute eigenfunctions by solving generalized eigenvalue problem W phi = lamba A phi

[LB.evals, order] = sort(diag(v),'ascend'); % sort the eigenvalues (and thus, the eigenvectors)
LB.evecs = e(:,order);

LB.areaMatrix=A;
  case 'tuftedMesh' % for non-vertex manifold 
        [laplace, mass] = tuftedWrapper(surface);
[eigenvector eigenvalue]=eigs(laplace,nEigenvec,-1e-6);
LB.evals=diag(eigenvalue); 
LB.evecs=eigenvector;
LB.areaMatrix=mass; 
    otherwise 
        
end 

if(LB.evals(1) < 0 && abs(LB.evals(1)<1e-7)) % avoid "negative zero" in Matlab
    LB.evals(1) = 0;
end
