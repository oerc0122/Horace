function [mess, data, position, npixtot, data_type] = get_sqw_data (fid, varargin)
% Read the data block from an sqw file. The file pointer is left at the end of the data block.
%
%   >> [mess, data, position, npixtot, data_type] = get_sqw_data(fid, file_format, data_type_in)
%   >> [mess, data, position, npixtot, data_type] = get_sqw_data(fid, opt, file_format, data_type_in)
%   >> [mess, data, position, npixtot, data_type] = get_sqw_data(fid, npix_lo, npix_hi, file_format, data_type_in)
%
%
% Input:
% ------
%   fid         File pointer to (already open) binary file
%   opt         [optional] Determines which fields to read
%                   '-h'     header-type information only: fields read:
%                               filename, filepath, title, alatt, angdeg,...
%                                   uoffset,u_to_rlu,ulen,ulabel,iax,iint,pax,p,dax[,urange]
%                              (If file was written from a structure of type 'b' or 'b+', then
%                               urange does not exist, and the output field will not be created)
%                   '-hverbatim'    Same as '-h' except that the file name as stored in the main_header and
%                                  data sections are returned as stored, not constructed from the
%                                  value of fopen(fid). This is needed in some applications where
%                                  data is written back to the file with a few altered fields.
%                   '-nopix' Pixel information not read (only meaningful for sqw data type 'a')
%
%               Default: read all fields of whatever is the sqw data type contained in the file ('b','b+','a','a-')
%
%   npix_lo     -|- [optional] pixel number range to be read from the file (only applies to type 'a')
%   npix_hi     -|
%
%   file_format     Format of file (character string)
%                       Current formats:  '-v2', '-v3'
%                       Obsolete formats: '-prototype'
%
%   data_type_in    If file_format is '-v3', this must be the known data block type in the file: can only be one of:
%                       'b'    fields: filename,...,dax,s,e
%                       'b+'   fields: filename,...,dax,s,e,npix
%                       'a'    fields: filename,...,dax,s,e,npix,urange,pix
%                       'a-'   fields: filename,...,dax,s,e,npix,urange
%                       'sp-'  fields: filename,...,dax,s,e,npix,urange (sparse format)
%                       'sp'   fields: filename,...,dax,s,e,npix,urange,pix,npix_nz,ipix_nz,pix_nz (sparse format)
%
%                   If file_format is '-v2' and '-prototype', the contents of data type is auto-detected and
%                  the value of data_type_in is ignored. For clarity, you can set data_type_in to the empty string:
%                       ''     auto-detect the fields in the file (file format '-v2' and '-prototype' only)
%
%
% Output:
% -------
%   mess        Error message; blank if no errors, non-blank otherwise
%
%   data        Output data structure actually read from the file. Will be one of:
%                   type 'h'    fields: fields: uoffset,...,dax[,urange]
%                   type 'b'    fields: filename,...,dax,s,e
%                   type 'b+'   fields: filename,...,dax,s,e,npix
%                   type 'a'    fields: filename,...,dax,s,e,npix,urange,pix
%                   type 'a-'   fields: filename,...,dax,s,e,npix,urange
%                   type 'sp-'  fields: filename,...,dax,s,e,npix,urange (sparse format)
%                   type 'sp'   fields: filename,...,dax,s,e,npix,urange,pix,npix_nz,ipix_nz,pix_nz (sparse format)
%               The final field urange is present for type 'h' if the header information was read from an sqw-type file.
%
%   position    Position (in bytes from start of file) of start of data block and of large fields:
%              These field are correctly filled even if the header only has been requested, that is,
%              if input option '-h' or '-hverbatim' was given
%                   position.data   position of start of data block
%                   position.s      position of array s
%                   position.e      position of array e
%                   position.npix   position of array npix (=[] if npix not present)
%                   position.urange position of array urange (=[] if urange not present)
%                   position.npix_nz position of array npix_nz (=[] if npix_nz not present)
%                   position.ipix_nz position of array ipix_nz (=[] if ipix_nz not present)
%                   position.pix_nz  position of array pix_nz (=[] if pix_nz not present)
%                   position.pix    position of array pix (=[] if pix not present)
%
%   npixtot     Total number of pixels written in file (=[] if the pix array is not present)
%
%   data_type   Type of sqw data written in the file
%                   type 'b'    fields: filename,...,dax,s,e
%                   type 'b+'   fields: filename,...,dax,s,e,npix
%                   type 'a'    fields: filename,...,dax,s,e,npix,urange,pix
%                   type 'a-'   fields: filename,...,dax,s,e,npix,urange
%                   type 'sp-'  fields: filename,...,dax,s,e,npix,urange (sparse format)
%                   type 'sp'   fields: filename,...,dax,s,e,npix,urange,pix,npix_nz,ipix_nz,pix_nz (sparse format)
%               If file_format is '-v3', this will be the same as the input argument 'data_type_in':
%               If file_format is '-v2' or '-prototype', data_type will have been autodetected regardless
%              of the value of the input data_type_in, which is ignored (see above)
%
%
% Fields read from the file are:
% ------------------------------
%   data.filename   Name of sqw file that is being read, excluding path
%   data.filepath   Path to sqw file that is being read, including terminating file separator
%          [Note that the filename and filepath that are written to file are ignored; we fill with the
%           values corresponding to the file that is being read.]
%
%   data.title      Title of sqw data structure
%   data.alatt      Lattice parameters for data field (Ang^-1)
%   data.angdeg     Lattice angles for data field (degrees)
%   data.uoffset    Offset of origin of projection axes in r.l.u. and energy ie. [h; k; l; en] [column vector]
%   data.u_to_rlu   Matrix (4x4) of projection axes in hkle representation
%                      u(:,1) first vector - u(1:3,1) r.l.u., u(4,1) energy etc.
%   data.ulen       Length of projection axes vectors in Ang^-1 or meV [row vector]
%   data.ulabel     Labels of the projection axes [1x4 cell array of character strings]
%   data.iax        Index of integration axes into the projection axes  [row vector]
%                  Always in increasing numerical order
%                       e.g. if data is 2D, data.iax=[1,3] means summation has been performed along u1 and u3 axes
%   data.iint       Integration range along each of the integration axes. [iint(2,length(iax))]
%                       e.g. in 2D case above, is the matrix vector [u1_lo, u3_lo; u1_hi, u3_hi]
%   data.pax        Index of plot axes into the projection axes  [row vector]
%                  Always in increasing numerical order
%                       e.g. if data is 3D, data.pax=[1,2,4] means u1, u2, u4 axes are x,y,z in any plotting
%                                       2D, data.pax=[2,4]     "   u2, u4,    axes are x,y   in any plotting
%   data.p          Cell array containing bin boundaries along the plot axes [column vectors]
%                       i.e. row cell array{data.p{1}, data.p{2} ...} (for as many plot axes as given by length of data.pax)
%   data.dax        Index into data.pax of the axes for display purposes. For example we may have
%                  data.pax=[1,3,4] and data.dax=[3,1,2] This means that the first plot axis is data.pax(3)=4,
%                  the second is data.pax(1)=1, the third is data.pax(2)=3. The reason for data.dax is to allow
%                  the display axes to be permuted but without the contents of the fields p, s,..pix needing to
%                  be reordered [row vector]
%
% If standard sqw format:
%   data.s          Average signal.  [size(data.s)=(length(data.p1)-1, length(data.p2)-1, ...)]
%   data.e          Average variance [size(data.e)=(length(data.p1)-1, length(data.p2)-1, ...)]
%   data.npix       No. contributing pixels to each bin of the plot axes.
%                  [size(data.pix)=(length(data.p1)-1, length(data.p2)-1, ...)]
%   data.urange     True range of the data along each axis [urange(2,4)]
%   data.pix        Array containing data for eaxh pixel:
%                  If npixtot=sum(npix), then pix(9,npixtot) contains:
%                   u1      -|
%                   u2       |  Coordinates of pixel in the projection axes
%                   u3       |
%                   u4      -|
%                   irun        Run index in the header block from which pixel came
%                   idet        Detector group number in the detector listing for the pixel
%                   ien         Energy bin number for the pixel in the array in the (irun)th header
%                   signal      Signal array
%                   err         Error array (variance i.e. error bar squared)
%
%
% If sparse format:
%   data.s          Average signal in the bins as a sparse column vector
%   data.e          Corresponding variance in the bins as a sparse column vector
%   data.npix       Number of contributing pixels as a sparse column vector
%   data.urange     <as above>
%
%   data.pix        Index of pixels, sorted so that all the pixels in the first
%                  bin appear first, then all the pixels in the second bin etc. (column vector)
%                                   ipix0 = ie + ne*(id-1)
%                               where
%                                   ie  energy bin index
%                                   id  detector index into list of all detectors (i.e. masked and unmasked)
%                                   ne  number of energy bins
%
%   data.npix_nz    Number of pixels in each bin with pixels with non-zero counts (sparse column vector)
%   data.ipix_nz    Index of pixels into pix array with non-zero counts
%   data.pix_nz     Array with idet,ien,s,e for the pixels with non-zero signal sorted so that
%                  all the pixels in the first bin appear first, then all the pixels in the second bin etc.
%
%
% NOTES:
% ======
% Supported file Formats
% ----------------------
% The current sqw file format comes in two variants:
%   - Horace version 1 and version 2: file format '-v2'
%      (Autumn 2008 onwards). Does not contain instrument and sample fields in the header block.
%       This format is the one still written if these fields all have the 'empty' value in the sqw object.
%   - Horace version 3: file format '-v3'.
%       (November 2013 onwards.) Writes the instrument and sample fields from the header block, and
%      positions of the start of major data blocks in the sqw file. This format is written if the
%      instrument and sample fields are not 'empty'.
%
% The data structure and as saved to file for these two formats is the same. However, in '-v2'
% the end of the file indicates the end of the data block, wheras '-v3' does not go to the end of
% the file. In the latter case the type of data in the file has to be explicitly given as an
% input argument, whereas it can be deduced for '-v2'
%
% Additionally, this routine will read the prototype sqw file format (July 2007(?) - Autumn 2008).
% The data block as written to file differs from the '-v2' and '-v3' formats in a few regards:
%   - title,alatt,angdeg are not stored in the data section (these will be filled from the
%     main header when converting to the current data format).
%   - The signal and error for the bins in stored without normalisation by the number of pixels.
%     Any data stored as type 'b' is therefore uninterpretable by Horace version 1 onwards because
%     the npix information that is needed to normalise the signal and error in each bin is not available.


% Original author: T.G.Perring
%
% $Revision$ ($Date$)

% Initialise output arguments
data=[];
position = struct('data',ftell(fid),'s',[],'e',[],'npix',[],'urange',[],'npix_nz',[],'ipix_nz',[],'pix_nz',[],'pix',[]);
npixtot=[];
data_type='';

% Check format flag and data type
valid_formats={'-v3','-v2','-prototype'};
valid_types={'b','b+','a-','a','sp',''};

if nargin>=2 && ischar(varargin{end-1}) && ischar(varargin{end})
    file_format=lower(strtrim(varargin{end-1}));
    data_type_in=lower(strtrim(varargin{end}));
    data_type_in_is_sparse=strcmpi(data_type_in,'sp');
    iform=find(strcmpi(file_format,valid_formats),1);
    itype=find(strcmpi(data_type_in,valid_types),1);
    if ~isempty(iform) && ~isempty(itype)
        if strcmp(file_format,'-v3') && ~isempty(data_type_in)
            autodetect=false;
            prototype=false;
        elseif strcmp(file_format,'-v2') && ~data_type_in_is_sparse
            autodetect=true;
            prototype=false;
        elseif strcmp(file_format,'-prototype') && ~data_type_in_is_sparse
            autodetect=true;
            prototype=true;
        else
            mess='Check the validity of the combination of data format flag and data type';
            return
        end
        nargs=numel(varargin)-2;
        args=varargin(1:end-2);
    else
        mess='Check the validity of the data format flag and data type';
        return
    end
else
    mess='Check the number and type of input arguments';
    return
end

% Parse optional input arguments
header_only=false;
hverbatim=false;
nopix=false;

if nargs==1 && ischar(args{1})
    opt = args{1};
    if strcmpi(opt,'-h')
        header_only=true;
    elseif strcmpi(opt,'-hverbatim')
        header_only=true;
        hverbatim=true;
    elseif strcmpi(opt,'-nopix')
        nopix=true;
    else
        mess = 'Invalid option';
        return
    end
elseif nargs==2 && isnumeric(args{1}) && isnumeric(args{2}) && isscalar(args{1}) && isscalar(args{2})
    if ~data_type_in_is_sparse
        npix_lo=args{1};
        npix_hi=args{2};
        if npix_lo<1 || npix_hi<npix_lo
            mess = 'Pixel range must have 1 <= npix_lo <= npix_hi';
            return
        end
    else
        mess = 'Option to read a limited pixel range is not valid for sparse format sqw data';
        return
    end
elseif nargs>0
    mess = 'Check the type of input argument(s)';
    return
end


% --------------------------------------------------------------------------
% Read data
% --------------------------------------------------------------------------
% This first set of fields are required for all output options
% ------------------------------------------------------------
if ~prototype
    [n, count, ok, mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;
    [dummy_filename, count, ok, mess] = fread_catch(fid,[1,n],'*char'); if ~all(ok); return; end;
    
    [n, count, ok, mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;
    [dummy_filepath, count, ok, mess] = fread_catch(fid,[1,n],'*char'); if ~all(ok); return; end;
    
    if hverbatim
        % Read filename and path from file
        data.filename=dummy_filename;
        data.filepath=dummy_filepath;
    else
        % Get file name and path (incl. final separator)
        [path,name,ext]=fileparts(fopen(fid));
        data.filename=[name,ext];
        data.filepath=[path,filesep];
    end
    
    [n, count, ok, mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;
    [data.title, count, ok, mess] = fread_catch(fid,[1,n],'*char'); if ~all(ok); return; end;
    
    [data.alatt, count, ok, mess] = fread_catch(fid,[1,3],'float32'); if ~all(ok); return; end;
    [data.angdeg, count, ok, mess] = fread_catch(fid,[1,3],'float32'); if ~all(ok); return; end;
    
else
    % Get file name and path (incl. final separator) and put empty information in fields not in the file
    [path,name,ext]=fileparts(fopen(fid));
    data.filename=[name,ext];
    data.filepath=[path,filesep];
    
    data.title = '';
    data.alatt = zeros(1,3);
    data.angdeg = zeros(1,3);
end

[data.uoffset, count, ok, mess] = fread_catch(fid,[4,1],'float32'); if ~all(ok); return; end;
[data.u_to_rlu, count, ok, mess] = fread_catch(fid,[4,4],'float32'); if ~all(ok); return; end;
[data.ulen, count, ok, mess] = fread_catch(fid,[1,4],'float32'); if ~all(ok); return; end;

[n, count, ok, mess] = fread_catch(fid,2,'int32'); if ~all(ok); return; end;
[ulabel, count, ok, mess] = fread_catch(fid,[n(1),n(2)],'*char'); if ~all(ok); return; end;
data.ulabel=cellstr(ulabel)';

[npax, count, ok, mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;
niax=4-npax;
if niax~=0
    [data.iax, count, ok, mess] = fread_catch(fid,[1,niax],'int32'); if ~all(ok); return; end;
    [data.iint, count, ok, mess] = fread_catch(fid,[2,niax],'float32'); if ~all(ok); return; end;
else
    data.iax=zeros(1,0);    % create empty index of integration array in standard form
    data.iint=zeros(2,0);
end

if npax~=0
    [data.pax, count, ok, mess] = fread_catch(fid,[1,npax],'int32'); if ~all(ok); return; end;
    psize=zeros(1,npax);    % will contain number of bins along each dimension of plot axes
    for i=1:npax
        [np,count,ok,mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;
        [data.p{i},count,ok,mess] = fread_catch(fid,np,'float32'); if ~all(ok); return; end;
        psize(i)=np-1;
    end
    [data.dax, count, ok, mess] = fread_catch(fid,[1,npax],'int32'); if ~all(ok); return; end;
    if length(psize)==1
        psize=[psize,1];    % make size of a column vector
    end
else
    data.pax=zeros(1,0);    % create empty index of plot axes
    data.p=cell(1,0);
    data.dax=zeros(1,0);    % create empty index of plot axes
    psize=[1,1];    % to hold a scalar
end

% Read s,e... fields
% ------------------
if ~data_type_in_is_sparse
    % -----------------------------------------
    % Data_type is not 'sp' or 'sp-'
    % -----------------------------------------
    
    % Read the signal and error data if required
    % ------------------------------------------
    position.s=ftell(fid);
    if ~header_only
        [tmp,count,ok,mess] = fread_catch(fid,prod(psize),'*float32'); if ~all(ok); return; end;
        data.s = reshape(double(tmp),psize);
        clear tmp
    else
        status=fseek(fid,4*(prod(psize)),'cof');  % skip field s
    end
    
    position.e=ftell(fid);
    if ~header_only
        [tmp,count,ok,mess] = fread_catch(fid,prod(psize),'*float32'); if ~all(ok); return; end;
        data.e = reshape(double(tmp),psize);
        clear tmp
    else
        status=fseek(fid,4*(prod(psize)),'cof');  % skip field e
    end
    
    % Read npix, urange, pix according to options and file contents
    % -------------------------------------------------------------
    % All of the above fields will be present in a valid sqw file. The following need not exist, but to be a valid sqw file,
    % for any one field to be present all earlier fields must have been written.
    
    % Determine if type 'b' or there are more fields in the data block
    if strcmp(data_type_in,'b') || (autodetect && fnothingleft(fid))    % reached end of file - can only be because has type 'b'
        data_type='b';
        if prototype && ~header_only
            mess = 'File does not contain number of pixels for each bin - unable to convert old format data';
            return
        end
        return
    else
        position.npix=ftell(fid);
        if ~header_only
            [tmp,count,ok,mess] = fread_catch(fid,prod(psize),'*int64'); if ~all(ok); return; end;
            data.npix = reshape(double(tmp),psize);
            clear tmp
        else
            status=fseek(fid,8*(prod(psize)),'cof');  % skip field npix
        end
    end
    
    % Determine if type 'b+' or there are more fields in the data block
    if strcmp(data_type_in,'b+') || (autodetect && fnothingleft(fid))    % reached end of file - can only be because has type 'b+'
        data_type='b+';
        if prototype && ~header_only
            [data.s,data.e]=convert_signal_error(data.s,data.e,data.npix);
        end
        return
    else
        position.urange=ftell(fid);
        [data.urange,count,ok,mess] = fread_catch(fid,[2,4],'float32'); if ~all(ok); return; end;
    end
    
    % Determine if type 'a-' or there are more fields in the data block
    if strcmp(data_type_in,'a-') || (autodetect && fnothingleft(fid))    % reached end of file - can only be because has type 'a-'
        data_type='a-';
        if prototype && ~header_only
            [data.s,data.e]=convert_signal_error(data.s,data.e,data.npix);
        end
        return
    else
        [dummy,count,ok,mess] = fread_catch(fid,1,'int32'); if ~all(ok); return; end;   % redundant field
        [npixtot,count,ok,mess] = fread_catch(fid,1,'int64'); if ~all(ok); return; end;
        position.pix=ftell(fid);
        if ~header_only && ~nopix
            if ~exist('npix_lo','var')
                if npixtot~=0
                    [tmp,count,ok,mess] = fread_catch(fid,[9,npixtot],'*float32'); if ~all(ok); return; end;
                    data.pix=double(tmp);
                    clear tmp
                else
                    data.pix=zeros(9,0);
                end
            else
                if npix_hi<=npixtot
                    status=fseek(fid,4*(9*(npix_lo-1)),'cof');
                    [tmp,count,ok,mess] = fread_catch(fid,[9,npix_hi-npix_lo+1],'float32'); if ~all(ok); return; end;
                    data.pix=double(tmp);
                    clear tmp
                else
                    mess=['Selected pixel range must lie inside or on the boundaries of 1 - ',num2str(npixtot)];
                    return
                end
            end
        else
            status=fseek(fid,4*(9*npixtot),'cof');  % skip field pix
        end
        data_type='a';
        if prototype && ~header_only
            [data.s,data.e]=convert_signal_error(data.s,data.e,data.npix);
        end
        return
    end
    
else
    % -----------------------------------------
    % Data_type is 'sp' or 'sp-'
    % -----------------------------------------
    
    % Read signal, variance and number of contributing pixels as sparse arrays
    position.s=ftell(fid);
    if ~header_only
        [data.s,ok,mess] = read_sparse(fid,header_only);
    else
        [tmp,ok,mess] = read_sparse(fid,header_only);
    end
    if ~all(ok); return; end;
    
    position.e=ftell(fid);
    if ~header_only
        [data.e,ok,mess] = read_sparse(fid,header_only);
    else
        [tmp,ok,mess] = read_sparse(fid,header_only);
    end
    if ~all(ok); return; end;
    
    position.npix=ftell(fid);
    if ~header_only
        [data.npix,ok,mess] = read_sparse(fid,header_only);
    else
        [tmp,ok,mess] = read_sparse(fid,header_only);
    end
    if ~all(ok); return; end;
    
    % Read urange
    position.urange=ftell(fid);
    [data.urange,count,ok,mess] = fread_catch(fid,[2,4],'float32'); if ~all(ok); return; end;
    
    % Read pixel information
    position.npix_nz=ftell(fid);
    if ~header_only
        [data.npix_nz,ok,mess] = read_sparse(fid,header_only);
    else
        [tmp,ok,mess] = read_sparse(fid,header_only);
    end
    if ~all(ok); return; end;
    
    % Read pixel information
    [npixtot_nz,count,ok,mess] = fread_catch(fid,1,'float64'); if ~all(ok); return; end;
    position.ipix_nz=ftell(fid);
    if ~header_only && ~nopix
        [tmp,count,ok,mess] = fread_catch(fid,[npixtot_nz,1],'*int32'); if ~all(ok); return; end;
        data.ipix_nz=double(tmp);
        clear tmp
    else
        status=fseek(fid,4*npixtot_nz,'cof');  % skip field
    end
    
    position.pix_nz=ftell(fid);
    if ~header_only && ~nopix
        [tmp,count,ok,mess] = fread_catch(fid,[4,npixtot_nz],'*float32'); if ~all(ok); return; end;
        data.pix_nz=double(tmp);
        clear tmp
    else
        status=fseek(fid,4*(4*npixtot_nz),'cof');  % skip field
    end
    
    [npixtot,count,ok,mess] = fread_catch(fid,1,'float64'); if ~all(ok); return; end;
    position.pix=ftell(fid);
    if ~header_only && ~nopix
        [tmp,count,ok,mess] = fread_catch(fid,[npixtot,1],'*int32'); if ~all(ok); return; end;
        data.pix=double(tmp);
        clear tmp
    else
        status=fseek(fid,4*npixtot,'cof');  % skip field
    end
    
end


%==================================================================================================
function answer=fnothingleft(fid)
% Determine if there is any more data in the file. Do this by trying to advance one byte
% Alternative is to go to end of file (fseek(fid,0,'eof') and see if location is the same.
status=fseek(fid,1,'cof');  % try to advance one byte
if status~=0;
    answer=true;
else
    answer=false;
    fseek(fid,-1,'cof');    % go back one byte
end

%==================================================================================================
function [s,e]=convert_signal_error(s,e,npix)
% Convert prototype (July 2007) format into standard format signal and error arrays
% Prototype format files have zeros for signal and variance arrays with no pixels
pixels = npix~=0;
s(pixels) = s(pixels)./npix(pixels);
e(pixels) = e(pixels)./(npix(pixels).^2);
