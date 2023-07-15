function polkaDotColor = polkaDotMesh(surface, numDots, dottedArea, edgeMode, edgeRange,distMode)
% polkaDotMesh - create a polka dot pattern on a mesh surface
%
%INPUT 
% surface       structure with two fields: faces and verices for a triangle
%               mesh
% numDots       number of dots on the surface 
% dottedArea    total fraction of polkadot area of the entire surface area 
% edgeMode      boudary of dots, set to 'step' for binary polka dots and 
%               'smooth' for blurry ones (Default = 'step')
% edgeRange     scalar value for blurring dot's boundary (Default =0.1)
% distMode      a way to calculate distance between dots, 'euclidean', 
%               'geodesic' (Default ='euclidean')
%OUTPUT
% polkaDotColor a vector of the size of surface.vertices for coloring mesh
%required 
% some functions from toolbox fast marching 
% https://www.mathworks.com/matlabcentral/fileexchange/6110-toolbox-fast-marching
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

% created by Meghan Driscoll - Danuser lab 2021
% revided by Hanieh Mazloom-Farsibaf 2022 (mostly documentation)

% find and label vertices spaced equidistantly in a euclidean fashion
if numDots > 1
    [~,polkaDotSeeds] = farthest_points(surface.vertices,numDots,'F',surface.faces','Distance',distMode);  % 'euclidean', 'geodesic', geodesic too slow to test
    %polkaDotSeeds = fps_euclidean(surface.vertices,numDots); % from ConsistantZoomOut repo, possibly a bit faster
else
    % pick a random vertex
    polkaDotSeeds = randi(length(surface.vertices));
    
end
%polkaDotSeeds = fps_euclidean(surface.vertices,numDots); % from ConsistantZoomOut repo, possibly a bit faster

% calculate the distance on the mesh from the nearest bright face
[distanceMesh,~,~] = perform_fast_marching_mesh(surface.vertices, surface.faces, polkaDotSeeds);
distanceMesh(polkaDotSeeds) = 0;

% normalize/threshold such that the dottedArea of the cell is bright
if strcmp(edgeMode, 'step')
    dotThresh = prctile(distanceMesh,100*dottedArea);
    polkaDotColor = double(distanceMesh < dotThresh);
elseif strcmp(edgeMode, 'smooth') % keep a smooth edge to avoid artifacts
    dotThreshLow = prctile(distanceMesh,100*(dottedArea-edgeRange/2));
    dotThreshHigh = prctile(distanceMesh,100*(dottedArea+edgeRange/2));
    polkaDotColor = distanceMesh - dotThreshLow;
    polkaDotColor = polkaDotColor/(dotThreshHigh-dotThreshLow);
    polkaDotColor(polkaDotColor > 1) = 1;
    polkaDotColor(polkaDotColor < 0) = 0;
    polkaDotColor = 1 - polkaDotColor;
else
    disp('Invalid edgeMode')
end
