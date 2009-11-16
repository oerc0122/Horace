function [figureHandle_, axesHandle_, plotHandle_] = pd(win,varargin)
% Overplot errorbars, markers and lines for a 1d dataset on an existing figure.
%
% Optional inputs:
%   >> pd(win);
%   >> pd(win,'color','red');
%
% See help for libisis\pd for more details of further options

% R.A. Ewings 14/10/2008

for i=1:numel(win)
    if dimensions(win(i))~=1
        if numel(win)==1
            error('sqw object is not one dimensional')
        else
            error('Not all elements in the array of sqw objects are one dimensional')
        end
    end
end

ixg_st_horace =  ixf_global_var('Horace','get','IXG_ST_HORACE');
[figureHandle_, axesHandle_, plotHandle_] = pd(IXTdataset_1d(win), 'name', ixg_st_horace.oned_name, 'tag', ixg_st_horace.tag, varargin{:});
