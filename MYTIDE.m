classdef MYTIDE < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        GridLayout               matlab.ui.container.GridLayout
        LeftPanel                matlab.ui.container.Panel
        WaitingLamp              matlab.ui.control.Lamp
        WaitingLampLabel         matlab.ui.control.Label
        ProcessingLamp           matlab.ui.control.Lamp
        ProcessingLampLabel      matlab.ui.control.Label
        CompleteLamp             matlab.ui.control.Lamp
        CompleteLampLabel        matlab.ui.control.Label
        DownloadButton           matlab.ui.control.Button
        IntervalDropDown         matlab.ui.control.DropDown
        IntervalDropDownLabel    matlab.ui.control.Label
        TimeZoneDropDown         matlab.ui.control.DropDown
        TimeZoneDropDownLabel    matlab.ui.control.Label
        UnitsDropDown            matlab.ui.control.DropDown
        UnitsDropDownLabel       matlab.ui.control.Label
        DatumDropDown            matlab.ui.control.DropDown
        DatumDropDownLabel       matlab.ui.control.Label
        EndDateEditField         matlab.ui.control.EditField
        EndDateEditFieldLabel    matlab.ui.control.Label
        StartDateEditField       matlab.ui.control.EditField
        StartDateEditFieldLabel  matlab.ui.control.Label
        MultiyeartidalinformationdataextractorLabel  matlab.ui.control.Label
        MYTIDELabel              matlab.ui.control.Label
        StationIDEditField       matlab.ui.control.EditField
        StationIDEditFieldLabel  matlab.ui.control.Label
        RightPanel               matlab.ui.container.Panel
        UIAxes                   matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: StationIDEditField
        function entry_station(app, event)
            station = app.StationIDEditField.Value;
            
        end

        % Value changed function: StartDateEditField
        function entry_start_date(app, event)
            first_date = app.StartDateEditField.Value;
            
        end

        % Value changed function: EndDateEditField
        function entry_end_date(app, event)
            last_date = app.EndDateEditField.Value;
            
        end

        % Value changed function: DatumDropDown
        function entry_datum(app, event)
            datum = app.DatumDropDown.Value;
            
        end

        % Value changed function: UnitsDropDown
        function entry_units(app, event)
            units = app.UnitsDropDown.Value;
            
        end

        % Value changed function: TimeZoneDropDown
        function entry_time_zone(app, event)
            time_zone = app.TimeZoneDropDown.Value;
            
        end

        % Value changed function: IntervalDropDown
        function entry_interval(app, event)
            interval = app.IntervalDropDown.Value;
            
        end

        % Button pushed function: DownloadButton
        function psh_download(app, event)
            % set lamps
            app.WaitingLamp.Enable          = 'off';
            app.WaitingLampLabel.Enable     = 'off';
            app.ProcessingLamp.Enable       = 'on';
            app.ProcessingLampLabel.Enable  = 'on';
            app.CompleteLamp.Enable         = 'off';
            app.CompleteLampLabel.Enable    = 'off';
            % import variables
            station    = app.StationIDEditField.Value;
            first_date = app.StartDateEditField.Value;
            last_date  = app.EndDateEditField.Value;
            datum      = app.DatumDropDown.Value;
            units      = app.UnitsDropDown.Value;
            time_zone  = app.TimeZoneDropDown.Value;
            interval   = app.IntervalDropDown.Value;
            if strcmp(interval,'6 minutes')
                interval ='6';
            elseif strcmp(interval,'Hourly')
                interval = 'h';
            elseif strcmp(interval,'High/Low')
                interval = 'hilo';
            end
           
            
            first_date_dt = datetime(first_date,'InputFormat','yyyyMMdd');
            last_date_dt  = datetime(last_date,'InputFormat','yyyyMMdd');
            % change pull dates depending on interval
            if strcmp(interval,'6')
                % monthly pull start and end dates
                pull_date_start = first_date_dt:calmonths(1):last_date_dt;
                pull_date_end   = dateshift(pull_date_start,'end','month');
            else
                % annual pulls
                pull_date_start = first_date_dt:calmonths(12):last_date_dt;
                pull_date_end   = dateshift(pull_date_start(2:end)-days(1),'end','month');
                pull_date_end(end+1) = last_date_dt;
            end
            [filename,filepath] = uiputfile('.csv','Save as',['tide prediction ',station,' ',first_date,' to ',last_date,'.csv']);
            filefull = fullfile(filepath,filename);
            url={}; output = {};
            for pp = 1:length(pull_date_start)
                url{pp} = ['https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?product=predictions&application=NOS.COOPS.TAC.WL' ...
                    '&begin_date=',datestr(pull_date_start(pp),'yyyymmdd'), ...
                    '&end_date=',datestr(pull_date_end(pp),'yyyymmdd'), ...
                    '&datum=',datum, ...
                    '&station=',station, ...
                    '&time_zone=',time_zone, ...
                    '&units=',units, ...
                    '&interval=',interval, ...
                    '&format=csv'];
            end
            if strcmp(units,'metric')
                u = 'm';
            else
                u = 'ft';
            end
            % save output if 1 file
            if pp<2
                output = websave(filefull,url{1});
                r = readtable(output);
                r.Properties.VariableNames = {['DateTime ',time_zone],['Tide Prediction (',u,')']};
                writetable(r,filefull);
            % otherwise merge outputs
            else
                r = [];
                for pp = 1:length(url)
                    output{pp} = websave(...
                        fullfile(filepath,[num2str(pp),filename]),...
                        url{pp});
                    r = [r; readtable(output{pp})];
                    delete(output{pp})
                end
                r.Properties.VariableNames = {['DateTime ',time_zone],['Tide Prediction (',u,')']};
                writetable(r,filefull);
            end
            % set lamps
            app.WaitingLamp.Enable          = 'off';
            app.WaitingLampLabel.Enable     = 'off';
            app.ProcessingLamp.Enable       = 'off';
            app.ProcessingLampLabel.Enable  = 'off';
            app.CompleteLamp.Enable         = 'on';
            app.CompleteLampLabel.Enable    = 'on';

            % plot
            app.UIAxes.Visible = 'on';
            plot(app.UIAxes,r{:,1},r{:,2});
 
            ylabel(app.UIAxes,r.Properties.VariableNames{2});
            xlabel(app.UIAxes,[])
            title(app.UIAxes,['Station ',station])
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create StationIDEditFieldLabel
            app.StationIDEditFieldLabel = uilabel(app.LeftPanel);
            app.StationIDEditFieldLabel.HorizontalAlignment = 'right';
            app.StationIDEditFieldLabel.Position = [19 395 58 22];
            app.StationIDEditFieldLabel.Text = 'Station ID';

            % Create StationIDEditField
            app.StationIDEditField = uieditfield(app.LeftPanel, 'text');
            app.StationIDEditField.ValueChangedFcn = createCallbackFcn(app, @entry_station, true);
            app.StationIDEditField.Tooltip = {'1234567'};
            app.StationIDEditField.Position = [92 395 105 22];

            % Create MYTIDELabel
            app.MYTIDELabel = uilabel(app.LeftPanel);
            app.MYTIDELabel.HorizontalAlignment = 'center';
            app.MYTIDELabel.FontWeight = 'bold';
            app.MYTIDELabel.Position = [6 450 208 17];
            app.MYTIDELabel.Text = 'MYTIDE';

            % Create MultiyeartidalinformationdataextractorLabel
            app.MultiyeartidalinformationdataextractorLabel = uilabel(app.LeftPanel);
            app.MultiyeartidalinformationdataextractorLabel.HorizontalAlignment = 'center';
            app.MultiyeartidalinformationdataextractorLabel.FontSize = 10;
            app.MultiyeartidalinformationdataextractorLabel.Position = [17 429 187 22];
            app.MultiyeartidalinformationdataextractorLabel.Text = 'Multi-year tidal information data extractor';

            % Create StartDateEditFieldLabel
            app.StartDateEditFieldLabel = uilabel(app.LeftPanel);
            app.StartDateEditFieldLabel.HorizontalAlignment = 'right';
            app.StartDateEditFieldLabel.Position = [17 364 60 22];
            app.StartDateEditFieldLabel.Text = 'Start Date';

            % Create StartDateEditField
            app.StartDateEditField = uieditfield(app.LeftPanel, 'text');
            app.StartDateEditField.ValueChangedFcn = createCallbackFcn(app, @entry_start_date, true);
            app.StartDateEditField.Tooltip = {'YYYYMMDD'};
            app.StartDateEditField.Position = [92 364 105 22];

            % Create EndDateEditFieldLabel
            app.EndDateEditFieldLabel = uilabel(app.LeftPanel);
            app.EndDateEditFieldLabel.HorizontalAlignment = 'right';
            app.EndDateEditFieldLabel.Position = [21 334 56 22];
            app.EndDateEditFieldLabel.Text = 'End Date';

            % Create EndDateEditField
            app.EndDateEditField = uieditfield(app.LeftPanel, 'text');
            app.EndDateEditField.ValueChangedFcn = createCallbackFcn(app, @entry_end_date, true);
            app.EndDateEditField.Tooltip = {'YYYYMMDD'};
            app.EndDateEditField.Position = [92 334 105 22];

            % Create DatumDropDownLabel
            app.DatumDropDownLabel = uilabel(app.LeftPanel);
            app.DatumDropDownLabel.HorizontalAlignment = 'right';
            app.DatumDropDownLabel.Position = [12 305 65 22];
            app.DatumDropDownLabel.Text = 'Datum';

            % Create DatumDropDown
            app.DatumDropDown = uidropdown(app.LeftPanel);
            app.DatumDropDown.Items = {'MHHW', 'MHW', 'MTL', 'MSL', 'MLW', 'MLLW', 'NAVD'};
            app.DatumDropDown.ValueChangedFcn = createCallbackFcn(app, @entry_datum, true);
            app.DatumDropDown.Tooltip = {'Ensure station has NAVD before using that datum'};
            app.DatumDropDown.Position = [93 305 104 22];
            app.DatumDropDown.Value = 'MLLW';

            % Create UnitsDropDownLabel
            app.UnitsDropDownLabel = uilabel(app.LeftPanel);
            app.UnitsDropDownLabel.HorizontalAlignment = 'right';
            app.UnitsDropDownLabel.Position = [12 275 65 22];
            app.UnitsDropDownLabel.Text = 'Units';

            % Create UnitsDropDown
            app.UnitsDropDown = uidropdown(app.LeftPanel);
            app.UnitsDropDown.Items = {'metric', 'english'};
            app.UnitsDropDown.ValueChangedFcn = createCallbackFcn(app, @entry_units, true);
            app.UnitsDropDown.Tooltip = {'english is feet'};
            app.UnitsDropDown.Position = [93 275 104 22];
            app.UnitsDropDown.Value = 'metric';

            % Create TimeZoneDropDownLabel
            app.TimeZoneDropDownLabel = uilabel(app.LeftPanel);
            app.TimeZoneDropDownLabel.HorizontalAlignment = 'right';
            app.TimeZoneDropDownLabel.Position = [12 246 65 22];
            app.TimeZoneDropDownLabel.Text = 'Time Zone';

            % Create TimeZoneDropDown
            app.TimeZoneDropDown = uidropdown(app.LeftPanel);
            app.TimeZoneDropDown.Items = {'GMT', 'LST', 'LST_LDT'};
            app.TimeZoneDropDown.ValueChangedFcn = createCallbackFcn(app, @entry_time_zone, true);
            app.TimeZoneDropDown.Tooltip = {''};
            app.TimeZoneDropDown.Position = [93 246 104 22];
            app.TimeZoneDropDown.Value = 'GMT';

            % Create IntervalDropDownLabel
            app.IntervalDropDownLabel = uilabel(app.LeftPanel);
            app.IntervalDropDownLabel.HorizontalAlignment = 'right';
            app.IntervalDropDownLabel.Position = [12 217 65 22];
            app.IntervalDropDownLabel.Text = 'Interval';

            % Create IntervalDropDown
            app.IntervalDropDown = uidropdown(app.LeftPanel);
            app.IntervalDropDown.Items = {'6 minutes', 'Hourly', 'High/Low'};
            app.IntervalDropDown.ValueChangedFcn = createCallbackFcn(app, @entry_interval, true);
            app.IntervalDropDown.Tooltip = {''};
            app.IntervalDropDown.Position = [93 217 104 22];
            app.IntervalDropDown.Value = '6 minutes';

            % Create DownloadButton
            app.DownloadButton = uibutton(app.LeftPanel, 'push');
            app.DownloadButton.ButtonPushedFcn = createCallbackFcn(app, @psh_download, true);
            app.DownloadButton.Position = [93 188 104 22];
            app.DownloadButton.Text = 'Download';

            % Create CompleteLampLabel
            app.CompleteLampLabel = uilabel(app.LeftPanel);
            app.CompleteLampLabel.HorizontalAlignment = 'right';
            app.CompleteLampLabel.Enable = 'off';
            app.CompleteLampLabel.Position = [100 114 57 22];
            app.CompleteLampLabel.Text = 'Complete';

            % Create CompleteLamp
            app.CompleteLamp = uilamp(app.LeftPanel);
            app.CompleteLamp.Enable = 'off';
            app.CompleteLamp.Position = [172 114 20 20];

            % Create ProcessingLampLabel
            app.ProcessingLampLabel = uilabel(app.LeftPanel);
            app.ProcessingLampLabel.HorizontalAlignment = 'right';
            app.ProcessingLampLabel.Enable = 'off';
            app.ProcessingLampLabel.Position = [92 135 65 22];
            app.ProcessingLampLabel.Text = 'Processing';

            % Create ProcessingLamp
            app.ProcessingLamp = uilamp(app.LeftPanel);
            app.ProcessingLamp.Enable = 'off';
            app.ProcessingLamp.Position = [172 135 20 20];
            app.ProcessingLamp.Color = [1 1 0];

            % Create WaitingLampLabel
            app.WaitingLampLabel = uilabel(app.LeftPanel);
            app.WaitingLampLabel.HorizontalAlignment = 'right';
            app.WaitingLampLabel.Position = [112 156 45 22];
            app.WaitingLampLabel.Text = 'Waiting';

            % Create WaitingLamp
            app.WaitingLamp = uilamp(app.LeftPanel);
            app.WaitingLamp.Position = [172 156 20 20];
            app.WaitingLamp.Color = [1 0 0];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.RightPanel);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [0 114 414 336];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MYTIDE

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end