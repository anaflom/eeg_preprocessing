function [EEG, Y, F ] = eega_rmvbadepochs(EEG, varargin)

%% ------------------------------------------------------------------------
%% Parameters

% Default parameters
P.DataField     = {'data'};
P.FactorField   = {'F'};
P.Silent        = 0;

[P, OK, extrainput] = eega_getoptions(P, varargin);
if ~OK
    error('eega_rmvbadepochs: Non recognized inputs')
end

if ~iscell(P.DataField)
    P.DataField = {P.DataField};
end
if ~iscell(P.FactorField)
    P.FactorField = {P.FactorField};
end

%% ------------------------------------------------------------------------
%% Obtain some usefull data
sss = size(EEG.(P.DataField{1}));
nEp = sss(end);

if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BE')
    BE = EEG.artifacts.BE; 
else
    BE = false(1,1,nEp);
end
goodEp = ~BE(:);
nEpnew=sum(goodEp);
fprintf('%d epochs aout of %d will be removed\n',nEp-nEpnew,nEp)

%% ------------------------------------------------------------------------
%% Remove bad epochs
for i=1:length(P.DataField)
    if isfield(EEG,P.DataField{i})
        EEG.(P.DataField{i}) = EEG.(P.DataField{i})(:,:,goodEp);
    end
end
for i=1:length(P.FactorField)
    if isfield(EEG,P.FactorField{i})
        for j=1:length(EEG.(P.FactorField{i}))
            EEG.(P.FactorField{i}){j}.g = EEG.(P.FactorField{i}){j}.g(goodEp);
        end
    end
end
if isfield(EEG,'epoch') && ~isempty(EEG.epoch)
    EEG.epoch = EEG.epoch(goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BE')
    EEG.artifacts.BE = EEG.artifacts.BE(goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BEm')
    EEG.artifacts.BEm = EEG.artifacts.BEm(goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BCT')
    EEG.artifacts.BCT = EEG.artifacts.BCT(:,:,goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BT')
    EEG.artifacts.BT = EEG.artifacts.BT(:,:,goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'BC')
    EEG.artifacts.BC = EEG.artifacts.BC(:,:,goodEp);
end
if isfield(EEG,'artifacts') && isfield(EEG.artifacts,'CCT')
    EEG.artifacts.CCT = EEG.artifacts.CCT(:,:,goodEp);
end
if isfield(EEG,'reject') && isfield(EEG.reject,'rejmanual') && ~isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = EEG.reject.rejmanual(goodEp);
end
if isfield(EEG,'reject') && isfield(EEG.reject,'rejmanualE') && ~isempty(EEG.reject.rejmanualE)
    EEG.reject.rejmanualE = EEG.reject.rejmanualE(:,goodEp);
end

EEG.trials = nEpnew;

% % add as an event the orignal epoch number
% Ep = find(goodEp);
% if isfield(EEG, 'epoch')
%     for e=1:length(EEG.epoch)
%         EEG.epoch(e).eventEpoch = Ep(e);
%     end
% end

end