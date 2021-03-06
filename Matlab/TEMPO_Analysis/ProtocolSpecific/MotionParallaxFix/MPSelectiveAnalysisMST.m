%-----------------------------------------------------------------------------------------------------------------------
%-- MPSelectiveAnalysis.m -- Comes from MPDepthTuningCurveEOHO.m
%-- We assume file may contain any number of interleaved conditions.
%-- Started by JWN, 8/11/06
%-- Last by JWN, 05/01/07  Exceptions to both eye coils noted for both monkeys
%-----------------------------------------------------------------------------------------------------------------------
function MPSelectiveAnalysis(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE);

ver = '2.0';
TEMPO_Defs;
Path_Defs;
symbols = {'bo' 'rs' 'gd' 'kv' 'm<' 'c>' 'bv' 'rv'};
line_types2 = {'b--' 'r--' 'g--' 'k--' 'g.-' 'b.-' 'r-.' 'k.'};
line_types4 = {'b-' 'r-' 'g-' 'k-' 'm-' 'c-' 'y-' 'b-'};
line_types5 = {'bo-' 'rs-' 'gd-' 'kv-' 'm<-' 'c>-' 'yo-' 'bs-'};
NULL_VALUE = -9999;

disp(sprintf('(MPSelectiveAnalysis v%s) Started at %s.',ver,datestr(now,14)));

% Get the trial type, depth values, and movement phase for each condition in the condition_list[]
MPdepths = data.moog_params(PATCH_DEPTH,:,MOOG);
uMPdepths = unique(MPdepths);
num_depths = size(uMPdepths,2);
MPtrial_types = data.moog_params(MP_TRIAL_TYPE,:,MOOG);
uMPtrial_types = unique(MPtrial_types);  % Conditions present
%Place breakouts here.  This is what SelectiveAnalysis could be all about!
%if(isempty(find(uMPtrial_types==###))) return;  end;
if(isempty(find(uMPtrial_types==0))) disp('(MPSelectiveAnalysis) Breakout: No MP');  return;  end;  % BREAKOUT ENABLED!

num_trial_types = length(uMPtrial_types);
MPphase = data.moog_params(MOVEMENT_PHASE,:,MOOG);
uMPphase = unique(MPphase);
num_phase = size(uMPphase,2);
if(num_phase ~= 2)
    disp('(MPSelectiveAnalysis) Fatal Error: Two phases required to calculate modulation indices.');
    return;
end
trials = size(MPphase,2);

% Get the mean firing rates for all the trials
area = 'MST';  % Kluge! 80 for MT, 100 for MST, +50 for transfer function delay 
if(strcmp(area,'MT'))  % Don't change this one!
    latency = 130;  % MT guess
else
    latency = 150;  % MST guess
end 
begin_time = find(data.event_data(1,:,1)==StartCode) + latency;
end_time = find(data.event_data(1,:,1)==StopCode) + latency;
corrupts = 0;
if(max(max(max(data.spike_data))) > 1)
    corrupts = sum(sum(sum(data.spike_data>1)));
    disp(sprintf('(MPSelectiveAnalysis) WARNING: %d corrupt values in data.spike_data.',corrupts));
    data.spike_data = cast(data.spike_data>0,'double');
end
raw_spikes = data.spike_data(1,begin_time:end_time,:);
spike_rates = 1000*squeeze(mean(raw_spikes))';  % The hard way
total_spike_bins = end_time - begin_time;
num_reduced_bins = 39;
bin_width = total_spike_bins/(num_reduced_bins+1);  % ~2000ms/(39+1) = ~50ms;
interpolation_spacing = 2*.01;  % resample at .01 resolution (real resolution is 0.5, hence *2)
num_interp = 1+(num_depths-2)/interpolation_spacing;  % number of interpolated points (depths)

% Recover PG
PG = mean(data.moog_params(PURSUIT_GAIN,1,MOOG));
if isnan(PG) PG = 1; end
% Take a break from firing to look at eye movements
% In data.eye_data, Channels 1,2,3&4 are eye (x&y), 5&6 are Moog (x&y).
% Only analyze stimulus time 200:642.
eye_xyl = data.eye_data(1:2,200:642,:);
eye_xyr = data.eye_data(3:4,200:642,:);
Moog_xy = data.eye_data(5:6,200:642,:);
% Realign axes to match preferred direction
pref = data.neuron_params(PREFERRED_DIRECTION);
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
[monkid, cellid, runstr]=strread(FILE,'m%dc%dr%s.htb');
switch monkid
    case 9, % Barracuda
        if cellid==155, eye_uv = eye_uvl; end
        if cellid==156, eye_uv = eye_uvl; end
    case 15, % Ovid
        if cellid<35, eye_uv = eye_uvl; end
        if cellid>46, eye_uv = eye_uvr; end
    otherwise
        disp('(MPSelectiveAnalysis) WARNING: Unknown monkid');
end
% Velocity in deg/s
%veye_uvr = diff(eye_uvr(1,:,:))*200;
%veye_uvl = diff(eye_uvl(1,:,:))*200;
vMoog_uv = diff(Moog_uv(1,:,:))*200;
veye_uv = diff(eye_uv(1,:,:))*200;
indices = logical(MPtrial_types == 0); % only care about MP, lumping phases together
% Do fft on Moog first for baseline, throwing out v component
fft_vMoog = squeeze(abs(fft(vMoog_uv(1,:,indices)))); %All ffts
Moog_amplitude = mean(fft_vMoog(2,:));
median_Moog_amplitude = median(fft_vMoog(2,:));
% Do fft on average eye
fft_veye = squeeze(abs(fft(veye_uv(1,:,indices)))); %All ffts
eye_amplitude = mean(fft_veye(2,:));
median_eye_amplitude = median(fft_veye(2,:));
pursuit_gain = eye_amplitude/Moog_amplitude;
median_pursuit_gain = median_eye_amplitude/median_Moog_amplitude;
% Do near and far too
indices = logical((MPtrial_types == 0) & (MPdepths == -2));
fft_veye = squeeze(abs(fft(veye_uv(1,:,indices)))); %All ffts
eye_amplitude = mean(fft_veye(2,:));
near_gain = eye_amplitude/Moog_amplitude;
indices = logical((MPtrial_types == 0) & (MPdepths == 2));
fft_veye = squeeze(abs(fft(veye_uv(1,:,indices)))); %All ffts
eye_amplitude = mean(fft_veye(2,:));
far_gain = eye_amplitude/Moog_amplitude;
if(isnan(pursuit_gain))
    pursuit_gain = 1;
end
dshift = (1-pursuit_gain)/.16;  % Amount of shift in degrees of disparity given pursuit_gain
dshift = round(dshift/(interpolation_spacing/2))*(interpolation_spacing/2);  % round the shift
cleave = abs(dshift)/(interpolation_spacing/2); % number of points to remove

% Redundant section correlates pursuit gains with spike rates within depths
for j=1:num_depths  % Ten MPdepths (which includes null)
    indices = logical((MPtrial_types == 0) & (MPdepths == uMPdepths(j)));
    fft_veye = squeeze(abs(fft(veye_uv(1,:,indices))));
    fft_vMoog = squeeze(abs(fft(vMoog_uv(1,:,indices))));
    eye = fft_veye(2,:)./fft_vMoog(2,:);
    resp = spike_rates((MPtrial_types == 0) & (MPdepths == uMPdepths(j)));
    eyerespcctmp = corrcoef(eye,resp);
    eyerespcc(j) = eyerespcctmp(2);
end
eyeresp = mean(abs(eyerespcc));

%%%  Calculate PDI and PDImod for all individual conditions  %%%
PDI = zeros(1,4);
xPDI = zeros(1,(num_interp-1)/2);
PDImod = zeros(1,4);
mPDI = zeros(1,6)+888;
mxPDI = zeros(1,6)+888;
mcxPDI = zeros(1,6)+888;
MP1iPDI = 888;
RM1iPDI = 888;
RMs1iPDI = 888; 
MPsxiPDI = 888;
mPDImod = zeros(1,6)+888;
pmPDI = zeros(1,6)+888;
pMPsxiPDI = 888;
pmPDImod = zeros(1,6)+888;
null_phases = zeros(1,6)+888;
signnull_phases = zeros(1,6);
null_amps = zeros(1,6)+888;
pnull_amps = zeros(1,6)+888; 
p3null_amps = zeros(1,6)+888;
fn_phases = zeros(1,6)+888;
signfn_phases = zeros(1,6);
fn_amps = zeros(1,6)+888;
pfn_amps = zeros(1,6)+888;
p3fn_amps = zeros(1,6)+888; 
for i = 1:6 % Try all 6 conditions
    if(isempty(find(uMPtrial_types==i-1))) continue;  end;  % Break out if none from that condition
    % Prep mis data (used to be handled by MPGetMI.m)
    reps = floor(sum(MPtrial_types == i-1)/(num_depths*num_phase));  % Moved reps in here because different conditions may now have different numbers of reps.
    mis = zeros(num_trial_types,num_depths,reps);
    phases = zeros(num_trial_types,num_depths,reps);
    for j=1:num_depths  % Ten MPdepths (which includes null)
        indices0 = logical((MPtrial_types == i-1) & (MPdepths == uMPdepths(j)) & (MPphase == uMPphase(1)));
        trials0 = find(indices0==1);
        indices180 = logical((MPtrial_types == i-1) & (MPdepths == uMPdepths(j)) & (MPphase == uMPphase(2)));
        trials180 = find(indices180==1);
        for k=1:reps    % Calculate MIs from paired trials
            % Get counts for phase 0
            raw_spikes = data.spike_data(1,begin_time:end_time,trials0(k));
            [bins, counts0] = SpikeBinner(raw_spikes, 1, bin_width, 0);
            % Get counts for phase 180
            raw_spikes = data.spike_data(1,begin_time:end_time,trials180(k));
            [bins, counts180] = SpikeBinner(raw_spikes, 1, bin_width, 0);
            % Subtract and calculate MI
            counts = counts180-counts0;
            phase_fft = fft(counts);
            phases(i,j,k) = phase_fft(2);
            full_fft = abs(phase_fft);  % Counts per half-cycle... 
            % mis(i,j,k) = full_fft(2);  % ...which for 2s = counts/second, so we could just do this, but we make Matlab do extra work...
            mis(i,j,k) = full_fft(2)/(size(full_fft,1)/2);  % Convert to counts/bin
            mis(i,j,k) = mis(i,j,k) * 1000/bin_width;  % Convert counts/bin to counts/second
        end
        % Get PSTHs for calculating far-near modulation (+/-2 only)
        raw_spikes = data.spike_data(1,begin_time:end_time,indices0);
        hist_data = sum(raw_spikes,3);
        [bins, saved_counts0(j,:)] = SpikeBinner(hist_data, 1, bin_width, 0);
        raw_spikes = data.spike_data(1,begin_time:end_time,indices180);
        hist_data = sum(raw_spikes,3);
        [bins, saved_counts180(j,:)] = SpikeBinner(hist_data, 1, bin_width, 0);
    end
    % First do null (-180 - -0)
    % - 0 180
    % N 0 180
    % F 0 180
    % null_phases(i) = angle(sum(phases(i,1,:)))*180/pi;  % Examine phase of null response
    % null_amps(i) = abs(sum(phases(i,1,:)))/reps;  % Examine amplitude of null response
    null_counts = saved_counts180(1,:)-saved_counts0(1,:);  % 1 for null
    null_fft = fft(null_counts);
    null_phases(i) = angle(null_fft(2))*180/pi;
    null_amps(i) = abs(null_fft(2))/reps;
    if(null_phases(i) > 120 | null_phases(i) < -120)
        signnull_phases(i) = 1;
    elseif (null_phases(i) > -60 & null_phases(i) < 60)
        signnull_phases(i) = -1;
    else signnull_phases(i) = 0;
    end
    % Then do far-near
    a_counts = saved_counts0(10,:)-saved_counts180(2,:);  % 10 and 2 for far and near
    b_counts = saved_counts180(10,:)-saved_counts0(2,:);
    fn_counts = b_counts - a_counts; % Aligns phases so that modulation in null that supports far will have the same phase as resulting far-near; see graph paper.  
    fn_fft = fft(fn_counts);
    fn_phases(i) = angle(fn_fft(2))*180/pi;
    fn_amps(i) = abs(fn_fft(2))/reps;
    if(fn_phases(i) > 120 | fn_phases(i) < -120)
        signfn_phases(i) = 1;
    elseif (fn_phases(i) > -60 & fn_phases(i) < 60)
        signfn_phases(i) = -1;
    else signfn_phases(i) = 0;
    end
    % Send data off to MPBootstrap2/3 for significance testing.
    [pnull_amps(i) pfn_amps(i)] = MPBootstrap2(data,i,begin_time,end_time,null_amps(i),fn_amps(i));
    p3null_amps(i) = MPBootstrap3(null_counts, reps, null_amps(i));
    p3fn_amps(i) = MPBootstrap3(fn_counts, reps, fn_amps(i));
    % Begin calculating both PDI and PDImods
    % Need to clear this too because different conditions may have different numbers of reps
    mean_data = zeros(reps*2,num_depths-1);
    for j = 1:num_depths-1
        tmp = spike_rates(MPdepths == uMPdepths(j+1) & MPtrial_types == i-1)';
        mean_data(:,j) = tmp(1:reps*2);  % ignore extra incomplete reps
    end
    mis_data = squeeze(mis(i,:,:));
    meanmean_data = mean(mean_data);  % mean of the trials from the means measure
    meanmis = mean(mis_data,2);  % mean of the trials from the mis measure
    stdmean_data = std(mean_data);
    stdmis = std(mis_data,0,2);
    for k = 1:num_depths/2-1
        nearm = meanmean_data(k);
        farm = meanmean_data(num_depths-k);
        nearstd = stdmean_data(k);
        farstd = stdmean_data(num_depths-k);
        PDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
        nearm = meanmis(k+1);  % Remember to shift by one to lose spont data
        farm = meanmis(num_depths-(k-1));  % and by six to get to the far data
        nearstd = stdmis(k+1);
        farstd = stdmis(num_depths-(k-1));
        PDImod(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
    end
    mPDI(i) = mean(PDI);
    mPDImod(i) = mean(PDImod);
    % Interpolate the means and stds and recalculate PDIs (now called <cond>xiPDIDs)
    xmeanmean_data = interp1(1:9,meanmean_data,1:interpolation_spacing:9);
    xstdmean_data = interp1(1:9,stdmean_data,1:interpolation_spacing:9);
    for k = 1:(num_interp-1)/2  % Using all pairs, regardless of shift size
        nearm = xmeanmean_data(k);
        farm = xmeanmean_data(num_interp+1-k);
        nearstd = xstdmean_data(k);
        farstd = xstdmean_data(num_interp+1-k);
        xPDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
    end
    mxPDI(i) = mean(xPDI);
    % Pull out a one-depth MP and RM, and then calculate a RMs1iPDI shifted for pursuit gain
    k = 3; % Using +/- 1
    if(i == 1)
        MP1iPDI = PDI(k);
    end
    if(i == 3)
        RM1iPDI = PDI(k);
        if(dshift >= 0.5)
            nearm = ((dshift-.5)*2)*meanmean_data(k-2) + (1-(dshift-.5)*2)*meanmean_data(k-1);
            farm = ((dshift-.5)*2)*meanmean_data(num_depths-k-2) + (1-(dshift-.5)*2)*meanmean_data(num_depths-k-1);
        elseif(dshift >= 0)
            nearm = (dshift*2)*meanmean_data(k-1) + (1-dshift*2)*meanmean_data(k);
            farm = (dshift*2)*meanmean_data(num_depths-k-1) + (1-dshift*2)*meanmean_data(num_depths-k);
        else
            nearm = (-dshift*2)*meanmean_data(k+1) + (1+dshift*2)*meanmean_data(k);
            farm = (-dshift*2)*meanmean_data(num_depths-k+1) + (1+dshift*2)*meanmean_data(num_depths-k);
        end
        nearstd = stdmean_data(k);
        farstd = stdmean_data(num_depths-k);
        RMs1iPDI = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
    end
    if(i == 1) % Get shifted MPsxiPDI by combining pursuit gain dshift with interpolated data
        if(dshift > 0)
            sxmeanmean_data = xmeanmean_data(2*cleave+1:length(xmeanmean_data));
            sxstdmean_data = xstdmean_data(2*cleave+1:length(xstdmean_data));
        elseif(dshift <= 0)
            sxmeanmean_data = xmeanmean_data(1:length(xmeanmean_data)-2*cleave);
            sxstdmean_data = xstdmean_data(1:length(xstdmean_data)-2*cleave);
        end
        num_sinterp = length(sxmeanmean_data);
        sxPDI = zeros(1,floor(num_sinterp/2));
        for k = 1:num_sinterp/2  % Using all remaining pairs
            nearm = sxmeanmean_data(k);
            farm = sxmeanmean_data(num_sinterp+1-k);
            nearstd = sxstdmean_data(k);
            farstd = sxstdmean_data(num_sinterp+1-k);
            sxPDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
        end
        MPsxiPDI = mean(sxPDI);
    end
    % Calculated a <cond>cxiPDI that represents a cleaved (not shifted) PDI
    xmeanmean_data = xmeanmean_data(cleave+1:length(xmeanmean_data)-cleave);
    xstdmean_data = xstdmean_data(cleave+1:length(xstdmean_data)-cleave);
    num_sinterp = length(xmeanmean_data);
    sxPDI = zeros(1,floor(num_sinterp/2));
    for k = 1:num_sinterp/2  % Using all remaining pairs
        nearm = xmeanmean_data(k);
        farm = xmeanmean_data(num_sinterp+1-k);
        nearstd = xstdmean_data(k);
        farstd = xstdmean_data(num_sinterp+1-k);
        sxPDI(k) = (farm-nearm)/(abs(farm-nearm)+sqrt((nearstd^2+farstd^2)/2));
    end
    mcxPDI(i) = mean(sxPDI);
    
    % Send data off to MPBootstrap for significance testing.
    pmPDI(i) = MPBootstrap(mean_data, mPDI(i));
    pmPDImod(i) = MPBootstrap(mis_data(2:end,:)', mPDImod(i));
end    

% Get RF properties (if necessary)
if(pref < 30 | pref > 330 | pref>150&pref<210)
    pref_cat = 1;
elseif(pref>60&pref<120 | pref>240&pref<300)
    pref_cat = 3;
else pref_cat = 2;
end
RFx = data.neuron_params(RF_XCTR);
RFy = data.neuron_params(RF_YCTR);
RFd = data.neuron_params(RF_DIAMETER);
% Calculate eccentricity, polar angle, and realigned polar angle (based on pref)
RFecc = sqrt(RFx^2 + RFy^2);
RFang = atan2(RFy,RFx)*180/pi;  % between -180 and 180
if(RFang<0)
    RFang = 360+RFang; % make it between 0 and 360 like pref is
end
rRFang = abs(pref-RFang);  % larger angle minus smaller angle
if(rRFang>=180)
    rRFang = 360-rRFang; % get the smaller of the two angle differences (the one less than 180)
end
if(rRFang>=90)
    rRFang = 180-rRFang; % convert to angle between 0 and 90
end
if(rRFang-45 < -15)
    sigrRFang = 1;
else if(rRFang-45 >15)
    sigrRFang = 3;
else
    sigrRFang = 2;
    end
end     

% Write results for this cell to 1 file
PATHOUT = 'Z:\Data\MOOG\Ovid\Analysis\';
filenames = {'eyeresp'};
for i = 1:1
    outfile = cell2mat(strcat(PATHOUT,area,'_',filenames(i),'.txt'));
    headerflag = 0;
    if (exist(outfile) == 0) % File does not yet exist, so print a header
        headerflag = 1;
    end
    fid = fopen(outfile, 'a');  % Open text file.
    if (headerflag)
        fprintf(fid, 'FILE ');
        fprintf(fid, 'monkid cellid PG ');
        fprintf(fid, 'MPgain MPmediangain MPneargain MPfargain eyeresp ');
        fprintf(fid, 'MPiPDI BDiPDI RMiPDI CiPDI EOiPDI HOiPDI ');
        fprintf(fid, 'MPxiPDI BDxiPDI RMxiPDI CxiPDI EOxiPDI HOxiPDI ');
        fprintf(fid, 'MPcxiPDI BDcxiPDI RMcxiPDI CcxiPDI EOcxiPDI HOcxiPDI ');
        fprintf(fid, 'MP1iPDI RM1iPDI RMs1iPDI MPsxiPDI ');
        fprintf(fid, 'absMPiPDI absBDiPDI absRMiPDI absCiPDI absEOiPDI absHOiPDI ');
        fprintf(fid, 'absMPxiPDI absBDxiPDI absRMxiPDI absCxiPDI absEOxiPDI absHOxiPDI ');
        fprintf(fid, 'absMPcxiPDI absBDcxiPDI absRMcxiPDI absCcxiPDI absEOcxiPDI absHOcxiPDI ');
        fprintf(fid, 'absMP1iPDI absRM1iPDI absRMs1iPDI absMPsxiPDI ');
        fprintf(fid, 'MPiPDIm BDiPDIm RMiPDIm CiPDIm EOiPDIm HOiPDIm ');
        fprintf(fid, 'absMPiPDIm absBDiPDIm absRMiPDIm absCiPDIm absEOiPDIm absHOiPDIm ');
        fprintf(fid, 'nullMPphase nullBDphase nullRMphase nullCphase nullEOphase nullHOphase ');
        fprintf(fid, 'signnullMPphase signnullBDphase signnullRMphase signnullCphase signnullEOphase signnullHOphase ');
        fprintf(fid, 'nullMPamp nullBDamp nullRMamp nullCamp nullEOamp nullHOamp ');
        fprintf(fid, 'fnMPphase fnBDphase fnRMphase fnCphase fnEOphase fnHOphase ');
        fprintf(fid, 'signfnMPphase signfnBDphase signfnRMphase signfnCphase signfnEOphase signfnHOphase ');
        fprintf(fid, 'fnMPamp fnBDamp fnRMamp fnCamp fnEOamp fnHOamp ');
        fprintf(fid, 'sigpnullMPamp sigpnullBDamp sigpnullRMamp sigpnullCamp sigpnullEOamp sigpnullHOamp ');
        fprintf(fid, 'sigpfnMPamp sigpfnBDamp sigpfnRMamp sigpfnCamp sigpfnEOamp sigpfnHOamp ');
        fprintf(fid, 'sigp3nullMPamp sigp3nullBDamp sigp3nullRMamp sigp3nullCamp sigp3nullEOamp sigp3nullHOamp ');
        fprintf(fid, 'sigp3fnMPamp sigp3fnBDamp sigp3fnRMamp sigp3fnCamp sigp3fnEOamp sigp3fnHOamp ');
        fprintf(fid, 'sigpMPiPDI sigpBDiPDI sigpRMiPDI sigpCiPDI sigpEOiPDI sigpHOiPDI ');
        fprintf(fid, 'sigpMPsxiPDI ');
        fprintf(fid, 'sigpMPiPDIm sigpBDiPDIm sigpRMiPDIm sigpCiPDIm sigpEOiPDIm sigpHOiPDIm ');
        fprintf(fid, 'pref prefcat RFx RFy RFd RFecc RFang rRFang sigrRFang corrupts');
        fprintf(fid, '\r\n');
    end
    fprintf(fid,'%10s', strtok(FILE,'.'));
    fprintf(fid,' %+2.5f', monkid, cellid, PG, pursuit_gain, median_pursuit_gain, near_gain, far_gain, eyeresp, mPDI, mxPDI, mcxPDI, MP1iPDI, RM1iPDI, RMs1iPDI, MPsxiPDI, abs(mPDI), abs(mxPDI), abs(mcxPDI), abs(MP1iPDI), abs(RM1iPDI), abs(RMs1iPDI), abs(MPsxiPDI), mPDImod, abs(mPDImod), null_phases, signnull_phases, null_amps, fn_phases, signfn_phases, fn_amps, (pnull_amps>0.05)+1, (pfn_amps>0.05)+1, (p3null_amps>0.05)+1, (p3fn_amps>0.05)+1, (pmPDI>0.025)+1, (pMPsxiPDI>0.25)+1, (pmPDImod>0.025)+1, pref, pref_cat, RFx, RFy, RFd, RFecc, RFang, rRFang, sigrRFang, corrupts);
    fprintf(fid,'\r\n');
    fclose(fid);
end

disp('(MPSelectiveAnalysis) Done.');
return;