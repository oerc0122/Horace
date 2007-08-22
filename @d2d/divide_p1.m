function wout = divide_p1(a,b)
%--- Help for d2d/divide_p1.m---
% call syntax: dataset_2d = divide_p1(a,b)
%
% divides each row of an d2d object by either a dataset_1d or a
% 1-d array. 
%
% When dividing by a 1d array (or d1d) the division is done such
% that
%
% dataset_2d(i).s(j,k) = ww(i).s(j,k) / n(k) 
%
% where n is either the 1d numeric array or signal data in the
% d1d
%
% inputs: a = d2d object, b = 1-d array or d1d object
% output: d2d object
%
% This operation has the same properties as divide_x in libisis. See
% documentation for advanced usage. 

wout = dnd_binary_op(a, b, @divide_x, 'd2d', 2);