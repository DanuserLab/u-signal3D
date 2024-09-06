function [laplace, mass] = tuftedWrapper(surface)
% tuftedWrapper is the wrapper function to run tufted-idt executable in Matlab
% It takes a Matlab variable as an input and outputted the Laplacian and mass matrix as Matlab variables.
% [D_laplace, D_mass] = tuftedWrapper(surface)
% input surface is a mesh.mat loaded in Matlab workspace
% outputs D_laplace is the Laplacian matrix and D_mass is the mass matrix
%
% See also tufted_setup_script
% by Qiongjing (Jenny) Zou, Sep 2021
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

%% check input
if isstruct(surface)
    if ~isfield(surface,'vertices') || ~isfield(surface,'faces')
        error('Missing vertices or faces field in input.')
    end
else
    error('Invalid input.')
end


%% Convert .mat mesh to .obj mesh

mesh_obj_path = [pwd filesep  'surface.obj'];
writeOBJ(mesh_obj_path, surface.vertices, surface.faces)


%% Building tufted Laplacian

[status,cmdout] = system( sprintf('tufted %s --writeLaplacian --writeMass', mesh_obj_path) )
delete(mesh_obj_path);

if ~isequal(status, 0)
    return
end

%% Read outputted the Laplacian and mass matrix as Matlab variables
% outputs .spmat are in matlab current dir then deleted

laplace_path = [pwd filesep 'tufted_laplacian.spmat'];
if exist(laplace_path,'file') == 2
    D_laplace = textread(laplace_path);
laplaceWeak = spconvert(D_laplace);
    delete(laplace_path);
else
    error('Outputted Laplacian matrix is not exist.')
end

mass_path = [pwd filesep 'tufted_lumped_mass.spmat'];
if exist(mass_path,'file') == 2
    D_mass = textread(mass_path);
    mass = spconvert(D_mass);
laplace = inv(mass)*laplaceWeak; 

    delete(mass_path);
else
    error('Outputted mass matrix is not exist.')
end

end