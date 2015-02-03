function varargout = horace_planner(varargin)
% HORACE_PLANNER M-file for horace_planner.fig
%      HORACE_PLANNER, by itself, creates a new HORACE_PLANNER or raises the existing
%      singleton*.
%
%      H = HORACE_PLANNER returns the handle to a new HORACE_PLANNER or the handle to
%      the existing singleton*.
%
%      HORACE_PLANNER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HORACE_PLANNER.M with the given input arguments.
%
%      HORACE_PLANNER('Property','Value',...) creates a new HORACE_PLANNER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before horace_planner_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to horace_planner_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help horace_planner

% Last Modified by GUIDE v2.5 03-Feb-2015 11:00:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @horace_planner_OpeningFcn, ...
                   'gui_OutputFcn',  @horace_planner_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before horace_planner is made visible.
function horace_planner_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to horace_planner (see VARARGIN)

% Choose default command line output for horace_planner
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes horace_planner wait for user response (see UIRESUME)
% uiwait(handles.Planner);


% --- Outputs from this function are returned to the command line.
function varargout = horace_planner_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function parfile_edit_Callback(hObject, eventdata, handles)
% hObject    handle to parfile_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of parfile_edit as text
%        str2double(get(hObject,'String')) returns contents of parfile_edit as a double


% --- Executes during object creation, after setting all properties.
function parfile_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parfile_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browse_pushbutton.
function browse_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to browse_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[par_filename,par_pathname,FilterIndex] = uigetfile({'*.par','*.PAR'},'Select par file');

if ischar(par_pathname) && ischar(par_filename)
    %i.e. the cancel button was not pressed
    set(handles.parfile_edit,'string',[par_pathname,par_filename]);
    guidata(gcbo,handles);
end



% --- Executes on button press in loadpar_pushbutton.
function loadpar_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadpar_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Clear error message
set(handles.message_text,'String','');
guidata(gcbo,handles);
drawnow;

try
    filename=get(handles.parfile_edit,'string');
    par=get_par(filename);
    handles.detpar=par;
    set(handles.message_text,'String','Par file loaded successfully');
    guidata(gcbo,handles);
    drawnow;
catch
    set(handles.message_text,'String','Error - see Matlab command window for details');
    disp('ERROR - no valid par file selected');
    guidata(gcbo,handles);
    drawnow;
end



function u_edit_Callback(hObject, eventdata, handles)
% hObject    handle to u_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of u_edit as text
%        str2double(get(hObject,'String')) returns contents of u_edit as a double


% --- Executes during object creation, after setting all properties.
function u_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to u_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function v_edit_Callback(hObject, eventdata, handles)
% hObject    handle to v_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of v_edit as text
%        str2double(get(hObject,'String')) returns contents of v_edit as a double


% --- Executes during object creation, after setting all properties.
function v_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to v_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ei_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ei_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ei_edit as text
%        str2double(get(hObject,'String')) returns contents of ei_edit as a double


% --- Executes during object creation, after setting all properties.
function ei_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ei_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eps_edit_Callback(hObject, eventdata, handles)
% hObject    handle to eps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eps_edit as text
%        str2double(get(hObject,'String')) returns contents of eps_edit as a double


% --- Executes during object creation, after setting all properties.
function eps_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psimin_edit_Callback(hObject, eventdata, handles)
% hObject    handle to psimin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psimin_edit as text
%        str2double(get(hObject,'String')) returns contents of psimin_edit as a double


% --- Executes during object creation, after setting all properties.
function psimin_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psimin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function psimax_edit_Callback(hObject, eventdata, handles)
% hObject    handle to psimax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of psimax_edit as text
%        str2double(get(hObject,'String')) returns contents of psimax_edit as a double


% --- Executes during object creation, after setting all properties.
function psimax_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to psimax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function alatt_edit_Callback(hObject, eventdata, handles)
% hObject    handle to alatt_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alatt_edit as text
%        str2double(get(hObject,'String')) returns contents of alatt_edit as a double


% --- Executes during object creation, after setting all properties.
function alatt_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alatt_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function angdeg_edit_Callback(hObject, eventdata, handles)
% hObject    handle to angdeg_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of angdeg_edit as text
%        str2double(get(hObject,'String')) returns contents of angdeg_edit as a double


% --- Executes during object creation, after setting all properties.
function angdeg_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to angdeg_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on button press in calc_pushbutton.
function calc_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to calc_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Clear error message
set(handles.message_text,'String','');
guidata(gcbo,handles);
drawnow;

u=get(handles.u_edit,'String');
v=get(handles.v_edit,'String');
ei=get(handles.ei_edit,'String');
eps=get(handles.eps_edit,'String');
psimin=get(handles.psimin_edit,'String');
psimax=get(handles.psimax_edit,'String');
alatt=get(handles.alatt_edit,'String');
angdeg=get(handles.angdeg_edit,'String');

if isempty(u) || isempty(v) || isempty(ei) || isempty(eps) || ...
        isempty(psimin) || isempty(psimax)
    set(handles.message_text,'String','Error - see Matlab command window for details');
    disp('ERROR - Ensure you have given values for u, v, Ei, eps, psi min and psi max');
    guidata(gcbo,handles);
    drawnow;
    return;
else
    %must strip out square brackets, if user has inserted them:
    s1=strfind(u,'['); s2=strfind(u,']');
    if isempty(s1) && isempty(s2)
        unew=strread(u,'%f','delimiter',',');
        unew=unew';
    elseif ~isempty(s1) && ~isempty(s2)
        u=u(s1+1:s2-1);
        unew=strread(u,'%f','delimiter',',');
    else
        set(handles.message_text,'String','Error - see Matlab command window for details');
        disp('ERROR - Ensure u is of form a,b,c or [a,b,c]');
        guidata(gcbo,handles);
        drawnow;
        return;
    end
    s1=strfind(v,'['); s2=strfind(v,']');
    if isempty(s1) && isempty(s2)
        vnew=strread(v,'%f','delimiter',',');
        vnew=vnew';
    elseif ~isempty(s1) && ~isempty(s2)
        v=v(s1+1:s2-1);
        vnew=strread(v,'%f','delimiter',',');
    else
        set(handles.message_text,'String','Error - see Matlab command window for details');
        disp('ERROR - Ensure v is of form a,b,c or [a,b,c]');
        guidata(gcbo,handles);
        drawnow;
        return;
    end
    s1=strfind(alatt,'['); s2=strfind(alatt,']');
    if isempty(s1) && isempty(s2)
        alattnew=strread(alatt,'%f','delimiter',',');
        alattnew=alattnew';
    elseif ~isempty(s1) && ~isempty(s2)
        alatt=alatt(s1+1:s2-1);
        alattnew=strread(alatt,'%f','delimiter',',');
    else
        set(handles.message_text,'String','Error - see Matlab command window for details');
        disp('ERROR - Ensure lattice angles are of form a,b,c or [a,b,c]');
        guidata(gcbo,handles);
        drawnow;
        return;
    end
    s1=strfind(angdeg,'['); s2=strfind(angdeg,']');
    if isempty(s1) && isempty(s2)
        angdegnew=strread(angdeg,'%f','delimiter',',');
        angdegnew=angdegnew';
    elseif ~isempty(s1) && ~isempty(s2)
        angdeg=angdeg(s1+1:s2-1);
        angdegnew=strread(angdeg,'%f','delimiter',',');
    else
        set(handles.message_text,'String','Error - see Matlab command window for details');
        disp('ERROR - Ensure lattice angles are of form alpha,beta,gamma or [alpha,beta,gamma]');
        guidata(gcbo,handles);
        drawnow;
        return;
    end
end

try
    if ischar(unew)
        u=str2num(unew);
    else
        u=unew;
    end   
    if numel(u) ~=3
        disp_error('Ensure u have 3 elements');
        return;        
    end
    if ischar(vnew)
        v=str2num(vnew);
    else
        v=vnew;
    end
    if numel(v) ~=3
        disp_error('Ensure v have 3 elements');        
        return;        
    end
     
    ei=str2num(ei);
    if numel(ei) ~=1
        disp_error('Ensure Ei has 1 element');                
        return;        
    end
    
    eps=str2num(eps);
    psimin=str2num(psimin);
    psimax=str2num(psimax);
    
    if ischar(alattnew)
        alatt=str2num(alattnew);
    else
        alatt=alattnew;
    end
    if numel(alatt) ~=3
        disp_error('Ensure lattice have 3 elements');                        
        return;        
    end
    
    if ischar(angdegnew)
        angdeg=str2num(angdegnew);
    else
        angdeg=angdegnew;
    end
    if numel(angdeg) ~=3
        disp_error('Ensure angdeg have 3 elements');                                
        return;        
    end
    
    if  numel(eps)~=1 || numel(psimin)~=1 || numel(psimax)~=1 
        disp_error('eps, psi min and psi max have 1 element');                                        
        return;
    end    
catch
    disp_error('Ensure u, v, lattice, Ei, eps, psi min and psi max are all numeric');                                            
    return;
end

if eps>ei
    disp_error('Ensure eps is smaller than Ei');      
    return;
end

if isfield(handles,'detpar')
    detpar=handles.detpar;
else
    disp_error('Ensure a valid par file is selected and loaded');          
    return;
end

%If we get to this stage, then all of the inputs are OK, and we can
%proceed.
try
    [xcoords,ycoords,zcoords,pts]=...
        calc_coverage_from_detpars(ei,eps,psimin,psimax,detpar,u,v,alatt,angdeg);
catch
    disp_error('non-trivial error on execution of calculations. Check inputs carefully...');              
    return;
end

%Now make the plots:
axes(handles.axes1);
cla;%clear pre-existing plots on these axes
jj=jet(30);
counter=1;
xmin=zeros(1,30); xmax=xmin;
ymin=xmin; ymax=ymin;
for i=linspace(psimin,psimax,30)
    plot(handles.axes1,xcoords{counter},ycoords{counter},'Color',jj(counter,:));
    hold on;
    xmin(counter)=min(xcoords{counter}); xmax(counter)=max(xcoords{counter});
    ymin(counter)=min(ycoords{counter}); ymax(counter)=max(ycoords{counter});
    counter=counter+1;
end
xmax=max(xmax); xmin=min(xmin);
ymax=max(ymax); ymin=min(ymin);
myind=find(pts(:,1)<=xmax & pts(:,1)>=xmin & pts(:,2)<=ymax & pts(:,2)>=ymin);

set(gca,'DataAspectRatio',[1,1,1]);
grid on;
set(gca,'Layer','top');
hold on;
try
    plot(pts(myind,1),pts(myind,2),'ok','LineWidth',1,'MarkerSize',4);
catch
    %something went wrong - e.g. invalid lattice pars or angles
    disp_error('non-trivial error on execution of calculations. (suspected invalid lattice pars or angles) Check lattice inputs carefully...');                  
    return;
end
colormap jet
cbarlab=colorbar;
caxis([psimin,psimax]);
%axis tight
xlabel('Q // u [Ang^-^1]');
ylabel('Q // v [Ang^-^1]');
tt=title(['Ei=',num2str(ei),'meV, E=',num2str(eps),'meV, ',...
     num2str(psimin),'<psi<',num2str(psimax)]);
xlab=xlabel(cbarlab,'dataset psi vals');
xlabpos=get(xlab,'Position');
xlabpos(2)=psimax+0.08*abs(psimax-psimin);
set(xlab,'Position',xlabpos);

axes(handles.axes2);
cla;%clear pre-existing plots on these axes
jj=jet(30);
counter=1;
zmin=zeros(1,30); zmax=zmin;
ymin=zmin; ymax=ymin;
for i=linspace(psimin,psimax,30)
    plot(handles.axes2,ycoords{counter},zcoords{counter},'Color',jj(counter,:));
    hold on;
    zmin(counter)=min(zcoords{counter}); zmax(counter)=max(zcoords{counter});
    ymin(counter)=min(ycoords{counter}); ymax(counter)=max(ycoords{counter});
    counter=counter+1;
end
zmax=max(zmax); zmin=min(zmin);
ymax=max(ymax); ymin=min(ymin);
myind=find(pts(:,3)<=zmax & pts(:,3)>=zmin & pts(:,2)<=ymax & pts(:,2)>=ymin);

set(gca,'DataAspectRatio',[1,1,1]);
grid on;
set(gca,'Layer','top');
hold on;
plot(pts(myind,2),pts(myind,3),'ok','LineWidth',1,'MarkerSize',4);
colormap jet
colorbar
caxis([psimin,psimax]);
axis tight
xlabel('Q // v [Ang^-^1]');
ylabel('Q out of plane [Ang^-^1]');


axes(handles.axes3);
cla;%clear pre-existing plots on these axes
jj=jet(30);
counter=1;
zmin=zeros(1,30); zmax=zmin;
xmin=zmin; xmax=xmin;
for i=linspace(psimin,psimax,30)
    plot(handles.axes3,xcoords{counter},zcoords{counter},'Color',jj(counter,:));
    hold on;
    zmin(counter)=min(zcoords{counter}); zmax(counter)=max(zcoords{counter});
    xmin(counter)=min(xcoords{counter}); xmax(counter)=max(xcoords{counter});
    counter=counter+1;
end
zmax=max(zmax); zmin=min(zmin);
xmax=max(xmax); xmin=min(xmin);
myind=find(pts(:,3)<=zmax & pts(:,3)>=zmin & pts(:,1)<=xmax & pts(:,1)>=xmin);

set(gca,'DataAspectRatio',[1,1,1]);
grid on;
set(gca,'Layer','top');
hold on;
plot(pts(myind,1),pts(myind,3),'ok','LineWidth',1,'MarkerSize',4);
colormap jet
colorbar
caxis([psimin,psimax]);
axis tight
xlabel('Q // u [Ang^-^1]');
ylabel('Q out of plane [Ang^-^1]');

set(handles.message_text,'String','Calculation performed successfully');
guidata(gcbo,handles);
drawnow;

function disp_error(err_code)
disp(['ERROR: ',err_code]);
set(handles.message_text,'String','Error - see Matlab command window for details');
guidata(gcbo,handles);
drawnow;


