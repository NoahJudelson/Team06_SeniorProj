function [W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs,WeightComparison]=sizing(MSN_Profile,Config_Row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs)
    %% Aircraft Design Mission Performance Sizing Analysis
    % ASEN 4138
    % Author: John Mah, Maggie Wussow, Jonathan Morris

    % Description:  This function estimates the fuel burn utilized through a
    % user defined mission profile through multiple iterations to converge on a
    % estimate for aircraft total weight.  The user must first model the aircraft
    % aerodynamically via the aero_analysis.m code or via
    % Open VSP and provide an initial "guess" at the total aircraft weight to
    % begin the iterative process. The mission profile should be defined in
    % an excel sheet (e.g. Mission_Profile_Template.xlsx). The initial 
    % guess weight is updated after each iteration with the average value
    % between the guess weight and the calculated weight at the end of the 
    % mission analysis.  Script will stop iterations once the aircraft total 
    % weight calcluated converges with the initial guess of the
    % aircraft total weight within a user defined percentage.

    %% Current Version:  AY24.??
    % Date Last Change: 23 Nov 24
    % Changes in Current Version: Refactored as a function from main
    % script. Now the code expects a mission profile defined by an excel
    % sheet. This sheet should be read in with Read_MSN_Profile.m which
    % returns a MSN_Profile structure. This profile is then interpreted by
    % the MSN_SEG_Handler.m function which calls the appropriate MSN_SEG
    % funtion and returns weight/battery mass fraction data.
    %
    % Functions & files required to execute this function
    %4138_Design Input File_V24-00.xlsx
    %aero_analyis.m (and its outputs)
    %atmos.m
    %DragPolar.m
    %DragPolar_Function.m
    %InducedDrag.m
    %LD.m
    %ParasiteDrag.m
    %Propulsion.m
    %WaveDrag.m
    %WingGeo.m
    %WingLiftDrag.m
    %MSN_SEG_TO.m
    %MSN_SEG_Climb.m
    %MSN_SEG_Cruise.m
    %MSN_SEG_Loiter.m
    %MSN_SEG_Handler.m



    %% Instructions
    % During initial conceptual evaluation, the ASEN4138_Aircraft_Design_Aero_Model_Main.m script
    % should be executed prior to utilization of this code to create the drag polar and propulsion
    % properties of the aircraft configuration concept required to run a
    % mission performance sizing. However, after refining and modeling the
    % concept in OPEN VSP, you should use the sizing.vsp script with
    % outputs from OPEN VSP.

    %%%%%%%%%%%%%%%%%%TWEAKABLES%%%%%%%%%%%%%%%%%%%%%%
    %These are factors that may need to be editted for certain designs. 
    Converge = .005; % Was originally 0.005 %Sets the percent difference between W0_guess and W0_calc to determine solution has converged
    Kvs = 1; %From Raymer Table 6.1 based on variable sweep (1.04) or fixed sweep (1.0)
    Composite_Factor=1; %Using the composite homebuilt model it was found that multiplying the empty weight fraction by 0.8-0.9 lined up more closely with serial produced composite aircraft. The Raymer text reccomends a similar approach.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    WeightComparison = table(); % Populated only for component-model runs.

    %%Initialization
    %Clear Mission Analyis Variables
    clear SizingStruct Msn_Sizing_Table MsnStruct
    %load(MSN_structure);

    %Start Mission Sizing Iterations
    i = 1; %Iteration number
    Diff_W0 = 1; %Set initial value in total weight difference to 100% or 1

    %% AIRCRAFT WEIGHT AND GEOMETRY INPUTS
    %Aircraft Geometry Constants (either from ASEN4138_Aircaft_Design_Aero_Model.m or
    %manually inputted via OPEN VSP)
    AR = Design_Input.AR_w(Config_Row);
    Sref = Design_Input.Sref_w(Config_Row);
    M_max = Design_Input.M_max(Config_Row);
    g = 32.2; %Accel of gravity (ft/s^2);
    ACType=Design_Input.ACType(Config_Row);


    %% PROPULSION INPUTS
    %Type of propulsion used in design. Only used to output final T/W or
    %P/W for specific configuration evaluated.  Fuel burn done in each
    %mission segment function.
    PropType = Propulsion_Input.PropType(Config_Row); %Determine if jet or prop propulsion
    %Jet Engine Values (if propellor propulsion, set all to zero)
    TA_mil_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.TA_mil_sl(Config_Row); %Uninstalled Mil power total thrust at sea level (all engines)
    TA_AB_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.TA_AB_sl(Config_Row); %Uninstalled AB power total thrust at sea level (all engines)
    
    %Prop Engine Values (if jet propulsion, set all to zero)
    PA_shp_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.PA_shp_sl(Config_Row); %shaft horsepower from engine at sea level (hp) total (all engines)
    NumEng=Propulsion_Input.Number(Config_Row);


    %% PACKAGE CONSTANTS AND ATMOSPHERE
    Constants = {Config_Row,AR,Sref,M_max,g,PropType}; %Package for use in functions

    %Set sea level std atmosphere values
    [~,a_sl,~,~,~,~] = atmos(0,'units','US'); %sea level std atmosphere properties

    %% MISSION ANALYSIS ITERATIVE SIZING
    %Set Convergence Criteria

    % Read_Material_Weight supplies an empty-weight estimate in pounds.
    useMaterialWeight = (istable(Design_Input) && ...
        ismember('Material_Empty_lb', Design_Input.Properties.VariableNames)) || ...
        (isstruct(Design_Input) && isfield(Design_Input, 'Material_Empty_lb'));
    if useMaterialWeight
        materialEmptyWeight = Design_Input.Material_Empty_lb(Config_Row);
        validateattributes(materialEmptyWeight, {'numeric'}, ...
            {'scalar','real','finite','positive'}, mfilename, 'Material_Empty_lb');
        % Total weight cannot start below the fixed empty weight and payload.
        W0_guess = max(W0_guess,materialEmptyWeight+W_crew+W_pay_fixed+W_pay_drop);
    else
        [a,c1,c2,c3,c4,c5,msgs]= WeightModel(PropType,ACType,msgs);
    end

    while Diff_W0 >= Converge
        assert(i<=100,'Sizing:NoConvergence', ...
            'Sizing did not converge within 100 iterations. Check the selected weight model and mission inputs.');

        %Calculate Aircraft Parameters & Empty Weight based on Total Weight
        %(W0) and statistical model
        disp("Iteration "+ num2str(i)+ ": Gross Takeoff Weight Guess: "+ W0_guess)

        if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')
            Power_Weight_Ratio =PA_shp_sl/W0_guess; %in hp/lb shaft hp at sea level/Wo
            V_max = (M_max*a_sl)*(3600/6076); %Max velocity in terms of knots (must convert ft/s to knots using 6076 ft per nautical mile and 3600 sec per hr).
            WingLoading = W0_guess/Sref;

            %Statistical empty weight fraction model for prop aircaft
            if useMaterialWeight
                We = materialEmptyWeight;
                We_W0 = We/W0_guess;
            else
                We_W0 = (a*(W0_guess)^c1*(AR)^c2*(Power_Weight_Ratio)^c3*(WingLoading)^c4*(V_max)^c5)*Kvs;
                We_W0=We_W0*Composite_Factor;

                We = We_W0*W0_guess; %Empty weight of aircraft (lb)
            end
        else
            Thrust_Weight_Ratio_mil =TA_mil_sl/W0_guess; %Uninstalled thrust at sea level / Wo
            Thrust_Weight_Ratio_AB = TA_AB_sl/W0_guess; %Uninstalled thrust at sea level / Wo
            Thrust_Weight_Ratio = max(Thrust_Weight_Ratio_AB,Thrust_Weight_Ratio_mil); %Size based on max value of T/W
            WingLoading = W0_guess/Sref;
            %Statistical empty weight fraction model for jet aircaft
            if useMaterialWeight
                We = materialEmptyWeight;
                We_W0 = We/W0_guess;
            else
                We_W0 = (a*(W0_guess)^c1*(AR)^c2*(Thrust_Weight_Ratio)^c3*(WingLoading)^c4*(M_max)^c5)*Kvs;
                We_W0=We_W0*Composite_Factor;

                We = We_W0*W0_guess; %Empty weight of aircraft (lb)
            end
        end
        
        %MSN_SEG_Handler replaces past versions of the code where the users
        %editted calls to MSN_SEG functions manually. MSN_SEG_Handler takes
        %in the mission profile and calls different MSN_SEG functions based
        %on user inputs. Returns weight/battery mass fraction and debugging
        %data for each segment and each convergence iteration.
        [W_Mat,BMF_Mat,DATA,msgs]=MSN_SEG_Handler(MSN_Profile,W0_guess,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
        config=Constants{1};
        PropType=Propulsion_Input.PropType(config);
        if strcmp(PropType,"PROP_Electric")
            BMF=sum(BMF_Mat);
            assert(isreal(BMF) && isfinite(BMF) && BMF>=0 && BMF<1, ...
                'Sizing:BatteryFraction', ...
                'Invalid mission battery fraction %.4f at W0 = %.3f lb.',BMF,W0_guess);
            if useMaterialWeight
                % W0 = fixed empty weight + crew + payload + BMF*W0.
                W0_calc=(We+W_crew+W_pay_fixed)/(1-BMF);
            else
                assert(isreal(We_W0) && isfinite(We_W0) && We_W0>0 && 1-BMF-We_W0>0, ...
                    'Sizing:WeightFraction', ...
                    ['Raymer sizing cannot update at W0 = %.3f lb: empty fraction %.4f + ' ...
                    'battery fraction %.4f leaves no positive payload/crew fraction. ' ...
                    'Check the Raymer category, mission inputs and starting weight.'],W0_guess,We_W0,BMF);
                W0_calc=(W_crew+W_pay_fixed)/(1-BMF-We_W0);
            end
            %% Calc Difference Between W0_guess and W0_calc
            Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;
            IterationData(i,:)=[i,W0_calc,We,BMF]; %#ok<AGROW>
            %% Next Iteration Update
            i = i + 1;
            W0_guess = (W0_guess+W0_calc)/2;


        else

            W_f_total_used=sum(W_Mat(:,3)); %Total amount of fuel burned for mission
            W_f_total_refuel=sum(W_Mat(:,5)); %Total amount of air refuel added in mission
            W_f_req_internal=W_f_total_used-W_f_total_refuel; %Total amount of fuel that must be carried internally
            W0_calc = W_crew + W_pay_fixed + W_pay_drop + W_f_req_internal + We; %Calcuated aircraft total weight based on mission

            %% Calc Difference Between W0_guess and W0_calc
            Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;
            IterationData(i,:)=[i,W0_calc,We,W_f_total_used]; %Save iteration data

            %% Next Iteration Update
            i = i + 1;
            W0_guess = (W0_guess+W0_calc)/2;


        end

    end

    if strcmp(PropType,"PROP_Electric")
        W0=W0_calc;

        FinalWeightData=[MSN_Profile.legtype',BMF_Mat'];
        FinalWeightData=array2table(FinalWeightData);
        FinalWeightData.Properties.VariableNames=["Leg Type","BMF"];
        IterationData=array2table(IterationData);
        IterationData.Properties.VariableNames=["Iteration Number","W0 [lb]","Empty Weight [lb]","BMF"];
        FinalSegmentData=DATA;

    else
        W0=W0_calc;
        FinalWeightData=[MSN_Profile.legtype',W_Mat];
        FinalWeightData=array2table(FinalWeightData);
        FinalWeightData.Properties.VariableNames=["Leg Type","Starting Weight [lb]","Ending Weight [lb]", "Fuel Weight [lb]", "Weight Fraction", "Fuel Added"];

        IterationData=array2table(IterationData);
        IterationData.Properties.VariableNames=["Iteration Number","W0 [lb]","Empty Weight [lb]","Total Fuel Weight [lb]"];
        FinalSegmentData=DATA;

    end
    
    %% Raymer UAV weight comparison at the nominal component-sized gross weight.
    if useMaterialWeight
        twoXEmptyWeight = materialEmptyWeight;
        if istable(Design_Input) && ismember('Material_Empty_2x_lb',Design_Input.Properties.VariableNames)
            twoXEmptyWeight = Design_Input.Material_Empty_2x_lb(Config_Row);
        elseif isstruct(Design_Input) && isfield(Design_Input,'Material_Empty_2x_lb')
            twoXEmptyWeight = Design_Input.Material_Empty_2x_lb(Config_Row);
        end
        validateattributes(twoXEmptyWeight,{'numeric'}, ...
            {'scalar','real','finite','>=',materialEmptyWeight},mfilename,'Material_Empty_2x_lb');
        if startsWith(string(PropType),"PROP_")
            uavCategory = "UAV_Prop";
            loadingR = PA_shp_sl/W0;
            speedR = M_max*a_sl*(3600/6076);
            raymerLabel = "Raymer: UAV Prop";
        else
            uavCategory = "UAV_Jet";
            loadingR = max(TA_mil_sl,TA_AB_sl)/W0;
            speedR = M_max;
            raymerLabel = "Raymer: UAV Jet";
        end
        [aR,c1R,c2R,c3R,c4R,c5R] = WeightModel(PropType,uavCategory,msgs);
        uavEstimate = W0*aR*W0^c1R*AR^c2R*loadingR^c3R* ...
            (W0/Sref)^c4R*speedR^c5R*Kvs*Composite_Factor;
        Model = ["Component Model — Nominal"; "All LWPLA Thicknesses ×2"; raymerLabel];
        Empty_lb = [materialEmptyWeight; twoXEmptyWeight; uavEstimate];
        WeightComparison = table(Model,Empty_lb,Empty_lb/W0,Empty_lb-materialEmptyWeight, ...
            'VariableNames',{'Model','Empty_lb','Empty_fraction','Difference_from_component_lb'});
        fprintf('\nEmpty-weight estimates at common W0 = %.3f lb; only nominal Component model was iterated.\n',W0);
        disp(WeightComparison)

        [fig,ax] = weightPlotAxes('comparison');
        fig.Position = [100 100 1150 560];
        bars = barh(ax,Empty_lb,0.72,'FaceColor','flat');
        bars.CData = [0.23 0.62 0.38; 0.13 0.48 0.73; 0.91 0.52 0.16];
        plotLabels = ["Component"; "2× LWPLA Skin"; replace(raymerLabel,":","")];
        set(ax,'YTick',1:3,'YTickLabel',cellstr(plotLabels), ...
            'YDir','reverse','TickLabelInterpreter','none','FontSize',22, ...
            'Box','off','Layer','bottom');
        ax.Position = [0.39 0.18 0.55 0.68];
        text(ax,Empty_lb,1:3,compose('  %.2g lb',Empty_lb), ...
            'FontSize',22,'Color',[0.15 0.18 0.22]);
        xlim(ax,[0 1.20*max(Empty_lb)]);
        ylim(ax,[0.5 3.5]);
        xtickformat(ax,'%.2g');
        ax.XGrid = 'on';
        ax.YGrid = 'off';
        ax.GridColor = [0.82 0.86 0.90];
        ax.GridAlpha = 0.25;
        xlabel(ax,'Battery Sizing Input Weight [lb]','FontSize',22);
        plotTitle = title(ax,'Component Weight Model vs. Raymer UAV Estimate','FontSize',22);
        plotTitle.Units = 'normalized';
        titlePosition = plotTitle.Position;
        titlePosition(1) = 0.34; % Center over the exported chart, including y-axis labels.
        plotTitle.Position = titlePosition;
        figuresFolder = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'figures');
        if ~isfolder(figuresFolder)
            mkdir(figuresFolder);
        end
        exportgraphics(ax,fullfile(figuresFolder,'weight_comp.png'),'Resolution',300);
    end

    %%Data Tables for output.
    %Convert data structure to table
    %T_SizingStruct = structfun(@transpose, SizingStruct, 'UniformOutput', false); %transpose data in structues for ease of reading
    %Msn_Sizing_Table = struct2table(T_SizingStruct);

    % Added in tables for easy display purposes (changes to P/W if prop vs T/W
    % % for jet)
    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')
        %fprintf("Table with Relevant Information\n\n")
        tableNames = {'W0(lb)', 'Wf req internal(lb)', 'Wf total air refuel(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
        outputTable = table(W0_calc,W_f_req_internal,W_f_total_refuel,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);

        %disp(outputTable) %now displayed in seperate display function that
        %displays all output data from sizing.m
    elseif strcmp(PropType,'PROP_Electric')
        tableNames = {'W0(lb)', 'Battery Mass (lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
        outputTable = table(W0_calc,BMF*W0_calc,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);

    else
        % fprintf("Table with Relevant Information\n\n")
        tableNames = {'W0(lb)', 'Wf req internal(lb)', 'Wf total air refuel(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','T/W mil(lb/lb)', 'T/W AB (lb/lb)'};
        outputTable = table(W0_calc,W_f_req_internal,W_f_total_refuel,We,WingLoading,Thrust_Weight_Ratio_mil,Thrust_Weight_Ratio_AB, 'VariableNames', tableNames);
        %disp(outputTable) %now displayed in seperate display function that
        %displays all output data from sizing.m
    end



end














