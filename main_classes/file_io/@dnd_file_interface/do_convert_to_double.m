function  val = do_convert_to_double(val)
% convert all numerical types of the structure into double
%
%
% $Revision: 1310 $ ($Date: 2016-11-01 09:41:28 +0000 (Tue, 01 Nov 2016) $)
%


if iscell(val)
    for i=1:numel(val)
        val{i} = dnd_file_interface.do_convert_to_double(val{i});
    end
elseif isstruct(val)
    fn = fieldnames(val);
    for i=1:numel(fn)
        val.(fn{i}) = dnd_file_interface.do_convert_to_double(val.(fn{i}));
    end
elseif isnumeric(val)
    val = double(val);
end

