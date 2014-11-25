function file_list=setup_demo_data()
%
% Internal routine for demo - generates some spe files that can then be
% used in the Horace demo suite.
%

demo_dir=pwd;

en=[-80:8:760];
par_file=[demo_dir,filesep,'4to1_124.PAR'];
sqw_file_single=[demo_dir,filesep,'single.sqw'];
efix=800;
emode=1;
alatt=[2.87,2.87,2.87];
angdeg=[90,90,90];
u=[1,0,0];
v=[0,1,0];
omega=0;dpsi=0;gl=0;gs=0;

psi=[0:4:90];
nxspe_limit = numel(psi)+2;%numel(psi)/2;
file_list = cell(1,numel(psi));

%horace_info_level(-Inf);
hil=get(hor_config,'horace_info_level');
set(hor_config,'horace_info_level',-Inf);
display('Getting data for Horace demo... Please wait a few minutes');
try
    for i=1:numel(psi)
        fake_sqw(en, par_file, sqw_file_single, efix, emode, alatt, angdeg,...
                         u, v, psi(i), omega, dpsi, gl, gs);

        w=read_sqw(sqw_file_single);
        %Make the fake data:
        w=sqw_eval(w,@demo_FM_spinwaves,[300 0 2 10 2]);%simulate spinwave cross-section 
        w=noisify(w,1);%add some noise to simulate real data
        if i<nxspe_limit
            d = rundata(w+0.74);
            file_list{i} = [demo_dir,filesep,'HoraceDemoDataFile',num2str(i),'.nxspe'];
            saveNXSPE(d,file_list{i});
        else
            d=spe(w+0.74);%also add a constant background
            file_list{i} = [demo_dir,filesep,'HoraceDemoDataFile',num2str(i),'.spe'];
            save(d,file_list{i});
        end
        %remove intermediate file
    end
catch err
    set(hor_config,'horace_info_level',hil);
    delete(sqw_file_single);
    fprintf('Errore producing fake_sqw data: %s Reason: %s\n',err.identifier,err.message);
    display('Problem generating data for Horace demo - check that 4to1_124.PAR file is present in current (demo) directory');
end

set(hor_config,'horace_info_level',hil);
%horace_info_level(hil)
delete(sqw_file_single);

    