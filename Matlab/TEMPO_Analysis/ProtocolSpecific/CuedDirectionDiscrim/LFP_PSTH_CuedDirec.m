%-----------------------------------------------------------------------------------------------------------------------
%-- LFP_PSTH_CuedDirec.m -- Plot PSTHs for each stimulus condition based on
%-- raw lfp signal (5-200Hz)
%--	VR, 9/21/05
%-----------------------------------------------------------------------------------------------------------------------

function LFP_PSTH_CuedDirec(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

%get the column of values of directions in the dots_params matrix
direction = data.dots_params(DOTS_DIREC,:,PATCH1);
unique_direction = munique(direction');
Pref_direction = data.one_time_params(PREFERRED_DIRECTION);
if (unique_direction(1) ~= Pref_direction) %reorder so that Pref_direction is first in unique_direction
    unique_direction = unique_direction(end:-1:1);
end
    
%get the motion coherences
coherence = data.dots_params(DOTS_COHER, :, PATCH1);
unique_coherence = munique(coherence');

%get the cue validity: -1=Invalid; 0=Neutral; 1=Valid; 2=CueOnly
cue_val = data.cue_params(CUE_VALIDITY,:,PATCH2);
unique_cue_val = munique(cue_val');
cue_val_names = {'NoCue','Invalid','Neutral','Valid','CueOnly'};
NOCUE = -2; INVALID = -1; NEUTRAL = 0; VALID = 1; CUEONLY = 2;

%get the cue directions
cue_direc = data.cue_params(CUE_DIREC, :, PATCH1);
unique_cue_direc = munique(cue_direc');
%cue_dir_type = 1 if PrefDir, 0 if Neutral Cue, -1 if Null Cue
cue_dir_type = logical( (squeeze_angle(cue_direc) == Pref_direction) & (cue_val ~= NEUTRAL) ) - logical( (squeeze_angle(cue_direc) ~= Pref_direction) & (cue_val ~= NEUTRAL) );
unique_cue_dir_type = munique(cue_dir_type');
cue_dir_typenames = {'Null','Neutral','Pref'};

%compute cue types - 0=neutral, 1=directional, 2=cue_only
cue_type = abs(cue_val); %note that both invalid(-1) and valid(+1) are directional
unique_cue_type = munique(cue_type');

%get whether the trial was correct or not
trial_outcomes = (data.misc_params(OUTCOME, :) == CORRECT);
%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (coherence == data.one_time_params(NULL_VALUE)) );

% keyboard

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(coherence);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get outcome for each trial: 0=incorrect, 1=correct
trial_outcomes = logical (data.misc_params(OUTCOME,:) == CORRECT);
trial_choices = ~xor((direction==Pref_direction),trial_outcomes); %0 for Null Choices, 1 for Pref Choices

linetypes = {'b-','r-','g-'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %some temporary stuff for testing timing
% %trials = [1:53, 55:100];
% for i = 1:length(trials)
% sync(i) = find(data.spike_data(2,:,trials(i))~=0,1);
% cueon(i) = find(data.event_data(1,:,trials(i))==CUE_ON_CD);
% stimstart(i) = find(data.event_data(1,:,trials(i))==VSTIM_ON_CD);
% cuediode(i) = find(data.spike_data(1,:,trials(i))~=0,1);
% stimdiode(i) = find(data.spike_data(1,stimstart(i)-100:end,trials(i))~=0,1)+stimstart(i)-100;
% end
% figure
% temph = cuediode-cueon; subplot(411); hist(temph); 
% title(sprintf('Cue diode-code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = sync-stimstart; subplot(412); hist(temph);
% title(sprintf('Sync-Code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = stimdiode-stimstart; subplot(413); hist(temph);
% title(sprintf('Stim: diode-code: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% temph = stimdiode-sync; subplot(414); hist(temph);
% title(sprintf('Stim: diode-sync: Range=[%3.1f:%3.1f] Med=%3.1f, Mean=%3.1f',min(temph),max(temph),median(temph),mean(temph)));
% xlabel('Time (ms)');
% keyboard


%first align the psths with the stimulus events - cue onset, motion onset

%first compute the psth centered around the cue onset, and a psth centered around the stimulus onset
precue = 200; %time to show before the cue starts
postcue = 400; %time to show after cue starts
prestim = 300; %time to display before the visual stimulus
poststim = 1100; %time to display after the visual stimulus
binwidth = 25; %in ms (used for psth)
bw = 50; %in ms, used for roc
spksamprate = 1000;
stddev = sqrt(2*15^2); %in ms, std dev of guassian used for filtering
stddev = 15; 
buff = 3*stddev; 
gaussfilt = normpdf([1:2:2*buff+1],buff+1,stddev); %gaussian filter 3 std.dev's wide
long = 200; %extra buffer to save to allow for extra smoothing later
cue_timing_offset = 46; %in ms, time between CUE_ON_CD and detectable light on screen; use to offset cue onset.
% stim_timing_offset = 12; %in ms, time between first sync pulse (*NOT* VSTIM_ON_CD) and detectable light on screen
stim_timing_offset = 52; %in ms, median time between VSTIM_ON_CD and first detectable light on screen

%now make psths from ALL trials to produce normalization values
select = trials(select_trials);
for m = 1:length(select)
    full_raster(m,:) = data.lfp_data(1,:,m);
    temp_sm_raster = conv(gaussfilt, full_raster(m,:));
    sm_full_raster(m,:) = temp_sm_raster(buff+1:end-buff);
    
    t_infixwin = find(data.event_data(1,:,select(m)) == IN_FIX_WIN_CD);
    targon_raster(m,:) = data.lfp_data(1,round((t_infixwin-250)./2):round((t_infixwin+250)./2),m);
    temp_sm_raster = conv(gaussfilt, targon_raster(m,:));
    sm_targon_raster(m,:) = temp_sm_raster(buff+1:end-buff);

    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
    sacc_raster(m,:) = data.lfp_data(1,round((t_sacc-250)./2):round((t_sacc+250)./2),m);
    temp_sm_raster = conv(gaussfilt, sacc_raster(m,:));
    sm_sacc_raster(m,:) = temp_sm_raster(buff+1:end-buff);
end
sm_all_full_psth = sum(sm_full_raster,1)./length(select).*spksamprate;
sm_all_targon_psth = sum(sm_targon_raster,1)./length(select).*spksamprate;
sm_all_sacc_psth = sum(sm_sacc_raster,1)./length(select).*spksamprate;
normval = [max(sm_all_full_psth) max(sm_all_targon_psth) max(sm_all_sacc_psth)];
clear sacc_raster sm_sacc_raster;
num_trials = zeros(length(unique_coherence),2,length(unique_cue_dir_type),2);

for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                prestim_raster{i,j,k}(m,:) = data.lfp_data(1,round((t_stimon-prestim-buff)./2):round((t_stimon+poststim+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
            end
            sm_prestim_psth{i,j,k} = sum(sm_prestim_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            prestim_psth{i,j,k} = sum(prestim_raster{i,j,k},1)./length(select).*spksamprate; %psth is NOT binned
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0\
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                num_trials(i,j,k,g) = length(select);
                %misc: save out raw rasters?  bigger 'long' window for
                %yet more smoothing!
                for m = 1:length(select)
                    t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    ungrouped_prestim_raster{i,j,k,g}(m,:) = data.lfp_data(1, round((t_stimon-prestim-buff)./2):round((t_stimon+poststim+buff)./2), select(m));
                    temp_sm_raster = conv(gaussfilt, ungrouped_prestim_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                    sm_ungrouped_prestim_raster{i,j,k,g}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
                end
                if length(select) > 0
                    sm_ungrouped_prestim_psth{i,j,k,g} = sum(sm_ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    ungrouped_prestim_psth{i,j,k,g} = sum(ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %psth is NOT binned
                else
                    sm_ungrouped_prestim_psth{i,j,k,g} = zeros(1,(prestim+poststim)/2+1);
                    ungrouped_prestim_psth{i,j,k,g} = zeros(1,(prestim+poststim)/2+1);
                end
            end
        end
        %now compute a running roc metric for the two choices
        for v = 1:(prestim+poststim)/2+1 %time bin
            if isempty(prestim_raster{i,1,k}) | isempty(prestim_raster{i,2,k})
                prestim_roc{i,k}(v) = NaN;
            else
                pc = sm_prestim_raster{i,1,k}(:,v);
                nc = sm_prestim_raster{i,2,k}(:,v);
                prestim_roc{i,k}(v) = rocn(pc,nc,100);
            end
        end
    end
    %repeat this collapsing across all coherences for the cue response
    for j = 1:2 %again for the two choices - a little kludgey organization but allows roc computation and inclusion of cue only trials
        select = trials(select_trials & (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) );
        for m = 1:length(select)
            t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
            postcue_raster{j,k}(m,:) = data.lfp_data(1,round((t_cueon-precue-buff)./2):round((t_cueon+postcue+buff)./2), select(m));
            temp_sm_raster = conv(gaussfilt, postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
            sm_postcue_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
        end
        sm_postcue_psth{j,k} = sum(sm_postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
        postcue_psth{j,k} = sum(postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
    end 
    %also combine the two directions in the postcue to get a single postcue psth
    sm_postcue_combined_raster{k} = [sm_postcue_raster{1,k}; sm_postcue_raster{2,k}];
    sm_postcue_combined_psth{k} = sum(sm_postcue_combined_raster{k},1)./size(sm_postcue_combined_raster{k},1).*spksamprate;
    %now compute ROC
    for v = 1:(precue+postcue)/2+1 %time bin
        if isempty(postcue_raster{1,k}) | isempty(postcue_raster{2,k})
            postcue_roc{k}(v) = NaN;
        else
            pc = postcue_raster{1,k}(:,v);
            nc = postcue_raster{2,k}(:,v);
            postcue_roc{k}(v) = rocn(pc,nc,100);
        end
    end
end

%find bounds of the psths
yl = repmat([inf -inf],length(unique_coherence),1);
for j = 1:length(unique_coherence)
    temp = prestim_psth(j,:,:);
    for i = 1:prod(size(temp))
        if (min(temp{i})<yl(j,1)),  yl(j,1) = min(temp{i});  end
        if (max(temp{i})>yl(j,2)),  yl(j,2) = max(temp{i});  end
    end
end

yl_postcue = [inf -inf];
for i = 1:prod(size(postcue_psth))
    if (min(postcue_psth{i})<yl_postcue(1)),  yl_postcue(1) = min(postcue_psth{i});  end
    if (max(postcue_psth{i})>yl_postcue(2)),  yl_postcue(2) = max(postcue_psth{i});  end
end

%now plot the peristimulus psths
postcue_x = [-precue:2:(2*length(sm_postcue_psth{1,1,1})-precue-1)];
prestim_x = [-prestim:2:(2*length(sm_prestim_psth{1,1,1})-prestim-1)];
h(1)=figure;
set(h(1),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Peri-Stimulus Time Histogram',FILE));

for j = 1:2 %PrefChoice = 1; NullChioce=2;
    %first plot the peri-CueOnset psth, then underneath plot the peri-VStim psths
    subplot(1+length(unique_coherence), 2, j); hold on;
    for k = 1:length(unique_cue_dir_type)
        plot(postcue_x,postcue_psth{j,k},linetypes{k});
    end
    axis tight; ylim(yl_postcue);
    xlabel('Time about Cue Onset');
    if j==1
        ylabel('F.R.{Hz}');
        title(sprintf('%s: PrefDir Choices',FILE));
%         legh=legend('NullDir','Neutral','PrefDir','Location','NorthEast');
%         set(legh,'box','off');
    else
        title('NullDir Choices');
    end
    for i = 1:length(unique_coherence)
        subplot(1+length(unique_coherence), 2, i*2+j);
        hold on;
        for k = 1:length(unique_cue_dir_type)
            if ~( isempty(prestim_psth{i,1,k}) | isempty(prestim_psth{i,2,k}) )
                plot(prestim_x,prestim_psth{i,j,k},linetypes{k});
            end
        end
        axis tight; ylim(yl(i,:));
        if j==1
            ylabel(sprintf('Coh= %3.1f%%',unique_coherence(i)));
        end
        if i==1
            
        elseif i==length(unique_coherence)
            xlabel('Time about VStim Onset (ms)');
        end
    end
end

%now plot the roc time courses per coherence
h(2)=figure;
set(h(2),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: ROC',FILE));
for i = 1:length(unique_coherence)
    subplot(length(unique_coherence)+1,1,i+1); hold on;    
    for k = 1:length(unique_cue_dir_type)
        plot(prestim_x,prestim_roc{i,k},linetypes{k});
    end
    axis tight
    plot(xlim, [0.5 0.5], 'k:');
    if i==length(unique_coherence)
        xlabel('Time about VStim Onset (ms)');
    end
    ylabel(sprintf('Coh = %6.1f',unique_coherence(i)));
end
%now plot the roc time course for the cue
subplot(length(unique_coherence)+1,1,1); hold on;
for k = 1:length(unique_cue_dir_type)
    plot(postcue_x,postcue_roc{k}, linetypes{k});
end
axis tight
plot(xlim,[0.5 0.5], 'k:');
xlabel('Time about Cue Onset (ms)'); ylabel('ROC');
%ylim([0 1]);
title(sprintf('%s: ROC values, sorted by cue direction',FILE));


% keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%now repeat this around saccades
%first compute the psth centered around the saccade onset
presacc = 400; %time to show before the saccade starts
postsacc = 200; %time to show after saccade starts


for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            for m = 1:length(select)
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
                sacc_raster{i,j,k}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff)./2):round((t_sacc+postsacc+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, sacc_raster{i,j,k}(m,:));
                sm_sacc_raster{i,j,k}(m,:) = temp_sm_raster(buff+1:end-buff);
            end
            sm_sacc_psth{i,j,k} = sum(sm_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            sacc_psth{i,j,k} = sum(sacc_raster{i,j,k},1)./length(select).*spksamprate;
        end
        for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0\
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
            %misc: save out raw rasters?  bigger 'long' window for yet more smoothing!
            for m = 1:length(select)
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD,1);
                ungrouped_sacc_raster{i,j,k,g}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff)./2):round((t_sacc+postsacc+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, ungrouped_sacc_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                sm_ungrouped_sacc_raster{i,j,k,g}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
            end
            if length(select) > 0
                sm_ungrouped_sacc_psth{i,j,k,g} = sum(sm_ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                ungrouped_sacc_psth{i,j,k,g} = sum(ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %psth is NOT binned
            else
                sm_ungrouped_sacc_psth{i,j,k,g} = zeros(1,(presacc+postsacc+1)/2);
                ungrouped_sacc_psth{i,j,k,g} = zeros(1,(presacc+postsacc+1)/2);
            end
        end

        %now compute a running roc metric for the two choices
        for v = 1:(presacc+postsacc)/2+1
            if isempty(sacc_raster{i,1,k}) | isempty(sacc_raster{i,2,k})
                sacc_roc{i,k}(v) = NaN;
            else
                pc = sacc_raster{i,1,k}(:,v);
                nc = sacc_raster{i,2,k}(:,v);
                sacc_roc{i,k}(v) = rocn(pc,nc,100);
            end
        end
    end
end
%find bounds of the psths
yl = repmat([inf -inf],length(unique_coherence),1);
for j = 1:length(unique_coherence)
    temp = sacc_psth(j,:,:);
    for i = 1:prod(size(temp))
        if (min(temp{i})<yl(j,1)),  yl(j,1) = min(temp{i});  end
        if (max(temp{i})>yl(j,2)),  yl(j,2) = max(temp{i});  end
    end
end
%now plot the peristimulus psths
sacc_x = [-presacc:2:(2*length(sacc_psth{1,1})-presacc-1)];
h(3)=figure;
set(h(3),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Peri-Saccadic Time Histogram',FILE));
for j = 1:2 %PrefChoice = 1; NullChioce=2;
    for i = 1:length(unique_coherence)
        subplot(length(unique_coherence), 2, (i-1)*2+j);
        hold on;
        for k = 1:length(unique_cue_dir_type)
            plot(sacc_x,sacc_psth{i,j,k},linetypes{k});
        end
        axis tight; ylim(yl(i,:));
        plot([0 0],ylim,'k');
        if j==1
            ylabel(sprintf('Coh= %3.1f%%',unique_coherence(i)));
        end
        if i==1
            if j==1
                title(sprintf('%s: PrefDir Choices',FILE));
            else
                title('NullDir Choices');
            end
        elseif i==length(unique_coherence)
            xlabel('Time about Saccade Onset (ms)');
        end
    end
end

%now plot the roc time courses per coherence
h(4)=figure;
set(h(4),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Saccade-aligned ROC',FILE));
for i = 1:length(unique_coherence)
    subplot(length(unique_coherence),1,i); hold on;    
    for k = 1:length(unique_cue_dir_type)
        plot(sacc_x,sacc_roc{i,k},linetypes{k});
    end
    axis tight
    plot(xlim, [0.5 0.5], 'k:');
    if i==1
        title(sprintf('%s: ROC values, sorted by cue direction',FILE));
    elseif i==length(unique_coherence)
        xlabel('Time about Saccade Onset (ms)');
    end
    ylabel(sprintf('Coh = %6.1f',unique_coherence(i)));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now repeat for cue only trials
precue_co = 200;
postcue_co = 200+150+1000;
prestim_co = -800; %200 before FP off
poststim_co = 1400;

for k = 1:2:length(unique_cue_dir_type)
    for j = 1:2
        select = trials(select_trials & (trial_choices == 2-j) & ...
            (cue_dir_type == unique_cue_dir_type(k)) & (cue_val == CUEONLY) );
        if isempty(select)
            sm_co_postcue_raster{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            sm_co_postcue_psth{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            sm_co_prestim_raster{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            sm_co_prestim_psth{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            sm_co_sacc_raster{j,k} = NaN.*ones(1,presacc+postsacc+1);
            sm_co_sacc_psth{j,k} = NaN.*ones(1,presacc+postsacc+1);
            co_postcue_raster{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            co_postcue_psth{j,k} = NaN.*ones(1,precue_co+postcue_co+1);
            co_prestim_raster{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            co_prestim_psth{j,k} = NaN.*ones(1,prestim_co+poststim_co+1);
            co_sacc_raster{j,k} = NaN.*ones(1,presacc+postsacc+1);
            co_sacc_psth{j,k} = NaN.*ones(1,presacc+postsacc+1);
        else
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);

                co_postcue_raster{j,k}(m,:) = data.lfp_data(1,round((t_cueon-precue_co-buff)./2):round((t_cueon+postcue_co+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, co_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                sm_co_postcue_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges

                co_prestim_raster{j,k}(m,:) = data.lfp_data(1,round((t_stimon-prestim_co-buff)./2):round((t_stimon+poststim_co+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, co_prestim_raster{j,k}(m,:)); %convolve with the gaussian filters
                sm_co_prestim_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges

                co_sacc_raster{j,k}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff)./2):round((t_sacc+postsacc+buff)./2), select(m));
                temp_sm_raster = conv(gaussfilt, co_sacc_raster{j,k}(m,:));
                sm_co_sacc_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff);
            end

            sm_co_postcue_psth{j,k} = sum(sm_co_postcue_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            co_postcue_psth{j,k} = sum(co_postcue_raster{j,k},1)./length(select).*spksamprate;

            sm_co_prestim_psth{j,k} = sum(sm_co_prestim_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            co_prestim_psth{j,k} = sum(co_prestim_raster{j,k},1)./length(select).*spksamprate;

            sm_co_sacc_psth{j,k} = sum(sm_co_sacc_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            co_sacc_psth{j,k} = sum(co_sacc_raster{j,k},1)./length(select).*spksamprate;
        end
    end

    %now compute a running roc metric for the two choices
    for v = 1:(prestim_co+poststim_co)/2+1
        if isempty(co_prestim_raster{1,k}) | isempty(co_prestim_raster{2,k})
            co_prestim_roc{k}(v) = NaN;
        else
            pc = co_prestim_raster{1,k}(:,v);
            nc = co_prestim_raster{2,k}(:,v);
            co_prestim_roc{k}(v) = rocn(pc,nc,100);
        end
    end
    for v = 1:(precue_co+postcue_co)/2+1
        if isempty(co_postcue_raster{1,k}) | isempty(co_postcue_raster{2,k})
            co_postcue_roc{k}(v) = NaN;
        else
            pc = co_postcue_raster{1,k}(:,v);
            nc = co_postcue_raster{2,k}(:,v);
            co_postcue_roc{k}(v) = rocn(pc,nc,100);
        end
    end
    for v = 1:(presacc+postsacc)/2+1
        if isempty(co_sacc_raster{1,k}) | isempty(co_sacc_raster{2,k})
            co_sacc_roc{k}(v) = NaN;
        else
            pc = co_sacc_raster{1,k}(:,v);
            nc = co_sacc_raster{2,k}(:,v);
            co_sacc_roc{k}(v) = rocn(pc,nc,100);
        end
    end
end

%now plot the timecourses and rocs on one figure
postcue_co_x = [-precue_co:2:(2*length(co_postcue_psth{1,1})-precue_co-1)];
prestim_co_x = [-prestim_co:2:(2*length(co_prestim_psth{1,1})-prestim_co-1)];
prestim_co_x = [-200:2:(2*length(co_prestim_psth{1,1})-200-1)]; %relative to FP offset, rather than "motion" onset
h(5) = figure;
set(h(5),'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: CueOnly',FILE));

subplot(6,2,1); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(postcue_co_x, co_postcue_psth{1,k}, linetypes{k})    
end
xlabel('Time about cue onset'); ylabel('FR (Hz)');
axis tight; yl = ylim; 
title(sprintf('%s: Pref Choices',FILE));

subplot(6,2,2); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(postcue_co_x, co_postcue_psth{2,k}, linetypes{k});
end
xlabel('Time about cue onset'); 
axis tight; 
title('Null Choices');
yl = [min([min(ylim) min(yl)]) max([max(ylim) max(yl)])];
ylim(yl); subplot(6,2,1); hold on; ylim(yl);

subplot(6,2,3:4); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(postcue_co_x, co_postcue_roc{k}, linetypes{k});
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about cue onset'); ylabel('ROC');


subplot(6,2,5); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(prestim_co_x, co_prestim_psth{1,k}, linetypes{k});
end
xlabel('Time about go signal'); ylabel('FR (Hz)');
axis tight; yl = ylim;

subplot(6,2,6); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(prestim_co_x, co_prestim_psth{2,k}, linetypes{k});
end
xlabel('Time about go signal'); 
axis tight; 
yl = [min([min(ylim) min(yl)]) max([max(ylim) max(yl)])];
ylim(yl); subplot(6,2,5); hold on; ylim(yl);

subplot(6,2,7:8); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(prestim_co_x, co_prestim_roc{k}, linetypes{k});
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about go signal (FP off)'); ylabel('ROC');


subplot(6,2,9); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(sacc_x, co_sacc_psth{1,k}, linetypes{k});
end
xlabel('Time about saccade onset'); ylabel('FR (Hz)');
axis tight; yl = ylim;

subplot(6,2,10); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(sacc_x, co_sacc_psth{2,k}, linetypes{k});
end
xlabel('Time about saccade onset'); 
axis tight; 
yl = [min([min(ylim) min(yl)]) max([max(ylim) max(yl)])];
ylim(yl); subplot(6,2,9); hold on; ylim(yl);

subplot(6,2,11:12); hold on;
for k = 1:2:length(unique_cue_dir_type)
    plot(sacc_x, co_sacc_roc{k}, linetypes{k});
end
axis tight; plot(xlim, [0.5 0.5], 'k:');
xlabel('Time about saccade onset'); ylabel('ROC');


REPRINT_DATA = 0;
if REPRINT_DATA
    print(h(3), '-dwinc');
    print(h(4), '-dwinc');
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%
% now recompute all the rasters tacking on some extra time on each end to
% allow additional smoothing
for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                long_prestim_raster{i,j,k}(m,:) = data.lfp_data(1,round((t_stimon-prestim-buff-long)./2):round((t_stimon+poststim+buff+long)./2), select(m));
                temp_sm_raster = conv(gaussfilt, long_prestim_raster{i,j,k}(m,:)); %convolve with the gaussian filters
                long_sm_prestim_raster{i,j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
            end
            long_sm_prestim_psth{i,j,k} = sum(long_sm_prestim_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_prestim_psth{i,j,k} = sum(long_prestim_raster{i,j,k},1)./length(select).*spksamprate; 
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                for m = 1:length(select)
                    t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset;
                    long_ungrouped_prestim_raster{i,j,k,g}(m,:) = data.lfp_data(1,round((t_stimon-prestim-buff-long)./2):round((t_stimon+poststim+buff+long)./2), select(m));
                    temp_sm_raster = conv(gaussfilt, long_ungrouped_prestim_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                    long_sm_ungrouped_prestim_raster{i,j,k,g}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
                end
                if length(select) > 0
                    long_sm_ungrouped_prestim_psth{i,j,k,g} = sum(long_sm_ungrouped_prestim_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    long_ungrouped_prestim_psth{i,j,k,g} = sum(long_ungrouped_prestim_raster{i,j,k,g}(:,buff+1:end-buff),1)./length(select).*spksamprate; %psth is NOT binned
                else
                    long_sm_ungrouped_prestim_psth{i,j,k,g} = zeros(1,(prestim+poststim+2*long)/2+1);
                    long_ungrouped_prestim_psth{i,j,k,g} = zeros(1,(prestim+poststim+2*long)/2+1);
                end
                
            end
        end
    end
    %repeat this collapsing across all coherences for the cue response
    for j = 1:2 %again for the two choices - a little kludgey organization but allows roc computation and inclusion of cue only trials
        select = trials(select_trials & (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) );
        for m = 1:length(select)
            t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
            long_postcue_raster{j,k}(m,:) = data.lfp_data(1,round((t_cueon-precue-buff-long)./2):round((t_cueon+postcue+buff+long)./2), select(m));
            temp_sm_raster = conv(gaussfilt, long_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
            long_sm_postcue_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
        end
        long_sm_postcue_psth{j,k} = sum(long_sm_postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
        long_postcue_psth{j,k} = sum(long_postcue_raster{j,k},1)./length(select).*spksamprate; %psth is NOT binned
    end 
    %also combine the two directions in the postcue to get a single postcue psth
    long_sm_postcue_combined_raster{k} = [long_sm_postcue_raster{1,k}; long_sm_postcue_raster{2,k}];
    long_sm_postcue_combined_psth{k} = sum(long_sm_postcue_combined_raster{k},1)./size(long_sm_postcue_combined_raster{k},1).*spksamprate;
    long_postcue_combined_raster{k} = [long_postcue_raster{1,k}; long_postcue_raster{2,k}];
    long_postcue_combined_psth{k} = sum(long_postcue_combined_raster{k},1)./size(long_postcue_combined_raster{k},1).*spksamprate;
end
for k = 1:length(unique_cue_dir_type)
    for i = 1:length(unique_coherence)
        for j = 1:2 %PrefChoice=1, NullChoice=2
            %first select the relevant trials and get a raster
            select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & (cue_val ~= CUEONLY) );
            for m = 1:length(select)
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);
                long_sacc_raster{i,j,k}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff-long)./2):round((t_sacc+postsacc+buff+long)./2), select(m));
                temp_sm_raster = conv(gaussfilt, long_sacc_raster{i,j,k}(m,:));
                long_sm_sacc_raster{i,j,k}(m,:) = temp_sm_raster(buff+1:end-buff);
            end
            long_sm_sacc_psth{i,j,k} = sum(long_sm_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            long_sacc_psth{i,j,k} = sum(long_sacc_raster{i,j,k},1)./length(select).*spksamprate; %sum and scale rasters
            for g = 1:length(unique_direction) %Motion: PrefDir = 1, NullDir = 0
                select = trials(select_trials & (coherence == unique_coherence(i)) & ...
                    (trial_choices == 2-j) & (cue_dir_type == unique_cue_dir_type(k)) & ...
                    (direction == unique_direction(g)) & (cue_val ~= CUEONLY) );
                for m = 1:length(select)
                    t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD,1);
                    long_ungrouped_sacc_raster{i,j,k,g}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff-long)./2):round((t_sacc+postsacc+buff+long)./2), select(m));
                    temp_sm_raster = conv(gaussfilt, long_ungrouped_sacc_raster{i,j,k,g}(m,:)); %convolve with the gaussian filters
                    long_sm_ungrouped_sacc_raster{i,j,k,g}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges
                end
                if length(select) > 0
                    long_sm_ungrouped_sacc_psth{i,j,k,g} = sum(long_sm_ungrouped_sacc_raster{i,j,k,g},1)./length(select).*spksamprate; %sum and scale rasters to get psth
                    long_ungrouped_sacc_psth{i,j,k,g} = sum(long_ungrouped_sacc_raster{i,j,k,g}(:,buff+1:end-buff),1)./length(select).*spksamprate; %psth is NOT binned
                else
                    long_sm_ungrouped_sacc_psth{i,j,k,g} = zeros(1,(presacc+postsacc+2*long)/2+1);
                    long_ungrouped_sacc_psth{i,j,k,g} = zeros(1,(presacc+postsacc+2*long)/2+1);
                end
            end
        end
    end
end
for k = 1:length(unique_cue_dir_type)
    for j = 1:2
        select = trials(select_trials & (trial_choices == 2-j) & ...
            (cue_dir_type == unique_cue_dir_type(k)) & (cue_val == CUEONLY) );
        if isempty(select)
            long_sm_co_postcue_raster{j,k} = NaN;
            long_sm_co_postcue_psth{j,k} = NaN.*ones(precue_co+postcue_co+2*long+1,1);
            long_sm_co_prestim_raster{j,k} = NaN;
            long_sm_co_prestim_psth{j,k} = NaN.*ones(prestim_co+poststim_co+2*long+1,1);
            long_sm_co_sacc_raster{j,k} = NaN;
            long_sm_co_sacc_psth{j,k} = NaN.*ones(presacc+postsacc+2*long+1,1);
            long_co_postcue_raster{j,k} = NaN;
            long_co_postcue_psth{j,k} = NaN.*ones(precue_co+postcue_co+2*long+1,1);
            long_co_prestim_raster{j,k} = NaN;
            long_co_prestim_psth{j,k} = NaN.*ones(prestim_co+poststim_co+2*long+1,1);
            long_co_sacc_raster{j,k} = NaN;
            long_co_sacc_psth{j,k} = NaN.*ones(presacc+postsacc+2*long+1,1);
        else
            for m = 1:length(select)
                % t_stimon = find(data.spike_data(2,:,select(m)) == 1,1) + stim_timing_offset; %relative to first sync pulse
                t_stimon = find(data.event_data(1,:,select(m)) == VSTIM_ON_CD,1) + stim_timing_offset; 
                t_cueon = find(data.event_data(1,:,select(m)) == CUE_ON_CD) + cue_timing_offset;
                t_sacc = find(data.event_data(1,:,select(m)) == SACCADE_BEGIN_CD);

                long_co_postcue_raster{j,k}(m,:) = data.lfp_data(1,round((t_cueon-precue_co-buff-long)./2):round((t_cueon+postcue_co+buff+long)./2), select(m));
%                 long_co_postcue_raster{j,k}(m,:) = data.lfp_data(1,round((t_cueon-precue-buff-long)./2):round((t_cueon+postcue+buff+long)./2), select(m));
                temp_sm_raster = conv(gaussfilt, long_co_postcue_raster{j,k}(m,:)); %convolve with the gaussian filters
                long_sm_co_postcue_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges

                long_co_prestim_raster{j,k}(m,:) = data.lfp_data(1,round((t_stimon-prestim_co-buff-long)./2):round((t_stimon+poststim_co+buff+long)./2), select(m));
%                 long_co_prestim_raster{j,k}(m,:) = data.lfp_data(1,round((t_stimon-prestim-buff-long)./2):round((t_stimon+poststim+buff+long)./2), select(m));
                temp_sm_raster = conv(gaussfilt, long_co_prestim_raster{j,k}(m,:)); %convolve with the gaussian filters
                long_sm_co_prestim_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff); %lop off the edges

                long_co_sacc_raster{j,k}(m,:) = data.lfp_data(1,round((t_sacc-presacc-buff-long)./2):round((t_sacc+postsacc+buff+long)./2), select(m));
                temp_sm_raster = conv(gaussfilt, long_co_sacc_raster{j,k}(m,:));
                long_sm_co_sacc_raster{j,k}(m,:) = temp_sm_raster(buff+1:end-buff);
            end

            long_sm_co_postcue_psth{j,k} = sum(long_sm_co_postcue_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_postcue_psth{j,k} = sum(long_co_postcue_raster{j,k},1)./length(select).*spksamprate;

            long_sm_co_prestim_psth{j,k} = sum(long_sm_co_prestim_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_prestim_psth{j,k} = sum(long_co_prestim_raster{j,k},1)./length(select).*spksamprate;

            long_sm_co_sacc_psth{j,k} = sum(long_sm_co_sacc_raster{j,k},1)./length(select).*spksamprate; %sum and scale rasters to get psth
            long_co_sacc_psth{j,k} = sum(long_co_sacc_raster{j,k},1)./length(select).*spksamprate;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%
%Now compute the zero-pct crossing of the fit for each cue_type.  
for k = 1:length(unique_cue_dir_type)
    d = [];
    for i = 1:length(unique_coherence)
        total = sum(logical( select_trials & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k)) ));
        corr = sum(logical( select_trials & trial_outcomes & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k)) ));
        pct_corr(k,i) = corr./total;
        d = [d; unique_coherence(i) pct_corr(k,i) total];
    end
    [alpha(k) beta(k) offset(k)] = weibull_bs_fit(d);
end
        


%%%%%%%%%%%
%now save the following variables to a common matrix and save the file
%sm_prestim_psth{i,j,k}, sm_postcue_psth{j,k}, sm_sacc_psth{i,j,k},
%sm_postcue_combined_psth{k}
%sm_co_prestim_psth{j,k}, sm_co_postcue_psth{j,k}, sm_co_sacc_psth{i,j,k} 

SAVEDATA = 0;

if SAVEDATA

    SAVEFILE = sprintf('Z:\\Data\\Tempo\\Baskin\\Analysis\\LIP_PSTH\\%s_lfp_psth_summary4.mat',FILE(1:8));
    file = FILE; coher = unique_coherence';
    save(SAVEFILE, 'file', 'coher', 'normval', 'sm_postcue_combined_psth', 'sm_postcue_psth', ...
        'sm_co_postcue_psth', 'sm_co_prestim_psth', 'sm_co_sacc_psth', 'sm_prestim_psth', 'sm_sacc_psth', ...
        'long_sm_postcue_combined_psth', 'long_sm_postcue_psth', 'long_sm_co_postcue_psth', 'long_sm_co_prestim_psth', ...
        'long_sm_co_sacc_psth', 'long_sm_prestim_psth', 'long_sm_sacc_psth', ...
        'sm_ungrouped_prestim_psth', 'long_sm_ungrouped_prestim_psth', 'long_ungrouped_prestim_psth', ...
        'sm_ungrouped_sacc_psth', 'long_sm_ungrouped_sacc_psth','long_ungrouped_sacc_psth',...
        'num_trials', 'offset');
    
%     SAVEFILE = 'Z:\LabTools\Matlab\TEMPO_Analysis\ProtocolSpecific\CuedDirectionDiscrim\cum_lip_psth3.mat';
%     load(SAVEFILE);
% 
%     cum_file{length(cum_file)+1} = FILE;
%     cum_coher = [cum_coher; unique_coherence'];
%     cum_normval = [cum_normval; normval];
%     for k = 1:length(unique_cue_dir_type)
%         cum_postcue_combined_psth{k}(end+1,:) = sm_postcue_combined_psth{k};
%         for j = 1:2 %prefchoice = 1, nullchoice = 2
%             cum_postcue_psth{j,k}(end+1,:) = sm_postcue_psth{j,k};
%             cum_co_postcue_psth{j,k}(end+1,:) = sm_co_postcue_psth{j,k};
%             cum_co_prestim_psth{j,k}(end+1,:) = sm_co_prestim_psth{j,k};
%             cum_co_sacc_psth{j,k}(end+1,:) = sm_co_sacc_psth{j,k};
%             for i = 1:length(unique_coherence)
%                 cum_prestim_psth{i,j,k}(end+1,:) =
%                 sm_prestim_psth{i,j,k};
%                 cum_sacc_psth{i,j,k}(end+1,:) = sm_sacc_psth{i,j,k};
%             end
%         end
%     end
% 
%     save(SAVEFILE, 'cum_file','cum_coher','cum_normval',...
%         'cum_postcue_combined_psth','cum_postcue_psth','cum_prestim_psth','cum_sacc_psth',...
%         'cum_co_postcue_psth','cum_co_prestim_psth','cum_co_sacc_psth');
end

end

% line below initializes variables stored in cum_lip_psth.mat
% cum_file = []; cum_coher = []; cum_postcue_combined_psth = repmat({[]},[1,3]); cum_normval = [];
% cum_postcue_psth = repmat({[]},[2,3]); cum_prestim_psth = repmat({[]},[5,2,3]); cum_sacc_psth = repmat({[]},[5,2,3]); 
% cum_co_postcue_psth = repmat({[]},[2,3]); cum_co_prestim_psth = repmat({[]},[2,3]); cum_co_sacc_psth = repmat({[]},[2,3]); 
