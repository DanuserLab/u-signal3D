function [D,S,Q] = perform_fast_marching_mesh(vertex, faces, start_points, options)

% perform_fast_marching_mesh - launch the Fast Marching algorithm on a 3D mesh.
%
%   [D,S,Q] = perform_fast_marching_mesh(vertex, faces, start_points, options)
%
%   vertex, faces: a 3D mesh
%   start_points(i) is the index of the ith starting point .
%
%   D is the distance function to the set of starting points.
%   S is the final state of the points : -1 for dead (ie the distance
%       has been computed), 0 for open (ie the distance is only a temporary
%       value), 1 for far (ie point not already computed). Distance function
%       for far points is Inf.
%   Q is the index of the closest point. Q is set to 0 for far points.
%       Q provide a Voronoi decomposition of the domain. 
%
%   Optional:
%   - You can provide non-uniform speed in options.W.
%   - You can provide special conditions for stop in options :
%       'options.end_points' : stop when these points are reached
%       'options.nb_iter_max' : stop when a given number of iterations is
%          reached.
%   - You can provide an heuristic in options.heuristic (typically that try to guess the distance
%       that remains from a given node to a given target).
%       This is an array of same size as W.
%   - You can provide a map L=options.constraint_map that reduce the set of
%       explored points. Only points with current distance smaller than L
%       will be expanded. Set some entries of L to -Inf to avoid any
%       exploration of these points.
%
%   Copyright (c) 2004-2006 Gabriel Peyr?
%
% Copyright (C) 2026, Danuser Lab - UTSouthwestern 
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


options.null = 0;
nverts = max(size(vertex));

end_points  = getoptions_tbx_fast_marching(options, 'end_points', []);
verbose     = getoptions_tbx_fast_marching(options, 'verbose', 1);
nb_iter_max = getoptions_tbx_fast_marching(options, 'nb_iter_max', Inf);
W       = getoptions_tbx_fast_marching(options, 'W', ones(nverts,1) );
L       = getoptions_tbx_fast_marching(options, 'constraint_map', []);
H       = getoptions_tbx_fast_marching(options, 'heuristic', []);
values  = getoptions_tbx_fast_marching(options, 'values', []);
dmax    = getoptions_tbx_fast_marching(options, 'dmax', 1e9);

I = find(L==-Inf); L(I)=-1e9;
I = find(L==Inf); L(I)=1e9;

nb_iter_max = min(nb_iter_max, 1.2*max(size(W)));

if size(vertex,1)>size(vertex,2)
    vertex = vertex';
end
if size(faces,1)>size(faces,2)
    faces = faces';
end
start_points = start_points(:);
end_points = end_points(:);

% use fast C-coded version if possible
if exist('perform_front_propagation_2d')~=0
    [D,S,Q] = perform_front_propagation_mesh(vertex, faces-1, W,start_points-1,end_points-1, nb_iter_max, H, L, values, dmax);
    Q = Q+1;
else
    error('You have to run compiler_mex before.');
end

% replace C 'Inf' value (1e9) by Matlab Inf value.
I = find( D>1e8 );
D(I) = Inf;
