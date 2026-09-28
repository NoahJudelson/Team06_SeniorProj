function [] = Graph_figure_update(FinalWeightData)
%GRAPH_FIGURE_UPDATE Summary of this function goes here
%   Detailed explanation goes here
%   Creates 1000 - series figures which are the new ones Im making

%% Creating mission segment plot - Leg Type vs. BMF bar chart
% Specifying figure size and what not
mission_seg_fig = figure(1001);
mission_seg_fig.Units = 'inches';
mission_seg_fig.Position=[1,1,16,9];

% Converting BMF strings to numbers
BMF = zeros(length(FinalWeightData{:,2}),1);
for i=1:length(FinalWeightData{:,2})
    BMF(i) = str2num(FinalWeightData{i,2});
end

% Making sure labels are unique
missionSegments = FinalWeightData{:,1};
for i=1:length(missionSegments)
    if i == 8
        break
    elseif missionSegments(i) == missionSegments(i+1)
        missionSegments(i+1) = missionSegments(i+1) + '2';
    end
end
bar(missionSegments, BMF);
ax = gca;
ax.FontSize = 18;
xlabel('Mission Segment', FontSize=22);
ylabel('BMF', FontSize=22);
title('BMF variation over Mission Profile', FontSize=24);
%print('Mission Profile Visual', '-dpng', '-r300')

%% Fixing Figure 1 for DR1
pp = figure(1);
pp.Units = 'inches';
pp.Position=[1,1,16,9];
xlim([0,8])
ylim([0,1])
ax = gca;
ax.FontSize = 18;
ylabel('Power to Weight $\frac{P}{W}$ - $[\frac{hp}{lbm}]$', 'Interpreter', 'latex', FontSize=22)
xlabel('Wing Loading $\frac{W}{S}$ - $[\frac{lbm}{ft^2}]$', Interpreter='latex', FontSize=22)
title('Point Performance Evaluation of Current Design', FontSize=24)
% print('Point Performance DR1', '-dpng', '-r300')

%% Getting Noahs weight figures updated
figure(700)
print('Weight Figs', '-dpng', '-r300')
end