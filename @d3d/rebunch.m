function wout = rebunch (win,varargin)
% Bunch together the bins in a three dimensional dataset
%
% Syntax:
%   >> wout = rebunch (win, nbunch)
%
% Input:
% ------
%   win     Input dataset or array of datasets
%   nbunch  Vector that sets the number of bins to be bunched together along
%          each axis
%           If nbunch is scalar, then the value is applied to all dimensions
%           If the original number of bins along an an axis is not an integer
%          multiple of nbunch, then the final bin of the output data set is
%          correspondingly enlarged.
%
% Output:
% -------
%   wout    Rebunched data structure
%
%
% EXAMPLE
%   >> wout = rebunch (win, 2)
%   >> wout = rebunch (win, [2,4])


% Original author: T.G.Perring
%
% $Revision:: 1750 ($Date:: 2019-04-08 17:55:21 +0100 (Mon, 8 Apr 2019) $)


% ----- The following should be independent of d0d, d1d,...d4d ------------
% Work via sqw class type

wout=dnd(rebunch(sqw(win),varargin{:}));
