function [S,C] = conncomp_gptbx(G)
  % CONNCOMP Drop in replacement for graphconncomp.m from the bioinformatics
  % toobox. G is an n by n adjacency matrix, then this identifies the S
  % connected components C. This is also an order of magnitude faster.
  %
  % [S,C] = conncomp(G)
  %
  % Inputs:
  %   G  n by n adjacency matrix
  % Outputs:
  %   S  scalar number of connected components
  %   C  
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

  % Transpose to match graphconncomp
  %from gptoolbox https://github.com/alecjacobson/gptoolbox
%  renamed by HMF Danuserlab2022
%  renamed from conncomp_gptoolbox to conncomp_gptbx to avoid CI build issue. By Qiongjing (Jenny) Zou, June 2022
  G = G';

  [p,q,r] = dmperm(G+speye(size(G)));
  S = numel(r)-1;
  C = cumsum(full(sparse(1,r(1:end-1),1,1,size(G,1))));
  C(p) = C;
end
