%-----------------------------------------------------------------------------------------------------------------------
%-- DispVergCurves.m -- Plots the depth tuning curves for all three fixation distances.curve
%--	VR, 7/31/04
%-----------------------------------------------------------------------------------------------------------------------
function DispVergCurves(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

% not implemented yet to select output
output = 0;

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP
TEMPO_Defs;

%get the column of values of horiz. disparities in the dots_params matrix
h_disp = data.dots_params(DOTS_HDISP,:,PATCH1);

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (h_disp == data.one_time_params(NULL_VALUE)) );
unique_hdisp = munique(h_disp(~null_trials)');

%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(h_disp);		% a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get the column of values of fixation distances
all_depth_fix_real = data.dots_params(DEPTH_FIX_REAL,:,PATCH2);
depth_fix_real = all_depth_fix_real(~null_trials & select_trials); %excludes null trials
unique_depth_fix_real = munique(depth_fix_real');

%get the eye_position data
if (data.eye_calib_done)
    eye_positions = data.eye_positions_calibrated;
else
    eye_positions = data.eye_positions;
end

%now, get the firing rates for all the trials 
spike_rates = data.spike_rates(SpikeChan, :);

plot_x = h_disp(~null_trials & select_trials);
plot_y = spike_rates(~null_trials & select_trials);

size(plot_x);
size(plot_y);
size(depth_fix_real);

near_trials = [plot_x(depth_fix_real == 28.5); plot_y(depth_fix_real == 28.5)];
mid_trials = [plot_x(depth_fix_real == 57); plot_y(depth_fix_real == 57)];
far_trials = [plot_x(depth_fix_real == 114); plot_y(depth_fix_real == 114)];

figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [150 100 500 573], 'Name', 'Depth Tuning Curves at Multiple Planes of Fixation');
subplot(3, 1, 3);


%NOTE: inputs to PlotTuningCurve must be column vectors, not row vectors, because of use of munique()
[p_near_x, p_near_y, p_near_err] = PlotTuningCurve ([near_trials(1,:)]', [near_trials(2,:)]', 'ro', 'r-', 1, 1);
hold on;
[p_mid_x, p_mid_y, p_mid_err] = PlotTuningCurve ([mid_trials(1,:)]', [mid_trials(2,:)]', 'go', 'g-', 1, 1);
hold on;
[p_far_x, p_far_y, p_far_err] = PlotTuningCurve ([far_trials(1,:)]', [far_trials(2,:)]', 'bo', 'b-', 1, 1);


%hold on;
%plot the data, after shifting as necessary above
%plot(plot_x, plot_y, 'k.');

% errorbar(p_near_x, p_near_y, p_near_err, p_near_err, 'ro');
% hold on
% errorbar(p_mid_x, p_mid_y, p_mid_err, p_mid_err, 'go');
% errorbar(p_far_x, p_far_y, p_far_err, p_far_err, 'bo');

%hold on;

% Compute DDI at each depth of fixation.
[near_DDI, near_DDIvar] = Compute_DDI(near_trials(:,1), near_trials(:,2));
[mid_DDI, mid_DDIvar] = Compute_DDI(mid_trials(:,1), mid_trials(:,2));
[far_DDI, far_DDIvar] = Compute_DDI(far_trials(:,1), far_trials(:,2));


% %now, fit the data with a Gaussian curve and plot this as well
% %means = [[p_near_x, p_near_y] [p_mid_x, p_mid_y] [p_far_x, p_far_y]];
 [near_pars] = gaussfit([p_near_x, p_near_y], near_trials', 0);  %last arg: allow positive going fit only
 [mid_pars] = gaussfit([p_mid_x, p_mid_y], mid_trials', 0);
 [far_pars] = gaussfit([p_far_x, p_far_y], far_trials', 0);
% interp_near_x = (p_near_x(1)): 0.01 : (p_near_x(length(p_near_x)));
% interp_near_y = gaussfunc(interp_near_x, near_pars);
% interp_mid_x = (p_mid_x(1)): 0.01 : (p_mid_x(length(p_mid_x)));
% interp_mid_y = gaussfunc(interp_mid_x, mid_pars);
% interp_far_x = (p_far_x(1)): 0.01 : (p_far_x(length(p_far_x)));
% interp_far_y = gaussfunc(interp_far_x, far_pars);
% 
% near_handle = plot(interp_near_x, interp_near_y, 'r-');
% mid_handle = plot(interp_mid_x, interp_mid_y, 'g-');
% far_handle = plot(interp_far_x, interp_far_y, 'b-');

%raw = [plot_x' plot_y'];
%[pars] = gaussfit(means, raw, 0);   %last arg: allow positive going fit only
%x_interp = (px(1)): 0.5 : (px(length(px)));
%y_interp = gaussfunc(x_interp, pars);
%plot(x_interp, y_interp, 'k-');

%now, get the firing rate for NULL condition trials and add spontaneous rate to plot
null_x = [min(plot_x) max(plot_x)];
null_resp = data.spike_rates(SpikeChan, null_trials & select_trials);
null_rate = mean(null_resp);
null_y = [null_rate null_rate];

near_null_resp = data.spike_rates(SpikeChan, select_trials & null_trials & logical(all_depth_fix_real == 28.5));
near_null_rate = mean(near_null_resp);
mid_null_resp = data.spike_rates(SpikeChan, select_trials & null_trials & logical(all_depth_fix_real == 57));
mid_null_rate = mean(mid_null_resp);
far_null_resp = data.spike_rates(SpikeChan, select_trials & null_trials & logical(all_depth_fix_real == 114));
far_null_rate = mean(far_null_resp);

hold on;
plot(null_x, [null_rate null_rate], 'k--');
near_handle = plot(null_x, [near_null_rate near_null_rate], 'r--');
mid_handle = plot(null_x, [mid_null_rate mid_null_rate], 'g--');
far_handle = plot(null_x, [far_null_rate far_null_rate], 'b--');
hold off;

yl = YLim;
YLim([0 yl(2)]);	% set the lower limit of the Y axis to zero
XLabel('Relative Horizontal Disparity (deg)');
YLabel('Firing Rate (spikes/sec)');
legh=legend([near_handle, mid_handle, far_handle], '28.5cm fixation', '57cm fixation', '114cm fixation', 'Location', 'Best');
legend(legh,'boxoff');

% %Compute 2-way ANOVA over fixation distance and target depth
% %note that matlab requires an equal number of repetitions per condition.
% reps = floor(length(trials) / 30);
% am = zeros(length(unique_depth_fix_real) * reps, length(unique_hdisp)); %am=AnovaMatrix
% for i = 1:length(unique_depth_fix_real)
%     temp_verg = find(all_depth_fix_real == unique_depth_fix_real(i));
%     for j = 1:length(unique_hdisp)
%         temp_depth = find(h_disp(temp_verg) == unique_hdisp(j));
%         for k = 1:reps
%             am(reps*(i-1)+k,j) = spike_rates(temp_depth(k));
%         end
%     end
% end
% h = gcf;
% [anova_p, table] = anova2(am, reps);
% anova_p
% table

%%Compute R^2 of the fit for both means and raw values
%y_fit = gaussfunc(px, pars);
%y_fit(y_fit < 0) = 0;  
%%add a column of ones to yfit to make regress happy
%y_fit = [ones(length(y_fit),1) y_fit];
%[b, bint, r, rint, stats1] = regress(py, y_fit);

%y_fit_raw = gaussfunc(plot_x', pars);
%y_fit_raw(y_fit_raw < 0) = 0;
%y_fit_raw = [ones(length(y_fit_raw),1) y_fit_raw];
%[b, bint, r, rint, stats2] = regress(plot_y', y_fit_raw);

%% Do chi-square goodness of fit test
%[chi2, chiP] = Chi2_Test(plot_x, plot_y, 'gaussfunc', pars, length(pars));


%now, plot vergence data in middle subplot
subplot(3,1,2);
verg_hor = eye_positions(REYE_H, select_trials) - eye_positions(LEYE_H, select_trials);

depth_fix_real= all_depth_fix_real(select_trials);
near_verg_hor = verg_hor(find(depth_fix_real == 28.5));
mid_verg_hor  = verg_hor(find(depth_fix_real == 57));
far_verg_hor  = verg_hor(find(depth_fix_real == 114));

mean_verg_hor = [mean(near_verg_hor) mean(mid_verg_hor) mean(far_verg_hor)];
ideal_verg_hor = [-3.51816 0 1.75908]; %ideal angles according to Tempo, for 28.5 57 114 respectively
diff_verg_hor = mean_verg_hor - ideal_verg_hor;
stddev_verg_hor = [std(near_verg_hor) std(mid_verg_hor) std(far_verg_hor)];


errorbar([28.5 57 114], mean_verg_hor, stddev_verg_hor);
xlabel('fixation distance (cm)');
ylabel('horizontal vergence angle (deg)');
hold on;

str = sprintf('Err(28.5)=%1.2g',diff_verg_hor(1));
text (21, 2.8, str, 'FontSize', 8)
str = sprintf('Err(57)=%1.2g',diff_verg_hor(2));
text (49, 2.8, str, 'FontSize', 8)
str = sprintf('Err(114)=%1.2g',diff_verg_hor(3));
text (100, 2.8, str, 'FontSize', 8)

tol = 0.37310; %Based on 0.75 pseudo-degree wide vergence window.  
%plot lines on the graph marking the targets and the tolerances
line (23:33, ideal_verg_hor(1).*ones(11));
line (25:31, (ideal_verg_hor(1)+tol).*ones(7));
line (25:31, (ideal_verg_hor(1)-tol).*ones(7));
line (52:62, ideal_verg_hor(2).*ones(11));
line (54:60, (ideal_verg_hor(2)+tol).*ones(7));
line (54:60, (ideal_verg_hor(2)-tol).*ones(7));
line (109:119, ideal_verg_hor(3).*ones(11));
line (111:117, (ideal_verg_hor(3)+tol).*ones(7));
line (111:117, (ideal_verg_hor(3)-tol).*ones(7));




%now, print out some useful information in the upper subplot
%figure(h);
subplot(3, 1, 1);
PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

%% calculate some metrics and stats then print them in plot
near_pref_disp = near_pars(3);
near_base_rate = near_pars(1);
near_ampl = near_pars(2);
near_max_rate = near_base_rate + near_ampl;
near_width = sqrt(-(log(.5)))*near_pars(4)*2*sqrt(2);
near_DSI = 1 - (near_base_rate - near_null_rate)/(near_max_rate - near_null_rate);
near_DMI = Compute_ModIndex(near_trials(1,:), near_trials(2,:), near_null_resp);

mid_pref_disp = mid_pars(3);
mid_base_rate = mid_pars(1);
mid_ampl = mid_pars(2);
mid_max_rate = mid_base_rate + mid_ampl;
mid_width = sqrt(-(log(.5)))*mid_pars(4)*2*sqrt(2);
mid_DSI = 1 - (mid_base_rate - mid_null_rate)/(mid_max_rate - mid_null_rate);
mid_DMI = Compute_ModIndex(mid_trials(1,:), mid_trials(2,:), mid_null_resp);

far_pref_disp = far_pars(3);
far_base_rate = far_pars(1);
far_ampl = far_pars(2);
far_max_rate = far_base_rate + far_ampl;
far_width = sqrt(-(log(.5)))*far_pars(4)*2*sqrt(2);
far_DSI = 1 - (far_base_rate - far_null_rate)/(far_max_rate - far_null_rate);
far_DMI = Compute_ModIndex(far_trials(1,:), far_trials(2,:), far_null_resp);

pref_disp = [near_pref_disp, mid_pref_disp, far_pref_disp];
base_rate = [near_base_rate, mid_base_rate, far_base_rate];
ampl = [near_ampl, mid_ampl, far_ampl];
max_rate = [near_max_rate, mid_max_rate, far_max_rate];
width = [near_width, mid_width, far_width];
DSI = [near_DSI, mid_DSI, far_DSI];
DMI = [near_DMI, mid_DMI, far_DMI];

%pref_dir = pars(3);
%p_value = spk_anova(plot_y, plot_x, unique_dirs);
%base_rate = pars(1);
%amplitude = pars(2);
%max_rate = base_rate + amplitude;
%width = sqrt(-(log(.5)))*pars(4)*2*sqrt(2);
%DSI = 1 - (base_rate - null_rate)/(max_rate - null_rate); 

%%Calculate modulation index using sqrt raw responses and subtracting spontaneous
%DMI = Compute_ModIndex(plot_x, plot_y, null_resp);

%PrintDirectionData(p_value, base_rate, null_rate, amplitude, pref_dir, max_rate, width, DSI, stats1, stats2, DirDI, chi2, chiP); 


% %output tuning curve metrics
% if (output == 1)
%     i = size(PATH,2) - 1;
%     while PATH(i) ~='\'	%Analysis directory is one branch below Raw Data Dir
%         i = i - 1;
%     end   
%     PATHOUT = [PATH(1:i) 'Analysis\Tuning\'];
%     i = size(FILE,2) - 1;
%     while FILE(i) ~='.'
%         i = i - 1;
%     end
%     FILEOUT = [FILE(1:i) 'dir'];
%     
%     fileid = [PATHOUT FILEOUT];
%     fwriteid = eval(['fopen(fileid, ''w'')']);
%     %fprintf(fwriteid, '%%Base Rate (q1)	Amplitude (q2)	Pref dir (q3)	q4	Width(FWHM)	Max Resp	Spont Resp	DSI	Curve ANOVA	Mapped Pref Dir	Pref Speed	Pref H Disp	RF X-Ctr	RF Y-Ctr	Diam\n');
%     fprintf(fwriteid, '%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f	%5.2f\n', pars(1), pars(2), pars(3), pars(4), width, max_rate, null_rate, DSI, p_value, data.one_time_params(PREFERRED_DIRECTION), data.one_time_params(PREFERRED_SPEED), data.one_time_params(PREFERRED_HDISP), data.one_time_params(RF_XCTR), data.one_time_params(RF_YCTR), data.one_time_params(RF_DIAMETER));
% 
% 	fclose(fwriteid);
% 
%    %---------------------------------------------------------------------------------------
%    %also write out data in form suitable for plotting tuning curve with Origin.
%     FILEOUT2 = [FILE(1:i) 'direc_curv_fit'];
%     fileid = [PATHOUT FILEOUT2];
%     proffid = fopen(fileid, 'w');
%     fprintf(proffid,'DirIn\tFit\tDirec\tAvgResp\tStdErr\tDir2\tSpon\n');
%     for kk=1:length(x_interp)
%         fprintf(proffid,'%6.2f\t%6.2f\t', x_interp(kk), y_interp(kk));
%         if (kk <= length(px))
%             fprintf(proffid,'%6.2f\t%6.2f\t%6.3f\t', px(kk), py(kk), perr(kk));
%         else
%             fprintf(proffid,'\t\t\t');
%         end
%         if (kk <= 2)
%             fprintf(proffid,'%6.2f\t%6.2f\n',null_x(kk),null_y(kk));
%         else
%             fprintf(proffid,'\t\n');
%         end
%     end
%     fclose(proffid);
%     
%     %---------------------------------------------------------------------------------------
%     %ALso, write out summary data to a cumulative summary file
%     [pdir360, pdir180, pdir90] = AngleWrap(pref_dir);
%     buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %10.8f\t %6.3f\t %10.8f\t %6.3f\t %10.8f\t %6.4f\t %6.3f\t %8.5f\t %10.8f\t', ...
%         FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
%         null_rate, DMI, base_rate, amplitude, pdir360, pdir180, pdir90, width, DSI, p_value, stats1(1), stats1(3), stats2(1), stats2(3), DirDI, var_term, chi2, chiP);
%     outfile = [BASE_PATH 'ProtocolSpecific\DirectionTuning\DirectionTuningSummary.dat'];
%     printflag = 0;
%     if (exist(outfile, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t\t PrDir\t PrSpd\t PrHDsp\t RFX\t RFY\t RFDiam\t Spont\t DirMI\t BRate\t Ampl\t PD360\t PD180\t PD90\t FWHM\t DSI\t AnovaP\t\t Rmeans\t Pmeans\t\t Rraw\t Praw\t\t DirDI\t VarTrm\t Chi2\t\t ChiP\t\t');
%         fprintf(fid, '\r\n');
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
%     %---------------------------------------------------------------------------------------
%     
%     %output a cumulative file of the Gaussian fit parameters
%     outfile = [BASE_PATH 'ProtocolSpecific\DirectionTuning\DirectionParams.dat'];
%     printflag = 0;
%     if (exist(outfile, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fsummid = fopen(outfile, 'a');
%     if (printflag)
%         fprintf(fsummid, 'FILE\t\t q(1)\t q(2)\t q(3)\t q(4)\t spont\t');
%         fprintf(fsummid, '\r\n');
%     end
%     fprintf(fsummid, '%s\t %7.5f %7.5f %7.5f %7.5f %7.5f', FILE, pars(1), pars(2), pars(3), pars(4), null_rate);
%     fprintf(fsummid, '\r\n');
%     fclose(fsummid);
%     
% end
% 

return;