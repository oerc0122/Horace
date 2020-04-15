function wout = rebunch (win,varargin)
% Rebunch method - gataway to dnd object rebunching only.

% Original author: T.G.Perring
%
% $Revision:: 1758 ($Date:: 2019-12-16 18:18:50 +0000 (Mon, 16 Dec 2019) $)

% Only applies to dnd datasets at the moment. Check all elements before rebunching (avoids possibly costly wasted computation if error)
for i=1:numel(win)
    if is_sqw_type(win(i))
        error('No rebunching of sqw data implemented. Convert to corresponding dnd object and rebunch that.')
    end
end

wout=win;   % initalise the output
for i=1:numel(win)
    wout(i).data = rebunch_dnd(win(i).data,varargin{:});
end
