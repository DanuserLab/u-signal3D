function [image3D, level] = prepareCellOtsuSeg(image3D)

% prepareCellOtsuSeg - calculates an Otsu threshold and prepares the image for thresholding
%
% Copyright (C) 2022, Danuser Lab - UTSouthwestern 
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

% normalize the image intensity
image3D = im2double(image3D);
image3D = image3D-min(image3D(:));
image3D = image3D./max(image3D(:));

% calculate the Otsu threshold
level = graythresh(image3D(:));

% fill holes in the grayscale image
image3D(isnan(image3D)) = 0;
image3D = imfill(image3D); 