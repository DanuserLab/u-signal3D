function varargout=plotWindows(windowIn,varargin)
%PLOTWINDOWS plots the input windows on the current axes
% 
% plotWindows(windowIn)
% h = plotWindows(windowIn)
% h = plotWindows(windowIn,plotStyle,showNum)
%
% This function is for displaying the window geometry. It plots the window
% oultines and fills in their interior on the current figure axes. This can
% be used to overlay the windows on an image or to inspect their geometry.
% 
% Input 
%
%   windowIn - The cell-array containing the windows, as created with
%   getMaskWindows or getMovieWindows.m You may also pass a sub-set of the
%   windows, e.g. plotWindows(windows(1:3)) or plotWindows(windows{1}(4)),
%   but in this case if the showNum option is enabled, the numbering
%   displayed will be altered.
% 
%   stringIn - Plot style option(s) to pass to the patch command,
%   determining the appearance of the windows when plotted. To pass
%   multiple options, include them in a cell array. See the patch.m help
%   for more details. Optional. Default is {'r','FaceAlpha',.2}, which
%   plots windows filled in transparently with red, and with a black
%   outline.
%
%   showNum - Integer. If greater than 0, the indices of each showNum-th
%   window will be plotted next to the window. That is, if showNum equals
%   5, then every 5th window will have it's location in the window cell
%   array plotted next to it. Optional. Default is 0 (no numbers). WARNING:
%   If you have lots of windows, enabling this option may drastically slow
%   down the plotting. Also, if you are plotting only a sub-set of the
%   windows, the numbering will start at (1,1) at the beginning of this
%   subset.
%
%   Optional parameters in param/value pairs
%
%   bandMin - Integer. The value of first band to be displayed.
%   Default: 1.
%
%   bandMax - Integer. The value of the last band to be displayed. 
%   Default: Inf.
%
% Output:
%   
%   h - array of handles to the patch graphic objects and text objects if
%   applicable
%
%   The windows will be plotted as polygons on the current axes.
%
%Hunter Elliott
%Re-Written 5/2010
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

if nargin < 1 || isempty(windowIn)
    error('Come on, you have to at least input the window cell-array!')
end

% Input check
ip = inputParser;
ip.addOptional('stringIn',{'r','FaceAlpha',.2},@(x)iscell(x) || ...
    (ischar(x) && ~ismember(x,{'bandMin','bandMax'})));
ip.addOptional('showNum',0,@isscalar)
ip.addParamValue('bandMin',1,@isscalar);
ip.addParamValue('bandMax',Inf,@isscalar);
ip.parse(varargin{:});

stringIn = ip.Results.stringIn;
if ~iscell(stringIn), stringIn = {stringIn}; end
showNum = ip.Results.showNum;

%Check the cell array to see if a sub-set of windows were passed
if iscell(windowIn)
    if any(cellfun(@iscell,windowIn))
        if any(cellfun(@(x)(~isempty(x) && iscell(x{1})),windowIn))
            cellDepth = 3;                            
        else
            cellDepth = 2;
        end
    else
        %A single window was passed
        cellDepth = 1;
    end        
else
    error('The input windowIn must be a cell array!')
end

prevHold = ishold(gca);%Get hold state so we can restore it.
if ~prevHold
    %If hold wasn't on, clear the axis and then turn it on
    cla
    hold on
end

h=[];
switch cellDepth
    
    
    case 1
        
        if any(~cellfun(@isempty,windowIn))                
            currWin = [windowIn{:}];
            if ~isempty(currWin)

                h=patch(currWin(1,:),currWin(2,:),stringIn{:});

            end
        end                
        
    case 2

        for j = 1:numel(windowIn)            
            if ~isempty(windowIn{j})                
                currWin = [windowIn{j}{:}];
                if ~isempty(currWin)

                    h(end+1)=patch(currWin(1,:),currWin(2,:),stringIn{:});

                    if showNum && mod(j,showNum)==0
                        h(end+1)=text(currWin(1,1),currWin(2,1),num2str(j));
                    end                    
                end
            end
        end                               
        
    case 3
        
        for j = 1:numel(windowIn)        
            
            for k = max(1,ip.Results.bandMin):min(numel(windowIn{j}),ip.Results.bandMax)        
                if ~isempty(windowIn{j}{k})                
                    currWin = [windowIn{j}{k}{:}];
                    if ~isempty(currWin)

                        h(end+1)=patch(currWin(1,:),currWin(2,:),stringIn{:});

                        if showNum && mod(j,showNum)==0 && mod(k,showNum) == 0
                            h(end+1)=text(currWin(1,1),currWin(2,1),[num2str(j) ',' num2str(k)]);                       
                        end                    
                    end
                end
            end       
        end    
        
end


if ~prevHold %Restore previous hold state
    hold off
end
axis image
axis ij
%Only return the handles if output requested.
if nargout > 0
    varargout{1} = h;
end
