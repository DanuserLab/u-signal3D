function t = tsurf(F,V,varargin)
  % TSURF trisurf wrapper, easily plot triangle meshes with(out) face or vertex
  % indices. Attaches callbacks so that click-and-holding on the mesh and then
  % pressing 'm' launches meshplot (if available)
  %
  % t = tsurf(F,V);
  % t = tsurf(F,V,'ParameterName',ParameterValue, ...)
  %
  % Inputs:
  %   F  list of faces #F x 3
  %   V  vertex positiosn #V x 3 or #V x 2
  %   Optional:
  %     'VertexIndices' followed by 
  %     'FaceIndices' followed by 
  %                   0 -> off
  %                   1 -> text and grey background
  %                  -1 -> text and grey background (decremented by 1)
  %                  >1 -> text
  %     ... additional options passed on to trisurf
  % Outputs:
  %  t  handle to trisurf object
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch)
  %
  % Example:
  %   % Compose with set function to set trisurf parameters to achieve
  %   % sharp isointervals
  %   tsurf(F,V, ...
  %     'FaceColor','interp', ...
  %     'FaceLighting','phong', ...
  %     'EdgeColor',[0.2 0.2 0.2]); 
  %   colormap(flag(8))
  %
  % See also: trisurf
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


  vertex_indices = 0;
  face_indices = 0;
  tets = [];
  buttondownfcn = 'default';

  v = 1;
  while v<=numel(varargin) && ischar(varargin{v}) 
    switch varargin{v}
    case 'VertexIndices'
      v = v+1;
      assert(v<=numel(varargin));
      vertex_indices = varargin{v};
    case 'FaceIndices'
      v = v+1;
      assert(v<=numel(varargin));
      face_indices = varargin{v};
    case 'Tets'
      v = v+1;
      assert(v<=numel(varargin));
      tets = varargin{v};
    case 'ButtonDownFcn'
      v = v+1;
      assert(v<=numel(varargin));
      buttondownfcn = varargin{v};
    otherwise
      break;
    end
    v = v+1;
  end
  
  % number of vertices
  n = size(V,1);

  % nuymber of dimensions
  dim = size(V,2);

  if(dim==2 || (dim ==3 && sum(abs(V(:,3))) == 0))
    V = [V(:,1) V(:,2) 0*V(:,1)];
    dim = 2;
  elseif ( (dim>3 || dim<2 ))
      if dim==4 && all(V(:,4)==1.0)
          V = V(:,1:3);
      else
    error('V must be #V x 3 or #V x 2');
    return;
      end
  end

  %tets = size(F,2) ==4 && (size(F,1)*4 > 1.01*size(boundary_faces(F),1));
  if isempty(tets)
    tets = false;
  if size(F,2) == 4
    VV = bsxfun(@minus,V,min(V))*max(max(V)-min(V));
    tets = sum(volume(VV,F))>1e-10;
    if ~tets
      Ftri = [F(:,[1 2 3]);F(:,[1 3 4])];
      Itri = repmat(1:size(F,1),1,2);
    end
  else
    tets = false;
    Ftri = F;
    Itri = 1:size(F,1);
  end
  end

  FI = 1:size(F,1);
  if face_indices<0
    FI = FI-1;
  end
  if tets
    t_copy = tetramesh(F,V,'FaceAlpha',0.5);
    FC = barycenter(V,F);
    if(abs(face_indices)==1)
      text(FC(:,1),FC(:,2),FC(:,3),num2str((FI)'),'BackgroundColor',[.7 .7 .7]);
    elseif(face_indices)
      text(FC(:,1),FC(:,2),FC(:,3),num2str((FI)'));
    end
    set(gcf,'Renderer','OpenGL');
  else
    t_copy = trisurf(F,V(:,1),V(:,2),V(:,3));
    FC = barycenter(V,F);
    if(abs(face_indices)==1)
      text(FC(:,1),FC(:,2),FC(:,3),num2str((FI)'),'BackgroundColor',[.7 .7 .7]);
    elseif(face_indices)
      text(FC(:,1),FC(:,2),FC(:,3),num2str((FI)'));
    end
  end
  
  % if 2d then set to view (x,y) plane
  if( dim == 2)
    view(2);
  end

  if vertex_indices
    visible = reshape(unique(F),[],1);
    VI = visible - (vertex_indices<0);
    if(abs(vertex_indices)==1)
      text(V(visible,1),V(visible,2),V(visible,3),num2str(VI),'BackgroundColor',[.8 .8 .8]);
    elseif(vertex_indices)
      text(V(visible,1),V(visible,2),V(visible,3),num2str(VI));
    end
  end
  % uncomment these to switch to a better 3d surface viewing mode
  %axis equal; axis vis3d;
  %axis(reshape([min(V(:,1:dim));max(V(:,1:dim))],1,dim*2));
  if ...
    strcmp(get(gca,'XLimMode'),'auto') && ...
    strcmp(get(gca,'YLimMode'),'auto') && ...
    strcmp(get(gca,'ZLimMode'),'auto')
    axis tight;
  end

  if v<=numel(varargin)
    set(t_copy,varargin{v:end});
  end

  % Only output if called with output variable, prevents ans = ... output on
  % terminal
  if nargout>=1
    t = t_copy;
  end

  % subversively set up the callbacks so that if the user clicks and holds on
  % the mesh then hits m, meshplot will open with this mesh
  switch buttondownfcn
  case 'default'
    set(t_copy,'buttondownfcn',@ondown);
  case 'none'
  otherwise
  end

  
  function ondown(src,ev)
    if exist('point_mesh_squared_distance','file')==3
      [~,ci,C] = point_mesh_squared_distance(ev.IntersectionPoint,V,Ftri);
      warning off;
        B = barycentric_coordinates(C,V(Ftri(ci,1),:),V(Ftri(ci,2),:),V(Ftri(ci,3),:));
      warning on;
      on_vertex = sum(B<0.15)==2;
      color = [.7 .5 .5];
      if on_vertex
        ci = Ftri(ci,max(B)==B);
        color = [.5 .5 .7];
        C = V(ci,:);
      else
        ci = Itri(ci);
        C = FC(ci,:);
      end
      text_h = text(C(:,1),C(:,2),C(:,3),num2str(ci),'BackgroundColor',color);
    end
    set(gcf,'windowbuttonupfcn',@onup);
    set(gcf,'keypressfcn',@onkeypress);

    function onkeypress(src,ev)
      switch ev.Character
      case 'm'
        V3 = t_copy.Vertices;
        if size(V3,2) == 2
          V3(:,3) = 0*V(:,1);
        end
        fprintf('Opening mesh in viewmesh...\n');
        writeOBJ('.vm.obj',V3,F);
        system('/usr/local/bin/viewmesh .vm.obj');
      otherwise
        warning(['Unknown key: ' ev.Character]);
      end
    end

    function onup(src,ev)
      if exist('text_h','var') && ishandle(text_h)
        delete(text_h);
      end
      set(gcf,'windowbuttonupfcn','');
      set(gcf,'keypressfcn',      '');
      set(gcf,'windowbuttonmotionfcn','');
    end
  end

end
