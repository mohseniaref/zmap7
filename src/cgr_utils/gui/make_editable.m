function returnstate = make_editable(p, finalUpdateFn, intermedUpdateFn, BEHAVIOR, LATLON_AWARE)
    % MAKE_EDITABLE embues a plot with the ability to add, move, and delete points, as well as translate and scale.
    % 
    % RETURNSTATE = MAKE_EDITABLE(PLT,finalUpdateFn, intermedUpdateFn, BEHAVIOR,LATLON_AWARE) will make the plot PLT (usually a Line object) interactive. 
    % the plot can have points moved, added, or removed. It can be translated or scaled.
    %   
    % RETURNSTATE is a function handle that will put all the callbacks back the way they were found, and
    % should be called once the plot is done being edited.
    %
    %
    % To scale: use mouse wheel
    % To delete a vertex : right click on vertex, and choose "delete point"
    % To add a new vertex : right click on line segment, and choose "add point"
    % To move a vertex : drag the vertex using the left mouse button
    % To move the entire line : drag a segment using the left mouse button.
    %
    % this will modify the figure and line/scatter callback functions. to put them back, call the function returned
    % by MAKE_EDITABLE.
    %  
    % BEHAVIOR: 'normal':
    %           'nopoints': disables point clicking
    %
    % example usage:
    % f=figure
    % ax=axes
    % plot(-10:.5:10,-10:.5:10,'.','color',[.5 .5 .5])
    % set(gca,'NextPlot','add')
    % p=plot([3;2.5;4],[2;1;3],'-*')
    % putback = make_editable(p);
    %
    % now you can, scale, translate, add, remove points.
    %
    % when done, run the result, which will restore the callbacks to original state. in this case:
    %
    % putback()
    %
    % returnstate is called when 'Finished' context menu is activated.
    % returnstate also calls 'updateFn'. Use this to update something with the new values
    
    error('deprecated. use "moveable_item" instead');
    
    if ~exist('finalUpdateFn','var') || isempty(finalUpdateFn)
        finalUpdateFn=@()[];
    end
    
    if ~exist('intermedUpdateFn','var') || isempty(intermedUpdateFn)
        intermedUpdateFn=@()[];
    end
    dragging=false;
    lastIntersect=[];
    
    ghost=gobjects(1);
        XTOL=0.01;
        YTOL=0.01;
    
    if ~exist('LATLON_AWARE','var')
        LATLON_AWARE=false;
    end
        
    if ~exist('BEHAVIOR','var')||isempty('BEHAVIOR')
        BEHAVIOR='normal';
    end
    switch BEHAVIOR
        case 'nopoint'
            
            getactivepoint=@(src,ev)[];
            
        otherwise
            % assume 'normal'
        getactivepoint=@(src,ev)find(abs(src.XData-ev.IntersectionPoint(1)) <XTOL &...
            abs(src.YData-ev.IntersectionPoint(2))<YTOL);
    end
    
    pOrigMarker=p.Marker;
    changeMaker(p,'s');

    ax=ancestor(p,'axes');
    f=ancestor(ax,'figure');
    
    f.Pointer='circle';
    returnstate=return_state(f,p); % used to put things back the way they were
    p.ButtonDownFcn=@bdown;
    p.UIContextMenu=pointcontext(p);
    f.WindowScrollWheelFcn={@scale,p};
    
    function bdown(src,ev)
        % when mouse button is pressed
        % LEFT
        %   on line:  start dragging entire object
        %   on vertex : start dragging this point
        % RIGHT
        %   on line: allow new point
        %   on vertex : allow deletion of point
        
        XTOL=0.005;
        YTOL=0.005;
        %activepoint=find(abs(src.XData-ev.IntersectionPoint(1)) <XTOL &...
        %    abs(src.YData-ev.IntersectionPoint(2))<YTOL);
        activepoint=getactivepoint(src,ev);
        
        %f.WindowButtonUpFcn={@mouseup,src,activepoint}; %attach mouseup function to THIS item
        
        if ev.Button==1 % LEFT CLICK
            dragging=true;
            if ~isempty(activepoint)
                % drag one point
                f.WindowButtonMotionFcn={@updatePoint,src,activepoint};
                f.WindowButtonUpFcn={@mouseup,src,activepoint}; %attach mouseup function to THIS item
            else
                % drag entire series
                xs=[ev.IntersectionPoint(1);ev.IntersectionPoint(1)];
                ys=[ev.IntersectionPoint(2);ev.IntersectionPoint(2)];
                set(gca,'NextPlot','add');
                h=plot(xs,ys,'ko:');
                ghost = copyobj(p,gca);
                ghost.LineStyle=':';
                ghost.Color='r';
                f.WindowButtonMotionFcn={@translateSeries,h};
                f.WindowButtonUpFcn={@endTranslation,src,h}; %attach mouseup function to THIS item
            end
        else
            lastIntersect=ev.IntersectionPoint;
        end
        
        if ev.Button==3 % RIGHT CLICK / CONTEXT
            if ~isempty(activepoint)
                % clicked on actual point
                dph=findobj(src.UIContextMenu,'Label','delete point');
                dph.Callback(3)={activepoint};
                set(findobj(src.UIContextMenu,'Label','add point'),'enable','off')
                set(findobj(src.UIContextMenu,'Label','delete point'),'enable','on')
            else
                % clicked on line segment
                set(findobj(src.UIContextMenu,'Label','add point'),'enable','on')
                set(findobj(src.UIContextMenu,'Label','delete point'),'enable','off')
            end
        end
        
    end
    
    function updatePoint(~,~,target,activepoint)
        % move this one point
        cp=ax.CurrentPoint;
        target.XData(activepoint)=cp(1,1);
        target.YData(activepoint)=cp(1,2);
        changeMaker(p,pOrigMarker);
    end
    
    function translateSeries(~,~,h)
        % move entire line
        cp=ax.CurrentPoint;
        h.XData(end)=cp(1,1);
        h.YData(end)=cp(1,2);
        translate_target(ghost,h);
    end
    
    function mouseup(~,~,target,activepoint)
        % 
        if ~isempty(target) && dragging
            if isempty(activepoint)
                assert('empty? I think not. translateSeries should be called');
            else
                
                cp=ax.CurrentPoint;
                target.XData(activepoint)=cp(1,1);
                target.YData(activepoint)=cp(1,2);
                dragging=false;
                %activepoint=[];
                f.WindowButtonMotionFcn='';
                intermedUpdateFn();
            end
        end
    end
    
    function translate_target(target,h)
        if LATLON_AWARE
            % to keep same shape, have to use distances & reckoning
            % MOUSEUP at PLOT level
            midX = (min(p.XData) + max(p.XData)) / 2;
            midY = (min(p.YData) + max(p.YData)) / 2;
            
            % find position of all points relative to center
            [ARCLEN, AZ] = distance([midY,midX],[p.YData(:),p.XData(:)]);
            
            %move center, then recalculate all points.
            [target.YData, target.XData] = reckon(midY+diff(h.YData), midX+diff(h.XData),ARCLEN, AZ);
            
        else
            % simply move points around  by constant
            target.XData=p.XData + (diff(h.XData));
            target.YData=p.YData + (diff(h.YData));
        end
    end
    
    function endTranslation(~,~,target,h)
        % MOUSEUP at PLOT level
        
        prevax=axis;
        
        if LATLON_AWARE
            % to keep same shape, have to use distances & reckoning
            % MOUSEUP at PLOT level
            midX = (min(target.XData) + max(target.XData)) / 2;
            midY = (min(target.YData) + max(target.YData)) / 2;
            
            % find position of all points relative to center
            [ARCLEN, AZ] = distance([midY,midX],[target.YData(:),target.XData(:)]);
            
            %move center, then recalculate all points.
            [target.YData, target.XData] = reckon(midY+diff(h.YData), midX+diff(h.XData),ARCLEN, AZ);
            
        else
            % simply move points around  by constant
            target.XData=target.XData + (diff(h.XData));
            target.YData=target.YData + (diff(h.YData));
        end
        
        delete(h);
        delete(ghost);
        axis(prevax)
        f.WindowButtonMotionFcn='';
        f.WindowButtonUpFcn='';
        intermedUpdateFn();
    end
    
    function delpoint(target, activepoint)
        % controlled by RT CLICK choice at PLOT level
        isEndpoint = activepoint(1)==1 || activepoint(1)==length(target.XData);
        closedLoop = target.XData(1)==target.XData(end) && target.YData(1)==target.YData(end);
        if closedLoop && length(target.XData)<=4
            warning('ZMAP:polygon:tooFewPoints','Cannot delete a closed shape down to less than 3 points')
            return
        else
            fprintf('%d points before deleting\n',length(target.XData));
            
        end
            
        if isEndpoint && closedLoop
            % keep loop closed.
            target.XData(1)=[];
            target.YData(1)=[];
            target.XData(end)=target.XData(1);
            target.YData(end)=target.YData(1);
        else
            target.XData(activepoint)=[];
            target.YData(activepoint)=[];
        end
        intermedUpdateFn()
    end
    
    function addpoint(target,activepoint)
        % controlled by RT CLICK choice at PLOT level
        if ~exist('activepoint','var') || isempty(activepoint)
            ds=@(A,B) sqrt((A(:,1)-B(:,1)).^2 + (A(:,2) - B(:,2)).^2);
            isOnLine=@(A,C) abs(ds(A(1:end-1,:),C) + ds(A(2:end,:),C) - ds(A(1:end-1,:),A(2:end,:)))<.001;
            pointBefore=find(isOnLine([target.XData(:) target.YData(:)],lastIntersect(1:2)));
            if ~isempty(pointBefore)
                if numel(pointBefore)>1
                    warning('multiple segments go through this line')
                    return
                end
                newPtX=lastIntersect(1);
                newPtY=lastIntersect(2);
                xbefore=target.XData(1:pointBefore);
                xafter=target.XData(pointBefore+1:end);
                ybefore=target.YData(1:pointBefore);
                yafter= target.YData(pointBefore+1:end);
                target.XData=[xbefore(:); newPtX; xafter(:)];
                target.YData=[ybefore(:); newPtY; yafter(:)];
            else
                disp('didn''t find it')
            end
            
        else
            warning('To add a point, click on a line segment, not a node.')
        end
        % figure out which point!
        
    end
    
    function scale(~,ev,targ)
        
        extent=[min(targ.XData) max(targ.XData) min(targ.YData) max(targ.YData)];
        %center=[mean(extent(1:2)), mean(extent(3:4))];j
        center.X=mean(extent(1:2));
        center.Y=mean(extent(3:4));
        
        factor=1.1;
        
        prevax.x=xlim;
        prevax.y=ylim;
        
        if ev.VerticalScrollCount<0
            factor = 1/factor;
        end
         if LATLON_AWARE
            % to keep same shape, have to use distances & reckoning
            
            % find position of all points relative to center
            [ARCLEN, AZ] = distance([center.Y,center.X],[targ.YData(:),targ.XData(:)]);
            
            %move center, then recalculate all points.
            [targ.YData, targ.XData] = reckon(center.Y,center.X, ARCLEN .* factor, AZ);
            
        else
            % simply move points around  by constant
            % SCALE controlled by scroll wheel at the FIGURE level
            relX=(targ.XData-center.X) .* factor;
            relY=(targ.YData-center.Y) .* factor;
            
            targ.XData=relX+center.X;
            targ.YData=relY+center.Y;
            
         end
        
        xlim(prevax.x);
        ylim(prevax.y);
        intermedUpdateFn();
        
    end
    
    function c=pointcontext(p)
        c=uicontextmenu('Tag','PointEditableContext');
        if BEHAVIOR ~= "nopoint"
            uimenu(c,'Label','delete point',MenuSelectedField(),@(~,~)delpoint(p));
            uimenu(c,'Label','add point',MenuSelectedField(),@(~,~)addpoint(p));
            uimenu(c,'Label','Finished', 'Separator','on',MenuSelectedField(),@(~,~)returnstate());
        else
            uimenu(c,'Label','Finished',MenuSelectedField(),@(~,~)returnstate());
        end
    end
    
    function changeMaker(p,newmarker)
        if strcmpi(p.Marker,'none')
            p.Marker=newmarker;
            p.MarkerFaceColor='k';
        end
    end
    
    function rs = return_state(f,p)
        % put all the callbacks back!
        % rs is a function, that when called, will set the states back to their original form
        
        % 'WindowButtonDownFcn'
        wbuf=f.WindowButtonUpFcn;
        wbmf=f.WindowButtonMotionFcn;
        wscwf=f.WindowScrollWheelFcn;
        pbdf=p.ButtonDownFcn;
        puicm=p.UIContextMenu;
        
        %hard-wire the original functions
        rs = @() resetfns(f,p,wbuf, wbmf, wscwf, pbdf, puicm, pOrigMarker,finalUpdateFn);
        function resetfns(f,p, wbuf, wbmf, wscwf, pbdf, puicm, pmark, ufn)
            %
            if isvalid(f)
                f.WindowButtonUpFcn=wbuf;
                f.WindowButtonMotionFcn=wbmf;
                f.WindowScrollWheelFcn=wscwf;
            end
            if isvalid(p)
                p.ButtonDownFcn=pbdf;
                p.UIContextMenu=puicm;
                p.Marker=pmark;
            end
            ufn()
            f.Pointer='arrow';
            delete(findobj(f,'Tag','PointEditableContext'));
        end
    end
    
        
end

        
