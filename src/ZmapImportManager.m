function catalog = ZmapImportManager(fun, funArguments, varargin)
    % ZMAPIMPORTMANAGER - handles the import of zmap catalogs.
    %
    % ZMAPIMPORTMANAGER( FUN ) provide the import function as a parameter. Catalog will replace
    % the primary catalog in ZmapGlobal.Data
    %
    % CATALOG = ZMAPIMPORTMANAGER( FUN ) return the catalog as output INSTEAD of updating the primary
    % catalog.
    %
    % ZMAPIMPORTMANAGER( FUN , ARGS ) ARGS is a cell of arguments that will be passed to the import
    % function FUN
    %
    % The ZMAPIMPORTMANAGER exists to do cleanup and shutdown as necessary of other catalogs in memory.
    % this includes the creation of maps and timeplots.
    %
    % catalogs imported throught he ZmapImportManager will be sorted in ascending Date order
    
    assert(nargout(fun)==2,'import function must have two output arguments : [catalog, ok]');
    if exist('funArguments','var')
        assert(iscell(funArguments),...
            'Second argument should be a CELL containing arguments to be passed to fun');
        [catalog,ok] = fun(funArguments{:});
    else
        [catalog,ok] = fun();
    end
    sort(catalog,'Date','ascend')
    
    if nargout ~= 0
        % do not assume we are modifying the primary catalog. This might be some other load
        if ~ok
            catalog = ZmapCatalog();
        end
    else
        % assume we replace the primary catalog
        if ok
            post_load();
        end
    end
    
    
    function post_load()
        disp('post load')
        ZG = ZmapGlobal.Data;
        ZG.primeCatalog = catalog;
        
        % ZG.mainmap_plotby='depth';
        
        setDefaultValues(ZG.primeCatalog);
        cf=@()ZG.primeCatalog;
        ZG.Views.primary=ZmapCatalogView(cf); % repeat for other loads?
        [ZG.Views.primary,ZG.maepi,ZG.big_eq_minmag] = catalog_overview(ZG.Views.primary, ZG.big_eq_minmag);
        
        % OPTIONALLY CLEAR SHAPE
        if ~isempty(ZG.selection_shape)
            % ask whether to keep shape
            switch questdlg('Keep current shape?','SHAPE','yes','no','no')
                case 'no'
                    ZG.selection_shape.cb_clear();
                case 'yes'
                    % do nothing
            end
        end
        
        % OPTIONALLY CLEAR GRID
        if ~isempty(ZG.Grid)
            switch questdlg('Keep curent grid?','GRID','yes','no','no')
                case 'no'
                    ZG.Grid.delete()
                case 'yes'
                    % do nothing
            end
        end
        
        ZG.newt2=ZG.Views.primary.Catalog();
        timeplot();
        
        ZmapMessageCenter.update_catalog();
        
        uimemorize_catalog();
        
        zmap_update_displays();
    end
    
end

function setDefaultValues(A)
    % SETDEFAULTVALUES sets certain Zmap Global values based on catalog.
    ZG=ZmapGlobal.Data; % get zmap globals
    
    %  default values
    [t0b, teb] = A.DateRange() ;
    ttdif = days(teb - t0b);
    if ~exist('bin_dur','var')
        ZG.bin_dur = days(ceil(ttdif/100));
    elseif ttdif<=10  &&  ttdif>1
        ZG.bin_dur = days(0.1);
    elseif ttdif<=1
        ZG.bin_dur = days(0.01);
    end
    ZG.big_eq_minmag = max(A.Magnitude) -0.2;
end