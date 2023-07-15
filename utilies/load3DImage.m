function image3D = load3DImage(inDirectory, name)

% load3DImage - load a 3D image using Matlab's built-in image reader
%
% INPUTS:
%
% inDirectory - the path to the image
%
% name - the name of the image
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

% try to find information about the image
try
    imageInfo = imfinfo(fullfile(inDirectory, name));
catch 
    disp([name ' is not an image and will not be analyzed.'])
    image3D = [];
    return
end

% find the image size
imageSize = [imageInfo(1).Height; imageInfo(1).Width; length(imageInfo)];

% initiate the image variable
image3D = zeros(imageSize(1), imageSize(2), imageSize(3));

% load each plane in Z
parfor z = 1:imageSize(3) 
    image3D(:,:,z) = im2double(imread(fullfile(inDirectory, name), 'Index', z, 'Info', imageInfo));
end
