 

pragma solidity ^0.4.0;

 

contract EtherShipsCore {

    struct ShipProduct {
        string name;  
        uint32 armor;  
        uint32 speed;  
        uint32 minDamage;  
        uint32 maxDamage;  
        uint32 attackSpeed;  
        uint8 league;  
         
         
        uint256 startPrice;
        uint256 currentPrice;  
        uint256 earning;  
        uint256 releaseTime;  
        uint32 amountOfShips;  

    }

    struct ShipEntity {
        uint32 productID;
        uint8[4] upgrades;
        address owner;  
        address earner;  
        bool selling;  
        uint256 auctionEntity;  
        uint256 earned;  
        uint32 exp;  
        uint32 lastCashoutIndex;  
    }

    struct AuctionEntity {
        uint32 shipID;
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

    event EventUpgradeShip (
        address indexed player,
        uint32 shipID,
        uint8 upgradeChoice
        );  

    event EventTransfer (
        address indexed player,
        address indexed receiver,
        uint32 shipID
        );  

    event EventTransferAction (
        address indexed player,
        address indexed receiver,
        uint32 shipID,
        uint8 ActionType
        );  

    event EventAuction (
        address indexed player,
        uint32 shipID,
        uint256 startPrice,
        uint256 finishPrice,
        uint256 duration,
        uint256 currentTime
        );  
        
    event EventCancelAuction (
        uint32 shipID
        );  

    event EventBid (
        uint32 shipID
        );  

    event EventBuyShip (
        address indexed player,
        uint32 productID,
        uint32 shipID
        );  

    address public UpgradeMaster;  
    address public AuctionMaster;  
    address public ShipSellMaster;  

    function ChangeUpgradeMaster (address _newMaster) public {
        require(msg.sender == UpgradeMaster);
        UpgradeMaster = _newMaster;
    }

    function ChangeShipSellMaster (address _newMaster) public {
        require(msg.sender == ShipSellMaster);
        ShipSellMaster = _newMaster;
    }

    function ChangeAuctionMaster (address _newMaster) public {
        require(msg.sender == AuctionMaster);
        AuctionMaster = _newMaster;
    }

    function EtherShipsCore() public {

        UpgradeMaster = msg.sender;
        AuctionMaster = msg.sender;
        ShipSellMaster = msg.sender;

         
         
        
        newShipProduct("L-Raz", 50, 5, 5, 40, 5, 1, 50000000000000000, 500000000000000, now);
        newShipProduct("L-Vip", 50, 4, 6, 35, 6, 1, 50000000000000000, 500000000000000, now+(60*60*3));
        newShipProduct("L-Rapt", 50, 5, 5, 35, 5, 1, 50000000000000000, 500000000000000, now+(60*60*6));
        newShipProduct("L-Slash", 50, 5, 5, 30, 6, 1, 50000000000000000, 500000000000000, now+(60*60*12));
        newShipProduct("L-Stin", 50, 5, 5, 40, 5, 1, 50000000000000000, 500000000000000, now+(60*60*24));
        newShipProduct("L-Scor", 50, 4, 5, 35, 5, 1, 50000000000000000, 500000000000000, now+(60*60*48));
        
        newShipProduct("Sub-Sc", 60, 5, 45, 115, 4, 2, 100000000000000000, 1000000000000000, now);
        newShipProduct("Sub-Cycl", 70, 4, 40, 115, 4, 2, 100000000000000000, 1000000000000000, now+(60*60*6));
        newShipProduct("Sub-Deep", 80, 5, 45, 120, 4, 2, 100000000000000000, 1000000000000000, now+(60*60*12));
        newShipProduct("Sub-Sp", 90, 4, 50, 120, 3, 2, 100000000000000000, 1000000000000000, now+(60*60*24));
        newShipProduct("Sub-Ab", 100, 5, 55, 130, 3, 2, 100000000000000000, 1000000000000000, now+(60*60*48));

        newShipProduct("M-Sp", 140, 4, 40, 120, 4, 3, 200000000000000000, 2000000000000000, now);
        newShipProduct("M-Arma", 150, 4, 40, 115, 5, 3, 200000000000000000, 2000000000000000, now+(60*60*12));
        newShipProduct("M-Penetr", 160, 4, 35, 120, 6, 3, 200000000000000000, 2000000000000000, now+(60*60*24));
        newShipProduct("M-Slice", 170, 4, 45, 120, 3, 3, 200000000000000000, 2000000000000000, now+(60*60*36));
        newShipProduct("M-Hell", 180, 3, 35, 120, 2, 3, 200000000000000000, 2000000000000000, now+(60*60*48));

        newShipProduct("H-Haw", 210, 3, 65, 140, 3, 4, 400000000000000000, 4000000000000000, now);
        newShipProduct("H-Fat", 220, 3, 75, 150, 2, 4, 400000000000000000, 4000000000000000, now+(60*60*24));
        newShipProduct("H-Beh", 230, 2, 85, 160, 2, 4, 400000000000000000, 4000000000000000, now+(60*60*48));
        newShipProduct("H-Mamm", 240, 2, 100, 170, 2, 4, 400000000000000000, 4000000000000000, now+(60*60*72));
        newShipProduct("H-BigM", 250, 2, 120, 180, 3, 4, 400000000000000000, 4000000000000000, now+(60*60*96));

    }

    function cashOut (uint256 _amount) public payable {

        require (_amount >= 0);  
        require (_amount == uint256(uint128(_amount)));  
        require (this.balance >= _amount);  
        require (balances[msg.sender] >= _amount);  
        if (_amount == 0){
            _amount = balances[msg.sender];
             
        }

        balances[msg.sender] -= _amount;  

        if (!msg.sender.send(_amount)){  
            balances[msg.sender] += _amount;  
        }

        EventCashOut (msg.sender, _amount);
        return;
    }

    function cashOutShip (uint32 _shipID) public payable {

        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].owner == msg.sender);  
        uint256 _amount = shipProducts[ships[_shipID].productID].earning*(shipProducts[ships[_shipID].productID].amountOfShips-ships[_shipID].lastCashoutIndex);
        require (this.balance >= _amount);  
        require (_amount > 0);

        uint32 lastIndex = ships[_shipID].lastCashoutIndex;

        ships[_shipID].lastCashoutIndex = shipProducts[ships[_shipID].productID].amountOfShips;  

        if (!ships[_shipID].owner.send(_amount)){  
            ships[_shipID].lastCashoutIndex = lastIndex;  
        }

        EventCashOut (msg.sender, _amount);
        return;
    }

    function login (string _hash) public {
        EventLogin (msg.sender, _hash);
        return;
    }

     
     
    function upgradeShip (uint32 _shipID, uint8 _upgradeChoice) public payable {
        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].owner == msg.sender);  
        require (_upgradeChoice >= 0 && _upgradeChoice < 4);  
        require (ships[_shipID].upgrades[_upgradeChoice] < 5);  
        require (msg.value >= upgradePrice);  
        ships[_shipID].upgrades[_upgradeChoice]++;  
        balances[msg.sender] += msg.value-upgradePrice;  
        balances[UpgradeMaster] += upgradePrice;  

        EventUpgradeShip (msg.sender, _shipID, _upgradeChoice);
        return;
    }


     
    function _transfer (uint32 _shipID, address _receiver) public {
        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].owner == msg.sender);  
        require (msg.sender != _receiver);  
        require (ships[_shipID].selling == false);  
        ships[_shipID].owner = _receiver;  
        ships[_shipID].earner = _receiver;  

        EventTransfer (msg.sender, _receiver, _shipID);
        return;
    }

     
    function _transferAction (uint32 _shipID, address _receiver, uint8 _ActionType) public {
        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].owner == msg.sender);  
        require (msg.sender != _receiver);  
        require (ships[_shipID].selling == false);  
        ships[_shipID].owner = _receiver;  

         
         
         
         
         
         
         

        EventTransferAction (msg.sender, _receiver, _shipID, _ActionType);
        return;
    }

     
    function sellShip (uint32 _shipID, uint256 _startPrice, uint256 _finishPrice, uint256 _duration) public {
        require (_shipID > 0 && _shipID < newIdShip);
        require (ships[_shipID].owner == msg.sender);
        require (ships[_shipID].selling == false);  
        require (_startPrice >= _finishPrice);
        require (_startPrice > 0 && _finishPrice >= 0);
        require (_duration > 0);
        require (_startPrice == uint256(uint128(_startPrice)));  
        require (_finishPrice == uint256(uint128(_finishPrice)));  

        auctions[newIdAuctionEntity] = AuctionEntity(_shipID, _startPrice, _finishPrice, now, _duration);
        ships[_shipID].selling = true;
        ships[_shipID].auctionEntity = newIdAuctionEntity++;

        EventAuction (msg.sender, _shipID, _startPrice, _finishPrice, _duration, now);
    }

     
    function bid (uint32 _shipID) public payable {
        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].selling == true);  
        AuctionEntity memory currentAuction = auctions[ships[_shipID].auctionEntity];  
        uint256 currentPrice = currentAuction.startPrice-(((currentAuction.startPrice-currentAuction.finishPrice)/(currentAuction.duration))*(now-currentAuction.startTime));
         
        if (currentPrice < currentAuction.finishPrice){  
            currentPrice = currentAuction.finishPrice;   
        }
        require (currentPrice >= 0);  
        require (msg.value >= currentPrice);  

         
        uint256 marketFee = (currentPrice/100)*3;  
        balances[ships[_shipID].owner] += currentPrice-marketFee;  
        balances[AuctionMaster] += marketFee;  
        balances[msg.sender] += msg.value-currentPrice;  
        ships[_shipID].owner = msg.sender;  
        ships[_shipID].selling = false;  
        delete auctions[ships[_shipID].auctionEntity];  
        ships[_shipID].auctionEntity = 0;  

        EventBid (_shipID);
    }

     
    function cancelAuction (uint32 _shipID) public {
        require (_shipID > 0 && _shipID < newIdShip);  
        require (ships[_shipID].selling == true);  
        require (ships[_shipID].owner == msg.sender);  
        ships[_shipID].selling = false;  
        delete auctions[ships[_shipID].auctionEntity];  
        ships[_shipID].auctionEntity = 0;  

        EventCancelAuction (_shipID);
    }


    function newShipProduct (string _name, uint32 _armor, uint32 _speed, uint32 _minDamage, uint32 _maxDamage, uint32 _attackSpeed, uint8 _league, uint256 _price, uint256 _earning, uint256 _releaseTime) private {
        shipProducts[newIdShipProduct++] = ShipProduct(_name, _armor, _speed, _minDamage, _maxDamage, _attackSpeed, _league, _price, _price, _earning, _releaseTime, 0);
    }

    function buyShip (uint32 _shipproductID) public payable {
        require (shipProducts[_shipproductID].currentPrice > 0 && msg.value > 0);  
        require (msg.value >= shipProducts[_shipproductID].currentPrice);  
        require (shipProducts[_shipproductID].releaseTime <= now);  
         
         

        if (msg.value > shipProducts[_shipproductID].currentPrice){
             
            balances[msg.sender] += msg.value-shipProducts[_shipproductID].currentPrice;
        }

        shipProducts[_shipproductID].currentPrice += shipProducts[_shipproductID].earning;

        ships[newIdShip++] = ShipEntity (_shipproductID, [0, 0, 0, 0], msg.sender, msg.sender, false, 0, 0, 0, ++shipProducts[_shipproductID].amountOfShips);

         
         
        balances[ShipSellMaster] += shipProducts[_shipproductID].startPrice;

        EventBuyShip (msg.sender, _shipproductID, newIdShip-1);
        return;
    }

     
     

    uint32 public newIdShip = 1;  
    uint32 public newIdShipProduct = 1;  
    uint256 public newIdAuctionEntity = 1;  

    mapping (uint32 => ShipEntity) ships;  
    mapping (uint32 => ShipProduct) shipProducts;
    mapping (uint256 => AuctionEntity) auctions;
    mapping (address => uint) balances;

    uint256 public constant upgradePrice = 5000000000000000;  

    function getShipName (uint32 _ID) public constant returns (string){
        return shipProducts[_ID].name;
    }

    function getShipProduct (uint32 _ID) public constant returns (uint32[7]){
        return [shipProducts[_ID].armor, shipProducts[_ID].speed, shipProducts[_ID].minDamage, shipProducts[_ID].maxDamage, shipProducts[_ID].attackSpeed, uint32(shipProducts[_ID].releaseTime), uint32(shipProducts[_ID].league)];
    }

    function getShipDetails (uint32 _ID) public constant returns (uint32[6]){
        return [ships[_ID].productID, uint32(ships[_ID].upgrades[0]), uint32(ships[_ID].upgrades[1]), uint32(ships[_ID].upgrades[2]), uint32(ships[_ID].upgrades[3]), uint32(ships[_ID].exp)];
    }

    function getShipOwner(uint32 _ID) public constant returns (address){
        return ships[_ID].owner;
    }

    function getShipSell(uint32 _ID) public constant returns (bool){
        return ships[_ID].selling;
    }

    function getShipTotalEarned(uint32 _ID) public constant returns (uint256){
        return ships[_ID].earned;
    }

    function getShipAuctionEntity (uint32 _ID) public constant returns (uint256){
        return ships[_ID].auctionEntity;
    }

    function getCurrentPrice (uint32 _ID) public constant returns (uint256){
        return shipProducts[_ID].currentPrice;
    }

    function getProductEarning (uint32 _ID) public constant returns (uint256){
        return shipProducts[_ID].earning;
    }

    function getShipEarning (uint32 _ID) public constant returns (uint256){
        return shipProducts[ships[_ID].productID].earning*(shipProducts[ships[_ID].productID].amountOfShips-ships[_ID].lastCashoutIndex);
    }

    function getCurrentPriceAuction (uint32 _ID) public constant returns (uint256){
        require (getShipSell(_ID));
        AuctionEntity memory currentAuction = auctions[ships[_ID].auctionEntity];  
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

    function howManyShips() public constant returns (uint32){
        return newIdShipProduct;
    }

}

 