function [ok, mess] = checkfields (d)
% Check fields for sigvar object
%
%   >> [ok, mess] = checkfields (d)
%
%   ok      ok=true if valid, =false if not
%   mess    Message if not a valid sqw object, empty string if is valid.

% Original author: T.G.Perring
%
% $Revision: 101 $ ($Date: 2007-01-25 09:10:34 +0000 (Thu, 25 Jan 2007) $)

fields = {'s';'e';'title'};  % column

ok=false;
mess='';
if isequal(fieldnames(d),fields)
    if ~(isnumeric(d.s) && isnumeric(d.e) && (isequal(size(d.s),size(d.e))||isequal(size(d.e),[0,0])))
        mess='Numeric array sizes for fields ''y'' and ''e'' incompatible';
        return
    end
    if any(d.e<0)
        mess='One or more elements of field ''e'' <0';
        return
    end
else
    mess='fields inconsistent with class type';
    return
end

% OK if got to here
ok=true;
