function wout = copydata (win,varargin)
% Overwrite the signal and errors from data in another object
%
% Signal and errors from numeric arrays:
%   >> wout = copydata (win, signal)
%   >> wout = copydata (win, signal, errors)
%
% Signal and error from an object
%   >> wout = copydata (win, object)
%
% Signal and error from different objects
%   >> wout = copydata (win, object_signal, object_errors)
%
% The input types can be mixed. Numeric arrays are scalar expanded if necessary.
% Set an argument to [] to leave the corresponding output unchanged:
%
%   >> wout = copydata (win, signal)        % signal changed, errors set to zero
%   >> wout = copydata (win, signal, [])    % signal changed, errors unchanged
%   >> wout = copydata (win, [], errors)    % signal unchanged, errors changed
%
% Input:
% ------
%   wout    Input dataset
%
%   signal  Numeric array with the signal to be copied
%
%   errors  [Optional] numeric array with the standard deviations to be copied
%
% *OR*
%
%   object  Object from which the signal and errors will be copied.
%           The object must have a method with name xye that satisfies the
%          following syntax:
%
% Output:
% -------
%   wout    Output dataset


% Original author: T.G.Perring
%
% $Revision:: 1759 ($Date:: 2020-02-10 16:06:00 +0000 (Mon, 10 Feb 2020) $)


% ----- The following shoudld be independent of d0d, d1d,...d4d ------------
% Work via sqw class type

wout=dnd(copydata(sqw_old(win),varargin{:}));

