function[varout1,varout2,varout3]=plotem(inputfilename)

% function[varout1,varout2,varout3]=plotem(inputfilename)
% Function to plot eye movement data, and permit concurrent viewing
%	of events and spikes, for single or blocks of trials.
% INPUT:  filename, e.g. 'ds014a'.  Should be in quotes.
% LOADS:  <filename>.s, .index, .ras, .tim, .e1h, .e1v
% CALLS:  (expects to find in default paths or current directory)
%	  plotemdefaults.m, load_FooIndexRaster.m, regtimsamp.m,
%	  msacalg.m
% Written by Crista, 9/1/98.

%%%%% Setting Root Configuration %%%%%
set(0,'ShowHiddenHandles','on')

%%%%% Setting Default Variables %%%%%
ERROR=0;
varout1=[];varout2=[];varout3=[];
figid='plotem.m';

currpath=cd;
fxnpath='Z:\LabTools\Matlab\TEMPO_Analysis\PlotEM';
%fxnpath='E:\Users\Lab\Matlab\PlotEM';
eval(['cd ',fxnpath])

uitot=46;
defaultdeggap=3;
loadflg=0;defflg=0;calcflg=0;plotflg=0;
eventnames={'None';
	    'SIN_FPON';
	    'SIN_FIX';
	    'SIN_STON';
	    'SIN_STOFF';
	    'SIN_TRGON';
	    'SIN_TRGOFF';
	    'SIN_FPOFF';
	    'SIN_SAC';
	    'SIN_TRGAC';
	    'SIN_DTON';
	    'SIN_DTOFF';
	    'SIN_SACST';
	    'SIN_SACEN'};
varnames={'foo';
	  'index';
	  'raster1';
	  'raster2';
	  'emt';
	  'emh';
	  'emv';
	  'msac';
	  'pemt';
	  'pemh';
	  'pemv';
	  'pmsac';
	  'trlnums';
	  'eventnames';
	  'indexcols'};
fxnlabels={'sac stats';
	  'sac-trig avg u1';
	  'sac-trig avg u2'};
fxncalls={['[summarystats]'],['plotmsacstats(pmsac,pemt,pemh,pemv,pdatindex,filename)'];
	  ['[msacta,msactatimes,msaccount]'],['msactamaker(pmsac,pemt,sptimes1,[filename,'' (u1)''])'];
	  ['[msacta,msactatimes,msaccount]'],['msactamaker(pmsac,pemt,sptimes2,[filename,'' (u2)''])']};
uicolors=[.96 .57 .96;
	  .76 .54 1.0;
	  .65 .65 1.0;
	  .54 .76 1.0];
evcolors=[0 0 0;
	  0 .78 0;
	  0 0 .8];

%%%%% Checking Input %%%%%
if nargin<1;inputfilename=-1;end
if isempty(inputfilename);inputfilename=-1;end

if ischar(inputfilename)
	cbv=0;				% callback value = 0
else
	cbv=inputfilename;		% callback value
end

%%%%% Assessing Input Type %%%%%
if cbv <= 0				% if input is a string or empty

	%%%%% If Program Called Anew %%%%%
	if cbv == 0
		defflg=1;
		filename=inputfilename;
	elseif cbv == -1
		defflg=0;
		filename=[];
	end
	clear inputfilename
   
 
	%%%%% Creating Figure %%%%%
	figure('Units','inches','Position',[0.5 0.5 12.5 9])
	set(gcf,'Number','off','Name',figid)
	set(gcf,'DefaultAxesFontName','Palatino','DefaultAxesFontSize',8)
	set(gcf,'DefaultTextFontName','Palatino','DefaultTextFontSize',8)
	set(gcf,'DefaultAxesNextPlot','add','DefaultAxesUnits','inches')
	set(gcf,'DefaultAxesTickDir','out','DefaultUicontrolUnits','inches')
	set(gcf,'DefaultUicontrolFontName','Palatino','DefaultUicontrolFontSize',10)
	set(gcf,'PaperUnits','inches')
	set(gcf,'PaperPosition',[.25 .10 10.5 8],'PaperOrientation','landscape')
	set(gcf,'DefaultTextEraseMode','background','DefaultLineEraseMode','xor')
	set(gcf,'BackingStore','off')
		
	%%%%% Creating Header Axes %%%%%
	axes('Position',[.1 7.3 12.3 1.6],'XLim',[.1 12.4],'YLim',[7.3 8.9])
	axis('off')
	
	%%%%% Creating Text in Header %%%%%
	text('Position',[0 0],'String','foo','Visible','off')		% v(1)
	text('Position',[0 0],'String','datindex','Visible','off')	% v(2)
	text('Position',[0 0],'String','raster1','Visible','off')	% v(3)
	text('Position',[0 0],'String','raster2','Visible','off')	% v(4)
	text('Position',[0 0],'String','emt','Visible','off')		% v(5)
	text('Position',[0 0],'String','emh','Visible','off')		% v(6)
	text('Position',[0 0],'String','emv','Visible','off')		% v(7)
	text('Position',[0 0],'String','msac','Visible','off')		% v(8)
	text('Position',[0 0],'String','pemt','Visible','off')		% v(9)
	text('Position',[0 0],'String','pemh','Visible','off')		% v(10)
	text('Position',[0 0],'String','pemv','Visible','off')		% v(11)
	text('Position',[0 0],'String','pmsac','Visible','off')		% v(12)
	text('Position',[0 0],'String','trlnums','Visible','off')	% v(13)

	text('Position',[.15 8.90],'String','File Name','FontSize',10)		% v(14)
	text('Position',[.15 8.43],'String','Data Paths','FontSize',10)		% v(15)
	text('Position',[.15 7.96],'String','Indices Path','FontSize',10)	% v(16)
	text('Position',[.15 7.49],'String','Paradigm','FontSize',10)		% v(17)
	text('Position',[.25 7.26],'String','0','FontSize',10)			% v(18)
	text('Position',[1.45 8.90],'String','Truncate (at end)','FontSize',10)	% v(19)
	text('Position',[2.80 8.43],'String','Regularize Data','FontSize',10)	% v(20)
%%% didn't comment out next line because it throws off text object order
	text('Position',[2.80 10.10],'String','Msac Params','FontSize',10)	% v(21)
	text('Position',[4.19 8.28],'String','thrhigh','FontSize',10)		% v(22)
	text('Position',[4.19 7.99],'String','thrlow','FontSize',10)		% v(23)
	text('Position',[5.11 8.28],'String','mindur','FontSize',10)		% v(24)
	text('Position',[5.11 7.99],'String','minisi','FontSize',10)		% v(25)
	text('Position',[2.75 7.96],'String','convfilt1','FontSize',10)		% v(26)
	text('Position',[2.75 7.49],'String','convfilt2','FontSize',10)		% v(27)
	text('Position',[7.05 8.90],'String','Events','FontSize',10)		% v(28)
	text('Position',[9.15 8.90],'String','Show Foocol','FontSize',10)	% v(29)
	text('Position',[8.20 8.90],'String','Show Spikes','FontSize',10)	% v(30)
	text('Position',[11.60 8.43],'String','Axes Mode','FontSize',10)	% v(31)
	text('Position',[11.60 7.96],'String','Trials/Axes','FontSize',10)	% v(32)
	text('Position',[9.65 8.18],'String','Xmin','FontSize',10)		% v(33)
	text('Position',[9.65 7.89],'String','Xmax','FontSize',10)		% v(34)
	text('Position',[10.55 8.18],'String','Ymin','FontSize',10)		% v(35)
	text('Position',[10.55 7.89],'String','Ymax','FontSize',10)		% v(36)
	text('Position',[9.40 7.00],'String','Trial         of','FontSize',10)	% v(37)
	text('Position',[9.82 7.00],'String','0','FontSize',10)			% v(38)
	text('Position',[10.40 7.00],'String','0','FontSize',10)		% v(39)
	text('Position',[10.30 8.90],'String','Time Zero','FontSize',10)	% v(40)
	text('Position',[4.25 8.90],'String','Algset Name','FontSize',10)	% v(41)
	text('Position',[10.45 7.58],'String','deg gap','FontSize',10)		% v(42)
	text('Position',[5.70 8.90],'String','Select Foocol','FontSize',10)	% v(43)
	text('Position',[6.03 8.28],'String','fc min','FontSize',10)		% v(44)
	text('Position',[6.03 7.99],'String','fc max','FontSize',10)		% v(45)
	text('Position',[4.85 6.88],'String','theta','FontSize',10)		% v(46)
	text('Position',[6.53 6.88],'String','range','FontSize',10)		% v(47)
	text('Position',[8.08 6.88],'String','(degrees)','FontSize',8)		% v(48)
	text('Position',[2.80 8.90],'String','Truncate (at beg)','FontSize',10)	% v(49)
	%text('Position',[11 .1],'String','KEY:','FontSize',9)  % v(50)
	text('Position',[12.4 .16],'String','VERTICAL EYE POSITION','FontSize',9,'Color','m','HorizontalAlignment','right')
	text('Position',[12.4 .02],'String','HORIZONTAL EYE POSITION','FontSize',9,'Color','b','HorizontalAlignment','right')
	text('Position',[8.20 8.18],'String','Vert','FontSize',10)
	text('Position',[8.20 7.89],'String','Horz','FontSize',10)
	text('Position',[8.20 8.43],'String','Manual FP Offset','FontSize',10)
	
	%%%%% Creating Uicontrols %%%%%
	
	%%% u(1):  FILE NAME STRING FIELD
	uic(1) = uicontrol('Style','edit','Position',[.1 8.52 1.0 .28], ....
		'HorizontalAlignment','left','FontSize',12, ....
      'String',filename,'BackGroundColor',uicolors(1,:).^.4);
   
%	%%% u(2):  DATA PATH STRING FIELD
%	uicontrol('Style','edit','Position',[.1 8.05 2.5 .28], ....
%		'HorizontalAlignment','left','FontSize',12, ....
%		'BackGroundColor',uicolors(1,:).^.4)
% u(2) is no longer an input, only displays what is coded in plotemdefaults.m

%	s=[char(datapath(1))];
%	for x=2:size(datapath,2)
%		s=[s,'|',char(datapath(x))];
%	end
	
	%%% u(2):  DATA PATHS NAMES
	uic(2) = uicontrol('Style','popup','Position',[.1 8.05 2.5 .28], ....
		'String','none','BackGroundColor',uicolors(1,:).^.4)
				
	%%% u(3):  INDICES PATH STRING FIELD
	uic(3) = uicontrol('Style','edit','Position',[.1 7.58 2.5 .28], ....
		'HorizontalAlignment','left','FontSize',12, ....
		'BackGroundColor',uicolors(1,:).^.4)
		
	%%% u(4):  RELOAD DATA COMMAND
	uic(4) = uicontrol('Style','pushbutton','Position',[1.7 7.11 .75 .28],'String', ....
		'RELOAD','Callback','plotem(4);','FontWeight','bold', ....
		'BackGroundColor',uicolors(1,:))
	
	%%% u(5):  RELOAD DEFAULTS COMMAND
	uic(5) = uicontrol('Style','pushbutton','Position',[.8 7.11 .85 .28],'String', ....
		'DEFAULTS','Callback','plotem(5);','FontWeight','bold', ....
		'BackGroundColor',uicolors(1,:))
	
	s=[char(eventnames(1))];
	for x=2:size(eventnames,1)
		s=[s,'|',char(eventnames(x))];
	end

	%%% u(6):  TRUNCATE DATA AT STRING (at end)
	uic(6) = uicontrol('Style','popup','Position',[1.4 8.52 1.2 .28],'String',s, ....
		'BackGroundColor',uicolors(2,:).^.4)
	
	%%% u(7):  REGULARIZE DATA FLAG
	uic(7) = uicontrol('Style','popup','Position',[2.75 8.05 1.2 .28],'String', ....
		'don''t reg|reg whole 4 ms|reg part 4 ms|reg whole 2 ms|reg part 2 ms','BackGroundColor', ....
		uicolors(2,:).^.4)

	%%% u(8):  MSAC HIGH THRESHOLD VALUE FIELD
	uic(8) = uicontrol('Style','edit','Position',[4.64 8.14 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(9):  MSAC LOW THRESHOLD VALUE FIELD
	uic(9) = uicontrol('Style','edit','Position',[4.64 7.86 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(10):  MSAC MINIMUM DURATION VALUE FIELD
	uic(10) = uicontrol('Style','edit','Position',[5.57 8.14 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(11):  MSAC MINIMUM INTERSACCADE INTERVAL VALUE FIELD
	uic(11) = uicontrol('Style','edit','Position',[5.57 7.86 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(12):  MSAC CONVFILT1 VALUE FIELD
	uic(12) = uicontrol('Style','edit','Position',[2.75 7.58 3.22 .28], ....
		'HorizontalAlignment','left','FontSize',9, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(13):  MSAC CONVFILT2 VALUE FIELD
	uic(13) = uicontrol('Style','edit','Position',[2.75 7.11 3.22 .28], ....
		'HorizontalAlignment','left','FontSize',9, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(14):  RECALCULATE DATA COMMAND
	uic(14) = uicontrol('Style','pushbutton','Position',[6.15 7.11 .75 .28],'String', ....
		'RECALC','Callback','plotem(14);','FontWeight','bold', ....
		'BackGroundColor',uicolors(2,:))
		
	%%% u(15):  DISPLAY EVENT STRING (1st one)
	uic(15) = uicontrol('Style','popup','Position',[7.00 8.52 1.0 .28],'String',s, ....
		'BackGroundColor',uicolors(3,:).^.4,'ForeGroundColor',evcolors(1,:))

	%%% u(16):  DISPLAY EVENT STRING (2nd one)
	uic(16) = uicontrol('Style','popup','Position',[7.00 8.05 1.0 .28],'String',s, ....
		'BackGroundColor',uicolors(3,:).^.4,'ForeGroundColor',evcolors(2,:))

	%%% u(17):  DISPLAY EVENT STRING (3rd one)
	uic(17) = uicontrol('Style','popup','Position',[7.00 7.58 1.0 .28],'String',s, ....
		'BackGroundColor',uicolors(3,:).^.4,'ForeGroundColor',evcolors(3,:))
	
	%%% u(18):  SHOW FOO COLUMN VALUE
	uic(18) = uicontrol('Style','popup','Position',[9.1 8.52 1.0 .28],'String', ....
		'blank','BackGroundColor',uicolors(3,:).^.4)

	%%% u(19):  SHOW SPIKES FLAG
	uic(19) = uicontrol('Style','popup','Position',[8.15 8.52 .85 .28],'String', ....
		'no|yes','BackGroundColor',uicolors(3,:).^.4)

	%%% u(20):  AXES MODE SELECTOR
	uic(20) = uicontrol('Style','popup','Position',[11.55 8.05 .85 .28],'String', ....
		'1 trial|1 block|2 blocks|3 blocks','Value',3,'UserData',0, ....
		'BackGroundColor',uicolors(3,:).^.4)
	
	%%% u(21):  TRIALS/AXES SELECTOR
	uic(21) = uicontrol('Style','popup','Position',[11.55 7.58 .85 .28],'String', ....
		'1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20', ....
		'Value',8,'BackGroundColor',uicolors(3,:).^.4)
	
	%%% u(22):  XMIN MANUAL VALUE FIELD
	uic(22) = uicontrol('Style','edit','Position',[10.05 8.04 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(3,:).^.4)
		
	%%% u(23):  XMAX MANUAL VALUE FIELD
	uic(23) = uicontrol('Style','edit','Position',[10.05 7.76 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(3,:).^.4)
		
	%%% u(24):  YMIN MANUAL VALUE FIELD
	uic(24) = uicontrol('Style','edit','Position',[10.95 8.04 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(3,:).^.4)
		
	%%% u(25):  YMAX MANUAL VALUE FIELD
	uic(25) = uicontrol('Style','edit','Position',[10.95 7.76 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(3,:).^.4)
		
	%%% u(26):  NEXT TRIAL SLIDER SELECTOR
	uic(26) = uicontrol('Style','slider','Position',[7.85 7.11 4.55 .28],'Min',1, ....
		'Max',2,'Value',1,'Callback','plotem(26);','BackGroundColor', ....
		uicolors(3,:).^.4)

	%%% u(27):  REPLOT DATA COMMAND
	uic(27) = uicontrol('Style','pushbutton','Position',[7.00 7.11 .75 .28], ....
		'String','REPLOT','Callback','plotem(27);','FontWeight', ....
		'bold','BackGroundColor',uicolors(3,:))
		
	%%% u(28):  BACK COMMAND
	uic(28) = uicontrol('Style','pushbutton','Position',[8.35 7.44 .75 .28], ....
		'String','BACK','Callback','plotem(28);','FontWeight', ....
		'bold','BackGroundColor',uicolors(3,:))
	
	%%% u(29):  NEXT COMMAND
	uic(29) = uicontrol('Style','pushbutton','Position',[9.35 7.44 .75 .28], ....
		'String','NEXT','Callback','plotem(29);','FontWeight', ....
		'bold','BackGroundColor',uicolors(3,:))
	
	%%% u(30):  TIME ZERO SELECTOR
	uic(30) = uicontrol('Style','popup','Position',[10.25 8.52 1.2 .28],'String', ....
		s,'BackGroundColor',uicolors(3,:).^.4)
		
	%%% u(31):  DEGREE GAP BETWEEN TRIALS SELECTOR
	uic(31) = uicontrol('Style','edit','Position',[10.95 7.44 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(3,:).^.4)
	
	%%% u(32):  MSAC ALGORITHM SET NAME
	uic(32) = uicontrol('Style','edit','Position',[4.20 8.52 1.2 .28], ....
		'HorizontalAlignment','left','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	s=[char(varnames(1))];
	for x=2:size(varnames,1)
		s=[s,'|',char(varnames(x))];
	end

	%%% u(33):  OUTPUT VARIABLE NAME
	uic(33) = uicontrol('Style','popup','Position',[.1 6.74 1 .28],'String',s, ....
		'Value',1,'Callback','plotem(33);','BackGroundColor', ....
		uicolors(4,:).^.4)

	%%% u(34):  OUTPUT VARIABLE COMMAND
	uic(34) = uicontrol('Style','pushbutton','Position',[1.3 6.74 .9 .28],'String', ....
		'OUTPUT','Callback',[varnames{1},'=plotem(34);'], ....
		'FontWeight','bold','BackGroundColor',uicolors(4,:))

	s=[char(fxnlabels(1))];
	for x=2:size(fxnlabels,1)
		s=[s,'|',char(fxnlabels(x))];
	end

	%%% u(35):  FUNCTION NAME
	uic(35) = uicontrol('Style','popup','Position',[2.4 6.74 1.2 .28],'String',s, ....
		'Value',1,'Callback','plotem(35);','BackGroundColor', ....
		uicolors(4,:).^.4)

	%%% u(36):  FUNCTION COMMAND
	uic(36) = uicontrol('Style','pushbutton','Position',[3.8 6.74 .9 .28],'String', ....
		'FUNCTION','Callback',[fxncalls{1},'=plotem(36);'], ....
		'FontWeight','bold','BackGroundColor',uicolors(4,:))

	%%% u(37):  SELECT FOO COLUMN
	uic(37) = uicontrol('Style','popup','Position',[5.65 8.52 1.2 .28],'String', ....
		'blank','BackGroundColor',uicolors(2,:).^.4)

	%%% u(38):  CRITERION MINIMUM FOR SELECT FOOCOL
	uic(38) = uicontrol('Style','edit','Position',[6.50 8.14 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(39):  CRITERION MAXIMUM FOR SELECT FOOCOL
	uic(39) = uicontrol('Style','edit','Position',[6.50 7.86 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)

	%%% u(40):  CRITERION THETA FOR WEEDING OUT MICROSACCADES
	uic(40) = uicontrol('Style','edit','Position',[5.27 6.74 1.0 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(41):  CRITERION RANGE FOR WEEDING OUT MICROSACCADES
	uic(41) = uicontrol('Style','edit','Position',[7.00 6.74 1.0 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)

	s=[char(eventnames(1))];
	for x=2:size(eventnames,1)
		s=[s,'|',char(eventnames(x))];
	end

	%%% u(42):  TRUNCATE DATA AT STRING (at beg)
	uic(42) = uicontrol('Style','popup','Position',[2.75 8.52 1.2 .28],'String',s, ....
		'BackGroundColor',uicolors(2,:).^.4)
	
	%%% u(43):  SAVE MSAC FILE
	uic(43) = uicontrol('Style','pushbutton','Position',[11.35 6.74 1.05 .28],'String', ....
		'save sac file','Callback','plotem(43);','BackGroundColor',uicolors(4,:))

	%%% u(44):  MANUAL FP OFFSET VERTICAL
	uic(44) = uicontrol('Style','edit','Position',[8.60 8.04 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)
		
	%%% u(45):  MANUAL FP OFFSET HORIZONTAL
	uic(45) = uicontrol('Style','edit','Position',[8.60 7.76 .4 .28], ....
		'HorizontalAlignment','center','FontSize',12, ....
		'BackGroundColor',uicolors(2,:).^.4)

	%%% u(uitot):  QUIT COMMAND
	uic(uitot) = uicontrol('Style','pushbutton','Position',[11.65 8.52 .75 .28], ....
		'String','QUIT','Callback',['plotem(',num2str(uitot),');'], ....
		'FontWeight','bold')
   
	clear s
   
   %temp = uic(1);   
	
	%%%%% Getting Object Handles %%%%%
   fc=get(gcf,'children'); 
    fc 
    uic'
   fc=sort(fc);
   u=fc(2:uitot+1);
    fc 
    uic'
   v=get(fc(1),'children');v=sort(v);v=v(2:length(v));
  
 
elseif cbv>0

	%%%%% If Program Called As Callback %%%%%
	if isempty(get(0,'children'))		% if there is no figure
		disp('error:  callback without a figure')
		ERROR=1;
	end
	if strcmp(get(gcf,'Name'),figid)~=1	% if it's the wrong figure
		disp('error:  callback from wrong figure')
		ERROR=1;
	end
	
	if ERROR == 0

		%%%%% Getting Object Handles %%%%%
		fc=get(gcf,'children');fc=sort(fc);
		u=fc(2:uitot+1);
		v=get(fc(1),'children');v=sort(v);v=v(2:length(v));
		
		%%%%% Evaluating Primary Callbacks %%%%%
		if cbv == 4
			loadflg=1;
		elseif cbv == 5
			defflg=1;
		elseif cbv == 14
			calcflg=1;
		elseif cbv == 27
			plotflg=1;
		end
	end
end

if defflg == 1;loadflg=1;end
if loadflg == 1;calcflg=1;end
if calcflg == 1;plotflg=1;end


if defflg & ERROR==0

	filename=get(u(u ==uic(1)),'String');
	if isempty(filename)
		disp('error in defaults:  no filename specified')
		ERROR=1;
	else
	
		%%%%% Loading Default Parameters %%%%%
		disp('loading defaults')

		plotemdefaults
		
		s=[char(datapath(1))];
		for x=2:size(datapath,2)
			s=[s,'|',char(datapath(x))];
		end
		
		set(u(u == uic(2)),'String',s,'UserData',datapath)
		set(u(u == uic(3)),'String',indpath)
		if ((regflg+1>=get(u(u == uic(7)),'Min')) & (regflg+1<=get(u(u == uic(7)),'Max')))
			set(u(u == uic(7)),'Value',regflg+1)
		else
			disp('error in defaults:  invalid regflg')
		end

		truncatecol=0;
		for x=1:size(eventnames,1)
			if strcmp(truncatestring,char(eventnames(x)))
				truncatecol=x;
			end
		end
		if truncatecol>0
			set(u(u == uic(6)),'Value',truncatecol)
		else
			disp('error in defaults:  invalid truncatestring')
		end

		truncatecol2=0;
		for x=1:size(eventnames,1)
			if strcmp(truncatestring2,char(eventnames(x)))
				truncatecol2=x;
			end
		end
		if truncatecol2>0
			set(u(u == uic(42)),'Value',truncatecol2)
		else
			disp('error in defaults:  invalid truncatestring2')
		end

		tzerovalue=0;
		for x=1:size(eventnames,1)
			if strcmp(tzerostring,char(eventnames(x)))
				tzerovalue=x;
			end
		end
		if tzerovalue>0
			set(u(u == uic(30)),'Value',tzerovalue)
		else
			disp('error in defaults:  invalid tzerostring')
		end
		if isempty(defaulttrlsperax);defaulttrlsperax=0;end
		if (defaulttrlsperax>=1 & defaulttrlsperax<=get(u(u == uic(21)),'Max'))
			set(u(u == uic(21)),'Value',defaulttrlsperax)
		else
			disp('error in defaults:  invalid defaulttrlsperax')
		end
		if isempty(defaultaxesmode);axesmode=0;end
		if (defaultaxesmode>=1 & defaultaxesmode<=get(u(u == uic(20)),'Max'))
			set(u(u == uic(20)),'Value',defaultaxesmode)
		else
			disp('error in defaults:  invalid defaultaxesmode')
		end
		set(u(u == uic(32)),'UserData',algsetpath)
		set(u(u == uic(32)),'String',algsetname)
		
		clear datapath indpath regflg truncatestring truncatecol x
	
	end
end


if loadflg & ERROR==0
   
   %get(u(1))
	filename=get(u(u == uic(1)),'String')
	%filename='rd029a';
	if isempty(filename)
		disp('error in loading:  no filename specified')
		ERROR=1;
	else

		%%%%% Loading Data %%%%%
		disp('loading data')
		
		foo=[];datindex=[];raster1=[];raster2=[];emt=[];emh=[];emv=[];
		paradigm=[];fpxstring=[];fpystring=[];

		plotemdefaults
		datapath=get(u(u == uic(2)),'UserData');
		indpath=get(u(u == uic(3)),'String');
	
		for dpi=1:size(datapath,2)
			currdatapath = char(datapath(dpi));
			if (isempty(foo) & exist([currdatapath,'/',filename,'.s'])==2)
				[foo,datindex,raster1]=load_FooIndexRaster(filename,currdatapath);
			end
			if (isempty(foo) & exist([currdatapath,'/',filename,'1.s'])==2)
				[foo,datindex,raster1]=load_FooIndexRaster([filename,'1'],currdatapath);
			end
			if (isempty(raster2) & exist([currdatapath,'/',filename,'2.s'])==2)
				[foo,datindex,raster2]=load_FooIndexRaster([filename,'2'],currdatapath);
			end
			if (isempty(emt) & exist([currdatapath,'/',filename,'.tim'])==2)
				eval(['load ',currdatapath,'/',filename,'.tim'])
				eval(['emt=',filename,';'])
			end
			if (isempty(emh) & exist([currdatapath,'/',filename,'.e1h'])==2)
				eval(['load ',currdatapath,'/',filename,'.e1h'])
				eval(['emh=',filename,'./40;'])
			end
			if (isempty(emv) & exist([currdatapath,'/',filename,'.e1v'])==2)
				eval(['load ',currdatapath,'/',filename,'.e1v'])
				eval(['emv=',filename,'./40;'])
			end
		end

		% Data loading error checks
  
		if isempty(foo)
			disp('error in loading: .s file not found')
			ERROR=1;
		end
		if isempty(emt)
			disp('error in loading: .tim file not found')
			ERROR=1;
		end      
		if isempty(emh)
			disp('error in loading: .e1h file not found')
			ERROR=1;
		end      
		if isempty(emv)
			disp('error in loading: .e1v file not found')
			ERROR=1;
		end  
		    
		eval(['clear ',filename])

	end
	
	if size(emt,1)~=size(datindex,1)
		disp('warning:  mismatch in number of trials in .index and .emt files')
	end
		
	if ERROR==0
		
		%%%%% Removing Redundant Data Points %%%%%
		trltot=size(emt,1);
		newemt=ones(trltot,size(emt,2))*nan;
		newemh=ones(trltot,size(emt,2))*nan;
		newemv=ones(trltot,size(emt,2))*nan;
		for trl=1:trltot
			emtdat=emt(trl,emt(trl,:)~=0);
			emhdat=emh(trl,emt(trl,:)~=0);
			emvdat=emv(trl,emt(trl,:)~=0);
			t=[1 diff(emtdat)];
			tkeep=find(t~=0);
			emtdat=emtdat(tkeep);
			emhdat=emhdat(tkeep);
			emvdat=emvdat(tkeep);
			newemt(trl,1:length(emtdat))=emtdat;
			newemh(trl,1:length(emtdat))=emhdat;
			newemv(trl,1:length(emtdat))=emvdat;
		end
		clear emhdat emvdat emtdat t tkeep trltot trl
		
		%%%%% Removing Extra Zeros %%%%%
		x=nansum(newemt);
		y=size(newemt,2);
		while isnan(x(y));y=y-1;end
		newemt=newemt(:,1:y);
		newemh=newemh(:,1:y);
		newemv=newemv(:,1:y);
		clear x y
	
		%%%%% Reassigning Variables %%%%%
		emt=newemt;clear newemt
		emh=newemh;clear newemh
		emv=newemv;clear newemv

		%%%%% Get Paradigm Number and FP Coordinates %%%%%
		for dpi=1:length(datapath)
			fid=fopen([char(datapath(dpi)),'/',filename,'.s']);
			if (fid == -1)
				fid=fopen([char(datapath(dpi)),'/',filename,'1.s']);
			end
		end
		if fid==-1
			disp('error in loading:  cannot open .s file')
		else
			index=0;fpx=[];fpy=[];
			while index==0
				line=fgets(fid);
				if line==-1;index=1;end
				if length(line)>8
					index=strcmp(line(1:8),'paradigm');
					if index==1
						paradigm=str2num(line(10:length(line)));
					end
				end
			end
			if isempty(paradigm)
				disp('error in loading:  no paradigm number found')
			else
			
				%%% Kluge for GregH's data
				if paradigm==502
					if ~isempty(raster1)
						raster1=raster1(:,3:size(raster1,2));
					end
					if ~isempty(raster2)
						raster2=raster2(:,3:size(raster2,2));
					end
				end

				set(v(18),'String',num2str(paradigm))
				if exist(['fpstrings',num2str(paradigm)])~=1
					disp('warning in loading:  default fp strings not found for this paradigm')
					disp('fixation point values of x=0, y=0 will be used.')
					fpx=0;fpy=0;
				else									
					eval(['fpstrings=fpstrings',num2str(paradigm),';'])

					if isempty(fpstrings)
						disp('warning in loading:  default fp strings not found for this paradigm')
						disp('fixation point values of x=0, y=0 will be used.')
						fpx=0;fpy=0;
					else

					fpxstring=char(fpstrings(1));
					fpystring=char(fpstrings(2));
					index=0;
					while index==0
						line=fgets(fid);
						if line==-1;index=1;end
						if length(line)>length(fpxstring)
							index=strcmp(line(1:length(fpxstring)),fpxstring);
							if index==1
								fpx=str2num(line(length(fpxstring)+1:length(line)))/10;
								if paradigm==363;fpx=fpx*(-1);end		% kluge
								if paradigm==364;fpx=fpx*(-1);end
							end
							index=0;
						end
						if length(line)>length(fpystring)
							index=strcmp(line(1:length(fpystring)),fpystring);
							if index==1
								fpy=str2num(line(length(fpystring)+1:length(line)))/10;
							end
							index=0;
						end
						if ~isempty(fpx) & ~isempty(fpy)
							index=1;
						end
					end
					
					set(u(u == uic(44)),'String',num2str(fpy))
					set(u(u == uic(45)),'String',num2str(fpx))
					
					%if isempty(fpx) | isempty(fpy)
					%	disp('error in loading:  fpx or fpy never found')
					%else
					%
					%	%%%%% Normalizing Data %%%%%
					%	emh=emh-fpx;
					%	emv=emv-fpy;
					%
					%end
					
					end
				end
			end
			fclose(fid);clear fid
			clear index fpx fpy fpxstring fpystring line fpstrings
		end
	end	
							
	%%%%% Storing Data %%%%%
	set(v(1),'UserData',foo)
	set(v(2),'UserData',datindex)
	set(v(3),'UserData',raster1)
	set(v(4),'UserData',raster2)
	set(v(5),'UserData',emt)
	set(v(6),'UserData',emh)
	set(v(7),'UserData',emv)
	
	%%%%% Loading Indices %%%%%
	if ~isempty(paradigm)
		if exist([indpath,'/indices_',num2str(paradigm),'.m'])==2
			eval(['cd ',indpath])
			eval(['indices_',num2str(paradigm),';'])
			eval(['cd ',fxnpath])
		
			s=who('SIN_*');
			indexcols=zeros(size(eventnames,1),1);
			for x=1:size(s,1)
				eval(['sinval=',char(s(x)),';'])
				if ~isempty(sinval)
					for y=2:size(eventnames,1)
						if strcmp(char(s(x)),char(eventnames(y)))
							indexcols(y)=sinval;
						end
					end
				end
			end
			set(u(u == uic(6)),'UserData',indexcols)
			set(u(u == uic(15)),'UserData',indexcols)
			set(u(u == uic(16)),'UserData',indexcols)
			set(u(u == uic(17)),'UserData',indexcols)
			clear sinval x s y indexcols
		
			s=who('I_*');
			foonames=cell(size(s,1)+1,1);
			foonames(1)={'None'};
			foocols=zeros(size(s,1)+1,1);
			for x=1:size(s,1)
				eval(['ival=',char(s(x)),';'])
				if ~isempty(ival)
					if ival>0
						foonames(ival+1)=s(x);
						foocols(ival+1)=ival;
					end
				end
			end
			foocheck=[1;find(foocols)];
			foonames=foonames(foocheck);foocols=foocols(foocheck);
			
			foostring=[char(foonames(1))];
			for x=2:size(foonames,1)
				foostring=[foostring,'|',char(foonames(x))];
			end
			set(u(u == uic(18)),'String',foostring,'UserData',foocols)
			set(u(u == uic(37)),'String',foostring,'UserData',foocols)
			clear ival x s foonames foostring
		else
			disp('error in loading:  indices not available')
		end		
	else
		disp('error in loading:  indices not available')
	end
	clear paradigm foo datindex raster1 raster2 emt emh emv fpxstring fpystring
end

if calcflg & ERROR==0

	%%%%% Recalculating Data For Plotting %%%%%
	disp('calculating data')
	
	foo=get(v(1),'UserData');
	datindex=get(v(2),'UserData');
	raster1=get(v(3),'UserData');
	raster2=get(v(4),'UserData');
	emt=get(v(5),'UserData');
	emh=get(v(6),'UserData');
	emv=get(v(7),'UserData');
	msac=[];
	pemt=emt;
	fpy=str2num(get(u(u == uic(44)),'String'));
	fpx=str2num(get(u(u == uic(45)),'String'));
	if isempty(fpy);fpy=0;end
	if isempty(fpx);fpx=0;end
	pemh=emh-fpx;
	pemv=emv-fpy;
	pmsac=[];
	trlnums=[];
	algsetpath=get(u(u == uic(32)),'UserData');
	algsetname=get(u(u == uic(32)),'String');
	
	indexcols=get(u(u == uic(6)),'UserData');
	trunflg=indexcols(get(u(u == uic(6)),'Value'));
	trunflg2=indexcols(get(u(u == uic(42)),'Value'));
	clear indexcols
	
	regflg=get(u(u == uic(7)),'Value')-1;
	if ~isempty(algsetname)
		msacflg=1;
	else
		msacflg=~isempty(get(u(u == uic(8)),'String'));
	end
	
	foocols=get(u(u == uic(37)),'UserData');
	cullcol=foocols(get(u(u == uic(37)),'Value'));
	cullmin=str2num(get(u(u == uic(38)),'String'));
	cullmax=str2num(get(u(u == uic(39)),'String'));

	msactheta=str2num(get(u(u == uic(40)),'String'));
	msacrange=str2num(get(u(u == uic(41)),'String'));
	
	if cullcol~=0				% if subset of trials is desired
		trlnums=[1:size(emt,1)]';
		if isempty(cullmin);cullmin=min(foo(:,cullcol));end
		if isempty(cullmax);cullmax=max(foo(:,cullcol));end
		testfoo=find(foo(:,cullcol)>=cullmin & foo(:,cullcol)<=cullmax);
		trlnums=trlnums(testfoo);
		pemt=pemt(trlnums,:);
		pemh=pemh(trlnums,:);
		pemv=pemv(trlnums,:);
	else
		trlnums=[1:size(emt,1)]';
	end

	if trunflg

		if isempty(datindex)
			disp('error in calculating:  cannot truncate because .index file empty')
		else
		
			%%%%% Truncating Data %%%%%
			validvalues=datindex(trlnums,trunflg);
			dumcheck=nanmax(nanmax(pemt));
			dum=find(validvalues<0);validvalues(dum)=dumcheck;
			validtimes=validvalues*ones(1,size(pemt,2));
			validtimes=pemt<=validtimes;
			dum=find(validtimes==0);validtimes(dum)=nan;
			pemt=pemt.*validtimes;			% multiply invalid times by nans
			pemh=pemh.*validtimes;
			pemv=pemv.*validtimes;
			clear validvalues dumcheck dum validtimes
		
		end
		
	end

	if trunflg2

		if isempty(datindex)
			disp('error in calculating:  cannot truncate because .index file empty')
		else
		
			%%%%% Truncating Data %%%%%
			validvalues=datindex(trlnums,trunflg2);
			%%% dumcheck=nanmax(nanmax(pemt));
			dum=find(validvalues<0);validvalues(dum)=0;
			validtimes=validvalues*ones(1,size(pemt,2));
			validtimes=pemt>=validtimes;
			dum=find(validtimes==0);validtimes(dum)=nan;
			pemt=pemt.*validtimes;			% multiply invalid times by nans
			pemh=pemh.*validtimes;
			pemv=pemv.*validtimes;
			clear validvalues dumcheck dum validtimes
		
		end
		
	end

	if regflg

		%%%%% Regularizing Data %%%%%
		dispmode=0;padding=nan;
		if regflg==1
			testper=4;regmode=1;
		elseif regflg==2
			testper=4;regmode=2;
		elseif regflg==3
			testper=2;regmode=1;
		elseif regflg==4
			testper=2;regmode=2;
		end
		[pemtindex,ERROR2]=regtimsamp(pemt,testper,regmode,padding,dispmode);
		if ERROR2==0
			pemt=pemt.*pemtindex;
			pemh=pemh.*pemtindex;
			pemv=pemv.*pemtindex;
		else
			disp('error in calculating:  unable to regularize samples')
		end
		clear testper dispmode pemtindex
	
		%%%%% Removing Redundant Data Points %%%%%
		trltot=size(pemt,1);
		newemt=ones(trltot,size(pemt,2))*nan;
		newemh=ones(trltot,size(pemt,2))*nan;
		newemv=ones(trltot,size(pemt,2))*nan;
		for trl=1:trltot
			emtdat=pemt(trl,~isnan(pemt(trl,:)));
			emhdat=pemh(trl,~isnan(pemt(trl,:)));
			emvdat=pemv(trl,~isnan(pemt(trl,:)));
			t=[1 diff(emtdat)];
			tkeep=find(t~=0);
			emtdat=emtdat(tkeep);
			emhdat=emhdat(tkeep);
			emvdat=emvdat(tkeep);
			newemt(trl,1:length(emtdat))=emtdat;
			newemh(trl,1:length(emtdat))=emhdat;
			newemv(trl,1:length(emtdat))=emvdat;
		end
		clear emhdat emvdat emtdat t tkeep trltot trl
		
		%%%%% Removing Extra Zeros %%%%%
		x=nansum(newemt);
		y=size(newemt,2);
		while isnan(x(y));y=y-1;end
		newemt=newemt(:,1:y);
		newemh=newemh(:,1:y);
		newemv=newemv(:,1:y);
		clear x y
	
		%%%%% Reassigning Variables %%%%%
		pemt=newemt;clear newemt
		pemh=newemh;clear newemh
		pemv=newemv;clear newemv
		
	end
	
	if msacflg

		%%%%% Getting Microsaccades %%%%%
		algparams=[];
		if ~isempty(algsetname)
			if exist([algsetpath,'.mat'])~=2
				disp('error in calculating:  algset file not found')
			else
				eval(['load ',algsetpath])
				if exist([algsetname])~=1
					disp('error in calculating:  algset variable not found')
				else
					eval(['algparams=',algsetname,';'])
					set(u(u == uic(8)),'String',num2str(algparams{1}))
					set(u(u == uic(9)),'String',num2str(algparams{2}))
					set(u(u == uic(10)),'String',num2str(algparams{3}))
					set(u(u == uic(11)),'String',num2str(algparams{4}))
					set(u(u == uic(12)),'String',num2str(algparams{5}))
					set(u(u == uic(13)),'String',num2str(algparams{6}))
				end
			end
		end
		if isempty(algparams)
			algparams=cell(6,1);
			algparams{1}=str2num(get(u(u == uic(8)),'String'));
			algparams{2}=str2num(get(u(u == uic(9)),'String'));
			algparams{3}=str2num(get(u(u == uic(10)),'String'));
			algparams{4}=str2num(get(u(u == uic(11)),'String'));
			algparams{5}=str2num(get(u(u == uic(12)),'String'));
			algparams{6}=str2num(get(u(u == uic(13)),'String'));
		end
		padding=nan;
		msac=msacalg(pemt,pemh,pemv,algparams,padding);
		pmsac=msac;
	end

	if ~isempty(msactheta)
	
		msacparams=getMsacParams(msac,pemt,pemh,pemv);
		pmsac=weedsac(msac,pemt,msacparams,msactheta*(pi/180),msacrange*(pi/180));
		 
	end
	
	set(v(9),'UserData',pemt);
	set(v(10),'UserData',pemh);
	set(v(11),'UserData',pemv);
	set(v(8),'UserData',msac);
	set(v(12),'UserData',pmsac);
	set(v(13),'UserData',trlnums);
	clear pemt pemh pemv msac pmsac trlnums foo datindex raster1 raster2 emt emh emv trunflg trunflg2 regflg msacflg
	
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Evaluating Special Callbacks %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if cbv == 26

	%%%%% Updating Trial/Block Slider Bar %%%%%
	x=get(u(u == uic(26)),'Value');
	x=round(x);
	set(u(u == uic(26)),'Value',x);
	set(v(38),'String',num2str(x));
	clear x

end

if cbv == 28 | cbv == 29
	plotflg=1;
end

if cbv == 33
	varnum=get(u(u == uic(33)),'Value');
	set(u(u == uic(34)),'Callback',[varnames{varnum},'=plotem(34);'])
end

if cbv == 34
	varnum=get(u(u == uic(33)),'Value');
	if (varnum>=1 & varnum<=12)
		eval(['varout1=get(v(',num2str(varnum),'),''UserData'');'])
	else
		indexcols=get(u(u == uic(6)),'UserData');
		eval(['varout1=',varnames{varnum},';'])
	end
end

if cbv == 35
	fxnnum=get(u(u == uic(35)),'Value');
	set(u(u == uic(36)),'Callback',[fxncalls{fxnnum,1},'=plotem(36);'])
end

if cbv == 36
	fxnnum=get(u(u == uic(35)),'Value');
	if fxnnum==1
		pmsac=get(v(12),'UserData');
		pemt=get(v(9),'UserData');
		pemh=get(v(10),'UserData');
		pemv=get(v(11),'UserData');
		datindex=get(v(2),'UserData');
		trlnums=get(v(13),'UserData');
		pdatindex=datindex(trlnums,:);
		filename=get(u(u == uic(1)),'String');
		eval(['[varout1]=',fxncalls{fxnnum,2},';'])
	elseif (fxnnum==2 | fxnnum==3)
		pmsac=get(v(12),'UserData');
		pemt=get(v(9),'UserData');
		sptimes1=get(v(3),'UserData');
		sptimes2=get(v(4),'UserData');
		
		%%% CRISTA:  this is a quick fix; program should be rewritten more elegantly. %%%
		%%% CRISTA:  this code crashes if there are no spikes (sptimes is empty) %%%
		trlnums=get(v(13),'UserData');
		if ~isempty(sptimes1);sptimes1=sptimes1(trlnums,:);end
		if ~isempty(sptimes2);sptimes2=sptimes2(trlnums,:);end
		
		filename=get(u(u == uic(1)),'String');
		eval(['[varout1,varout2,varout3]=',fxncalls{fxnnum,2},';'])
	end		
end

%%% Save msac data to file. %%%
% filename.sac:  pmsac, trlnums, pemt, algparams

if cbv == 43
	pmsac=get(v(12),'UserData');
	trlnums=get(v(13),'UserData');
	pemt=get(v(9),'UserData');
	algparams=cell(6,1);
	algparams{1}=str2num(get(u(u == uic(8)),'String'));
	algparams{2}=str2num(get(u(u == uic(9)),'String'));
	algparams{3}=str2num(get(u(u == uic(10)),'String'));
	algparams{4}=str2num(get(u(u == uic(11)),'String'));
	algparams{5}=str2num(get(u(u == uic(12)),'String'));
	algparams{6}=str2num(get(u(u == uic(13)),'String'));
	filename=get(u(u == uic(1)),'String');
	datapath=get(u(u == uic(2)),'UserData');
	eval(['save ',char(datapath(1)),'/',filename,'sac pmsac trlnums pemt algparams'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Plotting Loop %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

if plotflg & ERROR==0
	
%%% CRISTA:  insert control for if pemt is empty (no trials selected) %%%

	foo=get(v(1),'UserData');
	datindex=get(v(2),'UserData');
	raster1=get(v(3),'UserData');
	raster2=get(v(4),'UserData');
	pemt=get(v(9),'UserData');
	pemh=get(v(10),'UserData');
	pemv=get(v(11),'UserData');
	pmsac=get(v(12),'UserData');
	trlnums=get(v(13),'UserData');
	if ~isempty(pmsac);msacst=(pmsac==1);else;msacst=[];end
	if ~isempty(pmsac);msacen=(pmsac==-1);else;msacend=[];end
	
	tottrl=size(pemt,1);
	trlsperax=get(u(u == uic(21)),'Value');
	axesmode=get(u(u == uic(20)),'Value');
	oldaxesmode=get(u(u == uic(20)),'UserData');
	totaxes=axesmode-1;if totaxes==0;totaxes=1;end
	
	%%%%% If Number of Data Axes Has Changed %%%%%
	if oldaxesmode ~= axesmode
		for x=uitot+2:length(fc)
			delete(fc(x))
		end
		if axesmode==1 | axesmode==2
			axes('Position',[.5 .5 11.5 6.2])
		elseif axesmode==3
			axes('Position',[.5 .5 5.5 6.2])
			axes('Position',[6.5 .5 5.5 6.2])
		elseif axesmode==4
			axes('Position',[.5 .5 3.5 6.2])
			axes('Position',[4.5 .5 3.5 6.2])
			axes('Position',[8.5 .5 3.5 6.2])
		end
		set(u(u == uic(20)),'UserData',axesmode)
		if axesmode==1
			set(v(37),'String','Trial         of')
		else
			set(v(37),'String','Block         of')		
		end	
	end
	
	fc=get(gcf,'children');fc=sort(fc);
	for x=uitot+2:length(fc)
		axes(fc(x))
		cla
	end
	
	%%%%% Resetting if AxesMode or TrlsPerAxes Have Changed %%%%%
	trlblk=get(u(u == uic(26)),'Value');
	if axesmode==1
		tottrlblk=tottrl;
	else
		tottrlblk=ceil(tottrl/(trlsperax*totaxes));
	end
	if trlblk>tottrlblk;trlblk=tottrlblk;end
	if tottrlblk>2
		set(u(u == uic(26)),'Value',trlblk,'Min',1,'Max',tottrlblk)
		set(u(u == uic(26)),'SliderStep',[1/(tottrlblk-1) 2/(tottrlblk-1)])
		if (2/(tottrlblk-1))<=.1;set(u(u == uic(26)),'SliderStep',[1/(tottrlblk-1) .1]);end
	elseif tottrlblk==2
		set(u(u == uic(26)),'Value',trlblk,'Min',1,'Max',tottrlblk)
		set(u(u == uic(26)),'SliderStep',[.75/(tottrlblk-1) 1/(tottrlblk-1)])
		if (2/(tottrlblk-1))<=.1;set(u(u == uic(26)),'SliderStep',[1/(tottrlblk-1) .1]);end
	else	
		set(u(u == uic(26)),'Value',1,'Min',.9,'Max',1.1)
		set(u(u == uic(26)),'SliderStep',[0 1])
	end
	set(v(38),'String',num2str(trlblk))
	set(v(39),'String',num2str(tottrlblk))
	
	if cbv==28
		if trlblk-1>=1
			trlblk=trlblk-1;
			set(u(u == uic(26)),'Value',trlblk)
			set(v(38),'String',num2str(trlblk))
		end
	end
	if cbv==29
		if trlblk+1<=tottrlblk
			trlblk=trlblk+1;
			set(u(u == uic(26)),'Value',trlblk)
			set(v(38),'String',num2str(trlblk))
		end
	end
	
	%%%%% Plotting Trial/Block of Data %%%%%
	indexcols=get(u(u == uic(15)),'UserData');
	e1col=indexcols(get(u(u == uic(15)),'Value'));
	e2col=indexcols(get(u(u == uic(16)),'Value'));
	e3col=indexcols(get(u(u == uic(17)),'Value'));
	
	foocols=get(u(u == uic(18)),'UserData');
	foocol=foocols(get(u(u == uic(18)),'Value'));
	
	spikflg=get(u(u == uic(19)),'Value')-1;
	msacflg=~isempty(get(u(u == uic(8)),'String'));
	
	tzerocol=indexcols(get(u(u == uic(30)),'Value'));
	if tzerocol~=0
		toffsets=datindex(trlnums,tzerocol);
		dum=find(toffsets<-1000);
		toffsets(dum)=0;
		if ~isempty(dum)
			disp('warning:  invalid event times detected')
			disp('   not all trials aligned properly')
		end
	else
		toffsets=zeros(tottrl,1);
	end
	
	manxmin=str2num(get(u(u == uic(22)),'String'));
	manxmax=str2num(get(u(u == uic(23)),'String'));
	if isempty(manxmin)
		xmin=nanmin([nanmin(pemt')']-toffsets);
		xmin=floor(xmin/100)*100;
	else
		xmin=manxmin;
	end
	if isempty(manxmax)
		xmax=nanmax([nanmax(pemt')']-toffsets);
		xmax=ceil(xmax/100)*100;
	else
		xmax=manxmax;
	end
	if xmax<=xmin;xmax=xmin+1;end	

	manymin=str2num(get(u(u == uic(24)),'String'));
	manymax=str2num(get(u(u == uic(25)),'String'));
	if isempty(manymin)
		ymin=-1;
	else
		ymin=manymin;
	end
	if isempty(manymax)
		ymax=1;
	else
		ymax=manymax;
	end
	if ymax<=ymin;ymax=ymin+1;end	

	deggap=str2num(get(u(u == uic(31)),'String'));
	if isempty(deggap)
		deggap=defaultdeggap;
	else
		if deggap<0
			disp('error in plotting:  invalid deg gap')
			deggap=defaultdeggap;
		end
	end
	
	for ax=1:totaxes
		axes(fc(uitot+1+ax))
		if axesmode==1
			ptrlnums=trlblk;trlplot=0;
		else
			trlstart=1+trlsperax*(ax-1)+(trlblk-1)*trlsperax*totaxes;
			trlend=trlstart+trlsperax-1;
			ptrlnums=[trlstart:trlend];
			if deggap~=1
				trlplot=ptrlnums+[0:(deggap-1):(deggap-1)*(trlsperax-1)];
			else
				trlplot=ptrlnums;
			end
		end
	
		for trlindex=1:length(ptrlnums)
			ptrlnum=ptrlnums(trlindex);
			if ptrlnum<=tottrl
				if ~isempty(pemt)
				
					%%%%% Plotting Eye Movements %%%%%
					x=find(~isnan(pemt(ptrlnum,:)));
					plot(pemt(ptrlnum,x)-toffsets(ptrlnum),pemh(ptrlnum,x)+trlplot(trlindex),'b-');
					plot(pemt(ptrlnum,x)-toffsets(ptrlnum),pemv(ptrlnum,x)+trlplot(trlindex),'m-');
					if axesmode==1
						title(['TRL  ',num2str(trlnums(ptrlnum))],'FontSize',10)
					else
						text('Position',[xmin trlplot(trlindex)],'String', ....
							['TRL ',num2str(trlnums(ptrlnum)),'  '],'HorizontalAlignment', ....
							'right')
					end
					
					%%%%% Plotting Microsaccades %%%%%
					if ~isempty(msacst)
						x=find(msacst(ptrlnum,:));
						if ~isempty(x)
							xdat=pemt(ptrlnum,x)-toffsets(ptrlnum);
							ydat=trlplot(trlindex);
							if axesmode==1
								plot([xdat;xdat],[ydat+10;ydat-10],'-','Color',[.6 .6 .6],'LineWidth',.2);
							else
								plot([xdat;xdat],[ydat-.55;ydat-.75],'-','Color',[.6 .6 .6],'LineWidth',.2);
							end
							x=find(msacen(ptrlnum,:));
							xdat=pemt(ptrlnum,x)-toffsets(ptrlnum);
							ydat=trlplot(trlindex);
							if axesmode==1
								plot([xdat;xdat],[ydat+10;ydat-10],'-','Color',[.6 .6 .6],'LineWidth',.2);
							else
								plot([xdat;xdat],[ydat-.55;ydat-.75],'-','Color',[.6 .6 .6],'LineWidth',.2);
							end
						end
					end
					
					%%%%% Plotting Events %%%%%
					if e1col~=0
						plot(datindex(trlnums(ptrlnum),e1col)-toffsets(ptrlnum), ....
							trlplot(trlindex)-1.2,'^','MarkerSize',5, ....
							'Color',evcolors(1,:))
					end
					if e2col~=0
						plot(datindex(trlnums(ptrlnum),e2col)-toffsets(ptrlnum), ....
							trlplot(trlindex)-1.2,'^','MarkerSize',5, ....
							'Color',evcolors(2,:))
					end
					if e3col~=0
						plot(datindex(trlnums(ptrlnum),e3col)-toffsets(ptrlnum), ....
							trlplot(trlindex)-1.2,'^','MarkerSize',5, ....
							'Color',evcolors(3,:))
					end
					if foocol~=0
						if axesmode==1
							title(['TRL  ',num2str(trlnums(ptrlnum)),'     FC:  ', ....
								num2str(foo(trlnums(ptrlnum),foocol))],'FontSize',10)
						else
							text('Position',[xmin trlplot(trlindex)-.4],'String', ....
							['FC:  ',num2str(foo(trlnums(ptrlnum),foocol)),'  '], ....
							'HorizontalAlignment','right')
						end
					end
					
					%%%%% Plotting Spikes %%%%%
					if spikflg
						if isempty(raster1)
							if ax==1 & trlindex==1
								disp('error in plotting:  raster1 not available')
							end
						else
							x=find(raster1(trlnums(ptrlnum),:)~=0);
							xdat=raster1(trlnums(ptrlnum),x)-toffsets(ptrlnum);
							ydat=trlplot(trlindex);
							if ~isempty(xdat)
								plot([xdat;xdat],[ydat-.8;ydat-1],'-','Color','k','LineWidth',.2)
							end
						end
						if ~isempty(raster2)
							x=find(raster2(trlnums(ptrlnum),:)~=0);
							xdat=raster2(trlnums(ptrlnum),x)-toffsets(ptrlnum);
							ydat=trlplot(trlindex);
							if ~isempty(xdat)
								plot([xdat;xdat],[ydat-1.1;ydat-1.3],'-','Color','k','LineWidth',.2)
							end
						end
					end
					
					%%%%% Plotting Degree Marks %%%%%
					if axesmode~=1
						if ptrlnum/2~=round(ptrlnum/2)
							plot([xmax xmax],[trlplot(trlindex)-.5 trlplot(trlindex)+.5],'k-','LineWidth',1)
						end
					end
					
					%%%%% Setting XLimits %%%%%
					set(gca,'XLim',[xmin xmax])
					if axesmode==1
						set(gca,'YLim',[ymin ymax],'YTick',[ymin:(ymax-ymin)/4:ymax])
					else
						set(gca,'YLim',[min(trlplot)-deggap max(trlplot)+deggap], ....
							'YTick',[min(trlplot)-deggap*2 max(trlplot)+deggap*2])
					end
					xlabel('msec')

					%%%%% Resetting Plotting Order %%%%%
					d=get(gca,'children');d=sort(d);
					set(gca,'children',d);
					
				end		% end if there's eye data
			end			% end if trial exists
		end				% end for each trial
	end
end

if cbv==uitot & ERROR==0
	close(gcf)
end
				
%%%%% Unsetting Root Configuration %%%%%

set(0,'ShowHiddenHandles','off')

eval(['cd ',currpath])