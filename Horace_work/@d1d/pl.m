function pl(w)
% PL Draws a marker plot of a 1D dataset on an existing plot
%
%   >> pl(w)
%

% Original author: T.G.Perring
%
% $Revision$ ($Date$)
%
% Horace v0.1   J.Van Duijn, T.G.Perring

% Check spectrum is not an array
if length(w)>1
    error ('This function only plots a single 1D dataset - check length of spectrum array')
end

pl(d1d_to_spectrum(w))