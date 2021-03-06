% analyze eyetrace data
clear all
% choose protocol
%
% analyze_protocol = 'rotation_ves';%Que
analyze_protocol = 'rotation_vis';%Azrael
% analyze_protocol = 'translat_ves';%Zebulon
% analyze_protocol = 'translat_vis';


if analyze_protocol == 'rotation_ves'
    aa1 = dlmread('Eye_rot_Que_ves.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('Eye_rot_Que_vis.dat','',1,1);dim=size(aa2)  % load data
    aa3 = dlmread('Eye_tra_Que_ves.dat','',1,1);dim=size(aa3)  % load data
    aa4 = dlmread('Eye_tra_Que_vis.dat','',1,1);dim=size(aa4)  % load data
%     [names] = textread('Eye_rot_ves.dat','%s',2)
%     filename=names(2);
%     title1 = 'Rot Ves yaw Left';%title1 = 'Rot Ves Up';% Difference trans and rot.
%     title2 = 'Rot Ves yaw Right';%title2 = 'Rot Ves Down';
%     title3 = 'Rot Ves pitch Down';%title3 = 'Rot Ves Left';
%     title4 = 'Rot Ves pitch Up';%title4 = 'Rot Ves Right';
elseif analyze_protocol == 'rotation_vis'
    aa1 = dlmread('Eye_rot_Azrael_ves.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('Eye_rot_Azrael_vis.dat','',1,1);dim=size(aa2)  % load data
    aa3 = dlmread('Eye_tra_Azrael_ves.dat','',1,1);dim=size(aa3)  % load data
    aa4 = dlmread('Eye_tra_Azrael_vis.dat','',1,1);dim=size(aa4)  % load data
% %     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
%     title1 = 'Rot Vis yaw Left';%title1 = 'Rot Ves Up';
%     title2 = 'Rot Vis yaw Right';%title2 = 'Rot Ves Down';
%     title3 = 'Rot Vis pitch Down';%title3 = 'Rot Ves Left';
%     title4 = 'Rot Vis pitch Up';%title4 = 'Rot Ves Right';
elseif analyze_protocol == 'translat_ves'
    aa3 = dlmread('Eye_tra_Zebulon_ves.dat','',1,1);dim=size(aa3)  % load data
    aa4 = dlmread('Eye_tra_Zebulon_vis.dat','',1,1);dim=size(aa4)  % load data
    aa1 = dlmread('Eye_rot_Zebulon_ves.dat','',1,1);dim=size(aa1)  % load data
    aa2 = dlmread('Eye_rot_Zebulon_vis.dat','',1,1);dim=size(aa2)  % load data
%     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
%     title1 = 'tran ves up';
%     title2 = 'tran ves down';
%     title3 = 'tran ves left';
%     title4 = 'tran ves right';
else
    aa = dlmread('Eye_tra_vis.dat','',1,1);  % load data 
%     aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data
    title1 = 'tran vis up';
    title2 = 'tran vis down';
    title3 = 'tran vis left';
    title4 = 'tran vis right';
end


% % 1 Rotation vestibular
% aa = dlmread('Eye_rot_ves.dat','',1,1);  % load data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mean for repeats cells...%Azuel no need
% aa3=aa3(:,1:22402);%Que and Zebulon
% aa4=aa4(:,1:22402);%Que and Zebulon
% aa3=aa3(:,1:19202);%Azrael do not need because all are 192002
aa=[aa1;aa2;aa3;aa4];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

repeat = aa(:,1); % 1st column is repeatition, else are the raw eye trace
dim = size(aa)

% definition for sum all cells (>300), {i}
        res_x_up_sum(1,1:400) = 0;
        res_y_up_sum(1,1:400) = 0;
        res_x_down_sum(1,1:400) = 0;
        res_y_down_sum(1,1:400)  = 0;
        res_x_left_sum(1,1:400)  = 0;
        res_y_left_sum(1,1:400)  = 0;
        res_x_right_sum(1,1:400)  = 0;
        res_y_right_sum(1,1:400)  = 0;
        
        vel_x_up_sum(1,1:399) = 0;
%         vel_x_up_sum2(1,1:400) = 0;
        vel_y_up_sum(1,1:399) = 0;
        vel_x_down_sum(1,1:399) = 0;
        vel_y_down_sum(1,1:399) = 0;
        vel_x_left_sum(1,1:399) = 0;
        vel_y_left_sum(1,1:399) = 0;
        vel_x_right_sum(1,1:399) = 0;
        vel_y_right_sum(1,1:399) = 0;
        
% reconstruct into matrixs
% 2 files on 1 figure

for i = 1 : dim(1)
    
    for j = 1 : repeat(i)
        res_x_up{i}(j,:) = aa(i, 1+1+400*(j-1):400+1+400*(j-1));
        res_y_up{i}(j,:) = aa(i, 1+1+400*(j-1)+400*repeat:400+1+400*(j-1)+400*repeat);
        res_x_down{i}(j,:) = aa(i, 1+1+400*(j-1)+800*repeat:400+1+400*(j-1)+800*repeat);
        res_y_down{i}(j,:) = aa(i, 1+1+400*(j-1)+1200*repeat:400+1+400*(j-1)+1200*repeat);
        res_x_left{i}(j,:) = aa(i, 1+1+400*(j-1)+1600*repeat:400+1+400*(j-1)+1600*repeat);
        res_y_left{i}(j,:) = aa(i, 1+1+400*(j-1)+2000*repeat:400+1+400*(j-1)+2000*repeat);
        res_x_right{i}(j,:) = aa(i, 1+1+400*(j-1)+2400*repeat:400+1+400*(j-1)+2400*repeat);
        res_y_right{i}(j,:) = aa(i, 1+1+400*(j-1)+2800*repeat:400+1+400*(j-1)+2800*repeat);
        
        
        % Convert to velosity
        vel_x_up{i}(j,:) = diff(res_x_up{i}(j,:))*1000/5;
%         vel_x_up2{i}(j,:) = fderiv(res_x_up{i}(j,:),15,200);
        vel_y_up{i}(j,:) = diff(res_y_up{i}(j,:))*200;
        vel_x_down{i}(j,:) = diff(res_x_down{i}(j,:))*200;
        vel_y_down{i}(j,:) = diff(res_y_down{i}(j,:))*200;
        vel_x_left{i}(j,:) = diff(res_x_left{i}(j,:))*200;
        vel_y_left{i}(j,:) = diff(res_y_left{i}(j,:))*200;
        vel_x_right{i}(j,:) = diff(res_x_right{i}(j,:))*200;
        vel_y_right{i}(j,:) = diff(res_y_right{i}(j,:))*200;
    end
  

        res_x_up_mean{i}(1,:)= mean(res_x_up{i}(:,:));
        res_y_up_mean{i}(1,:)= mean(res_y_up{i}(:,:));
        res_x_down_mean{i}(1,:) = mean(res_x_down{i}(:,:));
        res_y_down_mean{i}(1,:) = mean(res_y_down{i}(:,:));
        res_x_left_mean{i}(1,:) = mean(res_x_left{i}(:,:));
        res_y_left_mean{i}(1,:)= mean(res_y_left{i}(:,:));
        res_x_right_mean{i}(1,:) = mean(res_x_right{i}(:,:));
        res_y_right_mean{i}(1,:)  = mean(res_y_right{i}(:,:));
        
        vel_x_up_mean{i}(1,:) = mean(vel_x_up{i}(:,:));
%         vel_x_up_mean2{i}(1,:) = mean(vel_x_up2{i}(:,:));
        vel_y_up_mean{i}(1,:) = mean(vel_y_up{i}(:,:));
        vel_x_down_mean{i}(1,:) = mean(vel_x_down{i}(:,:));
        vel_y_down_mean{i}(1,:) = mean(vel_y_down{i}(:,:));
        vel_x_left_mean{i}(1,:) = mean(vel_x_left{i}(:,:));
        vel_y_left_mean{i}(1,:) = mean(vel_y_left{i}(:,:));
        vel_x_right_mean{i}(1,:) = mean(vel_x_right{i}(:,:));
        vel_y_right_mean{i}(1,:) = mean(vel_y_right{i}(:,:));
      

        res_x_up_sum = res_x_up_mean{i}(1,:)+res_x_up_sum;
        res_y_up_sum =  res_y_up_mean{i}(1,:)+res_y_up_sum;
        res_x_down_sum = res_x_down_mean{i}(1,:)+res_x_down_sum;
        res_y_down_sum = res_y_down_mean{i}(1,:)+res_y_down_sum ;
        res_x_left_sum = res_x_left_mean{i}(1,:)+res_x_left_sum ;
        res_y_left_sum = res_y_left_mean{i}(1,:)+res_y_left_sum;
        res_x_right_sum = res_x_right_mean{i}(1,:)+res_x_right_sum ;
        res_y_right_sum =  res_y_right_mean{i}(1,:)+res_y_right_sum;
        
        vel_x_up_sum = vel_x_up_mean{i}(1,:)+vel_x_up_sum;
%         vel_x_up_sum2 = vel_x_up_mean2{i}(1,:)+vel_x_up_sum2;
        vel_y_up_sum = vel_y_up_mean{i}(1,:)+vel_y_up_sum;
        vel_x_down_sum = vel_x_down_mean{i}(1,:)+vel_x_down_sum;
        vel_y_down_sum = vel_y_down_mean{i}(1,:)+vel_y_down_sum;
        vel_x_left_sum = vel_x_left_mean{i}(1,:)+vel_x_left_sum;
        vel_y_left_sum = vel_y_left_mean{i}(1,:)+vel_y_left_sum;
        vel_x_right_sum = vel_x_right_mean{i}(1,:)+vel_x_right_sum;
        vel_y_right_sum = vel_y_right_mean{i}(1,:)+vel_y_right_sum;
end         
        res_x_up_cellmean = res_x_up_sum/dim(1);
        res_y_up_cellmean =  res_y_up_sum/dim(1);
        res_x_down_cellmean = res_x_down_sum/dim(1);
        res_y_down_cellmean = res_y_down_sum/dim(1) ;
        res_x_left_cellmean = res_x_left_sum/dim(1) ;
        res_y_left_cellmean = res_y_left_sum/dim(1);
        res_x_right_cellmean = res_x_right_sum/dim(1) ;
        res_y_right_cellmean =  res_y_right_sum/dim(1);
        
        vel_x_up_cellmean = vel_x_up_sum/dim(1);
%         vel_x_up_cellmean2 = vel_x_up_sum2/dim(1);
        vel_y_up_cellmean = vel_y_up_sum/dim(1);
        vel_x_down_cellmean = vel_x_down_sum/dim(1);
        vel_y_down_cellmean = vel_y_down_sum/dim(1);
        vel_x_left_cellmean = vel_x_left_sum/dim(1);
        vel_y_left_cellmean = vel_y_left_sum/dim(1);
        vel_x_right_cellmean = vel_x_right_sum/dim(1);
        vel_y_right_cellmean = vel_y_right_sum/dim(1);
        
        


% Furthermore, mean and get each direction's eye movement depth (use only
% midline 1sec)>>>>>1-400 coloum ;i=1 (0-2sec) 
%===>> take 100-300 (0.5-1.5sec);i=2
% for i=1:2
%   m_res_x_up(i) = mean(res_x_up_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_up(i) = mean(res_y_up_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_down(i) = mean(res_x_down_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_down(i) = mean(res_y_down_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_left(i) = mean(res_x_left_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_left(i) = mean(res_y_left_cellmean(201-(100*i):199+(100*i)));
%   m_res_x_right(i) = mean(res_x_right_cellmean(201-(100*i):199+(100*i)));
%   m_res_y_right(i) = mean(res_y_right_cellmean(201-(100*i):199+(100*i)));
%   
%   m_vel_x_up(i) = mean(vel_x_up_cellmean(201-(100*i):199+(100*i)));
% %   mean(vel_x_up_cellmean2(100:300))
%   m_vel_y_up(i) = mean(vel_y_up_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_down(i) = mean(vel_x_down_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_down(i) = mean(vel_y_down_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_left(i) = mean(vel_x_left_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_left(i) = mean(vel_y_left_cellmean(201-(100*i):199+(100*i)));
%   m_vel_x_right(i) = mean(vel_x_right_cellmean(201-(100*i):199+(100*i)));
%   m_vel_y_right(i) = mean(vel_y_right_cellmean(201-(100*i):199+(100*i)));
% end

for i=1:2
    if i==1
  mix_position_101_299 = [res_x_up_cellmean(201-(100*i):199+(100*i));...
  res_y_up_cellmean(201-(100*i):199+(100*i));...
  res_x_down_cellmean(201-(100*i):199+(100*i));...
  res_y_down_cellmean(201-(100*i):199+(100*i));...
  res_x_left_cellmean(201-(100*i):199+(100*i));...
  res_y_left_cellmean(201-(100*i):199+(100*i));...
  res_x_right_cellmean(201-(100*i):199+(100*i));...
  res_y_right_cellmean(201-(100*i):199+(100*i))];
  
  mix_velocity_101_299 = [vel_x_up_cellmean(201-(100*i):199+(100*i));...
  vel_y_up_cellmean(201-(100*i):199+(100*i));...
  vel_x_down_cellmean(201-(100*i):199+(100*i));...
  vel_y_down_cellmean(201-(100*i):199+(100*i));...
  vel_x_left_cellmean(201-(100*i):199+(100*i));...
  vel_y_left_cellmean(201-(100*i):199+(100*i));...
  vel_x_right_cellmean(201-(100*i):199+(100*i));...
  vel_y_right_cellmean(201-(100*i):199+(100*i))];

    elseif i==2
   mix_position_1_399 = [res_x_up_cellmean(201-(100*i):199+(100*i));...
  res_y_up_cellmean(201-(100*i):199+(100*i));...
  res_x_down_cellmean(201-(100*i):199+(100*i));...
  res_y_down_cellmean(201-(100*i):199+(100*i));...
  res_x_left_cellmean(201-(100*i):199+(100*i));...
  res_y_left_cellmean(201-(100*i):199+(100*i));...
  res_x_right_cellmean(201-(100*i):199+(100*i));...
  res_y_right_cellmean(201-(100*i):199+(100*i))];
  
  mix_velocity_1_399 = [vel_x_up_cellmean(201-(100*i):199+(100*i));...
  vel_y_up_cellmean(201-(100*i):199+(100*i));...
  vel_x_down_cellmean(201-(100*i):199+(100*i));...
  vel_y_down_cellmean(201-(100*i):199+(100*i));...
  vel_x_left_cellmean(201-(100*i):199+(100*i));...
  vel_y_left_cellmean(201-(100*i):199+(100*i));...
  vel_x_right_cellmean(201-(100*i):199+(100*i));...
  vel_y_right_cellmean(201-(100*i):199+(100*i))];     
    end
    
end
% 
%%%%%%%        output files

    m_pos_101_299=mean(mean(mix_position_101_299));
    s_pos_101_299=std(std(mix_position_101_299));
    m_vel_101_299=mean(mean(mix_velocity_101_299));
    s_vel_101_299=std(std(mix_velocity_101_299));

    space=[0];
    
    summary_101_299=[m_pos_101_299 s_pos_101_299 space m_vel_101_299 s_vel_101_299]
    csvwrite('summary_101_299.dat',summary_101_299);
    
% 	csvwrite('m_pos_101_299.dat',m_pos_101_299);
%     csvwrite('m_vel_101_299.dat',m_vel_101_299);
%     csvwrite('s_pos_101_299.dat',s_pos_101_299);
%     csvwrite('s_vel_101_299.dat',s_vel_101_299);
    
    m_pos_1_399=mean(mean(mix_position_1_399));
    s_pos_1_399=std(std(mix_position_1_399));
    m_vel_1_399=mean(mean(mix_velocity_1_399));
    s_vel_1_399=std(std(mix_velocity_1_399));
    
    summary_1_399=[m_pos_1_399 s_pos_1_399 space m_vel_1_399 s_vel_1_399]
    csvwrite('summary_1_399.dat',summary_1_399);

%       csvwrite('m_pos_1_399.dat',m_pos_1_399);
%       csvwrite('m_vel_1_399.dat',m_vel_1_399);
%       csvwrite('s_pos_1_399.dat',s_pos_1_399);
%       csvwrite('s_vel_1_399.dat',s_vel_1_399);



       


%%%%%%%%%%%%%%%%plot data%%%%%%%%%%%%%%%%%%%%%%
  title1 = 'axis up';
    title2 = 'axis down';
    title3 = 'axis left';
    title4 = 'axis right';
    
figure(2)

subplot(4,1,1)
plot(res_x_up_cellmean,'r.');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.5, 0.5]);
    ylabel('(deg)');
    title(['Eye Position /  ',title1]);

    plot(res_y_up_cellmean,'b.');
    hold off;


subplot(4,1,2)
plot(res_x_down_cellmean,'r.');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.5, 0.5]);
    ylabel('(deg)');
    title(['Eye Position /  ',title2]);

    plot(res_y_down_cellmean,'b.');
    hold off;

subplot(4,1,3)
plot(res_x_left_cellmean,'r.');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.5, 0.5]);
    ylabel('(deg)');
    title(['Eye Position /  ',title3]);

    plot(res_y_left_cellmean,'b.');
    hold off;
    
subplot(4,1,4)
plot(res_x_right_cellmean,'r.');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-0.5, 0.5]);
    ylabel('(deg)');
    title(['Eye Position /  ',title4]);

    plot(res_y_right_cellmean,'b.');
    hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(3)

subplot(4,1,1)
plot(vel_x_up_cellmean,'r');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-3, 3]);
    ylabel('(deg/sec)');
    title(['Velocity /  ',title1]);

    plot(vel_y_up_cellmean,'b');
    hold off;


subplot(4,1,2)
plot(vel_x_down_cellmean,'r');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-3, 3]);
    ylabel('(deg/sec)');
    title(['Velocity /  ',title2]);

    plot(vel_y_down_cellmean,'b');
    hold off;

subplot(4,1,3)
plot(vel_x_left_cellmean,'r');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-3, 3]);
    ylabel('(deg/sec)');
    title(['Velocity /  ',title3]);

    plot(vel_y_left_cellmean,'b');
    hold off;
    
subplot(4,1,4)
plot(vel_x_right_cellmean,'r');
    hold on;
    xlim( [1, 400] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,100,200,300,400]);
    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
    ylim([-3, 3]);
    ylabel('(deg/sec)');
    title(['Velocity /  ',title4]);

    plot(vel_y_right_cellmean,'b');
    hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output to text file


% for i=1:2	
% m_res_all=[m_res_x_up(i), m_res_y_up(i), m_res_x_down(i), m_res_y_down(i), m_res_x_left(i), m_res_y_left(i), m_res_x_right(i), m_res_y_right(i)];
% m_vel_all=[m_vel_x_up(i), m_vel_y_up(i), m_vel_x_down(i), m_vel_y_down(i), m_vel_x_left(i), m_vel_y_left(i), m_vel_x_right(i), m_vel_y_right(i)];
%   if i==1
% 	csvwrite('m_res_101_299.dat',m_res_all);
%     csvwrite('m_vel_101_299.dat',m_vel_all);
%   else
%       csvwrite('m_res_1_399.dat',m_res_all);
%       csvwrite('m_vel_1_399.dat',m_vel_all);
%   end
% 
% end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  all cell trace 2 cells in one paper, meaning 50 figures

% repeat = aa(:,1); % 1st column is repeatition, else are the raw eye trace
% dim = size(aa)
% % reconstruct into matrixs
% % 2 files on 1 figure
% 
% for i = 1 : dim(1)
%     
%     for j = 1 : repeat(i)
%         res_x_up{i}(j,:) = aa(i, 1+1+400*(j-1):400+1+400*(j-1));
%         res_y_up{i}(j,:) = aa(i, 1+1+400*(j-1)+400*repeat:400+1+400*(j-1)+400*repeat);
%         res_x_down{i}(j,:) = aa(i, 1+1+400*(j-1)+800*repeat:400+1+400*(j-1)+800*repeat);
%         res_y_down{i}(j,:) = aa(i, 1+1+400*(j-1)+1200*repeat:400+1+400*(j-1)+1200*repeat);
%         res_x_left{i}(j,:) = aa(i, 1+1+400*(j-1)+1600*repeat:400+1+400*(j-1)+1600*repeat);
%         res_y_left{i}(j,:) = aa(i, 1+1+400*(j-1)+2000*repeat:400+1+400*(j-1)+2000*repeat);
%         res_x_right{i}(j,:) = aa(i, 1+1+400*(j-1)+2400*repeat:400+1+400*(j-1)+2400*repeat);
%         res_y_right{i}(j,:) = aa(i, 1+1+400*(j-1)+2800*repeat:400+1+400*(j-1)+2800*repeat);
%     end
% end   
% 
% %%%%%%%%%%%%%%%%plot data%%%%%%%%%%%%%%%%%%%%%%
% 
% numfig=round(dim(1)/2);
% for m=1:numfig
% figure(m+1);
% % set(gca,'Position', [5,5 1000,680], 'Name', 'Envelope');    
% 
% i=m*2-1;
% 
%   subplot(4,2,1);
%     plot(res_x_up{i}(:,:)','r.');
%     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title1);
%     
%     plot(res_y_up{i}(:,:)','b.');
%     hold off;
% 
%     text (10,0.7,['Cell No.', num2str(i)]);
%     
%   subplot(4,2,3);
%     plot(res_x_down{i}(:,:)','r.');
%     hold on;    
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title2);
%       
%     plot(res_y_down{i}(:,:)','b.');
%     hold off;    
%  
%     
%     
%   subplot(4,2,5);
%     plot(res_x_left{i}(:,:)','r.');
%     hold on;   
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title3);
%     
%     plot(res_y_left{i}(:,:)','b.');
%     hold off;   
%   
%     
%     
%   subplot(4,2,7);
%     plot(res_x_right{i}(:,:)','r.');
%     hold on;  
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title4);
%     
%     plot(res_y_right{i}(:,:)','b.');
%     hold off;  
% 
% i=[];
% i=m*2;
% 
%   subplot(4,2,2);
%     plot(res_x_up{i}(:,:)','r.');
%     hold on;
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title1);
%     
%     plot(res_y_up{i}(:,:)','b.');
%     hold off;
% 
%      text (10,0.7,['Cell No.', num2str(i)]);
%     
%   subplot(4,2,4);
%     plot(res_x_down{i}(:,:)','r.');
%     hold on;    
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title2);
%       
%     plot(res_y_down{i}(:,:)','b.');
%     hold off;    
%  
%     
%     
%   subplot(4,2,6);
%     plot(res_x_left{i}(:,:)','r.');
%     hold on;   
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title3);
%     
%     plot(res_y_left{i}(:,:)','b.');
%     hold off;   
%   
%     
%     
%   subplot(4,2,8);
%     plot(res_x_right{i}(:,:)','r.');
%     hold on;  
%     xlim( [1, 400] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
%     ylim([-1,1]);
%     ylabel('(deg)');
%     title(title4);
%     
%     plot(res_y_right{i}(:,:)','b.');
%     hold off;   

% end