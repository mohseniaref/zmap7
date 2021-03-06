function [caNodeIndices, vResolution_] = ex_CreateIndexCatalog(mCatalog, mPolygon, bMap, nGriddingMode, nNumberEvents, fRadius, fSizeRectHorizontal, fSizeRectDepth)
% function [caNodeIndices] = ex_CreateIndexCatalog(mCatalog, mPolygon, bMap, nGriddingMode,
%                                                  nNumberEvents, fRadius, fSizeRectHorizontal, fSizeRectDepth)
% -------------------------------------------------------------------------------------------------------------
% Creates a cell-array with subcatalogs for every grid node defined by mPolygon. These subcatalogs
%   contain only indices to the earthquake "rows" in mCatalog.
%
% Input parameters:
%   mCatalog              Earthquake catalog
%   mPolygon              Polygon (defined by ex_selectgrid)
%   bMap                  Calculate cell-array for a map (=1) or a cross-section (=0)
%   nGriddingMode         Mode of creating grid node subcatalogs
%                         0: Constant number of events
%                         1: Constant radius
%                         2: Rectangular grid node samples
%   nNumberEvents         Number of events per grid node (nGriddingMode == 0)
%   fRadius               Radius of grid node sample (nGriddingMode == 1)
%   fSizeRectHorizontal   Latitude/horizontal size of rectangle (nGriddingMode == 2)
%   fSizeRectDepth        Longitude/depth size of rectangle (nGriddingMode == 2)
%
% Output parameters:
%   caNodeIndices         Cell-array with index-catalogs per grid node of mPolygon
%
% Danijel Schorlemmer
% June 17, 2002

global bDebug;
if bDebug
  report_this_filefun(mfilename('fullpath'));
end

% Create the catalogs for each node with pointers to the overall catalog
nNumberNodes_ = length(mPolygon(:,1));
caNodeIndices = cell(nNumberNodes_, 1);

% If cross-section calculate the length along cross-section
if ~bMap
  [nRow_, nColumn_] = size(mCatalog);
  vXSecX_ = mCatalog(:,nColumn_);  % length along x-section
  vXSecY_ = (-1) * mCatalog(:,7);  % depth of hypocenters
end


% vResolution give the radius (for nGriddingMode = 0) and no. of events
% (for nGriddingMode = 1)
vResolution_(:,1)=ones(nNumberNodes_,1)*nan;

% Loop over all points of the polygon
for nNode_ = 1:nNumberNodes_
  % Get the grid node coordinates
  fX_ = mPolygon(nNode_, 1);
  fY_ = mPolygon(nNode_, 2);

  if (nGriddingMode == 0) | (nGriddingMode == 1)  % Fixed radius or fixed number
    % Calculate distance from center point
    if bMap
      vDistances_ = sqrt(((mCatalog(:,1)-fX_)*cos(pi/180*fY_)*111).^2 + ((mCatalog(:,2)-fY_)*111).^2);
    else
      vDistances_ = sqrt(((vXSecX_ - fX_)).^2 + ((vXSecY_ - fY_)).^2);
    end
    if nGriddingMode == 0 % Fixed number
      if length(mCatalog(:,1)) == 0
        caNodeIndices{nNode_} = [];
        % NaN for no events
        vResolution_(nNode_) = nan;
      elseif nNumberEvents > length(mCatalog(:,1))
        caNodeIndices{nNode_} = vIndices(1:length(mCatalog(:,1)));
        % take the maximal distance for all eq. in the catalog
        vResolution_(nNode_) = max(vdistances_);
      else
        % Use first nNumberEvents events
        [vTmp, vIndices] = sort(vDistances_);
        caNodeIndices{nNode_} = vIndices(1:nNumberEvents);
        % radius of the nNumberEvents-th event in the sorted vDistances_
        vResolution_(nNode_) = vTmp(nNumberEvents);
      end
    else % Fixed radius
      % Use all events within fRadius
      caNodeIndices{nNode_} = find(vDistances_ <= fRadius);
      vResolution_(nNode_) = length(find(vDistances_ <= fRadius));
    end
  else % Rectangular gridding (nGriddingMode == 2)
    if bMap
      vSel_ = ((mCatalog(:,1) >= (fX_ - fSizeRectHorizontal/2)) & (mCatalog(:,1) < (fX_ + fSizeRectHorizontal/2)) & ...
        (mCatalog(:,2) >= (fY_ - fSizeRectDepth/2)) & (mCatalog(:,2) < (fY_ + fSizeRectDepth/2)));
      vResolution_(nNode_) = length(find(vSel_ > 0))
    else
      vSel_ = ((vXSecX_ >= (fX_ - fSizeRectHorizontal/2)) & (vXSecX_ < (fX_ + fSizeRectHorizontal/2)) & ...
        (vXSecY_ >= (fY_ - fSizRectDepth/2)) & (vXSecY_ < (fY_ + fSizeRectDepth/2)));
      vResolution_(nNode_) = length(find(vSel_ > 0))
    end
    caNodeIndices{nNode_} = find(vSel_ == 1);
  end
end; % of for nNode_
