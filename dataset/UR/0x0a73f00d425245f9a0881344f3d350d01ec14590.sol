 

pragma solidity ^0.5.10;

contract Oracle {
    
      
    constructor (uint ethPrice) public {
        admins[msg.sender] = true;
        addAsset("ETHUSD", ethPrice);
    }

    Asset[] public assets;
    uint[8][] private prices;  
    uint[8][] public lastWeekPrices;  
    mapping(address => bool) public admins;
    mapping(address => bool) public readers;
    uint constant DAILY_PRICE_TIME_MIN = 18 hours;  
    uint constant WEEKLY_PRICE_TIME_MIN = 5 days;    
    uint constant EDIT_PRICE_TIME_MAX = 45 minutes;    
    
    struct Asset {
        bytes32 name;
        uint lastPriceUpdateTime;
        uint lastSettlePriceTime;
        uint8 currentDay;
        bool isFinalDay;
    }
    
    event AssetAdded(
        uint indexed id,
        bytes32 name,
        uint price
    );

    event PriceUpdated(
        uint indexed id,
        bytes32 name,
        uint price,
        uint timestamp,
        uint8 dayNumber
    );

    event SettlePrice(
        uint indexed id,
        bytes32 name,
        uint price,
        uint timestamp,
        uint8 dayNumber
    );

    event PriceCorrected(
        uint indexed id,
        bytes32 indexed name, 
        uint price,
        uint timestamp,
        uint8 dayNumber
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
        returns (uint id2)
    {
        require (admins[msg.sender] || msg.sender == address(this));
         
        Asset memory asset;
        asset.name = _name;
        asset.currentDay = 0;
        asset.lastPriceUpdateTime = now;
        asset.lastSettlePriceTime = now - 5 days;
        assets.push(asset);
         
        uint[8] memory _prices;
        lastWeekPrices.push(_prices);
        _prices[0] = _startPrice;
        prices.push(_prices);
        emit AssetAdded(assets.length - 1, _name, _startPrice);
        emit PriceUpdated(assets.length - 1, _name, _startPrice, now, asset.currentDay);
        return assets.length - 1;
    }
    

     
    function editPrice(uint assetID, uint newPrice)
        public
        onlyAdmin
    {
        Asset storage asset = assets[assetID];
        require(now < asset.lastPriceUpdateTime + EDIT_PRICE_TIME_MAX);
        prices[assetID][asset.currentDay] = newPrice;
        emit PriceUpdated(assetID, asset.name, newPrice, now, asset.currentDay);
        emit PriceCorrected(assetID, asset.name, newPrice, now, asset.currentDay);
    }

     
    function addReader(address newReader)
        public
        onlyAdmin
    {
        readers[newReader] = true;
    }
    
     
    function getCurrentPrices(uint id)
        public
        view
        returns (uint[8] memory currentPrices)
    {
        require (admins[msg.sender] || readers[msg.sender]);
        currentPrices = prices[id];
    }

     
    function getCurrentPrice(uint id)
        public
        view
        returns (uint price)
    {
        require (admins[msg.sender] || readers[msg.sender]);    
        price =  prices[id][assets[id].currentDay];
    }

     
    function getLastUpdateTime(uint id)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[id].lastPriceUpdateTime;
    }

     
    function getLastSettleTime(uint id)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[id].lastSettlePriceTime;
    }
     
    function getPriceDay(uint id)
        public
        view
        returns (uint8 currentday)
    {
        if (assets[id].isFinalDay) currentday = 7;
        else currentday = assets[id].currentDay + 1;
    }
    
     
    function isFinalDay(uint id)
        public
        view
        returns (bool)
    {
        return assets[id].isFinalDay;
    }
    
     
    function isSettleDay(uint id)
        public
        view
        returns (bool)
    {
        return (assets[id].currentDay == 0);
    }
   
     
    function removeAdmin(address toRemove)
        public
        onlyAdmin
    {
        require(toRemove != msg.sender);
        admins[toRemove] = false;
    }
    
        
    function setIntraweekPrice(uint assetID, uint price, bool finalDayStatus)
        public
        onlyAdmin
    {
        Asset storage asset = assets[assetID];        
         
        require(now > asset.lastPriceUpdateTime + DAILY_PRICE_TIME_MIN);
        require(!asset.isFinalDay);
        asset.currentDay = asset.currentDay + 1;
        asset.lastPriceUpdateTime = now;
        prices[assetID][asset.currentDay] = price;
        asset.isFinalDay = finalDayStatus;
        emit PriceUpdated(assetID, asset.name, price, now, asset.currentDay);
    }
    
    
     
    function setSettlePrice(uint assetID, uint price)
        public
        onlyAdmin
    {
        Asset storage asset = assets[assetID];
         
        require(now > asset.lastPriceUpdateTime + DAILY_PRICE_TIME_MIN);
        require(now > asset.lastSettlePriceTime + WEEKLY_PRICE_TIME_MIN);
        require(asset.isFinalDay);
         
        lastWeekPrices[assetID] = prices[assetID];
         
        asset.currentDay = 0;
        uint[8] memory newPrices;
        newPrices[0] = price;
        prices[assetID] = newPrices;
        asset.lastPriceUpdateTime = now;
        asset.lastSettlePriceTime = now;
        asset.isFinalDay = false;
        emit PriceUpdated(assetID, asset.name, price, now, asset.currentDay);
        emit SettlePrice(assetID, asset.name, price, now, asset.currentDay);
    }
    
}