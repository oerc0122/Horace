function [mc_contributions,ok,mess] = mc_contributions_parse (varargin)
% Return structure with list of which components will contribute to the resolution
%
% Return default: (also use this to get a structure with all the possible
% component names)
%   >> [mc_contributions,ok,mess] = mc_contributions_parse
%
%   >> [mc_contributions,ok,mess] = mc_contributions_parse ('all')    % all contributions
%   >> [mc_contributions,ok,mess] = mc_contributions_parse ('none')   % no contributions
%
% All components included except...
%   >> [mc_contributions,ok,mess] = mc_contributions_parse ('nomoderator')
%   >> [mc_contributions,ok,mess] = mc_contributions_parse ('nomoderator','nochopper')
%
% Only include...
%   >> [mc_contributions,ok,mess] = mc_contributions_parse ('chopper','sample')
%
% Modify an existing Monte Carlo contriburions structure:
%   >> [mc_contributions,ok,mess] = mc_contributions_parse (mc_contrib_in,'moderator','nochopper')


% For use in other routines:
%   >> [mc_contributions,ok,mess] = mc_contributions_parse (mc_contrib_in)
% This will not throw an error, but return a status flag and error message.


contr={'moderator','aperture','chopper','sample','detector_depth','detector_area','energy_bin'}';

mc_contributions_all=cell2struct(num2cell(true(numel(contr),1)),contr);
mc_contributions_none=cell2struct(num2cell(false(numel(contr),1)),contr);

% Catch case of no input arguments, 'all' or 'none'
if numel(varargin)==0
    mc_contributions=mc_contributions_all; ok=true; mess=''; return
elseif numel(varargin)==1 && isempty(varargin{1})
    mc_contributions=mc_contributions_all; ok=true; mess=''; return
elseif numel(varargin)==1 && is_string(varargin{1}) && strcmpi(varargin{1},'all')
    mc_contributions=mc_contributions_all; ok=true; mess=''; return
elseif numel(varargin)==1 && is_string(varargin{1}) && strcmpi(varargin{1},'none')
    mc_contributions=mc_contributions_none; ok=true; mess=''; return
end

% Parse parameters:
[args,options,present] = parse_arguments(varargin,mc_contributions_none,contr);   % use mc_none to give dummy defaults;

if numel(args)==1 && isstruct(args{1}) && isequal(contr,fieldnames(args{1}))
    if isscalar(args{1})
        [ok,mc_in]=check_ok(args{1});
        if ok
            mc_contributions=change_contributions(mc_in,options,present);
            mess='';
        else
            mc_contributions=[]; mess='Values of contributions to Monte Carlo calculation must be logical true or false';
            if nargout<=1, error(mess), end
        end
    else
        mc_contributions=[]; ok=false; mess='Structure with list of contributions to Monte Carlo calculation must be a scalar structure';
        if nargout<=1, error(mess), end
    end
    
elseif numel(args)==0
    if all_present(options,present,true)
        mc_contributions=change_contributions(mc_contributions_none,options,present);
        ok=true; mess='';
    elseif all_present(options,present,false)
        mc_contributions=change_contributions(mc_contributions_all,options,present);
        ok=true; mess='';
    else
        mc_contributions=[]; ok=false; mess='Give the components that are present only (e.g. ''moderator'') or absent only (e.g. ''nomoderator'')';
        if nargout<=1, error(mess), end
    end
    
else
    mc_contributions=[]; ok=false;
    mess='Check Monte Carlo contributions argument is a structure with correct field names (type >> tobyfit_mc_contributions for a list)';
    if nargout<=1, error(mess), end
end


%--------------------------------------------------------------------------------------------------
function [ok,mc]=check_ok(mc_in)
% Check fields are all scalar logical or 0/1; make logical
ok=true;
mc=mc_in;
nam=fieldnames(mc);
for i=1:numel(nam)
    if islognumscalar(mc.(nam{i}))
        if ~islogical(mc.(nam{i}))
            mc.(nam{i})=logical(mc.(nam{i}));
        end
    else
        ok=false;
        return
    end
end

%--------------------------------------------------------------------------------------------------
function mc=change_contributions(mc_in,options,present)
% Change the logical status of contributions according to value if keyword was present
mc=mc_in;
nam=fieldnames(mc);
for i=1:numel(nam)
    if present.(nam{i})
        mc.(nam{i})=options.(nam{i});
    end
end

%--------------------------------------------------------------------------------------------------
function status=all_present(options,present,value)
% Determine if all present keywords had a particular value
status=true;
nam=fieldnames(options);
for i=1:numel(nam)
    if present.(nam{i}) && options.(nam{i})~=value
        status=false;
        break
    end
end
