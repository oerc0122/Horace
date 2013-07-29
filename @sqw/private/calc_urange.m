function urange = calc_urange (efix, emode, eps_lo, eps_hi, det, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs)
% Compute range of data for a collection of data files given the projection axes and crystal orientation
%
% Normal use:
%   >> urange = calc_urange (efix, emode, eps_lo, eps_hi, det, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs)
%
% Input: (in the following, nfile = no. spe files)
% ------
%   efix            Fixed energy (meV)                 [vector length nfile]
%   emode           Direct geometry=1, indirect geometry=2    [scalar or vector length nfile]
%   eps_lo          Lower energy transfer (meV)        [vector length nfile]
%   eps_hi          Upper energy transfer (meV)        [vector length nfile]
%                  If empty (i.e. ehi=[]) then this argument is ignored. Use this
%                  if just want to calculate urange for a single energy transfer.
%   det             Name of detector .par file, or detector structure as read by get_par
%                                                      [single file name or scalar structure]
%   alatt           Lattice parameters (Ang^-1)        [vector length 3 or array size [nfile,3]]
%   angdeg          Lattice angles (deg)               [vector length 3 or array size [nfile,3]]
%   u               First vector defining scattering plane (r.l.u.)
%                                                      [vector length 3 or array size [nfile,3]]
%   v               Second vector defining scattering plane (r.l.u.)
%                                                      [vector length 3 or array size [nfile,3]]
%   psi             Angle of u w.r.t. ki (rad)         [vector length nfile]
%   omega           Angle of axis of small goniometer arc w.r.t. notional u (rad) 
%                                                      [vector length nfile]
%   dpsi            Correction to psi (rad)            [vector length nfile]
%   gl              Large goniometer arc angle (rad)   [vector length nfile]
%   gs              Small goniometer arc angle (rad)   [vector length nfile]
%
% Output:
% --------
%   urange          Actual range of grid

% Original author: T.G.Perring
%
% $Revision: 688 $ ($Date: 2013-03-17 11:07:49 +0000 (Sun, 17 Mar 2013) $)


nfile=numel(efix);
eps_hi_empty=isempty(eps_hi);

% Replicate some parameters, if required
if numel(efix)==1, efix=efix*ones(nfile,1); end
if numel(alatt)==3, alatt=repmat(alatt(:)',[nfile,1]); end
if numel(angdeg)==3, angdeg=repmat(angdeg(:)',[nfile,1]); end
if numel(u)==3, u=repmat(u(:)',[nfile,1]); end
if numel(v)==3, v=repmat(v(:)',[nfile,1]); end

% Invoke public get_par routine
if ischar(det) && size(det,1)==1
    det=get_par(det,'-hor');    
end
ndet=length(det.group);

% Get the maximum limits along the projection axes across all spe files
data.filename='';
data.filepath='';
if ~eps_hi_empty
    data.S=zeros(2,ndet);
    data.E=zeros(2,ndet);
else
    data.S=zeros(1,ndet);
    data.E=zeros(1,ndet);
end

urange=[Inf, Inf, Inf, Inf;-Inf,-Inf,-Inf,-Inf];
for i=1:nfile
    if ~eps_hi_empty
        data.en=[eps_lo(i);eps_hi(i)];
    else
        data.en=eps_lo(i);
    end
    [u_to_rlu, ucoords] = calc_projections (efix(i), emode(i), alatt(i,:), angdeg(i,:), u(i,:), v(i,:), psi(i), ...
        omega(i), dpsi(i), gl(i), gs(i), data, det);
    urange = [min(urange(1,:),min(ucoords,[],2)'); max(urange(2,:),max(ucoords,[],2)')];
end