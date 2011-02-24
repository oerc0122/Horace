function [figureHandle, axesHandle, plotHandle] = dp(win,varargin)
% Plot errorbars and markers for 1d dataset.
%
%   >> dp(win)
%   >> dp(win,xlo,xhi)
%   >> dp(win,xlo,xhi,ylo,yhi)
% Or:
%   >> dp(win,'xlim',[xlo,xhi],'ylim',[ylo,yhi],'Color','red')
% etc.
%
% See help for libisis/dp for more details of more options

% R.A. Ewings 14/10/2008

[figureHandle_, axesHandle_, plotHandle_] = dp(sqw(win),varargin{:});

% Output only if requested
if nargout>=1, figureHandle=figureHandle_; end
if nargout>=2, axesHandle=axesHandle_; end
if nargout>=3, plotHandle=plotHandle_; end
