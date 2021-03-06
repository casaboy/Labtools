%-----------------------------------------------------------------------------------------------------------------------
%-- MP_DDD.m -- Looking for fabled DDD cells in MST.  Looks at the disparity-dependent difference in response phase
% (degrees) in the BD condition to see if any cells have disparity-dependent direction selectivity.  Also includes 
% an analysis of selectivity by ANOVA as in MPAnovas.m.
%-- Started by JWN, 12/05/07
%-- Last by JWN, 12/05/07
%-----------------------------------------------------------------------------------------------------------------------
function MP_DDD(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE);

ver = '1.0';
TEMPO_Defs;
Path_Defs;
symbols = {'bo' 'rs' 'gd' 'kv' 'm<' 'c>' 'bv' 'rv'};
line_types2 = {'b--' 'r--' 'g--' 'k--' 'g.-' 'b.-' 'r-.' 'k.'};
line_types4 = {'b-' 'r-' 'g-' 'k-' 'm-' 'c-' 'y-' 'b-'};
line_types5 = {'bo-' 'rs-' 'gd-' 'kv-' 'm<-' 'c>-' 'yo-' 'bs-'};
NULL_VALUE = -9999;

disp(sprintf('(MP_DDD v%s) Started at %s.',ver,datestr(now,14)));

[monkid, cellid, runstr]=strread(FILE,'m%dc%dr%s.htb');
% Get the trial type, depth values, and movement phase for each condition in the condition_list[]
MPdepths = data.moog_params(PATCH_DEPTH,:,MOOG);
uMPdepths = unique(MPdepths);
num_depths = size(uMPdepths,2);
MPtrial_types = data.moog_params(MP_TRIAL_TYPE,:,MOOG);
uMPtrial_types = unique(MPtrial_types);  % Conditions present
i = 2; % Look at only the BD condition
if(isempty(find(uMPtrial_types==i-1))) return;  end;  % Break out if none from that condition
    
num_trial_types = length(uMPtrial_types);
MPphase = data.moog_params(MOVEMENT_PHASE,:,MOOG);
uMPphase = unique(MPphase);
num_phase = size(uMPphase,2);
if(num_phase ~= 2)
    disp('(MP_DDD) Fatal Error: Two phases required to calculate modulation indices.');
    return;
end
trials = size(MPphase,2);

% Get the mean firing rates for all the trials
area = 'MST';  % Kluge! 80 for MT and 80 for MST (see Kruse et al 2002), +80 for transfer function delay
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
spont_rates = 1000*squeeze(mean(spont_spikes))';
total_spike_bins = end_time - begin_time;
num_reduced_bins = 39;
bin_width = total_spike_bins/(num_reduced_bins+1);  % ~2000ms/(39+1) = ~50ms;


reps = floor(sum(MPtrial_types==i-1)/(num_depths*num_phase));
% Separating near and far trials
indices0n = logical((MPtrial_types == i-1) & (MPdepths < 0) & (MPdepths > -10)& (MPphase == uMPphase(1)));
indices180n = logical((MPtrial_types == i-1) & (MPdepths < 0) & (MPdepths > -10) & (MPphase == uMPphase(2)));
indices0f = logical((MPtrial_types == i-1) & (MPdepths > 0) & (MPphase == uMPphase(1)));
indices180f = logical((MPtrial_types == i-1) & (MPdepths > 0) & (MPphase == uMPphase(2)));
% Getting PSTHs 
raw_spikes = data.spike_data(1,begin_time:end_time,indices0n);
hist_data = sum(raw_spikes,3);
[bins, saved_counts0n] = SpikeBinner(hist_data, 1, bin_width, 0);
raw_spikes = data.spike_data(1,begin_time:end_time,indices180n);
hist_data = sum(raw_spikes,3);
[bins, saved_counts180n] = SpikeBinner(hist_data, 1, bin_width, 0);
raw_spikes = data.spike_data(1,begin_time:end_time,indices0f);
hist_data = sum(raw_spikes,3);
[bins, saved_counts0f] = SpikeBinner(hist_data, 1, bin_width, 0);
raw_spikes = data.spike_data(1,begin_time:end_time,indices180f);
hist_data = sum(raw_spikes,3);
[bins, saved_counts180f] = SpikeBinner(hist_data, 1, bin_width, 0);
% Now subtracted phases and test for significant modulation
countsn = saved_counts180n-saved_counts0n;
countsf = saved_counts180f-saved_counts0f;
near_fft = fft(countsn);
far_fft = fft(countsf);
near_amp = abs(near_fft(2))/reps;  % Should have used reps*4 here to put into spikes/s but it doesn't matter
far_amp = abs(far_fft(2))/reps;
sigpn = MPBootstrap3(countsn, reps, near_amp);
sigpf = MPBootstrap3(countsf, reps, far_amp);
phase_difference = 888;
if (sigpn < 0.05 & sigpf < 0.05)  % compute FFT phases only if both modulations are significant by bootstrap
    near_phase = angle(near_fft(2));
    far_phase = angle(far_fft(2));
    phases = unwrap([near_phase far_phase]);
    phase_difference = abs(phases(1)-phases(2))*180/pi;  %in degrees
end

% Get selectivity by ANOVA too for comparison 
p = zeros(1,6)+888;
for i = 1:6
    if(isempty(find(uMPtrial_types==i-1))) continue;  end;  % Break out if none from that condition
    reps = floor(sum(MPtrial_types == i-1)/(num_depths*num_phase));  % Moved reps in here because different conditions may now have different numbers of reps.
    mean_data = zeros(reps*2,num_depths-1);
    for j = 1:num_depths-1
        tmp = spike_rates(MPdepths == uMPdepths(j+1) & MPtrial_types == i-1)';
        mean_data(:,j) = tmp(1:reps*2);  % ignore extra incomplete reps
    end
    p(i) = anova1(mean_data,([]),'off'); 
end

% Write results for this cell to 1 file
PATHOUT = 'Z:\Data\MOOG\Ovid\Analysis\';
filenames = {'DDD'};
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
        fprintf(fid, 'DDDdiff MPanovap BDanovap RManovap Canovap EOanovap HOanovap');
        fprintf(fid, '\r\n');
    end
    fprintf(fid,'%10s', strtok(FILE,'.'));
    fprintf(fid,' %+2.5f', monkid, cellid, phase_difference, p);
    fprintf(fid,'\r\n');
    fclose(fid);
end
disp('(MP_DDD) Done.');
return;