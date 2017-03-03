function [urange,u_to_rlu]=calc_urange(obj,varargin)
% Method calculates q-dE range, this rundata object has
%
%Usage:
%>>[urange,u_to_rlu]=obj.calc_urange()  Calculate urange for fully defined
%                                      rundatah object
%>>[urange,u_to_rlu]=obj.calc_urange('-cash_detectors')
%                           Calculate urange for fully defined
%                           rundatah object, using precacluated
%                           vectors, pointing detectors positons
%
%>>[urange,u_to_rlu]=obj.calc_urange(emin,emax) Calculate urange of the
%                  rundata object within the energy range provided.
%                  the object may be not fully defined (only detectors and
%                  (currently -- not mandatory) lattice should exist.
%                  if object is defined, energy range is calculated from
%                  min(emin,obj.en) to max(emax,obj.en)
%
%>>[urange,u_to_rlu,detdcn]=obj.calc_urange(emin,emax,'-cash_detectors')
%                  the combination of the previous two options
%
keys_recognized = {'-cash_detectors'};
[ok,mess,cash_detectors,params] = parse_char_options(varargin,keys_recognized);
if ~ok
    error('RUNDATAH:invalid_arguments','calc_urange: %s',mess)
end

b_obj = obj.build_bounding_obj(params{:});
det = b_obj.get_par();
% request to return all angular units as radians
b_obj.lattice = b_obj.lattice.set_rad();
%
%---------------------------------------------------------------------------
%

if cash_detectors
    detdcn = calc_or_restore_detdcn_(det);
else
    detdcn = [];
end
if isempty(obj.transform_sqw) % minor optimization not worth deploying ?
    data = struct('S',b_obj.S,'ERR',...
        b_obj.ERR,'en',b_obj.en);
    lat = b_obj.lattice;
    [u_to_rlu, urange] = calc_projections_(b_obj.efix, b_obj.emode,...
        lat.alatt, lat.angdeg, lat.u, lat.v,...
        lat.psi, lat.omega, lat.dpsi, lat.gl, lat.gs, data, det, detdcn);
    
else
   [~,~,urange] = b_obj.calc_sqw(2,[],varargin{:});                
end
