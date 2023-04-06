classdef FigFileDisplay < MovieDataDisplay
    %Concreate class to display external fig-file
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
    
    methods
        function obj=FigFileDisplay(varargin)
            obj@MovieDataDisplay(varargin{:})
        end
        
        function h=initDraw(obj,data,tag,varargin)
            % Plot the image and associate the tag
            h=gcf;         
            clf;
            h2= hgload(data, struct('visible','off'));
            copyobj(get(h2,'Children'),h);
            set(h,'Tag',tag);
        end
        function updateDraw(obj,h,data)
            h2= hgload(data, struct('visible','off'));
            copyobj(get(h2,'Children'),h);
        end  
    end 

    methods (Static)
        function params=getParamValidators()
            params=[];
        end
        function f=getDataValidator()
            f=@ischar;
        end
    end    
end