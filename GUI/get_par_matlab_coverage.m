function par=get_par_matlab_coverage(filename)
% Load data from ASCII Tobyfit .par file
%   >> par = get_par_matlab(filename)
%
%     filename      name of par file
%
%     par(5,ndet)   contents of array
%
%     1st column    sample-detector distance
%     2nd  "        scattering angle (deg)
%     3rd  "        azimuthal angle (deg)
%                   (west bank = 0 deg, north bank = -90 deg etc.)
%                   (Note the reversed sign convention cf .phx files)
%     4th  "        width (m)
%     5th  "        height (m)

% Original author: T.G.Perring
%
% $Revision: 301 $ ($Date: 2009-11-03 20:52:59 +0000 (Tue, 03 Nov 2009) $)
%
% Ibon Bustinduy

filename=strtrim(filename); % Remove blanks from beginning and end of filename
if isempty(filename),
   error('Filename is empty')
end
fid=fopen(filename,'rt');
if fid==-1,
   error(['Error opening file ',filename]);
end

n=fscanf(fid,'%d \n',1);
disp(['Loading .par file with ' num2str(n) ' detectors : ' filename]);
temp=fgetl(fid);
par=sscanf(temp,'%f');
cols=length(par); % number of columns 5 or 6
par=[par;fscanf(fid,'%f')];
fclose(fid);
par=reshape(par,cols,n);
