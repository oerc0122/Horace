function [figureHandle, axesHandle, plotHandle] = plot(win, varargin)
% Plots d3d object using sliceomatic
%
% Syntax:
%   >> plot (win)
%   >> plot (win, 'isonormals', true)     % to enable isonormals
%
% Equivalent to
%   >> sliceomatic (win,...)
%
%
% NOTES:
%
% - Ensure that the slice color plotting is in 'texture' mode -
%      On the 'AllSlices' menu click 'Color Texture'. No indication will
%      be made on this menu to show that it has been selected, but you can
%      see the result if you right-click on an arrow indicating a slice on
%      the graphics window.
%
% - To set the default for future Sliceomatic sessions - 
%      On the 'Object_Defaults' menu select 'Slice Color Texture'

[figureHandle, axesHandle, plotHandle] = sliceomatic(sqw(win),varargin{:});