function optimalXform = findOptimalXform(baseImage,inputImage,showFigs,xType,iGuess)
%FINDOPTIMALXFORM finds a transform which maximizes the agreement between the input images
%
% optimalXform = findOptimalXform(baseImage,inputImage,showFigs,xType)
%
% This function finds a transform which maximizes the agreement between the
% input and base images by transforming the input image. This transform can
% then be used to register two channels in a movie. The transform is
% determined by minimization of the RMSD between the base image and the
% transformed input image. Masks may also be used instead of images.
% 
% Input:
% 
%  baseImage - The image the input image will be compared (registered) to.
% 
%  inputImage - The image to transform to match the base image.
%
%  showFigs - True or false. If true, figures showing the alignment before
%  and after the transformation will be shown.
%
%  xType - A character string describing the transformation type to use to
%  align the two images. Default is 'projective'. See cp2tform help for
%  more info on the transformation types.
% 
%       Available Transformation Types:
%
%           'projective' - Projective transformation. Allows rotation,
%           change in perspective, translation, shear. This does everything
%           an affine transform can do and more.
%
%           'polynomial' - Non-linear, 3rd order polynomial transform.
%           Allows everything that projective does, in addition to the
%           possiblility of introducing curvature.
%
%   iGuess - The matrix containing the initial guess for the alignment
%   transform. For the projective transform this is a 3x3 matrix, while for
%   the polynomial transform this is a 10x2 matrix. Optional. IF not input,
%   the identity transform is used as the initial guess.
%
%
% Output:
%
%   optimalXform - The transform which minimizes the RMSD between the input
%   and base image. This is a transform structure, as used by imtransform.m
%
%
% Hunter Elliott, 2008
% Rewritten 11/2010
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

%% ------ Input ----- %%

if nargin < 2 || isempty(baseImage) || isempty(inputImage)
    error('You must input a base and input image!')
end

if ~isequal(size(baseImage),size(inputImage))
    error('The base and input images must be the same size!')
end

if nargin < 3 || isempty(showFigs)
    showFigs = 0;
end

if nargin < 4 || isempty(xType)
    xType = 'projective';
end

if nargin < 5 || isempty(iGuess)
    %If no initial guess given, use identity transform.
    switch xType

        case 'projective'    
            iGuess = eye(3);            
        case 'polynomial'
            
              iGuess = zeros(6,2);
              iGuess(2,1) = 1;
              iGuess(3,2) = 1;

        otherwise
            error(['"' xType '" is not a supported transformation type!'])
            
    end
end

%% -------- Init -------- %%



%If the images are actually masks, scale them differently to avoid rounding
%effects
if islogical(baseImage) && islogical(inputImage)
    baseImage = cast(baseImage,'double');
    inputImage = cast(inputImage,'double');
    baseImage = baseImage ./ 2 + .1;
    inputImage = inputImage ./ 2 + .1;    
else
    %Normalize the images
    baseImage = mat2gray(baseImage);
    inputImage = mat2gray(inputImage);    
end

%% ------ Transform optimization ------ %%

%Create objective function for minimization

%Create a dummy transformation structure which the optimization will tweak
%the parameters of. This prevents us having to create a transformation each
%time the objective function is evaluated.
if strcmp(xType,'projective')
    dumXf = maketform('projective',eye(3));
else
    dumXf = cp2tform(ones(10,2),ones(10,2)+rand(10,2)/10,'polynomial',2);     
end

objFun = @(x)tweakTransform(baseImage,inputImage,dumXf,x);

%Check initial RMSD
rmsdInit = objFun(iGuess(:));

tic;
%Minimize the objective function to find optimal transform
disp('Please wait, calculating transform...');

minOpts = optimset('TolFun',1e-10,'MaxFunEvals',5e3);

[x,rmsdFinal,exFlag,output] = fminsearch(objFun,iGuess(:),minOpts);


telaps = toc;
if exFlag > 0
     disp(['Finished. Took ' num2str(telaps/60) ' minutes.']);
     disp([num2str(output.iterations) ' iterations, ' num2str(output.funcCount) ' function evaluations.'])
     disp(['Initial RMSD : ' num2str(rmsdInit) ', final RMSD: ' num2str(rmsdFinal)]);
else
    disp('Optimization failed!')
    optimalXform = [];
    return
end

%Convert parameter vector back to transformation matrix
tMat = zeros(size(iGuess));
tMat(:) = x(:);        

%Convert it to transform structure
if strcmp(xType,'projective')
    optimalXform = maketform('projective',tMat);
else
    %There HAS to be a better way to do this????!!!!??
    optimalXform = cp2tform(ones(10,2),ones(10,2)+rand(10,2)/10,'polynomial',3);
    optimalXform.tdata = tMat;
end

if showFigs
    
    
    fsFigure(.75);
    subplot(1,2,1)
    image(cat(3,mat2gray(baseImage),mat2gray(inputImage),zeros(size(inputImage))))
    title('Original Overlay'),axis image
    newImage = imtransform(inputImage,optimalXform,'XData',[1 size(baseImage,2)],'YData',[1 size(baseImage,1)],'FillValues',1);
    subplot(1,2,2)
    image(cat(3,mat2gray(baseImage),mat2gray(newImage),zeros(size(inputImage))))
    title('Aligned Overlay'),axis image
    
end

function imErr = tweakTransform(baseImage,inImage,dumXf,dX)

%This function calculates the mean squared error between two images after
%one is transformed by the transformation specifed by the vector dX. The
%vector should be a vectorized version of the transformation matrix as used
%by imtransform.m 


%Create the transform with the current parameters
if numel(dX) == 9    
    dumXf = maketform('projective',reshape(dX,3,3));
elseif numel(dX) == 12
    dumXf.tdata(:) = dX(:);    
end

%Transform the input image with the new transformation
inImage = imtransform(inImage,dumXf,'XData',[1 size(baseImage,2)],'YData',[1 size(baseImage,1)],'FillValues',NaN);

%Calculate the MSD between the two images. Ignore NaNs.
imErr = nanmean(((baseImage(:) - inImage(:)) .^2 ));
