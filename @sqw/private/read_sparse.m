function [v,ok,mess]=read_sparse(fid,skip)
% Read sparse column vector of doubles written with write_sparse
%
%   >> [v,ok,mess] = read_sparse(fid,skip)
%
% Input:
% ------
%   fid     File identifier of already open file for binary output
%   skip    [Optional] If true, move to the end of the data without reading
%           Default: read the data
%
% Output:
% -------
%   v       Column vector (sparse format)

% Make sure any changes here are synchronised with the corresponding read_sparse


% Check arguments
if nargin==2
    if ~islogical(skip), skip=logical(skip); end
elseif nargin==1
    skip=false;
end

% Read data sizes and type
n = fread(fid,3,'float64');
nel=n(1);
nval=n(2);
nbits=n(3);

% Read or skip over data
if ~skip
    % Read indicies
    if nel>=intmax('int32')
        ind = fread(fid,[nval,1],'*int64');
    else
        ind = fread(fid,[nval,1],'*int32');
    end
    
    % Read values
    if nbits==32
        val = fread(fid,[nval,1],'*float32');
    elseif nbits==64
        val = fread(fid,[nval,1],'*float64');
    elseif nbits==-32
        val = fread(fid,[nval,1],'*int32');
    else
        error('Unrecognised type')
    end
    
    % Construct sparse column vector
    v=sparse(double(ind),1,double(val),nel,1);
else
    % Skip over the data, if requested, but position at end of the data
    if nel>=intmax('int32')
        nbytes=8*nval;
    else
        nbytes=4*nval;
    end
    if nbits==32
        nbytes=nbytes+4*nval;
    elseif nbits==64
        nbytes=nbytes+8*nval;
    elseif nbits==32
        nbytes=nbytes+4*nval;
    else
        error('Unrecognised type')
    end
    fseek(fid,nbytes,'cof');  % skip field pix
    v=[];
    ok=true;
    mess='';
end
