function EEG = eega_demean(EEG)
fprintf('### Zero mean ###\n')
[~, data_good] = eega_rmvbaddata(EEG, 'BadData', 'replacebynan');
nEl = size(data_good,1);
nS = size(data_good,2);
nEp = size(data_good,3);
mu = nanmean(reshape(data_good,[nEl nS*nEp]),2);
mu(isnan(mu)) = 0;
EEG.data = bsxfun(@minus,EEG.data,mu);
fprintf('\n')
end