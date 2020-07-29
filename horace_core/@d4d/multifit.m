function varargout = multifit (varargin)
% Simultaneously fit function(s) to one or more d4d objects
%
%   >> myobj = multifit (w1, w2, ...)      % w1, w2 objects or arrays of objects
%
% This creates a fitting object of class mfclass_Horace with the provided data,
% which can then be manipulated to add further data, set the fitting
% functions, initial parameter values etc. and fit or simulate the data.
% For details about how to do this  <a href="matlab:help('mfclass_Horace');">Click here</a>
%
% For example:
%
%   >> myobj = multifit (w1, w2, ...); % set the data
%       :
%   >> myobj = myobj.set_fun (@function_name, pars);  % set forgraound function(s)
%   >> myobj = myobj.set_bfun (@function_name, pars); % set background function(s)
%       :
%   >> myobj = myobj.set_free (pfree);      % set which parameters are floating
%   >> myobj = myobj.set_bfree (bpfree);    % set which parameters are floating
%   >> [wfit,fitpars] = myobj.fit;          % perform fit
%
% This method fits function(s) of the plot axes for both the foreground and
% the background function(s). An example fit function can be found here:
% <a href="matlab:edit('example_4d_function');">example_4d_function</a>
%
% See also multifit_sqw multifit_sqw_sqw

%-------------------------------------------------------------------------------
% <#doc_def:>
%   class_name = 'd4d'
%   dim = '4'
%   method_name = 'multifit'
%   mfclass_name = 'mfclass_Horace'
%   function_tag = ''
%
%   multifit_doc = fullfile(fileparts(which('multifit')),'_docify')
%   sqw_doc = fullfile(fileparts(which('mfclass_Horace')),'_docify')
%
%   doc_multifit_header = fullfile(multifit_doc,'doc_multifit_header.m')
%   doc_fit_functions = fullfile(sqw_doc,'doc_multifit_fit_functions_for_dnd.m')
%
%-------------------------------------------------------------------------------
% <#doc_beg:> multifit
%   <#file:>  <doc_multifit_header>  <class_name>  <method_name>  <mfclass_name>  <function_tag>
%
%   <#file:>  <doc_fit_functions>  <dim>
%
% See also multifit_sqw multifit_sqw_sqw
% <#doc_end:>
%-------------------------------------------------------------------------------

mf_init = mfclass_wrapfun (@func_eval, [], @func_eval, []);
varargout{1} = mfclass_Horace (varargin{:}, 'd1d', mf_init);
