function [image3D, image3DnotApodized] = weinerDeconvolve(image3D, OTF, weiner, apodizeFilter, saveNotApodized)

% weinerDeconvolve - weiner deconvolves and apodizes a 3D image 
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

% INPUTS:
%
% image3D - the image that will be deconvolved
%
% OTF - an optical transfer function that is the same size as the image
%
% weiner - the Weiner parameter, which is the inverse of the SNR
%
% apodizeFilter - an apodization filter in Fourier space to remove
%                 artifacts generated by the deconvolution


% Fourier transform the image
image3D = fftshift(fftn(image3D));

% perform the Weiner deconvolution
image3D = image3D.*OTF./((OTF.*OTF) + weiner); clear OTF

if saveNotApodized
    image3DnotApodized = ifftn(ifftshift(image3D));
    image3DnotApodized = abs(image3DnotApodized);
    image3DnotApodized = image3DnotApodized.*(image3DnotApodized > 0);
else
    image3DnotApodized = [];
end

% perform apodization
image3D = image3D.*apodizeFilter; clear apodizeFilter

% inverse Fourier transform back to the image domain
image3D = ifftn(ifftshift(image3D));

% take the absolute value of the image
image3D = abs(image3D);

% remove image values less than 0
image3D = image3D.*(image3D > 0);
