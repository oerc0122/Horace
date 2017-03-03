function    obj = put_sqw(obj,varargin)
% Save dnd data into new binary file or fully overwrite an existing file
%
% store header, which describes file as dnd file
%
%
% $Revision: 1335 $ ($Date: 2016-11-15 13:18:52 +0000 (Tue, 15 Nov 2016) $)
%
obj = obj.put_dnd(varargin{:});
