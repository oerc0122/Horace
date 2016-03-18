function obj = cut_transf_(obj,varargin)
% Internal construnctor, defining cut transformation
%
% $Revision: 449 $ ($Date: 2015-09-15 16:45:02 +0100 (Tue, 15 Sep 2015) $)
%
if ~(nargin==3 || nargin==5 || nargin == 1)
    error('CUT_TRANSF:invalid_argument','cut_transf construnctor accepts none, two or four argiments')
elseif nargin==3
    obj = set_range_(obj,1,varargin{1});
    obj = set_range_(obj,2,varargin{1});
    obj = set_range_(obj,3,varargin{1});
    obj = set_range_(obj,4,varargin{2});
elseif nargin==5
    obj = set_range_(obj,1,varargin{1});
    obj = set_range_(obj,2,varargin{2});
    obj = set_range_(obj,3,varargin{3});
    obj = set_range_(obj,4,varargin{4});
end

obj.transf_matrix_(1,1)=1;
obj.transf_matrix_(2,2)=1;
obj.transf_matrix_(3,3)=1;


