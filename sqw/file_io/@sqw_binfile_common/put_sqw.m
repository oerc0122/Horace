function    obj = put_sqw(obj,varargin)
% Save sqw data into new binary file or fully overwrite an existing file
%
%
% $Revision$ ($Date$)
%
%
% TODO: upgrade option 
%
% store header, which describes file as sqw file
obj.put_app_header();
%
obj.put_main_header();
%
obj.put_headers();
%
obj.put_det_info();
%
% write dnd image methadata
obj.put_dnd_methadata();
% write dnd image data
obj.put_dnd_data();
%
obj.put_pix(varargin{:});

%
fseek(obj.file_id_,0,'eof');
obj.real_eof_pos_ = ftell(obj.file_id_);
