function plotMeshvertexIntensity(surface, data)
    if (nargin == 1)
        data = surface.vertices(:,1).*surface.vertices(:,2).*surface.vertices(:,3);
    end
    
    trimesh(surface.faces, surface.vertices(:,2), surface.vertices(:,3), ...
        surface.vertices(:,1), data, ...
        'EdgeColor', 'interp', 'FaceColor', 'interp');
    view([-221 24]);
    axis equal;
    axis off;
    
emax = max(data); % compute the minumum and maximum values for a consistent color map
emin = min(data);

caxis manual % use a consistent color map
% caxis([min(0.5,emin) max(1.5,emax)]);
%
% Copyright (C) 2024, Danuser Lab - UTSouthwestern 
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
caxis([emin emax]);

lighting flat;
shading flat;

camlight('headlight'); % create light in 3D scene

cb = colorbar;
set(cb,'position',[.92 .22 .01 .7]);
end