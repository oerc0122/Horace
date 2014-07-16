function [mess, position, npixtot] = put_sqw_data_npix_and_pix_to_file (outfile, npix, pix)
% Write npix and pix to a file with same format as put_sqw_data
%
%   >> [mess, position] = put_sqw_data_npix_and_pix_to_file (outfile, npix, pix)
%
% Input:
% ------
%   outfile     File name, or file identifier of open file, to which to append data
%   npix        Array containing the number of pixels in each bin
%   pix         Array containing data for each pixel:
%              Each column of the of the array (which has size [9,npixtot] where npixtot=sum(npix)) contains:
%                   u1      -|
%                   u2       |  Coordinates of pixel in the projection axes of the original sqw file(s)
%                   u3       |
%                   u4      -|
%                   irun        Run index in the header block from which pixel came
%                   idet        Detector group number in the detector listing for the pixel
%                   ien         Energy bin number for the pixel in the array in the (irun)th header
%                   signal      Signal array
%                   err         Error array (variance i.e. error bar squared)
%
% Output:
% -------
%   mess        Message if there was a problem writing; otherwise mess=''
%   position    Position (in bytes from start of file) of large fields:
%                   position.npix   position of array npix (in bytes) from beginning of file
%                   position.pix    position of array pix (in bytes) from beginning of file
%   npixtot     Total number of pixels written to file

% T.G.Perring 10 August 2007


mess = [];
position = [];

% Open output file
if isnumeric(outfile)
    fid = outfile;   % copy fid
    if isempty(fopen(fid))
        mess = 'No open file with given file identifier';
        return
    end
    close_file = false;
else
    fid=fopen(outfile,'A');    % no automatic flushing: can be faster
    if fid<0
        mess = ['Unable to open file ',outfile];
        return
    end
    close_file = true;
end

% Write npix and pix in the same format as put_sqw_data
position.npix=ftell(fid);
fwrite(fid,int64(npix),'int64');    % make int64 so that can deal with huge numbers of pixels

position.pix=ftell(fid);
npixtot = size(pix,2);
% Try writing large array of pixel information a block at a time - seems to speed up the write slightly
% Need a flag to indicate if pixels are written or not, as cannot rely just on npixtot - we really
% could have no pixels because none contributed to the given data range.
block_size=get(hor_config,'mem_chunk_size');    % size of buffer to hold pixel information
% block_size=1000000;
if npixtot<=block_size
    fwrite(fid,single(pix),'float32');
else
    for ipix=1:block_size:npixtot
        istart = ipix;
        iend   = min(ipix+block_size-1,npixtot);
        fwrite(fid,single(pix(:,istart:iend)),'float32');
    end
end

% Close file if necessary
if close_file
    fclose(fid);
end
