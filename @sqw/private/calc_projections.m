function [u_to_rlu, ucoords] = ...
    calc_projections (efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs, data, det)
% Label pixels in an spe file with coords in the 4D space defined by crystal Cartesian coordinates
% and energy transfer. 
% Allows for correction scattering plane (omega, dpsi, gl, gs) - see Tobyfit for conventions
%
%   >> [u_to_rlu, ucoords] = ...
%    calc_projections (efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs, data, det)
%
% Input:
%   efix        Fixed energy (meV)
%   emode       Direct geometry=1, indirect geometry=2
%   alatt       Lattice parameters (Ang^-1)
%   angdeg      Lattice angles (deg)
%   u           First vector (1x3) defining scattering plane (r.l.u.)
%   v           Second vector (1x3) defining scattering plane (r.l.u.)
%   psi         Angle of u w.r.t. ki (rad)
%   omega       Angle of axis of small goniometer arc w.r.t. notional u
%   dpsi        Correction to psi (rad)
%   gl          Large goniometer arc angle (rad)
%   gs          Small goniometer arc angle (rad)
%   data        Data structure of spe file (see get_spe)
%   det         Data structure of par file (see get_par)
%
% Output:
%   u_to_rlu    Matrix (3x3) of projection axes in reciprocal lattice units
%              i.e. u(:,1) first vector - u(1:3,1) r.l.u. etc.
%              This matrix can be used to convert components of a vector in the
%              projection axes to r.l.u.: v_rlu = u * v_proj
%   ucoords     [4 x npix] array of coordinates of pixels in crystal Cartesian
%              coordinates and energy transfer

% Original author: T.G.Perring
%
% $Revision$ ($Date$)
%
%
% Check input parameters
% -------------------------
ndet=size(data.S,2);
% Check length of detectors in spe file and par file are same
if ndet~=length(det.phi)
    mess1=['.spe file ' data.filename ' and .par file ' det.filename ' not compatible'];
    mess2=['Number of detectors is different: ' num2str(ndet) ' and ' num2str(length(det.phi))];
    error('%s\n%s',mess1,mess2)
end

% Check incident energy consistent with energy bins
if emode==1 && data.en(end)>=efix
    error(['Incident energy ' num2str(efix) ' and energy bins incompatible'])
elseif emode==2 && data.en(1)<=-efix
    error(['Final energy ' num2str(efix) ' and energy bins incompatible'])
elseif emode==0 && exp(data.en(1))<0
    error('Elastic scattering mode and wavelength bins incompatible')
end

% Create matrix to convert from spectrometer axes to coords along projection axes
[spec_to_proj, u_to_rlu] = calc_proj_matrix (alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);


c=get_neutron_constants;
k_to_e = c.k_to_e; % picked up by calc_proj_c;

% Convert to projection axes 

% Calculate Q in spectrometer coordinates for each pixel 
use_mex=get(hor_config,'use_mex');
if use_mex
    try     %
        nThreads=get(hor_config,'threads'); % picked up by calc_proj_c;

        ucoords =calc_projections_c(spec_to_proj,data, det,efix, k_to_e,emode,nThreads);
    catch   %using matlab routine
        warning('HORACE:using_mex','Problem with C-code: %s, using Matlab',lasterr());   
        use_mex=false;
    end    
end
if ~use_mex
    qspec = calc_qspec (efix, k_to_e,emode, data, det);      
%    ucoords = calc_proj_matlab (spec_to_proj, qspec);
    ucoords = spec_to_proj*qspec(1:3,:);
    ucoords = [ucoords;qspec(4,:)];   

end

