function [Climb_bm_fraction,CLIMB_DATA,msgs] = MSN_SEG_Climb_Elec(Climb_Alt_Start,Climb_Alt_End,Climb_Mach_Start,Climb_Mach_End,CDx_Climb,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Models battery mass fraction used during a climb misson segment.
    %   Detailed explanation goes here

    % Unpack Constants

    Config_Row = Constants{1,1};
    Sref = Constants{1,3};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Prop_Eff = Propulsion_Input.Prop_eff(Config_Row);
    Esb_Real=Propulsion_Input.Esb_Real(Config_Row);%specific energy of battery after losses (Whr/kg)
    nb2s=Propulsion_Input.eta_b2s(Config_Row);%accounts for losses from battery to shaft


    % convert units
    Sref=Sref*(1/3.281)^2;
    g=g/3.281;
    Climb_Alt_Start=Climb_Alt_Start/3.281;
    Climb_Alt_End=Climb_Alt_End/3.281;
    W_start=W_start*4.44822;

    % MSN SEGMENT TYPE: Climb Weight Fraction Model
    %Average Climb Segment Alt and Mach
    Climb_Alt_Avg = (Climb_Alt_End+Climb_Alt_Start)/2; %Average altitude during climb segment (m)
    Climb_Mach_Avg = (Climb_Mach_End+Climb_Mach_Start)/2; %



    %Climb Atmospheric Properties
    [rho,a,~,~,~,~] = atmos(Climb_Alt_Avg);
    [~,a_start,~,~,~,~] = atmos(Climb_Alt_Start);
    [~,a_end,~,~,~,~] = atmos(Climb_Alt_End);

    %Climb Weight Fraction Model (Raymer Eq 19.8,19.9)
    %Change in Energy Height
    Climb_Vel_Start = Climb_Mach_Start*a_start; %m/s
    Climb_Vel_End = Climb_Mach_End*a_end; %m/s
    Climb_Vel_Avg = Climb_Mach_Avg*a; %m/s
    Delta_he = (Climb_Alt_End+(Climb_Vel_End)^2/(2*g))-(Climb_Alt_Start+(Climb_Vel_Start)^2/(2*g)); %Change in enegy height (m)

    %Average Drag
    Climb_CL = W_start/(0.5*rho*Climb_Vel_Avg^2*Sref); %Assuming L ~ W at start of climb
    [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Climb_Mach_Avg,Climb_CL,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    CD = CD+CDx_Climb; %Add any external parasite drag
    D = (CD)*(0.5*rho*Climb_Vel_Avg^2*Sref); %Average Drag (N)


    if strcmp(PropType,'PROP_Electric')

        %Average Thrust or Power & TSFC or SFC
        %%NOTE INPUTS TO THIS FUNCTION HAVE TO BE IN US CUSTOMARY UNITS
        %conversions back done inline
        %output PA_max output for electric will be in units of W

        [~,~,~,~,~,~,~,PA_max,~,~,msgs] =...
            Propulsion(Climb_Alt_Avg*3.281,Climb_Mach_Avg,Config_Row,Propulsion_Input,msgs);



        P_req=Climb_Vel_Avg*D;
        assert(PA_max>P_req,'Sizing:ClimbPower', ...
            'Climb requires positive excess power: drag power %.1f W, available propulsive power %.1f W.',P_req,PA_max);
        SpecificExcessPower = (PA_max-P_req)/W_start; %Energy-height rate, m/s
        assert(isfinite(Delta_he) && Delta_he>=0,'Sizing:ClimbEnergy', ...
            'Climb energy-height change must be finite and nonnegative.');
        TOC = (Delta_he/SpecificExcessPower)/60; %Minutes; includes acceleration
        ROC = 0;
        if TOC>0
            ROC = (Climb_Alt_End-Climb_Alt_Start)/(TOC*60); %Altitude rate, m/s
        end
        T = PA_max/Climb_Vel_Avg; %Calculate average thrust during climb out and acceleration

        %Climb Weight Fraction Model
        % Full-power energy includes drag work and potential/kinetic energy:
        % PA_max*t = D*V*t + W_start*Delta_he (J). TOC/60 is hours.
        Climb_bm_fraction=PA_max*(TOC/60)/(Esb_Real*nb2s*Prop_Eff*(W_start/g));


    else
        error("Only PROP_Electric propulsion types supported.")

    end

    %Record Climb Performance Data
    C=0; %C=TSFC
    %conversions back to imperial units done inline
    CLIMB_DATA= table(Delta_he*3.281,Climb_CL,CD,CDo_msn,k1_msn,k2_msn,D/4.448,T/4.448,C,ROC*3.281,TOC, ...
        'VariableNames',{'Energy Height Change [ft]','CL','CD','CDo','k1','k2', ...
        'Drag [lbf]','Thrust [lbf]','SFC','Rate of Climb [ft/s]','Time of Climb [min]'});

end
