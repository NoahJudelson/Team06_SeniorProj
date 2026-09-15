function MSN_Profile=Read_MSN_Profile(Filename,SheetNum,ProfileName)
%Author: Jonathan Morris
%ASEN 4138 11/23/24
%This function exists to read in user created mission profiles defined in
%an excel sheet. It is only expected to function with the format shown in
%the demo excel sheet (Mission_Profile_Template.xlsx). Any deviations from
%this format could cause errors. Currently the code does not catch these
%errors in a user friendly way, so it could be difficult to diagnose these
%errors. 
%
%Limitations:
%currently this read function will only support numeric imputs to the
%mission segment functions. If you were to add text inputs you could
%re-write this function in the same manner as Read_Requirements_Input.m
%
%Inputs:
%Filename: excel sheet filename
%SheetNum: number of sheet for the mission profile you are analyzing
%ProfileName: Name of the profile you're creating. (e.g. "F16 profile A")
%
%Outputs:
%MSN_Profile: A matlab structure that describes the mission profile defined
%in the excel sheet. Consists chiefy of input_table, a cell array that 
% saves the input to each MSN_SEG function, and legtype, an array of 
% strings describing which MSN_SEG function to use.
% Used directly in the MSN_Seg_Handler function
    
    X=readtable(Filename,'Sheet',SheetNum,'HeaderLines',0,'ReadVariableNames',false);
    X=X(:,2:end);
    Inputs=X(2:end,2:end);
    Inputs = Inputs(1:2:end, :);
    % Excel may store edited numbers as text. Convert cells individually
    % before assembling the numeric mission inputs; preserve blank cells.
    cells=table2cell(Inputs);
    Inputs=nan(size(cells));
    for row=1:size(cells,1)
        for col=1:size(cells,2)
            value=cells{row,col};
            if isempty(value) || (isscalar(value) && ismissing(value))
                continue
            end
            if ischar(value) || isstring(value)
                if strlength(strtrim(string(value)))==0
                    continue
                end
                value=str2double(value);
            end
            assert(isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value), ...
                'MissionProfile:InvalidInput', ...
                'Sheet %d, Excel row %d, input %d must be numeric or blank.',SheetNum,2*row+1,col);
            Inputs(row,col)=value;
        end
    end
    NaN_log=isnan(Inputs);%logical array depicting locations of NaNs
    %marks the index of the first NaN in a row. Then saves the input_table
    %cell array for that row up to the index before the NaN. This allows
    %the 
    for i=1:size(Inputs,1)
        Idx=find(NaN_log(i,:),1);%idx of first NAN
        if isempty(Idx)
            Idx=size(Inputs,2)+1; % Keep every input when the row is full.
        end
        input_table(i)={Inputs(i,1:Idx-1)};


    end
    legtype=rmmissing(X(:,1));%conditioning the legtype to remove blank rows
    legtype=string(table2array(legtype)');
    
    MSN_Profile.name=ProfileName;
    MSN_Profile.legnum=length(legtype);
    MSN_Profile.legtype=legtype;
    MSN_Profile.input_table=input_table;
end
