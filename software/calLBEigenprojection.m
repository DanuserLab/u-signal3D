function eigenprojection=calLBEigenprojection(eigenvector,areaMatrix,intensity)
% calLBEigenprojection - calculates the eigenprojections of a signal on a mesh 
% usingLaplacian-Beltrami operator results 
%
%INPUT 
% eigenvector  LB eigenvector of a mesh surface 
% areaMatrix   matrix of area around each mesh vertex from LB operator  
% intensity    signal defined on mesh vertices
% 
%OUTPUT
% eigenprojection  LB eigenprojection of a signal on surface
%required 
% laplacian code: /extern/
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

% cretaed by Hanieh Mazloom-Farsibaf - Danuser lab 2021

%calculate the projection coefficient
eigenprojection= eigenvector'*areaMatrix*intensity;
