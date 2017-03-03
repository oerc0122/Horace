function wout = sigvar (w)
% Create sigvar object from sqw object
% 
%   >> wout = sigvar (w)

% Original author: T.G.Perring
%
% $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)

wout = sigvar(w.data.s, w.data.e);
