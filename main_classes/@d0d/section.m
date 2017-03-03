function wout = section (win, varargin)
% Takes a section out of a 0-dimensional dataset. Dummy routine as sectioning not possible
%
% Syntax:
%   >> wout = section (win)
                                                        
% Original author: T.G.Perring
%
% $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)


% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type

if nargin==1
    wout = win; % trivial case of no sectioning being required
else
    wout = dnd(section(sqw(win),varargin{:}));
end
