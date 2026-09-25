function [Weight_Data,Weight_Sensitivity] = Read_Material_Weight(filename,Config_Row,Component_Row)
% Selected-row material weights: lb, ft, ft^2, and density in lb/ft^3.
% Config_Row selects geometry/airfoil data; Component_Row selects components.
% Omit Component_Row to require matching configuration labels on all sheets.
D = readtable(filename,'Sheet','Main_Input','ReadRowNames',true);
A = readtable(filename,'Sheet','Airfoil_Data','ReadRowNames',true);
C = readtable(filename,'Sheet','Component_Data','ReadRowNames',true);
separateComponentRow = nargin>=3;
if ~separateComponentRow
    Component_Row = Config_Row;
end
validateattributes(Config_Row,{'numeric'},{'scalar','integer','positive','<=',min(height(D),height(A))});
validateattributes(Component_Row,{'numeric'},{'scalar','integer','positive','<=',height(C)});
assert(strcmp(D.Properties.RowNames{Config_Row},A.Properties.RowNames{Config_Row}), ...
    'MaterialWeight:Configuration','Main_Input and Airfoil_Data labels must match at the selected row.');
if ~separateComponentRow
    assert(strcmp(D.Properties.RowNames{Config_Row},C.Properties.RowNames{Component_Row}), ...
        'MaterialWeight:Configuration','Component_Data label differs. Supply its row as the third argument.');
end
D = D(Config_Row,:);
C = C(Component_Row,:);

% Structural components share one shell equation and independent thicknesses.
keys = {'fuse','wing','h1','h2','v1','v2'};
materials = {'Fuse_Mat','Wing_Mat','h1_Mat','h2_Mat','v1_Mat','v2_Mat'};
areas = {'Swet_f','Swet_w','Swet_h1','Swet_h2','Swet_v1','Swet_v2'};
thicknesses = {'Thick_f','SkinThick_w','SkinThick_h1','SkinThick_h2','SkinThick_v1','SkinThick_v2'};
structuralWeights = zeros(1,6);
lwplaSkinWeight = 0;
for k = 1:numel(keys)
    weight = inputWeight(C,['W_' keys{k}]);
    if weight==0 && k>=3
        area = D.(['Sref_' keys{k}])(1);
        validateattributes(area,{'numeric'},{'scalar','real','finite','nonnegative'});
        if area==0
            continue % An unmeasured tail with no area is absent.
        end
    end
    measured = weight>0;
    weight = componentWeight(D,C,weight,materials{k},areas{k},thicknesses{k});
    if ~measured && strcmp(string(C.(materials{k})(1)),"rho_LWPLA")
        lwplaSkinWeight = lwplaSkinWeight + weight;
    end
    structuralWeights(k) = weight;
end

% Solid bulkhead prisms: count * width * height * depth * density.
bulkheadWeight = inputWeight(C,'W_bulkhead');
if bulkheadWeight==0
    count = C.N_bulkhead(1);
    panelWidth = C.Width_bulkhead(1);
    panelHeight = C.Height_bulkhead(1);
    panelDepth = C.Depth_bulkhead(1);
    material = char(string(C.Bulkhead_Mat(1)));
    assert(ismember(material,C.Properties.VariableNames), ...
        'MaterialWeight:BulkheadMaterial','Bulkhead_Mat must name a density column.');
    density = C.(material)(1);
    validateattributes(count,{'numeric'},{'scalar','integer','nonnegative'},mfilename,'N_bulkhead');
    validateattributes(panelWidth,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,'Width_bulkhead');
    validateattributes(panelHeight,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,'Height_bulkhead');
    validateattributes(panelDepth,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,'Depth_bulkhead');
    validateattributes(density,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,material);
    bulkheadWeight = count*panelWidth*panelHeight*panelDepth*density;
end
% Spar input is the weight of one spar; the spreadsheet sets the count.
assert(ismember('N_wing_spar',C.Properties.VariableNames), ...
    'MaterialWeight:MissingSparCount','Component_Data needs an N_wing_spar column.');
sparCount = C.N_wing_spar(1);
validateattributes(sparCount,{'numeric'},{'scalar','integer','nonnegative','finite'},mfilename,'N_wing_spar');
sparWeight = sparCount*inputWeight(C,'W_wing_spar');

% Nose, payload, ballast and systems are direct inputs (blank means zero).
% A zero nose weight means the nose is included in the fuselage shell.
directKeys = {'nose','pay','ballast','systems'};
directWeights = zeros(1,4);
for k = 1:numel(directKeys)
    directWeights(k) = inputWeight(C,['W_' directKeys{k}]);
end
weights = [directWeights(1) structuralWeights sparWeight bulkheadWeight directWeights(3:4)];
W_pay = directWeights(2);
W_empty = sum(weights);
assert(W_empty>0,'MaterialWeight:InvalidInput','Empty weight must be positive.');
Wo = W_empty+W_pay;

Weight_Data = array2table([Wo W_empty weights(1:9) W_pay weights(10:11)], ...
    'VariableNames',{'Wo','W_empty','W_nose','W_f','W_w','W_h1','W_h2','W_v1','W_v2','W_wing_spar','W_bulkhead','W_pay','W_ballast','W_systems'});
% 2x LWPLA skin-thickness sensitivity case; nominal sizing is unchanged.
Weight_Sensitivity = table(W_empty,W_empty+lwplaSkinWeight,lwplaSkinWeight, ...
    'VariableNames',{'W_empty_nominal','W_empty_2x','Skin_weight_added'});
Weight_Data.Properties.RowNames = D.Properties.RowNames;

% Component breakdown for the selected configuration (before battery sizing).
sparLabel = sprintf('%d Wing Spars',sparCount);
if sparCount==1
    sparLabel = '1 Wing Spar';
end
componentLabels = {'Nose','Fuselage','Wing','Horizontal Tail 1','Horizontal Tail 2', ...
    'Vertical Tail 1','Vertical Tail 2',sparLabel,sprintf('%d Bulkheads',C.N_bulkhead(1)),'Payload','Ballast','Systems'};
componentWeights = Weight_Data{1,3:end};
nonzeroComponents = componentWeights > 0;
componentLabels = componentLabels(nonzeroComponents);
componentWeights = componentWeights(nonzeroComponents);
[componentWeights,sortOrder] = sort(componentWeights,'ascend');
componentLabels = componentLabels(sortOrder);
[~,ax] = weightPlotAxes('component');
barh(ax,componentWeights,0.65,'FaceColor',[0.20 0.45 0.75]);
set(ax,'YTick',1:numel(componentLabels),'YTickLabel',componentLabels, ...
    'YDir','reverse','TickLabelInterpreter','none','FontSize',24, ...
    'Box','off','Layer','bottom');
ax.Position = [0.27 0.18 0.66 0.68];
text(ax,componentWeights,1:numel(componentWeights),compose('  %.2g lb',componentWeights), ...
    'FontSize',26,'Color',[0.15 0.18 0.22]);
xlim(ax,[0 1.30*max(componentWeights)]);
ylim(ax,[0.5 numel(componentWeights)+0.5]);
xtickformat(ax,'%.2g');
ax.XGrid = 'on';
ax.YGrid = 'off';
ax.GridColor = [0.82 0.86 0.90];
ax.GridAlpha = 0.25;
xlabel(ax,'Weight [lb]','FontSize',26);
title(ax,'JoyBringer Component Weight Breakdown','FontSize',24);
figuresFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))),'figures');
if ~isfolder(figuresFolder)
    mkdir(figuresFolder);
end
exportgraphics(ax,fullfile(figuresFolder,'component_weight_breakdown.png'),'Resolution',300);
end

function weight = inputWeight(C,name)
weight = C.(name)(1);
if ismissing(weight)
    weight = 0;
end
validateattributes(weight,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,name);
end

function weight = componentWeight(D,C,weight,materialName,areaName,thicknessName)
if weight>0
    return % Measured weight bypasses geometry/material inputs and the 1.05 factor.
end
area = D.(areaName)(1);
validateattributes(area,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,areaName);
if area==0
    return
end
material = char(string(C.(materialName)(1)));
density = C.(material)(1);
validateattributes(density,{'numeric'},{'scalar','real','finite','nonnegative'},mfilename,material);
weight = density * area * skinThickness(C,thicknessName) * 1.05;
validateattributes(weight,{'numeric'},{'scalar','real','finite','nonnegative'});
end

function thickness = skinThickness(C,name)
DEFAULT_SKIN_THICKNESS_FT = 0.0025 / 0.3048;
thickness = DEFAULT_SKIN_THICKNESS_FT;
if ismember(name,C.Properties.VariableNames)
    value = C.(name)(1);
    if iscell(value)
        value = value{1};
    end
    if isstring(value) || ischar(value)
        value = str2double(value);
    end
    if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && value>0
        thickness = value;
    end
end
end
