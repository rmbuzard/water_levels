function [] = ETSSConverter(url)
%%% ETSSCONVERTER
% % % CONVERTS ETSS DATA INTO AN ACTUAL USEFUL FORMAT
% % % 
% % %
% % % INPUTS
% % % Link to data you want to convert
% % % 
% % %
% % % OUTPUTS
% % % txt file with datenum and stage, labeled as location, in cd
% % %
% % %
% % % WRITTEN BY RICHARD BUZARD, FEB 7, 2017

%% Setup

% Prompt user to identify link and output file(s)
if exist('url')
else
    prompt = {'Paste URL:'};
    dlg_title = 'Input URL';
    num_lines = 1;
    defaultans = {''};
    url = char(inputdlg(prompt,dlg_title,num_lines,defaultans));
end

% Read in the url
url = urlread(url);

%% Read in data to variable. 
% Test for number of words in title
try allData = textscan(url, '%s %{MM/dd/yyyy}D  %d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d');
catch ME
end

if exist('allData')
    titlenum = 1;
    titlename = allData{1}(1);
else
    try allData = textscan(url, '%s %s %{MM/dd/yyyy}D  %d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d');
    catch ME
    end
    if exist('allData')
        titlenum = 2;
        titlename = char(strcat(allData{1}(1),'_',allData{2}(1)));
    else
        try allData = textscan(url, '%s %s %s %{MM/dd/yyyy}D  %d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d');
        catch ME
        end
        if exist('allData')
            titlenum = 3;
            titlename = strcat(allData{1}(1),'_',allData{2}(1),'_',allData{3}(1));
        else
            try allData = textscan(url, '%s %s %s %s %{MM/dd/yyyy}D  %d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d %d%d%d%d%d%d');
            catch ME
            end
            titlenum = 4;
            titlename = strcat(allData{1}(1),'_',allData{2}(1),'_',allData{3}(1),'_',allData{4}(1));
        end
        
    end
end

%% Get the date and time information
hours    = allData{titlenum + 2};
hoursFmt = double(hours)./24;
date     = allData{titlenum+1};
dateFmt  = datenum(date);

% Set up variables
dateNums = [];
stage = [];

%% Get the stage and datenumber

for ii = 1:length(allData{1})             % For each line of the data
    for kk = 1:6                        % For each six hour chunk in the line
        clockHour = double(hours(ii) + kk -1)/24;           % Get current clock hour in datenum
        dateNums  = [dateNums; dateFmt(ii) + clockHour];    % Make list of datenums
        stage     = [stage; allData{titlenum + 2 + kk}(ii)];  % Get stage at this hour in line ii
    end
end
            
%% Output stage and datenumber to file
titlename = strrep(titlename,'.','');
titlename = strrep(titlename,',','');
newfile = char(strcat(titlename, '.txt'));

fid = fopen(newfile,'wt');
for row = 1:length(dateNums)
    fprintf(fid,'%.4f\t',dateNums(row));
    fprintf(fid,'%.2f\r\n',stage(row));
end
fclose(fid);



%plot(dateNums,stage)
%datetick( 'x', 'mmm-yy' )

end
