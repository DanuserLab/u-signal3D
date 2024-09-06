function C = fastIntersect(A,B)

% fastIntersect - A faster version of Matlab's builtin intersect that only works on positive integers
% (from http://www.mathworks.com/matlabcentral/answers/53796-speed-up-intersect-setdiff-functions)
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

P = zeros(1, max(max(A),max(B)) ) ;
P(A) = 1;
C = B(logical(P(B)));