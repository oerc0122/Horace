classdef an_axis_caption
    %Lightweight class -- parent for different various axis caption classes
    %
    %By default implements sqw cut object captions functionality
    %
    %
    % $Revision: 877 $ ($Date: 2014-06-10 12:35:28 +0100 (Tue, 10 Jun 2014) $)
    %
    
    properties(Dependent)
        % property specifies if 2D picture, this class captions is intended
        % to should change aspect ration according to aspect ratio of the
        % data along axis
        changes_aspect_ratio;
    end
    properties(Access=protected)        
        caption_calc_func_;
        % internal property, which defines if appropriate picture changes
        changes_aspect_ratio_=true;
    end
    
    methods
        function obj=an_axis_caption(varargin)
            obj.caption_calc_func_ = @data_plot_titles;
        end
        function change=get.changes_aspect_ratio(this)
            change = this.changes_aspect_ratio_;
        end
        function [title_main, title_pax, title_iax, display_pax, display_iax, energy_axis] =...
                data_plot_titles(this,data)
            %Get titling and caption information for an sqw data structure
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
            
            [title_main, title_pax, title_iax, display_pax, display_iax, energy_axis]=...
                this.caption_calc_func_(data);
        end
    end
    
end

