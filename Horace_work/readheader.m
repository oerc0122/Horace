function data=readheader(binfil)

% this function obtains the header information contained in the binary file
% generated by gen_hkle.m and contains the following information
%
%       data.title_label: title label
%       data.ei: value of ei
%       data.a: a axis
%       data.b: b axis
%       data.c: c axis
%       data.alpha: alpha
%       data.beta: beta
%       data.gamma: gamma
%       data.grid: type of binary file (4D grid, blocks of spe file, etc)
%       data.title_label: title label
%       data.efixed: value of ei
%       data.a: a axis
%       data.b: b axis
%       data.c c axis
%       data.alpha: alpha
%       data.beta: beta
%       data.gamma: gamma
%       data.u     Matrix (4x4) of projection axes in original 4D representation
%              u(:,1) first vector - u(1:3,1) r.l.u., u(4,1) energy etc.
%       din.ulen  Length of vectors in Ang^-1, energy
%       data.nfiles: number of spe files contained within the binary file
%   if data is in grid:
%       din.p0    Offset of origin of projection [ph; pk; pl; pen]
%       din.pax   Index of plot axes in the matrix din.u
%               e.g. if data is 3D, din.pax=[2,4,1] means u2, u4, u1 axes are x,y,z in any plotting
%                               2D, din.pax=[2,4]     "   u2, u4,    axes
%                               are x,y   in any plotting
%

% Author:
%   J. van Duijn     01/06/2005
% Modified:
%
% Horace v0.1   J.Van Duijn, T.G.Perring

fid = fopen(binfil,'r');
data= getheader(fid);
fclose(fid);