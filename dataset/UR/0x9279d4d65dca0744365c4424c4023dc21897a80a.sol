 

pragma solidity 0.4.19;

contract EtherSpace {
     
    
    address public owner;
    
    struct ShipProduct {
        uint16 class;  
        uint256 startPrice;  
        uint256 currentPrice;  
        uint256 earning;  
        uint64 amount;  
    }
    
    struct ShipEntity {
        uint16 model;
        address owner;  
        uint64 lastCashoutIndex;  
        bool battle;
        uint32 battleWins;
        uint32 battleLosses;
    }
    
     
     
     
     
     
     
     
    
    event EventCashOut (
        address indexed player,
        uint256 amount
    );
        
    event EventBuyShip (
        address indexed player,
        uint16 productID,
        uint64 shipID
    );
    
    event EventAddToBattle (
        address indexed player,
        uint64 id
    );
    event EventRemoveFromBattle (
        address indexed player,
        uint64 id
    );
    event EventBattle (
        address indexed player,
        uint64 id,
        uint64 idToAttack,
        uint64 idWinner
    );
        
    function EtherSpace() public {
        owner = msg.sender;
        
        newShipProduct(0,   50000000000000000,   500000000000000);  
        newShipProduct(0,   70000000000000000,   700000000000000);  
        newShipProduct(0,   70000000000000000,   700000000000000);  
        newShipProduct(0,   70000000000000000,   700000000000000);  
        newShipProduct(0,  100000000000000000,  1000000000000000);  
        newShipProduct(0,  100000000000000000,  1000000000000000);  
        newShipProduct(0,  300000000000000000,  3000000000000000);  
        newShipProduct(0,  300000000000000000,  3000000000000000);  
        newShipProduct(0,  500000000000000000,  5000000000000000);  
        newShipProduct(0,  500000000000000000,  5000000000000000);  
        newShipProduct(0,  700000000000000000,  7000000000000000);  
        newShipProduct(0,  700000000000000000,  7000000000000000);  
        newShipProduct(0,  750000000000000000,  7500000000000000);  
        newShipProduct(0, 1000000000000000000, 10000000000000000);  
        newShipProduct(0, 2300000000000000000, 23000000000000000);  
    }
    
    uint64 public newIdShip = 0;  
    uint16 public newModelShipProduct = 0;  
    mapping (uint64 => ShipEntity) public ships;  
    mapping (uint16 => ShipProduct) shipProducts;
    mapping (address => uint64[]) shipOwners;
    mapping (address => uint) balances;
    
    function newShipProduct (uint16 _class, uint256 _price, uint256 _earning) private {
        shipProducts[newModelShipProduct++] = ShipProduct(_class, _price, _price, _earning, 0);
        
         
    }
    
    function cashOut () public payable {  
        uint _balance = balances[msg.sender];
        
        for (uint64 index=0; index<shipOwners[msg.sender].length; index++) {
            uint64 id = shipOwners[msg.sender][index];  
            uint16 model = ships[id].model;  
            
            _balance += shipProducts[model].earning * (shipProducts[model].amount - ships[id].lastCashoutIndex);

            ships[id].lastCashoutIndex = shipProducts[model].amount;
        }
        
        require (this.balance >= _balance);  
        
        balances[msg.sender] = 0;
        msg.sender.transfer(_balance);
        
        EventCashOut (msg.sender, _balance);
        return;
    }
    
    function buyShip (uint16 _shipModel) public payable {
        require (msg.value >= shipProducts[_shipModel].currentPrice);  
        require (shipOwners[msg.sender].length <= 10);  

        if (msg.value > shipProducts[_shipModel].currentPrice){
             
            balances[msg.sender] += msg.value - shipProducts[_shipModel].currentPrice;
        }
        
        shipProducts[_shipModel].currentPrice += shipProducts[_shipModel].earning;
    
        ships[newIdShip++] = ShipEntity(_shipModel, msg.sender, ++shipProducts[_shipModel].amount, false, 0, 0);

        shipOwners[msg.sender].push(newIdShip-1);

         
         
        balances[owner] += shipProducts[_shipModel].startPrice;
        
        EventBuyShip (msg.sender, _shipModel, newIdShip-1);
        return;
    }
    
     
    function newShip (uint16 _class, uint256 _price, uint256 _earning) public {
        require (owner == msg.sender);
        
        shipProducts[newModelShipProduct++] = ShipProduct(_class, _price, _price, _earning, 0);
    }
    
    function changeOwner(address _newOwner) public {
        require (owner == msg.sender);
        
        owner = _newOwner;
    }
    
     
    
    uint battleStake = 50000000000000000;  
    uint battleFee = 5000000000000000;  
    
    uint nonce = 0;
    function rand(uint min, uint max) public returns (uint){
        nonce++;
        return uint(sha3(nonce+uint256(block.blockhash(block.number-1))))%(min+max+1)-min;
    }
    
    function addToBattle(uint64 _id) public payable {
        require (msg.value == battleStake);  
        require (msg.sender == ships[_id].owner);  
        
        ships[_id].battle = true;
        
        EventAddToBattle(msg.sender, _id);
    }
    function removeFromBattle(uint64 _id) public {
        require (msg.sender == ships[_id].owner);  
        
        ships[_id].battle = false;
        balances[msg.sender] += battleStake;
        
        EventRemoveFromBattle(msg.sender, _id);
    }
    
    function battle(uint64 _id, uint64 _idToAttack) public payable {
        require (msg.sender == ships[_id].owner);  
        require (msg.value == battleStake);  
        require (ships[_idToAttack].battle == true);  
        require (ships[_id].battle == false);  
        
        uint randNumber = rand(0,1);
        
        if (randNumber == 1) {
            ships[_id].battleWins++;
            ships[_idToAttack].battleLosses++;
            
            balances[ships[_id].owner] += (battleStake * 2) - battleFee;
            
            EventBattle(msg.sender, _id, _idToAttack, _id);
            
        } else {
            ships[_id].battleLosses++;
            ships[_idToAttack].battleWins++;
            
            balances[ships[_idToAttack].owner] += (battleStake * 2) - battleFee;
            
            EventBattle(msg.sender, _id, _idToAttack, _idToAttack);
        }
        
        balances[owner] += battleFee;
        
        ships[_idToAttack].battle = false;
    }
    
     
    function getPlayerShipModelById(uint64 _id) public constant returns (uint16) {
        return ships[_id].model;
    }
    function getPlayerShipOwnerById(uint64 _id) public constant returns (address) {
        return ships[_id].owner;
    }
    function getPlayerShipBattleById(uint64 _id) public constant returns (bool) {
        return ships[_id].battle;
    }
    function getPlayerShipBattleWinsById(uint64 _id) public constant returns (uint32) {
        return ships[_id].battleWins;
    }
    function getPlayerShipBattleLossesById(uint64 _id) public constant returns (uint32) {
        return ships[_id].battleLosses;
    }
    
    function getPlayerShipCount(address _player) public constant returns (uint) {
        return shipOwners[_player].length;
    }
    
    function getPlayerShipModelByIndex(address _player, uint index) public constant returns (uint16) {
        return ships[shipOwners[_player][index]].model;
    }
    
    function getPlayerShips(address _player) public constant returns (uint64[]) {
        return shipOwners[_player];
    }
    
    function getPlayerBalance(address _player) public constant returns (uint256) {
        uint _balance = balances[_player];
        
        for (uint64 index=0; index<shipOwners[_player].length; index++) {
            uint64 id = shipOwners[_player][index];  
            uint16 model = ships[id].model;  

            _balance += shipProducts[model].earning * (shipProducts[model].amount - ships[id].lastCashoutIndex);
        }
        
        return _balance;
    }
    
    function getShipProductClassByModel(uint16 _model) public constant returns (uint16) {
        return shipProducts[_model].class;
    }
    function getShipProductStartPriceByModel(uint16 _model) public constant returns (uint256) {
        return shipProducts[_model].startPrice;
    }
    function getShipProductCurrentPriceByModel(uint16 _model) public constant returns (uint256) {
        return shipProducts[_model].currentPrice;
    }
    function getShipProductEarningByModel(uint16 _model) public constant returns (uint256) {
        return shipProducts[_model].earning;
    }
    function getShipProductAmountByModel(uint16 _model) public constant returns (uint64) {
        return shipProducts[_model].amount;
    }
    
    function getShipProductCount() public constant returns (uint16) {
        return newModelShipProduct;
    }
    function getShipCount() public constant returns (uint64) {
        return newIdShip;
    }
}