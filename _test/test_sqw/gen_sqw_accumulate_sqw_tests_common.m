classdef gen_sqw_accumulate_sqw_tests_common < TestCaseWithSave
    % Series of tests of gen_sqw and associated functions
    % generated using multiple Matlab workers.
    %
    % Optionally writes results to output file to compare with previously
    % saved sample test results
    %---------------------------------------------------------------------
    % Usage:
    %
    %1) Normal usage:
    % Run all unit tests and compare their results with previously saved
    % results stored in test_gen_sqw_accumulate_sqw_output.mat file
    % located in the same folder as this function:
    %
    %>>runtests test_gen_sqw_accumulate_sqw_sep_session
    %---------------------------------------------------------------------
    %2) Run particular test case from the suite:
    %
    %>>tc = test_gen_sqw_accumulate_sqw_sep_session();
    %>>tc.test_[particular_test_name] e.g.:
    %>>tc.test_accumulate_sqw14();
    %or
    %>>tc.test_gen_sqw();
    %---------------------------------------------------------------------
    %3) Generate test file to store test results to compare with them later
    %   (it stores test results into tmp folder.)
    %
    %>>tc=test_gen_sqw_accumulate_sqw_sep_session('save');
    %>>tc.save():
    properties
        % properties to use as input for data
        test_data_path;
        test_functions_path;
        par_file;
        nfiles_max=6;
        
        pars;
        scale;
        
        proj;
        gen_sqw_par={};
        % files;
        spe_file={[]};
        
        instrum
        sample
        %
        % the field stores initial configuration, was in place when test
        % was started to run
        initial_config;
        %
        % the property describes common name of the test files allowing to
        % distinguish these files from the files, generated by other type
        % of test
        test_pref = 'nomex';
        
        working_dir
        
    end
    methods(Static)
        function new_names = rename_file_list(input_list,new_ext)
            % change extension for list of files
            if ~iscell(input_list)
                input_list = {input_list};
            end
            new_names = cell(1,numel(input_list));
            for i=1:numel(input_list)
                fls = input_list{i};
                [fpath,fn,~] = fileparts(fls);
                flt = fullfile(fpath,[fn,new_ext]);
                new_names{i} = flt;
                if exist(fls,'file')==2
                    movefile(fls,flt,'f');
                end
            end
        end
    end
    
    methods
        function obj=gen_sqw_accumulate_sqw_tests_common(test_class_name,test_prefix)
            % The constructor for class, which is the common part of all
            % MPI-based gen_sqw system tests.
            %
            % Should be used as
            %
            %   >> test_gen_sqw_accumulate_sqw          % Compares with
            %   previously saved results in
            %   test_gen_sqw_accumulate_sqw_output.mat
            %                                           % in the same
            %                                           folder as this
            %                                           function
            %   >> test_gen_sqw_accumulate_sqw ('save') % Save to
            %   test_multifit_horace_1_output.mat
            %
            % Reads previously created test data sets.
            
            
            obj = obj@TestCaseWithSave(test_class_name,fullfile(fileparts(mfilename('fullpath')),'test_gen_sqw_accumulate_sqw_output.mat'));
            obj.test_pref = test_prefix;
            
            % do other initialization
            obj.comparison_par={ 'min_denominator', 0.01, 'ignore_str', 1};
            obj.tol = 1.e-5;
            hor_root= horace_root();
            obj.test_functions_path=fullfile(hor_root,'_test/common_functions');
            
            addpath(obj.test_functions_path);
            
            hc = hor_config;
            obj.working_dir = hc.working_directory;
            horace_set_local_parallel_config();
            
            % build test file names
            obj.spe_file=cell(1,obj.nfiles_max);
            wkd = obj.working_dir;
            for i=1:obj.nfiles_max
                obj.spe_file{i}=fullfile(wkd ,...
                    ['gen_sqw_acc_sqw_spe_',test_prefix,num2str(i),'.nxspe']);
            end
            
            data_path = fileparts(mfilename('fullpath'));
            %this.par_file=fullfile(this.results_path,'96dets.par');
            obj.par_file=fullfile(data_path,'gen_sqw_96dets.nxspe');
            
            
            % initiate test parameters
            en=cell(1,obj.nfiles_max);
            efix=zeros(1,obj.nfiles_max);
            psi=zeros(1,obj.nfiles_max);
            omega=zeros(1,obj.nfiles_max);
            dpsi=zeros(1,obj.nfiles_max);
            gl=zeros(1,obj.nfiles_max);
            gs=zeros(1,obj.nfiles_max);
            for i=1:obj.nfiles_max
                efix(i)=35+0.5*i;                       % different ei for each file
                en{i}=0.05*efix(i):0.2+i/50:0.95*efix(i);  % different energy bins for each file
                psi(i)=90-i+1;
                omega(i)=10+i/2;
                dpsi(i)=0.1+i/10;
                gl(i)=3-i/6;
                gs(i)=2.4+i/7;
            end
            psi=90:-1:90-obj.nfiles_max+1;
            
            emode=1;
            alatt=[4.4,5.5,6.6];
            angdeg=[100,105,110];
            u=[1.02,0.99,0.02];
            v=[0.025,-0.01,1.04];
            
            obj.gen_sqw_par={en,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs};
            
            obj.pars=[1000,8,2,4,0];  % [Seff,SJ,gap,gamma,bkconst]
            obj.scale=0.3;
            % build test files if they have not been build
            obj=build_test_files(obj);
            
        end
        %
        %
        function [en,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(this,varargin)
            if nargin>1
                n_elem = varargin{1};
                if numel(n_elem) >1
                    select = n_elem;
                else
                    select = 1:n_elem;
                end
            else
                n_elem = numel(this.gen_sqw_par{1});
                select = 1:n_elem;
            end
            en =this.gen_sqw_par{1}(select);
            efix=this.gen_sqw_par{2}(select);
            emode=this.gen_sqw_par{3};
            alatt=this.gen_sqw_par{4};
            angdeg=this.gen_sqw_par{5};
            u=this.gen_sqw_par{6};
            v=this.gen_sqw_par{7};
            psi=this.gen_sqw_par{8}(select);
            omega=this.gen_sqw_par{9}(select);
            dpsi=this.gen_sqw_par{10}(select);
            gl=this.gen_sqw_par{11}(select);
            gs=this.gen_sqw_par{12}(select);
        end
        %
        function obj=build_test_files(obj,spe_files)
            if ~exist('spe_files','var')
                spe_files = obj.spe_file;
            end
            
            % =====================================================================================================================
            % Make instrument and sample
            % =====================================================================================================================
            wmod=IX_moderator('AP2',12,35,'ikcarp',[3,25,0.3],'',[],0.12,0.12,0.05,300);
            wap=IX_aperture(-2,0.067,0.067);
            wchop=IX_fermi_chopper(1.8,600,0.1,1.3,0.003);
            instrument_ref.moderator=wmod;
            instrument_ref.aperture=wap;
            instrument_ref.fermi_chopper=wchop;
            sample_ref=IX_sample('PCSMO',true,[1,1,0],[0,0,1],'cuboid',[0.04,0.05,0.02],1.6,300);
            
            instrument=repmat(instrument_ref,1,numel(spe_files));
            for i=1:numel(instrument)
                instrument(i).IX_fermi_chopper.frequency=100*i;
            end
            obj.instrum = instrument;
            obj.sample  = sample_ref;
            
            
            
            file_exist = cellfun(@(fn)(exist(fn,'file') == 2),spe_files);
            if all(file_exist)
                obj.add_to_files_cleanList(spe_files{:});
                return;
            end
            spe_files = spe_files(~file_exist);
            n_files = numel(spe_files);
            
            
            %sample_1=sample_ref;
            %sample_2=sample_ref;
            %sample_2.temperature=350;
            
            
            % =====================================================================================================================
            % Make spe files
            % =====================================================================================================================
            % for the purposes of consistency, test files have to be always
            % generated by single thread, as multithreading causes pixels
            % permutation within a bin, and then random function adds
            % various amout of noise to various detectors according to the
            % ordering
            
            
            hc = hor_config();
            um = hc.get_data_to_store;
            clob = onCleanup(@()set(hc,um));
            hc.use_mex = false; % so use Matlab single thread to generate source sqw files
            hpcc = hpc_config();
            ds1 = hpcc.get_data_to_store;
            clob1 = onCleanup(@()set(hpcc ,ds1));
            [en,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj);
            for i=1:n_files
                if ~(exist(spe_files{i},'file') == 2)
                    horace_simulate_spe_testfunc (en{i}, obj.par_file,spe_files{i}, @sqw_sc_hfm_testfunc, obj.pars, obj.scale,...
                        efix(i), emode, alatt, angdeg, u, v, psi(i), omega(i), dpsi(i), gl(i), gs(i));
                end
            end
            
            obj.add_to_files_cleanList(spe_files{:});
        end
        %
        function test_gen_sqw(obj,varargin)
            %-------------------------------------------------------------
            if obj.skip_test
                return
            end
            if nargin> 1
                % running in single test method mode.
                obj.setUp();
                co1 = onCleanup(@()obj.tearDown());
            end
            %-------------------------------------------------------------
            
            
            % build test files if they have not been build
            obj=build_test_files(obj);
            % generate the names of the output sqw files
            
            sqw_file=cell(1,obj.nfiles_max);
            file_pref = obj.test_pref;
            wkdir = obj.working_dir;
            for i=1:obj.nfiles_max
                sqw_file{i}=fullfile(wkdir ,['test_gen_sqw_',file_pref ,num2str(i),'.sqw']);    % output sqw file
            end
            
            sqw_file_123456=fullfile(wkdir ,['sqw_123456_',file_pref,'.sqw']);             % output sqw file
            sqw_file_145623=fullfile(wkdir ,['sqw_145623_',file_pref,'.sqw']);            % output sqw file
            if ~obj.save_output
                cleanup_obj1=onCleanup(@()obj.delete_files(sqw_file_123456,sqw_file_145623,sqw_file{:}));
            end
            %% ---------------------------------------
            % Test gen_sqw ---------------------------------------
            
            [en,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj);
            %hc.threads = 1;
            
            
            [dummy,grid,urange1]=gen_sqw (obj.spe_file, '', sqw_file_123456, efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);
            %hc.build_sqw_in_parallel=0;
            [dummy,grid,urange2]=gen_sqw (obj.spe_file([1,4,5,6,2,3]), '', sqw_file_145623, efix([1,4,5,6,2,3]), emode, alatt, angdeg, u, v, psi([1,4,5,6,2,3]), omega([1,4,5,6,2,3]), dpsi([1,4,5,6,2,3]), gl([1,4,5,6,2,3]), gs([1,4,5,6,2,3]));
            
            assertElementsAlmostEqual(urange1,urange2,'relative',1.e-6);
            
            % Make some cuts: ---------------
            obj.proj.u=[1,0,0.1]; obj.proj.v=[0,0,1];
            
            
            
            % Check cuts from gen_sqw output with spe files in a different
            % order are the same
            [ok,mess,dummy_w1,w1b]=is_cut_equal(sqw_file_123456,sqw_file_145623,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            assertTrue(ok,['Cuts from gen_sqw output with spe files in a different order are not the same: ',mess]);
            
            w1a=cut_sqw(sqw_file_123456,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            % Test against saved or store to save later
            obj.save_or_test_variables(w1a,w1b);
            
        end
        %
        function test_accumulate_sqw14(obj,varargin)
            %-------------------------------------------------------------
            if obj.skip_test
                return
            end
            if nargin> 1
                % running in single test method mode.
                obj.setUp();
                clobS = onCleanup(@()obj.tearDown());
            end
            %-------------------------------------------------------------
            file_pref = obj.test_pref;
            wk_dir = obj.working_dir;
            
            sqw_file_accum=fullfile(wk_dir ,['test_sqw_accum_sqw14_',file_pref,'.sqw']);
            sqw_file_14=fullfile(wk_dir ,['test_sqw_14_',file_pref,'.sqw']);
            clobR=onCleanup(@()obj.delete_files(sqw_file_14,sqw_file_accum));
            
            % --------------------------------------- Test accumulate_sqw
            % ---------------------------------------
            
            % Create some sqw files against which to compare the output of
            % accumulate_sqw
            % ---------------------------------------------------------------------------
            [dummy,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj);
            
            [dummy,dummy,urange14]=gen_sqw (obj.spe_file([1,4]), '', sqw_file_14, efix([1,4]),...
                emode, alatt, angdeg, u, v, psi([1,4]), omega([1,4]), dpsi([1,4]), gl([1,4]), gs([1,4]));
            
            % Now use accumulate sqw ----------------------
            obj.proj.u=u;
            obj.proj.v=v;
            
            spe_accum={obj.spe_file{1},'','',obj.spe_file{4}};
            present = cellfun(@(x)~isempty(x),spe_accum,'UniformOutput',true);
            fin = spe_accum(present);
            function ff = file_rename(ff)
                [fp,fn,~]=fileparts(ff);
                ff=fullfile(fp,[fn,'.tmp']);
            end
            tmp_fls = cellfun(@file_rename,fin,'UniformOutput',false);
            clobT = onCleanup(@()obj.delete_files(tmp_fls));
            
            [dummy,dummy,acc_urange14]=accumulate_sqw (spe_accum, '', sqw_file_accum,efix(1:4), ...
                emode, alatt, angdeg, u, v, psi(1:4), omega(1:4), dpsi(1:4), gl(1:4), gs(1:4),'clean');
            
            
            if not(obj.save_output)
                assertElementsAlmostEqual(urange14,acc_urange14,'relative',1.e-2)
            end
            
            [ok,mess,w2_14]=is_cut_equal(sqw_file_14,sqw_file_accum,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            assertTrue(ok,['Cuts from gen_sqw output and accumulate_sqw are not the same',mess]);
            
            % Test against saved or store to save later
            obj.save_or_test_variables(w2_14);
            
            
        end
        %
        function test_accumulate_and_combine1to4(obj,varargin)
            if obj.skip_test
                return
            end
            if nargin> 1
                % running in single test method mode.
                obj.setUp();
                co1 = onCleanup(@()obj.tearDown());
            end
            %-------------------------------------------------------------
            % this test works with 1 tmp file so should not be run in
            % parpool mode.
            hpc = hpc_config;
            comb_code = hpc.combine_sqw_using;
            if strcmpi(comb_code,'mpi_code')
                return;
            end
            
            % build test files if they have not been build
            obj=build_test_files(obj);
            file_pref = obj.test_pref;
            sqw_file_accum=fullfile(obj.working_dir,['test_accum_and_comb14',file_pref,'.sqw']); % output sqw file
            if ~obj.save_output
                co2=onCleanup(@()obj.delete_files(sqw_file_accum));
            end
            
            spe_names = obj.spe_file([1,4,5,6]);
            for i=1:numel(spe_names)
                [fp,fn,~] = fileparts(spe_names{i});
                if exist(fullfile(fp,[fn,'.tmp']),'file') == 2
                    delete(fullfile(fp,[fn,'.tmp']));
                end
            end
            
            new_names = gen_sqw_accumulate_sqw_tests_common.rename_file_list(spe_names(3:4),'.tnxs');
            co3 = onCleanup(@()gen_sqw_accumulate_sqw_tests_common.rename_file_list(new_names,'.nxspe'));
            
            % --------------------------------------- Test accumulate_sqw
            % ---------------------------------------
            
            % Create some sqw files against which to compare the output of
            % accumulate_sqw
            % ---------------------------------------------------------------------------
            [~,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj,[1,4,5,6]);
            
            % Now use accumulate sqw ----------------------
            [~,~,urange]=accumulate_sqw(spe_names, '', sqw_file_accum, ...
                efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);
            
            gen_sqw_accumulate_sqw_tests_common.rename_file_list(new_names{1},'.nxspe');
            
            [~,~,urange_all]=accumulate_sqw(spe_names, '', sqw_file_accum, ...
                efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);
            
            assertElementsAlmostEqual(urange,urange_all,'relative',1.e-4)
            
            gen_sqw_accumulate_sqw_tests_common.rename_file_list(new_names{2},'.nxspe');
            [~,~,urange_all]=accumulate_sqw(spe_names, '', sqw_file_accum, ...
                efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);
            assertElementsAlmostEqual(urange,urange_all,'relative',1.e-4)
            
            %----------------------------
            obj.proj.u=u;
            obj.proj.v=v;
            w2_1456=cut_sqw(sqw_file_accum,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            
            % Test against saved or store to save later
            obj.save_or_test_variables(w2_1456);
            
        end
        
        function test_accumulate_sqw1456(obj,varargin)
            %-------------------------------------------------------------
            if obj.skip_test
                return
            end
            if nargin> 1
                % running in single test method mode.
                obj.setUp();
                co1 = onCleanup(@()obj.tearDown());
            end
            %-------------------------------------------------------------
            
            
            % build test files if they have not been build
            obj=build_test_files(obj);
            file_pref = obj.test_pref;
            sqw_file_accum=fullfile(obj.working_dir,['test_sqw_accum_sqw1456_',file_pref, '.sqw']);
            sqw_file_1456=fullfile(obj.working_dir,['test_sqw_1456_',file_pref, '.sqw']);
            
            if ~obj.save_output
                cleanup_obj1=onCleanup(@()obj.delete_files(sqw_file_1456,sqw_file_accum));
            end
            % --------------------------------------- Test accumulate_sqw
            % ---------------------------------------
            
            % Create some sqw files against which to compare the output of
            % accumulate_sqw
            % ---------------------------------------------------------------------------
            [dummy,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj);
            
            [dummy,dummy,urange1456]=gen_sqw (obj.spe_file([1,4,5,6]), '',sqw_file_1456, efix([1,4,5,6]), emode, alatt, angdeg, u, v,...
                psi([1,4,5,6]), omega([1,4,5,6]), dpsi([1,4,5,6]), gl([1,4,5,6]), gs([1,4,5,6]));
            
            
            % Now use accumulate sqw ----------------------
            obj.proj.u=u;
            obj.proj.v=v;
            
            spe_accum={obj.spe_file{1},'','',obj.spe_file{4},obj.spe_file{5},obj.spe_file{6}};
            [dummy,dummy,acc_urange1456]=accumulate_sqw (spe_accum, '', sqw_file_accum,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs);
            
            % This is actually bad as urange is not really close
            if ~obj.save_output
                assertElementsAlmostEqual(urange1456,acc_urange1456,'relative',4.e-2);
            end
            [ok,mess,w2_1456]=is_cut_equal(sqw_file_1456,sqw_file_accum,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            assertTrue(ok,['Cuts from gen_sqw output and accumulate_sqw are not the same: ',mess])
            
            % Test against saved or store to save later
            obj.save_or_test_variables(w2_1456);
        end
        %
        function test_accumulate_sqw11456(obj,varargin)
            %-------------------------------------------------------------
            if obj.skip_test
                return
            end
            if nargin> 1
                % running in single test method mode.
                obj.setUp();
                co1 = onCleanup(@()obj.tearDown());
            end
            %-------------------------------------------------------------
            
            
            % build test files if they have not been build
            obj=build_test_files(obj);
            file_pref = obj.test_pref;
            sqw_file_accum=fullfile(obj.working_dir,['test_sqw_acc_sqw11456_',file_pref, '.sqw']);
            sqw_file_11456=fullfile(obj.working_dir,['test_sqw_11456_',file_pref, '.sqw']);
            cleanup_obj1=onCleanup(@()obj.delete_files(sqw_file_11456,sqw_file_accum));
            
            % --------------------------------------- Test accumulate_sqw
            % ---------------------------------------
            
            % Create some sqw files against which to compare the output of
            % accumulate_sqw
            % ---------------------------------------------------------------------------
            [~,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs]=unpack(obj);
            spe_selected = obj.spe_file([1,1,4,5,6]);
            
            
            
            [tmp_files,grid_size1,urange1]=gen_sqw (spe_selected,...
                '', sqw_file_11456, efix([1,3,4,5,6]), ...
                emode, alatt, angdeg, u, v, psi([1,3,4,5,6]),...
                omega([1,3,4,5,6]), dpsi([1,3,4,5,6]), gl([1,3,4,5,6]), gs([1,3,4,5,6]),...
                'replicate');
            assertEqual(exist(sqw_file_11456,'file'),2)
            clobT = onCleanup(@()obj.delete_files(tmp_files));
            
            % Now use accumulate sqw ----------------------
            obj.proj.u=u;
            obj.proj.v=v;
            
            % Repeat a file with 'replicate'
            spe_accum={obj.spe_file{1},'',obj.spe_file{1},obj.spe_file{4},obj.spe_file{5},obj.spe_file{6}};
            clear clobT;
            [tmp_fls,~,urange2]=accumulate_sqw (spe_accum, '',...
                sqw_file_accum,efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs,...
                'replicate'); %grid_size1,urange1,
            clobT = onCleanup(@()obj.delete_files(tmp_fls));
            % ranges are equal only if urange1 is provided
            %assertElementsAlmostEqual(urange1,urange2);
            
            [ok,mess,w2_11456,w2_11456acc]=is_cut_equal(sqw_file_11456,sqw_file_accum,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            if ~ok
                acolor('b');
                plot(w2_11456);
                acolor('r');
                pd(w2_11456acc);
                keep_figure;
            end
            assertTrue(ok,['Cuts from gen_sqw output and accumulate_sqw are not the same',mess]);
            % Test against saved or store to save later
            obj.save_or_test_variables(w2_11456);
            
            
            if obj.save_output
                return;
            end
            
            % Accumulate nothing:
            spe_accum={obj.spe_file{1},'',obj.spe_file{1},obj.spe_file{4},obj.spe_file{5},obj.spe_file{6}};
            accumulate_sqw (spe_accum, '', sqw_file_accum, efix, emode, alatt, angdeg, u, v, psi, omega, dpsi, gl, gs, 'replicate');
            [ok,mess]=is_cut_equal(sqw_file_11456,sqw_file_accum,obj.proj,[-1.5,0.025,0],[-2.1,-1.9],[-0.5,0.5],[-Inf,Inf]);
            assertTrue(ok,['Cuts from gen_sqw output and accumulate_sqw are not the same: ',mess]);
        end
        %
        
        %
    end
end
