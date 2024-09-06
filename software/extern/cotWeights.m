% Compute the cotangent weight Laplacian.
% W is the symmetric cot Laplacian
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
function [W A] = cotWeights(X, T)
nv = size(X,1);

% Find orig edge lengths and angles
L1 = normv(X(T(:,2),:)-X(T(:,3),:));
L2 = normv(X(T(:,1),:)-X(T(:,3),:));
L3 = normv(X(T(:,1),:)-X(T(:,2),:));
EL = [L1,L2,L3];
A1 = (L2.^2 + L3.^2 - L1.^2) ./ (2.*L2.*L3);
A2 = (L1.^2 + L3.^2 - L2.^2) ./ (2.*L1.*L3);
A3 = (L1.^2 + L2.^2 - L3.^2) ./ (2.*L1.*L2);
A = [A1,A2,A3];
A = acos(A);

% The Cot Laplacian 
I = [T(:,1);T(:,2);T(:,3)];
J = [T(:,2);T(:,3);T(:,1)];
S = 0.5*cot([A(:,3);A(:,1);A(:,2)]);
In = [I;J;I;J];
Jn = [J;I;I;J];
Sn = [-S;-S;S;S];
W = sparse(In,Jn,Sn,nv,nv);
