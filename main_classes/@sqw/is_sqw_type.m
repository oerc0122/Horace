function sqw_type = is_sqw_type(w)
% Determine if sqw type object or dnd type object
%
%   >> sqw_type = is_sqw_type(w)
%
% Input:
% ------
%   w           sqw-type or dnd-type sqw object or array of objects
%
% Output:
% -------
%   sqw_type    =true or =false (array)

% Original author: T.G.Perring
%
% $Revision: 1030 $ ($Date: 2015-07-17 20:05:30 +0100 (Fri, 17 Jul 2015) $)

sqw_type=false(size(w));
for i=1:numel(w)
    if ~isempty(w(i).data.pix)
        sqw_type(i) = true;
    else
        sqw_type(i) = false;
    end
end
