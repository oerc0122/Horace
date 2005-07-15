function d = slice_4d (binfil, u, v, p0, p1_bin, p2_bin, p3_bin, varargin)
% Reads a binary spe file and creates a 4D data set from it.
%
% Syntax:
%  To retain original energy binning from spe file:
%   >> d = slice_4d (binfil, u, v, p0, p1_bin, p2_bin, p3_bin, type)
%  
%   >> d = slice_4d (binfil, u, v, p0, p1_bin, p2_bin, p3_bin, type, ...
%                                                     p1_lab, p2_lab, p3_lab)
%
%  To alter energy binning:
%   >> d = slice_4d (binfil, u, v, p0, p1_bin, p2_bin, p3_bin, p4_bin, type)
%  
%   >> d = slice_4d (binfil, u, v, p0, p1_bin, p2_bin, p3_bin, p4_bin, type, ...
%                                                     p1_lab, p2_lab, p3_lab)
%
% Input:
% ------
%   binfil          Binary spe file created using function gen_hkle
%   u(1:3)          Vector defining first plot axis (r.l.u.)
%   v(1:3)          Vector defining plane of plot in Q-space (r.l.u.)
%        These two directions define a plane with the first axis parallel to u
%       and the second perpendicular to u in the plane of u and v. A third axis 
%       is defined as perpendicular to the plane of u and v, forming a right-hand
%       set. Call the orthogonal set created from u and v: p1, p2, p3.
%        The 4D grid is now built up from p1, p2, p3 and energy (called p4 below).
%        The unit lengths along the axes p1, p2 and p3 are determined by the 
%       character codes in the variable 'type' described below.
%           
%   p0(1:4)         Vector defining origin of the 4D grid in QE-space (r.l.u.,E)
%   p1_bin(1:3)     Binning along p1 axis: [p1_start, p1_step, p1_end]
%   p2_bin(1:3)     Binning perpendicular to u axis within the plot plane:
%                        [p2_start, p2_step, p2_end]
%   p3_bin(1:3)     Binning perpendicular to p1 and p2: 
%                        [p3_start, p3_step, p3_end]
%   p4_bin(1:3)     Binning along the energy axis:
%                        [p4_start, p4_step, p4_end]
%                    or, to use bin size from original spe files but change range:
%                        [p4_start, p4_end] 
%                    or, to use range and bin size from original spe files
%                        -- omit p4_bin --
%                   If p4_step is smaller than that in the spe files, it is set
%                   equal to that in the spe files.
%   type            Defines measure of units length for binning.
%        Three-character string, each character indicating if p1, p2, p3 are
%       normalised to Angstrom^-1 or r.l.u., max(abs(h,k,l))=1:
%        - if 'a': unit length is one inverse Angstrom
%        - if 'r': then if (h,k,l) in r.l.u., is normalised so max(abs([h,k,l]))=1
%       e.g. type='rrr' or 'raa'
%
%   p1_lab          Short label for p1 axis (e.g. 'Q_h' or 'Q_{kk}'
%   p2_lab          Short label for p2 axis
%   p3_lab          Short label for p3 axis
%
%
% Output:
% -------
%   d       4D dataset defined on orthogonal axes above
%           For a complete description of the fields of the dataset, type
%               >> help dnd_checkfields

% Original author: J. van Duijn
%
% $Revision$ ($Date$)
%
% Horace v0.1   J. van Duijn, T.G.Perring

% parameter used to check rounding
small = 1.0e-13;

% Check input parameters.
if nargin==8,
    type= varargin{1};
elseif nargin==9,
    p4_bin=varargin{1};
    type= varargin{2};
elseif nargin==9,
    type= varargin{1};
    p1_lab = varargin{2};
    p2_lab = varargin{3};
    p3_lab = varargin{4};
elseif nargin==12,
    p4_bin=varargin{1};
    type= varargin{2};
    p1_lab = varargin{3};
    p2_lab = varargin{4};
    p3_lab = varargin{5};
else
    error ('ERROR - Check number of arguments')
end

% check p0(4) is zero
if abs(p0(4))>small
    error ('ERROR: offset along energy axis not permitted')
end

fid= fopen(binfil, 'r');    % open spebin file
h_main = get_header(fid);   % get the main header information

% obtain the conversion matrix that will convert the hkle vectors in the
% spe file in to equivalents in the orthogonal set defined by u and v
[rlu_to_ustep, u_to_rlu, ulen] = rlu_to_ustep_matrix ([h_main.a,h_main.b, h_main.c],...
    [h_main.alpha,h_main.beta,h_main.gamma], u, v, [p1_bin(2),p2_bin(2),p3_bin(2)], type);

% convert p0 to the equivalent vector in the new orthogonal set given by
% u_to_rlu
p0n= rlu_to_ustep*p0(1:3)';

for iblock = 1:h_main.nfiles,
    disp(['reading block no.: ' num2str(iblock)]);
    h = get_spe_datablock(fid); % read in spe block
    
    if iblock==1, % Create the output data structure
        d.file= binfil;
        d.grid= 'orthogonal-grid';
        d.title=h_main.title;
        d.a= h_main.a;
        d.b= h_main.b;
        d.c= h_main.c;
        d.alpha= h_main.alpha;
        d.beta= h_main.beta;
        d.gamma= h_main.gamma;
        d.u= [[u_to_rlu; 0 0 0], [0 0 0 1]'];
        d.ulen= [ulen,1];
        % set labels
        if exist('p1_lab','var')    % labels were provided
            d.label = {p1_lab,p2_lab,p3_lab,'E'};
        else
            % determine if the three axes are h, k and l (or some permutation)
            if max(max(abs(sort(u_to_rlu)-[0,0,0;0,0,0;1,1,1]))) < small
                lis= find(round(u_to_rlu));  % find the elements equal to unity
                tl= {'Q_h','Q_k','Q_l','E'};
                d.label= [tl(lis(1)),tl(lis(2)-3),tl(lis(3)-6),tl(4)];
            else
                d.label= {'Q_\zeta','Q_\xi','Q_\eta','E'};
            end
        end
        d.p0=p0';
        d.pax=[1,2,3,4];
        d.iax=[]; % create empty index of integration array
        d.uint=[];
        d.p1= [p1_bin(1):p1_bin(2):p1_bin(3)]'; % length of d.u1=floor((u1_bin(3)-u1_bin(1))/u1_bin(2))+1
        d.p2= [p2_bin(1):p2_bin(2):p2_bin(3)]'; % Contains the bin boundaries
        d.p3= [p3_bin(1):p3_bin(2):p3_bin(3)]';
        % Allow for energy range only to be given (TGP, 13 July 2005)
        enbin = (h.en(end)-h.en(1))/(length(h.en)-1);  % energy grid is stored as bin centres
        if ~exist('p4_bin','var')   % use intrinsic energy bin and step
            p4_bin = [(h.en(1)-enbin/2),enbin,(h.en(end)+enbin/2)];
            disp('Using energy range and binning from original spe files')
        else
            if length(p4_bin)==2 | ebin > p4_bin(2) % binning is smaller then the intrinsic binning, or is not given
                % tweak limits so that where there is existing spe data, the bin boundaries will match
                p4_bin = [(ceil((p4_bin(1)-h.en(1))/enbin)-0.5)*enbin, enbin, ...
                          (floor((p4_bin(1)-h.en(1))/enbin)+0.5)*enbin];
                disp ('Using energy bin size from original spe files')
            end
        end
        d.p4= [p4_bin(1):p4_bin(2):p4_bin(3)]';
        np1= length(d.p1)-1; % number of bins
        np2= length(d.p2)-1;
        np3= length(d.p3)-1;
        np4= length(d.p4)-1;
        d.s= zeros(np1,np2,np3,np4); % generate the 4D data structures
        d.e= zeros(np1,np2,np3,np4);
        d.n= int16(d.s);            
    end
    
    vstep= rlu_to_ustep*h.v; % convert h.v into the equivalent step matrix along the new 
                            % orthogonal set given by u_to_rlu
                            
    %generate the energy vector corresponding to each hkl vector
    emat= repmat(h.en, h.size(1), 1);
    emat= reshape(emat, h.size(1)*h.size(2),1);
    emat= emat';
    
    % convert vstep into index array where vstep(i,1)= 1 corresponds to data
    % between pi(1) and pi(2).
    vstep(1,:)= floor(vstep(1,:)-p0n(1)-p1_bin(1)/p1_bin(2))+1;
    vstep(2,:)= floor(vstep(2,:)-p0n(2)-p2_bin(1)/p2_bin(2))+1;
    vstep(3,:)= floor(vstep(3,:)-p0n(3)-p3_bin(1)/p3_bin(2))+1;
    
    % generate equivalent energy matrix
    emat= floor((emat-p4_bin(1) )/p4_bin(2))+1;
    
    % find the index array 
    lis=find(1<=vstep(1,:) & vstep(1,:)<=floor((max(d.p1)-p1_bin(1))/p1_bin(2)) & ...
             1<=vstep(2,:) & vstep(2,:)<=floor((max(d.p2)-p2_bin(1))/p2_bin(2)) & ...
             1<=vstep(3,:) & vstep(3,:)<=floor((max(d.p3)-p3_bin(1))/p3_bin(2)) & ...
             1<=emat       &       emat<=floor((max(d.p4)-p4_bin(1))/p4_bin(2)));
    
    % sum up the Intensity, errors and hits into the 4D array.
    % add the stepsize of the last bin of d.int with 0 int to make sure
    % that the accumulated array has the same size as d.int
    %a=(accumarray(vstep(1:3,lis)',h.S(lis)))
    d.s= d.s + accumarray([[vstep(1:3,lis);emat(lis)], [np1; np2; np3; np4]]',[h.S(lis) 0]); % summed 4D intensity array
    d.e= d.e + accumarray([[vstep(1:3,lis);emat(lis)], [np1; np2; np3; np4]]',[h.ERR(lis) 0]); % summed 4D error array
    d.n= d.n + int16(accumarray([[vstep(1:3,lis);emat(lis)], [np1; np2; np3; np4]]', [ones(1,length(lis)) 0])); 
end

fclose(fid);