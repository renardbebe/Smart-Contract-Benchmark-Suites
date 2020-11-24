 

pragma solidity ^0.4.13;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract EthPlot is Ownable {

     
     
     
    struct PlotOwnership {

         
        uint24 x;
        uint24 y;
        uint24 w;
        uint24 h;

         
        address owner;
    }

     
    struct PlotData {
        string ipfsHash;
        string url;
    }

     

     
     
    PlotOwnership[] private ownership;

     
    mapping(uint256 => PlotData) private data;

     
     
     
    mapping (uint256 => bool) private plotBlockedTags;

     
    mapping(uint256 => uint256) private plotIdToPrice;

     
     
    mapping(uint256 => uint256[]) private holes;
    
     
    uint24 constant private GRID_WIDTH = 250;
    uint24 constant private GRID_HEIGHT = 250;
    uint256 constant private INITIAL_PLOT_PRICE = 20000 * 1000000000;  

     
     
    uint256 constant private MAXIMUM_PURCHASE_AREA = 1000;
      
     

     
     
     
     
    event PlotPriceUpdated(uint256 plotId, uint256 newPriceInWeiPerPixel, address indexed owner);

     
     
     
     
    event PlotPurchased(uint256 newPlotId, uint256 totalPrice, address indexed buyer);

     
     
     
     
     
     
    event PlotSectionSold(uint256 plotId, uint256 totalPrice, address indexed buyer, address indexed seller);

     
     
    constructor() public payable {
         
        ownership.push(PlotOwnership(0, 0, GRID_WIDTH, GRID_HEIGHT, owner));
        data[0] = PlotData("Qmb51AikiN8p6JsEcCZgrV4d7C6d6uZnCmfmaT15VooUyv/img.svg", "https://www.ethplot.com/");
        plotIdToPrice[0] = INITIAL_PLOT_PRICE;
    }

     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function purchaseAreaWithData(
        uint24[] purchase,
        uint24[] purchasedAreas,
        uint256[] areaIndices,
        string ipfsHash,
        string url,
        uint256 initialBuyoutPriceInWeiPerPixel) external payable {
        
         
        uint256 initialPurchasePrice = validatePurchaseAndDistributeFunds(purchase, purchasedAreas, areaIndices);

         
        uint256 newPlotIndex = addPlotAndData(purchase, ipfsHash, url, initialBuyoutPriceInWeiPerPixel);

         
        for (uint256 i = 0; i < areaIndices.length; i++) {
            holes[areaIndices[i]].push(newPlotIndex);
        }

         
        emit PlotPurchased(newPlotIndex, initialPurchasePrice, msg.sender);
    }

     
     
     
    function updatePlotPrice(uint256 plotIndex, uint256 newPriceInWeiPerPixel) external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        require(msg.sender == ownership[plotIndex].owner);

        plotIdToPrice[plotIndex] = newPriceInWeiPerPixel;
        emit PlotPriceUpdated(plotIndex, newPriceInWeiPerPixel, msg.sender);
    }

     
     
     
     
    function updatePlotData(uint256 plotIndex, string ipfsHash, string url) external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        require(msg.sender == ownership[plotIndex].owner);

        data[plotIndex] = PlotData(ipfsHash, url);
    }

     
    
     
     
     
    function withdraw(address transferTo) onlyOwner external {
         
        require(transferTo == owner);

        uint256 currentBalance = address(this).balance;
        owner.transfer(currentBalance);
    }

     
     
     
     
    function togglePlotBlockedTag(uint256 plotIndex, bool plotBlocked) onlyOwner external {
        require(plotIndex >= 0);
        require(plotIndex < ownership.length);
        plotBlockedTags[plotIndex] = plotBlocked;
    }

     

     
     
     
     
    function getPlotInfo(uint256 plotIndex) public view returns (uint24 x, uint24 y, uint24 w , uint24 h, address owner, uint256 price) {
        require(plotIndex < ownership.length);
        return (
            ownership[plotIndex].x,
            ownership[plotIndex].y,
            ownership[plotIndex].w,
            ownership[plotIndex].h,
            ownership[plotIndex].owner,
            plotIdToPrice[plotIndex]);
    }

     
     
     
     
    function getPlotData(uint256 plotIndex) public view returns (string ipfsHash, string url, bool plotBlocked) {
        require(plotIndex < ownership.length);
        return (data[plotIndex].url, data[plotIndex].ipfsHash, plotBlockedTags[plotIndex]);
    }
    
     
     
    function ownershipLength() public view returns (uint256) {
        return ownership.length;
    }
    
     

     
     
     
     
     
     
     
     
     
     
    function validatePurchaseAndDistributeFunds(uint24[] purchase, uint24[] purchasedAreas, uint256[] areaIndices) private returns (uint256) {
         
        require(purchase.length == 4);
        Geometry.Rect memory plotToPurchase = Geometry.Rect(purchase[0], purchase[1], purchase[2], purchase[3]);
        
        require(plotToPurchase.x < GRID_WIDTH && plotToPurchase.x >= 0);
        require(plotToPurchase.y < GRID_HEIGHT && plotToPurchase.y >= 0);

         
        require(plotToPurchase.w > 0 && plotToPurchase.w + plotToPurchase.x <= GRID_WIDTH);
        require(plotToPurchase.h > 0 && plotToPurchase.h + plotToPurchase.y <= GRID_HEIGHT);
        require(plotToPurchase.w * plotToPurchase.h < MAXIMUM_PURCHASE_AREA);

         
        require(purchasedAreas.length >= 4);
        require(areaIndices.length > 0);
        require(purchasedAreas.length % 4 == 0);
        require(purchasedAreas.length / 4 == areaIndices.length);

         
        Geometry.Rect[] memory subPlots = new Geometry.Rect[](areaIndices.length);

        uint256 totalArea = 0;
        uint256 i = 0;
        uint256 j = 0;
        for (i = 0; i < areaIndices.length; i++) {
             
            Geometry.Rect memory rect = Geometry.Rect(
                purchasedAreas[(i * 4)], purchasedAreas[(i * 4) + 1], purchasedAreas[(i * 4) + 2], purchasedAreas[(i * 4) + 3]);
            subPlots[i] = rect;

            require(rect.w > 0);
            require(rect.h > 0);

             
            totalArea = SafeMath.add(totalArea, SafeMath.mul(rect.w,rect.h));

             
            require(Geometry.rectContainedInside(rect, plotToPurchase));
        }

        require(totalArea == plotToPurchase.w * plotToPurchase.h);

         
        for (i = 0; i < subPlots.length; i++) {
            for (j = i + 1; j < subPlots.length; j++) {
                require(!Geometry.doRectanglesOverlap(subPlots[i], subPlots[j]));
            }
        }

         
         
        uint256 remainingBalance = checkHolesAndDistributePurchaseFunds(subPlots, areaIndices);
        uint256 purchasePrice = SafeMath.sub(msg.value, remainingBalance);
        return purchasePrice;
    }

     
     
     
     
     
     
     
     
    function checkHolesAndDistributePurchaseFunds(Geometry.Rect[] memory subPlots, uint256[] memory areaIndices) private returns (uint256) {

         
        uint256 remainingBalance = msg.value;

         
         
        uint256 owedToSeller = 0;

        for (uint256 areaIndicesIndex = 0; areaIndicesIndex < areaIndices.length; areaIndicesIndex++) {

             
            uint256 ownershipIndex = areaIndices[areaIndicesIndex];
            Geometry.Rect memory currentOwnershipRect = Geometry.Rect(
                ownership[ownershipIndex].x, ownership[ownershipIndex].y, ownership[ownershipIndex].w, ownership[ownershipIndex].h);

             
             
            require(Geometry.rectContainedInside(subPlots[areaIndicesIndex], currentOwnershipRect));

             
            for (uint256 holeIndex = 0; holeIndex < holes[ownershipIndex].length; holeIndex++) {
                PlotOwnership memory holePlot = ownership[holes[ownershipIndex][holeIndex]];
                Geometry.Rect memory holeRect = Geometry.Rect(holePlot.x, holePlot.y, holePlot.w, holePlot.h);

                require(!Geometry.doRectanglesOverlap(subPlots[areaIndicesIndex], holeRect));
            }

             
            uint256 sectionPrice = getPriceOfPlot(subPlots[areaIndicesIndex], ownershipIndex);
            remainingBalance = SafeMath.sub(remainingBalance, sectionPrice);
            owedToSeller = SafeMath.add(owedToSeller, sectionPrice);

             
            if (areaIndicesIndex == areaIndices.length - 1 || ownershipIndex != areaIndices[areaIndicesIndex + 1]) {

                 
                address(ownership[ownershipIndex].owner).transfer(owedToSeller);
                emit PlotSectionSold(ownershipIndex, owedToSeller, msg.sender, ownership[ownershipIndex].owner);
                owedToSeller = 0;
            }
        }
        
        return remainingBalance;
    }

     
     
     
     
    function getPriceOfPlot(Geometry.Rect memory subPlotToPurchase, uint256 plotIndex) private view returns (uint256) {

         
        uint256 plotPricePerPixel = plotIdToPrice[plotIndex];
        require(plotPricePerPixel > 0);

        return SafeMath.mul(SafeMath.mul(subPlotToPurchase.w, subPlotToPurchase.h), plotPricePerPixel);
    }

     
     
     
     
     
     
     
    function addPlotAndData(uint24[] purchase, string ipfsHash, string url, uint256 initialBuyoutPriceInWeiPerPixel) private returns (uint256) {
        uint256 newPlotIndex = ownership.length;

         
        ownership.push(PlotOwnership(purchase[0], purchase[1], purchase[2], purchase[3], msg.sender));

         
        data[newPlotIndex] = PlotData(ipfsHash, url);

         
        if (initialBuyoutPriceInWeiPerPixel > 0) {
            plotIdToPrice[newPlotIndex] = initialBuyoutPriceInWeiPerPixel;
        }

        return newPlotIndex;
    }
}

library Geometry {
    struct Rect {
        uint24 x;
        uint24 y;
        uint24 w;
        uint24 h;
    }

    function doRectanglesOverlap(Rect memory a, Rect memory b) internal pure returns (bool) {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

     
    function computeRectOverlap(Rect memory a, Rect memory b) internal pure returns (Rect memory) {
        Rect memory result = Rect(0, 0, 0, 0);

         
        result.x = a.x > b.x ? a.x : b.x;
        result.y = a.y > b.y ? a.y : b.y;

         
        uint24 resultX2 = a.x + a.w < b.x + b.w ? a.x + a.w : b.x + b.w;
        uint24 resultY2 = a.y + a.h < b.y + b.h ? a.y + a.h : b.y + b.h;

         
        result.w = resultX2 - result.x;
        result.h = resultY2 - result.y;

        return result;
    }

    function rectContainedInside(Rect memory inner, Rect memory outer) internal pure returns (bool) {
        return inner.x >= outer.x && inner.y >= outer.y && inner.x + inner.w <= outer.x + outer.w && inner.y + inner.h <= outer.y + outer.h;
    }
}