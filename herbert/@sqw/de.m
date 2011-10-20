function [figureHandle, axesHandle, plotHandle] = de(win,varargin)
% Plot errorbars for 1d dataset.
%
%   >> de(win)
%   >> de(win,xlo,xhi)
%   >> de(win,xlo,xhi,ylo,yhi)
% Or:
%   >> de(win,'xlim',[xlo,xhi],'ylim',[ylo,yhi],'Color','red')
% etc.
%
% See help for libisis/de for more details of more options

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

name_oned =  get_global_var('horace_plot','name_oned');
[figureHandle_, axesHandle_, plotHandle_] = de(IX_dataset_1d(win), 'name', name_oned, varargin{:});

% Output only if requested
if nargout>=1, figureHandle=figureHandle_; end
if nargout>=2, axesHandle=axesHandle_; end
if nargout>=3, plotHandle=plotHandle_; end