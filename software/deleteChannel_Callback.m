function deleteChannel_Callback(hObject, eventdata, handles)
% Generic callback to be exectuted when a selected channel is removed from
% the graphical settings interface
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

% Get selected properties and returin if empty
selectedProps = get(handles.listbox_selectedChannels, {'String','UserData','Value'});
%selectedProps = {handles.listbox_selectedChannels.Items [find(ismember(handles.listbox_availableChannels.String, handles.listbox_selectedChannels.String))]};
if isempty(selectedProps{1}) || isempty(selectedProps{3}),return; end

% Delete selected item
%Jenny & Hillary: Debug edits on line below, changed from [] to {''}
selectedProps{1}(selectedProps{3}) = {''};
%selectedProps{2}(selectedProps{3}) = [ ];
%Hillary: Edited so index to be deleted from selectedProps{2} corresponds
%to value in selectedProps{3}
selectedProps{2}(find(selectedProps{2}==selectedProps{3})) = [];
% remove empty values from selectedProps{1}
selectedProps{1}(cellfun('isempty', selectedProps{1})) = [];
set(handles.listbox_selectedChannels, 'String', selectedProps{1},'UserData',selectedProps{2},...
    'Value',max(1,min(selectedProps{3},numel(selectedProps{1}))));