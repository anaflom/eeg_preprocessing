% -------------------------------------------------------------------------
% This functions changes the labels of the channels corresponding to the
% 128-electrodes Geodesic Sensor Net to the aproximately corresponding 
% electrodes in the standar system  
%
% INPUT
% chanlocs      structure with the channels location
%
% OPTIONAL INPUTS
% stdlatbelsch  cell of size n x 2 with the labels in chanlocs and the new
%               names. 
%               It can also be the name of a text file with the old and new
%               names.
%               If empty, the default is used
% order         vector of length 2, such that order(1) is the column 
%               corresponding to the old name anda order(2) to the new.
%               Default value [1 2]
% 
% OUTPUS
% chanlocsnew   structure with the new labels
% labchange     logical vector of size 1 x electrodes indicating for which
%               electrodes the label has changed
%
% -------------------------------------------------------------------------

function [chanlocsnew, labchange] = eega_changechlable(chanlocs,stdlatbelsch, order)
if nargin<3; order = [1 2]; end
if nargin<2; stdlatbelsch = []; end

if isempty(stdlatbelsch)
    newLab = {...
        'E1'	'F10';
        'E2'	'AF8';
        'E3'	'AF4';
        'E4'	'F2';
        'E5'	'FFC2';
        'E6'	'FCZ';
        'E7'	'CFC1';
        'E8'	'E8';
        'E9'	'Fp2';
        'E10'	'E10';
        'E11'	'FZ';
        'E12'	'FFC1';
        'E13'	'FC1';
        'E14'	'E14';
        'E15'	'FPZ';
        'E16'	'AFZ';
        'E17'	'E17';
        'E18'	'E18';
        'E19'	'F1';
        'E20'	'FFC3';
        'E21'	'E21';
        'E22'	'Fp1';
        'E23'	'AF3';
        'E24'	'F3';
        'E25'	'E25';
        'E26'	'AF7';
        'E27'	'F5';
        'E28'	'FC5';
        'E29'	'FC3';
        'E30'	'C1';
        'E31'	'CCP1';
        'E32'	'F9';
        'E33'	'F7';
        'E34'	'FT7';
        'E35'	'CFC7';
        'E36'	'C3';
        'E37'	'CP1';
        'E38'	'FT9';
        'E39'	'E39';
        'E40'	'T7';
        'E41'	'C5';
        'E42'	'CP3';
        'E43'	'E43';
        'E44'	'T9';
        'E45'	'T11';
        'E46'	'TP7';
        'E47'	'CP5';
        'E48'	'E48';
        'E49'	'E49';
        'E50'	'E50';
        'E51'	'P5';
        'E52'	'P3';
        'E53'	'PCP3';
        'E54'	'E54';
        'E55'	'CPZ';
        'E56'	'E56';
        'E57'	'TP9';
        'E58'	'P7';
        'E59'	'PPO5';
        'E60'	'P1';
        'E61'	'PCP1';
        'E62'	'PZ';
        'E63'	'E63';
        'E64'	'P9';
        'E65'	'PO7';
        'E66'	'E66';
        'E67'	'PPO1';
        'E68'	'E68';
        'E69'	'PPO7';
        'E70'	'O1';
        'E71'	'PO1';
        'E72'	'POZ';
        'E73'	'I1';
        'E74'	'OI1';
        'E75'	'OZ';
        'E76'	'PO2';
        'E77'	'PPO2';
        'E78'	'PCP2';
        'E79'	'E79';
        'E80'	'CCP2';
        'E81'	'E81';
        'E82'	'OI2';
        'E83'	'O2';
        'E84'	'E84';
        'E85'	'P2';
        'E86'	'PCP4';
        'E87'	'CP2';
        'E88'	'I2';
        'E89'	'PPO8';
        'E90'	'PO8';
        'E91'	'PPO6';
        'E92'	'P4';
        'E93'	'CP4';
        'E94'	'E94';
        'E95'	'P10';
        'E96'	'P8';
        'E97'	'P6';
        'E98'	'CP6';
        'E99'	'E99';
        'E100'	'TP10';
        'E101'	'E101';
        'E102'	'TP8';
        'E103'	'C6';
        'E104'	'C4';
        'E105'	'C2';
        'E106'	'CFC2';
        'E107'	'E107';
        'E108'	'T12';
        'E109'	'T8';
        'E110'	'CFC8';
        'E111'	'FC4';
        'E112'	'FC2';
        'E113'	'E113';
        'E114'	'T10';
        'E115'	'E115';
        'E116'	'FT8';
        'E117'	'FC6';
        'E118'	'FFC4';
        'E119'	'E119';
        'E120'	'E120';
        'E121'	'FT10';
        'E122'	'F8';
        'E123'	'F6';
        'E124'	'F4';
        'E125'	'E125';
        'E126'	'E126';
        'E127'	'E127';
        'E128'	'E128';
        'E129'	'Cz'};
elseif ischar(stdlatbelsch)
    FID = fopen(stdlatbelsch);
    data = textscan(FID,'%s\t%s');
    fclose(FID);
    newLab = [data{order(1)} data{order(2)}];
elseif iscell(stdlatbelsch)
    newLab = stdlatbelsch(:,order);
end

chanlocsnew = chanlocs;
L = {chanlocs(:).labels};
labchange = false(1,size(newLab,1));
for i=1:size(newLab,1)
    id = strcmp(newLab{i,1},L);
    if any(id)
        chanlocsnew(id).labels = newLab{i,2};
        labchange(id) = 1;
    end
end

end