% -------------------------------------------------------------------------
% This functions defines which epochs are bad based on the distance at each
% sample of epoch i to the ERP
%
% INPUT
% EEG   EEG structure
% limDist   threshold for the mean distance
% limBadDist    maximun proportion of time above the threshold
%
% OPTIONAL INPUTS
%   - keeppre       keep previuos values
%   - relative      relative (1) or absolute (0) threshold
%   - where         time limits where to look for bad data
%   - maxloops      maximun numbers of loops
%   - plot          plot the rejection
%   - savefigure    save the figure with the rejection
%   - filter        filter the data before omputing
%
% OUTPUTS
%   EEG     output data
%   BE     bad epochs, logical indexes
%
% -------------------------------------------------------------------------


function [ EEG, BE ] = eega_tDefBEdistFull( EEG, limDist, limBadTimeDist, limMeanDist, limMaxDist, varargin )

fprintf('### Identifying Bad Epochs Based on the Distance to the Mean ###\n' )

%% ------------------------------------------------------------------------
%% Parameters
P.keeppre       = 1;
P.relative      = 1;
P.maxloops      = 1;
P.plot          = 0;
P.savefigure    = 0;
P.where         = [];
P.rmvmean       = 0;
P.normdist      = 1;
P.hpfilter      = [];
P.lpfilter      = [];
P.distance      = 'euclidean';

[P, OK, extrainput] = eega_getoptions(P, varargin);
if ~OK
    error('eega_tDefBEdistT: Non recognized inputs')
end

%% ------------------------------------------------------------------------
%% Identify bad epochs based on the distance to the mean
nEl  = size(EEG.data,1);
nS   = size(EEG.data,2);
nEp  = size(EEG.data,3);

if nEp > 1
    if P.keeppre && isfield(EEG.artifacts,'BE')
        BEold = EEG.artifacts.BE;
    else
        BEold = false(1,1,nEp);
    end
    if ~isfield(EEG.artifacts,'BEm')
        EEG.artifacts.BEm = false(1,1,nEp);
    end
    
    % find the times to consider
    if isempty(P.where)
        P.where = [EEG.times(1) EEG.times(end)];
    end
    idxtime = EEG.times>=P.where(1) & EEG.times<=P.where(2);
    nS = sum(idxtime);
    
    % high pass filter if necessary
    if ~isempty(P.lpfilter) || ~isempty(P.hpfilter)
        EEGf = pop_eegfiltnew(EEG, P.hpfilter, P.lpfilter,[], 0, [], [], 0);
        data = EEGf.data;
        clear EEGf
    else
        data = EEG.data;
    end
    
    % reference data to calculate the distance
    data = bsxfun(@minus,data, nanmean(data,1));
    
    % obtain the mean epoch to calculate the distance from it
    dataM = data;
    dataM(EEG.artifacts.BCT)=nan;
    
    % do not consider bad electrodes in the rejection
    ElBadAll = all(EEG.artifacts.BC,3);
    data(ElBadAll,:,:) = [];
    dataM(ElBadAll,:,:) = [];
    
    % remove times
    data = data(:,idxtime,:);
    dataM = dataM(:,idxtime,:);
    
    % remove the mean
    if P.rmvmean
        dataM = dataM - mean(dataM,2);
    end
    
    %reject epochs having samples that are too far from the average
    BE = BEold(:) | EEG.artifacts.BEm(:);
    BEd = false(size(BE));
    ok=0;
    ci=1;
    while ~ok && ci<=P.maxloops
        
        M = nanmean(dataM(:,:,~BE),3);
        
        % scale the mean based on the standard deviations (otherwise the mean and the single trila data have differnt amplitudes)
        sdM = std(M,[],2);
        sdD = std(reshape(data,[size(data,1) size(data,2)*size(data,3)]),[],2);
        M = M .* sdD ./ sdM;
        % compute the distance
        if strcmp(P.distance,'euclidean')
            D = bsxfun(@minus,data,M);
            D = squeeze(sqrt(sum(D.^2,1)));
        else
            D = nan(size(data,2),size(data,3));
            for i=1:size(data,2)
                for j=1:size(data,3)
                    D(i,j) = pdist(cat(1,data(:,i,j)',M(:,i)'),P.distance);
                end
            end
        end
        
        % log transfomation to have a normal distribution
        if strcmp(P.distance,'euclidean')
            D = log(D);
        end
        
        % normalize the distance such that the variance and mean are equal across samples
        if P.normdist
            D = (D - mean(D(:,~BE),2)) ./  std(D(:,~BE),[],2);
        end
        
        % threshold for the distance
        if P.relative
            d = D(:,~BE);
            P75 = prctile(d(:),75);
            P25 = prctile(d(:),25);
            threshD = P75 + limDist .* (P75-P25);
        else
            threshD = limDist;
        end
        RR = D > repmat(threshD,[1 size(D,2)]);
        
        % threshold for the amount of data too far away
        if limBadTimeDist<=1
            Rt = (sum(RR,1)/nS)>limBadTimeDist;
        else
            P75 = prctile(sum(RR,1)/nS,75);
            P25 = prctile(sum(RR,1)/nS,25);
            threshR = P75 + limBadTimeDist .* (P75-P25);
            Rt = (sum(RR,1)/nS)>threshR;
        end
        Rt = Rt';
        
        % threshold for the mean distance
        if ~isempty(limMeanDist)
            if P.relative
                d = mean(D(:,~BE));
                P75 = prctile(d(:),75);
                P25 = prctile(d(:),25);
                threshMeanD = P75 + limMeanDist .* (P75-P25);
            else
                threshMeanD = limMeanDist;
            end
            Rmean = mean(D)' > threshMeanD;
        else
            Rmean = false(size(mean(D)'));
        end
        
        % threshold for the max distance
        if ~isempty(limMaxDist)
            if P.relative
                d = max(D(:,~BE));
                P75 = prctile(d(:),75);
                P25 = prctile(d(:),25);
                threshMaxD = P75 + limMaxDist .* (P75-P25);
            else
                threshMaxD = limMaxDist;
            end
            Rmax = max(D)' > threshMaxD;
        else
            Rmax = false(size(max(D)'));
        end
        
        % Rejection vector
        R = Rt | Rmean | Rmax;
        
        % check if new data was rejected
        if all( ( R | BE ) == BE)
            ok=1;
        end
        
        BEd = ( BEd | R );
        BE  = ( BE  | R );
        
        ci=ci+1;
    end
    TOT = [mean(D,1)' max(D,[],1)' sum(RR,1)'/nS];
    
    %% ------------------------------------------------------------------------
    %% Display rejected data
    BEnew=(BE(:) & ~BEold(:) & ~EEG.artifacts.BEm(:));
    
    fprintf('--> Rejected epochs by this algorithm: %03d out of %d : (%5.1f%% ) %s\n', sum(BEd), nEp, sum(BEd)/nEp*100, num2str(find(BEd(:)')) )
    fprintf('--> Total rejected epochs:             %03d out of %d (%5.1f%% ) %s\n', sum(BE), nEp, sum(BE)/nEp*100, num2str(find(BE(:)')) )
    fprintf('--> New rejected epochs:               %03d out of %d (%5.1f%% ) %s\n', sum(BEnew), nEp, sum(BEnew)/nEp*100, num2str(find(BEnew(:)')) )
    
    fprintf('\n')
    
    %% ------------------------------------------------------------------------
    %% Update the rejection matrix
    EEG.artifacts.BE = permute(BE,[3 2 1]);
    EEG.reject.rejmanual = permute(EEG.artifacts.BE,[1 3 2]);
    if exist('eega_summarypp','file')==2
        EEG = eega_summarypp(EEG);
    end
    
    %% ------------------------------------------------------------------------
    %% Plot
    if P.plot
        plottrialsrej(BE,BEd,BEold,D,TOT,P,EEG.filename,EEG.filepath)
    end
else
    fprintf('Not enouth good epochs\n')
end


end


%% ------------------------------------------------------------------------
function plottrialsrej(BE,BEd,BEold,D,TOT,P,filename,filepath)

AXxLim = [0 0.05 0.67 0.7 0.98 1];
AXyLim = [0 0.1 0.90 1];
axbox  = 0.050;
axboxm  = 0.020;

ppp ={'mean dist' 'max dist' '% of bad'};

col_good    = [0.1953    0.8008    0.1953];
col_new     = [1.0000    0.8398         0];
col_old     = [0.2539    0.4102    0.8789];
col_both    = [0.8594    0.0781    0.2344];

Egood   = ~BE(:);
Enew    = BEd & ~BEold(:);
Eold    = BEold(:) & ~BEd(:);
Eboth   = BEold(:) & BEd(:);

[~, trialssort] = sort(mean(D));
D = D(:,trialssort);
Egood = Egood(trialssort);
Enew = Enew(trialssort);
Eold = Eold(trialssort);
Eboth = Eboth(trialssort);

EEEE = [Egood Enew Eold Eboth];

hf=figure('Position',[100 100 1200 500]);

% trials bad data
% ---------------
axes('Units','normalized','Position', [AXxLim(2) AXyLim(2) AXxLim(3)-AXxLim(2) AXyLim(3)-AXyLim(2)])

p = prctile(D(:),[25 75]);
yl = [p(1)-3*diff(p) p(2)+3*diff(p)];
% yl = [3 6];
triaslorder=[];
L={};
C=[];
Nlim=0;
i=0;
if any(EEEE(:,1))
    i=i+1;
    triaslorder = cat(1,triaslorder,find(EEEE(:,1)));
    Nlim(i+1) = Nlim(i)+sum(EEEE(:,1));
    L{i} = 'good epoch';
    C(i,:)= col_good;
end
if any(EEEE(:,2))
    i=i+1;
    triaslorder = cat(1,triaslorder,find(EEEE(:,2)));
    Nlim(i+1) = Nlim(i)+sum(EEEE(:,2));
    L{i} = 'rejected new';
    C(i,:)= col_new;
end
if any(EEEE(:,3))
    i=i+1;
    triaslorder = cat(1,triaslorder,find(EEEE(:,3)));
    Nlim(i+1) = Nlim(i)+sum(EEEE(:,3));
    L{i} = 'rejected old';
    C(i,:)= col_old;
end
if any(EEEE(:,4))
    i=i+1;
    triaslorder = cat(1,triaslorder,find(EEEE(:,4)));
    Nlim(i+1) = Nlim(i)+sum(EEEE(:,4));
    L{i} = 'rejected both';
    C(i,:)= col_both;
end
Nlim=Nlim+0.5;

Dorder = D(:,triaslorder);
imagesc(Dorder')
colormap(jet)
caxis(yl)
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
xlabel('time')
ylabel('trial')
n=-round(size(Dorder,1)*0.02);
xlim([n size(Dorder,1)])
H=[];
for j=2:length(Nlim)
    v=[n Nlim(j); 0.5 Nlim(j); 0.5 Nlim(j-1); n Nlim(j-1)];
    h=patch(v(:,1),v(:,2),C(j-1,:),'EdgeColor','none');
    H{j-1}=h(1);
end
legend([H{:}]',L{:},'Location','southoutside','Orientation','horizontal')
title('Normalized distance to the average across epochs for each sample')
colorbar

% boxplots
% --------
X0=AXxLim(4);
for i=1:size(TOT,2)
    axes('Position', [X0 AXyLim(2) axbox AXyLim(3)-AXyLim(2)])
    hold on
    di=TOT(:,i);
    digood = di;
    digood(BE)=nan;
    boxplot([di digood],'Labels',{'all' 'good'},'PlotStyle','compact', 'Colors' ,[0 0 0])
    set(gca,'XTickLabelRotation',90)
    % set(gca,'YTickLabel',[])
    %     line(xlim, [thresh(i) thresh(i)],'color',[1 0 0])
    title(ppp{i})
    X0=X0+(axbox+axboxm);
end

if P.plot && P.savefigure
    [~,figurename,~]=fileparts(filename);
    figurename = ['rejBEdist_' figurename '.fig'];
    savefig(hf,fullfile(filepath,figurename))
end
end


