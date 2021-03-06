%-----------------------------------------------------------------------------------------------------------------------
%-- MPPursuitReviews.m -- Analyses to placate reviewers on the Nature paper.  Analysis of pursuit for Nature paper.
%  Calculates position gain, velocity gain, phase lag, mean retinal slip, normalized mean retinal slip (NMRS), 
%  DSDI, |DSDI|, and DSDIs corrected for position gain, velocity gain, and NMRS. 
%-- Started by JWN, 12/05/07
%-- Last by JWN, 11/02/08 - Added functionality to handle pursuit gain for all conditions, not just MP.  Commented out a big sections unrelated to PG.
%-----------------------------------------------------------------------------------------------------------------------
function MPPursuitReviews(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE);

ver = '1.0';
TEMPO_Defs;
Path_Defs;
symbols = {'bo' 'rs' 'gd' 'kv' 'm<' 'c>' 'bv' 'rv'};
line_types2 = {'b--' 'r--' 'g--' 'k--' 'g.-' 'b.-' 'r-.' 'k.'};
line_types4 = {'b-' 'r-' 'g-' 'k-' 'm-' 'c-' 'y-' 'b-'};
line_types5 = {'bo-' 'rs-' 'gd-' 'kv-' 'm<-' 'c>-' 'yo-' 'bs-'};
NULL_VALUE = -9999;

disp(sprintf('(MPPursuitReviews v%s) Started at %s.',ver,datestr(now,14)));

[monkid, cellid, runstr]=strread(FILE,'m%dc%dr%s.htb');
% Get the trial type, depth values, and movement phase for each condition in the condition_list[]
MPdepths = data.moog_params(PATCH_DEPTH,:,MOOG);
uMPdepths = unique(MPdepths);
num_depths = size(uMPdepths,2);
MPtrial_types = data.moog_params(MP_TRIAL_TYPE,:,MOOG);
uMPtrial_types = unique(MPtrial_types);  % Conditions present
%Place breakouts here.  This is what SelectiveAnalysis could be all about!
%if(isempty(find(uMPtrial_types==###))) return;  end;
%if(isempty(find(uMPtrial_types==0))) disp('(MPSelectiveAnalysis) Breakout: No MP');  return;  end;  % BREAKOUT ENABLED!

num_trial_types = length(uMPtrial_types);
MPphase = data.moog_params(MOVEMENT_PHASE,:,MOOG);
uMPphase = unique(MPphase);
num_phase = size(uMPphase,2);
if(num_phase ~= 2)
    disp('(MPPursuitReviews) Fatal Error: Two phases required to calculate modulation indices.');
    return;
end
trials = size(MPphase,2);

% Get the mean firing rates for all the trials
area = 'MT';  % Kluge! 80 for MT and 80 for MST (see Kruse et al 2002), +80 for transfer function delay
if(strcmp(area,'MT'))  % Don't change this one!
    latency = 160;  % MT guess
else
    latency = 160;  % MST guess
end 
begin_time = find(data.event_data(1,:,1)==StartCode) + latency; % Each trial always has the same start time so may as well use trial 1
end_time = begin_time + 1999; % 2s trial
if(max(max(max(data.spike_data))) > 1)
    data.spike_data = cast(data.spike_data>0,'double');
end
raw_spikes = data.spike_data(1,begin_time:end_time,:);
spont_spikes = data.spike_data(1,begin_time-500:begin_time,:);
spike_rates = 1000*squeeze(mean(raw_spikes))';  % The hard way
interpolation_spacing = 2*.01;  % resample at .01 resolution (real resolution is 0.5, hence *2)
num_interp = 1+(num_depths-2)/interpolation_spacing;  % number of interpolated points (depths)

% Recover PG
cleave = 0; dshift = 0;
pursuit_gain = 888; vpursuit_gain = 888;
pref = data.neuron_params(PREFERRED_DIRECTION);

% Take a break from firing to look at eye movements
% In data.eye_data, Channels 1,2,3&4 are eye (x&y), 5&6 are Moog (x&y).
% Only analyze stimulus time 214:614 (2s long).
eye_xyl = data.eye_data(1:2,215:614,:);
eye_xyr = data.eye_data(3:4,215:614,:);
Moog_xy = data.eye_data(5:6,215:614,:);
% Realign axes to match preferred direction
opp = tan(pref/(180/pi));
u = [1 opp] / sqrt(1+opp^2);
v = [-u(2) u(1)];
for i=1:size(eye_xyl,3)
    eye_uvr(1,:,i) = u*eye_xyr(:,:,i);
    eye_uvr(2,:,i) = v*eye_xyr(:,:,i);
    eye_uvl(1,:,i) = u*eye_xyl(:,:,i);
    eye_uvl(2,:,i) = v*eye_xyl(:,:,i);
    Moog_uv(1,:,i) = u*Moog_xy(:,:,i);
    Moog_uv(2,:,i) = v*Moog_xy(:,:,i);
end
eye_uv = (eye_uvl+eye_uvr)/2;  % Average of the two eyes
% Eye check based on file name (set up for Barracuda and Ovid 050107)
switch monkid
    case 9, % Barracuda
        if cellid==155, eye_uv = eye_uvl; end
        if cellid==156, eye_uv = eye_uvl; end
        gain_constant = .18;  % Based on viewing distance and interocular distance
    case 15, % Ovid
        if cellid<35, eye_uv = eye_uvl; end
        if cellid>46, eye_uv = eye_uvr; end
        gain_constant = .15;  % Based on viewing distance and interocular distance
    otherwise
        disp('(MPPursuitReviews) WARNING: Unknown monkid');
end
% Velocity in deg/s
vMoog_uv = diff(Moog_uv(1,:,:))*200;
veye_uv = diff(eye_uv(1,:,:))*200;
indices = logical(MPtrial_types == 0); % only care about MP, lumping phases together
% Do fft on Moog first for baseline, throwing out v component
fft_Moog = squeeze(abs(fft(Moog_uv(1,:,indices)))); %All ffts
fft_vMoog = squeeze(abs(fft(vMoog_uv(1,:,indices)))); %All ffts
Moog_amplitude = mean(fft_Moog(2,:));
Moog_vamplitude = mean(fft_vMoog(2,:));
% Do fft on average eye
% THEN compute PG using Moog signal from MP condition but eye signal from each condition

% All for 1Hz, plus a fft switch to 3 below
load saveouts.mat saveoutsflag
if saveoutsflag==0
    saveoutsflag = 5;
	save saveouts.mat saveoutsflag Moog_uv vMoog_uv Moog_amplitude Moog_vamplitude
    FILE
    disp('(MPPursuitReviews) 0.5Hz saveout');
    return;
else
    load saveouts.mat
    saveoutsflag = 0;
    save saveouts.mat saveoutsflag
end

for i = 1:6
    indices = logical(MPtrial_types == i-1); 
    fft_eye = squeeze(abs(fft(eye_uv(1,:,indices)))); %All ffts
    eye_amplitude = mean(fft_eye(3,:));  %3 for 1Hz, 2 for 0.5Hz
    pursuit_gain(i) = eye_amplitude/Moog_amplitude;
    fft_veye = squeeze(abs(fft(veye_uv(1,:,indices)))); %All ffts
    eye_vamplitude = mean(fft_veye(3,:));  %3 for 1Hz, 2 for 0.5Hz
    pursuit_vgain(i) = eye_vamplitude/Moog_vamplitude;
end
% % Calculate fft phaselag and normalized mean retinal slip (average velocity difference between target and eye at all times)
% phases_Moog = squeeze(angle(fft(vMoog_uv(1,:,indices)))); %All ffts
% phases_eye = squeeze(angle(fft(veye_uv(1,:,indices)))); %All ffts
% phases = unwrap([phases_eye(2,:)' phases_Moog(2,:)'],[],2).*(180/pi);  % Just in case
% phaselag = mean(phases(:,1)-phases(:,2)); % Mean phase lag to be plotted vs. DSDI or |DSDI|
% % boxcarwidthpos = 10;
% boxcarwidthvel = 40;
% indices = logical(MPtrial_types == 0 & MPphase == 0);
% vmpMoog0 = boxcarfilter(squeeze(mean(vMoog_uv(1,:,indices),3)),boxcarwidthvel);
% vmpeye0 = boxcarfilter(squeeze(mean(veye_uv(1,:,indices),3)),boxcarwidthvel);
% indices = logical(MPtrial_types == 0 & MPphase == 180);
% vmpMoog180 = boxcarfilter(squeeze(mean(vMoog_uv(1,:,indices),3)),boxcarwidthvel);
% vmpeye180 = boxcarfilter(squeeze(mean(veye_uv(1,:,indices),3)),boxcarwidthvel);
% mrs0 = vmpeye0-vmpMoog0;
% mrs180 = vmpeye180-vmpMoog180;
% mrs = mean([mrs0 mrs180]);
% % Do it one way by normalizing every instant
% prune = 0.2; % Prune away when target velocity falls below 0.2 deg/s so normalization doesn't blow up
% pruned_vmpMoog0 = vmpMoog0(find(abs(vmpMoog0)>prune));
% pruned_vmpMoog180 = vmpMoog180(find(abs(vmpMoog180)>prune));
% pruned_vmpeye0 = vmpeye0(find(abs(vmpMoog0)>prune));
% pruned_vmpeye180 = vmpeye180(find(abs(vmpMoog180)>prune));
% nmrs0 = (pruned_vmpeye0-pruned_vmpMoog0)./pruned_vmpMoog0;
% nmrs180 = (pruned_vmpeye180-pruned_vmpMoog180)./pruned_vmpMoog180;
% nmrs_inst = mean([nmrs0 nmrs180]);
% % Do it a second way by normalizing to peak
% % peak_stim_v = mean([max(vmpMoog0) -min(vmpMoog180)]);
% % nmrs_peak = (mrs/peak_stim_v)*(pi/2);

% Calculate PDIs
PDI = zeros(1,4);
mPDI = 888;
% i=1;
% reps = floor(sum(MPtrial_types == i-1)/(num_depths*num_phase));  % Moved reps in here because different conditions may now have different numbers of reps.
% mean_data = zeros(reps*2,num_depths-1);
% for j = 1:num_depths-1
%     tmp = spike_rates(MPdepths == uMPdepths(j+1) & MPtrial_types == i-1)';
%     mean_data(:,j) = tmp(1:reps*2);  % ignore extra incomplete reps
% end
% meanmean_data = mean(mean_data);  % mean of the trials from the means measure
% stdmean_data = std(mean_data);
% for k = 1:num_depths/2-1
%     nearm = meanmean_data(k);
%     farm = meanmean_data(num_depths-k);
%     nearstd = stdmean_data(k);
%     farstd = stdmean_data(num_depths-k);
%     PDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
% end
% mPDI(i) = mean(PDI);
% % Interpolate the means and stds for the next step
% xmeanmean_data = interp1(1:9,meanmean_data,1:interpolation_spacing:9);
% xstdmean_data = interp1(1:9,stdmean_data,1:interpolation_spacing:9);
% % gains = [pursuit_gain pursuit_vgain 1+nmrs*(pi/2)];  % Add 1 and multiply by pi/2 to make nmrs analogous to PG
% gains = [pursuit_gain pursuit_vgain 1+nmrs_inst];  % Add 1 to make nmrs analogous to PG
% % Calculate corrected PDIs; Get shifted MPsxiPDI by combining pursuit gain dshift with interpolated data
% for j = 1:length(gains)
%     dshift = (1-gains(j))/gain_constant;  % Amount of shift in degrees of disparity given pursuit_gain
%     dshift = round(dshift/(interpolation_spacing/2))*(interpolation_spacing/2);  % round the shift
%     cleave = abs(dshift)/(interpolation_spacing/2); % number of points to remove
%     cleave = cast(cleave,'int16');  % Stop warnings
%     if(dshift > 0)
%         sxmeanmean_data = xmeanmean_data(2*cleave+1:length(xmeanmean_data));
%         sxstdmean_data = xstdmean_data(2*cleave+1:length(xstdmean_data));
%     elseif(dshift <= 0)
%         sxmeanmean_data = xmeanmean_data(1:length(xmeanmean_data)-2*cleave);
%         sxstdmean_data = xstdmean_data(1:length(xstdmean_data)-2*cleave);
%     end
%     num_sinterp = length(sxmeanmean_data);
%     sxPDI = zeros(1,floor(num_sinterp/2));
%     for k = 1:num_sinterp/2  % Using all remaining pairs
%         nearm = sxmeanmean_data(k);
%         farm = sxmeanmean_data(num_sinterp+1-k);
%         nearstd = sxstdmean_data(k);
%         farstd = sxstdmean_data(num_sinterp+1-k);
%         sxPDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
%     end
%     MPsxiPDI(j) = mean(sxPDI);
% end

% Write results for this cell to 1 file
PATHOUT = 'Z:\Users\Jacob\';
filenames = {'AllCondsPursuitReviews1Hz'};
for i = 1:1
    outfile = cell2mat(strcat(PATHOUT,area,'_',filenames(i),'.txt'));
    headerflag = 0;
    if (exist(outfile) == 0) % File does not yet exist, so print a header
        headerflag = 1;
    end
    fid = fopen(outfile, 'a');  % Open text file.
    if (headerflag)
        fprintf(fid, 'FILE ');
        fprintf(fid, 'monkid cellid ');
        %fprintf(fid, 'MPpgain MPvgain phaselag mrs nmrsinst MPiPDI absMPiPDI sxip sxiv sxinmrsinst');
        fprintf(fid, 'MPpgain BDpgain RMpgain Cpgain EOpgain HOpgain MPvgain BDvgain RMvgain Cvgain EOvgain HOvgain ');
        fprintf(fid, '\r\n');
    end
    fprintf(fid,'%10s', strtok(FILE,'.'));
    %fprintf(fid,' %+2.5f', monkid, cellid, gains(1:2), phaselag, mrs, nmrs_inst, mPDI, abs(mPDI), MPsxiPDI);
    fprintf(fid,' %+2.5f', monkid, cellid, pursuit_gain, pursuit_vgain);
    fprintf(fid,'\r\n');
    fclose(fid);
end

disp('(MPPursuitReviews) Done.');
return;