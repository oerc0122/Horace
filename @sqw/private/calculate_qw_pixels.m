function qw=calculate_qw_pixels(win)
% Calculate qh,qk,ql,en for the pixels in an sqw dataset
%
%   >> qw=calculate_qw_bins(win)
%
%   win     Input sqw object
%
%   qw      Components of momentum (in rlu) and energy for each pixel in the dataset
%           Arrays are packaged as cell array of column vectors for convenience
%           with fitting routines etc.
%               i.e. qw{1}=qh, qw{2}=qk, qw{3}=ql, qw{4}=en
%

% Original author: T.G.Perring
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)


% Get some 'average' quantities for use in calculating transformations and bin boundaries
% *** assumes that all the contributing spe files had the same lattice parameters and projection axes
% This could be generalised later - but with repercussions in many routines

if iscell(win.header)
    header_ave = win.header{1};
else
    header_ave = win.header;
end
u0 = header_ave.uoffset;
u = header_ave.u_to_rlu(1:3,1:3);

% Assume that the first three axes are Q, and the 4th axis is energy
if ~all(u==eye(3))   % not identity matrix, so need to perform matrix transformation
    urlu=u*win.data.pix(1:3,:);
    qh=urlu(1,:)';
    qk=urlu(2,:)';
    ql=urlu(3,:)';
else
    qh=win.data.pix(1,:)';
    qk=win.data.pix(2,:)';
    ql=win.data.pix(3,:)';
end
en=win.data.pix(4,:)';

if ~u0(1)==0, qh=qh+u0(1); end 
if ~u0(2)==0, qk=qk+u0(2); end 
if ~u0(3)==0, ql=ql+u0(3); end 
if ~u0(4)==0, en=en+u0(4); end 

% package as cell array of column vectors for convenience with fitting routines etc.
qw = {qh(:), qk(:), ql(:), en(:)};