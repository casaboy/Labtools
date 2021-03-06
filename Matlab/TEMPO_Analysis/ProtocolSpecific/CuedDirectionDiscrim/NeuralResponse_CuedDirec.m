%-----------------------------------------------------------------------------------------------------------------------
%-- NeuralResponse_CuedDirec.m -- Plot neural response as a function of coherence and validity, ala Britten etal '93.
%--	VR, 4/15/06 
%-----------------------------------------------------------------------------------------------------------------------

function NeuralResponse_CuedDirec(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

% global cum_delay_LFP cum_delay_spikes cum_delay_LFP_bp; %to allow activity to be cumulated across trials
% SAVE_GLOBAL_DATA = 1;

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
trials = 1:length(direction);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get outcome for each trial: 0=incorrect, 1=correct
trials_outcomes = logical (data.misc_params(OUTCOME,BegTrial:EndTrial) == CORRECT);

nreps = floor(length(cue_type)/60); %assumes the total number of trials is a multiple of 60. 

%get the firing rates and lfp during delay and stim for all the trials
stim_spikes = data.spike_rates(SpikeChan, BegTrial:EndTrial);
% if (isempty(data.lfp_data)) %in case the lfp data wasn't saved, fill a matrix with zeros so that the other analyses can occur
%     data.lfp_data = zeros(size(data.spike_data(1,:,BegTrial:EndTrial)));
%     SAVE_GLOBAL_DATA = 0;
% end
% for i = 1:sum(select_trials)
%     start_delay(i) = find(data.event_data(1,:,i+BegTrial-1) == CUE_ON_CD);
%     end_delay(i) = find(data.event_data(1,:,i+BegTrial-1) == VSTIM_ON_CD);
%     delay_spikes(i) = sum(data.spike_data(SpikeChan,start_delay(i):end_delay(i),i+BegTrial-1)) / length(start_delay(i):end_delay(i)) * 1000;
%     %note that lfp is sampled at half the frequency as spikes, so divide bins by 2
%     delay_lfp(i) = sqrt(mean( data.lfp_data(1,ceil(start_delay(i)/2):floor(end_delay(i)/2),i+BegTrial-1).^2 )); 
%     start_stim(i) = ceil(end_delay(i)/2);
%     end_stim(i) = floor(find(data.event_data(1,:,i+BegTrial-1) == VSTIM_OFF_CD)/2);
%     stim_lfp(i) = sqrt(mean( data.lfp_data(1,start_stim(i):end_stim(i),i+BegTrial-1) .^2 ));
%     
%     %do the following to get the power of lfp between 50 and 150Hz 
%     %(remove 120 Hz contribution as noise), 400 samples sampled at 500Hz
%     band = find( (500*(0:200)./400 >= 50) & (500*(0:200)./400 <= 150) & (500*(0:200)./400 ~= 120) ); 
%     lfp_stim_powerspect{i} = abs(fft(data.lfp_data(1,start_stim(i):end_stim(i),i+BegTrial-1),400)).^2 ./ 400;
%     stim_lfp_bp(i) = sum(lfp_stim_powerspect{i}(band));
%     lfp_delay_powerspect{i} = abs(fft(data.lfp_data(1,start_delay(i):end_delay(i),i+BegTrial-1),400)).^2 ./ 400;
%     delay_lfp_bp(i) = sum(lfp_delay_powerspect{i}(band));
% end

MarkerColor = {'b','r','g'};

%keyboard

hlist=figure; 
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Neural Response Function',FILE));
subplot(3, 1, 2); hold on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute mean and std errors for firing rates and plot
for i = 1:sum(unique_cue_val~=2)
    for j = 1:length(unique_direction)
        for k = 1:length(unique_coherence);
            ok_trials = find( (cue_val==unique_cue_val(i)) & (direction==unique_direction(j)) & (coherence==unique_coherence(k)) );
            mean_fr(i,j,k) = mean(stim_spikes(ok_trials));
            stderr_fr(i,j,k) = std(stim_spikes(ok_trials))./sqrt(length(ok_trials));
        end
        temp_handl = errorbar(unique_coherence,mean_fr(i,j,:),stderr_fr(i,j,:),'o','Color',MarkerColor{i});
        if unique_direction(j) == Pref_direction
            set(temp_handl,'MarkerFaceColor',MarkerColor{i}); %make the preferred direction points solid color
        end
        linfit_params{i,j} = regress(squeeze(mean_fr(i,j,:)),[unique_coherence ones(length(unique_coherence),1)]);
        fit_x = [-2 max(xlim)];
        plot(fit_x, fit_x.*linfit_params{i,j}(1) + linfit_params{i,j}(2),'Color',MarkerColor{i})
    end
end

% now generate 1d neurometric function, fit with logistic and plot
subplot(313); hold on;
for i = 1:sum(unique_cue_val~=2)
    for j = 1:length(unique_coherence)
        prefdir_trials = find( (cue_val==unique_cue_val(i)) & (direction==Pref_direction) & (coherence==unique_coherence(j)) );
        nulldir_trials = find( (cue_val==unique_cue_val(i)) & (direction~=Pref_direction) & (coherence==unique_coherence(j)) );
        n_obs(:,j) = [length(prefdir_trials); length(nulldir_trials)];
        roc_vals(i,j) = rocn(stim_spikes(prefdir_trials), stim_spikes(nulldir_trials));
    end
    plot(unique_coherence, roc_vals(i,:), 'o', 'Color',MarkerColor{i},'MarkerFaceColor',MarkerColor{i});
    [neuron_alpha(i), neuron_beta(i)] = logistic_fit([unique_coherence roc_vals(i,:)' sum(n_obs,1)']);
    fit_x = [0:0.1:max(xlim)];
    fit_y(i,:) = logistic_curve(fit_x,[neuron_alpha(i) neuron_beta(i)]);
    handl(i) = plot(fit_x, fit_y(i,:), MarkerColor{i});
end
ylim([0 1])
xlabel('Coherence (%)'); ylabel('% Correct'); 
legend(handl,'Invalid','Neutral','Valid','Location','SouthEast');
    
%now perform glm on the neural data to look for significant effect of slope
%now do glm to look for significant interactions of coherence and validity
yy=[]; count=1;
for j = 1:length(unique_coherence)
    for k = 1:sum(unique_cue_val~=2)
        yy(count,1) = unique_coherence(j);
        yy(count,2) = unique_cue_val(k);
        yy(count,3) = roc_vals(k,j); %fraction correct choices (folded)
        yy(count,4) = 1;
        count = count + 1;
    end
end
[b, dev, stats] = glmfit([yy(:,1) yy(:,2) yy(:,1).*yy(:,2)],[yy(:,3) yy(:,4)],'binomial');
p_shift = stats.p(3);
p_slope = stats.p(4);


%in addition, recompute behavioral performance at each (folded) coherence
%(needed for output for averaging)
for j = 1:sum(unique_cue_val~=2) %exclude cue_only trials
    for i=1:length(unique_coherence)
        seltrials = ((coherence == unique_coherence(i)) & (cue_val == unique_cue_val(j)) & select_trials);
        correct_trials = (seltrials & trials_outcomes );
        pct_correct_coh(j,i) = sum(correct_trials)/sum(seltrials);
    end
end


           
% keyboard;

for i = 1:length(unique_cue_val)
    pct_correct(i) = sum(trials_outcomes(cue_val==unique_cue_val(i))) ./ sum(cue_val==unique_cue_val(i));
end


%% ********************** PRINT INFO *****************************
%now, print out some useful information in the upper subplot
subplot(3, 1, 1);
PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);
%now, print out some specific useful info.
xpos = -10; ypos = 25;
font_size = 8;
bump_size = 6;
for j = 1:sum(unique_cue_val~=2)
    line = sprintf('Neuron: CueStatus = %s, alpha = %6.2f, beta = %6.2f%%', ...
        cue_val_names{unique_cue_val(j)+3}, neuron_alpha(j), neuron_beta(j));
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
end
line = sprintf('GLM output: P_shift = %6.4f, P_slope = %6.4f',p_shift,p_slope);
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Pct Correct:');
for j = 1:length(unique_cue_val)
    line = strcat(line, sprintf(' %s = %4.2f%%;',cue_val_names{unique_cue_val(j)+3},pct_correct(j)*100));
end
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Directions tested: %6.3f, %6.3f deg', unique_direction(1), unique_direction(2) );
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;


%some temporary stuff to save out raw data to a text file so cleaner graphs
%can be made in origin
savename = sprintf('NRF-%s.txt',FILE);
temp = unique_coherence';
save(savename, 'temp', '-ascii'); %this saves a row containing the values of unique_coherence
temp = roc_vals;
save(savename, 'temp', '-ascii', '-append'); %this saves 3 lines - each containing the roc values at each coherence for a single validity (invalid, neutral, valid)
temp = fit_x;
save(savename, 'temp', '-ascii', '-append'); %this saves the x-values of the best fit logistic curves
temp = fit_y;
save(savename, 'temp', '-ascii', '-append'); %this saves the three lines (one for each validity) of y-values of the best fit logistic curves
% 
% keyboard




output = 0;
output2 = 0; %pct corrects for both neural and behavioral data

if (output)
    %----------------------------------------------------------------------
    %write out fit_params and p_vals to a cumulative text file, VR 4/16/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\NeuralResponseCurves_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t CueOnlyPct\t pShift\t pSlope\t InvPdSl\t InvPdOff\t InvNdSl\t InvNdOff\t NeuPdSl\t NeuPdOff\t NeuNdSl\t NeuNdOff\t ValPdSl\t ValPdOff\t ValNdSl\t ValNdOff\t InvAlpha\t InvBeta\t NeuAlpha\t NeuBeta\t ValAlpha\t ValBeta\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.2f\t %8.6f\t %8.6f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t',...
        FILE, pct_correct(4)*100, p_shift, p_slope,...
        linfit_params{1}, linfit_params{4}, linfit_params{2}, linfit_params{5}, linfit_params{3}, linfit_params{6}, ...
        [neuron_alpha; neuron_beta]);
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
end

if (output2)
    %----------------------------------------------------------------------
    %write out raw percent corrects for both neural and behavioral performance to a cumulative text file, VR 10/03/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\NPfolded_pctcorr_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t CueOnlyPct\t nTrials\t Coher1\t Coher2\t Coher3\t Coher4\t Coher5\t pInvC1\t pInvC2\t pInvC3\t pInvC4\t pInvC5\t pNeuC1\t pNeuC2\t pNeuC3\t pNeuC4\t pNeuC5\t pValC1\t pValC2\t pValC3\t pValC4\t pValC5\t nInvC1\t nInvC2\t nInvC3\t nInvC4\t nInvC5\t nNeuC1\t nNeuC2\t nNeuC3\t nNeuC4\t nNeuC5\t nValC1\t nValC2\t nValC3\t nValC4\t nValC5\t '); 
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.4f\t %d\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %3.1f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t %4.2f\t ',...
        FILE, pct_correct(4), length(trials), unique_coherence, pct_correct_coh', roc_vals');
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);    
end


%% ********************** SAVE FIGS *****************************
SAVE_FIGS = 0;
if SAVE_FIGS
    saveas(hlist, sprintf('%s_NeuralResponseCurves.fig',FILE),'fig');
end

return