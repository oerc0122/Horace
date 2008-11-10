function [title_main, title_pax, title_iax, display_pax, display_iax, energy_axis] = data_plot_titles (data)
% Get titling and caption information for an sqw data structure
%
% Syntax:
%   >> [title_main, title_pax, title_iax, display_pax, display_iax, energy_axis] = data_plot_titles (w)
% 
% Input:
% ------
%   data            Structure for which titles are to be created from the data in its fields.
%                   Type >> help check_sqw_data for a full description of the fields
%
% Output:
% -------
%   title_main      Main title (cell array of character strings)
%   title_pax       Cell array containing axes annotations for each of the plot axes
%   title_iax       Cell array containing annotations for each of the integration axes
%   display_pax     Cell array containing axes annotations for each of the plot axes suitable 
%                  for printing to the screen
%   display_iax     Cell array containing axes annotations for each of the integration axes suitable 
%                  for printing to the screen
%   energy_axis     The index of the column in the 4x4 matrix din.u that corresponds
%                  to the energy axis

% Original author: T.G.Perring
%
% $Revision: 113 $ ($Date: 2007-02-06 12:22:54 +0000 (Tue, 06 Feb 2007) $)
%
% Horace v0.1   J.Van Duijn, T.G.Perring

% initialise output arguments that may legitimately be returned as empty cell arrays
title_pax = {};
title_iax = {};
display_pax = {};
display_iax = {};

% Prepare input arguments
file = fullfile(data.filepath,data.filename);
title = data.title;

uoff = data.uoffset;
u_to_rlu = data.u_to_rlu;
ulen = data.ulen;
ulabel = data.ulabel;
iax = data.iax;
iint = data.iint;
pax = data.pax;
uplot = zeros(3,length(pax));
for i=1:length(pax)
    pvals = data.p{i};
    uplot(1,i) = pvals(1);
    uplot(2,i) = (pvals(end)-pvals(1))/(length(pvals)-1);
    uplot(3,i) = pvals(end);
end
dax = data.dax;

uofftot=uoff;
for i=1:length(iax)
    uofftot=uofftot+(0.5*(iint(1,i)+iint(2,i)))*u_to_rlu(:,iax(i));  % overall displacement of plot volume in (rlu;en)
end

% Axes and integration titles
% Character representations of input data
small = 1.0e-10;    % tolerance for rounding numbers to zero or unity in titling
for j=1:4
    if abs(uoff(j)) > small
        uoff_ch{j} = num2str(uoff(j),'%+11.4g');        
    else
        uoff_ch{j} = num2str(0,'%+11.4g');        
    end
    if abs(uofftot(j)) > small
        uofftot_ch{j} = num2str(uofftot(j),'%+11.4g');        
    else
        uofftot_ch{j} = num2str(0,'%+11.4g');        
    end
    for i=1:4
        if abs(u_to_rlu(i,j)) > small
            u_to_rlu_ch{i,j} = num2str(u_to_rlu(i,j),'%+11.4g');  % format ensures sign (+ or -) is attached to character representation
        else
            u_to_rlu_ch{i,j} = num2str(0,'%+11.4g');  % format ensures sign (+ or -) is attached to character representation
        end
    end
end

% pre-allocate cell arrays for titling:
title_pax = cell(length(pax),1);
display_pax = cell(length(pax),1);
title_iax = cell(length(iax),1);
display_iax = cell(length(iax),1);
title_main_pax = cell(length(pax),1);
title_main_iax = cell(length(iax),1);

% Create titling
for j=1:4
    % Determine if column vector in u corresponds to a Q-axis or energy
    if u_to_rlu(4,j)==0
        % Q axis ------------------------------------------------------------------------------
        % Captions including offsets from integration axes
        for i=1:3
            if ~strcmp(uofftot_ch{i}(2:end),'0') && ~strcmp(u_to_rlu_ch{i,j}(2:end),'0')     % uofftot(i) and u_to_rlu(i,j) both contain non-zero values
                if ~strcmp(u_to_rlu_ch{i,j}(2:end),'1')
                    ch{i,j} = [uofftot_ch{i},u_to_rlu_ch{i,j},ulabel{j}];
                else
                    ch{i,j} = [uofftot_ch{i},u_to_rlu_ch{i,j}(1),ulabel{j}];
                end
            elseif strcmp(uofftot_ch{i}(2:end),'0') && ~strcmp(u_to_rlu_ch{i,j}(2:end),'0')  % uofftot(i)=0 but u_to_rlu(i,j)~=0
                if ~strcmp(u_to_rlu_ch{i,j}(2:end),'1')
                    ch{i,j} = [u_to_rlu_ch{i,j},ulabel{j}];
                else
                    ch{i,j} = [u_to_rlu_ch{i,j}(1),ulabel{j}];
                end
            else
                ch{i,j} = uofftot_ch{i};
            end
            if ch{i,j}(1)=='+'        % strip off leading '+'
                ch{i,j} = ch{i,j}(2:end);
            end
        end
        totvector{j} = ['[',ch{1,j},', ',ch{2,j},', ',ch{3,j},']'];
        in_totvector{j} = [' in ',totvector{j}];
        
        % Captions excluding offsets from integration axes
        for i=1:3
            if ~strcmp(uoff_ch{i}(2:end),'0') && ~strcmp(u_to_rlu_ch{i,j}(2:end),'0')     % uoff(i) and u_to_rlu(i,j) both contain non-zero values
                if ~strcmp(u_to_rlu_ch{i,j}(2:end),'1')
                    ch{i,j} = [uoff_ch{i},u_to_rlu_ch{i,j},ulabel{j}];
                else
                    ch{i,j} = [uoff_ch{i},u_to_rlu_ch{i,j}(1),ulabel{j}];
                end
            elseif strcmp(uoff_ch{i}(2:end),'0') && ~strcmp(u_to_rlu_ch{i,j}(2:end),'0')  % uoff(i)=0 but u_to_rlu(i,j)~=0
                if ~strcmp(u_to_rlu_ch{i,j}(2:end),'1')
                    ch{i,j} = [u_to_rlu_ch{i,j},ulabel{j}];
                else
                    ch{i,j} = [u_to_rlu_ch{i,j}(1),ulabel{j}];
                end
            else
                ch{i,j} = uoff_ch{i};
            end
            if ch{i,j}(1)=='+'        % strip off leading '+'
                ch{i,j} = ch{i,j}(2:end);
            end
        end
        vector{j} = ['[',ch{1,j},', ',ch{2,j},', ',ch{3,j},']'];
        in_vector{j} = [' in ',vector{j}];
        
        % Create captioning
        if any(j==pax)   % j appears in the list of plot axes
            ipax = find(j==pax(dax));
            if abs(ulen(j)-1) > small
                title_pax{ipax} = [totvector{j},' in ',num2str(ulen(j)),' �^{-1}'];
            else
                title_pax{ipax} = [totvector{j},' (�^{-1})'];
            end
            title_main_pax{ipax} = [ulabel{j},'=',num2str(uplot(1,ipax)),':',num2str(uplot(2,ipax)),':',num2str(uplot(3,ipax)),in_totvector{j}];
            display_pax{ipax} = [ulabel{j},' = ',num2str(uplot(1,ipax)),':',num2str(uplot(2,ipax)),':',num2str(uplot(3,ipax)),in_totvector{j}];
        elseif any(j==iax)   % j appears in the list of integration axes
            iiax = find(j==iax);
            title_iax{iiax} = [num2str(iint(1,iiax)),' \leq ',ulabel{j},' \leq ',num2str(iint(2,iiax)),in_vector{j}];
            title_main_iax{iiax} = [num2str(iint(1,iiax)),' \leq ',ulabel{j},' \leq ',num2str(iint(2,iiax)),in_vector{j}];
            display_iax{iiax} = [num2str(iint(1,iiax)),' =< ',ulabel{j},' =< ',num2str(iint(2,iiax)),in_vector{j}];
        else
            error ('ERROR: Axis is neither plot axis nor integration axis')
        end
        
    else
        % energy axis ------------------------------------------------------------------------------
        % Captions including offsets from integration axes
        energy_axis = j;
        if ~strcmp(uofftot_ch{4}(2:end),'0') && ~strcmp(u_to_rlu_ch{4,j}(2:end),'0')     % uofftot(4) and u_to_rlu(4,j) both contain non-zero values
            if ~strcmp(u_to_rlu_ch{4,j}(2:end),'1')
                ch{4,j} = [uofftot_ch{4},u_to_rlu_ch{4,j},ulabel{j}];
            else
                ch{4,j} = [uofftot_ch{4},u_to_rlu_ch{4,j}(1),ulabel{j}];
            end
        elseif strcmp(uofftot_ch{4}(2:end),'0') && ~strcmp(u_to_rlu_ch{4,j}(2:end),'0')  % uofftot(4)=0 but u_to_rlu(4,j)~=0
            if ~strcmp(u_to_rlu_ch{4,j}(2:end),'1')
                ch{4,j} = [u_to_rlu_ch{4,j},ulabel{j}];
            else
                ch{4,j} = [u_to_rlu_ch{4,j}(1),ulabel{j}];
            end
        end
        if ch{4,j}(1)=='+'        % strip off leading '+'
            ch{4,j} = ch{4,j}(2:end);
        end
        if max(strcmpi(ch{4,j},{'e','en','energy','hw','hbar w','hbar.w','eps'}))==1  % conventional energy labels
            totvector{j} = '';
            in_totvector{j} = '';
        else
            totvector{j} = ['[0, 0, 0, ',ch{4,j},']'];
            in_totvector{j} = [' in ',totvector{j}];
        end
        
        % Captions excluding offsets from integration axes
        if ~strcmp(uoff_ch{4}(2:end),'0') && ~strcmp(u_to_rlu_ch{4,j}(2:end),'0')     % uoff(4) and u_to_rlu(4,j) both contain non-zero values
            if ~strcmp(u_to_rlu_ch{4,j}(2:end),'1')
                ch{4,j} = [uoff_ch{4},u_to_rlu_ch{4,j},ulabel{j}];
            else
                ch{4,j} = [uoff_ch{4},u_to_rlu_ch{4,j}(1),ulabel{j}];
            end
        elseif strcmp(uoff_ch{4}(2:end),'0') && ~strcmp(u_to_rlu_ch{4,j}(2:end),'0')  % uoff(4)=0 but u_to_rlu(4,j)~=0
            if ~strcmp(u_to_rlu_ch{4,j}(2:end),'1')
                ch{4,j} = [u_to_rlu_ch{4,j},ulabel{j}];
            else
                ch{4,j} = [u_to_rlu_ch{4,j}(1),ulabel{j}];
            end
        end
        if ch{4,j}(1)=='+'        % strip off leading '+'
            ch{4,j} = ch{4,j}(2:end);
        end
        if max(strcmpi(ch{4,j},{'e','en','energy','hw','hbar w','hbar.w','eps'}))==1  % conventional energy labels
            vector{j} = '';
            in_vector{j} = '';
        else
            vector{j} = ['[0, 0, 0, ',ch{4,j},']'];
            in_vector{j} = [' in ',vector{j}];
        end        
        
        if any(j==pax)   % j appears in the list of plot axes
            ipax = find(j==pax(dax));
            if abs(ulen(j)-1) > small
                title_pax{ipax} = [totvector{j},' in ',num2str(ulen(j)),' meV'];
            else
                title_pax{ipax} = [totvector{j},' (meV)'];
            end
            title_main_pax{ipax} = [ulabel{j},'=',num2str(uplot(1,ipax)),':',num2str(uplot(2,ipax)),':',num2str(uplot(3,ipax)),in_totvector{j}];
            display_pax{ipax} = [ulabel{j},' = ',num2str(uplot(1,ipax)),':',num2str(uplot(2,ipax)),':',num2str(uplot(3,ipax)),in_totvector{j}];
        elseif any(j==iax)   % j appears in the list of integration axes
            iiax = find(j==iax);
            title_iax{iiax} = [num2str(iint(1,iiax)),' \leq ',ulabel{j},' \leq ',num2str(iint(2,iiax)),in_vector{j}];
            title_main_iax{iiax} = [num2str(iint(1,iiax)),' \leq ',ulabel{j},' \leq ',num2str(iint(2,iiax)),in_vector{j}];
            display_iax{iiax} = [num2str(iint(1,iiax)),' =< ',ulabel{j},' =< ',num2str(iint(2,iiax)),in_vector{j}];
        else
            error ('ERROR: Axis is neither plot axis nor integration axis')
        end
    end
end


% Main title
iline = 1;
if ~isempty(file)
    title_main{iline}=avoidtex(file);
    iline = iline + 1;
end
if ~isempty(title)
    title_main{iline}=title;
    iline = iline + 1;
end
if ~isempty(iax)
    title_main{iline}=title_main_iax{1};
    if length(title_main_iax)>1
        for i=2:length(title_main_iax)
            title_main{iline}=[title_main{iline},' , ',title_main_iax{i}];
        end
    end
    iline = iline + 1;
end
if ~isempty(pax)
    title_main{iline}=title_main_pax{1};
    if length(title_main_pax)>1
        for i=2:length(title_main_pax)
            title_main{iline}=[title_main{iline},' , ',title_main_pax{i}];
        end
    end
end