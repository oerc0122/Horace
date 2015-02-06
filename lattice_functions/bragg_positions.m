function [rlu0,width,wcut,wpeak]=bragg_positions(w, rlu,...
    radial_cut_length, radial_bin_width, radial_thickness,...
    trans_cut_length, trans_bin_width, trans_thickness, varargin)
% Get actual Bragg peak positions, given initial estimates of their positions:
%
%   >> rlu0 = bragg_positions (w, rlu, ...
%                  radial_cut_length, radial_bin_width, radial_thickness,...
%                  trans_cut_length, trans_bin_width, trans_thickness, energy_window)
%
% The fits to the Bragg peaks can be checked with function bragg_positions_view:
%
%   >> [rlu0, widths, wcut, wpeak] = bragg_positions (...)
%   >> bragg_positions_view (wcut, wpeak)
%             (Press <CR> and follow instructions)
%
% Detailed description:
% ---------------------
% Use this function to find the true peak positions of a set of Bragg peaks.
% You provide the estimate of their positions (usually just the indicies of
% the Bragg peaks) and some parameters that describe the length, bin size and
% thickness of cuts through the nominal positions. The output can then be
% passed to functions that refine the crystal orientation e.g. refine_crystal
% (type >> help refine_crystal for more details of this function.
%
% For each Bragg position, the algorithm makes three orthogonal cuts through
% the nominal Bragg peak position, and finds the mid-point between the
% half-height positions either side of the peak for each of the three cuts.
% Alternatively, you can choose for a Gaussian to be fitted to each cut. The
% process is repeated for each Bragg peak in the input list. Various
% diagnostic information is returned, including the cuts themselves and the
% peak analysis. Make sure that the length and thickness of the cut fully cover
% the peaks, and that the bin width is appropriate.
%
% In practice, when refining the crystal orientation it is a good idea to get
% an approximate correction from two key Bragg peaks (e.g. in the horizontal
% plane, about 90 degrees apart), and then perform a refinement with a large
% list of reflections afterwards. The first correction should ensure that the
% nominal Bragg peak positions are all close to the true positions, so there
% is little concern that the length, bin and thickness parameters are
% inappropriate.
%
% Summary of this and related functions:
%   bragg_positions         % Get true Bragg peak positions
%
%   bragg_positions_view    % Cycle through the cuts and peak anaysis from
%                           % the above
%
%   refine_crystal          % Get a matrix that relates the nominal crystal
%                           % orientation to the refined orientation
%
%   change_crystal_horace   % Apply the correction matrix to an sqw or dnd file
%   change_crystal          % Apply the correction matrix to an sqw or dnd object
%
%   uv_correct2             % Return correct indexing of vectors u and v that
%                           % define the scattering plane for mslice
%
% Syntax:
% -------
%   >> [rlu0, widths, wcut, wpeak] = bragg_positions (w, rlu, ...
%               radial_cut_length, radial_bin_width, radial_thickness,...
%               trans_cut_length, trans_bin_width, trans_thickness, energy_window)
%
%   >> [rlu0, widths, wcut, wpeak] = bragg_positions (..., keyword1, keyword2)
%
% Input:
% ------
%   w                   Data source (sqw file name or sqw object)
%   rlu                 Set of nominal Bragg peak indicies in (n x 3) matrix:
%                           h1, k1, l1
%                           h2, k2, l2
%                           :   :   :
%                       These are the indicies of the Bragg peaks
%                       e.g. [1,0,0; 0,1,0; 1,1,0]
%
%   radial_cut_length-| Length of cuts along Q of Bragg peak,, bin size along
%   radial_bin_width  | the cut, and the thickness in the two perpendicular
%   radial_thickness -| directions.
%                       - If option 'bin_relative' these are given as fractions
%                         of |Q|. Good values might be 0.2, 0.002, 0.05 respectively
%                       - If option 'bin_absolute' they are in inverse Angstroms 
%                         Start with, say: 1.5, 0.05, 0.5 respectively
%
%   trans_cut_length-|  Length of cuts transverse to Q, bin size along
%   trans_bin_width  |  the cut, and the thickness in the two perpendicular
%   trans_thickness -|  directions.
%                       - If option 'bin_relative' these are given in degrees
%                         Good values might be 15, 0.5, 5 respectively
%                       - If option 'bin_absolute' they are in inverse Angstroms 
%                         Start with, say: 1.5, 0.05, 0.5 respectively
%
%   energy_window       Energy window around elastic line (meV)
%                       Choose according to the instrument resolution.
%                           e.g. for -1meV to +1 meV, set  energy_window=2
%
% Keyword options:
% ----------------
% Binning:
%   'bin_absolute'  Radial and transverse cut length, bin size, and thickness
%                  are in inverse Angstroms
%   'bin_relative'  Cut length, bin size and thickness are fractions of |Q|
%                  (radial cuts) and degrees (transverse cuts) [Default]
%
% Fitting:
%   'outer'         Determine peak position from centre half-height; find
%                  peak width moving inwards from limits of data - useful if
%                  there is known to be a single peak in the data as it is 
%                  more robust to too finely binned data.  [Default]
%   'inner'         Determine peak position from centre half height; find peak
%                  width moving outwards from peak maximum
%   'gaussian'      Fit Gaussian on a linear background.
%
%
% Output:
% -------
%   rlu0            The actual peak positions as (n x 3) matrix of h,k,l as
%                  indexed with the current lattice parameters
%   widths          Array (size (n x 3)) containing the FWHH in Ang^-1 of the
%                  peaks along each of the three projection axes
%   wcut            Array of cuts, size (n x 3),  along three orthogonal
%                  directions through each Bragg point from which the peak
%                  positions were determined. Pass to bragg_positions_view
%                  together with wpeak (below) to view the output. [Note: the
%                  cuts are IX_dataset_1d objects and can be plotted using
%                  the plot functions for these methods.]
%   wpeak           Array of spectra, size (n x 3), that summarise the peak
%                  analysis. Pass to bragg_positions_view together with wCUT
%                  (above) to view the output. [Note: the cuts are
%                  IX_dataset_1d objects and can be plotted using the plot
%                  functions for these methods.]


% Banner - catch case of old format
if nargin<8
    disp('--------------------------------------------------------------------------------')
    disp('    The original function prototype has been updated and this function')
    disp('   requires new arguments. Type >> help bragg_positions  for details. ')
    disp(' ')
    disp('    Alternatively: use the function bragg_positions_prototype which has')
    disp('   the old functionality. WARNING: there was a reason it was updated!')
    disp('--------------------------------------------------------------------------------')
    rlu0=[]; width=[]; wcut=[]; wpeak=[];
    return
end

% Check input arguments
if ischar(w)    % assume a file name
    file_type_ok=is_sqw_type_file(sqw,w);
    if ~isscalar(file_type_ok) || ~file_type_ok
        error('File must be sqw type')
    end
    h=head_sqw(w);  % get header information
elseif isa(w,'sqw') && is_sqw_type(w(1))
    if numel(w)~=1
        error('Data must be a single sqw object, not an array (or empty)')
    end
    if iscell(w.header)     % *** Really ought to have header_ave as a method. Use same algorithm here.
        h=w.header{1};
    else
        h=header;
    end
else
    error('Object must be sqw type')
end

npeaks=size(rlu,1);
if size(rlu,2)~=3 || npeaks==0
    error('The input Bragg point must form an (n x 3) array, one row per Bragg peak')
end

% Get cut binning and integration for each projection axes
if ~isscalar(radial_cut_length) || ~isnumeric(radial_cut_length) || radial_cut_length<=0
    error('Check radial cut length is a positive number greater than zero')
end
if ~isscalar(radial_bin_width) || ~isnumeric(radial_bin_width) || radial_bin_width<=0
    error('Check radial bin width is a positive number greater than zero')
end
if ~isscalar(radial_thickness) || ~isnumeric(radial_thickness) || radial_thickness<=0
    error('Check radial thickness is a positive number greater than zero')
end
if ~isscalar(trans_cut_length) || ~isnumeric(trans_cut_length) || trans_cut_length<=0
    error('Check transverse cut length is a positive number greater than zero')
end
if ~isscalar(trans_bin_width) || ~isnumeric(trans_bin_width) || trans_bin_width<=0
    error('Check transverse bin width is a positive number greater than zero')
end
if ~isscalar(trans_thickness) || ~isnumeric(trans_thickness) || trans_thickness<=0
    error('Check transverse thickness is a positive number greater than zero')
end

% Parse parameters:
arglist = struct('bin_relative',0,'bin_absolute',0,'inner',0,'outer',0,'gaussian',0);
flags = {'bin_relative','bin_absolute','inner','outer','gaussian'};
[args,opt] = parse_arguments(varargin,arglist,flags);
if numel(args)>1
    error('Check number and type of optional parameters')
end

% Get energy window
if numel(args)==1
    energy_window=args{1};
    if ~isscalar(energy_window) || ~isnumeric(energy_window) || energy_window<=0
        error('Check energy window is a positive number greater than zero')
    end
else
    energy_window=Inf;
    disp(' ')
    disp('*** Using default energy window as -Inf to Inf ***')
    disp(' ')
end
eint=[-energy_window/2,energy_window/2];

% Get binning option
optsum=opt.bin_relative+opt.bin_absolute;
if optsum==0
    relative_binning=true;
elseif optsum==1
    relative_binning=logical(opt.bin_relative);
else
    error('Check binning options')
end

% Get peak option
optsum=(opt.inner+opt.outer+opt.gaussian);
if optsum==0
    opt.outer=true;
elseif optsum~=1
    error('Check peak options')
end

if opt.inner
    opt='inner';
    gau=false;
elseif opt.outer
    opt='outer';
    gau=false;
elseif opt.gaussian
    gau=true;
else
    error('Logic problem - see T.G.Perring')
end


% Fit Peaks
% ---------
% Initialise output arguments
rlu0=zeros(size(rlu));
width=zeros(size(rlu));
wcut=repmat(IX_dataset_1d,npeaks,3);
wpeak=repmat(IX_dataset_1d,npeaks,3);

% Get matrix to convert rlu to input projection axes
u2rlu=h.u_to_rlu(1:3,1:3);
u1=u2rlu(:,1);
u2=u2rlu(:,2);

peak_problem=false(size(rlu));
for i=1:size(rlu,1)
    uq=u2rlu\rlu(i,:)';     % Q vector expressed in projection axes
    modQ=norm(uq);
    
    proj.uoffset=rlu(i,:);  % centre of cut is the nominal Bragg peak position
    % x axis is along Q, to get maximum resolution in d-spacing
    proj.u=rlu(i,:);
    % y axis is defined by whichever of u1, u2 projection axes is closer to perpendicular to Q (to avoid collinearity)
    if abs(dot(uq,u1))<=abs(dot(uq,u2))
        proj.v=u1';
    else
        proj.v=u2';
    end
    proj.type='aaa';        % force unit length of projection axes to be 1 Ang^-1
    
    % radial_cut_length, radial_bin_width, radial_thickness,...
    % trans_cut_length, trans_bin_width, trans_thickness, energy_window)
    if relative_binning
        len_r=radial_cut_length*modQ;
        bin_r=radial_bin_width*modQ;
        thick_r=radial_thickness*modQ;
        len_t=(pi/180)*trans_cut_length*modQ;
        bin_t=(pi/180)*trans_bin_width*modQ;
        thick_t=(pi/180)*trans_thickness*modQ;
    else
        len_r=radial_cut_length;
        bin_r=radial_bin_width;
        thick_r=radial_thickness;
        len_t=trans_cut_length;
        bin_t=trans_bin_width;
        thick_t=trans_thickness;
    end
    
    % Make three orthogonal cuts through nominal Bragg peak positions
    disp('--------------------------------------------------------------------------------')
    disp(['Peak ',num2str(i),':  [',num2str(rlu(i,:)),']','    scan: 1 (radial scan)'])
    w1a_1=cut_sqw(w, proj, [-len_r/2,bin_r,+len_r/2] ,[-thick_t/2,+thick_t/2]   ,[-thick_t/2,+thick_t/2],   eint, '-nopix');
    disp(' ')
    
    disp(['Peak ',num2str(i),':  [',num2str(rlu(i,:)),']','    scan: 2 (transverse scan)'])
    w1a_2=cut_sqw(w, proj, [-thick_r/2,+thick_r/2]   ,[-len_t/2,bin_t,+len_t/2] ,[-thick_t/2,+thick_t/2],   eint, '-nopix');
    disp(' ')
    
    disp(['Peak ',num2str(i),':  [',num2str(rlu(i,:)),']','    scan: 3 (transverse scan)'])
    w1a_3=cut_sqw(w, proj, [-thick_r/2,+thick_r/2]   ,[-thick_t/2,+thick_t/2]   ,[-len_t/2,bin_t,+len_t/2], eint, '-nopix');
    disp(' ')
    
    % Get peak positions
    upos0=zeros(3,1);
    if ~gau
        [upos0(1),dum1,width(i,1),dum2,dum3,dum4,w1a_1_pk]=peak_cwhh(IX_dataset_1d(w1a_1),opt);
        [upos0(2),dum1,width(i,2),dum2,dum3,dum4,w1a_2_pk]=peak_cwhh(IX_dataset_1d(w1a_2),opt);
        [upos0(3),dum1,width(i,3),dum2,dum3,dum4,w1a_3_pk]=peak_cwhh(IX_dataset_1d(w1a_3),opt);
    else
        [upos0(1),width(i,1),w1a_1_pk]=peak_gaussian(IX_dataset_1d(w1a_1));
        [upos0(2),width(i,2),w1a_2_pk]=peak_gaussian(IX_dataset_1d(w1a_2));
        [upos0(3),width(i,3),w1a_3_pk]=peak_gaussian(IX_dataset_1d(w1a_3));
    end
    
    % Fill output spectra with cuts and peak analysis
    wcut(i,1)=IX_dataset_1d(w1a_1);
    wcut(i,2)=IX_dataset_1d(w1a_2);
    wcut(i,3)=IX_dataset_1d(w1a_3);
    wpeak(i,1)=w1a_1_pk;
    wpeak(i,2)=w1a_2_pk;
    wpeak(i,3)=w1a_3_pk;
    
    % Get matrix to convert upos0 to rlu
    upos2rlu=w1a_1.u_to_rlu(1:3,1:3);
    
    % Convert peak position into r.l.u.
    if all(isfinite(upos0))
        rlu0(i,:)=(upos2rlu*upos0)' + rlu(i,:);
    else
        peak_problem(i,:)=~isfinite(upos0);
        rlu0(i,:)=NaN;
    end
end

disp('--------------------------------------------------------------------------------')
if any(peak_problem(:))
    disp('Problems determining peak position for:')
    for i=1:size(rlu,1)
        if any(peak_problem(i,:))
            disp(['Peak ',num2str(i),':  [',num2str(rlu(i,:)),']','    scan(s): ',num2str(find(peak_problem(i,:)))])
        end
    end
    disp(' ')
    disp(['Total number of peaks = ',num2str(size(rlu,1))])
    disp('--------------------------------------------------------------------------------')
end

%-----------------------------------------------------------------------------------------------------------
function [xcent,width,wfit]=peak_gaussian(w)
% Fit Gaussian to Bragg peak, trying to be robust

% Common case is too many bins if azimuthal scan from a single Laue diffraction shot. Assume only a single peak in the cut
[xcent,dum1,width,dum2,dum3,ypeak]=peak_cwhh(w,'outer');
if ~isfinite(xcent) % unable to find a peak
    xcent=NaN;
    width=NaN;
    wfit=w; wfit.signal=NaN(size(wfit.signal)); wfit.error=zeros(size(wfit.error));
    return
end

% Now fit Gaussian
[wfit_tmp,fitdata]=fit(w,@gauss_bkgd,[ypeak,xcent,width/2.3548,0,0]);
if all(isfinite(fitdata.sig)) && all(fitdata.sig>0)
    xcent=fitdata.p(2);
    width=2.3548*fitdata.p(3);
    wfit=func_eval(linspace(w,1000),@gauss_bkgd,fitdata.p);
else
    xcent=NaN;
    width=NaN;
    wfit=w; wfit.signal=NaN(size(wfit.signal)); wfit.error=zeros(size(wfit.error));
end
