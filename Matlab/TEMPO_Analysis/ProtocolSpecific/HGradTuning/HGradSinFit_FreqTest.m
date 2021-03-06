function HGradSinFit_FreqTest(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, PATH, FILE)

TEMPO_Defs;

symbols = {'bo' 'ro' 'go' 'ko' 'c*' 'm*' 'b*' 'r*' 'g*'};
lines = {'b-' 'r-' 'g-' 'k-' 'c-' 'm-' 'b-.' 'r-.' 'g-.'};
lines2 = {'b--' 'r--' 'g--' 'k--' 'c--' 'm--' 'b:' 'r:' 'g:'};
colors = {[0 0 1] [1 0 0] [0 1 0] [0 0 0] [0 1 1] [1 0 1] [0 0 1] [1 0 0] [0 1 0]};


%Start Data Retrieval Routines---------------------------------------------------------------------------------------------------------
%get the column of values of horiz. disparity magnitude in the dots_params matrix
mag_disp = data.dots_params(DOTS_HGRAD_MAG,BegTrial:EndTrial,PATCH1);

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (mag_disp == data.one_time_params(NULL_VALUE)) );

unique_mag_disp = munique(mag_disp(~null_trials)');	

%get the column of values of horiz. disparity angle of orientation in the dots_params matrix
disp_ang = data.dots_params(DOTS_HGRAD_ANGLE,BegTrial:EndTrial,PATCH1);
unique_disp_ang = munique(disp_ang(~null_trials)');


%get the column of mean disparity values
mean_disp = data.dots_params(DOTS_HDISP,BegTrial:EndTrial,PATCH1);

%get indices of monoc. and uncorrelated controls
control_trials = logical( (mean_disp == LEYE_CONTROL) | (mean_disp == REYE_CONTROL) | (mean_disp == UNCORR_CONTROL) );

unique_mean_disp = munique(mean_disp(~null_trials & ~control_trials)');

%get the column of different aperture sizes
ap_size = data.dots_params(DOTS_AP_XSIZ,BegTrial:EndTrial,PATCH1);

%do all sizes
all_sizes = 0
unique_ap_size = munique(ap_size(~null_trials)');
if all_sizes ~= 1
    unique_ap_size = unique_ap_size(length(unique_ap_size));
    num_ap_size = length(unique_ap_size);
else
    num_ap_size = length(unique_ap_size);
end

%unique_ap_size = munique(ap_size(~null_trials)');

%now, get the firing rates for all the trials 
spike_rates = data.spike_rates(SpikeChan, :);

%get the average horizontal eye positions to calculate vergence
Leyex_positions = data.eye_positions(1, :);
Reyex_positions = data.eye_positions(3, :);

vergence = Leyex_positions - Reyex_positions;


%now, remove trials from hor_disp and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(mag_disp);		% a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%End Data Retrieval Routines---------------------------------------------------------------------------------------------------------
num_ap_size = length(unique_ap_size);
num_mag_disp = length(unique_mag_disp);
graph = figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [500 50 500 773], 'Name', 'Fitted Tilt Tuning Curves');

stat_out = '';
f_out = '';
checkfile = ['Z:\Users\jerry\GradAnalysis\figure_data\simul_r_sqared_mdisp.dat'];
if (exist(checkfile, 'file') == 0)    %file does not yet exist
    stat_out{1} = sprintf('File\tMDisp\tR\tTDI\tChiP\tIndErr\tConstErr\tPseq\n');
end
font_size = 8;
bump_size = 10;

curve_out = cell(1000,1);
num_free_params = 5;
p_val = zeros(length(unique_ap_size), length(unique_mean_disp));
pref_tilt = zeros(length(unique_ap_size), length(unique_mean_disp));
TDI_save = zeros(1,(length(unique_ap_size)));
curve_out = cell(1000,1);
pars_out = cell(6,1);
for i=1:length(unique_ap_size)
    TDIdata = [];
    xpos = -40;
    if length(unique_mag_disp) < length(unique_mean_disp)
        for j=1:length(unique_mag_disp)
            start = zeros(length(unique_mean_disp), 1);
            stop = zeros(length(unique_mean_disp), 1);
            fixed_freq = [];
            for k=1:length(unique_mean_disp)
                xpos = xpos + 25;
                figure(graph);
                hold on;
                subplot(num_ap_size*2, num_mag_disp,  ((j-1)*(num_mag_disp) + i)*2);
                disp_select = logical((ap_size == unique_ap_size(i)) & (mag_disp == unique_mag_disp(j)) & (mean_disp == unique_mean_disp(k)) );
                
                plot_x = disp_ang(disp_select & ~null_trials & ~control_trials & select_trials);
                plot_y = spike_rates(disp_select & ~null_trials & ~control_trials & select_trials);
                
                %NOTE: inputs to PlotTuningCurve must be column vectors, not row vectors, because of use of munique()
                [px, py, perr, spk_max, spk_min] = PlotTuningCurve(plot_x', plot_y', symbols{k}, '', 1, 1);
                [TDI(k), var_term] = Compute_DDI(plot_x, plot_y);
                
                %store data to calculate adjusted TDI later
                start(k) = length(TDIdata)+1;
                stop(k) = length(plot_x)+start(k)-1;
                TDIdata(start(k):stop(k), 1) = plot_x';
                TDIdata(start(k):stop(k), 2) = plot_y';
                
                px = (px * pi)/180;
                plot_x = (plot_x * pi)/180;
                means{k} = [px py];
                raw{k} = [plot_x' plot_y'];
                
                ind_means = [px py];
                ind_raw = [plot_x' plot_y'];
                
                %fit with a distorted sin wave
                ind_pars{k} = sin_exp_fit(ind_means,ind_raw);
                ind_sinerr(k) = sin_exp_err(ind_pars{k});
                
                %fit with fixed freq
                [fixed_pars{k} fixed_freq(k)] = sin_exp_fit_frqfixed(ind_means,ind_raw);
                temp_pars = [fixed_pars{k}(1); fixed_freq(k); fixed_pars{k}(2); fixed_pars{k}(3); fixed_pars{k}(4)];
                fixed_sinerr(k) = sin_exp_err(temp_pars);
                
                %grab pref_tilt of indp fits and plot indp fits
                x_interp = (px(1)): .01 : (px(length(px)));
                x_deg = (x_interp * 180)/pi;
                y_sin = sin_exp_func(x_interp, ind_pars{k});
                y_err = sin_exp_err(ind_pars{k});
                y_sin(y_sin < 0) = 0;
                hold on
                plot(x_deg, y_sin, lines2{k});
                
                %grab pref_tilt of fixed fits
                x_deg = (x_interp * 180)/pi;
                y_sin = sin_exp_func(x_interp, temp_pars);
                y_err = sin_exp_err(temp_pars);
                y_sin(y_sin < 0) = 0;
                hold on
                plot(x_deg, y_sin, lines{k});
                
                null_x = [min(x_deg) max(x_deg)];
                null_rate = mean(data.spike_rates(SpikeChan, null_trials & select_trials));
                null_y = [null_rate null_rate];
                
                size_deg = length(x_deg);                
                
                print_pars = 0;
                if print_pars == 1
                    for out=1:length(temp_pars)+1
                        if out == 1
                            pars_out{out} = sprintf('%s%3.2f\t', pars_out{out}, unique_mean_disp(k));
                        elseif out == 2
                            pars_out{out} = sprintf('%s%3.2f\t', pars_out{out}, temp_pars(1));
                        elseif out == 3
                            pars_out{out} = sprintf('%s%1.4f\t', pars_out{out}, temp_pars(2));
                        elseif out == 4
                            pars_out{out} = sprintf('%s%1.4f\t', pars_out{out}, temp_pars(3));
                        elseif out == 5
                            pars_out{out} = sprintf('%s%4.2f\t', pars_out{out}, temp_pars(4));
                        elseif out == 6
                            pars_out{out} = sprintf('%s%1.2f\t', pars_out{out}, temp_pars(5));
                        end
                    end                            
                end
                
                printcurves = 0;
                if printcurves == 1
                    %print out each individual tuning curve for origin
                    for go=1:length(x_deg)
                        if isempty(curve_out{go})
                            curve_out{go} = '';
                        end
                        if (go<=2)
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t%6.2f\t%6.2f\t%6.3f\t%6.2f\t%6.2f\t', curve_out{go}, x_deg(go), y_sin(go), px(go), py(go), perr(go), null_x(go),null_y(go));
                        elseif (go<=length(px))
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t%6.2f\t%6.2f\t%6.3f\t\t\t', curve_out{go}, x_deg(go), y_sin(go), px(go), py(go), perr(go));
                        else
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t\t\t\t\t\t', curve_out{go}, x_deg(go), y_sin(go));
                        end
                    end
                    curve_out{1};
                end %end printcurves;                                
                %store p-values of each curve
                temp_x =(plot_x *180)/pi;
                p_val(i,k) = calc_mdisp_anovap(disp_select, temp_x, plot_y, unique_disp_ang);
                [value, index_max] = max(y_sin);
                pref_tilt(i,k) = x_deg(index_max);
                
                %run chi^2 test on fit
                [chi2(k), chiP(k)] = Chi2_Test(ind_raw(:,1), ind_raw(:,2), 'sin_exp_func', ind_pars{k}, num_free_params);
                
                x_raw{k} = plot_x;
                y_raw{k} = plot_y;
                
                x_means{k} = px;
                y_means{k} = py;
                
                %calculate R^2 of mean response
                %add a column of ones to yfit to make regress happy
                y_fit_mean = sin_exp_func(x_means{k}, temp_pars);
                
                %check to see if values are identical
                check = y_fit_mean(1);
                check2 = find(y_fit_mean==check);
                if length(check2)==length(y_fit_mean)
                    y_fit_mean(k) = y_fit_mean(k) + (rand * .00001);
                end
                
                y_fit_cell{k} = [ones(length(y_fit_mean),1) y_fit_mean];
                [b_mean, bint_mean, r_mean, rint_mean, stats_mean] = regress(y_means{k}, y_fit_cell{k});
                
                r(k) = stats_mean(1);
                
                %run chi^2 test on fit
                [chi2_fixed(k), chiP_fixed(k)] = Chi2_Test(raw{k}(:,1), raw{k}(:,2), 'sin_exp_func', temp_pars, 4);        
                
                %print out the parameters for the current mean disparity in the correct subplot
                if(num_ap_size >= num_mag_disp)
                    subplot(num_ap_size*2, num_mag_disp,  (((j-1)*(num_mag_disp) + i)*2)-1);
                elseif(num_ap_size < num_mag_disp)
                    subplot(num_mag_disp*2, num_ap_size,  (((j-1)*(num_ap_size) + i)*2)-1);
                end
                
                axis([0 100 0 100]);
                axis('off');
                ypos = 110-(20*(i-1));         
                
                line = sprintf('M Disp = %3.2f', unique_mean_disp(k));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;         
                line = sprintf('Disp Mag = %3.2f', unique_mag_disp(j));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;         
                line = sprintf('Amp(%1d) = %3.2f', k, fixed_pars{k}(1));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                line = sprintf('Freq = %1d', fixed_freq(k));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                line = sprintf('Phase = %1.4f', fixed_pars{k}(2));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                line = sprintf('Base(%1d) = %3.2f', k, fixed_pars{k}(3));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                line = sprintf('Exp(%1d) = %1.2f', k, fixed_pars{k}(4));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                
                line = sprintf('Ind Err = %3.4f', ind_sinerr(k));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
                
                line = sprintf('Const Err = %3.4f', fixed_sinerr(k));
                text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;    
                
                stat_string = sprintf('\t%1.3f\t%1.4f\t%1.4f\t%1.4f\t%3.4f\t%3.4f', unique_mean_disp(k), r(k),  TDI(k), chiP_fixed(k), ind_sinerr(k), fixed_sinerr(k)); 
                stat_out{k+1} = stat_string;

            end %end mdisp
            %readjust mean disparity responses to fall on the same mean
            %then calc avg TDI
            %shifted_graphs = figure;
            %set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [750 50 500 773], 'Name', 'Mean Adjusted Tilt Tuning Curves');
            total_mean = mean(TDIdata(:,2));
            for count_meandisp = 1:length(unique_mean_disp)
                disp_mean = mean(TDIdata(start(count_meandisp):stop(count_meandisp),2));
                difference = total_mean - disp_mean;
                TDIdata(start(count_meandisp):stop(count_meandisp),2) = TDIdata(start(count_meandisp):stop(count_meandisp),2) + difference;
            end
            [TDI_adj(i), var_term] = compute_DDI(TDIdata(:,1)', TDIdata(:,2)');
        end %end mag disp
    else
        for j=1:length(unique_mean_disp)
            start = zeros(length(unique_mag_disp), 1);
            stop = zeros(length(unique_mag_disp), 1);
            for k=1:length(unique_mag_disp)
                figure(graph);
                hold on;
                subplot(num_mag_disp*2, num_ap_size,  ((k-1)*(num_ap_size) + i)*2);
                
                disp_select = logical((ap_size == unique_ap_size(i)) & (mag_disp == unique_mag_disp(k)) & (mean_disp == unique_mean_disp(j)) );
                
                plot_x = disp_ang(disp_select & ~null_trials & ~control_trials & select_trials);
                plot_y = spike_rates(disp_select & ~null_trials & ~control_trials & select_trials);
                
                %NOTE: inputs to PlotTuningCurve must be column vectors, not row vectors, because of use of munique()
                [px, py, perr, spk_max, spk_min] = PlotTuningCurve(plot_x', plot_y', symbols{k}, '', 1, 1);
                [TDI(k), var_term] = Compute_DDI(plot_x, plot_y);
                
                %store data to calculate adjusted TDI later
                start(k) = length(TDIdata)+1;
                stop(k) = length(plot_x)+start(k)-1;
                TDIdata(start(k):stop(k), 1) = plot_x';
                TDIdata(start(k):stop(k), 2) = plot_y';
                
                px = (px * pi)/180;
                plot_x = (plot_x * pi)/180;
                means{k} = [px py];
                raw{k} = [plot_x' plot_y'];
                
                ind_means = [px py];
                ind_raw = [plot_x' plot_y'];
                
                %fit with a distorted sin wave
                ind_pars{k} = sin_exp_fit(ind_means,ind_raw);
                ind_sinerr(k) = sin_exp_err(ind_pars{k});
                
                %fit with fixed freq
                fixed_pars{k} = sin_exp_fit_frqfixed(ind_means,ind_raw);
                fixed_sinerr(k) = sin_exp_err(fixed_pars{k});
                
                %grab pref_tilt of indp fits
                x_interp = (px(1)): .01 : (px(length(px)));
                x_deg= x_interp*180/pi;
                y_sin = sin_exp_func(x_interp, ind_pars{k});
                y_err = sin_exp_err(ind_pars{k});
                y_sin(y_sin < 0) = 0;
                hold on
                plot(x_deg, y_sin, lines2{k});
                
                null_x = [min(x_deg) max(x_deg)];
                null_rate = mean(data.spike_rates(SpikeChan, null_trials & select_trials));
                null_y = [null_rate null_rate];
                
                size_deg = length(x_deg);
                
                printcurves = 1;
                if printcurves == 1
                    %print out each individual tuning curve for origin
                    for go=1:length(x_deg)
                        if isempty(curve_out{go})
                            curve_out{go} = '';
                        end
                        if (go<=2)
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t%6.2f\t%6.2f\t%6.3f\t%6.2f\t%6.2f\t', curve_out{go}, x_deg(go), y_sin(go), px(go), py(go), perr(go), null_x(go),null_y(go));
                        elseif (go<=length(px))
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t%6.2f\t%6.2f\t%6.3f\t\t\t', curve_out{go}, x_deg(go), y_sin(go), px(go), py(go), perr(go));
                        else
                            curve_out{go} = sprintf('%s%6.2f\t%6.2f\t\t\t\t\t\t', curve_out{go}, x_deg(go), y_sin(go));
                        end
                    end
                    curve_out{1}
                end %end printcurves;                
                %store p-values of each curve
                temp_x =(plot_x *180)/pi;
                p_val(i,k) = calc_mdisp_anovap(disp_select, temp_x, plot_y, unique_disp_ang);
                [value, index_max] = max(y_sin);
                pref_tilt(i,k) = x_deg(index_max);
                
                %run chi^2 test on fit
                [chi2(k), chiP(k)] = Chi2_Test(ind_raw(:,1), ind_raw(:,2), 'sin_exp_func', ind_pars{k}, num_free_params);
                
                x_raw{k} = plot_x;
                y_raw{k} = plot_y;
                
                x_means{k} = px;
                y_means{k} = py;
            end %end mag disp
            %readjust slant responses to fall on the same mean
            %then calc avg TDI
            %shifted_graphs = figure;
            %set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [750 50 500 773], 'Name', 'Mean Adjusted Tilt Tuning Curves');
            total_mean = mean(TDIdata(:,2));
            for count_meandisp = 1:length(unique_mean_disp)
                disp_mean = mean(TDIdata(start(count_meandisp):stop(count_meandisp),2));
                difference = total_mean - disp_mean;
                TDIdata(start(count_meandisp):stop(count_meandisp),2) = TDIdata(start(count_meandisp):stop(count_meandisp),2) + difference;
            end
            [TDI_adj(i), var_term] = compute_DDI(TDIdata(:,1)', TDIdata(:,2)');
        end %end mdisp
    end %end if
    
    %print out curves here if multiple mdisps
    if length(unique_mag_disp) < length(unique_mean_disp)
        PATHOUT = 'Z:\Users\Jerry\GradAnalysis\';
        filesize = size(FILE,2) - 1;
        while FILE(filesize) ~='.'
            filesize = filesize - 1;
        end
        
        if print_pars == 1
            FILEOUT = [FILE(1:filesize) 'sin_freq_pars'];
            fileid = [PATHOUT FILEOUT];
            proffid = fopen(fileid, 'a');
            for go = 1:6
                fprintf(proffid, '%s\n', pars_out{go});
            end
            fclose(proffid);
        end
        
        if printcurves == 1
            %print out each individual tuning curve for origin
            FILEOUT = [FILE(1:filesize) 'sin_freq_curve'];
            fileid = [PATHOUT FILEOUT];
            printflag = 0;
            if (exist(fileid, 'file') == 0)    %file does not yet exist
                printflag = 1;
            end
            proffid = fopen(fileid, 'a');
            if (printflag)
                fprintf(proffid,'IntHDisp\tSinFit\tHDisp\tAvgResp\tStdErr\tSpon\n');
                printflag = 0;
            end
            for go = 1:size_deg
                fprintf(proffid, '%s\n', curve_out{go});
            end
            fclose(proffid);
        end
    end
    
    %print out the parameters for the current mean disparity in the correct subplot
    if(num_ap_size >= num_mag_disp)
        subplot(num_ap_size*2, num_mag_disp,  (((j-1)*(num_mag_disp) + i)*2)-1);
    elseif(num_ap_size < num_mag_disp)
        subplot(num_mag_disp*2, num_ap_size,  (((j-1)*(num_ap_size) + i)*2)-1);
    end
    
    %do Sequential F-test
    paired_err = sum(fixed_sinerr);
    independent_err = sum(ind_sinerr);
    num_shared = 1;  % freq is fixed to one in all fits.  just like all fits sharing a freq of 1.
    
    if(num_ap_size >= num_mag_disp)
        indep_params = length(ind_pars{1})*length(unique_mean_disp);
        paired_params = indep_params-(length(unique_mean_disp)-1)*num_shared;
    elseif(num_ap_size < num_mag_disp)    
        indep_params = length(ind_pars{1})*length(unique_mag_disp);
        paired_params = indep_params-(length(unique_mag_disp)-1)*num_shared;
    end
    
    Npts = length(spike_rates(~null_trials & ~control_trials & select_trials));
    Fseq = ( (paired_err - independent_err )/(indep_params-paired_params) ) / ( independent_err/(Npts - indep_params) );
    Pseq = 1 - fcdf(Fseq, (indep_params-paired_params), (Npts-indep_params) );      
    
    stat_string = sprintf('\t%1.4f', Pseq); 
    for loopcat = 2:length(stat_out)
        stat_out{loopcat} = strcat(stat_out{loopcat}, stat_string);
    end
    
    %if (length(unique_mag_disp) < length(unique_mean_disp))
    f_string = sprintf(' %1.4f %1.4f', TDI_adj(i), Pseq); 
    f_out = strcat(f_out, f_string);
    %end
    
    line = sprintf('Fseq = %1.4f', Fseq);
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
    line = sprintf('Pseq = %1.4f', Pseq);
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;   
    line = sprintf('Overall Err = %3.4f', paired_err);
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;  
    
    if(num_ap_size >= num_mag_disp)
        subplot(num_ap_size*2, num_mag_disp,  ((j-1)*(num_mag_disp) + i)*2);
        height = axis;
        yheight = height(4);
        string = sprintf('File = %s', FILE);
        text(height(1)+2, .95*yheight, string, 'FontSize', 8);
        for counter =1:length(unique_mean_disp)
            string = sprintf('r^2 = %1.4f, TDI = %1.4f', r(counter), TDI(counter));
            %string = sprintf('r^2 = %1.4f, TDI = %1.4f', r(counter), TDI(counter));
            text_handle = text(height(1)+2, (1-.05*counter-.05)*yheight, string, 'FontSize', 8);
            set(text_handle, 'Color', colors{counter});
        end 
    elseif(num_ap_size < num_mag_disp)
        subplot(num_mag_disp*2, num_ap_size,  ((j-1)*(num_ap_size) + i)*2);
        height = axis;
        yheight = height(4);
        string = sprintf('File = %s', FILE);
        text(height(1)+2, .95*yheight, string, 'FontSize', 8);
        for counter =1:length(unique_mag_disp)
            subplot(num_mag_disp*2, num_ap_size,  ((counter-1)*(num_ap_size) + i)*2);
            string = sprintf('r^2 = %1.4f, TDI = %1.4f', r(counter), TDI(counter));
            text_handle = text(height(1)+2, (1-.05*counter-.05)*yheight, string, 'FontSize', 8);
            set(text_handle, 'Color', colors{counter});
        end         
    end
    
    
end %end ap size

printme = 0;
if (printme==1)
    PATHOUT = 'Z:\Users\jerry\GradAnalysis\';
    
    line = sprintf('%s', FILE);
    for i=2:length(stat_out)
        stat_out{i} = strcat(line, stat_out{i});
    end
    
    %print statistics for each mean disparity
    outfile = [PATHOUT 'Fixed_Freq_fit_MDispStats_012803.dat'];
    print_label = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        print_label = 1;
    end
    
    fid = fopen(outfile, 'a');
    if print_label == 1
        fprintf(fid, '%s', [stat_out{1}]);
    end
    for i=2:length(stat_out)
        fprintf(fid, '%s', [stat_out{i}]);
        fprintf(fid, '\r\n');
    end
    fclose(fid);
    
    f_out = strcat(line, f_out);
    %print F statistics for single cell
    outfile = [PATHOUT 'Fixed_Freq_fit_FStats_012803.dat'];
    print_label = 0;
    if (exist(outfile, 'file') == 0)
        print_label = 1;
    end
    fid = fopen(outfile, 'a');
    if print_label == 1    %file does not yet exist
        fprintf(fid, 'File\tTDI\tSeqF_pval\n');
    end
    fprintf(fid, '%s', [f_out]);
    fprintf(fid, '\r\n');
    fclose(fid);
end

