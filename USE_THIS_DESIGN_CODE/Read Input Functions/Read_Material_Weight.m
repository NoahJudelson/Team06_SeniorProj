function [W_empty,W_pay] = Read_Material_Weight(filename,Config_Row,Component_Row,WeightPlotsOn)
% Weights in lb; density in lb/ft^3; wetted area in ft^2; thickness in ft.
if nargin < 4
    WeightPlotsOn = true;
end
if nargin < 3
    Component_Row = Config_Row;
end
validateattributes(WeightPlotsOn,{'numeric','logical'},{'scalar','binary'});
D = readtable(filename,'Sheet','Main_Input','ReadRowNames',true);
C = readtable(filename,'Sheet','Component_Data','ReadRowNames',true);
validateattributes(Config_Row,{'numeric'},{'scalar','integer','positive','<=',height(D)});
validateattributes(Component_Row,{'numeric'},{'scalar','integer','positive','<=',height(C)});
D = D(Config_Row,:);
C = C(Component_Row,:);

% Empty-weight components: nose, six shells, spars, bulkheads, ballast, systems.
weights = C{1,{'W_nose','W_fuse','W_wing','W_h1','W_h2','W_v1','W_v2', ...
    'W_wing_spar','W_bulkhead','W_ballast','W_systems'}};
weights(ismissing(weights)) = 0; % Intentionally blank weight inputs mean zero.
validateattributes(weights,{'numeric'},{'real','finite','nonnegative'});
materialNames = {'Fuse_Mat','Wing_Mat','h1_Mat','h2_Mat','v1_Mat','v2_Mat'};
areaNames = {'Swet_f','Swet_w','Swet_h1','Swet_h2','Swet_v1','Swet_v2'};
thicknessNames = {'Thick_f','SkinThick_w','SkinThick_h1','SkinThick_h2','SkinThick_v1','SkinThick_v2'};
tailAreaNames = {'Sref_h1','Sref_h2','Sref_v1','Sref_v2'};
for k = 1:6
    if weights(k+1) > 0
        continue % A measured shell bypasses geometry, material and margin.
    end
    if k >= 3
        tailArea = D{1,tailAreaNames{k-2}};
        validateattributes(tailArea,{'numeric'},{'scalar','real','finite','nonnegative'});
        if tailArea == 0
            continue % Absent tails need no material or thickness inputs.
        end
    end
    area = D{1,areaNames{k}};
    validateattributes(area,{'numeric'},{'scalar','real','finite','nonnegative'});
    if area == 0
        continue
    end
    material = char(string(C{1,materialNames{k}}));
    assert(ismember(material,C.Properties.VariableNames), ...
        'MaterialWeight:Material','%s must name a density column.',materialNames{k});
    density = C{1,material};
    validateattributes(density,{'numeric'},{'scalar','real','finite','nonnegative'});
    thickness = 0.0025/0.3048; % Original 2.5 mm default, converted to ft.
    if ismember(thicknessNames{k},C.Properties.VariableNames)
        value = C{1,thicknessNames{k}};
        if iscell(value), value = value{1}; end
        if ischar(value) || isstring(value), value = str2double(value); end
        if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && value > 0
            thickness = value;
        end
    end
    weights(k+1) = density * area * thickness * 1.05;
    validateattributes(weights(k+1),{'numeric'},{'scalar','real','finite','nonnegative'});
end

% Spar input is lb per spar; bulkhead override is the total measured weight.
validateattributes(C.N_wing_spar,{'numeric'},{'scalar','integer','finite','nonnegative'});
weights(8) = C.N_wing_spar * weights(8);
if weights(9) == 0
    material = char(string(C.Bulkhead_Mat));
    assert(ismember(material,C.Properties.VariableNames), ...
        'MaterialWeight:BulkheadMaterial','Bulkhead_Mat must name a density column.');
    density = C{1,material};
    validateattributes(C.N_bulkhead,{'numeric'},{'scalar','integer','finite','nonnegative'});
    validateattributes([C.Width_bulkhead C.Height_bulkhead C.Depth_bulkhead density], ...
        {'numeric'},{'real','finite','nonnegative'});
    weights(9) = C.N_bulkhead * C.Width_bulkhead * C.Height_bulkhead * C.Depth_bulkhead * density;
end
W_empty = sum(weights); % Payload, mission battery and fuel are excluded.
assert(W_empty>0,'MaterialWeight:InvalidInput','Empty weight must be positive.');
W_pay = C.W_pay;
if ismissing(W_pay), W_pay = 0; end
validateattributes(W_pay,{'numeric'},{'scalar','real','finite','nonnegative'});

if WeightPlotsOn
    sparLabel = sprintf('%d Wing Spars',C.N_wing_spar);
    if C.N_wing_spar == 1
        sparLabel = '1 Wing Spar';
    end
    labels = {'Nose','Fuselage','Wing','Horizontal Tail 1','Horizontal Tail 2', ...
        'Vertical Tail 1','Vertical Tail 2',sparLabel,sprintf('%d Bulkheads',C.N_bulkhead), ...
        'Ballast','Systems','Payload'};
    [plotWeights,order] = sort([weights W_pay]);
    labels = labels(order(plotWeights>0));
    plotWeights = plotWeights(plotWeights>0);
    figure(700); clf;
    barh(plotWeights);
    set(gca,'YTick',1:numel(plotWeights),'YTickLabel',labels,'YDir','reverse');
    xlabel('Weight [lb]');
    title('JoyBringer Component Weight Breakdown');
    text(plotWeights,1:numel(plotWeights),compose('  %.2g lb',plotWeights));
end
end
