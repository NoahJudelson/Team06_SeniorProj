function [Weight_Data,CG_Data] = Read_Material_Weight(filename,Config_Row)
% Material weight model for ONE configuration row (header not counted).
% Keep Main_Input, Airfoil_Data and Component_Data in the same row order.
% Weights: lb. Lengths/CG: ft. Areas: ft^2. Bulk densities: lb/ft^3.
% Uses the supplied Weight model: measured weight or density * volume,
% a 1.05 glue/fastener allowance, and weight-averaged CG.

Design_Input = readtable(filename,'Sheet','Main_Input','ReadRowNames',true);
Airfoil = readtable(filename,'Sheet','Airfoil_Data','ReadRowNames',true);
Component_Data = readtable(filename,'Sheet','Component_Data','ReadRowNames',true);
n = Config_Row;
assert(strcmp(Design_Input.Properties.RowNames{n},Airfoil.Properties.RowNames{n}) && ...
    strcmp(Design_Input.Properties.RowNames{n},Component_Data.Properties.RowNames{n}), ...
    'MaterialWeight:Configuration','Config labels must match at the selected row in all three sheets.');
Weight_Factor = 1.05;

% Nose: a zero weight means it is included in the modeled fuselage.
W_nose = Component_Data.W_nose(n);
CG_nose = Component_Data.Xcg_nose(n);

% Fuselage
W_f = Component_Data.W_fuse(n);
if W_f == 0
    material = char(string(Component_Data.Fuse_Mat(n)));
    density = Component_Data.(material)(n);
    W_f = density * Design_Input.Swet_f(n) * Component_Data.Thick_f(n) * Weight_Factor;
end
CG_f = Component_Data.Xcg_fuse(n);
if CG_f == 0
    CG_f = Design_Input.Length_f(n)/2;
end

% Main wing geometry, calculated only when a weight/CG estimate needs it.
W_w = Component_Data.W_wing(n);
CG_w = Component_Data.Xcg_wing(n);
if W_w == 0 || CG_w == 0
    span = sqrt(Design_Input.Sref_w(n)*Design_Input.AR_w(n));
    taper = Design_Input.Taper_w(n);
    rootChord = 2*Design_Input.Sref_w(n)/(span*(1+taper));
    MAC_w = (2/3)*rootChord*(1+taper+taper^2)/(1+taper);
    x_MAC_w = span/6*(1+2*taper)/(1+taper)*tand(Design_Input.Sweep_w(n));
end
if W_w == 0
    material = char(string(Component_Data.Wing_Mat(n)));
    density = Component_Data.(material)(n);
    W_w = density * Design_Input.Sref_w(n) * Airfoil.Thick_w(n) * MAC_w * Weight_Factor;
end
if CG_w == 0
    CG_w = Component_Data.X_LE_wing(n)+x_MAC_w+0.3*MAC_w;
end

% h1 tail (zero area and zero measured weight means absent).
W_h1 = Component_Data.W_h1(n);
CG_h1 = Component_Data.Xcg_h1(n);
if W_h1 == 0 && Design_Input.Sref_h1(n) == 0
    CG_h1 = 0;
else
    if W_h1 == 0
        material = char(string(Component_Data.h1_Mat(n)));
        density = Component_Data.(material)(n);
        W_h1 = density * Design_Input.Sref_h1(n) * Design_Input.MAC_h1(n) * Airfoil.Thick_h1(n) * Weight_Factor;
    end
    if CG_h1 == 0
        CG_h1 = Component_Data.X_LE_h1(n)+0.3*Design_Input.MAC_h1(n);
    end
end

% h2 tail (zero area and zero measured weight means absent).
W_h2 = Component_Data.W_h2(n);
CG_h2 = Component_Data.Xcg_h2(n);
if W_h2 == 0 && Design_Input.Sref_h2(n) == 0
    CG_h2 = 0;
else
    if W_h2 == 0
        material = char(string(Component_Data.h2_Mat(n)));
        density = Component_Data.(material)(n);
        W_h2 = density * Design_Input.Sref_h2(n) * Design_Input.MAC_h2(n) * Airfoil.Thick_h2(n) * Weight_Factor;
    end
    if CG_h2 == 0
        CG_h2 = Component_Data.X_LE_h2(n)+0.3*Design_Input.MAC_h2(n);
    end
end

% v1 tail (zero area and zero measured weight means absent).
W_v1 = Component_Data.W_v1(n);
CG_v1 = Component_Data.Xcg_v1(n);
if W_v1 == 0 && Design_Input.Sref_v1(n) == 0
    CG_v1 = 0;
else
    if W_v1 == 0
        material = char(string(Component_Data.v1_Mat(n)));
        density = Component_Data.(material)(n);
        W_v1 = density * Design_Input.Sref_v1(n) * Design_Input.MAC_v1(n) * Airfoil.Thick_v1(n) * Weight_Factor;
    end
    if CG_v1 == 0
        CG_v1 = Component_Data.X_LE_v1(n)+0.3*Design_Input.MAC_v1(n);
    end
end

% v2 tail (zero area and zero measured weight means absent).
W_v2 = Component_Data.W_v2(n);
CG_v2 = Component_Data.Xcg_v2(n);
if W_v2 == 0 && Design_Input.Sref_v2(n) == 0
    CG_v2 = 0;
else
    if W_v2 == 0
        material = char(string(Component_Data.v2_Mat(n)));
        density = Component_Data.(material)(n);
        W_v2 = density * Design_Input.Sref_v2(n) * Design_Input.MAC_v2(n) * Airfoil.Thick_v2(n) * Weight_Factor;
    end
    if CG_v2 == 0
        CG_v2 = Component_Data.X_LE_v2(n)+0.3*Design_Input.MAC_v2(n);
    end
end

% Directly entered weights and x positions.
W_pay = Component_Data.W_pay(n);
CG_pay = Component_Data.Xcg_pay(n);
W_ballast = Component_Data.W_ballast(n);
CG_ballast = Component_Data.Xcg_ballast(n);
W_systems = Component_Data.W_systems(n);
CG_systems = Component_Data.Xcg_systems(n);

% Empty weight excludes payload; mission sizing adds payload separately.
weights = [W_nose W_f W_w W_h1 W_h2 W_v1 W_v2 W_ballast W_systems];
positions = [CG_nose CG_f CG_w CG_h1 CG_h2 CG_v1 CG_v2 CG_ballast CG_systems];
assert(all(isfinite([weights W_pay])) && all([weights W_pay]>=0) && ...
    all(isfinite([positions CG_pay])) && sum(weights)>0, ...
    'MaterialWeight:InvalidInput','Fill the selected row with valid weights, geometry, densities and CG positions.');
W_empty = sum(weights);
CG_empty = sum(weights.*positions)/W_empty;
Wo = W_empty+W_pay;
CG_tot = (W_empty*CG_empty+W_pay*CG_pay)/Wo;

% One output row, corresponding to Config_Row in the workbook.
Weight_Data = table(Wo,W_empty,W_nose,W_f,W_w,W_h1,W_h2,W_v1,W_v2,W_pay,W_ballast,W_systems);
CG_Data = table(CG_tot,CG_empty,CG_nose,CG_f,CG_w,CG_h1,CG_h2,CG_v1,CG_v2,CG_pay,CG_ballast,CG_systems);
Weight_Data.Properties.RowNames = Design_Input.Properties.RowNames(n);
CG_Data.Properties.RowNames = Design_Input.Properties.RowNames(n);
end
