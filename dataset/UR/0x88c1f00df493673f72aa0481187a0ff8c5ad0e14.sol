 

pragma solidity ^0.4.23;

 

library ByteConvert {

  function bytesToBytes2(bytes b) public pure returns (bytes2) {
    bytes2 out;
    for (uint i = 0; i < 2; i++) {
      out |= bytes2(b[i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  function bytesToBytes5(bytes b) public pure returns (bytes5) {
    bytes5 out;
    for (uint i = 0; i < 5; i++) {
      out |= bytes5(b[i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  function bytesToBytes8(bytes b) public pure returns (bytes8) {
    bytes8 out;
    for (uint i = 0; i < 8; i++) {
      out |= bytes8(b[i] & 0xFF) >> (i * 8);
    }
    return out;
  }

}

 

contract EtherSpaceBattleInterface {
  function isEtherSpaceBattle() public pure returns (bool);
  function battle(bytes8 _spaceshipAttributes, bytes5 _spaceshipUpgrades, bytes8 _spaceshipToAttackAttributes, bytes5 _spaceshipToAttackUpgrades) public returns (bool);
  function calculateStake(bytes8 _spaceshipAttributes, bytes5 _spaceshipUpgrades) public pure returns (uint256);
  function calculateLevel(bytes8 _spaceshipAttributes, bytes5 _spaceshipUpgrades) public pure returns (uint256);
}

 

contract EtherSpaceUpgradeInterface {
  function isEtherSpaceUpgrade() public pure returns (bool);
  function isSpaceshipUpgradeAllowed(bytes5 _upgrades, uint16 _upgradeId, uint8 _position) public view;
  function buySpaceshipUpgrade(bytes5 _upgrades, uint16 _model, uint8 _position) public returns (bytes5);
  function getSpaceshipUpgradePriceByModel(uint16 _model, uint8 _position) public view returns (uint256);
  function getSpaceshipUpgradeTotalSoldByModel(uint16 _model, uint8 _position) public view returns (uint256);
  function getSpaceshipUpgradeCount() public view returns (uint256);
  function newSpaceshipUpgrade(bytes1 _identifier, uint8 _position, uint256 _price) public;
}

 

 

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

 

 

 
contract Destructible is Ownable {

    constructor() public payable { }

     
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
    }

}

 

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 

 

 
contract Claimable is Ownable {

    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

}

 

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 

 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    emit Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    emit Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

 

contract EtherSpaceCore is ERC721Token, Ownable, Claimable, Destructible {

  string public url = "https://etherspace.co/";

  using SafeMath for uint256;

  struct Spaceship {
    uint16 model;
    bool battleMode;
    uint32 battleWins;
    uint32 battleLosses;
    uint256 battleStake;
    bytes5 upgrades;
    bool isAuction;
    uint256 auctionPrice;
  }

  mapping (uint256 => Spaceship) private spaceships;
  uint256[] private spaceshipIds;

   
  struct SpaceshipProduct {
    uint16 class;
    bytes8 attributes;
    uint256 price;  
    uint32 totalSold;  
  }

  mapping (uint16 => SpaceshipProduct) private spaceshipProducts;
  uint16 spaceshipProductCount = 0;  

  mapping (address => uint256) private balances;  

   
  uint256 public battleFee = 0;

   
  uint32 public saleFee = 5;  

  EtherSpaceUpgradeInterface public upgradeContract;
  EtherSpaceBattleInterface public battleContract;

   
  event EventCashOut (
    address indexed player,
    uint256 amount
  );
  event EventBattleAdd (
    address indexed player,
    uint256 tokenId
  );
  event EventBattleRemove (
    address indexed player,
    uint256 tokenId
  );
  event EventBattle (
    address indexed player,
    uint256 tokenId,
    uint256 tokenIdToAttack,
    uint256 tokenIdWinner
  );
  event EventBuySpaceshipUpgrade (
    address indexed player,
    uint256 tokenId,
    uint16 model,
    uint8 position
  );
  event Log (
    string message
  );

  constructor() public {
    _newSpaceshipProduct(0,   0x001e,   0x0514,   0x0004,   0x0005,   50000000000000000);  
    _newSpaceshipProduct(0,   0x001d,   0x0226,   0x0005,   0x0006,   60000000000000000);  
    _newSpaceshipProduct(0,   0x001f,   0x03e8,   0x0003,   0x0009,   70000000000000000);  
    _newSpaceshipProduct(0,   0x001e,   0x0258,   0x0005,   0x0009,   80000000000000000);  
    _newSpaceshipProduct(0,   0x001a,   0x0064,   0x0006,   0x000a,   90000000000000000);  
    _newSpaceshipProduct(0,   0x0015,   0x0032,   0x0007,   0x000b,  100000000000000000);  
  }

  function _setUpgradeContract(address _address) private {
    EtherSpaceUpgradeInterface candidateContract = EtherSpaceUpgradeInterface(_address);

    require(candidateContract.isEtherSpaceUpgrade());

     
    upgradeContract = candidateContract;
  }

  function _setBattleContract(address _address) private {
    EtherSpaceBattleInterface candidateContract = EtherSpaceBattleInterface(_address);

    require(candidateContract.isEtherSpaceBattle());

     
    battleContract = candidateContract;
  }

   
  function() external payable {
      require(false);
  }

   
  function name() external pure returns (string) {
    return "EtherSpace";
  }

  function symbol() external pure returns (string) {
    return "ESPC";
  }

   
  function ids() external view returns (uint256[]) {
    return spaceshipIds;
  }

   
  function setSpaceshipPrice(uint16 _model, uint256 _price) external onlyOwner {
    require(_price > 0);

    spaceshipProducts[_model].price = _price;
  }

  function newSpaceshipProduct(uint16 _class, bytes2 _propulsion, bytes2 _weight, bytes2 _attack, bytes2 _armour, uint256 _price) external onlyOwner {
    _newSpaceshipProduct(_class, _propulsion, _weight, _attack, _armour, _price);
  }

  function setBattleFee(uint256 _fee) external onlyOwner {
    battleFee = _fee;
  }

  function setUpgradeContract(address _address) external onlyOwner {
    _setUpgradeContract(_address);
  }

  function setBattleContract(address _address) external onlyOwner {
    _setBattleContract(_address);
  }

  function giftSpaceship(uint16 _model, address _player) external onlyOwner {
    _generateSpaceship(_model, _player);
  }

  function newSpaceshipUpgrade(bytes1 _identifier, uint8 _position, uint256 _price) external onlyOwner {
    upgradeContract.newSpaceshipUpgrade(_identifier, _position, _price);
  }

   
  function _newSpaceshipProduct(uint16 _class, bytes2 _propulsion, bytes2 _weight, bytes2 _attack, bytes2 _armour, uint256 _price) private {
    bytes memory attributes = new bytes(8);
    attributes[0] = _propulsion[0];
    attributes[1] = _propulsion[1];
    attributes[2] = _weight[0];
    attributes[3] = _weight[1];
    attributes[4] = _attack[0];
    attributes[5] = _attack[1];
    attributes[6] = _armour[0];
    attributes[7] = _armour[1];

    spaceshipProducts[spaceshipProductCount++] = SpaceshipProduct(_class, ByteConvert.bytesToBytes8(attributes), _price, 0);
  }

   
  function cashOut() public {
    require(address(this).balance >= balances[msg.sender]);  
    require(balances[msg.sender] > 0);  

    uint256 _balance = balances[msg.sender];

    balances[msg.sender] = 0;
    msg.sender.transfer(_balance);

    emit EventCashOut(msg.sender, _balance);
  }

   
  function buySpaceship(uint16 _model) public payable {
    require(msg.value > 0);
    require(msg.value == spaceshipProducts[_model].price);
    require(spaceshipProducts[_model].price > 0);

    _generateSpaceship(_model, msg.sender);

    balances[owner] += spaceshipProducts[_model].price;
  }

  function _generateSpaceship(uint16 _model, address _player) private {
     
    uint256 tokenId = spaceshipIds.length;
    spaceshipIds.push(tokenId);
    super._mint(_player, tokenId);

    spaceships[tokenId] = Spaceship({
      model: _model,
      battleMode: false,
      battleWins: 0,
      battleLosses: 0,
      battleStake: 0,
      upgrades: "\x00\x00\x00\x00\x00",  
      isAuction: false,
      auctionPrice: 0
    });

    spaceshipProducts[_model].totalSold++;
  }

  function sellSpaceship(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
    spaceships[_tokenId].isAuction = true;
    spaceships[_tokenId].auctionPrice = _price;
  }

  function bidSpaceship(uint256 _tokenId) public payable {
    require(getPlayerSpaceshipAuctionById(_tokenId));  
    require(getPlayerSpaceshipAuctionPriceById(_tokenId) == msg.value);  

     
    uint256 ownerPercentage = msg.value.mul(uint256(saleFee)).div(100);
    balances[owner] += ownerPercentage;

     
    balances[getPlayerSpaceshipOwnerById(_tokenId)] += msg.value.sub(ownerPercentage);

     
    super.clearApprovalAndTransfer(getPlayerSpaceshipOwnerById(_tokenId), msg.sender, _tokenId);

     
    spaceships[_tokenId].isAuction = false;
    spaceships[_tokenId].auctionPrice = 0;
  }

   
  function battleAdd(uint256 _tokenId) public payable onlyOwnerOf(_tokenId) {
    require(msg.value == getPlayerSpaceshipBattleStakeById(_tokenId));
    require(msg.value > 0);
    require(spaceships[_tokenId].battleMode == false);

    spaceships[_tokenId].battleMode = true;
    spaceships[_tokenId].battleStake = msg.value;

    emit EventBattleAdd(msg.sender, _tokenId);
  }

  function battleRemove(uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    require(spaceships[_tokenId].battleMode == true);

    spaceships[_tokenId].battleMode = false;

    balances[msg.sender] = balances[msg.sender].add(spaceships[_tokenId].battleStake);

    emit EventBattleRemove(msg.sender, _tokenId);
  }

  function battle(uint256 _tokenId, uint256 _tokenIdToAttack) public payable onlyOwnerOf(_tokenId) {
    require (spaceships[_tokenIdToAttack].battleMode == true);  
    require (spaceships[_tokenId].battleMode == false);  
    require(msg.value == getPlayerSpaceshipBattleStakeById(_tokenId));

    uint256 battleStakeDefender = spaceships[_tokenIdToAttack].battleStake;

    bool result = battleContract.battle(spaceshipProducts[spaceships[_tokenId].model].attributes, spaceships[_tokenId].upgrades, spaceshipProducts[spaceships[_tokenIdToAttack].model].attributes, spaceships[_tokenIdToAttack].upgrades);

    if (result) {
        spaceships[_tokenId].battleWins++;
        spaceships[_tokenIdToAttack].battleLosses++;

        balances[super.ownerOf(_tokenId)] += (battleStakeDefender + msg.value) - battleFee;
        spaceships[_tokenIdToAttack].battleStake = 0;

        emit EventBattle(msg.sender, _tokenId, _tokenIdToAttack, _tokenId);

    } else {
        spaceships[_tokenId].battleLosses++;
        spaceships[_tokenIdToAttack].battleWins++;

        balances[super.ownerOf(_tokenIdToAttack)] += (battleStakeDefender + msg.value) - battleFee;
        spaceships[_tokenIdToAttack].battleStake = 0;

        emit EventBattle(msg.sender, _tokenId, _tokenIdToAttack, _tokenIdToAttack);
    }

    balances[owner] += battleFee;

    spaceships[_tokenIdToAttack].battleMode = false;
  }

   
  function buySpaceshipUpgrade(uint256 _tokenId, uint16 _model, uint8 _position) public payable onlyOwnerOf(_tokenId) {
    require(msg.value > 0);
    uint256 upgradePrice = upgradeContract.getSpaceshipUpgradePriceByModel(_model, _position);
    require(msg.value == upgradePrice);
    require(getPlayerSpaceshipBattleModeById(_tokenId) == false);

    bytes5 currentUpgrades = spaceships[_tokenId].upgrades;
    upgradeContract.isSpaceshipUpgradeAllowed(currentUpgrades, _model, _position);

    spaceships[_tokenId].upgrades = upgradeContract.buySpaceshipUpgrade(currentUpgrades, _model, _position);

    balances[owner] += upgradePrice;

    emit EventBuySpaceshipUpgrade(msg.sender, _tokenId, _model, _position);
  }

   
  function getPlayerSpaceshipCount(address _player) public view returns (uint256) {
    return super.balanceOf(_player);
  }

  function getPlayerSpaceshipModelById(uint256 _tokenId) public view returns (uint16) {
    return spaceships[_tokenId].model;
  }

  function getPlayerSpaceshipOwnerById(uint256 _tokenId) public view returns (address) {
    return super.ownerOf(_tokenId);
  }

  function getPlayerSpaceshipModelByIndex(address _owner, uint256 _index) public view returns (uint16) {
    return spaceships[super.tokensOf(_owner)[_index]].model;
  }

  function getPlayerSpaceshipAuctionById(uint256 _tokenId) public view returns (bool) {
    return spaceships[_tokenId].isAuction;
  }

  function getPlayerSpaceshipAuctionPriceById(uint256 _tokenId) public view returns (uint256) {
    return spaceships[_tokenId].auctionPrice;
  }

  function getPlayerSpaceshipBattleModeById(uint256 _tokenId) public view returns (bool) {
    return spaceships[_tokenId].battleMode;
  }

  function getPlayerSpaceshipBattleStakePaidById(uint256 _tokenId) public view returns (uint256) {
    return spaceships[_tokenId].battleStake;
  }

  function getPlayerSpaceshipBattleStakeById(uint256 _tokenId) public view returns (uint256) {
    return battleContract.calculateStake(spaceshipProducts[spaceships[_tokenId].model].attributes, spaceships[_tokenId].upgrades);
  }

  function getPlayerSpaceshipBattleLevelById(uint256 _tokenId) public view returns (uint256) {
    return battleContract.calculateLevel(spaceshipProducts[spaceships[_tokenId].model].attributes, spaceships[_tokenId].upgrades);
  }

  function getPlayerSpaceshipBattleWinsById(uint256 _tokenId) public view returns (uint32) {
    return spaceships[_tokenId].battleWins;
  }

  function getPlayerSpaceshipBattleLossesById(uint256 _tokenId) public view returns (uint32) {
    return spaceships[_tokenId].battleLosses;
  }

  function getPlayerSpaceships(address _owner) public view returns (uint256[]) {
    return super.tokensOf(_owner);
  }

  function getPlayerBalance(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function getPlayerSpaceshipUpgradesById(uint256 _tokenId) public view returns (bytes5) {
    return spaceships[_tokenId].upgrades;
  }

   
  function getSpaceshipProductPriceByModel(uint16 _model) public view returns (uint256) {
    return spaceshipProducts[_model].price;
  }

  function getSpaceshipProductClassByModel(uint16 _model) public view returns (uint16) {
    return spaceshipProducts[_model].class;
  }

  function getSpaceshipProductTotalSoldByModel(uint16 _model) public view returns (uint256) {
    return spaceshipProducts[_model].totalSold;
  }

  function getSpaceshipProductAttributesByModel(uint16 _model) public view returns (bytes8) {
    return spaceshipProducts[_model].attributes;
  }

  function getSpaceshipProductCount() public view returns (uint16) {
    return spaceshipProductCount;
  }

   
  function getSpaceshipTotalSold() public view returns (uint256) {
    return super.totalSupply();
  }

   
  function getSpaceshipUpgradePriceByModel(uint16 _model, uint8 _position) public view returns (uint256) {
    return upgradeContract.getSpaceshipUpgradePriceByModel(_model, _position);
  }

  function getSpaceshipUpgradeTotalSoldByModel(uint16 _model, uint8 _position) public view returns (uint256) {
    return upgradeContract.getSpaceshipUpgradeTotalSoldByModel(_model, _position);
  }

  function getSpaceshipUpgradeCount() public view returns (uint256) {
    return upgradeContract.getSpaceshipUpgradeCount();
  }

}