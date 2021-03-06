function makeavmap() 
    % create ana-value map at a given Mc.
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    
    prompt={'Enter the magnitude at which you like to compute the a-value:'};
    def={num2str(min(ZG.primeCatalog.Magnitude))};
    dlgTitle='Input fora-value map';
    lineNo=1;
    answer=inputdlg(prompt,dlgTitle,lineNo,def);
    
    Mc_a = str2double(answer{1});
    
    av2 = log10(ZG.primeCatalog.Count)+b1*min(ZG.primeCatalog.Magnitude);
    
    AV = zeros(length(bvg(:,1)),1);
    for i = 1:length(bvg)
        AV(i) =  polyval([-bvg(i,1) bvg(i,8)],Mc_a);
    end
    
    
    normlap2(kll)= AV;
    valueMap=reshape(normlap2,length(yvect),length(xvect));
    lab1 = ['a-value at M=' num2str(Mc_a,3) ];
    
    
end
