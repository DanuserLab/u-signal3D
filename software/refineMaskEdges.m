function refinedMask = refineMaskEdges(maskIn,imageIn,maxAdjust,maxGap,preGrow)
%REFINEMASKEDGES uses edge-detection to refine the postion of the input mask edge
%
% refinedMask = refineMaskEdges(mask,image,maxEdgeAdjust,maxEdgeGap,preGrow)
%
% This function uses edge detection to refine the edges of a mask.
% It assumes that the input mask (maskIn) OVERSHOOTS the cell boundary in
% all areas - that is the cell/object in the image is completely contained
% within the mask. If you aren't sure this is the case, input a non-zero
% integer for preGrow, which will grow the mask prior to edge refinement.
% It also assumes that the object contained in the mask is brighter than
% the background.
% 
% Input:
% 
%   maskIn - The mask to refine.
% 
%   imageIn - The image the mask was created for. 
% 
%   maxAdjust - The maximum distance to adjust the edge location by, in
%   pixels. This distance is relative to the original input masks's edge
%   location, ignoring the effects of the pre-growth (see below);
%   Optional. Default is 10.
% 
%   maxEdgeGap - The largest size of gaps in the detected edges to close.
%   THis is the radius of the closure opp performed on the final mask.
%   Optional. Default is 5;
% 
%   preGrow - This is the radius in pixels to grow the mask by prior to
%   edge refinement. This may be needed if the object to be segmented is
%   not completely contained in the input mask.
%   Optional. Default is 3.
% 
% 
% Output:
% 
%   refinedMask - The new mask, with (hopefully..) improved edge location.
%
%Hunter Elliott 3/2009
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


%% -------------- Input ------------ %%


if nargin < 5 || isempty(preGrow)
    preGrow = 3;
elseif abs(round(preGrow)) ~= preGrow
    error('The mask growth radius, preGrow, must be a positive integer!')
end

if nargin < 4 || isempty(maxGap)
    maxGap = 5;
end

if nargin < 3 || isempty(maxAdjust)
    maxAdjust = 10;    
end

if nargin < 2 || isempty(maskIn) || isempty(imageIn)
    error('You must input a mask and an image!')
end

if ~isequal(size(maskIn),size(imageIn));
    error('The input mask and image must be the same size!!!')
end

imageIn = double(imageIn);


%% ------ Parameters ----- %%

tooSmall = 1; %If a detected edge fragment is below this size in pixels it is thrown out.
threshScale = [.75 .5]; %Fraction by which to adjust edge threshold on second round.
nSig = 2; %Number of standard deviations above background intensity to keep edges.(darker edges are removed)
sigFilter = 1.5; %Sigma of filter used in canny edge detection.
showPlots = false; %For debugging/parameter testing. Shows plots of intermediate steps, overlay of final mask.

%% ----- Edge Detection ------ %%

%Run initial edge detection
[edges,autoThresh] = edge(imageIn,'canny',[],sigFilter); %#ok<ASGLU>

%Run a second round with lower thresholds
edges = edge(imageIn,'canny', autoThresh .* threshScale,sigFilter);


if showPlots
   figure
   hold on
   title('Initial Edge Detection')       
   imshow(imageIn,[])   
   hold on      
   spy(edges,'r')
   caxis(caxis/2);    
end


%% ------ Edge Pre-Processing ------ %%

%Get statistics for the background intensity
meanBak = mean(imageIn(~maskIn(:)));
stdBak = std(imageIn(~maskIn(:)));

%Remove edges in very dark areas.
edges(imageIn < (meanBak + nSig*stdBak )) = false;

%Remove small, isolated edge fragments
edges = bwareaopen(edges,tooSmall);

if showPlots
   figure
   hold on
   title('Pre-Processed Edge Detection')       
   imshow(imageIn,[])   
   hold on
   spy(bwperim(maskIn))
   spy(edges,'y')   
   caxis(caxis/2);           
    
end


%% ------- Edge Refinement ------ %%

%Get the distance transform of the mask's inverse before growing.
%This is because the maxAdjust parameter is relative to the original edge
%position.
distX = bwdist(~maskIn);

if preGrow > 0
    seGrow = strel('disk',preGrow);
    maskIn = imdilate(maskIn,seGrow);
end

%Get rid of edges which are outside of the (possibly grown) mask.
edges = edges & maskIn;

%Add an inner border at maxAdjust pixels inwards from the mask
edges = edges | distX >= maxAdjust;

%Close these edges
seClose = strel('disk',maxGap,0); %Don't use approximations for the closure, as this can cause gaps in the resulting edge.
refinedMask = imclose(edges,seClose);

%Fill in 1-pixel gaps from straight segments. At some point, some more
%comprehensive gap-closing should be done, as longer straight segments may
%still have holes.
refinedMask = bwmorph(refinedMask,'bridge');

%Fill the insides
refinedMask = imfill(refinedMask,4,'holes');

if showPlots
   figure
   hold on
   title('Final refined mask')       
   imshow(imageIn,[])   
   hold on   
   spy(refinedMask)
   caxis(caxis/2);           
end 

