function nifti4d_viewer(action,varargin)
% Tool for reviewing time series MRI data
% FORMAT nifti4d_viewer
% FORMAT nifti4d_viewer('Display',image_fname[,realign_param_fname])
%
% nifti4d_viewer is an interactive tool to review time series MRI data
% (EPI or DTI). Similar to FSLview/eyes, time series MRI data is displayed
% like a movie, allowing quick review of whole time series. Additionally, 
% using realignment parameters ('rp_*.txt'), this tool automatically 
% calculate frame-wise displacement (Power, 2012, Neuroimage), and display
% on the same screen.
% 
% How to use
% Enter the following command on the command window.
%
%    nifti4d_viewer
%
% Interactive GUI (spm_select) appears to specify your image. Optionally
% you can specify a head motion parameter file ('rp_*.txt').
% To implement in a script, you can also include path of MRI time series
% and head motion parameter file (optional), as follows.
%
%    nifti4d_viewer('Display',image_fname[,realign_param_fname])
%
% If you wish to redraw the display panel, enter
%
%    nifti4d_viewer('Redraw')
%
%
%  nifti4d_viewer Ver 0.20
%  @ Written by Yosuke Morishima, Jan 25, 2020 @
%  @ Last updated by Yosuke Morishima, Jan 29, 2020 @ Ver 0.20


global img
if ~nargin, action = 'Init';
    p= spm_select(Inf,'any','Select single 4D NIFTI image file, no need to expand',[],pwd,'^.*\.nii$');
    pth=spm_fileparts(p(1,:));
    p_rp= spm_select([0 1],'any','Select Head Motion file',[],pth,'^rp.*\.txt$');
elseif strcmp(lower(action),'display') && nargin >=2
        p=varargin{1};
    if strcmp(lower(action),'display') && nargin ==3
        p_rp=varargin{2};
    end
end

switch lower(action)
    case {'init','display'}
        disp('Loading image files...');
        % load files
        vol= spm_vol(p);
        nvol=numel(vol);

        % Calculate frame wise_displacement
        if isempty(p_rp)==0
            rp = load(p_rp); 
            if size(rp,1) ~= nvol
                error('Realign parameter and image files do not match!')
            end
            d = rp(:,1:3); r = rp(:,4:6);
            img.fd=[0;sum(abs(diff(d,1,1)),2)+50*pi*sum(abs(diff(r,1,1)),2)/180]; % append 0 at 1st vol
            img.rp=rp;
            img.p_rp=p_rp;
        else
            img.fd=zeros(nvol,1);
        end
        % setup variables
        img.xyz_dim= vol(1).dim;
        try 
            img.Y = spm_read_vols(vol);
        catch
            for i = 1:numel(vol)
                img.Y(:,:,:,i) = spm_read_vols(vol(i));
            end
        end
        img.vol=vol;
        img.nvol=numel(vol);
        img.curr_vol=1;
        init_display; % setup display figure
    case 'redraw'
        try
            close(img.handles.fg)
        catch
        end
        init_display;
        
    case 'scrub_vol'
        rm_handles=open_input_gui;
        rm_handles=remove_vols(rm_handles);
        try
            close(img.handles.fg)
        catch
        end
        nifti4d_viewer('Display',rm_handles.p,rm_handles.p_rp);
       
    case 'single_vol' % Display single volume
        % prepare subplot
        h1=subplot('Position',[0.05 0.7 0.4 0.25]);
        h2=subplot('Position',[0.50 0.7 0.4 0.25]); 
        h3=subplot('Position',[0.05 0.4 0.4 0.25]);
        h4=subplot('Position',[0.50 0.4 0.4 0.25]);
        
        % Prepare variables
        i =img.curr_vol;
        fd = img.fd;
        Y = img.Y;
        xyz_dim=img.xyz_dim;
        
        % display current volume
        cdata1=rot90(squeeze(Y(:,round(xyz_dim(2)/2),:,i)));
        image(cdata1,'Parent',h1,'CDataMapping','scaled');
        set(h1,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);

        cdata2= fliplr(rot90(squeeze(Y(round(xyz_dim(1)/2),:,:,i))));
        image(cdata2,'Parent',h2,'CDataMapping','scaled');
        set(h2,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);

        cdata3=rot90(squeeze(Y(:,:,round(xyz_dim(3)/2),i)));
        image(cdata3,'Parent',h3,'CDataMapping','scaled');
        set(h3,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);

        % plot FD values
        hold(h4,'off');
        plot(fd,'b'); hold(h4,'on');
        plot(i,fd(i),'rx'); ylim([0 2]);
        title(sprintf('Framewise displacement'));
        uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[190 155 40 20].*img.WS,'String',sprintf('FD %2.2f',img.fd(img.curr_vol)),'FontWeight','bold')
        
    case 'move_to' % Display specified volume
        try
            i=get(img.handles.u3,'String');
            if isempty(i); i=img.curr_vol;end
            if ischar(i); i = str2num(i);end
        catch
        end
        % prepare variables
        if (i >img.nvol) || (i < 1)
            i = img.curr_vol;
            set(img.handles.u3,'String',img.curr_vol);
        end
        img.curr_vol=i;
        nifti4d_viewer('single_vol');
        
    case {'back','forward'} % Display specified volume
        if strcmp(action,'back') && (img.curr_vol>1)
            img.curr_vol=img.curr_vol-1;
        elseif strcmp(action,'forward') && (img.curr_vol<img.nvol)
            img.curr_vol=img.curr_vol+1;
        end
        nifti4d_viewer('single_vol');
        set(img.handles.u3,'String',img.curr_vol);

    case 'stop_movie' % Stop movie (doesn't work with Matlab2019)
        set(img.handles.u2,'UserData',1);
            
    case 'stream' % Display movie
        % prepare subplot
        h1=subplot('Position',[0.05 0.7 0.4 0.25]); 
        h2=subplot('Position',[0.50 0.7 0.4 0.25]); 
        h3=subplot('Position',[0.05 0.4 0.4 0.25]);
        h4=subplot('Position',[0.50 0.4 0.4 0.25]);
        
        % prepare variables
        fd = img.fd;
        Y = img.Y;
        xyz_dim=img.xyz_dim;
        nvol=img.nvol;
        
        % display stream
        for i = 1:nvol
            img.curr_vol=i;
            v2 = get(img.handles.u2,'UserData');
            if v2 % stop condition
                break;
            end      
            
            cdata1=rot90(squeeze(Y(:,round(xyz_dim(2)/2),:,i)));
            image(cdata1,'Parent',h1,'CDataMapping','scaled');
            set(h1,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);

            cdata2= fliplr(rot90(squeeze(Y(round(xyz_dim(1)/2),:,:,i))));
            image(cdata2,'Parent',h2,'CDataMapping','scaled');
            set(h2,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);

            cdata3=rot90(squeeze(Y(:,:,round(xyz_dim(3)/2),i)));
            image(cdata3,'Parent',h3,'CDataMapping','scaled');
            set(h3,'TickLength',[0 0],'XTickLabel',[],'YTickLabel',[],'DataAspectRatio',[1 1 1]);
            
            hold(h4,'off');
            plot(fd,'b'); hold(h4,'on');
            if i > 1; plot(i,fd(i-1),'rx'); end
            ylim([0 2])
            title(sprintf('Framewise displacement'));
            
            set(img.handles.u3,'String',img.curr_vol);
            uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[190 155 40 20].*img.WS,'String',sprintf('FD %2.2f',img.fd(i)),'FontWeight','bold')
            pause(0.03)
        end
        
        set(img.handles.u2,'UserData',0);
        img.curr_vol=i;
        set(img.handles.u3,'String',img.curr_vol);
        nifti4d_viewer('single_vol');
end

%
function init_display
global img
    % Prepare variables
    FS   = spm('FontSizes');
    Rect = spm('WinSize','Graphics');
    Rect(1) = Rect(1)+100;
    Rect(4) = Rect(4)-Rect(2)*5;
    Rect(2) = Rect(2)*4;
%     WS = spm('WinScale');
    WS=1;
    
    % Create display figure
    img.handles.fg    = figure('Name','NIFTI 4D Viewer','NumberTitle','off','Position', Rect,'Resize','off','Color','w','ColorMap',gray(64));
    i = img.curr_vol;

    % UI panel
    img.handles.u1 = uipanel(img.handles.fg,'Units','Pixels','Title','','Position',[40 25 500 250].*WS,'Tag','currVol', 'UserData', i);
    % File info
    uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[10  220 450 16].*WS,'String',sprintf('File: %s',spm_file(img.vol(1).fname,'filename')),'HorizontalAlignment','left');
    uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[10  200 450 16].*WS,'String',sprintf('Description: %s',img.vol(1).descrip),'HorizontalAlignment','left');
    
    % 4D stream buttons
    uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[5 55 90 20].*WS,'String','Movie',...
        'Callback','nifti4d_viewer(''stream'')','ToolTipString','View stream 4D image');
    img.handles.u2=uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[5 30 90 20].*WS,'String','Stop movie',...
            'Callback','nifti4d_viewer(''stop_movie'')','ToolTipString','Stop stream 4D image');
    set(img.handles.u2,'UserData',0);
    
    % Close botton        
    uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[5 5 90 20].*WS,'String','Close',...
        'Callback','close(''all'')','ToolTipString','Close viewer');
    
    % Current Volume, its FD value
    uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[5  155  100 20].*WS,'String','Current Volume:')
    uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[150  155  30 20].*WS,'String',sprintf('/ %d',img.nvol))
    u3=uicontrol('Parent',img.handles.u1,'Style','Edit','Position',[120 160 30 20].*WS,'String',img.curr_vol,'Callback','nifti4d_viewer(''move_to'')','ToolTipString','Enter volume to display');
    uicontrol('Parent',img.handles.u1,'Style','Text', 'Position',[190  155  40 20].*WS,'String',sprintf('FD %d',img.fd(img.curr_vol)))
    
    % Move volume
    uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[5 90 90 20].*WS,'String','Prev',...
            'Callback','nifti4d_viewer(''back'')','ToolTipString','1 volume backward','Tag','backward');
    uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[100 90 90 20].*WS,'String','Next',...
            'Callback','nifti4d_viewer(''forward'')','ToolTipString','1 volume forward','Tag','forward');

    % Scrubbing volumes
    uicontrol('Parent',img.handles.u1,'Style','Pushbutton','Position',[300 90 90 20].*WS,'String','Scrubbing',...
            'Callback','nifti4d_viewer(''scrub_vol'')','ToolTipString','Scrubbing volumes','Tag','scrubbing');
        

    % Store figure handles and data
    img.handles.u3=u3;
    img.curr_vol=1;
    img.WS=WS;
    nifti4d_viewer('single_vol');


function rm_handles=open_input_gui
% Specify volume numbers to scrub
global img
% Create input figure and obtain scrubbing criteria
    % Create display figure
    Rect2 = spm('WinSize','Graphic');
    Rect=[Rect2(1) Rect2(4)/2 500 300];
    fig    = figure('Name','Scrubbing volume specification','NumberTitle','off','Position',Rect ,'Resize','off','Color',[0.9 0.9 0.9],'MenuBar','none');
    fig.UserData.fname=img.vol(1).fname;
    u1 = uipanel(fig,'Units','Pixels','Title','','Position',[5 5 490 290]);

    % FD threshold value
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 235 250 25],'String','FD threshold (i.e. 0.5 or 1):', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 220 250 25],'String','(Enter 0, if FD criteria is not used)', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Edit','Position',[280 230 100 30],'String',0.5,'Tag','FD','Callback','fd_th=str2num(get(gcbo,''String''));');
    
    % Specified volumes
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 155 250 25],'String','Scrubbing Volume # (i.e. [25 91 .. 249]):', 'HorizontalAlignment','left') 
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 140 250 25],'String','(Keep empty or enter 0, if this is not used)', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Edit','Position',[280 150 100 30],'String',[],'Callback','selvol=get(gcbo,''String''); h=gcbf; h.UserData.selvol=str2num(selvol);');
    
    
    % Handle mat file
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 90 250 25],'String','Use previous criteria:', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 75 250 25],'String','(if scrb*.mat file is selected,', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Text', 'Position',[15 60 250 25],'String','other criterion will be ignored)', 'HorizontalAlignment','left')
    uicontrol('Parent',u1,'Style','Edit','Position',[280 75 100 30],'String',[],'tag', 'scrub_spec','Callback','scrbmat=get(gcbo,''String''); h=gcbf; h.UserData.scrbmat=scrbmat;');
    uicontrol('Parent',u1,'Style','Pushbutton','Position',[400 75 50 30],'String' ,'...', 'Callback',...
        'hfig=gcbf;udata=get(hfig,''UserData'');f=spm_select(1,''mat'',''Select Scrub parameter file'',[],spm_fileparts(udata.fname),''^scrb_param.*\.mat$'');h=findobj(''Tag'',''scrub_spec'');h.String=f;hfig=gcbf;hfig.UserData.scrbmat=f;');
    
    u2=uicontrol('Parent',u1,'Style','Pushbutton','Position',[400 25 50 30],'String' ,'OK','Tag','ok','Callback','h = findobj(''Tag'',''FD'');fd_th=str2num(get(h,''String'')); h=gcbf; h.UserData.fd_th=fd_th; set(gcbo,''UserData'',''ok'');');
    
    waitfor(u2,'UserData','ok')
    rm_handles=get(fig,'UserData');
    close(fig);
    
% Import re_handles mat file, if specified
    if isfield(rm_handles,'scrbmat')
        try
            load(rm_handles.scrbmat)
            return;
        catch
        end
    end

% Thresholded by FD value
    idx_fd = find(img.fd >rm_handles.fd_th)';

% Manually entered volume
    if isfield(rm_handles,'selvol')
        idx_sel =rm_handles.selvol;
    else
        idx_sel =[];
    end
    
% create rm_handles
    rm_idx=sort(unique([idx_sel,idx_fd]));
    if sum(rm_idx>img.nvol)>0
        rm_idx(rm_idx>img.nvol)=[];
        warning('Volume(s) specified exceeds total number of MRI volume.')
        warning('Those specified volumes are excluded for further processing.')
    end
    rm_handles.rm_idx=sort(unique([idx_sel,idx_fd]));
    [pth,f]=spm_fileparts(img.vol(1).fname);
    if length(f)>30; f=f(1:20);end
    formatOut = 'yyyy-mmm-dd-HHMM'; time_str=datestr(now,formatOut);
    mat_name=sprintf('scrb_param_%s_%s.mat',time_str,f);
    
    handle_path=fullfile(pth,mat_name);
    save(handle_path,'rm_handles');

function rm_handles=remove_vols(rm_handles)
% Scrubbing volumes
global img
    rm_idx=rm_handles.rm_idx;
    img.Y(:,:,:,rm_idx)=[];
    img.vol(rm_idx)=[];
    new_nvol=img.nvol-length(rm_idx);
    img.nvol=new_nvol;
    [pth,f,ext]=spm_fileparts(img.vol(1).fname);
    new_p=fullfile(pth,sprintf('scrb%s%s',f,ext));
    new_descrip=sprintf('scrub: %s',img.vol(1).descrip);

    % Update volume information, write scrubbed volumes
    for i=1:img.nvol
        img.vol(i).fname=new_p;
        img.vol(i).descrip=new_descrip;
        img.vol(i).n=[i 1];
        spm_write_vol(img.vol(i),img.Y(:,:,:,i));
    end
    % Write scrubbed realign parameter file if imported
    if isfield(img,'p_rp')
        img.rp(rm_idx,:)=[];
        img.fd(rm_idx,:)=[];
        [pth,f,ext]=spm_fileparts(img.p_rp);
        new_p_rp=fullfile(pth,sprintf('rpscrb_%s%s',f(3:end),ext));
        img.p_rp=new_p_rp;
        rp = img.rp;
        save(img.p_rp,'rp','-ascii')
    end
   
    % Update rm_handles to re-import data
    rm_handles.p=new_p;
    rm_handles.p_rp=new_p_rp;
    
    return