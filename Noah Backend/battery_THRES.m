%% Housekeeping
clc
clear
close all

%% Inputs
W_lb = 55;          % Aircraft weight [lb]
S = 1;              % Wing area [m^2]
D_front = 0.11;     % Fuselage diameter [m]
A_front = (pi / 4) * (D_front^2);     % Fuselage cross-sectional area [m^2]
AR = 7;             % Aspect ratio
e = 0.75;           % Oswald efficiency factor

% Drag coefficients
CD0_fuse_front = 0.20;            % Pessimistic fuselage CD0 (frontal area based)
CD0_fuse_wing = CD0_fuse_front * (A_front / S); % Fuselage CD0 scaled to wing area
CD0_wing_other = 0.0200;          % Wing profile + tail/parasite drag estimate
CD0 = CD0_fuse_wing + CD0_wing_other; % Total aircraft zero-lift drag referenced to S

V_mph = 125;        % Cruise speed [mph]
rho = 0.8491;       % Air density at 12,000 ft [kg/m^3]
time_hr = 1.0;      % Cruise duration [hr]
eta_prop = 0.70;    % Propeller efficiency
eta_motor = 0.90;   % Motor/controller efficiency
battery_usable_fraction = 0.80;   % Fraction of rated battery energy usable
battery_energy_density = 330;     % Battery specific energy [Wh/kg]

%% Conversions
W = W_lb * 4.44822;     % Weight [N]
V = V_mph * 0.44704;    % Speed [m/s]

%% Aerodynamics
q = 0.5 * rho * V^2;
CL = W / (q * S);
CDi = CL^2 / (pi * e * AR);
CD = CD0 + CDi;
D = q * S * CD;

%% Power
P_aero = D * V;
P_battery = P_aero / (eta_prop * eta_motor);

%% Battery energy
E_cruise = P_battery * time_hr;                 % Energy actually required [Wh]
E_battery = E_cruise / battery_usable_fraction; % Required rated pack energy [Wh]
battery_mass_kg = E_battery / battery_energy_density;
battery_mass_lb = battery_mass_kg * 2.205;

%% Results
fprintf('CL = %.3f\n', CL)
fprintf('CD = %.4f\n', CD)
fprintf('Drag = %.1f N\n', D)
fprintf('Aerodynamic Power = %.0f W\n', P_aero)
fprintf('Battery Power = %.0f W\n', P_battery)
fprintf('Cruise Energy Required = %.0f Wh\n', E_cruise)
fprintf('Rated Battery Energy = %.0f Wh\n', E_battery)
fprintf('Battery Mass = %.1f kg\n', battery_mass_kg)
fprintf('Battery Mass = %.1f lb\n', battery_mass_lb)