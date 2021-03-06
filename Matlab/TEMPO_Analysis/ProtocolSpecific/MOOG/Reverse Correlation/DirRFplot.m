function [g_spikeTracker,maxDelay]=DirRFplot(spikeHist,directions_array,numXpatches,numYpatches,spikeHistIndex,uniqueDirs, corrDelay,PATH,FILE,bootstp_num, FigureIndex)
maxCount=0;
minCount=999;
Variance0=0;

figure(FigureIndex);clf;
orient landscape;%orient portrait; 
for (Xpatch = 1:numXpatches)
    for (Ypatch = 1:numYpatches)
        %cplot=zeros(spikeHistIndex+2,length(uniqueDirs)+2); 
        cplot=zeros(spikeHistIndex+2,length(uniqueDirs)+1); 
        clear temp_direction_array;temp_direction_array=[directions_array{Xpatch,Ypatch}];
        
%         %********%Determine total number of directions per patch        
%         for (k = 1:length(uniqueDirs))
%             clear select;select=logical(temp_direction_array==uniqueDirs(k));
%             g_dirCounter(Xpatch,Ypatch,uniqueDirs(k)+1)=length(temp_direction_array(select));
%         end
        
        for (z = 1:spikeHistIndex)
            %Pull out a spike histogram from the list            
            clear spikeHistArray; spikeHistArray = [spikeHist{z}];                                                                     
            for (k = 1:length(uniqueDirs))               
                clear select;select = logical((temp_direction_array==uniqueDirs(k)));              
                if sum(sum(select))>0
                    spikeHist_select=spikeHistArray(select); 
                    %do the bootstrap if possible
                    if bootstp_num>1                        
                        for b=1:bootstp_num
                            spikeHist_select=spikeHist_select(randperm(length(spikeHist_select)));
                            spikeHist_bootstrap(b)=spikeHist_select(1);
                        end
                        g_spikeTracker(Xpatch,Ypatch,z,uniqueDirs(k)+1)=mean(spikeHist_bootstrap);
                    else
                        g_spikeTracker(Xpatch,Ypatch,z,uniqueDirs(k)+1)=mean(spikeHist_select);
                    end
                    
                else
                    g_spikeTracker(Xpatch,Ypatch,z,uniqueDirs(k)+1)=0;
                end                
            end
            normalizedHist=squeeze(g_spikeTracker(Xpatch,Ypatch,z,uniqueDirs+1))';
            cplot(z+1,:)=[normalizedHist,normalizedHist(1)];
            %cplot(z+1,:)=[0,normalizedHist,0];
            [tmpMax,DirectionIndex]=max(normalizedHist);
            [tmpMin,DirectionIndexMin]=min(normalizedHist);
            Variance=var(normalizedHist);
            if(tmpMax>maxCount)
                maxCount=tmpMax;
            end
            if(tmpMin<minCount)
                minCount=tmpMin;
            end
            if(Variance>Variance0)
                Variance0=Variance;
                maxX=Xpatch;
                maxY=Ypatch;
                maxDelay=corrDelay(z);
                maxDirection=uniqueDirs(DirectionIndex);
            end
        end
        %figure(FigureIndex);subplot(numXpatches,numYpatches, Xpatch+(Ypatch-1)*numXpatches);contourf(cplot);
        cplot_simple=cplot([1:5:spikeHistIndex],:);
        figure(FigureIndex);subplot(numXpatches,numYpatches, Xpatch+(Ypatch-1)*numXpatches);contourf(cplot_simple);
    end
end
uniqueDirs=[uniqueDirs 360];
for (Xpatch = 1:(numXpatches*numYpatches))
    figure(FigureIndex);subplot(numXpatches, numYpatches, Xpatch);caxis([minCount, maxCount]); 
    y=0:floor(0.25*size(cplot_simple,1)):size(cplot_simple,1);%y=[2:0.1*(spikeHistIndex-1):spikeHistIndex+2];%y=[2:20:size(cplot, 1)];%y = [2:2:size(cplot, 1)];
    set(gca, 'YTick', y);    
    ticks=0:50:max(corrDelay);%ticks=0:20:max(corrDelay);%ticks = corrDelay(1:2:length(corrDelay));
    set(gca,'YTickLabel', ticks);
    set(gca, 'TickDir', 'out');
    
    x = mean(diff(uniqueDirs));
    set(gca, 'XTick', [1:2:length(uniqueDirs)+1]);
    set(gca, 'XTickLabel', uniqueDirs([1:2:length(uniqueDirs)]));
%     set(gca, 'XTick', [1:1:length(uniqueDirs)+1]);
%     set(gca, 'XTickLabel', uniqueDirs([1:1:length(uniqueDirs)]));
    %hold on;line([min(XLim) max(XLim)],[maxDelay/max(corrDelay)*size(cplot,1) maxDelay/max(corrDelay)*size(cplot,1)],'LineWidth',2.0,'Color','k');
    hold on;line([min(XLim) max(XLim)],[maxDelay/max(corrDelay)*size(cplot_simple,1) maxDelay/max(corrDelay)*size(cplot_simple,1)],'LineWidth',2.0,'Color','k');
    if (Xpatch == numXpatches*numYpatches)
        colorbar;
    elseif (Xpatch == 1)
        % Puts a label that says the filename above all the subplots.
%         text(0, 1.2*max(corrDelay), [PATH, FILE]); 
        text(0, 1.2*size(cplot_simple,1), [PATH, FILE]);
    end    
end