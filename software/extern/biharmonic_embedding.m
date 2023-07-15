function [B,EV,ED] = biharmonic_embedding(V,F,dim,p);
  % [B,EV,ED] = biharmonic_embedding(V,F);
  %
  % Takes a mesh (V,F) and returns an embedding using the spectrum of the
  % biharmonic operator. Then the biharmonic distance between two points i and
  % j can be computed as the euclidean distance between B(i,:) and B(j,:),
  % namely: 
  %   dist_ij = sqrt(sum((B(i,:)-B(j,:)).^2,2));
  % 
  % Input:
  %   V  vertex list
  %   F  face list
  %   dim requested dimension of the embedding
  %   Optional:
  %     p  exponent above eigen values
  %       0.5  "semi-harmonic" embedding
  %       1  commute time embedding, "harmonic"
  %       2  biharmonic {default}
  %       3  "triharmonic" embedding
  % Output:
  %   B  biharmonic embedding
  %   EV  eigenvectors used in embedding
  %   ED  eigenvalues used in embedding
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

  % if dimension is not specfied use 4
  if(~exist('dim','var'))
    dim = 4;
  end

  if(~exist('p','var'))
    p = 2;
  end

  % get cotangent matrix
  L = cotmatrix(V,F);
  % This should be better, but yaron seemed to use barycentric
  %M = massmatrix(V,F);
  M = massmatrix(V,F,'barycentric');

  % get dim+1 smallest magnitude eigenvalues and corresponding vectors
  [EV,ED] = eigs(L,M,dim+1,'sm');
  EV = EV(:, 2:end);
  ED = ED(2:end, 2:end);

  % This is not exactly the same, essentially it removes the mass matrix and
  % multiplies everything by a factos of -2
  % % This also works, because of the sign change in the eigenvalues matlab
  % % reverses the output order so 0.0 is the last eigenvalue
  % [EV,ED] = eigs(-2*L,M./sum(M(:)),dim+1,'sm');
  % EV = EV(:, 1:end-1);
  % ED = ED(1:end-1, 1:end-1);

  %  divide each eigenvector by corresponding eigenvalue 
  %  divide the power by 2 first because it will appear in the denominator of
  %  distance computation *outside* the squared difference see (4) and (11)
  B = EV * (inv(abs(ED))^(p/2));
end
