function RFContourFigurePlot(data, Protocol, Analysis, SpikeChan, SpikeChan2, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% XY domain size: 3 x 3 degs?
% Time domain: 0 - 200 msec in 20 msec steps
% Grid Size: 4 x 4?
% Number of repetitions: ??
% Total time for RF measurement: ?? min
% Duration of individual stimuli: 100 msec? (6 frames)
% direcs_per_patch = floor(visual_stim_time /(1000.0/REFRESH_RATE*static_params[PATCH_DWELL]));
ProtocolDefs;
Path_Defs;

g_spikeTracker = zeros(30, 30, 30, 360);
g_dirCounter = zeros(30, 30, 360);
g_spikeTracker_f = zeros(30, 30, 30, 360);
g_dirCounter_f = zeros(30, 30, 360);

% Set the correlation delay parameters.
corrDelayLow = 0;
corrDelayInc = 10;
corrDelayHigh = 200;
figure(2);clf;

for (trial = 1:size(data.revcorr_params, 2))
    % Draw the contour subplot.
    %    figure(plotWindow);        
    figure(2);
    fprintf('Analyzing Trial: %d\n', trial);
    
    % Grab the random directions list.
    random_directions = squeeze(data.revcorr_params(DOT_DIREC, trial, :));    
    % Determine the unique directions from the random direction list.
    x = find(isnan(random_directions) == 0);
    uniqueDirs = munique(random_directions(1:length(x)))';
    
    % Grab the number of width and height patches.
    numXpatches = data.revcorr_params(PATCH_DIMS, 1, 1);
    numYpatches = data.revcorr_params(PATCH_DIMS, 1, 2);
    
    % Determine total number of directions per patch.
    numDirections = length(x) / (numXpatches * numYpatches);
    
    % Create the correlation delay matrix.
    corrDelay = [corrDelayLow:corrDelayInc:corrDelayHigh];
    
    % Store all the different spike histograms we collect in this data
    % structure.
    spikeHist = {};    
    spikeHist_f={};
    spikeHistIndex = 0;
    maxCount = 0;    
    
    % Pull out the original spikes.
    origSpikes = squeeze(data.spike_data(SpikeChan, :, trial));
    origSpikes_f=squeeze(data.spike_data(SpikeChan, :, trial));     
    %origSpikes = spike_data{curr_condition,num_reps{curr_condition}}(:,1);    
    % Figure out what the edges will be for the spike histogram.
    histEdges = find(squeeze(data.spike_data(2, :, trial)) ~= 0);
    meanEdge = round(mean(diff(histEdges)));
    histEdges = [histEdges, histEdges(length(histEdges)) + meanEdge];
    
    % Do a spike histogram for all the correlation delays.
    for (delay = corrDelay)
        spikeHistIndex = spikeHistIndex + 1;        
        % Shift the spikes over to compensate for neuron lag.  Pad the end with
        % zeros because shifting will truncate the vector.
        shiftedSpikes = origSpikes(delay+1:length(origSpikes));
        shiftedSpikes = [shiftedSpikes, zeros(1, 5000-length(shiftedSpikes))]; 
        % Find all shiftedSpikes elements that aren't zero.
        spikeTimes = find(shiftedSpikes);
        % Do a histogram to bin out spike counts for each direction presented
        % in the trial.
        tmpHist = histc(spikeTimes, histEdges);
        spikeHist{spikeHistIndex} = tmpHist(1:length(tmpHist)-1); 
        
        %forward to get the noise level       
        shiftedSpikes_f=zeros(1,delay+1);
        shiftedSpikes_f = [shiftedSpikes_f,origSpikes_f(1:5000-length(shiftedSpikes_f))];       
%        shiftedSpikes_f = [origSpikes_f(1:5000-length(shiftedSpikes_f)),shiftedSpikes_f];       
        spikeTimes_f= find(shiftedSpikes_f);
        tmpHist_f = histc(spikeTimes_f, histEdges);
        spikeHist_f{spikeHistIndex} = tmpHist_f(1:length(tmpHist_f)-1);
    end
    
    % OK.  The basic strategy here is to iterate through every
    % patch and use the histogram we did above to add on directions
    % to make another histogram, which will be our analysis.
    % Example, we'll look at patch (0,0) and figure out which
    % directions were displayed in that patch during the trial.
    % Then, we'll take each direction and add it to a vector the number of
    % times it is represented in the histogram calculated above.
    for (Xpatch = 1:numXpatches)
        for (Ypatch = 1:numYpatches)           
            % Determine total number of directions per patch.
            % numDirections = totalDirections / (numXpatches * numYpatches);
            % Keep track of how many times each direction was displayed per
            % patch so we can normalize the results.
            for (k = 1:numDirections)
                angle = random_directions((Xpatch-1)*numDirections*numYpatches + (Ypatch-1)*numDirections + k) + 1;
                g_dirCounter(Xpatch, Ypatch, angle) = g_dirCounter(Xpatch, Ypatch, angle) + 1;
                g_dirCounter_f(Xpatch, Ypatch, angle) = g_dirCounter_f(Xpatch, Ypatch, angle) + 1;                
            end

            for (z = 1:spikeHistIndex)
                % Pull out a spike histogram from the list.
                spikeHistArray = [spikeHist{z}]; 
                spikeHistArray_f = [spikeHist_f{z}];                 
                for (k = 1:numDirections)
                    % Extract the direction for this segment.
                    angle = random_directions((Xpatch-1)*numDirections*numYpatches + (Ypatch-1)*numDirections + k) + 1;                    
                    % Add the hist count for this patch, angle, delay combination.
                    g_spikeTracker(Xpatch, Ypatch, z, angle) = g_spikeTracker(Xpatch, Ypatch, z, angle) + spikeHistArray(k);
                    g_spikeTracker_f(Xpatch, Ypatch, z, angle) = g_spikeTracker_f(Xpatch, Ypatch, z, angle) + spikeHistArray_f(k);
                end % End for (k = 1:numDirections)
            end % End for (z = 1:spikeHistIndex)            
        end % End for (Ypatch = 1:numYpatches)
    end % End for (Xpatch = 1:numXpatches)    
end % End for (trial = 1:size(data.revcorr_params, 2))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Find optimal correlation delay (using max avg variance)
Variance0=0;
for (Xpatch = 1:numXpatches)
    for (Ypatch = 1:numYpatches)           
        cplot = zeros(spikeHistIndex+2, length(uniqueDirs)+2);
        cplot_f = zeros(spikeHistIndex+2, length(uniqueDirs)+2);
        for (cindex = 1:spikeHistIndex)                 
            tmp = squeeze(g_spikeTracker(Xpatch, Ypatch, cindex, uniqueDirs+1))';
            tmp_f=squeeze(g_spikeTracker_f(Xpatch, Ypatch, cindex, uniqueDirs+1))';
            normalizedHist = [];
            normalizedHist_f = [];
            for (div = 1:length(uniqueDirs))
                if (g_dirCounter(Xpatch, Ypatch, uniqueDirs(div)+1) == 0)
                    normalizedHist(div) = 0;
                    normalizedHist_f(div)=0;
                else
                    normalizedHist(div) = tmp(div) / g_dirCounter(Xpatch, Ypatch, uniqueDirs(div)+1);
                    normalizedHist_f(div) = tmp_f(div) / g_dirCounter_f(Xpatch, Ypatch, uniqueDirs(div)+1);
                end
            end
            cplot(cindex+1, :) = [0, normalizedHist, 0];          
            cplot_f(cindex+1, :) = [0, normalizedHist_f, 0];          
            [tmpMax, DirectionIndex]=max(normalizedHist);
            [tmpMax_f, DirectionIndex_f]=max(normalizedHist_f);
            Variance=var(normalizedHist);
            Variance_f=var(normalizedHist_f);
            if (tmpMax > maxCount)
                maxCount = tmpMax;
                maxCount_f = tmpMax_f;
            end
            if (Variance > Variance0)
                Variance0 = Variance;
                maxX=Xpatch;
                maxY=Ypatch;
                maxDelay=corrDelay(cindex);
                maxDirection=uniqueDirs(DirectionIndex);
            end       
        end           
        figure(2);subplot(numXpatches, numYpatches, Xpatch + (Ypatch-1)*numXpatches);contourf(cplot);
        figure(3);subplot(numXpatches, numYpatches, Xpatch + (Ypatch-1)*numXpatches);contourf(cplot_f);        
    end % End for (Ypatch = 1:numYpatches)
end % End for (Xpatch = 1:numXpatches)

for (Xpatch = 1:(numXpatches*numYpatches))
    figure(2);subplot(numXpatches, numYpatches, Xpatch);caxis([0, maxCount]); 
    ticks = corrDelay(1:2:length(corrDelay));
    set(gca,'YTickLabel', ticks);
    y = [2:2:size(cplot, 1)];
    set(gca, 'YTick', y);
    set(gca, 'TickDir', 'out');
    x = mean(diff(uniqueDirs));
    set(gca, 'XTick', [2:2:length(uniqueDirs)]);
    set(gca, 'XTickLabel', uniqueDirs([1:2:length(uniqueDirs)]));
    hold on;line([min(XLim) max(XLim)],[maxDelay/max(corrDelay)*size(cplot,1) maxDelay/max(corrDelay)*size(cplot,1)],'LineWidth',2.0,'Color','k');
    if (Xpatch == numXpatches*numYpatches)
        colorbar;
    elseif (Xpatch == 1)
        % Puts a label that says the filename above all the subplots.
        text(0, 27, [PATH, FILE]); 
    end
    figure(3);subplot(numXpatches, numYpatches, Xpatch);caxis([0, maxCount_f]); 
    ticks = corrDelay(1:2:length(corrDelay));
    set(gca,'YTickLabel', ticks);
    y = [2:2:size(cplot, 1)];
    set(gca, 'YTick', y);
    set(gca, 'TickDir', 'out');
    x = mean(diff(uniqueDirs));
    set(gca, 'XTick', [2:2:length(uniqueDirs)]);
    set(gca, 'XTickLabel', uniqueDirs([1:2:length(uniqueDirs)]));    
    if (Xpatch == numXpatches*numYpatches)
        colorbar;
    elseif (Xpatch == 1)
        % Puts a label that says the filename above all the subplots.
        text(0, 27, [PATH, FILE]); 
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%`
%At max delay, fit direction vs response data for each loc
clear DelayIndex;DelayIndex=find(corrDelay==maxDelay);
cplot_wrapped=zeros(numXpatches+2, numYpatches+2);
param_label = 'A          mu         sigma       DC';
MaxCount_Fitted=0;
figure(4);clf;
for Xpatch=1:numXpatches
    for Ypatch=1:numYpatches          
        clear Response; Response=squeeze(g_spikeTracker(Xpatch,Ypatch,DelayIndex, uniqueDirs+1))';
        DirectionNumber=squeeze(g_dirCounter(Xpatch,Ypatch,uniqueDirs+1))';
        Response=Response./DirectionNumber;
        k=Xpatch + (Ypatch-1)*numXpatches;
        [Response_F, x, x0]=OrienFitting(Response);
        NewX{k}=x;
        NewX0{k}=x0;
        xDirection=[0    45    90   135   180   225   270   315 ]*pi/180;
        figure(4);subplot(numXpatches,numYpatches, Xpatch + (Ypatch-1)*numXpatches);plot(xDirection,Response,'bo');hold on; % ylim([0 maxCount])        
        temp_Ori1(k,:)=xDirection;
        temp_Ori2(k,:)=Response;        
        % finish plotting
        x_smooth = 0:0.01:2*pi;
        y_smooth = (DirCurvefit(x,x_smooth));
        xdata_tran = [0    45    90   135   180   225   270   315]*pi/180;%xdata_tran = [-90 -45 0 45 90 135 180 225 270] * pi/180;
        x_smooth_tran = xdata_tran(1):0.01:xdata_tran(end);
        y_smooth_tran = (DirCurvefit(x,x_smooth_tran));
        plot(x_smooth_tran,y_smooth_tran,'r');        
        temp_Fit1(k,:)=x_smooth_tran;
        temp_Fit2(k,:)=y_smooth_tran;
        % take peak of fitted function as preferred heading 
        peak = x_smooth(find(y_smooth == max(y_smooth))) * 180/pi;
        cplot_wrapped(Xpatch+1,Ypatch+1)=max(y_smooth_tran)-min(y_smooth_tran);%????        
        tempMaxCount_Fitted=max(y_smooth_tran);
        if (tempMaxCount_Fitted > MaxCount_Fitted)
            MaxCount_Fitted=tempMaxCount_Fitted
        end     
        xlim( [xdata_tran(1) xdata_tran(end)]);
        set(gca, 'xtick', xdata_tran);
        set(gca, 'xticklabel','0|45|90|135|180|225|270|315');  
        Fit_Error(Xpatch,Ypatch)=100/length(xDirection)*sum(abs(Response_F-Response)/max(Response));        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get the circular variance at the maxDelay
        clear Rate Resp;
%         Rate=squeeze(g_spikeTracker(Xpatch,Ypatch,DelayIndex,uniqueDirs+1))';
%         Resp=sum(Rate.*exp(2*i*uniqueDirs/180*pi))/sum(Rate);
%         CV_Max(Xpatch,Ypatch)=1-abs(Resp); 
        Resp=sum(Response.*exp(2*i*uniqueDirs/180*pi))/sum(Response);
        CV_Max(Xpatch,Ypatch)=1-abs(Resp);   
        
        TempResp(Xpatch,Ypatch)=abs(Resp);
%        [Azi_Max(Xpatch,Ypatch), Ele_Max(Xpatch,Ypatch), Amp_Max(Xpatch,Ypatch)] = vectorsum(Response);
        [Azi_Max(Xpatch,Ypatch), Ele_Max(Xpatch,Ypatch), Amp_Max(Xpatch,Ypatch)] = vectorsum(Response/max(Response));
        r_Max(Xpatch,Ypatch) = 1-abs(Amp_Max(Xpatch,Ypatch)) / sum(Response/max(Response)); 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %Also, write out some summary data to a cumulative summary file
%         sprint_txt=['%s\t %f\t   %f\t   %f\t   %f\t   %f\t   %f\t   %f\t   %f\t'];
%         buff=sprintf(sprint_txt, FILE, x0(1), x0(2)*180/pi, x0(3)*180/pi, x0(4), x(1),x(2)*180/pi, x(3)*180/pi, x(4));
%         outfile =['Z:\Users\Aihua\Cluster_Analysis\ReverseCorrelation\CurveFit.dat'];
%         printflag = 0;
%         if (exist(outfile, 'file') == 0)    %file does not yet exist
%             printflag = 1;
%         end
%         fid = fopen(outfile, 'a');
%         if (printflag)
%             fprintf(fid, 'FILE\t         A0\t mu0\t sigma0\t DC0\t A\t mu\t sigma\t DC\t');
%             fprintf(fid, '\r\n');
%         end
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%         fclose(fid);
    end
end 

for (Xpatch = 1:(numXpatches*numYpatches))   
    figure(4);subplot(numXpatches, numYpatches, Xpatch);  ylim([0 MaxCount_Fitted+0.2]);
    % show params for each fit
    param_text = [num2str(NewX{Xpatch}(1),'%1.2f') '     ' num2str(NewX{Xpatch}(2)*180/pi,'%1.2f') '    ' num2str(NewX{Xpatch}(3)*180/pi,'%1.2f') '     ' num2str(NewX{Xpatch}(4),'%1.2f')];            
    x0_text = [num2str(NewX0{Xpatch}(1),'%1.2f') '     ' num2str(NewX0{Xpatch}(2)*180/pi,'%1.2f') '    ' num2str(NewX0{Xpatch}(3)*180/pi,'%1.2f') '     ' num2str(NewX0{Xpatch}(4),'%1.2f')];    
    y_lim = ylim;
    y_range = y_lim(2)-y_lim(1);
    text(0, y_lim(2)+.17*y_range, param_label,'FontSize', 8);
    text(0, y_lim(2)+.10*y_range, x0_text, 'FontSize', 8);
    text(0, y_lim(2)+.03*y_range, param_text, 'FontSize',8);     
    if (Xpatch == numXpatches*numYpatches)
        legend('Original Data', 'Fitted Curve',4);xlabel('Azimuth');ylabel('Normalized Response');       
    elseif (Xpatch == 1)
        % Puts a label that says the filename above all the subplots.
        text(-2, y_lim(2)+.35*y_range, [PATH, FILE]); text(750,4,['Time= -',num2str(maxDelay),'ms']);       
    end    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%check significance of Cirular Variance and calculate p value, do bootstrap at the same
%time to test value varience

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot the circular variance and calculate p value or significant test
% Borghuis B.G. (2003). The motion reverse correlation (MRC) method: A
% linear systems approach in the motion domain. Journal of Neuroscience
% Method 123: 153-166.
clear CV Rate Resp;
bin=0.005;
x_bin=0:bin:1;
%perm_num=1000;
for (Xpatch = 1:numXpatches)
    for (Ypatch = 1:numYpatches) 
        for (DelayIndex = 1:spikeHistIndex)  
            clear Response; Response=squeeze(g_spikeTracker_f(Xpatch,Ypatch,DelayIndex, uniqueDirs+1))';
            DirectionNumber=squeeze(g_dirCounter_f(Xpatch,Ypatch,uniqueDirs+1))';
            Response=Response./DirectionNumber;
            Resp_f=sum(Response.*exp(2*i*uniqueDirs/180*pi))/sum(Response);
            CV_f(Xpatch,Ypatch,DelayIndex)=1-abs(Resp_f);             

            [Azi(Xpatch,Ypatch,DelayIndex), Ele(Xpatch,Ypatch,DelayIndex), Amp(Xpatch,Ypatch,DelayIndex)] = vectorsum(Response/max(Response));
            r_f(Xpatch,Ypatch,DelayIndex) = 1-abs(Amp(Xpatch,Ypatch,DelayIndex)) / sum(Response/max(Response));
        end

        figure(5);subplot(numXpatches, numYpatches, Xpatch + (Ypatch-1)*numXpatches);hist(CV_f(Xpatch,Ypatch,:),x_bin);axis([0.8 1 0 10]);
        figure(6);subplot(numXpatches, numYpatches, Xpatch + (Ypatch-1)*numXpatches);hist(r_f(Xpatch,Ypatch,:),x_bin);axis([0.6 1 0 10]);
        
        MeanCV(Xpatch,Ypatch)=mean(CV_f(Xpatch,Ypatch,:));%axis([0.8 1 0 10]);text(0.9,8,['mean=', num2str(mean(CV))]);        
        hist_cv=hist(CV_f(Xpatch,Ypatch,:),x_bin);
        hist_r=hist(r_f(Xpatch,Ypatch,:),x_bin);
%         hist_cv=hist(CV(Xpatch,Ypatch,:),x_bin);
        bin_sum=0;
        n=0;
        while(n<=(CV_Max(Xpatch,Ypatch)/bin))
            n=n+1;
            bin_sum=bin_sum+hist_cv(1,n);
            %p(Xpatch,Ypatch)=(perm_num-bin_sum)/perm_num;
            CVp(Xpatch,Ypatch)=bin_sum/sum(hist_cv);
        end
        
        bin_sum=0;
        n=0;
        while (n<=(r_Max(Xpatch,Ypatch)/bin))
            n=n+1;
            bin_sum=bin_sum+hist_r(1,n);
            rp(Xpatch,Ypatch)=bin_sum/sum(hist_r);
        end
        
%         bin_sum = 0;
%         n = 0;
%         while ( bin_sum < 0.025*sum(hist_cv) )   % define confidential value to be 0.05, now consider one side only which is 0.025 of confidence
%             n = n+1;
%             bin_sum = bin_sum + hist_cv(1, n);      
%             pp(Xpatch,Ypatch) = CV_Max(Xpatch,Ypatch) - n * bin ;    % calculate what HTI value is thought to be significant different            
%         end
        figure(4);subplot(numXpatches,numYpatches, Xpatch + (Ypatch-1)*numXpatches); 
        x_lim=xlim;y_lim=ylim;
        text(0.5*x_lim(2),0.9*y_lim(2),['CirVar=',num2str(CV_Max(Xpatch,Ypatch))],'FontSize', 8);
        text(0.5*x_lim(2),0.75*y_lim(2),['p=',num2str(CVp(Xpatch,Ypatch))],'FontSize', 8);        
        text(0.5*x_lim(2),0.45*y_lim(2),['VectAmp=',num2str(Amp_Max(Xpatch,Ypatch))],'FontSize', 8);        
        text(0.5*x_lim(2),0.3*y_lim(2),['r=',num2str(r_Max(Xpatch,Ypatch))],'FontSize', 8);        
        text(0.5*x_lim(2),0.15*y_lim(2),['rp=',num2str(rp(Xpatch,Ypatch))],'FontSize', 8);        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fit the Spatial_RF map with a two-dimensional Gaussian function
x_interp=1:numXpatches+2;
y_interp=1:numYpatches+2;
for Xpatch=1:length(x_interp)
    for Ypatch=1:length(y_interp)
        temp(((Xpatch-1)*(length(y_interp)) + Ypatch), 1) = x_interp(Xpatch);
        temp(((Xpatch-1)*(length(y_interp)) + Ypatch), 2) = y_interp(Ypatch);
        temp(((Xpatch-1)*(length(y_interp)) + Ypatch), 3) = cplot_wrapped(Xpatch, Ypatch);
        z_gauss(Xpatch, Ypatch) = cplot_wrapped(Xpatch, Ypatch);        
    end
end
means(:,1) = temp(:,1);
means(:,2) = temp(:,2);
means(:,3) = temp(:,3);
raw=means;
mean_graph = zeros(length(x_interp), length(y_interp));
for Xpatch=1:size(mean_graph,1)
    mean_graph(:,Xpatch)=means((Xpatch-1)*size(mean_graph,2)+1:Xpatch*size(mean_graph,2),3);
end
mean_graph2 = flipud(mean_graph);
figure(7);clf;subplot(2,2,1);contourf(x_interp, y_interp, mean_graph2);colorbar
clear x; x=[2:1:size(cplot_wrapped,1)-1];
set(gca, 'XTick', x);
ticks = [-0.5*(numXpatches-1):1:0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'XTickLabel', ticks);
clear y;y=[2:1:size(cplot_wrapped,1)-1];
set(gca,'YTick',y)
ticks = [0.5*(numXpatches-1):-1:-0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'YTickLabel', ticks);
clear y_lim y_range;
y_lim = ylim;
y_range = y_lim(2)-y_lim(1);
xlabel('X Direction');ylabel('Y Direction');Title=['Time= -',num2str(maxDelay),'ms'];title(Title);
text(0.1, y_lim(2)+.15*y_range, [PATH, FILE]); 

%%%%%%%%%%%%%%
%2D_Gaussion Fit
pars = gauss2Dfit(means,raw);
unique_x_pos = 1:numXpatches+2;
unique_y_pos = 1:numYpatches+2;
x_interp_new = unique_x_pos(1): 0.2 : unique_x_pos(length(unique_x_pos));
y_interp_new = unique_y_pos(1): 0.2 : unique_y_pos(length(unique_y_pos));
z_gauss = zeros(length(x_interp), length(y_interp));

for Xpatch=1:length(x_interp)
    for Ypatch = 1:length(y_interp)        
        z_gauss(Xpatch,Ypatch) =  gauss2Dfunc(x_interp(Xpatch),y_interp(Ypatch), pars);
    end
end

for Xpatch=1:length(x_interp_new)
    for Ypatch = 1:length(y_interp_new)
        z_gauss_new(Xpatch,Ypatch) =  gauss2Dfunc(x_interp_new(Xpatch),y_interp_new(Ypatch), pars);
    end
end
[r,p2] = corrcoef(cplot_wrapped,z_gauss);
R_Value=r(1,2)
P_Value=p2(1,2);clear r p2;
z_gauss = rot90(z_gauss);
z_gauss_new=rot90(z_gauss_new);
%figure(5);clf;contourf(x_interp, y_interp, z_gauss);colorbar
figure(7);subplot(2,2,2);contourf(x_interp,y_interp,z_gauss);colorbar;

clear x; x=[2:1:size(cplot_wrapped,1)-1];
set(gca, 'XTick', x);
ticks = [-0.5*(numXpatches-1):1:0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'XTickLabel', ticks);
clear y;y=[2:1:size(cplot_wrapped,1)-1];
set(gca,'YTick',y)
ticks = [0.5*(numXpatches-1):-1:-0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'YTickLabel', ticks);
clear y_lim y_range;
y_lim = ylim;
y_range = y_lim(2)-y_lim(1);
xlabel('X Direction');ylabel('Y Direction');title('2D Gaussian Fitted RF');
figure(7);subplot(2,2,3);contourf(x_interp_new,y_interp_new,z_gauss_new);colorbar

rf_xctr=data.one_time_params(RF_XCTR);
rf_yctr=data.one_time_params(RF_YCTR);

y_lim = ylim;
string=sprintf('Base Rate =%1.3f', pars(1));
text(-1.0,y_lim(2)/2+2.5+.25,string,'FontSize',8);
string=sprintf('Amplitude =%1.3f', pars(2));
text(-1.0,y_lim(2)/2+1.5+.25,string,'FontSize',8);

string=sprintf('FWHM_X =%1.3f', pars(4)*90/numXpatches*2.35);%(FWHM (full width half maximum) by the equation: sigma=FWHM/(2*SQRT(ALOG(2))), this is typically written as: sigma=FWHM/2.35; Peter Neri. Spatial Integration of Optic flow signals in fly motion-sensitive neurons. Ypatch.Neurophysiol. 95:1608-1619,2006)
text(-1.0,y_lim(2)/2+0.5+.25,string,'FontSize',8);
string=sprintf('FWHM_Y =%1.3f', pars(6)*90/numXpatches*2.35);
text(-1.0,y_lim(2)/2-0.5+.25,string,'FontSize',8);
string=sprintf('Fitted CTR =(%1.3f,%1.3f)',(pars(3)-1.5-numXpatches/2)*90/numXpatches,(pars(5)-1.5-numXpatches/2)*90/numXpatches);
text(-1.0,y_lim(2)/2-1.5+.25,string,'FontSize',8);
% string=sprintf('RFPLOT CTR =(%1.3f,%1.3f)', rf_xctr, rf_yctr);
% text(-1.0,y_lim(2)/2-2.5+.25,string,'FontSize',8);
clear x; x=[2:1:size(cplot_wrapped,1)-1];
set(gca, 'XTick', x);
ticks = [-0.5*(numXpatches-1):1:0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'XTickLabel', ticks);
clear y;y=[2:1:size(cplot_wrapped,1)-1];
set(gca,'YTick',y)
ticks = [0.5*(numXpatches-1):-1:-0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'YTickLabel', ticks);

clear y_lim y_range;
y_lim = ylim;
y_range = y_lim(2)-y_lim(1);
xlabel('X Direction');ylabel('Y Direction');title('RF with interpolation'); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_name = 'cplot'; % name of the  mat file with all the Original CrossCorrelation Histrogram 
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= cplot_wrapped;'])
if SpikeChan==1
    Directory=['save Z:\Users\Aihua\Cluster_Analysis\ReverseCorrelation\SU']
else
    Directory=['save Z:\Users\Aihua\Cluster_Analysis\ReverseCorrelation\MU']
end
save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'z_gauss'; % name of the  mat file with all the Original CrossCorrelation Histrogram 
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= z_gauss;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'z_gauss_interp'; % name of the  mat file with all the Original CrossCorrelation Histrogram 
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= z_gauss_new;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'CirVar'; % name of the mat of circular variance from the noise (Reverse Correlaiton_forward)
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= CV_f;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'CirVar_Max'; % name of the mat of circular variance from the noise (Reverse Correlaiton_forward)
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= CV_Max;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'CV_p'; % tuning index
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= CVp;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'VectAmp'; % name of the mat of circular variance from the noise (Reverse Correlaiton_forward)
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= Amp_Max;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'r_Max'; % name of the mat of circular variance from the noise (Reverse Correlaiton_forward)
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= r_Max;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'r_f'; % name of the mat of circular variance from the noise (Reverse Correlaiton_forward)
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= r_f;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

save_name = 'r_p'; % tuning index
dum_name = FILE(1:end-4);
spacer = ' ';
eval([dum_name '= rp;'])
clear save_file;save_file=[Directory(6:end) save_name];
if (exist([save_file '.mat'], 'file') == 0)    %file does not yet exist  
    eval([Directory save_name spacer dum_name]);
else
    eval([Directory save_name spacer dum_name ' -APPEND']);   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Extracting the optic flow
[X,Y]=meshgrid(1:.2:numXpatches+2);
for k=1:size(NewX,2)
    temp=NewX{k}';
    GaussFit(k,:)=temp;
end

Direction=GaussFit(:,2)*180/pi;
%Direction=GaussFit(:,2);
DirectionArray=zeros(numXpatches+2,numYpatches+2);
for Xpatch=1:numXpatches
    for Ypatch=1:numYpatches
        DirectionArray(Xpatch+1,Ypatch+1)=Direction(Ypatch+(Xpatch-1)*numXpatches);
    end
end
Direction_Interp=interp2(DirectionArray,X,Y,'spline');%Right or not?
%Direction_Interp=interp2(DirectionArray,X,Y,'nearest');
%Direction_Interp=interp2(DirectionArray,X,Y,'cubic');
XX=z_gauss_new.*cos(Direction_Interp*pi/180);
YY=z_gauss_new.*sin(Direction_Interp*pi/180);

%[XX,YY] = pol2cart(z_gauss,Direction_Interp.*pi/180);
figure(7);subplot(2,2,4);contour(X,Y,z_gauss_new);
hold on;
quiver(X,Y,XX,YY);
%colormap hsv
grid off;
hold off;
colorbar

clear x; x=[2:1:size(cplot_wrapped,1)-1];
set(gca, 'XTick', x);
ticks = [-0.5*(numXpatches-1):1:0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'XTickLabel', ticks);
clear y;y=[2:1:size(cplot_wrapped,1)-1];
set(gca,'YTick',y)
ticks = [0.5*(numXpatches-1):-1:-0.5*(numXpatches-1)]*90/numXpatches;
set(gca,'YTickLabel', ticks);

y_lim = ylim;
y_range = y_lim(2)-y_lim(1);
xlabel('X Direction');ylabel('Y Direction');title('Optic Flow');
%text(0.1, y_lim(2)+.075*y_range, [PATH, FILE]); 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Directory ='Z:\Users\Aihua\Cluster_Analysis\ReverseCorrelation\figure';
% FileName1=[Directory,'\',FILE(1:end-4),'_01_Direction_RF.fig'];figure(2); saveas(gcf,FileName1,'fig');
% FileName2=[Directory,'\',FILE(1:end-4),'_02_Direction_RF_forward.fig'];figure(3); saveas(gcf,FileName2,'fig');
% FileName3=[Directory,'\',FILE(1:end-4),'_03_Wrapped Gaussian Fitting.fig'];figure(4); saveas(gcf,FileName3,'fig');
% FileName4=[Directory,'\',FILE(1:end-4),'_04_CirVar.fig'];figure(5); saveas(gcf,FileName4,'fig');
% FileName5=[Directory,'\',FILE(1:end-4),'_05_Spatial_RF.fig'];figure(6); saveas(gcf,FileName5,'fig');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%---------------------------------------------------------------------------------------
%Also, write out some summary data to a cumulative summary file
sprint_txt=['%s\t %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %6.3f\t   %6.3f\t    %6.3f\t   %6.3f\t'];
if SpikeChan==1
    FILEName=[FILE '_SU'];
else
    FILEName=[FILE '_MU'];
end
buff=sprintf(sprint_txt, FILEName, pars(1), pars(2), pars(4)*90/numXpatches*2.35, pars(6)*90/numYpatches*2.35, (pars(3)-1.5-numXpatches/2)*90/numXpatches,(pars(5)-1.5-numYpatches/2)*90/numYpatches, rf_xctr, rf_yctr, R_Value, P_Value, numXpatches, numYpatches);
% buff = sprintf('%s\t %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t   %1.3f\t', ...
%      FILE, pars(1), pars(2), pars(3), pars(6), pars(3)-1, pars(5)-1, rf_xctr, rf_yctr );
%outfile =['C:\Documents and Settings\Aihua\Desktop\Data analysis\Reverse Correlation\ReverseCorr.dat'];
outfile =['Z:\Users\Aihua\Cluster_Analysis\ReverseCorrelation\ReverseCorr.dat'];
printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)
    fprintf(fid, 'FILE\t         Base Rate\t Amplitude\t XWidth\t YWidth\t Fitted_CTRx\t Fitted_CTRy\t RF_XCTR\t RF_YCTR\t R_Value\t P_Value\t numXpatches\t numYpatches\t');
    fprintf(fid, '\r\n');
end
fprintf(fid, '%s', buff);
fprintf(fid, '\r\n');
fclose(fid);
%---------------------------------------------------------------------------------------

return;