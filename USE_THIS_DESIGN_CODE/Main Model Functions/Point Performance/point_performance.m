function msgs = point_performance(Design_Input,Config,W0_calc,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs)

%% Initialization

[rho_sl,a_sl] = atmos(0,'units','US');

g = 32.2;
Config_Row = Config;
Wo = W0_calc;

S0 = Design_Input.Sref_w(Config_Row);
AR0 = Design_Input.AR_w(Config_Row);
taper = Design_Input.Taper_w(Config_Row);

%% Original Wing Geometry

b0 = sqrt(AR0*S0);
c0 = 2*S0/(b0*(1+taper));

%% Point Performance Analysis

Constants = {g,Config_Row,Wo,S0,rho_sl,a_sl};

[X_Y_req,~,msgs] = Point_Performance_Handler(Req_Input,...
    Constants,W_S_range,Propulsion_Input,Config_Row,...
    DragPolar_Model,WaveDrag_Data,msgs);

PropType = string(Propulsion_Input.PropType(Config_Row));
reqtype = string(Req_Input.reqtype);

% Get original power or thrust to weight

PowerProp = any(PropType == ...
    ["PROP_Electric","PROP_Fuel","PROP_Turbocharged","PROP_Turboprop"]);

if PowerProp

    if PropType == "PROP_Electric"
        Ratio = outputTable{1,5};
    else
        Ratio = outputTable{1,6};
    end

else

    Ratio = outputTable{1,6};
    Ratio_AB = outputTable{1,7};

end

%% Wing Geometry Trade Studies

% Change this range as desired
range = .85:0.15:1.85;

for study = 1:2

    if study == 1

        % Wingspan changes, chord stays constant
        b = b0*range;
        c = c0*ones(size(range));

        GraphTitle = 'Wingspan Trade Study';

    else

        % Chord changes, wingspan stays constant
        b = b0*ones(size(range));
        c = c0*range;

        GraphTitle = 'Root Chord Trade Study';

    end

    % Calculate new wing properties
    S = b.*c*(1+taper)/2;
    AR = b.^2./S;
    WS = Wo./S;

    %% Plot Constraint Diagram

    figure
    hold on

    hReq = gobjects(length(reqtype),1);

    for i = 1:length(reqtype)

        switch reqtype(i)

            case "Stall Velocity"
                hReq(i) = xline(X_Y_req(i,1),'-.k');

            case "Landing Distance"
                hReq(i) = xline(X_Y_req(i,1),'--k');

            otherwise
                hReq(i) = plot(W_S_range,X_Y_req(i,:));

        end

    end

    %% Plot All Design Points

    if PowerProp

        % All configurations
        hTrade = plot(WS,Ratio*ones(size(WS)),...
            'kd','MarkerSize',9,...
            'MarkerFaceColor','k',...
            'LineStyle','none');

        % Highlight original configuration
        hBase = plot(WS(3),Ratio,'rd',...
            'MarkerSize',11,'MarkerFaceColor','r');

        ylabel('Power to Weight (hp/lb)')

        legend([hReq;hTrade;hBase],...
            [string(Req_Input.labels(:));...
            "Trade Study";"Original Design"],...
            'Location','best')

    else

        % Military thrust
        hTrade = plot(WS,Ratio*ones(size(WS)),...
            'kd','MarkerSize',9,...
            'MarkerFaceColor','k',...
            'LineStyle','none');

        % Afterburner thrust
        hAB = plot(WS,Ratio_AB*ones(size(WS)),...
            'bd','MarkerSize',9,...
            'MarkerFaceColor','b',...
            'LineStyle','none');

        % Original configuration
        hBase = plot(WS(3),Ratio,'rd',...
            'MarkerSize',11,'MarkerFaceColor','r');

        ylabel('Thrust to Weight')

        legend([hReq;hTrade;hAB;hBase],...
            [string(Req_Input.labels(:));...
            "Trade Study (mil)";"Trade Study (AB)";...
            "Original Design"],'Location','best')

    end

    xlabel('Wing Loading (lb/ft^2)')
    title(GraphTitle)

    % Label each diamond with percentage change
    for j = 1:length(range)

        text(WS(j),Ratio,...
            sprintf('  %.0f%%',range(j)*100),...
            'FontSize',8,...
            'VerticalAlignment','bottom');

    end

    grid on
    hold off

end

end