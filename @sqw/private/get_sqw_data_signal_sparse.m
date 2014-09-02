function [mess, data] = get_sqw_data_signal_sparse (fid, fmt_ver, S, make_full_fmt, opt, varargin)
% Read data structure
%
%   >> [mess, data] = get_sqw_data_signal (fid, fmt_ver, S, make_full_fmt, opt)
%   >> [mess, data] = get_sqw_data_signal (fid, fmt_ver, S, make_full_fmt, opt, range)
%   >> [mess, data] = get_sqw_data_signal (fid, fmt_ver, S, make_full_fmt, opt, range, range2)
%
% Input:
% ------
%   fid         File identifier of output file (opened for binary reading). The file position
%              indicator on entry to be at the start of the signal array.
%
%               The input file is assumed to have either dnd-type or sqw-type data.
%   fmt_ver     Version of file format e.g. appversion('-v3')
%
%   S           sqwfile structure that contains information about the data in the sqw file
%
%   make_full_fmt   Make sparse arrays full format if true
%
%   opt         Structure that defines the output (only one field can be true, the other false):
%                       'dnd','sqw','nopix','buffer'
%                       'npix','npix_nz','pix_nz','pix'
%
%   range, range2   Optional arguments in the case of fields 'npix','npix_nz','pix_nz','pix':
%                   if opt.npix     [bin_lo, bin_hi],   [ind_lo, ind_hi]
%                   if opt.npix_nz  [bin_lo, bin_hi],   [ind_lo, ind_hi]
%                   if opt.pix_nz   [ind_lo, ind_hi]
%                   if opt.pix_nz   [pix_lo, pix_hi]                        if not make_full_fmt
%                                   [pix_lo, pix_hi]    [ind_lo, ind_hi]    if make_full_fmt
%
% Output:
% -------
%   mess        Error message; ='' if all OK, non-empty if a problem
%
%   data        Contains data read from file
%               If option is one of 'dnd', 'sqw', 'nopix', 'buffer', then data
%              is a structure with the fields below:
%                   opt.dnd:    s,e,npix
%                   opt.sqw:    s,e,npix,urange,npix_nz,pix_nz,pix
%                   opt.nopix:  s,e,npix,urange
%                   opt.buffer: npix,npix_nz,pix_nz,pix
%
%       data.s          Average signal in the bins (sparse column vector)
%       data.e          Corresponding variance in the bins (sparse column vector)
%       data.npix       Number of contributing pixels to each bin as a sparse column vector
%       data.urange     True range of the data along each axis [urange(2,4)]. This is in the
%                      coordinates of the plot/integration projection axes, NOT the projection
%                      axes of the individual pixel info.
%       data.npix_nz    Number of non-zero pixels in each bin (sparse column vector)
%       data.pix_nz     Array with idet,ien,s,e for the pixels with non-zero signal sorted so that
%                      all the pixels in the first bin appear first, then all the pixels in the
%                      second bin etc. If more than one run contributed, array contains irun,idet,ien,s,e.
%       data.pix        Index of pixels, sorted so that all the pixels in the first
%                      bin appear first, then all the pixels in the second bin etc. (column vector)
%                           ipix = ie + ne*(id-1)
%                       where
%                           ie  energy bin index
%                           id  detector index into list of all detectors (i.e. masked and unmasked)
%                           ne  number of energy bins
%                       If more than one run contributed, then
%                           ipix = ie + ne*(id-1) + cumsum(ne(1:irun-1))*ndet
%
%               If option is to read npix, npix_nz, pix_nz or pix, then data is a single array:
%                   opt.npix    npix arrayarray (or column vector if range present, length=diff(range))
%                   opt.pix     [9,npixtot] array (or [9,n] array if range present, n=diff(range))


% Original author: T.G.Perring
%
% $Revision: 890 $ ($Date: 2014-08-31 16:32:12 +0100 (Sun, 31 Aug 2014) $)


% Prepare some parameters for reading the data
% --------------------------------------------
% Unpack fields of S to reduce access time later on
info=S.info;
pos=S.position;
fmt=S.fmt;

% Get size of signal, error, npix arrays
ndims=info.dims;
if ndims>1
    sz=info.sz_npix(1:ndims);
elseif ndims==1
    sz=[info.sz_npix(1),1];
else
    sz=[1,1];
end

% Determine which fields to read and if output is a data structure
read_se     = opt.dnd || opt.sqw || opt.nopix;
read_npix   = read_se || opt.buffer || opt.npix;
read_urange = opt.sqw || opt.nopix;
read_npix_nz= ((opt.sqw || opt.buffer) && ~make_full_fmt) || opt.npix_nz;
read_pix_nz = opt.sqw || opt.buffer || (opt.pix && make_full_fmt) || opt.pix_nz;
read_pix    = opt.sqw || opt.buffer || opt.pix;

datastruct  = opt.dnd || opt.sqw || opt.nopix || opt.buffer;


% Read the fields
% ---------------
% Read signal and error
if read_se
    fseek(fid,pos.s,'bof');
    if make_full_fmt    % for some reason, this odd looking 3 lines is faster (1 sep 2014)
        [s,ok,mess] = read_sparse(fid,make_full_fmt);
        if ~ok, return, end
        data.s=reshape(s,sz);
        clear s
    else
        [data.s,ok,mess] = read_sparse(fid);
        if ~ok, return, end
    end
    
    fseek(fid,pos.e,'bof');
    if make_full_fmt    % for some reason, this odd looking 3 lines is faster (1 sep 2014)
        [e,ok,mess] = read_sparse(fid,make_full_fmt);
        if ~ok, return, end
        data.e=reshape(e,sz);
        clear e
    else
        [data.e,ok,mess] = read_sparse(fid);
        if ~ok, return, end
    end
end

% Read npix
if read_npix
    fseek(fid,pos.npix,'bof');
    if datastruct
        if make_full_fmt    % for some reason, this odd looking 3 lines is faster (1 sep 2014)
            [npix,ok,mess] = read_sparse2(fid,fmt.npix,make_full_fmt);
            if ~ok, return, end
            data.npix=reshape(npix,sz);
            clear npix
        else
            [data.npix,ok,mess] = read_sparse2(fid,fmt.npix);
            if ~ok, return, end
        end
    else
        [data,ok,mess] = read_sparse2(fid,fmt.npix,varargin{:},make_full_fmt);
        if ~ok, return, end
        if numel(varargin)~=0 && make_full_fmt
            data=reshape(data,sz);
        end
    end
end

% Read urange
if read_urange
    fseek(fid,pos.urange,'bof');
    data.urange = fread(fid, [2,4], ['*',fmt.urange]);
end

% Read npix_nz
if read_npix_nz
    fseek(fid,pos.npix_nz,'bof');
    if datastruct   % only case is sqw in sparse format
        [data.npix_nz,ok,mess] = read_sparse2(fid,fmt.npix_nz);
    else
        [data,ok,mess] = read_sparse2(fid,fmt.npix_nz,varargin{:},make_full_fmt);
    end
    if ~ok, return, end
end

% Read pix_nz
if read_pix_nz
    nrows=4+(info.nfiles>1);% 4 rows if single file, 5 rows if more than one
    if numel(varargin)==0   % read whole array
        pos_start = pos.pix_nz;
        npix_read = info.npixtot_nz;
    else
        if opt.pix_nz
            range=varargin{1};
        elseif opt.pix      % read_pix_nz ensures that this also has make_full_fmt
            range=varargin{2};
        end
        pos_start = pos.pix_nz + nrows*fmt_nbytes(fmt.pix_nz)*(range(1)-1);
        npix_read = diff(range)+1;
    end
    if npix_read>0
        fseek(fid,pos_start,'bof');
        tmp = fread(fid, [nrows,npix_read], ['*',fmt.pix_nz]);
        if datastruct && ~make_full_fmt
            data.pix_nz = double(tmp);
        elseif opt.pix_nz
            data = double(tmp);
        else    % used to create full format pix array, either in sqw or buffer output, or pix output
            pix_nz = double(tmp);
        end
        clear tmp
    else
        if datastruct && ~make_full_fmt
            data.pix = zeros(nrows,0);
        elseif opt.pix_nz
            data = zeros(nrows,0);
        else
            pix_nz = zeros(nrows,0);
        end
    end
end

% Read pix
if read_pix
    if numel(varargin)==0   % read whole array
        pos_start = pos.pix;
        npix_read = info.npixtot;
    else
        pos_start = pos.pix + fmt_nbytes(fmt.pix)*(varargin{1}(1)-1);
        npix_read = diff(varargin{1})+1;
    end
    if npix_read>0
        fseek(fid,pos_start,'bof');
        tmp = fread(fid, npix_read, ['*',fmt.pix]);
        if make_full_fmt
            if datastruct
                data.pix = make_pix_full(tmp,pix_nz,ne,ndet);
            else
                data = make_pix_full(tmp,pix_nz,info.ne,info.ndet);
            end
        else
            if datastruct
                data.pix = double(tmp);
            else
                data = double(tmp);
            end
        end
        clear tmp
    else
        if make_full_fmt
            if datastruct
                data.pix = zeros(9,0);
            else
                data = zeros(9,0);
            end
        else
            if datastruct
                data.pix = zeros(0,1);
            else
                data = zeros(0,1);
            end
        end
    end
end

%==================================================================================================
function pix_full = make_pix_full(pix,pix_nz,ne,ndet)
