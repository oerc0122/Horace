function [ok, mess] = checkfields (d)
% Check fields for d2d object
%
%   >> [ok, mess] = checkfields (d)
%
%   ok      ok=true if valid, =false if not
%   mess    Message if not a valid object, empty string if is valid.

% Original author: T.G.Perring
%
% $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)

% Non-ideal routine:
% Because we go via sqw objects to make d0d,d1d... the only
% way we have to check the fields is to try to construct the dnd.
tmp=d2d(d);
ok=true;
mess='';
