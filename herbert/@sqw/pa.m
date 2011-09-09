function [figureHandle, axesHandle, plotHandle] = pa(win,varargin)
% Area plot for 2D dataset
%
%   >> pa(win)
%   >> pa(win,'colormap','bone')
% etc.
%
% See help for libisis/pa for more details of other options

% R.A. Ewings 14/10/2008

for i=1:numel(win)
    if dimensions(win(i))~=2
        if numel(win)==1
            error('sqw object is not two dimensional')
        else
            error('Not all elements in the array of sqw objects are two dimensional')
        end
    end
end

name_area =  get_global_var('horace_plot','name_area');
[figureHandle_, axesHandle_, plotHandle_] = pa(IX_dataset_2d(win), 'name', name_area, varargin{:});

pax = win(1).data.pax;
dax = win(1).data.dax;                 % permutation of projection axes to give display axes
ulen = win(1).data.ulen(pax(dax));     % unit length in order of the display axes
energy_axis = 4;    % by convention in Horace
if pax(dax(1))~=energy_axis && pax(dax(2))~=energy_axis    % both plot axes are Q axes
    aspect(ulen(1), ulen(2));
end

colorslider;

% Output only if requested
if nargout>=1, figureHandle=figureHandle_; end
if nargout>=2, axesHandle=axesHandle_; end
if nargout>=3, plotHandle=plotHandle_; end
