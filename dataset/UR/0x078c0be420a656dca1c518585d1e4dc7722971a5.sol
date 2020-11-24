 

pragma solidity 0.4.24;

 
library SafeMath {
   
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address internal contractOwner;

  constructor () internal {
    if(contractOwner == address(0)){
      contractOwner = msg.sender;
    }
  }

   
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    contractOwner = newOwner;
  }

}

contract MyCryptoChampCore{
    struct Champ {
        uint id;
        uint attackPower;
        uint defencePower;
        uint cooldownTime; 
        uint readyTime;
        uint winCount;
        uint lossCount;
        uint position; 
        uint price; 
        uint withdrawCooldown; 
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; 
    }
    
    struct AddressInfo {
        uint withdrawal;
        uint champsCount;
        uint itemsCount;
        string name;
    }

    struct Item {
        uint id;
        uint8 itemType; 
        uint8 itemRarity; 
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId; 
        bool onChamp; 
        bool forSale;
    }
    
    Champ[] public champs;
    Item[] public items;
    mapping (uint => uint) public leaderboard;
    mapping (address => AddressInfo) public addressInfo;
    mapping (bool => mapping(address => mapping (address => bool))) public tokenOperatorApprovals;
    mapping (bool => mapping(uint => address)) public tokenApprovals;
    mapping (bool => mapping(uint => address)) public tokenToOwner;
    mapping (uint => string) public champToName;
    mapping (bool => uint) public tokensForSaleCount;
    uint public pendingWithdrawal = 0;

    function addWithdrawal(address _address, uint _amount) public;
    function clearTokenApproval(address _from, uint _tokenId, bool _isTokenChamp) public;
    function setChampsName(uint _champId, string _name) public;
    function setLeaderboard(uint _x, uint _value) public;
    function setTokenApproval(uint _id, address _to, bool _isTokenChamp) public;
    function setTokenOperatorApprovals(address _from, address _to, bool _approved, bool _isTokenChamp) public;
    function setTokenToOwner(uint _id, address _owner, bool _isTokenChamp) public;
    function setTokensForSaleCount(uint _value, bool _isTokenChamp) public;
    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) public;
    function newChamp(uint _attackPower,uint _defencePower,uint _cooldownTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale,address _owner) public returns (uint);
    function newItem(uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale,address _owner) public returns (uint);
    function updateAddressInfo(address _address, uint _withdrawal, bool _updatePendingWithdrawal, uint _champsCount, bool _updateChampsCount, uint _itemsCount, bool _updateItemsCount, string _name, bool _updateName) public;
    function updateChamp(uint _champId, uint _attackPower,uint _defencePower,uint _cooldownTime,uint _readyTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _withdrawCooldown,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale) public;
    function updateItem(uint _id,uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale) public;

    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256);
    function getChampsByOwner(address _owner) external view returns(uint256[]);
    function getTokensForSale(bool _isTokenChamp) view external returns(uint256[]);
    function getItemsByOwner(address _owner) external view returns(uint256[]);
    function getTokenCount(bool _isTokenChamp) external view returns(uint);
    function getTokenURIs(uint _tokenId, bool _isTokenChamp) public view returns(string);
    function onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) external view returns(bool);
    
}

contract Inherit is Ownable{
  address internal coreAddress;
  MyCryptoChampCore internal core;

  modifier onlyCore(){
    require(msg.sender == coreAddress);
    _;
  }

  function loadCoreAddress(address newCoreAddress) public onlyOwner {
    require(newCoreAddress != address(0));
    coreAddress = newCoreAddress;
    core = MyCryptoChampCore(coreAddress);
  }

}

contract Strings {

    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

}

 
interface EC {
    function emitTransfer(address _from, address _to, uint _tokenId) external;  
}

 
contract Controller is Inherit, Strings {

    using SafeMath for uint; 

    struct Champ {
        uint id;  
        uint attackPower;
        uint defencePower;
        uint cooldownTime;  
        uint readyTime;  
        uint winCount;
        uint lossCount;
        uint position;  
        uint price;  
        uint withdrawCooldown;  
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale;  
    }

    struct Item {
        uint id;
        uint8 itemType;  
        uint8 itemRarity;  
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId;  
        bool onChamp; 
        bool forSale;  
    }

    EC champsEC;
    EC itemsEC;
     
     
    modifier contractMinBalanceReached(){
        uint pendingWithdrawal = core.pendingWithdrawal();
        require( (address(core).balance).sub(pendingWithdrawal) > 1000000 );
        _;
    }
    
    modifier onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) 
    {
        require(core.onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp));
        _;
    }
    

     
    function getChampReward(uint _position) public view returns(uint) 
    {
        if(_position <= 800){
             
             
             
             
            uint rewardPercentage = uint(2000).sub(2 * (_position - 1));

             
            uint availableWithdrawal = address(coreAddress).balance.sub(core.pendingWithdrawal());

             
             
            return availableWithdrawal / 1000000 * rewardPercentage;
        }else{
            return uint(0);
        }
    }

    function setChampEC(address _address) public onlyOwner {
        champsEC = EC(_address);
    }


    function setItemsEC(address _address) public onlyOwner {
        itemsEC = EC(_address);
    }

    function changeChampsName(uint _champId, string _name, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true)
    onlyCore
    {
        core.setChampsName(_champId, _name);
    }

     
    function withdrawChamp(uint _id, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_id, _msgsender, true) 
    contractMinBalanceReached  
    onlyCore 
    {
        Champ memory champ = _getChamp(_id);
        require(champ.position <= 800); 
        require(champ.withdrawCooldown < block.timestamp);  

        champ.withdrawCooldown = block.timestamp + 1 days;  
        _updateChamp(champ);  

        core.addWithdrawal(_msgsender, getChampReward(champ.position));
    }
    

     
    function _attackCompleted(Champ memory _winnerChamp, Champ memory _defeatedChamp, uint _pointsGiven) private 
    {
         
         
        _winnerChamp.attackPower += _pointsGiven;  
        _winnerChamp.defencePower += _pointsGiven;  
                
         
         
         
        _defeatedChamp.attackPower = (_defeatedChamp.attackPower <= _pointsGiven + 2) ? 2 : _defeatedChamp.attackPower - _pointsGiven;  

         
        _defeatedChamp.defencePower = (_defeatedChamp.defencePower <= _pointsGiven) ? 1 : _defeatedChamp.defencePower - _pointsGiven;  


         
        _winnerChamp.winCount++;
        _defeatedChamp.lossCount++;
            

         
        if(_winnerChamp.position > _defeatedChamp.position) {  
            uint winnerPosition = _winnerChamp.position;
            uint loserPosition = _defeatedChamp.position;
        
            _defeatedChamp.position = winnerPosition;
            _winnerChamp.position = loserPosition;
        }

        _updateChamp(_winnerChamp);
        _updateChamp(_defeatedChamp);
    }


     
    function attack(uint _champId, uint _targetId, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
    onlyCore 
    {
        Champ memory myChamp = _getChamp(_champId); 
        Champ memory enemyChamp = _getChamp(_targetId); 
        
        require (myChamp.readyTime <= block.timestamp);  
        require(_champId != _targetId);  
        require(core.tokenToOwner(true, _targetId) != address(0));  
    
        uint pointsGiven;  
        uint myChampAttackPower;  
        uint enemyChampDefencePower; 
        uint myChampCooldownReduction;
        
        (myChampAttackPower,,myChampCooldownReduction) = core.getChampStats(_champId);
        (,enemyChampDefencePower,) = core.getChampStats(_targetId);


         
        if (myChampAttackPower > enemyChampDefencePower) {
            
             
             
            if(myChampAttackPower - enemyChampDefencePower < 5){
                pointsGiven = 6;  
            }else if(myChampAttackPower - enemyChampDefencePower < 10){
                pointsGiven = 4;  
            }else{
                pointsGiven = 2;  
            }
            
            _attackCompleted(myChamp, enemyChamp, pointsGiven/2);

        } else {
            
             
            pointsGiven = 2;

            _attackCompleted(enemyChamp, myChamp, pointsGiven/2);
             
        }
        
         
        myChamp.readyTime = uint(block.timestamp + myChamp.cooldownTime - myChampCooldownReduction);

        _updateChamp(myChamp);

    }

     function _cancelChampSale(Champ memory _champ) private 
     {
         
         
        _champ.forSale = false;

         

        _updateChamp(_champ);
     }
     

    function _transferChamp(address _from, address _to, uint _champId) private onlyCore
    {
        Champ memory champ = _getChamp(_champId);

         
        if(champ.forSale){
             _cancelChampSale(champ);
        }

        core.clearTokenApproval(_from, _champId, true);

         
        (,uint toChampsCount,,) = core.addressInfo(_to); 
        (,uint fromChampsCount,,) = core.addressInfo(_from);

        core.updateAddressInfo(_to,0,false,toChampsCount + 1,true,0,false,"",false);
        core.updateAddressInfo(_from,0,false,fromChampsCount - 1,true,0,false,"",false);

        core.setTokenToOwner(_champId, _to, true);

        champsEC.emitTransfer(_from,_to,_champId);

         
        if(champ.eq_sword != 0) { _transferItem(_from, _to, champ.eq_sword); }
        if(champ.eq_shield != 0) { _transferItem(_from, _to, champ.eq_shield); }
        if(champ.eq_helmet != 0) { _transferItem(_from, _to, champ.eq_helmet); }
    }


    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) external
    onlyCore{
        if(_isTokenChamp){
            _transferChamp(_from, _to, _id);
        }else{
            _transferItem(_from, _to, _id);
        }
    }

    function cancelTokenSale(uint _id, address _msgsender, bool _isTokenChamp) public 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp)
      onlyCore 
    {
        if(_isTokenChamp){
            Champ memory champ = _getChamp(_id);
            require(champ.forSale);  
            _cancelChampSale(champ);
        }else{
            Item memory item = _getItem(_id);
          require(item.forSale);
           _cancelItemSale(item);
        }
    }

     
    function giveToken(address _to, uint _id, address _msgsender, bool _isTokenChamp) external 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp)
      onlyCore 
    {
        if(_isTokenChamp){
            _transferChamp(core.tokenToOwner(true,_id), _to, _id);
        }else{
             _transferItem(core.tokenToOwner(false,_id), _to, _id);
        }
    }


    function setTokenForSale(uint _id, uint _price, address _msgsender, bool _isTokenChamp) external 
      onlyApprovedOrOwnerOfToken(_id, _msgsender, _isTokenChamp) 
      onlyCore 
    {
        if(_isTokenChamp){
            Champ memory champ = _getChamp(_id);
            require(champ.forSale == false);  
            champ.forSale = true;
            champ.price = _price;
            _updateChamp(champ);
            
             
        }else{
            Item memory item = _getItem(_id);
            require(item.forSale == false);
            item.forSale = true;
            item.price = _price;
            _updateItem(item);
            
             
        }

    }

    function _updateChamp(Champ memory champ) private 
    {
        core.updateChamp(champ.id, champ.attackPower, champ.defencePower, champ.cooldownTime, champ.readyTime, champ.winCount, champ.lossCount, champ.position, champ.price, champ.withdrawCooldown, champ.eq_sword, champ.eq_shield, champ.eq_helmet, champ.forSale);
    }

    function _updateItem(Item memory item) private
    {
        core.updateItem(item.id, item.itemType, item.itemRarity, item.attackPower, item.defencePower, item.cooldownReduction,item.price, item.onChampId, item.onChamp, item.forSale);
    }
    
    function _getChamp(uint _champId) private view returns (Champ)
    {
        Champ memory champ;
        
         
        (champ.id, champ.attackPower, champ.defencePower, champ.cooldownTime, champ.readyTime, champ.winCount, champ.lossCount, champ.position,,,,,,) = core.champs(_champId);
        (,,,,,,,,champ.price, champ.withdrawCooldown, champ.eq_sword, champ.eq_shield, champ.eq_helmet, champ.forSale) = core.champs(_champId);
        
        return champ;
    }
    
    function _getItem(uint _itemId) private view returns (Item)
    {
        Item memory item;
        
         
        (item.id, item.itemType, item.itemRarity, item.attackPower, item.defencePower, item.cooldownReduction,,,,) = core.items(_itemId);
        (,,,,,,item.price, item.onChampId, item.onChamp, item.forSale) = core.items(_itemId);
        
        return item;
    }

    function getTokenURIs(uint _id, bool _isTokenChamp) public pure returns(string)
    {
        if(_isTokenChamp){
            return strConcat('https: 
        }else{
            return strConcat('https: 
        }
    }


    function _takeOffItem(uint _champId, uint8 _type) private
    {
        uint itemId;
        Champ memory champ = _getChamp(_champId);
        if(_type == 1){
            itemId = champ.eq_sword;  
            if (itemId > 0) {  
                champ.eq_sword = 0;  
            }
        }
        if(_type == 2){
            itemId = champ.eq_shield;  
            if(itemId > 0) { 
                champ.eq_shield = 0;  
            }
        }
        if(_type == 3){
            itemId = champ.eq_helmet;  
            if(itemId > 0) {  
                champ.eq_helmet = 0;  
            }
        }
        if(itemId > 0){
            Item memory item = _getItem(itemId);
            item.onChamp = false;
            _updateItem(item);
        }
    }

    function takeOffItem(uint _champId, uint8 _type, address _msgsender) public 
    onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
    onlyCore
    {
            _takeOffItem(_champId, _type);
    }

    function putOn(uint _champId, uint _itemId, address _msgsender) external 
        onlyApprovedOrOwnerOfToken(_champId, _msgsender, true) 
        onlyApprovedOrOwnerOfToken(_itemId, _msgsender, false) 
        onlyCore 
        {
            Champ memory champ = _getChamp(_champId);
            Item memory item = _getItem(_itemId);

             
            if(item.onChamp){
                _takeOffItem(item.onChampId, item.itemType);  
            }

            item.onChamp = true;  
            item.onChampId = _champId;  

             
            if(item.itemType == 1){
                 
                if(champ.eq_sword > 0){
                    _takeOffItem(champ.id, 1);
                }
                champ.eq_sword = _itemId;  
            }
            if(item.itemType == 2){
                 
                if(champ.eq_shield > 0){
                    _takeOffItem(champ.id, 2);
                }
                champ.eq_shield = _itemId;  
            }
            if(item.itemType == 3){
                 
                if(champ.eq_helmet > 0){
                    _takeOffItem(champ.id, 3);
                }
                champ.eq_helmet = _itemId;  
            }

            _updateChamp(champ);
            _updateItem(item);
    }


    function _cancelItemSale(Item memory item) private {
       
      item.forSale = false;
      
       

      _updateItem(item);
    }

    function _transferItem(address _from, address _to, uint _itemID) private 
    {
        Item memory item = _getItem(_itemID);

        if(item.forSale){
              _cancelItemSale(item);
        }

         
        if(item.onChamp && _to != core.tokenToOwner(true, item.onChampId)){
          _takeOffItem(item.onChampId, item.itemType);
        }

        core.clearTokenApproval(_from, _itemID, false);

         
        (,,uint toItemsCount,) = core.addressInfo(_to);
        (,,uint fromItemsCount,) = core.addressInfo(_from);

        core.updateAddressInfo(_to,0,false,0,false,toItemsCount + 1,true,"",false);
        core.updateAddressInfo(_from,0,false,0,false,fromItemsCount - 1,true,"",false);
        
        core.setTokenToOwner(_itemID, _to,false);

        itemsEC.emitTransfer(_from,_to,_itemID);
    }

    function forgeItems(uint _parentItemID, uint _childItemID, address _msgsender) external 
    onlyApprovedOrOwnerOfToken(_parentItemID, _msgsender, false) 
    onlyApprovedOrOwnerOfToken(_childItemID, _msgsender, false) 
    onlyCore
    {
         
        require(_parentItemID != _childItemID);
        
        Item memory parentItem = _getItem(_parentItemID);
        Item memory childItem = _getItem(_childItemID);
        
         
        if(parentItem.forSale){
          _cancelItemSale(parentItem);
        }
        
         
        if(childItem.forSale){
          _cancelItemSale(childItem);
        }

         
        if(childItem.onChamp){
            _takeOffItem(childItem.onChampId, childItem.itemType);
        }

         
        parentItem.attackPower = (parentItem.attackPower > childItem.attackPower) ? parentItem.attackPower : childItem.attackPower;
        parentItem.defencePower = (parentItem.defencePower > childItem.defencePower) ? parentItem.defencePower : childItem.defencePower;
        parentItem.cooldownReduction = (parentItem.cooldownReduction > childItem.cooldownReduction) ? parentItem.cooldownReduction : childItem.cooldownReduction;
        parentItem.itemRarity = uint8(6);

        _updateItem(parentItem);

         
        _transferItem(core.tokenToOwner(false,_childItemID), address(0), _childItemID);

    }


}