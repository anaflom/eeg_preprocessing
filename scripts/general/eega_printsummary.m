function [T] = eega_printsummary(filenames, pathIn, patternname, patternn, silent)
if nargin<5
    silent=1;
end
if nargin<4
    patternn=[];
end
if nargin<3
    patternname=[];
end


%% List of files
ssList = dir(fullfile(pathIn,filenames));
rem = false(length(ssList),1);
for tf = 1:length(ssList)
    if ssList(tf).name(1)=='.';
        rem(tf) = 1;
    end
end
ssList(rem) = [];
subjects = 1:length(ssList);
nsbj = length(subjects);

%% Do it for all the files
if ~isempty(subjects)
    
    SBJ = cell(nsbj,1);
    
    summaryIDX = nan(3,1);
    what = cell(3,1);
    
    Nch = nan(nsbj,length(summaryIDX));
    Nspl = nan(nsbj,length(summaryIDX));
    Nep = nan(nsbj,length(summaryIDX));
    BCT = nan(nsbj,length(summaryIDX));
    CCT = nan(nsbj,length(summaryIDX));
    BT = nan(nsbj,length(summaryIDX));
    BC = nan(nsbj,length(summaryIDX));
    
    for s = 1:nsbj
        
        % -----------------------------------------------------------------
        % Load the data
        [~,nameSubj,Ext] = fileparts(ssList(subjects(s)).name);
        fprintf('\n%s\nSubject %s\n',repmat('-',[1 50]),nameSubj)
        clear EEG
        if strcmp(Ext,'.set')
            EEG = pop_loadset( ssList(s).name, pathIn );
        elseif strcmp(Ext,'.mat')
            EEG = load(fullfile(pathIn,  ssList(s).name));
            feeg = fieldnames(EEG);
            EEG = EEG.(feeg{1});
        end
        
        % -----------------------------------------------------------------
        % Find the info for the different stages during pre-processing
        
        % Last stage before epoching
        idx = find(EEG.summaryhistory.nep==1);
        if ~isempty(idx)
            summaryIDX(1) = idx(end);
            what{1} = 'continuos data';
        end
        
        % Before rejecting bad epochs
        idx = find(diff(EEG.summaryhistory.nep)<0);
        if ~isempty(idx)
            summaryIDX(2) = idx(end);
            what{2} = 'epoch data';
        end
        
        % Finale stage
%         idx = find(diff(EEG.summaryhistory.nep)<0);
        idx  = length(EEG.summaryhistory.nep);
        if ~isempty(idx)
            summaryIDX(3) = idx(1);
            what{3} = 'epoch data without bad epochs';
        end
        
        % -----------------------------------------------------------------
        % Take the important info
        
        if isempty(patternname)
            SBJ{s} = EEG.filename;
        else
            k = strfind(EEG.filename,patternname);
            if ~isempty(patternn)
                SBJ{s} = EEG.filename(k:k+patternn-1);
            else
                SBJ{s} = EEG.filename(k:end);
            end
        end
        
        if length(summaryIDX)==1 && summaryIDX==0 && isfield(EEG,'summary')
            Nch(s) = EEG.summary.nch;
            Nspl(s) = EEG.summary.nsmpl;
            Nep(s) = EEG.summary.nep;
            BCT(s) = 100* EEG.summary.BCTn / (Nspl(s)*Nch(s)*Nep(s));
            CCT(s) = 100* EEG.summary.CCTn / (Nspl(s)*Nch(s)*Nep(s));
            BT(s) = 100* EEG.summary.BTn / (Nspl(s)*Nep(s));
            BC(s) = 100* EEG.summary.BCn / (Nch(s)*Nep(s));
        elseif length(summaryIDX)>1 && isfield(EEG,'summaryhistory')
            for j=1:length(summaryIDX)
                if summaryIDX(j)==0
                    Nch(s,j) = EEG.summary.nch;
                    Nspl(s,j) = EEG.summary.nsmpl;
                    Nep(s,j) = EEG.summary.nep;
                    BCT(s,j) = 100* EEG.summary.BCTn / (Nspl(s,j)*Nch(s,j)*Nep(s,j));
                    CCT(s,j) = 100* EEG.summary.CCTn / (Nspl(s,j)*Nch(s,j)*Nep(s,j));
                    BT(s,j) = 100* EEG.summary.BTn / (Nspl(s,j)*Nep(s,j));
                    BC(s,j) = 100* EEG.summary.BCn/ (Nch(s,j))*Nep(s,j);
                else
                    Nch(s,j) = EEG.summaryhistory.nch(summaryIDX(j));
                    Nspl(s,j) = EEG.summaryhistory.nsmpl(summaryIDX(j));
                    Nep(s,j) = EEG.summaryhistory.nep(summaryIDX(j));
                    BCT(s,j) = 100* EEG.summaryhistory.BCTn(summaryIDX(j)) / (Nspl(s,j)*Nch(s)*Nep(s,j));
                    CCT(s,j) = 100* EEG.summaryhistory.CCTn(summaryIDX(j)) / (Nspl(s,j)*Nch(s)*Nep(s,j));
                    BT(s,j) = 100* EEG.summaryhistory.BTn(summaryIDX(j)) / (Nspl(s,j)*Nep(s,j));
                    BC(s,j) = 100* EEG.summaryhistory.BCn(summaryIDX(j)) / (Nch(s,j)*Nep(s,j));
                end
            end
        end
    end
    VarNames = {'Ch' 'Smpl' 'Ep' 'BCT(%)' 'CCT(%)' 'BT(%)' 'BC(%)'};
    T = cell(1,length(summaryIDX));
    for j=1:length(summaryIDX)
        T{j} = table(Nch(:,j),Nspl(:,j),Nep(:,j),BCT(:,j),CCT(:,j),BT(:,j),BC(:,j), 'VariableNames',VarNames,'RowNames',SBJ);
        writetable(T{j},fullfile(pathIn,sprintf('%s.txt',what{j})),'Delimiter','\t','WriteRowNames',1);
        if ~silent
            fprintf('\n%s\nSummary for all subject: %s \n\n',repmat('-',[1 50]),what{j})
            disp(T{j})
        end
    end
else
    warning('No data files were found!')
end

end