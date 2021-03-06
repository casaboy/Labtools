%-----------------------------------------------------------------------------------------------------------------------
%-- CueDirecEffects.m -- RMS LFP activity and spikes during delay period and during stimulus for various cue directions.
%--	VR, 9/21/05 
%-----------------------------------------------------------------------------------------------------------------------

function CueDirecEffects(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

global cum_delay_LFP cum_delay_spikes cum_delay_LFP_bp; %to allow activity to be cumulated across trials
SAVE_GLOBAL_DATA = 1;

%get the column of values of directions in the dots_params matrix
direction = data.dots_params(DOTS_DIREC,BegTrial:EndTrial,PATCH1);
unique_direction = munique(direction');
Pref_direction = data.one_time_params(PREFERRED_DIRECTION);
unique_direction = [unique_direction(find(unique_direction==Pref_direction)) unique_direction(find(unique_direction~=Pref_direction))];
    %above line puts the preferred direction in the front of the list... useful for plotting.

%get the motion coherences
coherence = data.dots_params(DOTS_COHER, BegTrial:EndTrial, PATCH1);
unique_coherence = munique(coherence');

%get the cue validity: -1=Invalid; 0=Neutral; 1=Valid; 2=CueOnly
cue_val = data.cue_params(CUE_VALIDITY,BegTrial:EndTrial,PATCH2);
unique_cue_val = munique(cue_val');
cue_val_names = {'NoCue','Invalid','Neutral','Valid','CueOnly'};

%get the cue directions
cue_direc = data.cue_params(CUE_DIREC, BegTrial:EndTrial, PATCH1);
unique_cue_direc = munique(cue_direc');

%classifies each trial based on the cue direction: 1=PrefDir, -1=NullDir, 0=Neutral, 2=CueOnly (both cue directions)
cue_dir_type = cue_val;
for i=1:length(cue_dir_type)
    if abs(cue_dir_type(i))==1
        cue_dir_type(i) = -1+2*(squeeze_angle(Pref_direction)==squeeze_angle(cue_direc(i)));
    end
end
unique_cue_dir_type = munique(cue_dir_type');
NDCUE = -1; NEUCUE = 0; PDCUE = 1;
cue_dir_type_names = {'NoCue','NullDir','Neutral','PrefDir','CueOnly'};

%compute cue types - 0=neutral, 1=directional, 2=cue_only
cue_type = abs(cue_val); %note that invalid(-1) and valid(+1) are directional
unique_cue_type = munique(cue_type');

%now, select trials that fall between BegTrial and EndTrial
trials = 1:size(data.dots_params,2);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get outcome for each trial: 0=incorrect, 1=correct
trials_outcomes = logical (data.misc_params(OUTCOME,BegTrial:EndTrial) == CORRECT);

nreps = floor(length(cue_type)/60); %assumes the total number of trials is a multiple of 60. 

%get the firing rates and lfp during delay and stim for all the trials
stim_spikes = data.spike_rates(SpikeChan, BegTrial:EndTrial);
if (isempty(data.lfp_data)) %in case the lfp data wasn't saved, fill a matrix with zeros so that the other analyses can occur
    data.lfp_data = zeros(size(data.spike_data(1,:,BegTrial:EndTrial)));
    SAVE_GLOBAL_DATA = 0;
end
for i = 1:sum(select_trials)
    start_delay(i) = find(data.event_data(1,:,i+BegTrial-1) == CUE_ON_CD);
    start_delay_lfp(i) = ceil(start_delay(i)/2);
    end_delay(i) = find(data.event_data(1,:,i+BegTrial-1) == VSTIM_ON_CD);
    end_delay_lfp(i) = floor(end_delay(i)/2);
    delay_spikes(i) = sum(data.spike_data(SpikeChan,start_delay(i):end_delay(i),i+BegTrial-1)) / length(start_delay(i):end_delay(i)) * 1000;
    %delay_spikes_end: use only last 200ms of delay period to compute delay period firing rate (or the entire period if it's a short delay trial)
    %delay_spikes_nostart: use all but the first 200ms (or the entire period if it's a short delay trial)
    if ( end_delay(i)-start_delay(i) < 200 )  
        delay_spikes_nostart(i) = delay_spikes(i);
        delay_spikes_end(i) = delay_spikes(i);
    else
        delay_spikes_nostart(i) = sum(data.spike_data(SpikeChan,start_delay(i)+200:end_delay(i),i+BegTrial-1)) / length(start_delay(i)+200:end_delay(i)) * 1000;
        delay_spikes_end(i) = sum(data.spike_data(SpikeChan,end_delay(i)-200:end_delay(i),i+BegTrial-1)) / length(end_delay(i)-200:end_delay(i)) * 1000;
    end
    %note that lfp is sampled at half the frequency as spikes, so divide bins by 2
    delay_lfp(i) = sqrt(mean( data.lfp_data(1,start_delay_lfp(i):end_delay_lfp(i),i+BegTrial-1).^2 )); 
    start_stim_lfp(i) = ceil(end_delay(i)/2); %note lfp is sampled @ 500Hz
    end_stim(i) = find(data.event_data(1,:,i+BegTrial-1) == VSTIM_OFF_CD);
    end_stim_lfp(i) = floor(end_stim(i)/2); %note lfp is sampled @ 500Hz
    stim_lfp(i) = sqrt(mean( data.lfp_data(1,start_stim_lfp(i):end_stim_lfp(i),i+BegTrial-1) .^2 ));
    
%     %do the following to get the power of lfp between 50 and 150Hz 
%     %(remove 120 Hz contribution as noise), 400 samples sampled at 500Hz
%     band = find( (500*(0:200)./400 >= 50) & (500*(0:200)./400 <= 150) & (500*(0:200)./400 ~= 120) ); 
%     lfp_stim_powerspect{i} = abs(fft(data.lfp_data(1,start_stim_lfp(i):end_stim_lfp(i),i+BegTrial-1),400)).^2 ./ 400;
%     stim_lfp_bp(i) = sum(lfp_stim_powerspect{i}(band));
%     lfp_delay_powerspect{i} = abs(fft(data.lfp_data(1,start_delay(i):end_delay(i),i+BegTrial-1),400)).^2 ./ 400;
%     delay_lfp_bp(i) = sum(lfp_delay_powerspect{i}(band));
%     
    %compute the spike_rates for the first and second half of the stimulus period
    stim_spikes_halves(1,i) = sum(data.spike_data(SpikeChan,end_delay(i):floor((end_delay(i)+end_stim(i))/2),i+BegTrial-1)) / ...
        length(end_delay(i):floor((end_delay(i)+end_stim(i))/2)) * 1000;
    stim_spikes_halves(2,i) = sum(data.spike_data(SpikeChan,floor((end_delay(i)+end_stim(i))/2)+1:end_stim(i),i+BegTrial-1)) / ...
        length(floor((end_delay(i)+end_stim(i))/2)+1:end_stim(i)) * 1000;
    stim_spikes_full(i) = sum(data.spike_data(SpikeChan,end_delay(i):end_stim(i),i+BegTrial-1)) / ...
        length(end_delay(i):end_stim(i)) * 1000;
    
end

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (coherence == data.one_time_params(NULL_VALUE)) );


%keyboard

hlist = []; %list of figure handles for saving out graphs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% first perform ANOVA of LFP during delay period using cue direction 

%get trial #s when cue is in preferred and null directions and neutral cue trials
PD_cue_trials = find( (squeeze_angle(cue_direc) == squeeze_angle(Pref_direction)) & (cue_val ~= 0));
ND_cue_trials = find( (squeeze_angle(cue_direc) ~= squeeze_angle(Pref_direction)) & (cue_val ~= 0));
neutral_cue_trials = find(cue_val == 0);

%list of all selected trials marked with -1=NullDirCues, 1=PrefDirCues, %0=remainder(neutral cues)
PD_CUEDIR = 1; NEU_CUEDIR = 0; ND_CUEDIR = -1;
signed_cue_dirs = zeros(1,sum(select_trials));
signed_cue_dirs(PD_cue_trials') = 1;
signed_cue_dirs(ND_cue_trials') = -1;

% cum_delay_LFP = {[] [] []}; cum_delay_spikes = {[] [] []}; cum_delay_LFP_bp = {[] [] []};
% if (SAVE_GLOBAL_DATA)
%     cum_delay_LFP{1} = [cum_delay_LFP{1} (delay_lfp(PD_cue_trials) - mean(delay_lfp))./std(delay_lfp)];
%     cum_delay_LFP_bp{1} = [cum_delay_LFP_bp{1} (delay_lfp_bp(PD_cue_trials) - mean(delay_lfp_bp))./std(delay_lfp_bp)];
%     cum_delay_spikes{1} = [cum_delay_spikes{1} (delay_spikes(PD_cue_trials) - mean(delay_spikes))./std(delay_spikes)];
%     cum_delay_LFP{2} = [cum_delay_LFP{2} (delay_lfp(neutral_cue_trials) - mean(delay_lfp))./std(delay_lfp)];
%     cum_delay_LFP_bp{2} = [cum_delay_LFP_bp{2} (delay_lfp_bp(neutral_cue_trials) - mean(delay_lfp_bp))./std(delay_lfp_bp)];
%     cum_delay_spikes{2} = [cum_delay_spikes{2} (delay_spikes(neutral_cue_trials) - mean(delay_spikes))./std(delay_spikes)];
%     cum_delay_LFP{3} = [cum_delay_LFP{3} (delay_lfp(ND_cue_trials) - mean(delay_lfp))./std(delay_lfp)];
%     cum_delay_LFP_bp{3} = [cum_delay_LFP_bp{3} (delay_lfp_bp(ND_cue_trials) - mean(delay_lfp_bp))./std(delay_lfp_bp)];
%     cum_delay_spikes{3} = [cum_delay_spikes{3} (delay_spikes(ND_cue_trials) - mean(delay_spikes))./std(delay_spikes)];
% end

% %% use zscores to combine across signed_coherences (do this only for stim period, of course)
% stimlfp_zscores = stim_lfp; stimspikes_zscores = stim_spikes; stimlfp_bp_zscores = stim_lfp_bp;
% %include cueonly trials initially to allow proper dir/coher indexing
% for i = 1:length(unique_direction)
%     for j = 1:length(unique_coherence)
%         indices = find( (direction == unique_direction(i)) & (coherence == unique_coherence(j)) & (cue_val ~= 2) );
%         stimlfp_zscores(indices) = zscore(stim_lfp(indices));
%         stimlfp_bp_zscores(indices) = zscore(stim_lfp_bp(indices));
%         stimspikes_zscores(indices) = zscore(stim_spikes(indices));
%     end
% end
%p_zscore_anova_stimlfp = anovan(stimlfp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
%p_zscore_anova_stimlfp_bp = anovan(stimlfp_bp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
%p_zscore_anova_stimspikes = anovan(stimspikes_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
%now remove cueonly trials
% stimlfp_zscores = stimlfp_zscores(find(cue_val~=CUEONLY)); 
% stimlfp_bp_zscores = stimlfp_bp_zscores(find(cue_val~=CUEONLY)); 
% stimspikes_zscores = stimspikes_zscores(find(cue_val~=CUEONLY));
PDcue_val_noCO_trials = PD_cue_trials( cue_val(PD_cue_trials)==VALID); %remove cueonly trials from list of PD/ND trials
PDcue_inv_noCO_trials = PD_cue_trials( cue_val(PD_cue_trials)==INVALID); %remove cueonly trials from list of PD/ND trials
NDcue_val_noCO_trials = ND_cue_trials(cue_val(ND_cue_trials)==VALID);
NDcue_inv_noCO_trials = ND_cue_trials(cue_val(ND_cue_trials)==INVALID);


% %% compute mean and std dev values
% mean_delay_lfp = [mean(delay_lfp(PD_cue_trials)); mean(delay_lfp(neutral_cue_trials)); mean(delay_lfp(ND_cue_trials))];
% std_delay_lfp  = [std(delay_lfp(PD_cue_trials)); std(delay_lfp(neutral_cue_trials)); std(delay_lfp(ND_cue_trials))];
% mean_delay_lfp_bp = [mean(delay_lfp_bp(PD_cue_trials)); mean(delay_lfp_bp(neutral_cue_trials)); mean(delay_lfp_bp(ND_cue_trials))];
% std_delay_lfp_bp  = [std(delay_lfp_bp(PD_cue_trials)); std(delay_lfp_bp(neutral_cue_trials)); std(delay_lfp_bp(ND_cue_trials))];
% mean_delay_spikes = [mean(delay_spikes(PD_cue_trials)); mean(delay_spikes(neutral_cue_trials)); mean(delay_spikes(ND_cue_trials))];
% std_delay_spikes =  [std(delay_spikes(PD_cue_trials)); std(delay_spikes(neutral_cue_trials)); std(delay_spikes(ND_cue_trials))];
% mean_stim_zlfp = [mean(stimlfp_zscores(PDcue_val_noCO_trials)); mean(stimlfp_zscores(PDcue_inv_noCO_trials)); mean(stimlfp_zscores(neutral_cue_trials)); mean(stimlfp_zscores(NDcue_inv_noCO_trials)); mean(stimlfp_zscores(NDcue_val_noCO_trials))];
% std_stim_zlfp =  [std(stimlfp_zscores(PDcue_val_noCO_trials)); std(stimlfp_zscores(PDcue_inv_noCO_trials)); std(stimlfp_zscores(neutral_cue_trials)); std(stimlfp_zscores(NDcue_inv_noCO_trials)); std(stimlfp_zscores(NDcue_val_noCO_trials))];
% mean_stim_zlfp_bp = [mean(stimlfp_bp_zscores(PDcue_val_noCO_trials)); mean(stimlfp_bp_zscores(PDcue_inv_noCO_trials)); mean(stimlfp_bp_zscores(neutral_cue_trials)); mean(stimlfp_bp_zscores(NDcue_inv_noCO_trials)); mean(stimlfp_bp_zscores(NDcue_val_noCO_trials))];
% std_stim_zlfp_bp =  [std(stimlfp_bp_zscores(PDcue_val_noCO_trials)); std(stimlfp_bp_zscores(PDcue_inv_noCO_trials)); std(stimlfp_bp_zscores(neutral_cue_trials)); std(stimlfp_bp_zscores(NDcue_inv_noCO_trials)); std(stimlfp_bp_zscores(NDcue_val_noCO_trials))];
% mean_stim_zspikes = [mean(stimspikes_zscores(PDcue_val_noCO_trials)); mean(stimspikes_zscores(PDcue_inv_noCO_trials)); mean(stimspikes_zscores(neutral_cue_trials)); mean(stimspikes_zscores(NDcue_inv_noCO_trials)); mean(stimspikes_zscores(NDcue_val_noCO_trials))];
% std_stim_zspikes =  [std(stimspikes_zscores(PDcue_val_noCO_trials)); std(stimspikes_zscores(PDcue_inv_noCO_trials)); std(stimspikes_zscores(neutral_cue_trials)); std(stimspikes_zscores(NDcue_inv_noCO_trials)); std(stimspikes_zscores(NDcue_val_noCO_trials))];
% mean_delay_spikes_end = [mean(delay_spikes_end(PD_cue_trials)); mean(delay_spikes_end(neutral_cue_trials)); mean(delay_spikes_end(ND_cue_trials))];
% mean_delay_spikes_nostart = [mean(delay_spikes_nostart(PD_cue_trials)); mean(delay_spikes_nostart(neutral_cue_trials)); mean(delay_spikes_nostart(ND_cue_trials))];



% %1-way ttest to test whether PDcue > NDcue
% [h_delayspikes,p_delayspikes]=ttest2(delay_spikes(PD_cue_trials),delay_spikes(ND_cue_trials),.05,'right');
% [h_delaylfp,p_delaylfp]=ttest2(delay_lfp(PD_cue_trials),delay_lfp(ND_cue_trials),.05,'right');
% [h_delaylfp_bp,p_delaylfp_bp]=ttest2(delay_lfp_bp(PD_cue_trials),delay_lfp_bp(ND_cue_trials),.05,'right');
% [h_stimspikes,p_stimspikes]=ttest2(stimspikes_zscores(PD_cue_trials(find(cue_val(PD_cue_trials)~=CUEONLY))),...
%     stimspikes_zscores(ND_cue_trials(find(cue_val(ND_cue_trials)~=CUEONLY))),.05,'right');  %exclude CueOnly trials from stim
% [h_stimlfp,p_stimlfp]=ttest2(stimlfp_zscores(PD_cue_trials(find(cue_val(PD_cue_trials)~=CUEONLY))),...
%     stimlfp_zscores(ND_cue_trials(find(cue_val(ND_cue_trials)~=CUEONLY))),.05,'right'); 
% [h_stimlfp_bp,p_stimlfp_bp]=ttest2(stimlfp_bp_zscores(PD_cue_trials(find(cue_val(PD_cue_trials)~=CUEONLY))),...
%     stimlfp_bp_zscores(ND_cue_trials(find(cue_val(ND_cue_trials)~=CUEONLY))),.05,'right'); 
% 
% %1-way anova to test whether there is a significant difference among PDcue-neutral-NDcue
% p_1way_anova_delaylfp = anovan(delay_lfp,{signed_cue_dirs},'varnames','CueDir','display','off');
% p_1way_anova_delaylfp_bp = anovan(delay_lfp_bp,{signed_cue_dirs},'varnames','CueDir','display','off');
% p_1way_anova_delayspikes = anovan(delay_spikes,{signed_cue_dirs},'varnames','CueDir','display','off');
% p_1way_anova_stimlfp = anovan(stimlfp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
% p_1way_anova_stimlfp_bp = anovan(stimlfp_bp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
% p_1way_anova_stimspikes = anovan(stimspikes_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY))},'varnames','CueDir','display','off');
% 
% %2-way anova with CueDir and Signed Coherence as factors (ignore CueOnly trials)
% %if there's an interaction, that would argue that the cue direction modifies the response to the visual stimulus 
% %in a way not accounted for by the fact that the stimulus itself is changing. 
% %(what about something like a sequential f-test to see whether knowledge of the cue_dir improves fit?)
% signed_coherence = coherence.*(-1+2.*(squeeze_angle(direction)==squeeze_angle(Pref_direction)));
% p_2way_anova_stimlfp = anovan(stimlfp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY)) signed_coherence(find(cue_val~=CUEONLY))},'model',[1 2 3],'varnames',{'CueDir';'SignedCoherence'},'display','off');
% p_2way_anova_stimlfp_bp = anovan(stimlfp_bp_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY)) signed_coherence(find(cue_val~=CUEONLY))},'model',[1 2 3],'varnames',{'CueDir';'SignedCoherence'},'display','off');
% p_2way_anova_stimspikes = anovan(stimspikes_zscores(find(cue_val~=CUEONLY)),{signed_cue_dirs(find(cue_val~=CUEONLY)) signed_coherence(find(cue_val~=CUEONLY))},'model',[1 2 3],'varnames',{'CueDir';'SignedCoherence'},'display','off');
% 
% 
% 
% %% make subplots showing mean values +/- std devs
% hlist(1+length(hlist))=figure;
% set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Cue Direction Effects',FILE));
% subplot(2,6,7);
% errorbar([1:3], mean_delay_lfp, std_delay_lfp./sqrt([length(PD_cue_trials) length(neutral_cue_trials) length(ND_cue_trials)]'));
% xlabel('Pr Neu Nu'); set(gca,'XTickLabel',[]); title('Delay: LFP');
% subplot(2,6,8);
% errorbar([1:3], mean_delay_lfp_bp, std_delay_lfp_bp./sqrt([length(PD_cue_trials) length(neutral_cue_trials) length(ND_cue_trials)]'));
% xlabel('Pr Neu Nu'); set(gca,'XTickLabel',[]); title('Delay: BP');
% subplot(2,6,9);
% errorbar([1:3], mean_delay_spikes, std_delay_spikes./sqrt([length(PD_cue_trials) length(neutral_cue_trials) length(ND_cue_trials)]'));
% xlabel('Pr Neu Nu'); set(gca,'XTickLabel',[]); title('Delay: Spikes');
% subplot(2,6,10);
% errorbar([-2:2], mean_stim_zlfp, std_stim_zlfp./sqrt([sum(cue_val(PD_cue_trials)==VALID) sum(cue_val(PD_cue_trials)==INVALID) ...
%     length(neutral_cue_trials) sum(cue_val(ND_cue_trials)==INVALID) sum(cue_val(ND_cue_trials)==VALID)]'));
% xlabel('PrV PrI 0 NuI NuV'); set(gca,'XTickLabel',[]); title('Stim: LFP'); xlim([-3 3]);
% subplot(2,6,11);
% errorbar([-2:2], mean_stim_zlfp_bp, std_stim_zlfp_bp./sqrt([sum(cue_val(PD_cue_trials)==VALID) sum(cue_val(PD_cue_trials)==INVALID) ...
%     length(neutral_cue_trials) sum(cue_val(ND_cue_trials)==INVALID) sum(cue_val(ND_cue_trials)==VALID)]'));
% xlabel('PrV PrI 0 NuI NuV'); set(gca,'XTickLabel',[]); title('Stim: BP'); xlim([-3 3]);
% subplot(2,6,12);
% errorbar([-2:2], mean_stim_zspikes, std_stim_zspikes./sqrt([sum(cue_val(PD_cue_trials)==VALID) sum(cue_val(PD_cue_trials)==INVALID) ...
%     length(neutral_cue_trials) sum(cue_val(ND_cue_trials)==INVALID) sum(cue_val(ND_cue_trials)==VALID)]'));
% xlabel('PrV PrI 0 NuI NuV'); set(gca,'XTickLabel',[]); title('Stim: Spikes'); xlim([-3 3]);
% 
% %% ********************** PRINT INFO *****************************
% %now, print out some useful information in the upper subplot
% subplot(2, 1, 1);
% PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);
% 
% %now, print out some specific useful info.
% xpos = -10; ypos = 25;
% font_size = 8;
% bump_size = 5;
% line = sprintf('1-tailed T-tests:');
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(delay/lfp)=%5.3f, p(delay/spikes)=%5.3f, p(delay/bp)=%5.3f',p_delaylfp, p_delayspikes, p_delaylfp_bp);
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(stim/lfp)=%5.3f, p(stim/spikes)=%5.3f, p(stim/bp)=%5.3f', p_stimlfp, p_stimspikes, p_stimlfp_bp);
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('Delay period 1-way ANOVAs:');
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(delay/lfp)=%5.3f, p(delay/spikes)=%5.3f, p(delay/bp)=%5.3f', p_1way_anova_delaylfp, p_1way_anova_delayspikes, p_1way_anova_delaylfp_bp);
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('VStim period 2-way ANOVAs:');
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(stim/LFP:me)=%5.3f, p(stim/LFP:intrxn)=%5.3f, p(stim/spike:me)=%5.3f, p(stim/spikes:intrxn)=%5.3f',...
%     p_2way_anova_stimlfp(1), p_2way_anova_stimlfp(3), p_2way_anova_stimspikes(1), p_2way_anova_stimspikes(3));
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(stim/BP:me)=%5.3f, p(stim/BP:intrxn)=%5.3f', p_2way_anova_stimlfp_bp(1), p_2way_anova_stimlfp_bp(3));
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('VStim period Z-scored 1-way ANOVAs:');
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf('  p(stim/lfp)=%5.3f, p(stim/spikes)=%5.3f, p(stim/bp)=%5.3f', p_zscore_anova_stimlfp, p_zscore_anova_stimspikes, p_zscore_anova_stimlfp_bp);
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% 
% 
% % line = sprintf('Directions tested: %6.3f, %6.3f deg', unique_direction(1), unique_direction(2) );
% % text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% 
% 
% % %now try to plot timecourses
% 
% % PD_lfpdata = squeeze(data.lfp_data(:,:,PD_cue_trials));
% % ND_lfpdata = squeeze(data.lfp_data(:,:,ND_cue_trials));
% % neutral_lfpdata = squeeze(data.lfp_data(:,:,neutral_cue_trials));
% % 
% % PD_spikedata = squeeze(data.spike_data(SpikeChan,:,PD_cue_trials));
% % ND_spikedata = squeeze(data.spike_data(SpikeChan,:,ND_cue_trials));
% % neutral_spikedata = squeeze(data.spike_data(SpikeChan,:,neutral_cue_trials));
% % 
% % lfp_delay_t = [-400:2:0]; spike_delay_t = [-400:1:0];
% % figure;
% % subplot(2,2,1); hold on;
% % plot(lfp_delay_t,getval(conv( sqrt(mean(PD_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'b');
% % plot(lfp_delay_t,getval(conv( sqrt(mean(ND_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'r');
% % plot(lfp_delay_t,getval(conv( sqrt(mean(neutral_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'g');
% % %xlabel('Time before stimulus (ms)'); 
% % ylabel('rms LFP'); 
% % %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue');
% % 
% % subplot(2,2,3); hold on;
% % plot(spike_delay_t,getval(conv( sum(PD_spikedata(end_delay-400-2:end_delay+1,:),2), 0.25*ones(1,4)),4:404),'b')
% % plot(spike_delay_t,getval(conv( sum(ND_spikedata(end_delay-400-2:end_delay+1,:),2), 0.25*ones(1,4)),4:404),'r')
% % plot(spike_delay_t,getval(conv( sum(neutral_spikedata(end_delay-400-2:end_delay+1,:),2), 0.25*ones(1,4)),4:404),'g')
% % xlabel('Time before stimulus (ms)'); ylabel('firing rate (imp/s)');
% % %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue');
% % 
% % lfp_stim_t = [0:2:1000]; spike_delay_t = [0:1:1000];
% % subplot(2,2,2); hold on;
% % plot(lfp_stim_t,getval(conv( sqrt(mean(PD_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'b');
% % plot(lfp_stim_t,getval(conv( sqrt(mean(ND_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'r');
% % plot(lfp_stim_t,getval(conv( sqrt(mean(neutral_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'g');
% % %xlabel('Time before stimulus (ms)'); ylabel('rms LFP'); 
% % legend('PrefDirec Cue','NullDirec Cue','Neutral Cue'); legend(gca,'boxoff');
% % 
% % subplot(2,2,4); hold on;
% % plot(spike_delay_t,getval(conv( sum(PD_spikedata(end_delay-6:end_delay+1000+3,:),2), 0.125*ones(1,8)),6:1006),'b')
% % plot(spike_delay_t,getval(conv( sum(ND_spikedata(end_delay-6:end_delay+1000+3,:),2), 0.125*ones(1,8)),6:1006),'r')
% % plot(spike_delay_t,getval(conv( sum(neutral_spikedata(end_delay-6:end_delay+1000+3,:),2), 0.125*ones(1,8)),6:1006),'g')
% % xlabel('Time after stimulus (ms)'); %ylabel('firing rate (imp/s)');
% % %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% lfpdata = squeeze(data.lfp_data(:,:,:));
% PD_lfpdata = squeeze(data.lfp_data(:,:,PD_cue_trials));
% ND_lfpdata = squeeze(data.lfp_data(:,:,ND_cue_trials));
% neutral_lfpdata = squeeze(data.lfp_data(:,:,neutral_cue_trials));
% 
% spikedata = squeeze(data.spike_data(SpikeChan,:,BegTrial:EndTrial));
% PD_spikedata = squeeze(data.spike_data(SpikeChan,:,PD_cue_trials));
% ND_spikedata = squeeze(data.spike_data(SpikeChan,:,ND_cue_trials));
% neutral_spikedata = squeeze(data.spike_data(SpikeChan,:,neutral_cue_trials));
% 
% lfp_delay_t = [-400:2:0]; spike_delay_t = [-400:1:0];
% hlist(1+length(hlist))=figure;
% set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Cue Direction Effects: TimeCourses',FILE));
% subplot(4,1,1); hold on;
% plot(lfp_delay_t,getval(conv( sqrt(mean(PD_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'b');
% plot(lfp_delay_t,getval(conv( sqrt(mean(ND_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'r');
% plot(lfp_delay_t,getval(conv( sqrt(mean(neutral_lfpdata(ceil(end_delay/2)-200-2:floor(end_delay/2)+1,:).^2,2)), 0.25*ones(1,4)),4:204),'g');
% title(FILE);
% %xlabel('Time before stimulus (ms)'); 
% ylabel('rms LFP'); 
% legend('PrefDirec Cue','NullDirec Cue','Neutral Cue','Location','NorthOutside','Orientation','Horizontal');legend(gca,'BoxOff')
% 
% subplot(4,1,2); hold on;
% plot(spike_delay_t,getval(conv( sum(PD_spikedata(end_delay-400-6:end_delay+3,:),2), 0.125*ones(1,8)),6:406),'b')
% plot(spike_delay_t,getval(conv( sum(ND_spikedata(end_delay-400-6:end_delay+3,:),2), 0.125*ones(1,8)),6:406),'r')
% plot(spike_delay_t,getval(conv( sum(neutral_spikedata(end_delay-400-6:end_delay+3,:),2), 0.125*ones(1,8)),6:406),'g')
% xlabel('Time before stimulus (ms)'); ylabel('mean spikes/bin(1ms)');
% %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue');
% 
% lfp_stim_t = [0:2:1000]; spike_stim_t = [0:1:1000];
% subplot(4,1,3); hold on;
% plot(lfp_stim_t,getval(conv( sqrt(mean(PD_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'b');
% plot(lfp_stim_t,getval(conv( sqrt(mean(ND_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'r');
% plot(lfp_stim_t,getval(conv( sqrt(mean(neutral_lfpdata(start_stim-2:start_stim+500+1,:).^2,2)), 0.25*ones(1,4)),4:504),'g');
% %xlabel(FILE);
% %xlabel('Time before stimulus (ms)'); 
% ylabel('rms LFP'); 
% %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue'); legend(gca,'boxoff');
% 
% raw_spikes_tc = spikedata(end_delay-6:end_delay+1000+3,:);
% zsc_spikes_tc = zeros(size(raw_spikes_tc));
% for i = 1:length(unique_direction)
%     for j = 1:length(unique_coherence)
%         ind = find( (direction == unique_direction(i)) & (coherence == unique_coherence(j)) );
%         zsc_spikes_tc(:,ind) = zscore(raw_spikes_tc(:,ind));
%     end
% end
% 
% subplot(4,1,4); hold on;
% plot(spike_stim_t,getval(conv( mean(zsc_spikes_tc(:,find( (signed_cue_dirs == PD_CUEDIR)&(cue_val~=CUEONLY) )),2), 0.125*ones(1,8)),6:1006),'b');
% plot(spike_stim_t,getval(conv( mean(zsc_spikes_tc(:,find( (signed_cue_dirs == NEU_CUEDIR)&(cue_val~=CUEONLY) )),2), 0.125*ones(1,8)),6:1006),'r');
% plot(spike_stim_t,getval(conv( mean(zsc_spikes_tc(:,find( (signed_cue_dirs == ND_CUEDIR)&(cue_val~=CUEONLY) )),2), 0.125*ones(1,8)),6:1006),'g');
% xlabel('Time after stimulus (ms)'); ylabel('mean spikes/bin(1ms)');
% 
% % plot(spike_stim_t,getval(conv( mean(PD_spikedata(end_delay-6:end_delay+1000+3,find(cue_val(PD_cue_trials)~=CUEONLY)),2), 0.125*ones(1,8)),6:1006),'b')
% % plot(spike_stim_t,getval(conv( mean(ND_spikedata(end_delay-6:end_delay+1000+3,find(cue_val(ND_cue_trials)~=CUEONLY)),2), 0.125*ones(1,8)),6:1006),'r')
% % plot(spike_stim_t,getval(conv( mean(neutral_spikedata(end_delay-6:end_delay+1000+3,:),2), 0.125*ones(1,8)),6:1006),'g') %not necessary to exclude CueOnly from Neutral trials
% %legend('PrefDirec Cue','NullDirec Cue','Neutral Cue');
% 
% %Now plot psth sorted by direction and coherence
% figure; set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Cue Direction Effects: Stim: Dir x Coher',FILE));
% for i = 1:length(unique_direction)
%     for j = 1:length(unique_coherence)
%         spike_psth{i,j,1} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==PD_CUEDIR) )),2),0.125*ones(1,8));
%         spike_psth{i,j,2} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==NEU_CUEDIR) )),2),0.125*ones(1,8));
%         spike_psth{i,j,3} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==ND_CUEDIR) )),2),0.125*ones(1,8));
%         subplot(length(unique_coherence),length(unique_direction)+1,(length(unique_direction)+1)*(j-1)+i);  hold on;
%         plot(spike_stim_t,getval(spike_psth{i,j,1},6:1006),'b');
%         plot(spike_stim_t,getval(spike_psth{i,j,2},6:1006),'r');
%         plot(spike_stim_t,getval(spike_psth{i,j,3},6:1006),'g');
%         if (j==length(unique_coherence))
%             xlabel('Time after stimulus (ms)');
%         end
%         if i==1
%             ylabel(sprintf('%3.1f%%coher',unique_coherence(j)));
%         end
%         if j==1
%             if i==1
%                 title(sprintf('%s\n%ddeg(%sD)',FILE,unique_direction(i),getval('NP',1+(Pref_direction==unique_direction(i)))));
%             else
%                 title(sprintf('%ddeg(%sD)',unique_direction(i),getval('NP',1+(Pref_direction==unique_direction(i)))));
%                 legend('PD','Neu','ND','Location','NorthOutside','Orientation','horizontal'); legend(gca,'boxoff');
%             end
%         end
%     end
% end
% %now plot average spike rates separated into direction and coherence for stimulus
% PrefNull = {'PrefStm','NullStm'};
for j = 1:length(unique_coherence)
    for i = 1:length(unique_direction)
%         %subplot(length(unique_coherence),length(unique_direction),length(unique_direction)*(j-1)+i); 
%         subplot(length(unique_coherence),length(unique_direction)+1,(length(unique_direction)+1)*(j-1)+3);  hold on;
        mean_stim_spikes{i,j} = [mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (cue_val~=2) & (signed_cue_dirs==PD_CUEDIR) )))...
            mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (cue_val~=2) & (signed_cue_dirs==NEU_CUEDIR) )))...
            mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (cue_val~=2) & (signed_cue_dirs==ND_CUEDIR) )))];
%         std_stim_spikes{i,j} =  [std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )))...
%             std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )))...
%             std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )))];
%         count_stim_cond{i,j} =  [sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )...
%             sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )...
%             sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )];
%         errorbar([-1:1],mean_stim_spikes{i,j},std_stim_spikes{i,j}./sqrt(count_stim_cond{i,j}),'Color',[i-1 2-i 1]);
%         set(gca,'XTick',[-1:1],'XTickLabel',{'PD','Neu','ND'}); xlim([-1.1 1.1]);
        mean_stim_spikes_full{i,j} = [mean(stim_spikes_full(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )))...
            mean(stim_spikes_full(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )))...
            mean(stim_spikes_full(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )))];
        mean_stim_spikes_old{i,j} = [mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )))...
            mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )))...
            mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )))];
    end
%     if j==1
%         legend(PrefNull, 'Location','NorthOutside','Orientation','horizontal');
%         legend(gca,'boxoff');
%         text(0,max(ylim),'Mean FR','HorizontalAlignment','center');
%     end
%     if j==length(unique_coherence)
%         xlabel('Cue Direction');
%     end
end
% 
% % %Now plot psth sorted by direction and coherence
% % figure; set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', 'Cue Direction Effects: Stim PSTH: Dir x Coher');
% % for i = 1:length(unique_direction)
% %     for j = 1:length(unique_coherence)
% %         spike_psth{i,j,1} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==PD_CUEDIR) )),2),0.125*ones(1,8));
% %         spike_psth{i,j,2} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==NEU_CUEDIR) )),2),0.125*ones(1,8));
% %         spike_psth{i,j,3} = conv(mean(spikedata(:,find( (coherence==unique_coherence(j)) & (direction==unique_direction(i)) & (signed_cue_dirs==ND_CUEDIR) )),2),0.125*ones(1,8));
% %         subplot(length(unique_coherence),length(unique_direction),length(unique_direction)*(j-1)+i);  hold on;
% %         plot(spike_stim_t,getval(spike_psth{i,j,1},6:1006),'b');
% %         plot(spike_stim_t,getval(spike_psth{i,j,2},6:1006),'r');
% %         plot(spike_stim_t,getval(spike_psth{i,j,3},6:1006),'g');
% %         if (j==length(unique_coherence))
% %             xlabel('Time after stimulus (ms)');
% %         end
% %         if i==1
% %             ylabel(sprintf('%3.1f%%coher',unique_coherence(j)));
% %         end
% %         if j==1
% %             if i==1
% %                 title(sprintf('%s\n%ddeg(%sD)',FILE,unique_direction(i),getval('NP',1+(Pref_direction==unique_direction(i)))));
% %             else
% %                 title(sprintf('%ddeg(%sD)',unique_direction(i),getval('NP',1+(Pref_direction==unique_direction(i)))));
% %                 legend('PD','Neu','ND','Location','NorthOutside','Orientation','horizontal'); legend(gca,'boxoff');
% %             end
% %         end
% %     end
% % end
% % 
% % %now plot average spike rates separated into direction and coherence for stimulus
% % PrefNull = {'PrefDir','NullDir'};
% % figure; set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', 'Cue Dir Effects - Stim: Dir x Coher');
% % for j = 1:length(unique_coherence)
% %     for i = 1:length(unique_direction)
% %         %subplot(length(unique_coherence),length(unique_direction),length(unique_direction)*(j-1)+i); 
% %         subplot(length(unique_coherence),1,j); hold on;
% %         mean_stim_spikes{i,j} = [mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )))...
% %             mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )))...
% %             mean(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )))];
% %         std_stim_spikes{i,j} =  [std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )))...
% %             std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )))...
% %             std(stim_spikes(find( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )))];
% %         count_stim_cond{i,j} =  [sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==PD_CUEDIR) )...
% %             sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==NEU_CUEDIR) )...
% %             sum( (direction==unique_direction(i)) & (coherence==unique_coherence(j)) & (signed_cue_dirs==ND_CUEDIR) )];
% %         errorbar([-1:1],mean_stim_spikes{i,j},std_stim_spikes{i,j}./sqrt(count_stim_cond{i,j}),'Color',[i-1 2-i 1]);
% % %         if i==1,  set(gco,'Color',[0 1 1]);
% % %         else,     set(gco,'Color',[1 0 1]);
% % %         end
% %         set(gca,'XTick',[-1:1],'XTickLabel',{'PD','Neu','ND'}); xlim([-1.1 1.1]);
% %         ylabel(sprintf('%3.1f%%coher\n(spikes/s)',unique_coherence(j)));
% %     end
% %     if j==1
% %         legend(PrefNull, 'Location','NorthOutside','Orientation','horizontal');
% %         legend(gca,'boxoff');
% %     end
% % end

%Compute Ratios and Indices for Delay and Stimulus spikes.  The ratio or
%index are two different ways of asking how much does that particular
%directional cue modify the activity wrt neutral cue
% spk_dl_ratio = [mean_delay_spikes(1)/mean_delay_spikes(2) mean_delay_spikes(3)/mean_delay_spikes(2)];
% spk_dl_index = [( mean_delay_spikes(1)-mean_delay_spikes(2) )/( mean_delay_spikes(1)+mean_delay_spikes(2) ) ...
%                 ( mean_delay_spikes(3)-mean_delay_spikes(2) )/( mean_delay_spikes(3)+mean_delay_spikes(2) )];
% spk_dl_diff = [mean_delay_spikes(1)-mean_delay_spikes(2) mean_delay_spikes(3)-mean_delay_spikes(2)];
% spk_dl_end_ratio = [mean_delay_spikes_end(1)/mean_delay_spikes_end(2) mean_delay_spikes_end(3)/mean_delay_spikes_end(2)];
% spk_dl_nostart_ratio = [mean_delay_spikes_nostart(1)/mean_delay_spikes_nostart(2) mean_delay_spikes_nostart(3)/mean_delay_spikes_nostart(2)];
% spk_dl_end_index = [( mean_delay_spikes_end(1)-mean_delay_spikes_end(2) )/( mean_delay_spikes_end(1)+mean_delay_spikes_end(2) ) ...
%                     ( mean_delay_spikes_end(3)-mean_delay_spikes_end(2) )/( mean_delay_spikes_end(3)+mean_delay_spikes_end(2) )];
% spk_dl_nostart_index = [( mean_delay_spikes_nostart(1)-mean_delay_spikes_nostart(2) )/( mean_delay_spikes_nostart(1)+mean_delay_spikes_nostart(2) ) ...
%                     ( mean_delay_spikes_nostart(3)-mean_delay_spikes_nostart(2) )/( mean_delay_spikes_nostart(3)+mean_delay_spikes_nostart(2) )];
% spk_dl_end_diff = [mean_delay_spikes_end(1)-mean_delay_spikes_end(2) mean_delay_spikes_end(3)-mean_delay_spikes_end(2)];
% spk_dl_nostart_diff = [mean_delay_spikes_nostart(1)-mean_delay_spikes_nostart(2) mean_delay_spikes_nostart(3)-mean_delay_spikes_nostart(2)];
% 
% for i=1:length(unique_coherence)
%     spk_st_ratio(i,:) = [mean_stim_spikes{1,i}(1)/mean_stim_spikes{1,i}(2) mean_stim_spikes{2,i}(1)/mean_stim_spikes{2,i}(2)...
%                          mean_stim_spikes{1,i}(3)/mean_stim_spikes{1,i}(2) mean_stim_spikes{2,i}(3)/mean_stim_spikes{2,i}(2)];
%     spk_st_index(i,:) = [(mean_stim_spikes{1,i}(1)-mean_stim_spikes{1,i}(2))/(mean_stim_spikes{1,i}(1)+mean_stim_spikes{1,i}(2)) ...
%                          (mean_stim_spikes{2,i}(1)-mean_stim_spikes{2,i}(2))/(mean_stim_spikes{2,i}(1)+mean_stim_spikes{2,i}(2)) ...
%                          (mean_stim_spikes{1,i}(3)-mean_stim_spikes{1,i}(2))/(mean_stim_spikes{1,i}(3)+mean_stim_spikes{1,i}(2)) ...
%                          (mean_stim_spikes{2,i}(3)-mean_stim_spikes{2,i}(2))/(mean_stim_spikes{2,i}(3)+mean_stim_spikes{2,i}(2))];
% 
%     spk_st_full_ratio(i,:) = [mean_stim_spikes_full{1,i}(1)/mean_stim_spikes_full{1,i}(2)...
%                               mean_stim_spikes_full{2,i}(1)/mean_stim_spikes_full{2,i}(2)...
%                               mean_stim_spikes_full{1,i}(3)/mean_stim_spikes_full{1,i}(2)...
%                               mean_stim_spikes_full{2,i}(3)/mean_stim_spikes_full{2,i}(2)];
%     spk_st_full_index(i,:) = [(mean_stim_spikes_full{1,i}(1)-mean_stim_spikes_full{1,i}(2))/(mean_stim_spikes_full{1,i}(1)+mean_stim_spikes_full{1,i}(2))...
%                               (mean_stim_spikes_full{2,i}(1)-mean_stim_spikes_full{2,i}(2))/(mean_stim_spikes_full{2,i}(1)+mean_stim_spikes_full{2,i}(2))...
%                               (mean_stim_spikes_full{1,i}(3)-mean_stim_spikes_full{1,i}(2))/(mean_stim_spikes_full{1,i}(3)+mean_stim_spikes_full{1,i}(2))...
%                               (mean_stim_spikes_full{2,i}(3)-mean_stim_spikes_full{2,i}(2))/(mean_stim_spikes_full{2,i}(3)+mean_stim_spikes_full{2,i}(2))];
% 
%     spk_st_diff(i,:) = [(mean_stim_spikes{1,i}(1)-mean_stim_spikes{1,i}(2)) ... 
%                         (mean_stim_spikes{2,i}(1)-mean_stim_spikes{2,i}(2)) ...
%                         (mean_stim_spikes{1,i}(3)-mean_stim_spikes{1,i}(2)) ...
%                         (mean_stim_spikes{2,i}(3)-mean_stim_spikes{2,i}(2))];
%     spk_st_old_ratio(i,:) = [mean_stim_spikes_old{1,i}(1)/mean_stim_spikes_old{1,i}(2)...
%                              mean_stim_spikes_old{2,i}(1)/mean_stim_spikes_old{2,i}(2)...
%                              mean_stim_spikes_old{1,i}(3)/mean_stim_spikes_old{1,i}(2)...
%                              mean_stim_spikes_old{2,i}(3)/mean_stim_spikes_old{2,i}(2)];
%     spk_st_old_index(i,:) = [(mean_stim_spikes_old{1,i}(1)-mean_stim_spikes_old{1,i}(2))/(mean_stim_spikes_old{1,i}(1)+mean_stim_spikes_old{1,i}(2))...
%                              (mean_stim_spikes_old{2,i}(1)-mean_stim_spikes_old{2,i}(2))/(mean_stim_spikes_old{2,i}(1)+mean_stim_spikes_old{2,i}(2))...
%                              (mean_stim_spikes_old{1,i}(3)-mean_stim_spikes_old{1,i}(2))/(mean_stim_spikes_old{1,i}(3)+mean_stim_spikes_old{1,i}(2))...
%                              (mean_stim_spikes_old{2,i}(3)-mean_stim_spikes_old{2,i}(2))/(mean_stim_spikes_old{2,i}(3)+mean_stim_spikes_old{2,i}(2))];
% end
% 
% for m = 1:2 %two halves of the stimulus period
%     for j = 1:length(unique_direction)
%         for k = 1:length(unique_coherence)
%             mean_stim_fr_halves{m}(:,j,k) = [mean(stim_spikes_halves(m,find( (direction==unique_direction(j)) & (coherence==unique_coherence(k)) & (signed_cue_dirs==PD_CUEDIR) & (cue_val~=2) ))); ...
%                                              mean(stim_spikes_halves(m,find( (direction==unique_direction(j)) & (coherence==unique_coherence(k)) & (signed_cue_dirs==NEU_CUEDIR) & (cue_val~=2) ))); ...
%                                              mean(stim_spikes_halves(m,find( (direction==unique_direction(j)) & (coherence==unique_coherence(k)) & (signed_cue_dirs==ND_CUEDIR) & (cue_val~=2) )))]';
%         end
%     end
% end
% for m = 1:2
% for j=1:length(unique_direction)
%     for k=1:length(unique_coherence)
%         spk_st_ratio_halves{m}(:,j,k) = [mean_stim_fr_halves{m}(1,j,k)/mean_stim_fr_halves{m}(2,j,k)...
%                                          mean_stim_fr_halves{m}(3,j,k)/mean_stim_fr_halves{m}(2,j,k)];
%         spk_st_index_halves{m}(:,j,k) = [(mean_stim_fr_halves{m}(1,j,k)-mean_stim_fr_halves{m}(2,j,k)) / (mean_stim_fr_halves{m}(1,j,k)+mean_stim_fr_halves{m}(2,j,k)) ...
%                                          (mean_stim_fr_halves{m}(3,j,k)-mean_stim_fr_halves{m}(2,j,k)) / (mean_stim_fr_halves{m}(3,j,k)+mean_stim_fr_halves{m}(2,j,k)) ];
% %         spk_st_ratio(i,:) = [mean_stim_spikes{1,i}(1)/mean_stim_spikes{1,i}(2) mean_stim_spikes{2,i}(1)/mean_stim_spikes{2,i}(2)...
% %                              mean_stim_spikes{1,i}(3)/mean_stim_spikes{1,i}(2) mean_stim_spikes{2,i}(3)/mean_stim_spikes{2,i}(2)];
% %         spk_st_index(i,:) = [(mean_stim_spikes{1,i}(1)-mean_stim_spikes{1,i}(2))/(mean_stim_spikes{1,i}(1)+mean_stim_spikes{1,i}(2)) ...
% %                              (mean_stim_spikes{2,i}(1)-mean_stim_spikes{2,i}(2))/(mean_stim_spikes{2,i}(1)+mean_stim_spikes{2,i}(2)) ...
% %                              (mean_stim_spikes{1,i}(3)-mean_stim_spikes{1,i}(2))/(mean_stim_spikes{1,i}(3)+mean_stim_spikes{1,i}(2)) ...
% %                              (mean_stim_spikes{2,i}(3)-mean_stim_spikes{2,i}(2))/(mean_stim_spikes{2,i}(3)+mean_stim_spikes{2,i}(2))];
%     end
% end
% end

%compute mean activity for 0% coherence trials combining across both
%directions and compute ratios
for i = 1:sum(unique_cue_dir_type~=2)
    seltrials = logical( (cue_dir_type == unique_cue_dir_type(i)) & (coherence == 0) );
    mean_zero_coh_spikes(i) = mean(stim_spikes(seltrials));
end
zero_coh_PD_ratio = mean_zero_coh_spikes(3)/mean_zero_coh_spikes(2);
zero_coh_ND_ratio = mean_zero_coh_spikes(1)/mean_zero_coh_spikes(2);
zero_coh_PD_index = (mean_zero_coh_spikes(3)-mean_zero_coh_spikes(2))/(mean_zero_coh_spikes(3)+mean_zero_coh_spikes(2));
zero_coh_ND_index = (mean_zero_coh_spikes(1)-mean_zero_coh_spikes(2))/(mean_zero_coh_spikes(1)+mean_zero_coh_spikes(2));

% %Compute Means and Variances of spikes across each condition (delay/stim, coherence, cuedir, stimdir) for output
% meanvar_dl = []; meanvar_st =[];
% meanvar_dl = [mean(delay_spikes(PD_cue_trials)) mean(delay_spikes(neutral_cue_trials)) mean(delay_spikes(ND_cue_trials));
%               var(delay_spikes(PD_cue_trials)) var(delay_spikes(neutral_cue_trials)) var(delay_spikes(ND_cue_trials))];
% for i = 1:length(unique_coherence)
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == PDCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == PDCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == PDCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == PDCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == NEUCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == NEUCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == NEUCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == NEUCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == NDCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == NDCUE)&(squeeze(direction)==squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
%     meanvar_st = [meanvar_st [mean(stim_spikes(find( (cue_dir_type == NDCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) ))) var(stim_spikes(find( (cue_dir_type == NDCUE)&(squeeze(direction)~=squeeze(Pref_direction))&(coherence==unique_coherence(i)) )))]'];
% end                    
%                               
% %Compute means and variance of spikes during CueOnly trials based on accuracy and cue direction
% PD_cue_logical = (squeeze_angle(cue_direc) == squeeze_angle(Pref_direction)) & (cue_val ~= 0);
% ND_cue_logical = (squeeze_angle(cue_direc) ~= squeeze_angle(Pref_direction)) & (cue_val ~= 0);
% neutral_cue_logical = (cue_val == 0);
% 
% meanCOAllDl = [mean(delay_spikes(find( PD_cue_logical & (cue_val==2) ))) mean(delay_spikes(find( ND_cue_logical & (cue_val==2) )))];
% varCOAllDl = [var(delay_spikes(find( PD_cue_logical & (cue_val==2) ))) var(delay_spikes(find( ND_cue_logical & (cue_val==2) )))];
% v2mCOAllDl = varCOAllDl ./ meanCOAllDl;
% meanCOCorDl = [mean(delay_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 1) ))) mean(delay_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 1) )))];
% varCOCorDl = [var(delay_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 1) ))) var(delay_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 1) )))];
% v2mCOCorDl = varCOCorDl ./ meanCOCorDl;
% meanCOIncDl = [mean(delay_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 0) ))) mean(delay_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 0) )))];
% varCOIncDl = [var(delay_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 0) ))) var(delay_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 0) )))];
% v2mCOIncDl = varCOIncDl ./ meanCOIncDl;
% meanCOAllSt = [mean(stim_spikes(find( PD_cue_logical & (cue_val==2) ))) mean(stim_spikes(find( ND_cue_logical & (cue_val==2) )))];
% varCOAllSt = [var(stim_spikes(find( PD_cue_logical & (cue_val==2) ))) var(stim_spikes(find( ND_cue_logical & (cue_val==2) )))];
% v2mCOAllSt = varCOAllSt ./ meanCOAllSt;
% meanCOCorSt = [mean(stim_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 1) ))) mean(stim_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 1) )))];
% varCOCorSt = [var(stim_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 1) ))) var(stim_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 1) )))];
% v2mCOCorSt = varCOCorSt ./ meanCOCorSt;
% meanCOIncSt = [mean(stim_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 0) ))) mean(stim_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 0) )))];
% varCOIncSt = [var(stim_spikes(find( PD_cue_logical & (cue_val==2) & (trials_outcomes == 0) ))) var(stim_spikes(find( ND_cue_logical & (cue_val==2) & (trials_outcomes == 0) )))];
% v2mCOIncSt = varCOIncSt ./ meanCOIncSt;
% nCOAll = [sum( PD_cue_logical & (cue_val==2) ) sum( ND_cue_logical & (cue_val==2) )];
% nCOCor = [sum( PD_cue_logical & (cue_val==2) & (trials_outcomes == 1) ) sum( ND_cue_logical & (cue_val==2) & (trials_outcomes == 1) )];
% nCOInc = [sum( PD_cue_logical & (cue_val==2) & (trials_outcomes == 0) ) sum( ND_cue_logical & (cue_val==2) & (trials_outcomes == 0) )];
% 
% %compute delay period means and variances based on length of delay period... 
% %i'm taking the MEDIAN period for the exponential distribution (291ms) to be the cutoff between long and short delays
% mean_delay = 2*215; %delays range exponentially from 150-800ms
% short_delays = find(end_delay-start_delay+1 < mean_delay);
% long_delays  = find(end_delay-start_delay+1 > mean_delay);
% n_short_trials = length(short_delays);
% n_long_trials = length(long_delays);
% short_mean = [mean(delay_spikes(short_delays)) mean(delay_spikes(intersect(short_delays, PD_cue_trials))) ...
%               mean(delay_spikes(intersect(short_delays, neutral_cue_trials))) mean(delay_spikes(intersect(short_delays, ND_cue_trials)))];
% short_var  = [var(delay_spikes(short_delays)) var(delay_spikes(intersect(short_delays, PD_cue_trials))) ...
%               var(delay_spikes(intersect(short_delays, neutral_cue_trials))) var(delay_spikes(intersect(short_delays, ND_cue_trials)))];
% short_v2m = short_var./short_mean;
% long_mean = [mean(delay_spikes(long_delays)) mean(delay_spikes(intersect(long_delays, PD_cue_trials))) ...
%               mean(delay_spikes(intersect(long_delays, neutral_cue_trials))) mean(delay_spikes(intersect(long_delays, ND_cue_trials)))];
% long_var  = [var(delay_spikes(long_delays)) var(delay_spikes(intersect(long_delays, PD_cue_trials))) ...
%               var(delay_spikes(intersect(long_delays, neutral_cue_trials))) var(delay_spikes(intersect(long_delays, ND_cue_trials)))];          
% long_v2m = long_var./long_mean;

% keyboard

output = 0;
output2 = 0; %ratio/index values
output3 = 0; %ratio/index values NOT combined across stimulus directions
output4 = 0; %mean and variance during delay and stimulus period for each condition separately
output5 = 0; %mean and variance during delay period cue only trials sorted by accuracy
output6 = 0; %mean and variance in delay periods sorted by long and short delays
output7 = 0; %ratio/index values like output3, but also computed separately for each half of visual stimulus period
output8 = 0; %raw difference in spike counts, like output3
output9 = 0; %delay period activity and ratios/indices - computed using entire delay, last 200ms, or all but first 200ms
output10 = 1; %ratios for zero coherence trials combining across both directions of motion

if (output)
    %------------------------------------------------------------------------
    %write out LFP parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_LFP_Effects_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t PrDir\t PrSpd\t PrHDsp\t RFX\t RFY\t RFDiam\t Tt:dl_lfp\t Tt:st_lfp\t 1A:dl_lfp\t 1A:st_lfp\t 2A-ME:st_lfp\t 2A-In:st_lfp\t 1A-Zs:st_lfp\t Mean_Dl_Lfp_Pd\t Std_Dl_Lfp_Pd\t Mean_Dl_Lfp_Neu\t Std_Dl_Lfp_Neu\t Mean_Dl_Lfp_Nd\t Std_Dl_Lfp_Nd\t Mean_St_Lfp_Pd\t Std_St_Lfp_Pd\t Mean_St_Lfp_Neu\t Std_St_Lfp_Neu\t Mean_St_Lfp_Nd\t Std_St_Lfp_Nd\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t',...
        FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
        p_delaylfp, p_stimlfp, p_1way_anova_delaylfp, p_1way_anova_stimlfp, ...
        p_2way_anova_stimlfp(1), p_2way_anova_stimlfp(3), p_zscore_anova_stimlfp, ...
        mean_delay_lfp(1), std_delay_lfp(1), mean_delay_lfp(2), std_delay_lfp(2), mean_delay_lfp(3), std_delay_lfp(3), ...
        mean_stim_zlfp(1), std_stim_zlfp(1), mean_stim_zlfp(2), std_stim_zlfp(2), mean_stim_zlfp(3), std_stim_zlfp(3));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %----------------------------------------------------------------------
    %write out LFP Power parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_LFP-BP_Effects_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t PrDir\t PrSpd\t PrHDsp\t RFX\t RFY\t RFDiam\t Tt:dl_bp\t Tt:st_bp\t 1A:dl_bp\t 1A:st_bp\t 2A-ME:st_bp\t 2A-In:st_bp\t 1A-Zs:st_bp\t Mean_Dl_Bp_Pd\t Std_Dl_Bp_Pd\t Mean_Dl_Bp_Neu\t Std_Dl_Bp_Neu\t Mean_Dl_Bp_Nd\t Std_Dl_Bp_Nd\t Mean_St_Bp_Pd\t Std_St_Bp_Pd\t Mean_St_Bp_Neu\t Std_St_Bp_Neu\t Mean_St_Bp_Nd\t Std_St_Bp_Nd\t');
        
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t',...
        FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
        p_delaylfp_bp, p_stimlfp_bp, p_1way_anova_delaylfp_bp, p_1way_anova_stimlfp_bp, ...
        p_2way_anova_stimlfp_bp(1), p_2way_anova_stimlfp_bp(3), p_zscore_anova_stimlfp_bp, ...
        mean_delay_lfp_bp(1), std_delay_lfp_bp(1), mean_delay_lfp_bp(2), std_delay_lfp_bp(2), mean_delay_lfp_bp(3), std_delay_lfp_bp(3), ...
        mean_stim_zlfp_bp(1), std_stim_zlfp_bp(1), mean_stim_zlfp_bp(2), std_stim_zlfp_bp(2), mean_stim_zlfp_bp(3), std_stim_zlfp_bp(3));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %------------------------------------------------------------------------
    %write out spike-count parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spikes_Effects_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t PrDir\t PrSpd\t PrHDsp\t RFX\t RFY\t RFDiam\t Tt:dl_spk\t Tt:st_spk\t 1A:dl_spk\t 1A:st_spk\t 2A-ME:st_spk\t 2A-In:st_spk\t 1A-Zs:st_spk\t Mean_Dl_Spk_Pd\t Std_Dl_Spk_Pd\t Mean_Dl_Spk_Neu\t Std_Dl_Spk_Neu\t Mean_Dl_Spk_Nd\t Std_Dl_Spk_Nd\t Mean_St_Spk_Pd\t Std_St_Spk_Pd\t Mean_St_Spk_Neu\t Std_St_Spk_Neu\t Mean_St_Spk_Nd\t Std_St_Spk_Nd\t');
        
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t %10.8f\t',...
        FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
        p_delayspikes, p_stimspikes, p_1way_anova_delayspikes, p_1way_anova_stimspikes, ...
        p_2way_anova_stimspikes(1), p_2way_anova_stimspikes(3), p_zscore_anova_stimspikes, ...
        mean_delay_spikes(1), std_delay_spikes(1), mean_delay_spikes(2), std_delay_spikes(2), mean_delay_spikes(3), std_delay_spikes(3), ...
        mean_stim_zspikes(1), std_stim_zspikes(1), mean_stim_zspikes(2), std_stim_zspikes(2), mean_stim_zspikes(3), std_stim_zspikes(3) );
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output2)
    %----------------------------------------------------------------------
    %write out ratio/index metrics to a cumulative text file, VR 11/21/05
    %note that these metrics average the values computed for each stim direction... i can get each 
    %individual one by not averaging within the buffer.
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_RatioIndex_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t SpkDlPDRat\t SpkDlNDRat\t SpkDlPDInd\t SpkDlNDInd\t SpkC1PDRat\t SpkC1NDRat\t SpkC1PDInd\t SpkC1NDInd\t SpkC2PDRat\t SpkC2NDRat\t SpkC2PDInd\t SpkC2NDInd\t SpkC3PDRat\t SpkC3NDRat\t SpkC3PDInd\t SpkC3NDInd\t SpkC4PDRat\t SpkC4NDRat\t SpkC4PDInd\t SpkC4NDInd\t SpkC5PDRat\t SpkC5NDRat\t SpkC5PDInd\t SpkC5NDInd\t SpkStPDRat\t SpkStNDRat\t SpkStPDInd\t SpkStNDInd\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',...
        FILE, unique_coherence(1), unique_coherence(2), unique_coherence(3), unique_coherence(4), unique_coherence(5), ...
        spk_dl_ratio(1), spk_dl_ratio(2), spk_dl_index(1), spk_dl_index(2), ...
        mean(spk_st_ratio(1,1:2)), mean(spk_st_ratio(1,3:4)), mean(spk_st_index(1,1:2)), mean(spk_st_index(1,3:4)), ...
        mean(spk_st_ratio(2,1:2)), mean(spk_st_ratio(2,3:4)), mean(spk_st_index(2,1:2)), mean(spk_st_index(2,3:4)), ...
        mean(spk_st_ratio(3,1:2)), mean(spk_st_ratio(3,3:4)), mean(spk_st_index(3,1:2)), mean(spk_st_index(3,3:4)), ...
        mean(spk_st_ratio(4,1:2)), mean(spk_st_ratio(4,3:4)), mean(spk_st_index(4,1:2)), mean(spk_st_index(4,3:4)), ...
        mean(spk_st_ratio(5,1:2)), mean(spk_st_ratio(5,3:4)), mean(spk_st_index(5,1:2)), mean(spk_st_index(5,3:4)), ...        
        mean(mean(spk_st_ratio(:,1:2))), mean(mean(spk_st_ratio(:,3:4))), mean(mean(spk_st_index(:,1:2))), mean(mean(spk_st_index(:,3:4))));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output3)
    %----------------------------------------------------------------------
    %write out ratio/index metrics to a cumulative text file, VR 11/21/05
    %note that these metrics average the values computed for each stim direction... i can get each 
    %individual one by not averaging within the buffer.
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_RatioIndex_stimdir_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t SpkDlPDRat\t SpkDlNDRat\t SpkDlPDInd\t SpkDlNDInd\t SpkC1PcPsRat\t SpkC1PcNsRat\t SpkC1NcPsRat\t SpkC1NcNsRat\t SpkC1PcPsInd\t SpkC1PcNsInd\t SpkC1NcPsInd\t SpkC1NcNsInd\t SpkC2PcPsRat\t SpkC2PcNsRat\t SpkC2NcPsRat\t SpkC2NcNsRat\t SpkC2PcPsInd\t SpkC2PcNsInd\t SpkC2NcPsInd\t SpkC2NcNsInd\t SpkC3PcPsRat\t SpkC3PcNsRat\t SpkC3NcPsRat\t SpkC3NcNsRat\t SpkC3PcPsInd\t SpkC3PcNsInd\t SpkC3NcPsInd\t SpkC3NcNsInd\t SpkC4PcPsRat\t SpkC4PcNsRat\t SpkC4NcPsRat\t SpkC4NcNsRat\t SpkC4PcPsInd\t SpkC4PcNsInd\t SpkC4NcPsInd\t SpkC4NcNsInd\t SpkC5PcPsRat\t SpkC5PcNsRat\t SpkC5NcPsRat\t SpkC5NcNsRat\t SpkC5PcPsInd\t SpkC5PcNsInd\t SpkC5NcPsInd\t SpkC5NcNsInd\t SpkStPcPsRat\t SpkStPcNsRat\t SpkStNcPsRat\t SpkStNcNsRat\t SpkStPcPsInd\t SpkStPcNsInd\t SpkStNcPsInd\t SpkStNcNsInd\t ');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',...
        FILE, unique_coherence, spk_dl_ratio, spk_dl_index, spk_st_ratio(1,:), spk_st_index(1,:), spk_st_ratio(2,:), spk_st_index(2,:),...
        spk_st_ratio(3,:), spk_st_index(3,:),spk_st_ratio(4,:), spk_st_index(4,:),spk_st_ratio(5,:), spk_st_index(5,:),...
        mean(spk_st_ratio,1), mean(spk_st_index,1));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output4)
    %----------------------------------------------------------------------
    %write out mean, and variance for each coherence and each cue direction to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_MeanVar_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t  MnDlPc\t VrDlPc\t MnDl0c\t VrDl0c\t MnDlNc\t VrDlNc\t MnC1PcPs\t VrC1PcPs\t MnC1PcNs\t VrC1PcNs\t MnC10cPs\t VrC10cPs\t MnC10cNs\t VrC10cNs\t MnC1NcPs\t VrC1NcPs\t MnC1NcNs\t VrC1NcNs\t MnC2PcPs\t VrC2PcPs\t MnC2PcNs\t VrC2PcNs\t MnC20cPs\t VrC20cPs\t MnC20cNs\t VrC20cNs\t MnC2NcPs\t VrC2NcPs\t MnC2NcNs\t VrC2NcNs\t MnC3PcPs\t VrC3PcPs\t MnC3PcNs\t VrC3PcNs\t MnC30cPs\t VrC30cPs\t MnC30cNs\t VrC30cNs\t MnC3NcPs\t VrC3NcPs\t MnC3NcNs\t VrC3NcNs\t MnC4PcPs\t VrC4PcPs\t MnC4PcNs\t VrC4PcNs\t MnC40cPs\t VrC40cPs\t MnC40cNs\t VrC40cNs\t MnC4NcPs\t VrC4NcPs\t MnC4NcNs\t VrC4NcNs\t MnC5PcPs\t VrC5PcPs\t MnC5PcNs\t VrC5PcNs\t MnC50cPs\t VrC50cPs\t MnC50cNs\t VrC50cNs\t MnC5NcPs\t VrC5NcPs\t MnC5NcNs\t VrC5NcNs\t ');  
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t ',...
        FILE, unique_coherence, meanvar_dl, meanvar_st); %note that matrices are read down columns.
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output5)
    %----------------------------------------------------------------------
    %write out mean, and variance for CueOnly trials sorted by cue direction and accuracy to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_CueOnly_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t nAPc\t nANc\t nCPc\t nCNc\t nIPc\t nINc\t MADlPc\t VADlPc\t MADlNc\t VADlNc\t v2mADlPc\t v2mADlNc\t MCDlPc\t VCDlPc\t MCDlNc\t VCDlNc\t v2mCDlPc\t v2mCDlNc\t MIDlPc\t VIDlPc\t MIDlNc\t VIDlNc\t v2mIDlPc\t v2mIDlNc\t MAStPc\t VAStPc\t MAStNc\t VAStNc\t v2mAStPc\t v2mAStNc\t MCStPc\t VCStPc\t MCStNc\t VCStNc\t v2mCStPc\t v2mCStNc\t MIStPc\t VIStPc\t MIStNc\t VIStNc\t v2mIStPc\t v2mIStNc\t ');  
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %d\t %d\t %d\t %d\t %d\t %d\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t %3.2f\t ',...
        FILE, nCOAll, nCOCor, nCOInc, ...
        [meanCOAllDl; varCOAllDl; v2mCOAllDl], [meanCOCorDl; varCOCorDl; v2mCOCorDl], [meanCOIncDl; varCOIncDl; v2mCOIncDl], ...
        [meanCOAllSt; varCOAllSt; v2mCOAllSt], [meanCOCorSt; varCOCorSt; v2mCOCorSt], [meanCOIncSt; varCOIncSt; v2mCOIncSt]); 
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output6)
    %----------------------------------------------------------------------
    %write out mean, and variance for delay period with trials sorted by delay period length, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_DelayLength_V2M_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t NShTrials\t NLoTrials\t ShAllV2M\t ShAllMean\t ShAllVar\t ShPcV2M\t ShPcMean\t ShPcVar\t ShNeuV2M\t ShNeuMean\t ShNeuVar\t ShNcV2M\t ShNcMean\t ShNcVar\t LoAllV2M\t LoAllMean\t LoAllVar\t LoPcV2M\t LoPcMean\t LoPcVar\t LoNeuV2M\t LoNeuMean\t LoNeuVar\t LoNcV2M\t LoNcMean\t LoNcVar\t ');  
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %d\t %d\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t %6.3f\t ',...
        FILE, n_short_trials, n_long_trials, [short_v2m; short_mean; short_var], [long_v2m; long_mean; long_var]);
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output7)
    %----------------------------------------------------------------------
    %write out ratio/index metrics to a cumulative text file separately by half of stimulus period, VR 4/17/06
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_Ratio_halves_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t C1T1PcPsRat\t C1T1PcNsRat\t C1T1NcPsRat\t C1T1NcNsRat\t C1T2PcPsRat\t C1T2PcNsRat\t C1T2NcPsRat\t C1T2NcNsRat\t C2T1PcPsRat\t C2T1PcNsRat\t C2T1NcPsRat\t C2T1NcNsRat\t C2T2PcPsRat\t C2T2PcNsRat\t C2T2NcPsRat\t C2T2NcNsRat\t C3T1PcPsRat\t C3T1PcNsRat\t C3T1NcPsRat\t C3T1NcNsRat\t C3T2PcPsRat\t C3T2PcNsRat\t C3T2NcPsRat\t C3T2NcNsRat\t C4T1PcPsRat\t C4T1PcNsRat\t C4T1NcPsRat\t C4T1NcNsRat\t C4T2PcPsRat\t C4T2PcNsRat\t C4T2NcPsRat\t C4T2NcNsRat\t C5T1PcPsRat\t C5T1PcNsRat\t C5T1NcPsRat\t C5T1NcNsRat\t C5T2PcPsRat\t C5T2PcNsRat\t C5T2NcPsRat\t C5T2NcNsRat\t');  
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',  ...
        FILE, unique_coherence, spk_st_ratio_halves{1}(:,:,1)', spk_st_ratio_halves{2}(:,:,1)', ...
        spk_st_ratio_halves{1}(:,:,2)', spk_st_ratio_halves{2}(:,:,2)', spk_st_ratio_halves{1}(:,:,3)', spk_st_ratio_halves{2}(:,:,3)', ...
        spk_st_ratio_halves{1}(:,:,4)', spk_st_ratio_halves{2}(:,:,4)', spk_st_ratio_halves{1}(:,:,5)', spk_st_ratio_halves{2}(:,:,5)');
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %----------------------------------------------------------------------
    %write out index metrics to a cumulative text file separately by half of stimulus period, VR 4/17/06
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_Index_halves_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t C1T1PcPsIndt\t C1T1PcNsInd\t C1T1NcPsInd\t C1T1NcNsInd\t C1T2PcPsInd\t C1T2PcNsInd\t C1T2NcPsInd\t C1T2NcNsInd\t C2T1PcPsInd\t C2T1PcNsInd\t C2T1NcPsInd\t C2T1NcNsInd\t C2T2PcPsInd\t C2T2PcNsInd\t C2T2NcPsInd\t C2T2NcNsInd\t C3T1PcPsInd\t C3T1PcNsInd\t C3T1NcPsInd\t C3T1NcNsInd\t C3T2PcPsInd\t C3T2PcNsInd\t C3T2NcPsInd\t C3T2NcNsInd\t C4T1PcPsInd\t C4T1PcNsInd\t C4T1NcPsInd\t C4T1NcNsInd\t C4T2PcPsInd\t C4T2PcNsInd\t C4T2NcPsInd\t C4T2NcNsInd\t C5T1PcPsInd\t C5T1PcNsInd\t C5T1NcPsInd\t C5T1NcNsInd\t C5T2PcPsInd\t C5T2PcNsInd\t C5T2NcPsInd\t C5T2NcNsInd\t');  
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',  ...
        FILE, unique_coherence, spk_st_index_halves{1}(:,:,1)', spk_st_index_halves{2}(:,:,1)', ...
        spk_st_index_halves{1}(:,:,2)', spk_st_index_halves{2}(:,:,2)', spk_st_index_halves{1}(:,:,3)', spk_st_index_halves{2}(:,:,3)', ...
        spk_st_index_halves{1}(:,:,4)', spk_st_index_halves{2}(:,:,4)', spk_st_index_halves{1}(:,:,5)', spk_st_index_halves{2}(:,:,5)');
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output8)
    %----------------------------------------------------------------------
    %write out raw spike rate differences to a cumulative text file, VR 5/22/06
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_Diffs_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t SpkDlPDdf\t SpkDlNDdf\t SpkC1PcPsdf\t SpkC1PcNsdf\t SpkC1NcPsdf\t SpkC1NcNsdf\t SpkC2PcPsdf\t SpkC2PcNsdf\t SpkC2NcPsdf\t SpkC2NcNsdf\t SpkC3PcPsdf\t SpkC3PcNsdf\t SpkC3NcPsdf\t SpkC3NcNsdf\t SpkC4PcPsdf\t SpkC4PcNsdf\t SpkC4NcPsdf\t SpkC4NcNsdf\t SpkC5PcPsdf\t SpkC5PcNsdf\t SpkC5NcPsdf\t SpkC5NcNsdf\t SpkStPcPsdf\t SpkStPcNsdf\t SpkStNcPsdf\t SpkStNcNsdf\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',...
        FILE, unique_coherence(1), unique_coherence(2), unique_coherence(3), unique_coherence(4), unique_coherence(5), spk_dl_diff, ...
        spk_st_diff(1,:), spk_st_diff(2,:), spk_st_diff(3,:), spk_st_diff(4,:), spk_st_diff(5,:), mean(spk_st_diff,1) );
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output9)    
    %----------------------------------------------------------------------
    %write out delay period spike rates (computed a variety of ways) to a cumulative text file, VR 5/22/06
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CueDir_Spk_Delay_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t DlPDrat\t DlNDrat\t DlPDind\t DlNDind\t DlPDdf\t DlNDdf\t DlEndPDrat\t DlEndNDrat\t DlEndPDind\t DlEndNDind\t DlEndPDdf\t DlEndNDdf\t DlNoPDrat\t DlNoNDrat\t DlNoPDind\t DlNoNDind\t DlNoPDdf\t DlNoNDdf\t DlSpkPD\t DlSpkNeu\t DlSpkND\t DlEndSpkPD\t DlEndSpkNeu\t DlSpkEndND\t DlNoSpkPD\t DlNoSpkNeu\t DlNoSpkND\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t',...
        FILE, spk_dl_ratio, spk_dl_index, spk_dl_diff, ...
        spk_dl_end_ratio, spk_dl_end_index, spk_dl_end_diff, ...
        spk_dl_nostart_ratio, spk_dl_nostart_index, spk_dl_nostart_diff, ...
        mean_delay_spikes, mean_delay_spikes_end, mean_delay_spikes_nostart);
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end
if (output10)    
    %----------------------------------------------------------------------
    %write out ratios/indices of activity at zero coherence combining across both directions of "motion"
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\Zero_Coh_RatInd_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t C1PcRat\t C1NcRat\t C1PcInd\t C2NcInd\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t', ...
        FILE, zero_coh_PD_ratio, zero_coh_ND_ratio, zero_coh_PD_index, zero_coh_ND_index);
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end    
% keyboard
%% ********************** SAVE FIGS *****************************
SAVE_FIGS = 0;
if SAVE_FIGS
    saveas(hlist(1), sprintf('%s_CueDirEffects.fig',FILE),'fig');
    saveas(hlist(2), sprintf('%s_CueDirEffects_TimeC.fig',FILE),'fig');
end

return