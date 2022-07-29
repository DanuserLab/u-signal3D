function [ tf ] = all_insequence( s, start, stop , interval)
%insequence Checks to see if value is in the sequence start:interval:stop
%
% Roughly equivalent to all(ismember(x,start:interval:stop))
%
% This function does not handle negative intervals
% It is faster than ismember since for a sequence one can first check to
% see if x in the interval [start stop], and then see if (x-start)/interval
% is an integer.
%
% INPUT
% x - vector to query if in the sequence
% start - beginning of sequence
% stop  - end of sequence
% interval - (optional) interval between numbers in sequence
%            default: 1
%
% OUTPUT
% tf - logical vector same size as x
%
% See also ismember, insequence, insequence_and_scalar
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

% Mark Kittisopikul, April 2017
% Jaqaman Lab
% UT Southwestern

tf = true;

for x = s(:).'

    if(x < start || x > stop)
        tf = false;
        return;
    end

    if(nargin < 4)
        x = (x - start);

    else
        x = (x - start)./interval;
    end
    tf = x == round(x);
    if(~tf)
        break;
    end
    
end



end

