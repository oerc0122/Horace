classdef test_SQW_GENCUT_perf < TestCaseWithSave
    % Test checks performance achieved during sqw file generation and
    % different cuts, done over the test sqw files.
    %
    % The performance results (in second) are stored in a matlab binary file
    % combining results for all hosts where the tests were run
    % The format of the file is as follows:
    % -host_name1->test_name1(nworkers)->test_time(sec)
    %           |->test_name2(nworkers)->test_time(sec)
    %           |->test_name3(nworkers)->test_time(sec)
    % -host_name2->test_name1(nworkers)->test_time(sec)
    %           |->test_name2(nworkers)->test_time(sec)
    %           |->test_name3(nworkers)->test_time(sec)
    %
    % where nworkers is the number of parallel workers used to process the
    % data  and the test_name is the name, specified as input to
    % save_or_test_performance method
    % The host_name is the variable combined from the preffix containign the
    % output of Hergbert getHostName function
    % and the suffix containing the number of files used as the input for
    % the test.
    
    properties(Dependent)
        %  Number of input files to use. Depending on this number the test
        %  would verify small, large or huge datasets
        n_files_to_use% = 10;
        % time to run the test which should not be substantially increase
        % on a given machine. The first time one runs the test on the
        % machine, it is ignored
        time_to_run = [];
        % performance suite name consists of the pc name and the number of
        % input files to run. Describes the test suite which was or will be
        % processed on current pc with current number of test files.
        perf_test_name;
        % performance data to compare against or store current results
        perf_data
        % performance tests result file, containing the results of all
        % tests, run using this class. For normal operations of adding/modifying
        % the performance results, this file should come with the test
        % class, exist in the same folder as the test class and be
        % accessible for read/write operations.
        perf_test_res_file
    end
    
    properties
        % directory, containing data file necessary for the tests
        source_data_dir
        % directory to keep temporary working files
        working_dir
        %
        % target file for gen_sqw command and source file for cut commands
        sqw_file = 'GenSQW_perfTest.sqw'
    end
    
    properties(Access=private)
        % list of source files to process
        test_source_files_list_
        %
        % the mat file containing the performance data for the tests run on
        % different machines. The file is located in the test folder so should
        % be write-enabled on unix when the test is run for the first time.
        %
        perf_test_res_file_ = 'SQW_GENCUT_Perf.mat'
        % performance test suite name to run/verify
        perf_suite_name_;
        % performance data to compare against or store current results
        perf_data_;
        % performance suite name consists of the pc name and the number of
        % input files to run
        perf_test_name_ ='';
        %  Number of input files to use. Depending on this number the test
        %  would verify small, large or huge datasets
        n_files_to_use_ = 10;
        % Template file name: the name of the file used as a template for
        % others. HACK. Nice version would generate test source files from
        % some scattering and instrument models.
        template_file_ = 'MER19566_22.0meV_one2one125.nxspe';
        % parameter file
        par_file = 'one2one_125.par'
        
        % time to run the test which should not be substantially increase
        % on a given machine. The first time one runs the test on the
        % machine, it is ignored
        time_to_run_ = [];
        
    end
    methods
        %------------------------------------------------------------------
        function tr = get.time_to_run(obj)
            % the time to run resent test case
            tr = obj.time_to_run_;
        end
        function nf = get.n_files_to_use(obj)
            % number of test files, used in performance tests
            nf = obj.n_files_to_use_;
        end
        function pfn = get.perf_test_name(obj)
            % current test name, combined from the host name and the number of
            % test files, used in tests
            pfn = obj.perf_test_name_;
        end
        function pfd = get.perf_data(obj)
            % returns the structure, containing all performance data,
            % availible for tests. Can be equivalent to loading the whole
            % perf_test_res_file in memory
            pfd = obj.perf_data_;
        end
        function pf = get.perf_test_res_file(obj)
            % the name of binary Matlab file, containign all existing
            % performance results.
            pf = obj.perf_test_res_file_;
        end
        %------------------------------------------------------------------
        function obj = test_SQW_GENCUT_perf(varargin)
            % create test suite, generate source files and load existing
            % perfomance data.
            %
            obj = obj@TestCaseWithSave(varargin{:});
            obj.source_data_dir = pwd();
            % locate the test data folder
            stat = mkdir('test_SQWGEN_performance_rw_test');
            if stat == 1
                rmdir('test_SQWGEN_performance_rw_test','s');
                obj.working_dir = obj.source_data_dir;
            else
                obj.working_dir = tmpdir;
                
            end
            obj.n_files_to_use = obj.n_files_to_use_;
            obj.add_to_files_cleanList(obj.sqw_file);
            %
            tests_name = obj.perf_test_name_;
            if exist(obj.perf_test_res_file_,'file')==2
                ld = load(obj.perf_test_res_file_);
                obj.perf_data_ = ld.sqw_gen_cut_perf_data;
            else
                obj.perf_data_ = struct(tests_name,[]);
            end
        end
        function test_data = save_or_test_performance(obj,start_time,test_method_name)
            % save performance data if the previous version for current pc
            % does not exist or test performance against previously stored
            % performance data
            %
            % start_time -- time of the test run start measured by tic
            %               function
            
            run_time= toc(start_time);
            sqw_gen_cut_perf_data = obj.perf_data_;
            if isfield(sqw_gen_cut_perf_data,obj.perf_test_name)
                test_data = sqw_gen_cut_perf_data.(obj.perf_test_name);
            else
                test_data = [];
            end
            if isempty(test_data)
                test_data = struct(test_method_name,run_time);
                fprintf('*** Method %s: Run time: %3.2e min;\n',...
                    test_method_name,run_time/60);
                
            else
                if isfield(test_data,test_method_name)
                    old_time = test_data.(test_method_name);
                    fprintf(...
                        ['*** Method %s: Run time: %3.2e min; old time:',...
                        ' %3.2e min: run is %3.2e times faster\n'],...
                        test_method_name,run_time/60,old_time/60,...
                        (old_time-run_time)/old_time)
                    %assertEqualToTol(run_time,old_time,'relTol',0.1);
                end
                test_data.(test_method_name) = run_time;
            end
            obj.time_to_run_ = run_time;
            sqw_gen_cut_perf_data.(obj.perf_test_name) = test_data;
            save(obj.perf_test_res_file_,'sqw_gen_cut_perf_data')
            obj.perf_data_ = sqw_gen_cut_perf_data;
            
        end
        %-------------------------------------------------------------
        
        
        function set.n_files_to_use(obj,val)
            % change number of files to use and modify all related
            % internal properties which depends on this number
            %
            obj.n_files_to_use_ = floor(abs(val));
            if obj.n_files_to_use_ < 1
                obj.n_files_to_use_ = 1;
            end
            obj.perf_test_name_ = [getComputerName(),'_nf',num2str(obj.n_files_to_use_)];
            filelist = source_nxspe_files_generator(obj.n_files_to_use,...
                obj.source_data_dir,obj.working_dir,obj.template_file_);
            % delete generated files after the test completed.
            obj.add_to_files_cleanList(filelist);
            obj.test_source_files_list_ = filelist;
            fb = 'GenSQW_perfTest';
            obj.sqw_file = sprintf('%s_%dFiles.sqw',fb,obj.n_files_to_use_);
        end
        %--------------------------------------------------------------------------
        function combine_performance_test(obj,varargin)
            % this method tests tmp file combine operations only. It can be
            % deployed after test_gensqw_performance method has been run
            % with hor_config class delete_tmp option set to false. In this
            % case tmp files created by gen_sqw method are kept and this
            % method may test combime operations only.
            %
            % Usage:
            % tob.combine_performance_test([n_workers])
            % where n_workers, if present, specify the number of parallel
            % workers to run the test routines with. 
            %
            % As this test method violates unit test agreement, demanding
            % test method independence on each other, it does not start
            % from the name test to avoid running it by automated test
            % suites.
            if nargin == 1
                n_workers = 0;
            else
                n_workers = varargin{1};
            end
            clob_wk = check_and_set_workers_(obj,n_workers);
            
            
            
            function fn = replace_fext(fn)
                [fp,fn] = fileparts(fn);
                fn = fullfile(fp,[fn,'.tmp']);
            end
            
            spe_files = obj.test_source_files_list_;
            tmp_files = cellfun(@(fn)(replace_fext(fn)),spe_files,'UniformOutput',false);
            
            % check all tmp files were generated
            f_exist = cellfun(@(fn)(exist(fn,'file')==2),tmp_files,'UniformOutput',true);
            
            assertTrue(all(f_exist),'Some tmp files necessary to run the test do not exist. Can not continue');
            
            ts = tic();
            write_nsqw_to_sqw(tmp_files,obj.sqw_file);
            
            obj.save_or_test_performance(ts,['combine_tmp_using_',num2str(n_workers),'_wrkr']);
            
            % spurious check to ensure the cleanup object is not deleted
            % before the end of the test
            assertTrue(isa(clob_wk,'onCleanup'))
            
            obj.rm_files(tmp_files{:});
            
        end
        %------------------------------------------------------------------
        function perf_res= test_gensqw_performance(obj,varargin)
            % test performance (time spent on processing) class-defined
            % number of files using number of workers provided as input
            %
            % Usage:
            % tob.combine_performance_test([n_workers])
            % where n_workers, if present, specify the number of parallel
            % workers to run the test routines with. 
            %
            % n_workers>1 sets up parallel file combining.
            % 1 or absent does not change current Horace configuration.
            if nargin == 1
                n_workers = 0;
            else
                n_workers = varargin{1};
            end
            clob_wk = check_and_set_workers_(obj,n_workers);
            
            nwk = num2str(n_workers);
            efix= 22.8;%incident energy in meV
            
            emode=1;%direct geometry
            alatt=10.7488*[1 1 1];%lattice parameters [a,b,c]
            angdeg=[90,90,90];%lattice angles [alpha,beta,gamma]
            u=[1,1,0];%u=// to incident beam
            v=[0,0,1];%v= perpendicular to the incident beam, pointing towards the large angle detectors on Merlin in the horizontal plane
            omega=0;
            dpsi=-1.8464+(0.9246);
            gl=-3.1871+(-0.1634);
            gs=-1.7047+(0.0028);
            
            nfiles=numel(obj.test_source_files_list_);
            psi= 0.5*(1:nfiles);
            %psi=round(psi);
            ts = tic();
            
            gen_sqw (obj.test_source_files_list_,obj.par_file,obj.sqw_file, efix, emode, alatt, angdeg,u, v, psi, omega, dpsi, gl, gs,'replicate');
            
            obj.save_or_test_performance(ts,['gen_sqw_nWorkers',nwk]);
            
            % test small 1 dimensional cuts, non-axis aligned
            ts = tic();
            proj1 = struct('u',[1,0,0],'v',[0,1,1]);
            sqw1 = cut_sqw(obj.sqw_file,proj1,0.01,[-0.1,0.1],[-0.1,0.1],[-5,5]);
            obj.save_or_test_performance(ts,['cutH1D_Small_nw',nwk]);
            
            ts = tic();
            sqw1 = cut_sqw(obj.sqw_file,proj1,[-0.1,0.1],0.01,[-0.1,0.1],[-5,5]);
            obj.save_or_test_performance(ts,['cutK1D__Small_nw',nwk]);
            
            ts = tic();
            sqw1 = cut_sqw(obj.sqw_file,proj1,[-0.1,0.1],[-0.1,0.1],0.01,[-5,5]);
            obj.save_or_test_performance(ts,['cutL1D_Small_nw',nwk]);
            
            ts = tic();
            sqw1 = cut_sqw(obj.sqw_file,proj1,[-0.1,0.1],[-0.1,0.1],[-0.1,0.1],0.2);
            obj.save_or_test_performance(ts,['cutE__Small_nw',nwk]);
            
            % check nopix performance -- read and integrate the whole file from the HDD
            hs = head_sqw(obj.sqw_file);
            urng = hs.urange';
            ts = tic();
            proj1 = struct('u',[1,0,0],'v',[0,1,1]);
            sqw1=cut_sqw(obj.sqw_file,proj1,0.01,urng(2,:),urng(3,:),urng(4,:),'-nopix');
            obj.save_or_test_performance(ts,['cutH1D_AllInt_fbnw',nwk]);
            
            ts = tic();
            sqw1=cut_sqw(obj.sqw_file,proj1,urng(1,:),0.01,urng(3,:),urng(4,:),'-nopix');
            obj.save_or_test_performance(ts,['cutK1D_AllInt_npnw',nwk]);
            
            ts = tic();
            sqw1=cut_sqw(obj.sqw_file,proj1,urng(1,:),urng(2,:),0.01,urng(4,:),'-nopix');
            obj.save_or_test_performance(ts,['cutL1D_AllInt_npnw',nwk]);
            
            ts = tic();
            sqw1=cut_sqw(obj.sqw_file,proj1,urng(1,:),urng(2,:),urng(3,:),0.2,'-nopix');
            obj.save_or_test_performance(ts,['cutE_AllInt_npnw',nwk]);
            
            
            % test large 1 dimensional cuts, non-axis aligned, with whole
            % integration. for big input sqw files this should go to
            % file-based cuts
            fl2del = {'cutH1D_AllInt.sqw','cutK1D_AllInt.sqw',...
                'cutL1D_AllInt.sqw','cutE_AllInt.sqw'};
            clob = onCleanup(@()rm_files(obj,fl2del{:}));
            
            ts = tic();
            proj1 = struct('u',[1,0,0],'v',[0,1,1]);
            cut_sqw(obj.sqw_file,proj1,0.01,urng(2,:),urng(3,:),urng(4,:),'cutH1D_AllInt.sqw');
            obj.save_or_test_performance(ts,['cutH1D_AllInt_fbnw',nwk]);
            
            ts = tic();
            cut_sqw(obj.sqw_file,proj1,urng(1,:),0.01,urng(3,:),urng(4,:),'cutK1D_AllInt.sqw');
            obj.save_or_test_performance(ts,['cutK1D_AllInt_fbnw',nwk]);
            
            ts = tic();
            cut_sqw(obj.sqw_file,proj1,urng(1,:),urng(2,:),0.01,urng(4,:),'cutL1D_AllInt.sqw');
            obj.save_or_test_performance(ts,['cutL1D_AllInt_fbnw',nwk]);
            
            ts = tic();
            cut_sqw(obj.sqw_file,proj1,urng(1,:),urng(2,:),urng(3,:),0.2,'cutE_AllInt.sqw');
            perf_res=obj.save_or_test_performance(ts,['cutE_AllInt_fbnw',nwk]);
            
            % spurious check to ensure the cleanup object is not deleted
            % before the end of the test
            assertTrue(isa(clob_wk,'onCleanup'))
        end
    end
    methods(Access=private)
        function clob = check_and_set_workers_(obj,n_workers)
            % function verifies and sets new number of MPI workers
            %
            % returns cleanup object to return the number of temporary
            % workers to its initial value
            hc = hor_config;
            as = hc.accum_in_separate_process;
            an = hc.accumulating_process_num;
            if as && an > 1
                clob = onCleanup(@()set(hc,'accum_in_separate_process',as,'accumulating_process_num',an));
            else
                clob = onCleanup(@()(an));
            end
            if (n_workers~=0 && ~as)
                hc.accum_in_separate_process = true;
                hc.accumulating_process_num = n_workers;
            end
            
        end
    end
end
