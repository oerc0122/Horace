function [mess, S, pos_start] = get_sqw_information (fid)
% Get information header blocks from sqw file
%
%   >> [mess, S, pos_start] = get_sqw_information (fid)
%
% Input:
% ------
%   fid         File pointer to (already open) binary file
%
% Output:
% -------
%   mess        Message if there was a problem writing; otherwise mess=''
%   S           sqwfile structure
%   pos_start   Position of start of detector parameter block


mess='';
S=sqwfile();
pos_start=ftell(fid);

% Fill sqwfile structure
S.fid=fid;
S.filename=fopen(fid);

newfile=fnothingleft(fid);
if ~newfile
    ver3p1=appversion(3,1);
    
    expected_name='Horace';
    % Get Horace version and file format
    [mess, S.application] = get_sqw_application (fid, expected_name);
    if ~isempty(mess)
        S=sqwfile(); return
    end
    fmt_ver=S.application.file_format;
    
    % Check that the file format is older or equal to the current format
    if fmt_ver>ver3p1
        mess='File format is more recent than this version of Horace can read';
        S=sqwfile(); return
    end
    
    % Get information and position blocks
    if fmt_ver==ver3p1
        % Latest format
        [mess, S.info] = get_sqw_info (fid, fmt_ver);
        if ~isempty(mess)
            S=sqwfile(); return
        end
        [mess, S.position] = get_sqw_position (fid, fmt_ver);
        if ~isempty(mess)
            S=sqwfile(); return
        end
        [mess, S.fmt] = get_sqw_fmt (fid, fmt_ver);
        if ~isempty(mess)
            S=sqwfile(); return
        end
        
    else
        % Older formats ('-v3','-v1','-v0') - use legacy function
        [mess, S.info, S.position, S.fmt] = get_sqw_LEGACY_info_position_fmt (fid, fmt_ver);
        if ~isempty(mess)
            S=sqwfile(); return
        end
    end
    
end

%==================================================================================================
function answer=fnothingleft(fid)
% Determine if there is any more data in the file. Do this by trying to advance one byte
% Alternative is to go to end of file (fseek(fid,0,'eof') and see if location is the same.
status=fseek(fid,1,'cof');  % try to advance one byte
if status~=0;
    answer=true;
else
    answer=false;
    fseek(fid,-1,'cof');    % go back one byte
end
