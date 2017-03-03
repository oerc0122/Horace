function [res,varargout] = get_sqw (obj,varargin)
% Load an dnd file from disk and return dnd object.
%
% The same as  get_dnd function providing unified interface for all sqw/dnd
% files loaders
%
%   >> dnd_object = obj.get_sqw()
%   >> dnd_object = obj.get_sqw('-verbatim')
%
% Input:
% --------
%   infile      File name, or file identifier of open file, from which to read data
%
%   opt         [optional] Determines which fields to read:
%                                    (If the file was written from a structure of type 'b' or 'b+', then
%                                    urange does not exist, and the output field will not be created)
%                   '-verbatim'    Same as '-h' except that the file name as stored in the main_header and
%                                  data sections are returned as stored, not constructed from the
%                                  value of fopen(fid). This is needed in some applications where
%                                  data is written back to the file with a few altered fields.
%               Default: read all fields of whatever is the sqw data type contained in the file ('b','b+','a','a-')
%
%
% Output:
% --------
%  fully formed sqw object
%
%   data        Output data structure actually read from the file. Will be one of:
%                   type 'h'    fields: filename,...,uoffset,...,dax[,urange]
%                   type 'b'    fields: filename,...,uoffset,...,dax,s,e
%                   type 'b+'   fields: filename,...,uoffset,...,dax,s,e,npix
%                   type 'a-'   fields: filename,...,uoffset,...,dax,s,e,npix,urange
%                   type 'a'    fields: filename,...,uoffset,...,dax,s,e,npix,urange,pix
%               The final field urange is present for type 'h' if the header information was read from an sqw-type file.
%
% Original author: T.G.Perring
%
% $Revision: 1394 $ ($Date: 2016-12-21 20:32:42 +0000 (Wed, 21 Dec 2016) $)
%
if nargout > 1
    [res,varargout] = obj.get_dnd(varargin{:});
else
    res = obj.get_dnd(varargin{:});
end

