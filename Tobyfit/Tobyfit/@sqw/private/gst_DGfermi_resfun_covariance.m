function [cov_hkle, cov_kikf, cov_proj, cov_spec] = gst_DGfermi_resfun_covariance(win, indx, lookup)
% Return 4D momentum-energy covariance matrix for the resolution function
%
% For all pixels:
%   >> [cov_spec, cov_kikf, cov_proj, cov_hkle] = gst_DGfermi_resfun_covariance (w)
%
% For selected pixels:
%   >> [cov_spec, cov_kikf, cov_proj, cov_hkle] = gst_DGfermi_resfun_covariance (w, indx)
%
%
% Input:
% ------
%   win         Array of sqw objects, or cell array of scalar sqw objects
%
%  [Optional]
%   indx        Pixel indicies:
%               Single sqw object:
%                 - ipix            Array of pixels indicies
%            *OR* - {irun,idet,ien} Arrays of run, detector and energy bin index
%                                   Dimension expansion is performed on scalar
%                                  quantities i.e. each must be a scalar or array
%                                  with arrays having the same length
%               Multiple sqw object:
%                 - As above, assumed to apply to all sqw objects,
%            *OR* - Cell array of the above, one cell array per sqw object
%                  e.g. if two sqw objects:
%                       {ipix1, ipix2}
%                       {{irun1,idet1,ien1}, {irun2,idet2,ien2}}
%
% Output:
% -------
% [The format of the following trhee arguments depends on the format of win:
%   - win is a scalar sqw object:       Array size [4,4,npix]
%   - win is an array of sqw objects:   Cell array of arrays size [4,4,npix(i)]
%   - win is a cell array:               "     "    "    "     "       "         ]
%
%   cov_proj    Covariance matrix for wavevector-energy in projection axes
%
%   cov_spec    Covariance matrix for wavevector-energy in spectrometer axes
%              i.e. x || ki, z vertical upwards, y perpendicular to z and y.
%
%   cov_hkle    Covariance matrix for wavevector-energy in h-k-l-energy
%
% Like the other outputs, but [6,6,npix]
%   cov_kikf    Covariance matrix for ki_1, ki_2, ki_3, kf_1, kf_2, kf_3,
%               where 1 is parallel to the beam, 2 perpendicular (usually
%               in the horizontal plan) and 3 completes the right handed
%               coordinate system

% Check which output has been requested
which_cov = true(4,1);
for i=4:-1:2; if nargout < i; which_cov(i) = false; end; end
% Don't bother doing anything for no output variables
if nargout < 1; return; end

% Check inputs
if nargin < 2 || isempty(indx)
    all_pixels = true;
else
    all_pixels = false;
end
if nargin < 3 || isempty(lookup)
    % Get lookup arrays
    % -----------------
    if all_pixels
        [ok,~,lookup] = gst_DGfermi_resconv_init( win, 'notables' );
    else
        [ok,~,lookup] = gst_DGfermi_resconv_init( win, indx, 'notables' );
    end
    if ~ok; return; end
end


% Get variances
% -------------
% This block of code effectively does the equivalent of tobyfit_DGfermi_resconv

use_tube=false; % use 3He cylindrical gas tube (true) or Tobyfit original (false)

if which_cov(1); cov_hkle = cell(size(win)); end
if which_cov(2); cov_kikf = cell(size(win)); end
if which_cov(3); cov_proj = cell(size(win)); end
if which_cov(4); cov_spec = cell(size(win)); end

for iw = 1:numel(win)
    if iscell(win), wtmp = win{iw}; else, wtmp = win(iw); end
    if all_pixels
        [~,~,irun,idet] = parse_pixel_indicies (wtmp);
    else
        [~,~,irun,idet] = parse_pixel_indicies (wtmp,indx,iw);
    end
    npix = numel(irun);
    
    % Simple pointers to items in lookup
    ei = lookup.ei{iw};
    moderator = lookup.moderator{iw};
    chopper = lookup.chopper{iw};
    wa = lookup.wa{iw};
    ha = lookup.ha{iw};
    sample = lookup.sample(iw);
    kf = lookup.kf{iw};
    det_width = lookup.det_width{iw};
    det_height = lookup.det_height{iw};
    dt = lookup.dt{iw};
    
    % Compute variances
    var_mod = (10^-6 * arrayfun_special(@pulse_width,moderator(irun),ei(irun))).^2;
    var_wa = wa(irun).^2 / 12;
    var_ha = ha(irun).^2 / 12;
    var_chop = (10^-6 * arrayfun_special(@pulse_width,chopper(irun),ei(irun))).^2;
    cov_sam = covariance(sample);
    if use_tube
        He3det=IX_He3tube(0.0254,10,6.35e-4);   % 1" tube, 10atms, wall thickness=0.635mm
        var_det_depth = var_d (He3det, kf);
        var_det_width = var_w (He3det, kf);
        var_det_height = det_height(idet).^2 / 12;
    else
        var_det_depth = repmat(0.015^2 / 12, npix, 1);  % approx dets as 25mm diameter, and FWHH=0.6 diameter
        var_det_width = det_width(idet).^2 / 12;
        var_det_height = det_height(idet).^2 / 12;
    end
    var_tdet = dt.^2 / 12;
    
    % Compute covariance matrix
    dq_mat = lookup.dq_mat{iw};
    b_mat = lookup.b_mat{iw};
    spec_to_rlu = lookup.spec_to_rlu{iw};
    
    cov_x = zeros(11,11,npix);
    cov_x(1,1,:) = var_mod;
    cov_x(2,2,:) = var_wa;
    cov_x(3,3,:) = var_ha;
    cov_x(4,4,:) = var_chop;
    cov_x(5:7,5:7,:) = repmat(cov_sam,1,1,npix);
    cov_x(8,8,:) = var_det_depth;
    cov_x(9,9,:) = var_det_width;
    cov_x(10,10,:) = var_det_height;
    cov_x(11,11,:) = var_tdet;
    
    % If we've gotten this far, we need cov_hkle for sure
    cov_hkle{iw} = transform_matrix (cov_x, dq_mat);
    if which_cov(2)
        cov_kikf{iw} = transform_matrix (cov_x, b_mat);
    end
    if which_cov(3)
        cov_proj{iw} = transform_matrix (cov_hkle{iw}, inv(wtmp.data.u_to_rlu));
    end
    if which_cov(4) 
        rlu_to_spec = invert_matrix (spec_to_rlu);
        rlu_to_spec4(1:3,1:3,:) = rlu_to_spec(:,:,irun);
        rlu_to_spec4(4,4,:) = 1;
        cov_spec{iw} = transform_matrix (cov_hkle{iw}, rlu_to_spec4);
    end
end

if ~iscell(win) && isscalar(win)
    if which_cov(1); cov_hkle = cov_hkle{1}; end
    if which_cov(2); cov_kikf = cov_kikf{1}; end
    if which_cov(3); cov_proj = cov_proj{1}; end
    if which_cov(4); cov_spec = cov_spec{1}; end
end

%test_covariance(cov_x,dq_mat)


%=============================================================================
function Cout = transform_matrix (C,B)
% Compute the matrix product Cout = B * C * B' for nD matricies
% B can be a 2D matrix and dimension expansion is performed

szC = size(C);
szB = size(B);
if numel(szC)==2 && numel(szB)==2
    % Just do straighforward matlab matric multiplication
    Cout = B * C * B';
else
    if numel(szB)==2
        tmp = mtimesx_horace (C, B');
    else
        tmp = mtimesx_horace (C, permute(B,[2,1,3:numel(szB)]));
    end
    Cout = mtimesx_horace (B, tmp);
end


%=============================================================================
function Cinv = invert_matrix (C)
% Compute the inverse of an array of square matricies, taking additional
% dimensions as the matrix array dimensions

szC = size(C);
if numel(szC)==2
    % Just do straighforward matlab inversion
    Cinv = inv(C);
else
    Cinv = zeros(size(C));
    for i=1:prod(szC(3:end))
        Cinv(:,:,i) = inv(C(:,:,i));
    end
end


%===================================================
function test_covariance (cov, dq_mat)
% COntributins to energy width
contr = zeros(11,1);
for i=1:11
    contr(i) = log(256)*cov(i,i)*dq_mat(4,i)^2;
end
total = sum(contr);
disp('-------------------------------')
disp(sqrt(total))
disp(sqrt(contr))
disp('-------------------------------')
