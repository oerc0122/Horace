function [ok,mess,ei,x0,xa,x1,moderator,shaping_chopper,mono_chopper,...
    horiz_div,vert_div] = instpars_DGdisk(header)
% Get parameters needed for chopper spectrometer resolution function calculation
%
%   >> [ok,mess,ei,x0,xa,x1,moderator,shaping_chopper,mono_chopper,...
%                           horiz_div,vert_div] = instpars_DGdisk (header)
% Input:
% ------
%   header      Header field from sqw object
%
% Output: (arrays are column vectors with length equal to the number of contributing runs)
% -------
%   ok          Error status: true if OK, false otherwise
%   mess        Error message: empty if OK, filled otherwise
%   ei          Incident energies (mev)     [Column vector]
%   x0          Moderator-monochromating chopper distance (m) 	 [column vector]
%   xa          Shaping-monochromating chopper distance (m)      [column vector]
%   x1          Monochromating chopper-sample distance  (m)      [column vector]
%   moderator       Array of moderator objects  [Column vector]
%   shaping_chopper Array of shaping chopper objects    [Column vector]
%   mono_chopper    Array of monochromating chopper objects    [Column vector]
%   horiz_div       Array of horizontal divergence profile objects [Column vector]
%   vert_div        Array of horizontal divergence profile objects [Column vector]


% Get array of instruments
if ~iscell(header)
    nrun=1;
    inst=header.instrument;
    header={header};
else
    nrun=numel(header);
    inst=repmat(header{1}.instrument,[nrun,1]);
    for i=2:nrun
        inst(i)=header{i}.instrument;
    end
end

% Fill output arguments
ei=zeros(nrun,1);
x0=zeros(nrun,1);
xa=zeros(nrun,1);
x1=zeros(nrun,1);
moderator=repmat(IX_moderator,[nrun,1]);
shaping_chopper=repmat(IX_doubledisk_chopper,[nrun,1]);
mono_chopper=repmat(IX_doubledisk_chopper,[nrun,1]);
horiz_div=repmat(IX_divergence_profile,[nrun,1]);
vert_div=repmat(IX_divergence_profile,[nrun,1]);
for i=1:nrun
    ei(i)=header{i}.efix;
    x1(i)=abs(inst(i).chop_mono.distance);
    x0(i)=abs(inst(i).moderator.distance) - x1(i);      % distance from mono chopper to moderator face
    xa(i)=abs(inst(i).chop_shape.distance) - x1(i);     % distance from shaping chopper to mono chopper
    moderator(i)=inst(i).moderator;
    shaping_chopper(i)=inst(i).chop_shape;
    mono_chopper(i)=inst(i).chop_mono;
    horiz_div(i)=inst(i).horiz_div;
    vert_div(i)=inst(i).vert_div;
end

ok=true;
mess='';
