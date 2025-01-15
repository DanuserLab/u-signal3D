function l = edge_lengths(V,F)
  % EDGE_LENGTHS Compute the edge lengths for a simplex mesh
  % 
  % l = edge_lengths(V,F)
  %
  % Inputs:
  %   V   #V by dim list of triangle indices
  %   F  #F by simplex list of simplices
  % Outputs:
  %   l  #F by 1 list of edge lengths
  %     or
  %   l  #F by 3 list of edge lengths corresponding to 23,31,12
  %     or 
  %   l  #F by 6 list of edge lengths corresponding to edges opposite *face*
  %     pairs: 23 31 12 41 42 43
  %
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
  switch size(F,2)
  case 2
    l = normrow(V(F(:,2),:) - V(F(:,1),:));
  case 3
    i1 = F(:,1); i2 = F(:,2); i3 = F(:,3);
    s12 = normrow(V(i2,:) - V(i1,:));
    s13 = normrow(V(i3,:) - V(i1,:));
    s23 = normrow(V(i3,:) - V(i2,:));
    l = [s23 s13 s12];
  case 4
    T = F;
    % lengths of edges opposite *face* pairs: 23 31 12 41 42 43
    l = [ ...
      sqrt(sum((V(T(:,4),:)-V(T(:,1),:)).^2,2)) ...
      sqrt(sum((V(T(:,4),:)-V(T(:,2),:)).^2,2)) ...
      sqrt(sum((V(T(:,4),:)-V(T(:,3),:)).^2,2)) ...
      sqrt(sum((V(T(:,2),:)-V(T(:,3),:)).^2,2)) ...
      sqrt(sum((V(T(:,3),:)-V(T(:,1),:)).^2,2)) ...
      sqrt(sum((V(T(:,1),:)-V(T(:,2),:)).^2,2)) ...
    ];
  otherwise
    error('Unsupported simplex size');
  end
end
