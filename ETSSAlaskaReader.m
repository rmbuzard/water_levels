% % % ETSSAlaskaReader
% % % 
% % % Reads ETSS data for Alaska
% % % Writes / Overwrites output text files
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % 
% % % Written By Richard Buzard
% % % Feb 9, 2017

%% Setup
clear all; close all;
url = 'http://slosh.nws.noaa.gov/user/tayloraa/etsurge_Database/';

%%% ACTIVATE THIS TO PROMPT USER FOR WEBSITE
% prompt = {'Paste URL:'};
% dlg_title = 'Input URL';
% num_lines = 1;
% defaultans = {''};
%url = char(inputdlg(prompt,dlg_title,num_lines,defaultans));
%%% END ACTIVATION AREA

outputDir = uigetdir('','Select Output Folder');
cd(outputDir)

% Read in website html
masterlist = urlread(url);

% Find filenames that are format "ak ... .ss
ak = strfind(masterlist,'"ak')+1;
ss = strfind(masterlist,'.ss');

% Create list of Alaska filenames
listAK = {};
for ii = 1:length(ak)               % For each time ak is found
    % Record when .ss follows
    ssIndex = ss(ss>ak(ii)+4 & ss<=(ak(ii)+6));
    listAK{ii} = masterlist(ak(ii):(ssIndex+2));
end
% Remove duplicates and empty cells
[~,idx]= unique(listAK);
listAK = listAK(:,idx);

%% Write the files
for ii = 1:length(listAK)
    if isempty(listAK{ii})
    else
        newURL = strcat(url,listAK{ii});
        ETSSConverter(newURL)
        disp(listAK{ii})
    end
end
