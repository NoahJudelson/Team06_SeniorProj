function Create_Material_Weight_Template(sourceFile,outputFile)
% Copy an existing design workbook and add material-weight input sheet.
% NaN entries are deliberately blank in Excel and must be filled by the user.
assert(~isfile(outputFile),'MaterialWeight:FileExists', ...
    'Choose a new output filename; existing workbooks are not overwritten.');
D = readtable(sourceFile,'Sheet','Main_Input','ReadRowNames',true);
existing = sheetnames(sourceFile);
assert(~any(ismember(existing,["Component_Data","Material_Data"])), ...
    'MaterialWeight:ExistingSheets','Source already contains material input sheet.');
C = table(string(D.Properties.RowNames),'VariableNames',{'Config'});
keys = {'nose','fuse','wing','h1','h2','v1','v2','pay','ballast','systems'};
for k = 1:numel(keys)
    C.(['W_' keys{k}]) = nan(height(D),1);
    C.(['Xcg_' keys{k}]) = nan(height(D),1);
end
for key = {'wing','h1','h2','v1','v2'}
    C.(['X_LE_' key{1}]) = nan(height(D),1);
end
for key = {'Fuse_Mat','Wing_Mat','h1_Mat','h2_Mat','v1_Mat','v2_Mat'}
    C.(key{1}) = repmat("",height(D),1);
end
C.Thick_f = nan(height(D),1);
C.rho_LWPLA = nan(height(D),1);
C.rho_bulk = nan(height(D),1);
[ok,message] = copyfile(sourceFile,outputFile);
assert(ok,'MaterialWeight:Copy','Could not copy workbook: %s',message);
writetable(C,outputFile,'Sheet','Component_Data');
end
