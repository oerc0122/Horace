function w = sigvar_set(w,sigvarobj)
% Set output object signal and variance fields from input sigvar object
%
%   >> w = sigvar_set(w,sigvarobj)

% Original author: T.G.Perring
%
% $Revision:: 1759 ($Date:: 2020-02-10 16:06:00 +0000 (Mon, 10 Feb 2020) $)

if ~isequal(size(w.data.s),size(sigvarobj.s))
    error('sqw object and sigvar object have inconsistent sizes')
end

w.data.s=sigvarobj.s;
w.data.e=sigvarobj.e;

if is_sqw_type(w)
    % RAE spotted error 8/12/2010: should only create pix field if sqw object
    stmp = replicate_array(w.data.s, w.data.npix)';
    etmp = replicate_array(w.data.e, w.data.npix)';
    w.data.pix.signal = stmp;  % propagate signal into the pixel data
    w.data.pix.variance = etmp;
end

% If no pixels, then our convention is that signal and error set to zero
nopix=(w.data.npix==0);
w.data.s(nopix)=0;
w.data.e(nopix)=0;

