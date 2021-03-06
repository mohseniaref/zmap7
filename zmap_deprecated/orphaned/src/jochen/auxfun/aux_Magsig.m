function aux_Magsig(params, hParentFigure)
% function aux_Magsig(params, hParentFigure);
% -------------------------------------------
% Selcts the closest grid point and generates magnitude signature plot
% using plot_Magsig.
%
% Incoming variables:
% params        : all variables
% hParentFigure : Handle of the parent figure
%
% J.Woessner, woessner@seismo.ifg.ethz.ch
% last update: 30.09.02

% Track of changes:

% Get the axes handle of the plotwindow
axes(pf_result('GetAxesHandle', hParentFigure, [], guidata(hParentFigure)));
hold on;
% Select a point in the plot window with the mouse
[fX, fY] = ginput(1);
disp(['X: ' num2str(fX) ' Y: ' num2str(fY)]);
% Plot a small circle at the chosen place
plot(fX,fY,'ok');

% Get closest gridnode for the chosen point on the map
[fXGridNode fYGridNode,  nNodeGridPoint] = calc_ClosestGridNode(params.mPolygon, fX, fY);
plot(fXGridNode, fYGridNode, '*r');
hold off;

% Get the data for the grid node
mNodeCatalog_ = params.mCatalog(params.caNodeIndices{nNodeGridPoint}, :);
%%%% Doe: Determine next grid point and earthquakes associated with it %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check for Split time
if ~exist('params.fSplitTime')
    prompt = {'Split time (dec.years):'};
    dlg_title = 'Split Time input';
    num_lines= 1;
    def     = {'' num2str(mean(mNodeCatalog_(:,3))) ''};
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    params.fSplitTime = str2double(answer(1));
end

params.fTimePeriod = params.fTimePeriod/365;
% Split the gridpoint catalog according to the defined Splittime
[mCat1, mCat2, fPer1Exact, fPer2Exact, fPeriod1,...
        fPer2] = ex_SplitCatalog(mNodeCatalog_, params.fSplitTime, params.bTimePeriod,...
    params.fTimePeriod, params.bTimePeriod, params.fTimePeriod);

% Calculate magnitude signature and plot
fBinning = 0.1;
[mLMagsig mHMagsig fLZmax fLZmean fLZmin fHZmax fHZmean,  fHZmin] = ...
    plot_Magsig(mCat1, mCat2 , fPer1Exact, fPer2Exact, fBinning);

% % Calculate magnitude signature and plot for Magnitude transformatioin model
% mCatModel = mCat1;
% % mCatModel(:,6) = mCatModel(:,6)*params.mValueGrid(nNodeGridPoint,11);
% mCatModel(:,6) = mCatModel(:,6)+params.mValueGrid(nNodeGridPoint,7);
%
% [mLMagsigMod mHMagsigMod fLZmaxMod fLZmeanMod fLZminMod fHZmaxMod fHZmeanMod,  fHZminMod] = ...
%     plot_Magsig(mCatModel, mCat2 , fPer1Exact, fPer2Exact, fBinning);
