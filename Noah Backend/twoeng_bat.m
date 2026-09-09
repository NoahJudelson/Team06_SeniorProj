%% Two-Engine Battery Sizing Analysis

%% Housekeeping

clc
clear
close all

%% Aircraft Inputs

W_lb = 55;                 % Aircraft weight [lb]

S = 1.0;                   % Wing area [m^2]

D_front = 0.11;            % Fuselage diameter [m]

A_front = (pi/4)*(D_front^2);  % Fuselage frontal area [m^2]

AR = 7;                    % Aspect ratio

e = 0.75;                  % Oswald efficiency factor

rho = 0.77082;             % Air density at 15,000 ft [kg/m^3]


%% Drag Coefficients

CD0_fuse_front = 0.20;     % Fuselage CD0 referenced to frontal area

CD0_fuse_wing = CD0_fuse_front*(A_front/S);

CD0_wing_other = 0.0200;   % Wing + tail + other parasite drag

CD0 = CD0_fuse_wing + CD0_wing_other;


%% Mission Requirements

V_top_mph = 150;           % Required maximum speed [mph]

time_top_min = 10;         % Time spent at maximum speed [min]

time_top_hr = time_top_min/60;


%% Propulsion System

num_motors = 2;

eta_prop = 0.70;           % Propeller efficiency

eta_motor = 0.90;          % Motor/controller efficiency


%% Battery

battery_usable_fraction = 0.80;

battery_energy_density = 330;   % Battery specific energy [Wh/kg]


%% Conversions

W = W_lb*4.44822;          % Weight [N]

V_top = V_top_mph*0.44704; % Maximum speed [m/s]


%% Aerodynamics at Maximum Speed

q_top = 0.5*rho*V_top^2;

CL_top = W/(q_top*S);

CDi_top = CL_top^2/(pi*e*AR);

CD_top = CD0 + CDi_top;

D_top = q_top*S*CD_top;


%% Total Power Required at Maximum Speed

P_aero_total = D_top*V_top;

P_battery_total = P_aero_total/(eta_prop*eta_motor);


%% Two-Motor Power Split

P_aero_per_motor = P_aero_total/num_motors;

P_battery_per_motor = P_battery_total/num_motors;


%% Battery Energy for 10 Minutes at Maximum Speed

E_top = P_battery_total*time_top_hr;

E_battery = E_top/battery_usable_fraction;

battery_mass_kg = E_battery/battery_energy_density;

battery_mass_lb = battery_mass_kg*2.205;

P_shaft_total = P_aero_total / eta_prop;

P_shaft_per_motor = P_shaft_total / num_motors;

P_electrical_per_motor = P_battery_total / num_motors;


%% Results

fprintf('\n----- TWO ENGINE TOP-SPEED ANALYSIS -----\n\n')

fprintf('Maximum Speed = %.0f mph\n', V_top_mph)

fprintf('Time at Maximum Speed = %.1f min\n\n', time_top_min)

fprintf('CL = %.3f\n', CL_top)

fprintf('CD = %.4f\n', CD_top)

fprintf('Drag = %.1f N\n\n', D_top)

fprintf('Total Aerodynamic Power = %.0f W\n', P_aero_total)

fprintf('Total Battery Power = %.0f W\n\n', P_battery_total)

fprintf('Number of Motors = %d\n', num_motors)

fprintf('Aerodynamic Power per Motor = %.0f W\n', P_aero_per_motor)

fprintf('Electrical Power per Motor = %.0f W\n\n', P_battery_per_motor)

fprintf('Energy Required for %.0f min at Top Speed = %.0f Wh\n', ...
    time_top_min, E_top)

fprintf('Required Rated Battery Energy = %.0f Wh\n', E_battery)

fprintf('Battery Mass = %.2f kg\n', battery_mass_kg)

fprintf('Battery Mass = %.2f lb\n', battery_mass_lb)

fprintf('Shaft Power per Motor = %.0f W\n', P_shaft_per_motor)
fprintf('Electrical Power per Motor = %.0f W\n', P_electrical_per_motor)


%% Mission Time Study

% Analyze 1 to 90 minutes at maximum speed
time_range_min = 1:1:90;

% Preallocate arrays
E_required_range = zeros(size(time_range_min));
E_battery_range = zeros(size(time_range_min));
battery_mass_range_kg = zeros(size(time_range_min));
battery_mass_range_lb = zeros(size(time_range_min));

% Calculate battery requirements for each mission time
for i = 1:length(time_range_min)

    time_hr_i = time_range_min(i)/60;

    % Actual electrical energy required
    E_required_range(i) = P_battery_total*time_hr_i;

    % Rated battery energy including usable fraction
    E_battery_range(i) = E_required_range(i)/battery_usable_fraction;

    % Battery mass
    battery_mass_range_kg(i) = ...
        E_battery_range(i)/battery_energy_density;

    battery_mass_range_lb(i) = ...
        battery_mass_range_kg(i)*2.205;

end


%% Plot 1 - Battery Energy vs Time at Maximum Speed

figure

plot(time_range_min,E_battery_range,'LineWidth',2)

hold on

plot(time_top_min,E_battery,'o','MarkerSize',8,'LineWidth',2)

xline(time_top_min,'--','10 min')

grid on

xlabel('Time at 150 mph [min]')

ylabel('Required Rated Battery Energy [Wh]')

title('Battery Energy Required vs Time at Maximum Speed')

legend('Required Battery Energy','10-Minute Design Point', ...
    'Location','southeast')


%% Plot 2 - Battery Mass vs Time at Maximum Speed

figure

plot(time_range_min,battery_mass_range_lb,'LineWidth',2)

hold on

plot(time_top_min,battery_mass_lb,'o','MarkerSize',8,'LineWidth',2)

xline(time_top_min,'--','10 min')

yline(W_lb,'--','55 lb Aircraft Weight Limit')

grid on

xlabel('Time at 150 mph [min]')

ylabel('Required Battery Mass [lb]')

title('Battery Mass vs Time at Maximum Speed')

legend('Required Battery Mass', ...
       '10-Minute Design Point', ...
       'Location','southeast')