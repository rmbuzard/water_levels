% ETSS File Converter
% Converts the .t##z files into files per station with final stats
% Pulls peaks
clear all; close all; 
% get directory of PETSS forecast folders
dir1 = 'E:\STORM_DATABASE\EVENTS\202209_WesternAK\PETSS\';
cd(dir1)
d = dir('petss*');  % find directories
d([d.isdir]==0)=[]; % remove non-directories
headers = {'DATE','TIDE','OB','SURGE','BIAS','TWL','SURGE90p','TWL90p','SURGE10p','TWL10p'};

% walk through each folder and pull data. Walk backwards to get most recent
% data first
m=[];


for dd = length(d):-1:1                    % for each PETSS folder
    cd(fullfile(d(dd).folder,d(dd).name))   % go to folder
    % convert to CSV
    f = dir('*.t*z');                       % index files in original format
    if ~isempty(f)                          % if files are in .t##z format
        for ff = 1:length(f)
            newName = f(ff).name; newName(end-4)='_';
            copyfile(f(ff).name,[newName,'.csv']);
            delete(f(ff).name);
        end
    end
    % combine files to only include final data
    f = dir('petss*z.csv');
    
    for ff = length(f):-1:1    % from the most recent file backwards
        [t,str,raw] = xlsread(f(ff).name);      % get file data
        % it makes 3 header rows per station
        % the first station headers are removed, the rest are NaN in t
        
        % index stations
        stationID=[];
        for ss = 1:size(str,1)              % for each row
            entry = str{ss,1};                  % get the row contents
            idx = strfind(entry,'PaxHeaders');  % index for header
            if ~isempty(idx)                    % if row is header
                % get station ID number which matches NOAA tidal datum
                stationID(ss,1) = str2double(entry((idx + 18):(idx + 24)));
                ber = strfind(entry,'ber');     % find if it is a ber#### station
                if ~isempty(ber)
                    stationID(ss,1) = str2double(entry((ber + 3):(ber + 6)));
                end
            end
        end

        % index rows of data per station. This neatly works out with t
        idx = find(stationID>0);

        % add station data to variable and append
        for ss = 1:length(idx)                              % for each station
            if ss < length(idx)     % get station data. Change index for final station
                station_data = t(idx(ss):(idx(ss+1)-4),:);
            else
                station_data = t(idx(ss):end,:);
            end

            s2 = [];                                            % empty variable for station data
            for rr = 1:size(station_data,1)                     % for each row in the station
                if station_data(rr,4) ~= 9999                       % remove rows with no forecast. It came as 6 min but forecasts every hour
                    s2 = [s2;station_data(rr,:)];                   % new station data variable
                end
            end

            % Index station row
            if length(m)<ss                             % if first time
                m(ss).station = stationID(idx(ss));     % set station name
                m(ss).data = s2;                        % add data 
            else
                mm = find([m.station] == stationID(idx(ss)));   % or index station row        
                u1 = m(ss).data(:,1);           % existing dates
                u2 = s2(:,1);                   % new dates
                [~,pos] = intersect(u2,u1);     % index matching dates
                s3 = s2(1:pos(1)-1,:);          % new data occurs before first match
                m(ss).data = [m(ss).data;s3];   % append new data
            end                    
        end % for each station
    end     % for each file
end         % for each directory

% sort by date
[~, b] = arrayfun(@(x) sort(x.data(:,1)),m,'UniformOutput',false);
for mm = 1:length(m)
    m(mm).data = m(mm).data(b{mm},:);
end

%% Get peak WL
for mm = 1:length(m)
    [m(mm).TWL, m(mm).TWL_GMT] = max(m(mm).data(:,6));  % find TWL and index datetime
    m(mm).TWL_GMT = m(mm).data(m(mm).TWL_GMT,1);        % record datetime
end

%% Save Station Data
cd(dir1)
mkdir('PETSS_final_forecast_raw')
cd('PETSS_final_forecast_raw')
for ss = 1:length(m)                          
    T = array2table(m(ss).data,'VariableNames',headers);
    writetable(T,strcat(num2str(m(ss).station),'.csv'))
end

%% Save station peaks
cd(dir1)
T=array2table([m.station; m.TWL; m.TWL_GMT]','VariableNames',...
    {'StationID','TWL (ft MLLW)','TWL Datetime (GMT)'});
writetable(T,'PETSS_peaks_ft_MLLW.csv')

%% Convert peaks to tidal datum if possible
cd(dir1)
td = readtable('Tidal_datums.csv');

% index matching stations
[~,it, im] = intersect(td.TideStationID,[m.station]);

% Create new table and append TWL in m MLLW
t2 = td(it,:);
t2 = [t2, array2table([[m(im).TWL]'*.3048,[m(im).TWL_GMT]'],'VariableNames',{'TWL','TWL_GMT'})];
writetable(t2,'Tidal_datums_TWL_m_MLLW.csv')

%% make copy of non-ber stations convert to m MLLW
cd(dir1)
mkdir('PETSS_final_forecast_m_MLLW')

cd('PETSS_final_forecast_raw')
f = dir('*.csv');
fnames = arrayfun(@(x) str2double(x.name(1:end-4)),f);
[~,a,b] = intersect(fnames,t2.TideStationID);
adir = f(1).folder;
bdir = [dir1,'PETSS_final_forecast_m_MLLW'];
for ff = 1:length(a)
    s1 = table2array(readtable(f(a(ff)).name));
    s1(s1==9999) = NaN;
    s1(:,2:end) = round(s1(:,2:end)*0.3048,3);
    s1 = array2table(s1,'VariableNames',headers);
    writetable(s1,fullfile(bdir,f(a(ff)).name));
end



%% Connect tidal datum to areas

% ber00## to NOAA station ID
petss_noaa = [22	9459949
20	9462694
25	9462955
16	9464075
19	9464075
32	9464512
15	9464874
17	9465182
14	9465203
28	9465911
18	9465951
10	9466057
30	9466563
35	9467124
4	9467861
37	9468151
8	9468261
24	9468863
27	9469031
2	9469239
1	9494935
40	9497645];

m2 = m;

cd(dir1)
for ss = 1:size(petss_noaa,1)           % for each ber station 
    % Grab station data
    cd(dir1)
    sidx = find([m.station]==petss_noaa(ss,1));
    % Grab tidal data
    cd('E:\STORM_DATABASE\EVENTS\202209_WesternAK\PETSS\Tidal predictions')
    tide_file = dir(['*',num2str(petss_noaa(ss,2)),'*.csv']);    % file name matching ber
    if isempty(tide_file) % if tide data does not exist skip it
        continue
    end
    
    % Read in tide data and correct datum to m MLLW
    tide = readtable(tide_file.name);                            % read in as table
    tidx = find(td.TideStationID == petss_noaa(ss,2));
    if ~isempty(strfind(tide_file.name,'MHHW'))
        tide.TidePrediction_m_ = tide.TidePrediction_m_ + td.MHHW(tidx);
    elseif ~isempty(strfind(tide_file.name,'NAVD88'))
        tide.TidePrediction_m_ = tide.TidePrediction_m_ + td.NAVD88(tidx);
    end
    % connect dates
    station_date = datetime(string(m(sidx).data(:,1)),'InputFormat','yyyyMMddHHmm');
    [TF LOC] = ismember(station_date,table2array(tide(:,1))); % find matching date rows
    idx = LOC(TF);
    s2 = m(sidx).data(TF,:); % get station data where tide data exist
    s2(s2==9999) = NaN;
    s2(:,2:end) = round(s2(:,2:end)*0.3048,3); % change to meters
    s2(:,2) = tide{idx,2};     % add tide data
    s2(:,6) = s2(:,2)+s2(:,4); % TWL
    s2(:,8) = s2(:,2)+s2(:,7); % TWL90p
    s2(:,10)= s2(:,2)+s2(:,9); % TWL10p
    
    % save peak water levels
    m2(sidx).station = petss_noaa(ss,2);
    [m2(sidx).TWL, b] = max(s2(:,6));
    m2(sidx).TWL = m2(sidx).TWL/.3048; % easier to convert back to ft to match remaining values, then convert to meters at end
    m2(sidx).TWL_GMT = s2(b,1);
    cd(bdir)
    
    writetable(array2table(s2,"VariableNames",headers),[num2str(petss_noaa(ss,2)),'.csv'])
    % Need to double check it is all adding up by doing a manual run in
    % excel
    % seems the forecast surge height is still influenced by the tidal
    % datum, Teller and Kotlik have much higher TWL than before.
end

% Convert peaks to tidal datum if possible
cd(dir1)
td = readtable('Tidal_datums.csv');

% index matching stations
[~,it, im] = intersect(td.TideStationID,[m2.station]);

% Create new table and append TWL in m MLLW
t2 = td(it,:);
t2 = [t2, array2table([round([m2(im).TWL]'*.3048,3),[m2(im).TWL_GMT]'],'VariableNames',{'TWL','TWL_GMT'})];
writetable(t2,'Tidal_datums_TWL_m_MLLW.csv')
%% Simple viewer

td = readtable('Tidal_datums.csv');
petss = dir('9*.csv');
fc=[];
for ff = 1:length(petss)
    fc{ff,1} = readtable(petss(ff).name);
    fc{ff}.DateTime = datetime(string(fc{ff}.DATE),'InputFormat','yyyyMMddHHmm');
    station_name{ff} = [petss(ff).name(1:end-4),' ',...
        td.StationName{find(str2double(petss(ff).name(1:end-4))==td.TideStationID)}];
end


%%
fig = uifigure;
p = plot(fig,fc{ff}.DateTime,fc{ff}.TWL);
dd = uidropdown(fig,'Items',station_name,'ValueChangedFcn',@(dd,event) selection(dd,p,fc,station_name,fig));

function selection(dd,p,fc,station_name,fig)
val = dd.Value;
for pp = 1:length(station_name)
    if strcmp(station_name{pp}, val)
        p = plot(fig,fc{pp}.DateTime,fc{pp}.TWL);
    end
end
end