 

pragma solidity ^0.4.18;

contract Admin {
  address public owner;
  mapping(address => bool) public isAdmin;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin() {
    require(isAdmin[msg.sender]);
    _;
  }

  function Admin() public {
    owner = msg.sender;
    addAdmin(owner);
  }

  function addAdmin(address _admin) public onlyOwner {
    isAdmin[_admin] = true;
  }

  function removeAdmin(address _admin) public onlyOwner {
    isAdmin[_admin] = false;
  }
}

 
 
 
contract Trees is Admin {
  event LogWaterTree(uint256 indexed treeId, address indexed owner, uint256 date);
  event LogRewardPicked(uint256 indexed treeId, address indexed owner, uint256 date, uint256 amount);

   
  mapping(uint256 => Tree) public treeDetails;
   
  mapping(address => uint256[]) public ownerTreesIds;
   
   
  mapping(uint256 => mapping(uint256 => bool)) public treeWater;

  struct Tree {
    uint256 ID;
    address owner;
    uint256 purchaseDate;
    uint256 treePower;  
    uint256 salePrice;
    uint256 timesExchanged;
    uint256[] waterTreeDates;
    bool onSale;
    uint256 lastRewardPickedDate;  
  }

  uint256[] public trees;
  uint256[] public treesOnSale;
  uint256 public lastTreeId;
  address public defaultTreesOwner = msg.sender;
  uint256 public defaultTreesPower = 1;  
  uint256 public defaultSalePrice = 1 ether;
  uint256 public totalTreePower;
  uint256 public timeBetweenRewards = 1 days;

   
   
  function generateTrees(uint256 _amountToGenerate) public onlyAdmin {
    for(uint256 i = 0; i < _amountToGenerate; i++) {
        uint256 newTreeId = lastTreeId + 1;
        lastTreeId += 1;
        uint256[] memory emptyArray;
        Tree memory newTree = Tree(newTreeId, defaultTreesOwner, now, defaultTreesPower, defaultSalePrice, 0, emptyArray, true, 0);

         
         
        ownerTreesIds[defaultTreesOwner].push(newTreeId);
        treeDetails[newTreeId] = newTree;
        treesOnSale.push(newTreeId);
        totalTreePower += defaultTreesPower;
    }
  }

   
   
   
  function putTreeOnSale(uint256 _treeNumber, uint256 _salePrice) public {
    require(msg.sender == treeDetails[_treeNumber].owner);
    require(!treeDetails[_treeNumber].onSale);
    require(_salePrice > 0);

    treesOnSale.push(_treeNumber);
    treeDetails[_treeNumber].salePrice = _salePrice;
    treeDetails[_treeNumber].onSale = true;
  }

   
  function buyTree(uint256 _treeNumber, address _originalOwner) public payable {
    require(msg.sender != treeDetails[_treeNumber].owner);
    require(treeDetails[_treeNumber].onSale);
    require(msg.value >= treeDetails[_treeNumber].salePrice);
    address newOwner = msg.sender;
     
     
    for(uint256 i = 0; i < ownerTreesIds[_originalOwner].length; i++) {
        if(ownerTreesIds[_originalOwner][i] == _treeNumber) delete ownerTreesIds[_originalOwner][i];
    }
     
    for(uint256 a = 0; a < treesOnSale.length; a++) {
        if(treesOnSale[a] == _treeNumber) {
            delete treesOnSale[a];
            break;
        }
    }
    ownerTreesIds[newOwner].push(_treeNumber);
    treeDetails[_treeNumber].onSale = false;
    if(treeDetails[_treeNumber].timesExchanged == 0) {
         
        owner.transfer(msg.value / 2);
    } else {
        treeDetails[_treeNumber].owner.transfer(msg.value * 90 / 100);  
    }
    treeDetails[_treeNumber].owner = newOwner;
    treeDetails[_treeNumber].timesExchanged += 1;
  }

   
  function cancelTreeSell(uint256 _treeId) public {
    require(msg.sender == treeDetails[_treeId].owner);
    require(treeDetails[_treeId].onSale);
     
    for(uint256 a = 0; a < treesOnSale.length; a++) {
        if(treesOnSale[a] == _treeId) {
            delete treesOnSale[a];
            break;
        }
    }
    treeDetails[_treeId].onSale = false;
  }

   
  function waterTree(uint256 _treeId) public {
    require(_treeId > 0);
    require(msg.sender == treeDetails[_treeId].owner);
    uint256[] memory waterDates = treeDetails[_treeId].waterTreeDates;
    uint256 timeSinceLastWater;
     
    uint256 day;
    if(waterDates.length > 0) {
        timeSinceLastWater = now - waterDates[waterDates.length - 1];
        day = waterDates[waterDates.length - 1] / 1 days;
    }else {
        timeSinceLastWater = timeBetweenRewards;
        day = 1;
    }
    require(timeSinceLastWater >= timeBetweenRewards);
    treeWater[_treeId][day] = true;
    treeDetails[_treeId].waterTreeDates.push(now);
    treeDetails[_treeId].treePower += 1;
    totalTreePower += 1;
    LogWaterTree(_treeId, msg.sender, now);
  }

   
  function pickReward(uint256 _treeId) public {
    require(msg.sender == treeDetails[_treeId].owner);
    require(now - treeDetails[_treeId].lastRewardPickedDate > timeBetweenRewards);

    uint256[] memory formatedId = new uint256[](1);
    formatedId[0] = _treeId;
    uint256[] memory rewards = checkRewards(formatedId);
    treeDetails[_treeId].lastRewardPickedDate = now;
    msg.sender.transfer(rewards[0]);
    LogRewardPicked(_treeId, msg.sender, now, rewards[0]);
  }

   
  function checkTreesWatered(uint256[] _treeIds) public constant returns(bool[]) {
    bool[] memory results = new bool[](_treeIds.length);
    uint256 timeSinceLastWater;
    for(uint256 i = 0; i < _treeIds.length; i++) {
        uint256[] memory waterDates = treeDetails[_treeIds[i]].waterTreeDates;
        if(waterDates.length > 0) {
            timeSinceLastWater = now - waterDates[waterDates.length - 1];
            results[i] = timeSinceLastWater < timeBetweenRewards;
        } else {
            results[i] = false;
        }
    }
    return results;
  }

   
   
   
   
   
   
   
   
  function checkRewards(uint256[] _treeIds) public constant returns(uint256[]) {
    uint256 amountInTreasuryToDistribute = this.balance / 10;
    uint256[] memory results = new uint256[](_treeIds.length);
    for(uint256 i = 0; i < _treeIds.length; i++) {
         
        uint256 yourPercentage = treeDetails[_treeIds[i]].treePower * 1 ether / totalTreePower;
        uint256 amountYouGet = yourPercentage * amountInTreasuryToDistribute / 1 ether;
        results[i] = amountYouGet;
    }
    return results;
  }

   
  function getTreeIds(address _account) public constant returns(uint256[]) {
    if(_account != address(0)) return ownerTreesIds[_account];
    else return ownerTreesIds[msg.sender];
  }

   
  function getTreesOnSale() public constant returns(uint256[]) {
      return treesOnSale;
  }

   
  function emergencyExtract() public onlyOwner {
    owner.transfer(this.balance);
  }
}