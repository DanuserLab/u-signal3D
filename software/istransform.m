function isIt = istransform(xFormIn)
%ISTRANSFORM checks if the input variable is an image toolbox image transform
%
% isIt = istransform(xFormIn)
% 
% 
% Input:
%   
%   xFormIn - The variable to be tested.
% 
% Output:
% 
%  iIt - True if the input xFormIn was an Image Processing Toolbox
%  transform, and false otherwise.
% 
% Hunter Elliott
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

if isfield(xFormIn,'ndims_in') && isfield(xFormIn,'ndims_out') && isfield(xFormIn,'forward_fcn') && isfield(xFormIn,'inverse_fcn')...
        && isfield(xFormIn,'tdata')
    
    isIt = true;
    
else
    isIt = false;
end