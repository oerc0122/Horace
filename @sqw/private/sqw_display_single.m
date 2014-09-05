function sqw_display_single (din,type,npixtot)
% Display useful information from an sqw object
%
%   >> sqw_display_single (din)
%   >> sqw_display_single (din,type,npixtot)
%
% Input:
% ------
%   din             Structure from sqw object (sqw-type or dnd-type)
%   type            [Optional] data type: 'sqw' or 'dnd'
%   npixtot         [Optional] total number of pixels if sqw type
%                  
%   If the optional parameters are given, then only the header information
%   part of data needs to be passed, namely the fields:
%      uoffset,u_to_rlu,ulen,ulabel,iax,iint,pax,p,dax[,urange]
%  (urange is only present if sqw type object)
%
%   If the optional parameters are not given, then the whole data structure
%   needs to be given, and npixtot and type are computed from the structure.
%
%   If an optional parameter is given but is empty, then the missing value for that
%   parameter is computed from the data structure.
%
% NOTE: uses sprintf to get fixed formatting of numbers (num2str strips trailing blanks)


% Original author: T.G.Perring
%
% $Revision$ ($Date$)


% Determine if displaying dnd-type or sqw-type sqw object
if ~exist('type','var') || isempty(type)
    type = data_structure_type_name(din);
end

if strcmpi(type,'sqw')
    sqw_type=true;
    nfiles = din.main_header.nfiles;
    if ~exist('npixtot','var') || isempty(npixtot)
        npixtot = sum(din.data.npix(:));
    end
else
    sqw_type=false;
end

% Display summary information
[ndim,sz] = data_dims(din.data);
disp(' ')
disp([' ',num2str(ndim),'-dimensional object:'])
disp(' -------------------------')


if ~isempty(din.data.filename)
    filename=fullfile(din.data.filepath,din.data.filename);
    disp([' Original datafile: ',filename])
else
    disp([' Original datafile: ','<none>'])
end


if ~isempty(din.data.title)
    disp(['             Title: ',din.data.title])
else
    disp(['             Title: ','<none>'])
end


disp(' ')
disp( ' Lattice parameters (Angstroms and degrees):')
disp(['         a=',sprintf('%-11.4g',din.data.alatt(1)),    '    b=',sprintf('%-11.4g',din.data.alatt(2)),   '     c=',sprintf('%-11.4g',din.data.alatt(3))])
disp(['     alpha=',sprintf('%-11.4g',din.data.angdeg(1)),' beta=',sprintf('%-11.4g',din.data.angdeg(2)),' gamma=',sprintf('%-11.4g',din.data.angdeg(3))])
disp(' ')


if sqw_type
    disp( ' Extent of data: ')
    disp(['     Number of spe files: ',num2str(nfiles)])
    disp(['        Number of pixels: ',num2str(npixtot)])
    disp(' ')
end

[title_main, title_pax, title_iax, display_pax, display_iax] = data_plot_titles (din.data);
if ndim~=0
    npchar = '[';
    for i=1:ndim
        npchar = [npchar,num2str(sz(din.data.dax(i))),'x'];   % size along each of the display axes
    end
    npchar(end)=']';
    disp([' Size of ',num2str(ndim),'-dimensional dataset: ',npchar])
end
if ndim~=0
    disp( '     Plot axes:')
    for i=1:ndim
        disp(['         ',display_pax{i}])
    end
    disp(' ')
end
if ndim~=4
    disp( '     Integration axes:')
    for i=1:4-ndim
        disp(['         ',display_iax{i}])
    end
    disp(' ')
end

% Print warning if no data in the cut, if full cut has been passed
if npixtot < 0.5   % in case so huge that can no longer hold integer with full precision
    disp(' WARNING: The dataset contains no counts')
    disp(' ')
end
