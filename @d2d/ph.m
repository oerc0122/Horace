function [fig_out, axes_out, plot_out] = ph(w,varargin)
%----help for gtk histogram overplot command ph----------------------------
%
% function syntax: PH(1ddataset_object,[property_name,property_value])
%
% purpose: overplot with histogram data
%
% input: 1d dataset object,property name and value
% output: none
%
% example: PH(w)
% PH(w,'color','red')
%
% See libisis graphics documentation for advanced syntax.
%-----------------------------------

%global structures
[IXG_ST_ERROR, IXG_ST_STDVALUES] = ixf_global_var('libisis_graphics','get','IXG_ST_ERROR','IXG_ST_STDVALUES');

%check args
if ( nargin < 1 )
    ixf_display_error(IXG_ST_ERROR.wrong_arg);
end

%check my figure
currflag = ixf_checkinit(IXG_ST_STDVALUES.currentfigure);
if (currflag == IXG_ST_STDVALUES.false)
    ixf_display_error(IXG_ST_ERROR.no_figure);
end
%hold
hold on;

%call already prepared dh utility
[figureHandle_, axesHandle_, plotHandle_] = dh(w,'counter',IXG_ST_STDVALUES.counter_increment,varargin{:});
hold off;

if nargout > 0
    fig_out = figureHandle_;
    axes_out = axesHandle_;
    plot_out = plotHandle_;
end