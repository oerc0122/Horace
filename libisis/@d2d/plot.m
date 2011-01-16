function [figureHandle, axesHandle, plotHandle] = plot(win,varargin)
% Plot d2d object
%
%   >> plot(win)
%
% Equivalent to:
%   >> da(win)
%

% R.A. Ewings 9/1/2009

[figureHandle_, axesHandle_, plotHandle_] = plot(sqw(win),varargin{:});

% Output only if requested
if nargout>=1, figureHandle=figureHandle_; end
if nargout>=2, axesHandle=axesHandle_; end
if nargout>=3, plotHandle=plotHandle_; end
