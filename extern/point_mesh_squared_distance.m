% Compute distances from a set of points P to a triangle mesh (V,F)
% 
% [sqrD,I,C] = point_mesh_squared_distance(P,V,F);
%
% Inputs:
%   P  #P by 3 list of query point positions
%   V  #V by 3 list of vertex positions
%   F  #F by (3|2|1) list of triangle|edge|point indices
% Outputs:
%   sqrD  #P list of smallest squared distances
%   I  #P list of facet indices corresponding to smallest distances
%   C  #P by 3 list of closest points
%
% Known bugs: This only computes distances to given primitives. So unreferenced
% vertices are ignored.
%
% Examples:
%   [sqrD,I,C] = point_mesh_squared_distance(P,V,F);
%   B = barycentric_coordinates(C,V(F(I,1),:),V(F(I,2),:),V(F(I,3),:));
%   on_face = sum(B<1e-15)==0;
%   on_edge = sum(B<1e-15)==1;
%   on_vertex = sum(B<1e-15)==2;
%   N_face = normalizerows(normals(F));
%   N_vertex = per_vertex_normals(V,F);
%   per_edge_normals
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
