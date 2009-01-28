function wout = mask (win, mask_array)
% Remove the bins indicated by the mask array
%
% Syntax:
%   >> wout = mask (win, mask_array)
%
% Input:
% ------
%   win                 Input sqw object
%
%   mask_array          Array of 1 or 0 (or true or false) that indicate
%                      which points to retain. 
%                       Numeric or logical array of same number of elements
%                      as the data.
%                       Note: mask will be applied to the stored data array
%                      according as the projection axes, not the display axes.
%                      Thus permuting the display axes does not alter the
%                      effect of masking the data.
%
% Output:
% -------
%   wout                Output dataset.

% Original author: T.G.Perring
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)


% Initialise output argument
wout = win;

% Trivial case of empty or no mask arguments
if nargin==1 || isempty(mask_array)
    return
end

% Check mask is OK
if ~(isnumeric(mask_array) || islogical(mask_array)) || numel(mask_array)~=numel(win.data.s)
    error('Mask must provide a numeric or logical array with same number of elements as the data')
end
if ~islogical(mask_array)
    mask_array=logical(mask_array);
end

% Mask signal, variance and npix arrays
wout.data.s(~mask_array) = 0;
wout.data.e(~mask_array) = 0;
wout.data.npix(~mask_array) = 0;

% Section the pix array, if sqw type, and update urange
if is_sqw_type(win)
    mask_pix = logical(replicate_array (mask_array, win.data.npix));
    wout.data.pix=[];   % Clear the memory of a large array that is going to be replaced - but is a field, so musst leave present
    wout.data.pix=win.data.pix(:,mask_pix);
    wout.data.urange=[min(wout.data.pix(1:4,:),[],2)';max(wout.data.pix(1:4,:),[],2)'];
end