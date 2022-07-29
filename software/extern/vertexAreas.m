function A = vertexAreas(X, T)

% Triangle areas
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
N = cross(X(T(:,1),:)-X(T(:,2),:), X(T(:,1),:) - X(T(:,3),:));
At = 1/2*normv(N);

% Vertex areas = 1/3*(sum of areas of triangles nearby)
I = [T(:,1);T(:,2);T(:,3)];
J = ones(size(I));
S = 1/3*[At(:,1);At(:,1);At(:,1)];
nv = size(X,1);
% Vector of area weights
A = sparse(I,J,S,nv,1);

% Convert to a sparse diagonal matrix
A = spdiags(A,0,nv,nv);