function urange = calc_sqw_urange (varargin)
% Compute range of data for a collection of data files given the projection axes and crystal orientation
%
% Normal use:
%   >> urange = calc_grid (efix, emode, eps_lo, eps_hi, det, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs)
%
% Input: (in the following, nfile = no. spe files)
%   efix            Fixed energy (meV)                 [scalar or vector length nfile]
%   emode           Direct geometry=1, indirect geometry=2    [scalar]
%   eps_lo          Lower energy transfer (meV)        [scalar or vector length nfile]
%   eps_hi          Upper energy transfer (meV)        [scalar or vector length nfile]
%   det             Name of detector .par file, or detector structure as read by get_par
%   alatt           Lattice parameters (Ang^-1)        [row or column vector]
%   angdeg          Lattice angles (deg)               [row or column vector]
%   u               First vector (1x3) defining scattering plane (r.l.u.)
%   v               Second vector (1x3) defining scattering plane (r.l.u.)
%   psi             Angle of u w.r.t. ki (deg)         [scalar or vector length nfile]
%   omega           Angle of axis of small goniometer arc w.r.t. notional u (deg) [scalar or vector length nfile]
%   dpsi            Correction to psi (deg)            [scalar or vector length nfile]
%   gl              Large goniometer arc angle (deg)   [scalar or vector length nfile]
%   gs              Small goniometer arc angle (deg)   [scalar or vector length nfile]
%
% Output:
% --------
%   urange          Actual range of grid

% Original author: T.G.Perring
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)


% Gateway routine that calls sqw method
urange = calc_sqw_urange (sqw, varargin{:});