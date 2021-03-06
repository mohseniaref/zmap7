function cirbva() 
    %   This subroutine "circle"  selects the Ni closest earthquakes
    %   around a interactively selected point.  Resets ZG.newcat and ZG.newt2
    %   Operates on "primeCatalog".
    %   changes newt2
    %
    % axis: h1
    % plots to: plos1 as xk
    % inCatalog: a
    % outCatalog: newt2, newcat
    % mouse controlled
    % closest events OR radius
    % calls: bdiff
    %
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    
    %  Input Ni:
    %
    report_this_filefun();
    ZG=ZmapGlobal.Data;
 
    delete(findobj('Tag','plos1'));
    disp(ZmapGlobal.Data.hold_state)
    
    axes(h1)
    %zoom off
    
    titStr ='Selecting EQ in Circles                         ';
    messtext= ...
        ['                                                '
        '  Please use the LEFT mouse button              '
        ' to select the center point.                    '
        ' The "ni" events nearest to this point          '
        ' will be selected and displayed in the map.     '];
    
    msg.dbdisp(messtext, titStr);
    
    % Input center of circle with mouse
    %
    [xa0,ya0]  = ginput(1);
    
    stri1 = [ 'Circle: ' num2str(xa0,5) '; ' num2str(ya0,4)];
    stri = stri1;
    pause(0.1)
    %  calculate distance for each earthquake from center point
    %  and sort by distance
    %
    l = ZG.primeCatalog.epicentralDistanceTo(ya0,xa0);
    ZG.newt2=ZG.primeCatalog; % points to same thing
    if met == 'ni'
        % take first ni and sort by time
        [ZG.newt2, R2] = ZG.primeCatalog.selectClosestEvents(ni);
    elseif  met == 'ra'
        ZG.newt2 = ZG.primeCatalog.selectRadius(ra);
        R2=ra;
    elseif met == 'ti'
        global t1 t2 t3 t4
        
        lt =  ZG.newt2.Date >= t1 &  ZG.newt2.Date <t2 ;
        bdiff(ZG.newt2.subset(lt));
        ZG.hold_state=true;
        lt =  ZG.newt2.Date >= t3 &  ZG.newt2.Date <t4 ;
        bdiff(ZG.newt2.subset(lt));
        
        
    end
    ZG.newt2.sort('Date');
    R2 = ra;
    
    %
    % plot Ni clostest events on map as 'x':
    
    set(gca,'NextPlot','add')
    plot(ZG.newt2.Longitude,ZG.newt2.Latitude,'xk','Tag','plos1');
    
    % plot circle containing events as circle
    x = -pi-0.1:0.1:pi;
    pl = plot(xa0+sin(x)*R2/(cosd(ya0)*111), ya0+cos(x)*R2/(cosd(ya0)*111),'k')
    %plot(xa0+sin(x)*l(ni)/111, ya0+cos(x)*l(ni)/111,'k')
    
    
    set(gcf,'Pointer','arrow')
    
    %
    newcat = ZG.newt2;                   % resets ZG.newcat and ZG.newt2
    
    bdiff(ZG.newt2,ZmapGlobal.Data.hold_state)
    
end
