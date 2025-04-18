function writeNODE(filename,V,varargin)
  % WRITENODE Write vertex positions to a .node file
  %
  % writeNODE(filename,V)
  % writeNODE(filename,V,'ParameterName',ParameterValue)
  %
  % Inputs:
  %  filename  name of output file
  %  V  list of vertex positions
  %  Optional:
  %    'MinIndex' followed by minimum index {1}
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
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

  % default parameters
  min_index = 1;

  ii = 1;
  while ii <= numel(varargin)
    switch varargin{ii}
    case 'MinIndex'
      assert((ii+1)<=numel(varargin));
      ii = ii + 1;
      min_index = varargin{ii};
    otherwise
      error('Unsupported parameter: %s',varargin{ii});
    end
    ii = ii+1;
  end

  fp = fopen(filename,'w');
  % attributes are not supported
  % number of vertices  number of dimensions  0 0
  fprintf(fp,'%d %d 0 1\n',size(V));
  % .node is 1-indexed
  % build format string
  str = '%d';
  for(ii = 1:size(V,2))
    % use 0.16f so that triangle reproduces input
    str = [str ' %0.16f'];
  end
  str = [str ' 0\n'];
  indices = (1:size(V,1)) + (min_index-1);
  fprintf(fp,str,[indices' , V]');
  fclose(fp);
end
