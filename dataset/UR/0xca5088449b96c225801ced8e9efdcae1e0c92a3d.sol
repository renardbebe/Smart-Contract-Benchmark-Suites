 

pragma solidity ^0.4.0;

contract EtherTanks {
    
    struct TankHull {
        uint32 armor;  
        uint32 speed;  
        uint8 league;  
    }
    
    struct TankWeapon {
        uint32 minDamage;  
        uint32 maxDamage;  
        uint32 attackSpeed;  
        uint8 league;  
    }
    
    struct TankProduct {
        string name;  
        uint32 hull;  
        uint32 weapon;  
         
         
        uint256 startPrice;
        uint256 currentPrice;  
        uint256 earning;  
        uint256 releaseTime;  
    }
        
    struct TankEntity {
        uint32 productID;
        uint8[4] upgrades;
        address owner;  
        address earner;  
        bool selling;  
        uint256 auctionEntity;  
        uint256 earned;  
        uint32 exp;  
    }
    

    struct AuctionEntity {
        uint32 tankId;
        uint256 startPrice;
        uint256 finishPrice;
        uint256 startTime;
        uint256 duration;
    }
    
    event EventCashOut (
       address indexed player,
       uint256 amount
       );  
    
    event EventLogin (
        address indexed player,
        string hash
        );  
    
    event EventUpgradeTank (
        address indexed player,
        uint32 tankID,
        uint8 upgradeChoice
        );  
    
    event EventTransfer (
        address indexed player,
        address indexed receiver,
        uint32 tankID
        );  
        
    event EventTransferAction (
        address indexed player,
        address indexed receiver,
        uint32 tankID,
        uint8 ActionType
        );  
        
    event EventAuction (
        address indexed player,
        uint32 tankID,
        uint256 startPrice,
        uint256 finishPrice,
        uint256 duration,
        uint256 currentTime
        );  
    event EventCancelAuction (
        uint32 tankID
        );  
    
    event EventBid (
        uint32 tankID  
        );  
    
    event EventProduct (
        uint32 productID,
        string name,
        uint32 hull,
        uint32 weapon,
        uint256 price,
        uint256 earning,
        uint256 releaseTime,
        uint256 currentTime
        );  
        
    event EventBuyTank (
        address indexed player,
        uint32 productID,
        uint32 tankID
        );  

    
    address public UpgradeMaster;  
    address public AuctionMaster;  
    address public TankSellMaster;  
     
     
    
    function ChangeUpgradeMaster (address _newMaster) public {
        require(msg.sender == UpgradeMaster);
        UpgradeMaster = _newMaster;
    }
    
    function ChangeTankSellMaster (address _newMaster) public {
        require(msg.sender == TankSellMaster);
        TankSellMaster = _newMaster;
    }
    
    function ChangeAuctionMaster (address _newMaster) public {
        require(msg.sender == AuctionMaster);
        AuctionMaster = _newMaster;
    }
    
    function EtherTanks() public {
        
        UpgradeMaster = msg.sender;
        AuctionMaster = msg.sender;
        TankSellMaster = msg.sender;

         
        newTankHull(100, 5, 1);
        newTankHull(60, 6, 2);
        newTankHull(140, 4, 1);
        newTankHull(200, 3, 1);
        newTankHull(240, 3, 1);
        newTankHull(200, 6, 2);
        newTankHull(360, 4, 2);
        newTankHull(180, 9, 3);
        newTankHull(240, 8, 3);
        newTankHull(500, 4, 2);
        newTankHull(440, 6, 3);
        
         
        newTankWeapon(6, 14, 5, 1);
        newTankWeapon(18, 26, 3, 2);
        newTankWeapon(44, 66, 2, 1);
        newTankWeapon(21, 49, 3, 1);
        newTankWeapon(60, 90, 2, 2);
        newTankWeapon(21, 49, 2, 2);
        newTankWeapon(48, 72, 3, 2);
        newTankWeapon(13, 29, 9, 3);
        newTankWeapon(36, 84, 4, 3);
        newTankWeapon(120, 180, 2, 3);
        newTankWeapon(72, 108, 4, 3);
        
         
        newTankProduct("LT-1", 1, 1, 10000000000000000, 100000000000000, now);
        newTankProduct("LT-2", 2, 2, 50000000000000000, 500000000000000, now);
        newTankProduct("MT-1", 3, 3, 100000000000000000, 1000000000000000, now);
        newTankProduct("HT-1", 4, 4, 500000000000000000, 5000000000000000, now);
        newTankProduct("SPG-1", 5, 5, 500000000000000000, 5000000000000000, now);
        newTankProduct("MT-2", 6, 6, 700000000000000000, 7000000000000000, now+(60*60*2));
        newTankProduct("HT-2", 7, 7, 1500000000000000000, 15000000000000000, now+(60*60*5));
        newTankProduct("LT-3", 8, 8, 300000000000000000, 3000000000000000, now+(60*60*8));
        newTankProduct("MT-3", 9, 9, 1500000000000000000, 15000000000000000, now+(60*60*24));
        newTankProduct("SPG-2", 10, 10, 2000000000000000000, 20000000000000000, now+(60*60*24*2));
        newTankProduct("HT-3", 11, 11, 2500000000000000000, 25000000000000000, now+(60*60*24*3));
    }
    
    function cashOut (uint256 _amount) public payable {
        require (_amount >= 0);  
        require (_amount == uint256(uint128(_amount)));  
        require (this.balance >= _amount);  
        require (balances[msg.sender] >= _amount);  
        if (_amount == 0){
            _amount = balances[msg.sender];
             
        }
        if (msg.sender.send(_amount)){  
            balances[msg.sender] -= _amount;  
        }
        
        EventCashOut (msg.sender, _amount);
        return;
    }
    
    function login (string _hash) public {
        EventLogin (msg.sender, _hash);
        return;
    }
    
     
     
    function upgradeTank (uint32 _tankID, uint8 _upgradeChoice) public payable {
        require (_tankID > 0 && _tankID < newIdTank);  
        require (tanks[_tankID].owner == msg.sender);  
        require (_upgradeChoice >= 0 && _upgradeChoice < 4);  
        require (tanks[_tankID].upgrades[_upgradeChoice] < 5);  
        require (msg.value >= upgradePrice);  
        tanks[_tankID].upgrades[_upgradeChoice]++;  
        balances[msg.sender] += msg.value-upgradePrice;  
        balances[UpgradeMaster] += upgradePrice;  
        
        EventUpgradeTank (msg.sender, _tankID, _upgradeChoice);
        return;
    }
    
    
     
    function _transfer (uint32 _tankID, address _receiver) public {
        require (_tankID > 0 && _tankID < newIdTank);  
        require (tanks[_tankID].owner == msg.sender);  
        require (msg.sender != _receiver);  
        require (tanks[_tankID].selling == false);  
        tanks[_tankID].owner = _receiver;  
        tanks[_tankID].earner = _receiver;  

        EventTransfer (msg.sender, _receiver, _tankID);
        return;
    }
    
     
    function _transferAction (uint32 _tankID, address _receiver, uint8 _ActionType) public {
        require (_tankID > 0 && _tankID < newIdTank);  
        require (tanks[_tankID].owner == msg.sender);  
        require (msg.sender != _receiver);  
        require (tanks[_tankID].selling == false);  
        tanks[_tankID].owner = _receiver;  
        
         
         
         
         
         
         
         
        
        EventTransferAction (msg.sender, _receiver, _tankID, _ActionType);
        return;
    }
    
     
    function sellTank (uint32 _tankID, uint256 _startPrice, uint256 _finishPrice, uint256 _duration) public {
        require (_tankID > 0 && _tankID < newIdTank);
        require (tanks[_tankID].owner == msg.sender);
        require (tanks[_tankID].selling == false);  
        require (_startPrice >= _finishPrice);
        require (_startPrice > 0 && _finishPrice >= 0);
        require (_duration > 0);
        require (_startPrice == uint256(uint128(_startPrice)));  
        require (_finishPrice == uint256(uint128(_finishPrice)));  
        
        auctions[newIdAuctionEntity] = AuctionEntity(_tankID, _startPrice, _finishPrice, now, _duration);
        tanks[_tankID].selling = true;
        tanks[_tankID].auctionEntity = newIdAuctionEntity++;
        
        EventAuction (msg.sender, _tankID, _startPrice, _finishPrice, _duration, now);
    }
    
     
    function bid (uint32 _tankID) public payable {
        require (_tankID > 0 && _tankID < newIdTank);  
        require (tanks[_tankID].selling == true);  
        AuctionEntity memory currentAuction = auctions[tanks[_tankID].auctionEntity];  
        uint256 currentPrice = currentAuction.startPrice-(((currentAuction.startPrice-currentAuction.finishPrice)/(currentAuction.duration))*(now-currentAuction.startTime));
         
        if (currentPrice < currentAuction.finishPrice){  
            currentPrice = currentAuction.finishPrice;   
        }
        require (currentPrice >= 0);  
        require (msg.value >= currentPrice);  
        
         
        uint256 marketFee = (currentPrice/100)*3;  
        balances[tanks[_tankID].owner] += currentPrice-marketFee;  
        balances[AuctionMaster] += marketFee;  
        balances[msg.sender] += msg.value-currentPrice;  
        tanks[_tankID].owner = msg.sender;  
        tanks[_tankID].selling = false;  
        delete auctions[tanks[_tankID].auctionEntity];  
        tanks[_tankID].auctionEntity = 0;  
        
        EventBid (_tankID);
    }
    
     
    function cancelAuction (uint32 _tankID) public {
        require (_tankID > 0 && _tankID < newIdTank);  
        require (tanks[_tankID].selling == true);  
        require (tanks[_tankID].owner == msg.sender);  
        tanks[_tankID].selling = false;  
        delete auctions[tanks[_tankID].auctionEntity];  
        tanks[_tankID].auctionEntity = 0;  
        
        EventCancelAuction (_tankID);
    }
    
    
    function newTankProduct (string _name, uint32 _hull, uint32 _weapon, uint256 _price, uint256 _earning, uint256 _releaseTime) private {
        tankProducts[newIdTankProduct++] = TankProduct(_name, _hull, _weapon, _price, _price, _earning, _releaseTime);
        
        EventProduct (newIdTankProduct-1, _name, _hull, _weapon, _price, _earning, _releaseTime, now);
    }
    
    function newTankHull (uint32 _armor, uint32 _speed, uint8 _league) private {
        tankHulls[newIdTankHull++] = TankHull(_armor, _speed, _league);
    }
    
    function newTankWeapon (uint32 _minDamage, uint32 _maxDamage, uint32 _attackSpeed, uint8 _league) private {
        tankWeapons[newIdTankWeapon++] = TankWeapon(_minDamage, _maxDamage, _attackSpeed, _league);
    }
    
    function buyTank (uint32 _tankproductID) public payable {
        require (tankProducts[_tankproductID].currentPrice > 0 && msg.value > 0);  
        require (msg.value >= tankProducts[_tankproductID].currentPrice);  
        require (tankProducts[_tankproductID].releaseTime <= now);  
         
         
        
        if (msg.value > tankProducts[_tankproductID].currentPrice){
             
            balances[msg.sender] += msg.value-tankProducts[_tankproductID].currentPrice;
        }
        
        tankProducts[_tankproductID].currentPrice += tankProducts[_tankproductID].earning;
        
        for (uint32 index = 1; index < newIdTank; index++){
            if (tanks[index].productID == _tankproductID){
                balances[tanks[index].earner] += tankProducts[_tankproductID].earning;
                tanks[index].earned += tankProducts[_tankproductID].earning;
            }
        }
        
        if (tanksBeforeTheNewTankType() == 0 && newIdTankProduct <= 121){
            newTankType();
        }
        
        tanks[newIdTank++] = TankEntity (_tankproductID, [0, 0, 0, 0], msg.sender, msg.sender, false, 0, 0, 0);
        
         
         
        balances[TankSellMaster] += tankProducts[_tankproductID].startPrice;
        
        EventBuyTank (msg.sender, _tankproductID, newIdTank-1);
        return;
    }
    
     
    function newTankType () public {
        if (newIdTankProduct > 121){
            return;
        }
         
        if (createNewTankHull < newIdTankHull - 1 && createNewTankWeapon >= newIdTankWeapon - 1) {
            createNewTankWeapon = 1;
            createNewTankHull++;
        } else {
            createNewTankWeapon++;
            if (createNewTankHull == createNewTankWeapon) {
                createNewTankWeapon++;
            }
        }
        newTankProduct ("Tank", uint32(createNewTankHull), uint32(createNewTankWeapon), 200000000000000000, 3000000000000000, now+(60*60));
        return;
    }
    
     
     
    
    uint32 public newIdTank = 1;  
    uint32 public newIdTankProduct = 1;  
    uint32 public newIdTankHull = 1;  
    uint32 public newIdTankWeapon = 1;  
    uint32 public createNewTankHull = 1;  
    uint32 public createNewTankWeapon = 0;  
    uint256 public newIdAuctionEntity = 1;  

    mapping (uint32 => TankEntity) tanks;  
    mapping (uint32 => TankProduct) tankProducts;
    mapping (uint32 => TankHull) tankHulls;
    mapping (uint32 => TankWeapon) tankWeapons;
    mapping (uint256 => AuctionEntity) auctions;
    mapping (address => uint) balances;

    uint256 public constant upgradePrice = 50000000000000000;  

    function getTankName (uint32 _ID) public constant returns (string){
        return tankProducts[_ID].name;
    }
    
    function getTankProduct (uint32 _ID) public constant returns (uint32[6]){
        return [tankHulls[tankProducts[_ID].hull].armor, tankHulls[tankProducts[_ID].hull].speed, tankWeapons[tankProducts[_ID].weapon].minDamage, tankWeapons[tankProducts[_ID].weapon].maxDamage, tankWeapons[tankProducts[_ID].weapon].attackSpeed, uint32(tankProducts[_ID].releaseTime)];
    }
    
    function getTankDetails (uint32 _ID) public constant returns (uint32[6]){
        return [tanks[_ID].productID, uint32(tanks[_ID].upgrades[0]), uint32(tanks[_ID].upgrades[1]), uint32(tanks[_ID].upgrades[2]), uint32(tanks[_ID].upgrades[3]), uint32(tanks[_ID].exp)];
    }
    
    function getTankOwner(uint32 _ID) public constant returns (address){
        return tanks[_ID].owner;
    }
    
    function getTankSell(uint32 _ID) public constant returns (bool){
        return tanks[_ID].selling;
    }
    
    function getTankTotalEarned(uint32 _ID) public constant returns (uint256){
        return tanks[_ID].earned;
    }
    
    function getTankAuctionEntity (uint32 _ID) public constant returns (uint256){
        return tanks[_ID].auctionEntity;
    }
    
    function getCurrentPrice (uint32 _ID) public constant returns (uint256){
        return tankProducts[_ID].currentPrice;
    }
    
    function getProductEarning (uint32 _ID) public constant returns (uint256){
        return tankProducts[_ID].earning;
    }
    
    function getTankEarning (uint32 _ID) public constant returns (uint256){
        return tanks[_ID].earned;
    }
    
    function getCurrentPriceAuction (uint32 _ID) public constant returns (uint256){
        require (getTankSell(_ID));
        AuctionEntity memory currentAuction = auctions[tanks[_ID].auctionEntity];  
        uint256 currentPrice = currentAuction.startPrice-(((currentAuction.startPrice-currentAuction.finishPrice)/(currentAuction.duration))*(now-currentAuction.startTime));
        if (currentPrice < currentAuction.finishPrice){  
            currentPrice = currentAuction.finishPrice;   
        }
        return currentPrice;
    }
    
    function getPlayerBalance(address _player) public constant returns (uint256){
        return balances[_player];
    }
    
    function getContractBalance() public constant returns (uint256){
        return this.balance;
    }
    
    function howManyTanks() public constant returns (uint32){
        return newIdTankProduct;
    }
    
    function tanksBeforeTheNewTankType() public constant returns (uint256){
        return 1000+(((newIdTankProduct)+10)*((newIdTankProduct)+10)*(newIdTankProduct-11))-newIdTank;
    }
}

 