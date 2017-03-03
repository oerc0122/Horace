function display_single (w)
% Display useful information from a d2d object
%
% Syntax:
%
%   >> display_single(w)

% Original author: T.G.Perring
%
% $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)

% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type

display(sqw(w))
