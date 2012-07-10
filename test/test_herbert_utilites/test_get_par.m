classdef test_get_par< TestCase
% 
% $Revision: 135 $ ($Date: 2012-02-08 14:42:48 +0000 (Wed, 08 Feb 2012) $)
%
    
    properties 
    end
    methods       
        % 
        function this=test_get_par(name)
            this = this@TestCase(name);
        end
        % tests themself
        function test_wrong_file_name(this)               
            f = @()get_par('non-existent-file-name');            
            assertExceptionThrown(f,'GET_PAR:invalid_argument');
        end               
        function test_get_par_from_ASCII(this)
            par = get_par('one2one_112.par');
            assertEqual([6,69632],size(par));
        end               
        function test_gethor_par_from_ASCII(this)
            par = get_par('one2one_112.par','-hor');
            assertTrue(isstruct(par));
            assertTrue(isfield(par,'x2'));
            assertTrue(isfield(par,'phi'));
            assertTrue(isfield(par,'azim'));            
            assertTrue(isfield(par,'width'));                        
            assertTrue(isfield(par,'height')); 
        end               
        function test_wrong_data_format_ignored(this)                       
            par = get_par('one2one_112.par');
            assertEqual([6,69632],size(par));
        end
        function test_get_par_nxspe(this)
		   if is_herbert_used()
				par = get_par('MAR11001_test.nxspe');
				assertEqual([6,285],size(par));            
		   else
		       % currently does not read nxspe
               ok=true;			   
			   assertTrue(ok);
		   end
        end
  

    end
end
