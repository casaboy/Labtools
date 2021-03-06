function  DirectionTuning2D_pursuit_PSTH(data, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE, Protocol);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%KT 02-02-2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TEMPO_Defs;
Path_Defs;
ProtocolDefs; 

%get the column of values for elevation, fp_rotate
temp_elevation = data.moog_params(ROT_ELEVATION,:,MOOG);
temp_fp_rotate = data.moog_params(FP_ROTATE,:,MOOG);
temp_spike_data = data.spike_data(SpikeChan,:);
temp_spike_rates = data.spike_rates(SpikeChan,:);   %Timebin: The duration of one trial 

sti_duration=length(temp_spike_data)/length(temp_spike_rates);
for i=1:length(temp_spike_rates)   
    spike_data(i,:)=temp_spike_data((i-1)*sti_duration+1:i*sti_duration);
end

real_trials=find(temp_elevation~=data.one_time_params(NULL_VALUE));
elevation=temp_elevation(real_trials)
%delete;
unique_elevation = munique(elevation');
fp_rotate = temp_fp_rotate(real_trials);
unique_fp_rotate = munique(fp_rotate');

h_title{1}='Head-fixed';
h_title{2}='World-fixed';
h_title{3}='Pursuit only';

% add parameters here
timebin=50;% timebin for plot PSTH
x_time=1:sti_duration/timebin;%x-axis for plot PSTH

%count spike data from raster data (spike _data)
for j=1:length(unique_fp_rotate)
    for i=1:length(unique_elevation)
        select=find(elevation==unique_elevation(i) & (fp_rotate==unique_fp_rotate(j)));
        trial_mean=mean(spike_data(select,:));   
        for n=1:length(x_time)
            temp_count(1,n)=sum(trial_mean(1,(n-1)*timebin+1: n*timebin));            
        end
        count_y{i,j}=temp_count; 
       count_y_max(i,j)=max(temp_count);
        clear temp_count
        if max(count_y{i,j})~=0;
            count_y_norm{i,j}=count_y{i,j} / max(count_y{i,j});
        else
            count_y_norm{i,j}=0;
        end
    end
end
max_count=max(max(count_y_max));


% plot PSTH now
% get the largest count_y so that make the scale in each figures equal    
% plot two lines as stimulus start and stop marker
x_start = [StartEventBin(1,1)/timebin, StartEventBin(1,1)/timebin];
x_stop = [StopEventBin(1,1)/timebin,  StopEventBin(1,1)/timebin];
y_marker=[0,max_count];
% define figure
figure(2);
set(2,'Position', [5,5 1000,700], 'Name', 'RVOR_pursuit');
orient landscape;
title(FILE);
axis off;

% now plot
% output some text 
axes('position',[0 0 1 0.9]); 
xlim([-50,50]);
ylim([-50,50]);
for i=1:length(unique_fp_rotate)   
    text(-48,65-22.5*i, h_title{i} );
end
%text(-47,-35, 'Azim:             270                  225                  180                  135                  90                  45                  0                  315                  270');
text(-47,-35, 'Azim:                0                    45                   90                  135                    180                    225                  270                  315                  0');
text(-10,-40, 'RVOR / pursuit'); 
axis off;
hold on;

for i=1:length(unique_elevation)+1      % aizmuth 0 are plotted two times in order to make circular data
    for j=1:length(unique_fp_rotate)
       axes('position',[0.01+0.09*i  (1.0-0.2*j)  0.085 0.085])
        if (i < 9 )                                 % temporarilly line output figure with contour one, so that the middle panel corresponds to 90 deg,                             
            bar( x_time,count_y{i,j}(1,:) );    % which is forward motion and the lateral edges correspond to 0 deg which is backward motion
        else
            bar( x_time,count_y{1,j}(1,:) ); 
        end
        hold on;
        plot( x_start, y_marker, 'r-');
        plot( x_stop,  y_marker, 'r-');
        set( gca, 'xticklabel', ' ' );        
        % set the same scale for all plot
       xlim([0,sti_duration/timebin]);
       ylim([0,max_count]);
    end    
end 

% for i=1:length(unique_elevation)+1      % aizmuth 270 are plotted two times in order to make circular data
%     for j=1:length(unique_fp_rotate)
%        axes('position',[0.01+0.09*i  (1.0-0.2*j)  0.085 0.085])
%         if (i < 8 )                                 % temporarilly line output figure with contour one, so that the middle panel corresponds to 90 deg,                             
%             bar( x_time,count_y{8-i,j}(1,:) );    % which is forward motion and the lateral edges correspond to 270 deg which is backward motion
%         elseif(i==8)
%             bar( x_time,count_y{i,j}(1,:) ); 
%         else
%             bar( x_time,count_y{7,j}(1,:) ); 
%         end
%         hold on;
%         plot( x_start, y_marker, 'r-');
%         plot( x_stop,  y_marker, 'r-');
%         set( gca, 'xticklabel', ' ' );        
%         % set the same scale for all plot
%        xlim([0,sti_duration/timebin]);
%        ylim([0,max_count]);
%     end    
% end 


% for i=1:length(unique_azimuth)+1  
%     for j=1:length(unique_TT_MODE)
%         if (i < 8 )              
%             figure(2);subplot(4,9, (i-1)*4+j), bar( x_time,count_y{8-i,j}(1,:) );  
%         elseif(i==8)
%             figure(2);subplot(4,9, (i-1)*4+j), bar( x_time,count_y{i,j}(1,:) ); 
%         else
%             figure(2);subplot(4,9, (i-1)*4+j), bar( x_time,count_y{7,j}(1,:) ); 
%         end
%         hold on;
%         plot( x_start, y_marker, 'r-');
%         plot( x_stop,  y_marker, 'r-');
%         set( gca, 'xticklabel', ' ' );       
%         % set the same scale for all plot
%        xlim([0,x_length]);
%        ylim([0,max_count]);
%     end    
% end 

return;

