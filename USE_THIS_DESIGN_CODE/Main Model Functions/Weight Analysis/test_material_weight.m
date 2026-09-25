function test_material_weight
% Check selected-row weights, spar and bulkhead inputs, and the 2x case.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'Read Input Functions'));
source = [tempname '.xlsx'];
target = [tempname '.xlsx'];
cleanup = onCleanup(@() removeFiles(source,target)); %#ok<NASGU>
D = table(["Unused";"Aircraft"],[NaN;10],[NaN;2],[NaN;4], ...
    [NaN;1],[NaN;0],[NaN;0],[NaN;0],[NaN;0],[NaN;0], ...
    'VariableNames',{'Config','Swet_f','Sref_w','AR_w','Taper_w', ...
    'Sweep_w','Sref_h1','Sref_h2','Sref_v1','Sref_v2'});
D.Swet_w = [NaN;sqrt(2)];
A = table(["Unused";"Aircraft"],[NaN;0.1],'VariableNames',{'Config','Thick_w'});
writetable(D,source,'Sheet','Main_Input');
writetable(A,source,'Sheet','Airfoil_Data');
Create_Material_Weight_Template(source,target);
C = readtable(target,'Sheet','Component_Data');
for key = {'nose','fuse','wing','h1','h2','v1','v2','pay','ballast','systems'}
    C.(['W_' key{1}])(2) = 0;
end
C.Fuse_Mat = ["";"rho_LWPLA"];
C.Wing_Mat = ["";"rho_LWPLA"];
C.rho_LWPLA(2) = 10;
C.Thick_f(2) = 0.1;
C.SkinThick_w(2) = 0.1;
C.W_pay(2) = 2;
C.W_systems(2) = 1;
C.W_wing_spar(2) = 0.293;
C.N_wing_spar(2) = 2;
C.N_bulkhead(2) = 3;
C.Width_bulkhead(2) = 0.30;
C.Height_bulkhead(2) = 0.35;
C.Depth_bulkhead(2) = 0.01;
C.rho_LW_balsa(2) = 5.5;
writetable(C,target,'Sheet','Component_Data');
[W,S] = Read_Material_Weight(target,2);
expectedF = 10*10*0.1*1.05;
expectedWing = 10*sqrt(2)*0.1*1.05;
expectedBulkhead = 3*0.30*0.35*0.01*5.5;
assert(height(W)==1 && strcmp(W.Properties.RowNames{1},'Aircraft'));
assert(abs(W.W_empty-(expectedF+expectedWing+1+2*0.293+expectedBulkhead))<1e-10);
assert(abs(W.W_wing_spar-2*0.293)<1e-10);
assert(abs(W.W_bulkhead-expectedBulkhead)<1e-10);
assert(abs(W.Wo-W.W_empty-2)<1e-10);
assert(abs(S.W_empty_2x-W.W_empty-expectedF-expectedWing)<1e-10);

% Non-LWPLA shells and direct spar/bulkhead weights stay fixed in the 2x case.
C.Wing_Mat(2) = "rho_LW_balsa";
C.rho_LW_balsa(2) = 10;
writetable(C,target,'Sheet','Component_Data');
[W,S] = Read_Material_Weight(target,2);
assert(abs(S.W_empty_2x-W.W_empty-expectedF)<1e-10);
C.W_fuse(2) = 1;
C.W_wing(2) = 2;
writetable(C,target,'Sheet','Component_Data');
[W,S] = Read_Material_Weight(target,2);
assert(abs(W.W_empty-(4+2*0.293+3*0.30*0.35*0.01*10))<1e-10);
assert(S.W_empty_2x==W.W_empty);
C.W_bulkhead(2) = 0.5;
writetable(C,target,'Sheet','Component_Data');
[W,~] = Read_Material_Weight(target,2);
assert(W.W_bulkhead==0.5);

% Without an explicit component row, configuration labels must match.
writetable(C([2 1],:),target,'Sheet','Component_Data');
try
    Read_Material_Weight(target,2);
    error('Test:ExpectedFailure','Expected configuration mismatch.');
catch err
    assert(strcmp(err.identifier,'MaterialWeight:Configuration'));
end
disp('Selected-row material weight tests passed.');
end

function removeFiles(varargin)
for k = 1:nargin
    if isfile(varargin{k})
        delete(varargin{k});
    end
end
end
