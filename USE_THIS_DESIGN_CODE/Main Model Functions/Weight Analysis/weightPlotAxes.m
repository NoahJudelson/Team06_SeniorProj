function [fig,ax] = weightPlotAxes(plotName)
% Keep component and comparison plots in two tabs of figure 700.
plotName = validatestring(plotName,{'component','comparison'});
fig = figure(700);
if ~strcmp(fig.Tag,'JoyBringerWeightPlots')
    clf(fig);
    set(fig,'Name','JoyBringer Weight Plots','Tag','JoyBringerWeightPlots', ...
        'WindowStyle','normal','Position',[100 100 1350 820]);
    tabs = uitabgroup(fig);
    axes('Parent',uitab(tabs,'Title','Component breakdown'),'Tag','component');
    axes('Parent',uitab(tabs,'Title','Raymer comparison'),'Tag','comparison');
end
ax = findobj(fig,'Type','axes','Tag',plotName);
cla(ax,'reset'); % Reset only this tab and preserve the other plot.
ax.Tag = plotName;
ax.Parent.Parent.SelectedTab = ax.Parent;
end
