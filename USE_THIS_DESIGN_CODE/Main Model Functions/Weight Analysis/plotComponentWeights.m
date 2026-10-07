function plotComponentWeights(Weight_Data,sparCount,bulkheadCount)
% Sorted horizontal component bars in the shared weight-plot window.
sparLabel = sprintf('%d Wing Spars',sparCount);
if sparCount == 1
    sparLabel = '1 Wing Spar';
end
labels = {'Nose','Fuselage','Wing','Horizontal Tail 1','Horizontal Tail 2', ...
    'Vertical Tail 1','Vertical Tail 2',sparLabel,sprintf('%d Bulkheads',bulkheadCount), ...
    'Payload','Ballast','Systems'};
[weights,order] = sort(Weight_Data{1,3:end});
labels = labels(order(weights>0));
weights = weights(weights>0);
rows = 1:numel(weights);

[~,ax] = weightPlotAxes('component');
barh(ax,weights,0.65,'FaceColor',[0.20 0.45 0.75]);
set(ax,'YTick',rows,'YTickLabel',labels,'YDir','reverse', ...
    'TickLabelInterpreter','none','FontSize',24,'Box','off','Layer','bottom', ...
    'Position',[0.27 0.18 0.66 0.68],'XLim',[0 1.30*max(weights)], ...
    'YLim',[0.5 numel(rows)+0.5],'XGrid','on','YGrid','off', ...
    'GridColor',[0.82 0.86 0.90],'GridAlpha',0.25);
text(ax,weights,rows,compose('  %.2g lb',weights), ...
    'FontSize',26,'Color',[0.15 0.18 0.22]);
xtickformat(ax,'%.2g');
xlabel(ax,'Weight [lb]','FontSize',26);
title(ax,'JoyBringer Component Weight Breakdown','FontSize',24);
folder = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'figures');
if ~isfolder(folder)
    mkdir(folder);
end
exportgraphics(ax,fullfile(folder,'component_weight_breakdown.png'),'Resolution',300);
end
