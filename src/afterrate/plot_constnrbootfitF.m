function plot_constnrbootfitF() 
    % plot_constnrbootfitF Selects constant number of earthquakes around a grid node  in learning period and calculates the forecast by using calc_bootfitF
    %
    % Jochen Woessner
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    report_this_filefun();
    
    ShapeGeneral.clearplot(); % was tag plos1
    
    % interactively get the circle of interest
    shape=ShapeCircle(); 
    [ZG.newt2, max_km] = selectCircle(newa, shape.toStruct());

    % Select events in learning time period
    vSel = (ZG.newt2.Date <= ZG.maepi.Date(1)+days(time));
    newt2_learn = ZG.newt2.subset(vSel);
    vSel2 = (ZG.newt2.Date > ZG.maepi.Date(1)+days(time) & ZG.newt2.Date <= ZG.maepi.Date(1)+(time+timef)/365);
    newt2_forecast = ZG.newt2.subset(vSel2);
    
    % Distance from grid node for learning period and forecast period
    vDist = sort(l(vSel));
    vDist_forecast = sort(l(vSel2));
    
    % Select constant number
    newt2_learn = newt2_learn(1:ni,:);
    % Maxilearn = newt2_learn(1:ni,:);
    % Maximmum distance of events in learning period
    fMaxDist = vDist(ni);
    
    if fMaxDist <= fMaxRadius
        vSel3 = vDist_forecast <= fMaxDist;
        newt2_forecast = newt2_forecast(vSel3,:);
        ZG.newt2 = [newt2_learn; newt2_forecast];
    else
        vSel4 = (l < fMaxRadius & ZG.newt2.Date <= ZG.maepi.Date(1)+days(time));
        ZG.newt2 = ZG.newt2.subset(vSel4);
        newt2_learn = ZG.newt2;
        fMaxDist = fMaxRadius;
    end
    
    messtext = ['Radius of selected Circle:' num2str(l(ni))  ' km' ];
    disp(messtext)
    % Sort by time
    ZG.newt2.sort('Date');
    
    % Set limiting radius to plot
    R2 = fMaxDist;
    
    % Check for maximum radius
    l2 = sort(l);
    fMaxDist = l2(ni);
    % Check for maximum radius
    if fMaxDist > fMaxRadius
        sWarnstr = ['Maximum radius exceeded to obtain ', num2str(ni) , ' events'];
        hWarn = warndlg(sWarnstr,'Check number of events')
    end % End if on rd
    
    
    % Plot selected earthquakes
    shape.plot([],ZG.newt2); % linespec was xk, tag was plos1
    
    % Compute and Plot the forecast
    calc_bootfitF(ZG.newt2.Date,time,timef,bootloops,ZG.maepi.Date)
    
    ZG.newcat = ZG.newt2;
    ctp=CumTimePlot(ZG.newt2);
    ctp.plot();
end
