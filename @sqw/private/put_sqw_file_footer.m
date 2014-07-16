function [mess, position] = put_sqw_file_footer (fid, position_info_location, data_type)
% Write final entry to sqw file: location of position information in the file and data_type
%
%   >> [mess, position] = put_sqw_file_footer (fid, position_info_location, data_type)
%
% Input:
% ------
%   fid                     File identifier of output file (opened for binary writing)
%   position_info_location  Position of the position information block
%   data_type               Type of sqw data contained in the file:
%                               type 'b'    fields: filename,...,uoffset,...,dax,s,e
%                               type 'b+'   fields: filename,...,uoffset,...,dax,s,e,npix
%                               type 'a'    fields: filename,...,uoffset,...,dax,s,e,npix,urange,pix
%                               type 'a-'   fields: filename,...,uoffset,...,dax,s,e,npix,urange
%                               type 'sp-'  fields: filename,...,dax,s,e,npix,urange (sparse format)
%                               type 'sp'   fields: filename,...,dax,s,e,npix,urange,pix,npix_nz,ipix_nz,pix_nz (sparse format)
%
% Output:
% -------
%   mess                    Message if there was a problem writing; otherwise mess=''
%   position                Position of the file footer in the file


% Original author: T.G.Perring
%
% $Revision$ ($Date$)

mess = '';
position = ftell(fid);

try
    % Position of position information block
    fwrite(fid,position_info_location,'float64');
    
    % Data type (last entry)
    % (Note that the length of the data type is written last, so that it can be
    % discovered by going to the end of the file and then backing up 4 bytes)
    n=length(data_type);
    fwrite(fid,data_type,'char*1');
    fwrite(fid,n,'int32');              % write length of data_type
    
catch
    mess='Unable to write footer block to file';
end
