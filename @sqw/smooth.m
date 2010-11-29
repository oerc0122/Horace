function wout = smooth (win,varargin)
% Smooth method - dataway to dnd object smoothing only.

% Original author: T.G.Perring
%
% $Revision$ ($Date$)

wout=win;%initalise the output
for i=1:numel(win)
    if is_sqw_type(win(i))
        error('No smoothing of sqw data implemented. Convert to corresponding dnd object and smooth that.')
    else
        wout(i) = win(i);
        wout(i).data = smooth_dnd(win(i).data,varargin{:});
    end
end