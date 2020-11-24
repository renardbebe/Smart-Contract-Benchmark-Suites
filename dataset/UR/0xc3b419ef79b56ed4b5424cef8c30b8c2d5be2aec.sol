 

pragma solidity ^0.5.11;

contract Oracle {

     
    constructor (uint ethPrice) public {
        admins[msg.sender] = true;
        addAsset("ETHUSD", ethPrice);
    }
    Asset[] public assets;
    uint[8][] private prices; 
    mapping(address => bool) public admins;
    mapping(address => bool) public readers;
     
     
    uint public constant UPDATE_TIME_MIN = 20 hours;  
     
    uint public constant SETTLE_TIME_MIN = 5 days;   
     
    uint public constant EDIT_TIME_MAX = 30 minutes;  
    
    struct Asset {
        bytes32 name;
        uint8 currentDay;
        uint lastUpdateTime;
        uint lastSettleTime;
        bool isFinalDay;
    }

    event PriceUpdated(
        uint indexed id,
        bytes32 indexed name,
        uint price,
        uint timestamp,
        uint8 dayNumber,
        bool isCorrection
    );

        modifier onlyAdmin()
    {
        require(admins[msg.sender]);
        _;
    }

     
    function addAdmin(address newAdmin)
        public
        onlyAdmin
    {
        admins[newAdmin] = true;
    }

     
    function addAsset(bytes32 _name, uint _startPrice)
        public
        returns (uint _assetID)
    {
        require (admins[msg.sender] || msg.sender == address(this));
         
        Asset memory asset;
        asset.name = _name;
        asset.currentDay = 0;
        asset.lastUpdateTime = now;
        asset.lastSettleTime = now - 5 days;
        assets.push(asset);
        uint[8] memory _prices;
        _prices[0] = _startPrice;
        prices.push(_prices);
        return assets.length - 1;
    }
     
    
    function editPrice(uint _assetID, uint _newPrice)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
        require(now < asset.lastUpdateTime + EDIT_TIME_MAX);
        prices[_assetID][asset.currentDay] = _newPrice;
        emit PriceUpdated(_assetID, asset.name, _newPrice, now, asset.currentDay, true);
    }

     
    function addReader(address newReader)
        public
        onlyAdmin
    {
        readers[newReader] = true;
    }

     
    function getPrices(uint _assetID)
        public
        view
        returns (uint[8] memory _priceHist)
    {
        require (admins[msg.sender] || readers[msg.sender]);
        _priceHist = prices[_assetID];
    }
    
     
    function getStalePrices(uint _assetID)
        public
        view
        returns (uint[8] memory _priceHist)
    {
        _priceHist = prices[_assetID];
        _priceHist[assets[_assetID].currentDay]=0;
    }

     
    function getCurrentPrice(uint _assetID)
        public
        view
        returns (uint _price)
    {
        require (admins[msg.sender] || readers[msg.sender]);
        _price =  prices[_assetID][assets[_assetID].currentDay];
    }

     
    function getLastUpdateTime(uint _assetID)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[_assetID].lastUpdateTime;
    }

     
    function getLastSettleTime(uint _assetID)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[_assetID].lastSettleTime;
    }
    
     
    function getStartDay(uint _assetID)
        public
        view
        returns (uint8 _startDay)
    {
        if (assets[_assetID].isFinalDay) _startDay = 7;
        else if (assets[_assetID].currentDay == 7) _startDay = 1;
        else _startDay = assets[_assetID].currentDay + 1;
    }

      
    function isPenultimateUpdate(uint _assetID)
        public
        view
        returns (bool)
    {
        return assets[_assetID].isFinalDay;
    }

     
    function isSettleDay(uint _assetID)
        public
        view
        returns (bool)
    {
        return (assets[_assetID].currentDay == 7);
    }

     
    function removeAdmin(address toRemove)
        public
        onlyAdmin
    {
        require(toRemove != msg.sender);
        admins[toRemove] = false;
    }

      
    function intraWeekPrice(uint _assetID, uint _price, bool finalDayStatus)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
         
        require(now > asset.lastUpdateTime + UPDATE_TIME_MIN);
         
        require(!asset.isFinalDay);
        if (asset.currentDay == 7) {
             asset.currentDay = 1;
             uint[8] memory newPrices;
              
             newPrices[0] = prices[_assetID][7];
             newPrices[1] = _price;
             prices[_assetID] = newPrices;
        } else {
            asset.currentDay = asset.currentDay + 1;
            prices[_assetID][asset.currentDay] = _price;
            asset.isFinalDay = finalDayStatus;
        }
        asset.lastUpdateTime = now;
        emit PriceUpdated(_assetID, asset.name, _price, now, asset.currentDay, false);
    }
    
     
    function settlePrice(uint _assetID, uint _price)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
         
        require(now > asset.lastUpdateTime + UPDATE_TIME_MIN);
         
        require(asset.isFinalDay);
         
        require(now > asset.lastSettleTime + SETTLE_TIME_MIN,
            "Sufficient time must pass between weekly price updates.");
             
             asset.currentDay = 7;
             prices[_assetID][7] = _price;
             asset.lastSettleTime = now;
             asset.isFinalDay = false;
        asset.lastUpdateTime = now;
        emit PriceUpdated(_assetID, asset.name, _price, now, 7, false);
        
    }

}