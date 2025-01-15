function [DirichletEnergy]=calDirichletEnergySpectrum(...
    eigenprojection,eigenvalue)
% calDirichletEnergySpectrum - measures the energy spectrum for all
% Laplace-Beltrami operator's eigenvectors
%
%INPUT
% eigenprojection     LB eigenprojection for a given signal on 3Dsurface
% eigenvalue          LB eigenvalue for a given 3Dsurface
% 
%OUPUT
% DirichletEnergy     energy of the signal on the 3D surface, formula is
%                     eigenvalue * abs(eigenprojection^2)
% DirichletEnergyDensity   normalized to 1 of the dirichlet enery spectra
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

% created by Hanieh Mazloom-Farsibaf - Danuser lab 2021
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 

%calculate per eigenvalue
for nn=1:(size(eigenvalue,1))             
    DirichletEnergy(nn)= sum((conj(eigenprojection(nn)).*eigenprojection(nn)).*eigenvalue(nn));
end
