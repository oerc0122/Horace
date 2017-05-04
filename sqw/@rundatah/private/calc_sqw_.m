function [w, grid_size, urange] = calc_sqw_(obj,detdcn, det0, grid_size_in, urange_in)
% Create an sqw object, optionally keeping only those data points within a defined data range.
%
%   >> [w, grid_size, urange] = obj.calc_sqw(detdch, det0,grid_size_in,
%   urange_in)
%
% Input:
% ------
%   detdcn         Direction of detector in spectrometer coordinates ([3 x ndet] array)
%                       [cos(phi); sin(phi).*cos(azim); sin(phi).sin(azim)]
%   det0           Detector structure corresponding to unmasked detectors. This
%                  is what is used int the creation of the sqw object. It must
%                  be consistent with det.
%                  [If data has field qspec, then det is ignored]
%   grid_size_in    Scalar or [1x4] vector of grid dimensions
%   urange_in       Range of data grid for output as a [2x4] matrix:
%                     [x1_lo,x2_lo,x3_lo,x4_lo;x1_hi,x2_hi,x3_hi,x4_hi]
%                   If [] then uses the smallest hyper-cuboid that encloses the whole data range.
%
%
% Output:
% --------
%   w               Output sqw object
%   grid_size       Actual size of grid used (size is unity along dimensions
%                  where there is zero range of the data points)
%   urange          Actual range of grid - the specified range if it was given,
%                  or the range of the data if not.
%
% $Revision$ ($Date$)
%


hor_log_level=config_store.instance().get_value('hor_config','log_level');

% Fill output main header block
% -----------------------------
main_header.filename='';
main_header.filepath='';
main_header.title='';
main_header.nfiles=1;


% Fill header and data blocks
% ---------------------------
if hor_log_level>-1
    disp('Calculating projections...');
end
% Perform calculations
% -----------------------
% Calculate projections of the instrument data into the q-space;
[pix_range,pix] = convert_to_lab_frame_(obj,detdcn,obj.qpsecs_cash);
[header,sqw_data]=build_header(obj);
[~,u_to_rlu] = obj.lattice.calc_proj_matrix();

u = obj.lattice.u;
v = obj.lattice.v;
sqw_data.proj = projection(grid_size_in,urange_in,u,v);

sqw_data.proj.u_to_rlu = u_to_rlu;
header.u_to_rlu = sqw_data.proj.u_to_rlu;

% sort pixels into image bins but keep them in initial coordinate system
[sqw_data.s,sqw_data.e,sqw_data.npix,sqw_data.pix]...
    = sqw_data.proj.sort_pixels_by_bins(pix,pix_range);

 

% Create sqw object (just a packaging of pointers, so no memory penalty)
% ----------------------------------------------------------------------
d.main_header=main_header;
d.header=header;
d.detpar=det0;
d.data=data_sqw_dnd(sqw_data);
%
grid_size = sqw_data.proj.grid_size;
urange    = sqw_data.proj.urange;
w=sqw(d);


%------------------------------------------------------------------------------------------------------------------
function [header,sqw_data] = build_header(obj)
% Calculate sqw file header and data for a single spe file
%
%   >> [header,sqw_data] = calc_sqw_header_data (efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs, data, det)
%
% Input:
% ------
%              [If data has field qspec, then det is ignored]
%   detdcn      Direction of detector in spectrometer coordinates ([3 x ndet] array)
%                   [cos(phi); sin(phi).*cos(azim); sin(phi).sin(azim)]
%
% Ouput:
% ------
%   header      Header information in data structure suitable for put_sqw_header
%   sqw_data    Data structure suitable for put_sqw_data

% Original author: T.G.Perring


% Create header block
% -------------------
[fp,fn,fe]=fileparts(obj.data_file_name);

header.filename = [fn,fe];
header.filepath = [fp,filesep];
header.efix     = obj.efix;
header.emode   = obj.emode;
%
%TODO: Wrap in lattice:
%header.lattice  = obj.lattice;
lat = obj.lattice.set_rad();
header.alatt = lat.alatt;
header.angdeg = lat.angdeg;
header.cu = lat.u;
header.cv = lat.v;
header.psi = lat.psi;
header.omega = lat.omega;
header.dpsi = lat.dpsi;
header.gl = lat.gl;
header.gs = lat.gs;
%<< -- end of lattice

header.en       = obj.en;
%>------------ a single file data projection! --> TODO: generalize to
%projection
header.uoffset = [0;0;0;0];
% TODO: inserted empty field here to avoid incorrect class checks. Should
% be changed properly when header is class.
header.u_to_rlu = []; %
header.ulen = [1,1,1,1];
header.ulabel = {'Q_\zeta','Q_\xi','Q_\eta','E'};
%<------------ a file projection!
% Update some header fields
header.instrument=obj.instrument;
header.sample=obj.sample;


% Now package the data
% --------------------
sqw_data.filename = '';
sqw_data.filepath = '';
sqw_data.title = '';
sqw_data.alatt = obj.lattice.alatt;
sqw_data.angdeg = obj.lattice.angdeg;
