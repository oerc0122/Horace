function write_grid_data (fid, data)
% Writes orthogonal grid data to a binary file
%
% Input:
% ------
%   fid     File pointer to (already open) binary file
%
%   data    Data structure with the following fields:
%
%   data.p1    Column vector of bin boundaries along first plot axis
%   data.p2    Column vector of bin boundaries along second plot axis
%     :       (for as many plot axes as given by length of data.pax)
%   data.s     Cumulative signal.  [size(data.s)=(length(data.p1)-1, length(data.p2)-1, ...)]
%   data.e     Cumulative variance [size(data.e)=(length(data.p1)-1, length(data.p2)-1, ...)]
%   data.n     Number of contributing pixels [size(data.n)=(length(data.p1)-1, length(data.p2)-1, ...)]
%             If 1D, 2D, 3D, data.n is written as a double; if 4D, data.n is written as int16


% Original author: J. van Duijn
%
% $Revision$ ($Date$)
%
% Horace v0.1   J. van Duijn, T.G.Perring

ndim = length(size(data.s));

% Write grid data
if ndim==4, % 4D grid
    np1=length(data.p1); % length of vector data.p1
    fwrite(fid,np1,'int32');
    np2=length(data.p2); % length of vector data.p2
    fwrite(fid,np2,'int32');
    np3=length(data.p3); % length of vector data.p3
    fwrite(fid,np3,'int32');
    np4=length(data.p4); % length of vector data.p4
    fwrite(fid,np4,'int32');
    fwrite(fid,data.p1,'float32');
    fwrite(fid,data.p2,'float32');
    fwrite(fid,data.p3,'float32');
    fwrite(fid,data.p4,'float32');
elseif ndim==3, %3D grid
    np1=length(data.p1); % length of vector data.p1
    fwrite(fid,np1,'int32');
    np2=length(data.p2); % length of vector data.p2
    fwrite(fid,np2,'int32');
    np3=length(data.p3); % length of vector data.p3
    fwrite(fid,np3,'int32');
    fwrite(fid,data.p1,'float32');
    fwrite(fid,data.p2,'float32');
    fwrite(fid,data.p3,'float32');
elseif ndim==2, %2D grid
    np1=length(data.p1); % length of vector data.p1
    fwrite(fid,np1,'int32');
    np2=length(data.p2); % length of vector data.p2
    fwrite(fid,np2,'int32');
    fwrite(fid,data.p1,'float32');
    fwrite(fid,data.p2,'float32');
elseif ndim==1, %1D grid
    np1=length(data.p1); % length of vector data.p1
    fwrite(fid,np1,'int32');
    fwrite(fid,data.p1,'float32');
else
    error ('ERROR: Check dimension of dataset');
end

% Write data
fwrite(fid,data.s,'float32');
fwrite(fid,data.e,'float32');
if length(data.pax)==4,
    fwrite(fid,data.n,'int16');
else
    fwrite(fid,data.n,'double');
end
