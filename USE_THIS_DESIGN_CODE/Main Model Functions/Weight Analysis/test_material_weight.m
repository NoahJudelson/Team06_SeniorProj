function test_material_weight
% Verify selected-row behavior, bulk material equations and payload moments.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'Read Input Functions'));
source = [tempname '.xlsx'];
target = [tempname '.xlsx'];
cleanup = onCleanup(@() removeFiles(source,target)); %#ok<NASGU>
D = table(["Unused";"Aircraft"],[NaN;10],[NaN;2],[NaN;4], ...
    [NaN;1],[NaN;0],[NaN;0],[NaN;0],[NaN;0],[NaN;0],[NaN;6], ...
    'VariableNames',{'Config','Swet_f','Sref_w','AR_w','Taper_w', ...
    'Sweep_w','Sref_h1','Sref_h2','Sref_v1','Sref_v2','Length_f'});
A = table(["Unused";"Aircraft"],[NaN;0.1],'VariableNames',{'Config','Thick_w'});
writetable(D,source,'Sheet','Main_Input');
writetable(A,source,'Sheet','Airfoil_Data');
Create_Material_Weight_Template(source,target);
C = readtable(target,'Sheet','Component_Data');
for key = {'nose','fuse','wing','h1','h2','v1','v2','pay','ballast','systems'}
    C.(['W_' key{1}])(2) = 0;
    C.(['Xcg_' key{1}])(2) = 0;
end
C.Fuse_Mat = ["";"rho_LWPLA"];
C.Wing_Mat = ["";"rho_LWPLA"];
C.rho_LWPLA(2) = 10;
C.Thick_f(2) = 0.1;
C.X_LE_wing(2) = 2;
C.W_pay(2) = 2;
C.Xcg_pay(2) = 4;
C.W_systems(2) = 1;
C.Xcg_systems(2) = 1;
writetable(C,target,'Sheet','Component_Data');
[W,X] = Read_Material_Weight(target,2);
chord = sqrt(2/4);
expectedF = 10*10*0.1*1.05;
expectedWing = 10*2*chord*0.1*1.05;
assert(height(W)==1 && strcmp(W.Properties.RowNames{1},'Aircraft'));
assert(abs(W.W_empty-(expectedF+expectedWing+1))<1e-10);
assert(abs(X.CG_w-(2+0.3*chord))<1e-10);
assert(abs(X.CG_empty-(expectedF*3+expectedWing*X.CG_w+1)/W.W_empty)<1e-10);
assert(abs(X.CG_tot-(W.W_empty*X.CG_empty+2*4)/W.Wo)<1e-10);
C.Xcg_pay(2) = 6;
writetable(C,target,'Sheet','Component_Data');
[W2,X2] = Read_Material_Weight(target,2);
assert(W2.W_empty==W.W_empty && X2.CG_empty==X.CG_empty);
assert(abs(X2.CG_tot-X.CG_tot-2*W.W_pay/W.Wo)<1e-10);
% Measured weights bypass material estimates and the glue allowance.
C.W_fuse(2) = 1;
C.W_wing(2) = 2;
C.Xcg_fuse(2) = 2;
C.Xcg_wing(2) = 3;
writetable(C,target,'Sheet','Component_Data');
[W,X] = Read_Material_Weight(target,2);
assert(W.W_empty==4 && X.CG_empty==2.25);
% Do not silently remap a differently ordered component sheet.
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
