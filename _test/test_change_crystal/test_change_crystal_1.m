function test_change_crystal_1
% Test crystal refinement functions change_crytstal and refine_crystal
%
%   >> test_refinement           % Use previously saved sqw input data file
%
% Author: T.G.Perring

banner_to_screen(mfilename)

% -----------------------------------------------------------------------------
% Add common functions folder to path, and get location of common data
addpath(fullfile(fileparts(which('horace_init')),'_test','common_functions'))
common_data_dir=fullfile(fileparts(which('horace_init')),'_test','common_data');
% -----------------------------------------------------------------------------

dir_out=tempdir;
sim_sqw_file=fullfile(dir_out,'test_change_crystal_sim.sqw');           % output file for simulation in reference lattice
sim_sqw_file_corr=fullfile(dir_out,'test_change_crystal_sim_corr.sqw'); % output file for correction


% Data for creation of test sqw file
% ----------------------------------
efix=45;
emode=1;
en=-0.75:0.5:0.75;
par_file=fullfile(common_data_dir,'9cards_4_4to1.par');

% Parameters for generation of reference sqw file
alatt=[5,5,5];
angdeg=[90,90,90];
u=[1,0,0];
v=[0,1,0];
psi=0:1:90;
omega=0; dpsi=2; gl=3; gs=-3;

% Parameters of the true lattice
alatt_true=[5.5,5.5,5.5];
angdeg_true=[90,90,90];
qfwhh=0.1;                  % Spread of Bragg peaks
efwhh=1;                    % Energy width of Bragg peaks
rotvec=[10,10,0]*(pi/180);  % orientation of the true lattice w.r.t reference lattice


% Create sqw file for refinement testing
% --------------------------------------
urange = calc_sqw_urange (efix, emode, en(1), en(end), par_file, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);

sqw_file=cell(size(psi));
for i=1:numel(psi)
    sqw_file{i}=fullfile(dir_out,['dummy_',num2str(i),'.sqw']);
    fake_sqw (en, par_file, sqw_file{i}, efix, emode, alatt, angdeg,...
        u, v, psi(i), omega, dpsi, gl, gs, [1,1,1,1], urange);
end

% Simulate cross-section on all the sqw files: place blobs at Bragg positions of the true lattice
for i=1:numel(psi)
    wtmp=read_horace(sqw_file{i});
    wtmp=sqw_eval(wtmp,@make_bragg_blobs,{[qfwhh,efwhh],[alatt,angdeg],[alatt_true,angdeg_true],rotvec});
    save(wtmp,sqw_file{i});
end

% Combine the sqw files
write_nsqw_to_sqw(sqw_file,sim_sqw_file);

% Delete temporary sqw files
try
    for i=1:numel(psi)
        delete(sqw_file{i})
    end
catch
    disp('Unable to delete temporary sqw file(s)')
end


% Fit Bragg peak positions
% ------------------------
% Should get approximately: rlu0=[1.052,-0.142,0.722; 0.199,0.732,1.036; 0.158,-0.135,0.886; 0.895,0.015,-0.158; -0.015,-0.900,-0.158];
proj.u=[1,0,0];
proj.v=[0,1,0];

rlu=[1,0,1; 0,1,1; 0,0,1; 1,0,0; 0,-1,0];
half_len=0.5; half_thick=0.25; bin_width=0.025;

rlu0=get_bragg_positions(read_sqw(sim_sqw_file), proj, rlu, half_len, half_thick, bin_width);


% Get correction matrix from the 5 peak positions:
% ------------------------------------------------
[rlu_corr,alatt_fit,angdeg_fit,rotmat_fit] = refine_crystal(rlu0,alatt,angdeg,rlu,'fix_angdeg');


% Apply to a copy of the sqw object to see that the alignment is now OK
% ---------------------------------------------------------------------
copyfile(sim_sqw_file,sim_sqw_file_corr)
change_crystal_sqw(sim_sqw_file_corr,rlu_corr)
rlu0_corr=get_bragg_positions(read_sqw(sim_sqw_file_corr), proj, rlu, half_len, half_thick, bin_width);

if max(abs(rlu0_corr(:)-rlu(:)))>qfwhh
    assertTrue(false,'Problem in refinement of crystal orientation and lattice parameters')
end


% Success announcement and cleanup
% --------------------------------
try
    delete(sim_sqw_file)
    delete(sim_sqw_file_corr)
catch
    disp('Unable to delete temporary sqw file(s)')
end

banner_to_screen([mfilename,': Test(s) passed (matches are within requested tolerances)'],'bot')