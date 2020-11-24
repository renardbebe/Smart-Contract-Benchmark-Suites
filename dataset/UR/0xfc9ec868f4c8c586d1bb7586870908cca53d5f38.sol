 

pragma solidity ^0.4.8;

 
contract KittyItemToken {
  function transfer(address, uint256) public pure returns (bool) {}
  function transferAndApply(address, uint256) public pure returns (bool) {}
  function balanceOf(address) public pure returns (uint256) {}
}

 
contract KittyItemMarket {

  struct Item {
    address itemContract;
    uint256 cost;   
    address artist;
    uint128 split;   
    uint256 totalFunds;
  }

  address public owner;
  mapping (string => Item) items;
  bool public paused = false;

   
  event Buy(string itemName);

   
  function KittyItemMarket() public {
    owner = msg.sender;
  }

   
  function transferOwnership(address newOwner) public {
    require(msg.sender == owner);
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

   
  function setPaused(bool _paused) public {
    require(msg.sender == owner);
    paused = _paused;
  }

   
  function getItem(string _itemName) view public returns (address, uint256, address, uint256, uint256) {
    return (items[_itemName].itemContract, items[_itemName].cost, items[_itemName].artist, items[_itemName].split, items[_itemName].totalFunds);
  }

   
  function addItem(string _itemName, address _itemContract, uint256 _cost, address _artist, uint128 _split) public {
    require(msg.sender == owner);
    require(items[_itemName].itemContract == 0x0);   
    items[_itemName] = Item(_itemContract, _cost, _artist, _split, 0);
  }

   
  function modifyItem(string _itemName, address _itemContract, uint256 _cost, address _artist, uint128 _split) public {
    require(msg.sender == owner);
    require(items[_itemName].itemContract != 0x0);   
    Item storage item = items[_itemName];
    item.itemContract = _itemContract;
    item.cost = _cost;
    item.artist = _artist;
    item.split = _split;
  }

   
  function buyItem(string _itemName, uint256 _amount) public payable {
    require(paused == false);
    require(items[_itemName].itemContract != 0x0);   
    Item storage item = items[_itemName];   
    require(msg.value >= item.cost * _amount);   
    item.totalFunds += msg.value;
    KittyItemToken kit = KittyItemToken(item.itemContract);
    kit.transfer(msg.sender, _amount);
     
    Buy(_itemName);
  }

   
  function buyItemAndApply(string _itemName, uint256 _kittyId) public payable {
    require(paused == false);
     
    require(items[_itemName].itemContract != 0x0);   
    Item storage item = items[_itemName];   
    require(msg.value >= item.cost);   
    item.totalFunds += msg.value;
    KittyItemToken kit = KittyItemToken(item.itemContract);
    kit.transferAndApply(msg.sender, _kittyId);
     
    Buy(_itemName);
  }

   
  function splitFunds(string _itemName) public {
    require(msg.sender == owner);
    Item storage item = items[_itemName];   
    uint256 amountToArtist = item.totalFunds * item.split / 10000;
    uint256 amountToOwner = item.totalFunds - amountToArtist;
    item.artist.transfer(amountToArtist);
    owner.transfer(amountToOwner);
    item.totalFunds = 0;
  }

   
  function returnTokensToOwner(string _itemName) public returns (bool) {
    require(msg.sender == owner);
    Item storage item = items[_itemName];   
    KittyItemToken kit = KittyItemToken(item.itemContract);
    uint256 contractBalance = kit.balanceOf(this);
    kit.transfer(msg.sender, contractBalance);
    return true;
  }

}