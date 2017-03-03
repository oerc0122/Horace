function [uoffset,ulabel,dax,u_to_rlu,ulen,axis_titles] = get_proj_param_(proj,data_in,pax)
% store parameters, describing cut sqw object and important for
% its behaviour wrt subsequent cuts.
%

uoffset = [proj.ucentre;0];

ulabel = {'\rho','\theta','\phi','En'};
dax = zeros(1,length(pax));
% plot axes in the input data set in order x-axis, y-axis, ...
plotaxis = data_in.pax(data_in.dax);
j=1;
for i=1:length(plotaxis)
    idax = find(plotaxis(i)==pax);
    if ~isempty(idax)   % must be in the list if a plot axis
        dax(j)=idax;
        j=j+1;
    end
end
u_to_rlu=proj.data_u_to_rlu_;
ulen = proj.usteps;
%[~,~,~,~,~,u_to_rlu,ulen] = proj.get_pix_transf_();
%u_to_rlu = [[u_to_rlu,[0;0;0]];[0,0,0,1]];
%ulen = [ulen,1];
% class which generates captions for spherical projection
axis_titles = spher_proj_caption();
