function xForm = getTransformFromBeadImages(baseImage,inputImage,xFormType,beadRad,showFigs)
%TRANSFORMFROMBEADIMAGES calculates an alignment transform based on two bead images
% 
% xForm = transformFromBeadImages(baseImage,inputImage)
% xForm = transformFromBeadImages(baseImage,inputImage,xFormType,beadRad,showFigs)
% 
% This function is used to calculate a transform which can be used to align
% images from two different cameras/channels on the same microscope. It
% takes as input images of fluorescent beads taken from the two different
% channels and returns a transform which can be used with imtransform.m to
% align the two channels. This is accomplished by detecting bead locations
% in each image and then using cp2tform.m The resulting transforms can
% usually use some refinement. See calculateMovieTransform.m for a more
% comprehensive alignment-transform creation.
% 
% ***NOTE*** This function expects that the beads will be sparse within the
% image. That is, the vast majority of the image will be background, and
% the maximum misalignment between the two images is much less than the
% average spacing between beads.
%
% Input:
% 
%   baseImage - The 2D image which is used as a reference for transformation.
%   That is, the transformation will be used to align images to this image.
% 
%   inputImage - The 2D image which will be aligned to the baseImage by the
%   transformation. When the resulting transform is applied to this image,
%   it should align with the baseImage.
% 
% Optional Input:
%
%   xFormType - Character array. Optional. Specifies the type of transform
%   to use to align the two images. Default is 'projective', but any type
%   supported by imtransform.m can be used.
%
%   beadRad - Scalar. The approximate radius of the beads in each image,
%   in pixels. Optional, default is 3 pixels.
%
%   showFigs - True/False. If true, figures showing the bead detection and
%   alignment willb e displayed. Optional. Default is false.
%
% Output:
%
%   xForm - The structure describing the transform, as used by
%   imtransform.m
%
% Hunter Elliott 
% 10/2010
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

%% ------------ Input ----------- %%

if nargin < 2 || isempty(baseImage) || isempty(inputImage)
    error('You must input a base and input image!')
end

[M,N] = size(baseImage);
if size(inputImage,1) ~= M || size(inputImage,2) ~= N
    error('The base and input images must be the same size!');
end

if nargin <3 || isempty(xFormType)
    xFormType = 'projective';
end

if nargin < 4 || isempty(beadRad)
    beadRad = 3;
end

if nargin < 4 || isempty(showFigs)
    showFigs = true;
end

%% ---------- Init -------------- %%

%Determine filter size for local maxima detection
fSize = round(beadRad*2+1);


%Determine initial rmsd
rmsdInit = sqrt(mean((double(baseImage(:)) - double(inputImage(:))).^2));
disp(['Initial RMSD between images: ' num2str(rmsdInit)]);

%% ---------- Detection --------- %%

disp('Detecting beads in both images...')

%Detect local maxima in both images
bMax = locmax2d(baseImage,[fSize fSize]);
iMax = locmax2d(inputImage,[fSize fSize]);

%Keep only the "bright" local maxima. The image should be mostly
%background, so we just use the average of the whole image to get
%approximate background intensity and standard deviation.
bMax = bMax > (mean(baseImage(:))+2*std(double(baseImage(:))));
iMax = iMax > (mean(inputImage(:))+2*std(double(inputImage(:))));





%% ------------ Assignment --------- %%
%Finds correspondence between detcted beads in each image

disp('Determining bead correspondence between images...')

[xB,yB] = find(bMax);
[xI,yI] = find(iMax);

%Number of spots detected in base image
nDetBase = numel(xB);

minD = zeros(nDetBase,1);
xIc = zeros(nDetBase,1);%Corresponding points in input image
yIc = zeros(nDetBase,1);

for j = 1:nDetBase

    %Calculate distance from this point to all those in input image
    currDists = sqrt((xB(j)-xI) .^2 + (yB(j)-yI) .^2);
    
    %And to every point in the base image
    currSameDist = sqrt((xB(j)-xB) .^2 + (yB(j)-yB) .^2);
    
    %find the closest point in the input image and it's distance
    [minD(j),iClosest] = min(currDists);
    
    %Make sure there isn't a point in the base image which is closer
    minDb = min(currSameDist(currSameDist>0));    
    if minD(j) < minDb
        %Assign this point as corresponding
        xIc(j) = xI(iClosest);
        yIc(j) = yI(iClosest);
        
        %Prevent duplicate assignment by removing it.
        xI(iClosest) = [];
        yI(iClosest) = [];                
        
    end
    
            
        
end


%Remove outliers at 95%, as these are probably bad assignments
iOutlier = detectOutliers(minD,2);

xB(iOutlier) = [];
yB(iOutlier) = [];
xIc(iOutlier) = [];
yIc(iOutlier) = [];


%Now do sub-resulution detection for the selected points in each image
disp('Performing sub-resolution position refinement...');

%Get window size for gaussian fitting.
winSize = ceil(beadRad)+2;
%Make sure none of the points are too close to the image border
isOK = (xIc - winSize) > 0 & (yIc - winSize) > 0 & ...
       (xIc + winSize) <= M & (yIc + winSize) <= M & ...
       (xB - winSize) > 0 & (yB - winSize) > 0 & ...
       (xB + winSize) <= M & (yB + winSize) <= M;
xIc = xIc(isOK);
yIc = yIc(isOK);
xB = xB(isOK);
yB = yB(isOK);

nBeads = numel(xB);
       

for j = 1:nBeads
        
    %Get the sub-region of the image for readability/debugging    
    imROI = double(inputImage(xIc(j)-winSize:xIc(j)+winSize,...
                              yIc(j)-winSize:yIc(j)+winSize));
    
    %Fit a gaussian to get the sub-pixel location of each bead.
    pVec = fitGaussian2D(imROI,...
                    [0 0 double(inputImage(xIc(j),yIc(j))) ...
                    beadRad/2 mean(double(inputImage(:)))],'xyAsc');
        
    %Make sure the fit converged, and then add it to the integer position
    if all(abs(pVec(1:2))) < winSize;                  
        xIc(j) = xIc(j) + pVec(2);
        yIc(j) = yIc(j) + pVec(1);
    else
        disp('unconverged!')
    end
        
    
    %Get the sub-region of the image for readability/debugging  
    imROI = double(baseImage(xB(j)-winSize:xB(j)+winSize,...
                              yB(j)-winSize:yB(j)+winSize));

    %Fit a gaussian to get the sub-pixel location of each bead.                      
    pVec = fitGaussian2D(imROI,...
                [0 0 double(baseImage(xB(j),yB(j))) ...
                 beadRad/2 mean(double(baseImage(:)))],'xyAsc');
        
    %Make sure it converged to somewhere within the window
    if all(abs(pVec(1:2)) < winSize);                             
        xB(j) = xB(j) + pVec(2);
        yB(j) = yB(j) + pVec(1);
    else
        disp('unconverged!')
    end
     
end

%% ----------- Get Transform ---------- %%

disp('Determining transformation...')

%Use matlab built in function to determine transform
xForm = cp2tform([yIc xIc],[yB xB],xFormType);


if showFigs
       
    figure
    imshow(cat(3,mat2gray(baseImage),mat2gray(inputImage),zeros(size(baseImage))),[]);
    hold on

    plot(yB,xB,'ro')
    plot(yIc,xIc,'go')
    for j = 1:nBeads                      
        plot([yIc(j) yB(j)],[xIc(j) xB(j)],'--b')                        
    end
    
    legend('Base Image','Input Image','Correspondence');    
    
    figure
    xIn = imtransform(inputImage,xForm,'XData',[1 size(baseImage,2)],'YData',[1 size(baseImage,1)]);
    
    image(cat(3,mat2gray(baseImage),mat2gray(xIn),zeros(size(baseImage))));
    axis off, axis image
    title('Aligned Image Overlay')
    
    rmsdFinal = sqrt(mean((double(baseImage(:)) - double(xIn(:))).^2));
    disp(['Final RMSD between aligned images: ' num2str(rmsdFinal)]);
    disp(['RMSD Change : ' num2str(rmsdFinal - rmsdInit)])
    
    
end
    
    


