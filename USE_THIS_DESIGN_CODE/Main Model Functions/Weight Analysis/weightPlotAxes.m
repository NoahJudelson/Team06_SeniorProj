function [fig,ax] = weightPlotAxes(plotName)
%WEIGHTPLOTAXES Keep the two weight plots in tabs of one figure window.
plotName = validatestring(plotName,{'component','comparison'});

% Remove the old standalone comparison figure when rerunning a section.
delete(findall(groot,'Type','figure','Number',710));
fig = findall(groot,'Type','figure','Tag','JoyBringerWeightPlots');
if isempty(fig)
    delete(findall(groot,'Type','figure','Number',700));
    fig = figure(700);
    set(fig,'Name','JoyBringer Weight Plots','Tag','JoyBringerWeightPlots', ...
        'WindowStyle','normal','Position',[100 100 1350 820]);
    tabs = uitabgroup(fig,'Units','normalized','Position',[0 0 1 1]);
    componentTab = uitab(tabs,'Title','Component breakdown');
    comparisonTab = uitab(tabs,'Title','Raymer comparison');
    componentAxes = axes('Parent',componentTab);
    comparisonAxes = axes('Parent',comparisonTab);
    setappdata(fig,'WeightPlotAxes',[componentAxes comparisonAxes]);
end

plotAxes = getappdata(fig,'WeightPlotAxes');
if strcmp(plotName,'component')
    ax = plotAxes(1);
else
    ax = plotAxes(2);
end
cla(ax,'reset');
ax.Parent.Parent.SelectedTab = ax.Parent;
end
