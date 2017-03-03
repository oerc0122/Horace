function    obj = put_sqw(obj,varargin)
% Save sqw data into new binary file or fully overwrite an existing file
%
%
% $Revision: 1380 $ ($Date: 2016-12-13 19:29:24 +0000 (Tue, 13 Dec 2016) $)
%
%
%
[ok,mess,update,nopix,argi]=parse_char_options(varargin,{'-update','-nopix'});
if ~ok
    error('SQW_FILE_IO:invalid_artgument',...
        ['DND_BINFILE_COMMON::put_sqw Error: ',mess]);
end
%
if ~isempty(argi)
    input = argi{1};
    if isa(input,'sqw')
        obj.sqw_holder_ = input;
    else
        type = class(input);
        error('SQW_FILE_IO:invalid_artgument',...
            'put_sqw: this function can accept only sqw-type object, but got: %s type',type)
    end
    if numel(argi) > 1
        argi = argi{2:end};
    else
        argi = {};
    end
end
%
if update
    if ~obj.upgrade_mode % set up info for upgrade mode and the mode itself
        obj.upgrade_mode = true;
    end
    %return update option to argument list
    argi{end+1} = '-update';
end
if nopix
    argi{end+1} = '-nopix';    
end



% store header, which describes file as sqw file
obj=obj.put_app_header();
%
obj=obj.put_main_header(argi{:});
%
obj=obj.put_headers(argi{:});
%
obj=obj.put_det_info(argi{:});
%
% write dnd image methadata
obj=obj.put_dnd_metadata(argi{:});
% write dnd image data
obj=obj.put_dnd_data(argi{:});
%
obj=obj.put_pix(argi{:});

%
if ~update
    fseek(obj.file_id_,0,'eof');
    obj.real_eof_pos_ = ftell(obj.file_id_);
end
