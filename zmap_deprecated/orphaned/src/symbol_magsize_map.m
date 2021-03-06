% plot eqs according to depth and size
%TODO Delete me (functionality in MainInteractiveMap)

report_this_filefun(mfilename('fullpath'));

c = jet;

ButtonName=questdlg('Choose a colormap?', ...
    'colormap selection', ...
    'jet','hot','cool','hsv');


switch ButtonName
    case 'jet'
        c = jet;
        c = c(64:-1:1,:);
    case 'hot'
        c = hot;
    case 'cool'
        c = cool;
    case 'hsv'
        c = hsv;
end % switch

% sort by depth
[s,is] = sort(a.Depth);
a = a(is(:,1),:) ;

for i = 1:length(a)

    pl =plotm(a(i,2),a(i,1),'ow');
    hold on
    fac = 64/max(a.Depth);

    facm = 4/max(a.Magnitude);
    sm = a(i,6)* facm;
    if sm < 1; sm = 1; end

    col = ceil(a(i,7)*fac)+1; if col > 63; col = 63; end ; if col < 1; col = 1 ; end
    set(pl,'Markersize',ceil(sm),'markerfacecolor',[c(col,:)],'markeredgecolor',c(col,:));
end
h1 = gca;
set(h1,'pos',[0.13 0.08 0.65 0.85])
zdatam(handlem('allline'),max(max(tmap))) % keep line on surface

% resort by time
[s,is] = sort(a.Date);
a = a(is(:,1),:) ;

return
% make a depth legend

vx =  (mindep:1:maxdep);
v = [vx ; vx]; v = v';
rect = [0.83 0.2 0.01 0.2];
axes('position',rect)
pcolor((1:2),vx,v)
shading flat
set(gca,'XTickLabels',[])
set(gca,'FontSize',8,'FontWeight','normal',...
    'LineWidth',1.0,'YAxisLocation','right',...
    'Box','on','SortMethod','childorder','TickDir','out')
xlabel('  Depth [km]');
colormap(c)


% make a mag legend:

anzmag = 0;allpl = [];allls = [];
for i = floor(min(a.Magnitude)):1:ceil(max(a.Magnitude))
    axes(h1);
    pl = plotm(a(1,1),a(1,2),'ok');
    if i < 1; i = 1; end
    set(pl,'Markersize',i);
    anzmag = anzmag+1;
    allpl = [allpl , pl];
    allls = [allls ; 'M' num2str(i) ];

end

le = legend(allpl(:),allls);
set(le,'position',[ 0.83 0.73 0.32 0.12],'FontSize',8,'color','w')

axes(h1)
watchoff;
set(gcf,'color','w');
