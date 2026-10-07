function [Weight_Data,Weight_Sensitivity] = Read_Material_Weight(filename,Config_Row,Component_Row,WeightPlotsOn)
% Component weights in lb; geometry in ft/ft^2; density in lb/ft^3.
% Positive entered weights override estimates. Blank weights mean zero.
% Omit Component_Row to require matching labels across all three sheets.
% WeightPlotsOn defaults to true; false skips plotting and PNG export.
if nargin < 4
    WeightPlotsOn = true;
end
validateattributes(WeightPlotsOn,{'numeric','logical'},{'scalar','binary'});
D = readtable(filename,'Sheet','Main_Input','ReadRowNames',true);
A = readtable(filename,'Sheet','Airfoil_Data','ReadRowNames',true);
C = readtable(filename,'Sheet','Component_Data','ReadRowNames',true);
if nargin < 3
    Component_Row = Config_Row;
end
validateattributes(Config_Row,{'numeric'},{'scalar','integer','positive','<=',min(height(D),height(A))});
validateattributes(Component_Row,{'numeric'},{'scalar','integer','positive','<=',height(C)});
assert(strcmp(D.Properties.RowNames{Config_Row},A.Properties.RowNames{Config_Row}), ...
    'MaterialWeight:Configuration','Main_Input and Airfoil_Data labels must match at the selected row.');
if nargin < 3
    assert(strcmp(D.Properties.RowNames{Config_Row},C.Properties.RowNames{Component_Row}), ...
        'MaterialWeight:Configuration','Component_Data label differs. Supply its row as the third argument.');
end
D = D(Config_Row,:);
C = C(Component_Row,:);

% Read all entered weights once; normalize blanks before doing arithmetic.
weightNames = {'W_nose','W_fuse','W_wing','W_h1','W_h2','W_v1','W_v2', ...
    'W_wing_spar','W_bulkhead','W_pay','W_ballast','W_systems'};
entered = C{1,weightNames};
entered(ismissing(entered)) = 0;
validateattributes(entered,{'numeric'},{'real','finite','nonnegative'});
C{1,weightNames} = entered;

% Shells: measured weight, or 1.05 * density * wetted area * thickness.
% Each shell also returns the extra weight when its LWPLA thickness doubles.
[W_f,F_added] = shellWeight(D,C,'W_fuse','Fuse_Mat','Swet_f','Thick_f');
[W_w,W_added] = shellWeight(D,C,'W_wing','Wing_Mat','Swet_w','SkinThick_w');
[W_h1,H1_added] = shellWeight(D,C,'W_h1','h1_Mat','Swet_h1','SkinThick_h1','Sref_h1');
[W_h2,H2_added] = shellWeight(D,C,'W_h2','h2_Mat','Swet_h2','SkinThick_h2','Sref_h2');
[W_v1,V1_added] = shellWeight(D,C,'W_v1','v1_Mat','Swet_v1','SkinThick_v1','Sref_v1');
[W_v2,V2_added] = shellWeight(D,C,'W_v2','v2_Mat','Swet_v2','SkinThick_v2','Sref_v2');

% W_wing_spar is the measured weight of one spar.
assert(ismember('N_wing_spar',C.Properties.VariableNames), ...
    'MaterialWeight:MissingSparCount','Component_Data needs an N_wing_spar column.');
validateattributes(C.N_wing_spar,{'numeric'},{'scalar','integer','finite','nonnegative'});
W_wing_spar = C.N_wing_spar * C.W_wing_spar;

% Bulkheads are solid rectangular prisms, unless their total is measured.
W_bulkhead = C.W_bulkhead;
if W_bulkhead == 0
    material = char(string(C.Bulkhead_Mat));
    assert(ismember(material,C.Properties.VariableNames), ...
        'MaterialWeight:BulkheadMaterial','Bulkhead_Mat must name a density column.');
    density = C.(material);
    validateattributes(C.N_bulkhead,{'numeric'},{'scalar','integer','finite','nonnegative'});
    dimensions = [C.Width_bulkhead C.Height_bulkhead C.Depth_bulkhead density];
    validateattributes(dimensions,{'numeric'},{'real','finite','nonnegative'});
    W_bulkhead = C.N_bulkhead * C.Width_bulkhead * C.Height_bulkhead * C.Depth_bulkhead * density;
end

% Payload and the mission battery are excluded from empty weight.
W_empty = C.W_nose + W_f + W_w + W_h1 + W_h2 + W_v1 + W_v2 ...
    + W_wing_spar + W_bulkhead + C.W_ballast + C.W_systems;
assert(W_empty>0,'MaterialWeight:InvalidInput','Empty weight must be positive.');
Wo = W_empty + C.W_pay;
Weight_Data = table(Wo,W_empty,C.W_nose,W_f,W_w,W_h1,W_h2,W_v1,W_v2, ...
    W_wing_spar,W_bulkhead,C.W_pay,C.W_ballast,C.W_systems, ...
    'VariableNames',{'Wo','W_empty','W_nose','W_f','W_w','W_h1','W_h2','W_v1','W_v2', ...
    'W_wing_spar','W_bulkhead','W_pay','W_ballast','W_systems'});
Weight_Data.Properties.RowNames = D.Properties.RowNames;
Skin_weight_added = F_added + W_added + H1_added + H2_added + V1_added + V2_added;
Weight_Sensitivity = table(W_empty,W_empty+Skin_weight_added,Skin_weight_added, ...
    'VariableNames',{'W_empty_nominal','W_empty_2x','Skin_weight_added'});

if WeightPlotsOn
    plotComponentWeights(Weight_Data,C.N_wing_spar,C.N_bulkhead);
end
end

function [weight,added] = shellWeight(D,C,weightName,materialName,areaName,thicknessName,tailAreaName)
weight = C.(weightName);
added = 0;
if weight > 0
    return
end
% A tail with zero reference area is absent; its material inputs are unused.
if nargin == 7
    validateattributes(D.(tailAreaName),{'numeric'},{'scalar','real','finite','nonnegative'});
    if D.(tailAreaName) == 0
        return
    end
end
area = D.(areaName);
validateattributes(area,{'numeric'},{'scalar','real','finite','nonnegative'});
if area == 0
    return
end
material = char(string(C.(materialName)));
density = C.(material);
validateattributes(density,{'numeric'},{'scalar','real','finite','nonnegative'});

% Missing or invalid thickness uses the original 2.5 mm default in feet.
thickness = 0.0025 / 0.3048;
if ismember(thicknessName,C.Properties.VariableNames)
    value = C.(thicknessName);
    if iscell(value)
        value = value{1};
    end
    if isstring(value) || ischar(value)
        value = str2double(value);
    end
    if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && value > 0
        thickness = value;
    end
end
weight = density * area * thickness * 1.05;
validateattributes(weight,{'numeric'},{'scalar','real','finite','nonnegative'});
if strcmp(material,'rho_LWPLA')
    added = weight;
end
end
