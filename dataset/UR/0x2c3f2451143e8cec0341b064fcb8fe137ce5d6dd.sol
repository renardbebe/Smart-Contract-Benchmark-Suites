 

pragma solidity ^0.4.21;

 
library Maths {
   
  function plus(
    uint256 addendA,
    uint256 addendB
  ) public pure returns (uint256 sum) {
    sum = addendA + addendB;
  }

   
  function minus(
    uint256 minuend,
    uint256 subtrahend
  ) public pure returns (uint256 difference) {
    assert(minuend >= subtrahend);
    difference = minuend - subtrahend;
  }

   
  function mul(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    if (factorA == 0 || factorB == 0) return 0;
    product = factorA * factorB;
    assert(product / factorA == factorB);
  }

   
  function times(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    return mul(factorA, factorB);
  }

   
  function div(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    quotient = dividend / divisor;
    assert(quotient * divisor == dividend);
  }

   
  function dividedBy(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    return div(dividend, divisor);
  }

   
  function divideSafely(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient, uint256 remainder) {
    quotient = div(dividend, divisor);
    remainder = dividend % divisor;
  }

   
  function min(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a <= b ? a : b;
  }

   
  function max(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a >= b ? a : b;
  }

   
  function isLessThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a < b;
  }

   
  function isAtMost(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a <= b;
  }

   
  function isGreaterThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a > b;
  }

   
  function isAtLeast(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a >= b;
  }
}

 
contract Manageable {
  address public owner;
  address public manager;

  event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
  event ManagementChanged(address indexed previousManager, address indexed newManager);

   
  function Manageable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

   
  modifier onlyManagement() {
    require(msg.sender == owner || msg.sender == manager);
    _;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }

   
  function replaceManager(address newManager) public onlyManagement {
    require(newManager != address(0));
    ManagementChanged(manager, newManager);
    manager = newManager;
  }
}

contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function approve(address spender, uint256 value) public returns (bool);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
}

contract MythereumERC20Token is ERC20 {
  function burn(address burner, uint256 amount) public returns (bool);
  function mint(address to, uint256 amount) public returns (bool);
}

contract MythereumCardToken {
  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) public;

  function isEditionAvailable(uint8 _editionNumber) public view returns (bool);
  function cloneCard(address _owner, uint256 _tokenId) public returns (bool);
  function mintRandomCards(
    address _owner,
    uint8 _editionNumber,
    uint8 _numCards
  ) public returns (bool);
  function improveCard(
    uint256 _tokenId,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public returns (bool);
  function destroyCard(uint256 _tokenId) public returns (bool);
}

contract Mythereum is Manageable {
  using Maths for uint256;

  struct Edition {
    string  name;
    uint256 sales;
    uint256 maxSales;
    uint8   packSize;
    uint256 packPrice;
    uint256 packPriceIncrease;
  }

  mapping (uint8 => Edition) public editions;
  mapping (address => bool) public isVIP;
  mapping (address => bool) public isTokenAccepted;
  mapping (address => uint256) public tokenCostPerPack;

  mapping (uint256 => uint256) public mythexCostPerUpgradeLevel;
  mapping (uint256 => uint256) public cardDamageUpgradeLevel;
  mapping (uint256 => uint256) public cardShieldUpgradeLevel;
  uint256 public maxCardUpgradeLevel = 30;

  address public cardTokenAddress;
  address public xpTokenAddress;
  address public mythexTokenAddress;
  address public gameHostAddress;

   
  uint256 public totalShares = 0;
  uint256 public totalReleased = 0;
  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;

  event CardsPurchased(uint256 editionNumber, uint256 packSize, address buyer);
  event CardUpgraded(uint256 cardId, uint256 addedDamage, uint256 addedShield);

  modifier onlyHosts() {
    require(
      msg.sender == owner ||
      msg.sender == manager ||
      msg.sender == gameHostAddress
    );
    _;
  }

  function Mythereum() public {
    editions[0] = Edition({
      name: "Genesis",
      sales: 3999,
      maxSales: 5000,
      packSize: 7,
      packPrice: 100 finney,
      packPriceIncrease: 1 finney
    });

    editions[1] = Edition({
      name: "Survivor",
      sales: 20,
      maxSales: 1000000,
      packSize: 10,
      packPrice: 0,
      packPriceIncrease: 0
    });

    isVIP[msg.sender] = true;
  }

   
  function () public payable {
    revert();
  }

  function buyPack(
    uint8 _editionNumber
  ) public payable {
    uint256 packPrice = isVIP[msg.sender] ? 0 : editions[_editionNumber].packPrice;

    require(msg.value.isAtLeast(packPrice));
    if (msg.value.isGreaterThan(packPrice)) {
      msg.sender.transfer(msg.value.minus(packPrice));
    }

    _deliverPack(msg.sender, _editionNumber);
  }

  function buyPackWithERC20Tokens(
    uint8   _editionNumber,
    address _tokenAddress
  ) public {
    require(isTokenAccepted[_tokenAddress]);
    _processERC20TokenPackPurchase(_editionNumber, _tokenAddress, msg.sender);
  }

  function upgradeCardDamage(uint256 _cardId) public {
    require(cardDamageUpgradeLevel[_cardId].isLessThan(maxCardUpgradeLevel));
    uint256 costOfUpgrade = 32 * (cardDamageUpgradeLevel[_cardId] + 1);

    MythereumERC20Token mythexContract = MythereumERC20Token(mythexTokenAddress);
    require(mythexContract.balanceOf(msg.sender).isAtLeast(costOfUpgrade));
    burnMythexTokens(msg.sender, costOfUpgrade);

    cardDamageUpgradeLevel[_cardId]++;
    _improveCard(_cardId, 1, 0);
  }

  function upgradeCardShield(uint256 _cardId) public {
    require(cardShieldUpgradeLevel[_cardId].isLessThan(maxCardUpgradeLevel));
    uint256 costOfUpgrade = 32 * (cardShieldUpgradeLevel[_cardId] + 1);

    MythereumERC20Token mythexContract = MythereumERC20Token(mythexTokenAddress);
    require(mythexContract.balanceOf(msg.sender).isAtLeast(costOfUpgrade));
    burnMythexTokens(msg.sender, costOfUpgrade);

    cardShieldUpgradeLevel[_cardId]++;
    _improveCard(_cardId, 0, 1);
  }

  function improveCard(
    uint256 _cardId,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement {
    require(cardShieldUpgradeLevel[_cardId].isLessThan(maxCardUpgradeLevel));
    _improveCard(_cardId, _addedDamage, _addedShield);
  }

  function _improveCard(
    uint256 _cardId,
    uint256 _addedDamage,
    uint256 _addedShield
  ) internal {
    MythereumCardToken cardToken = MythereumCardToken(cardTokenAddress);
    require(cardToken.improveCard(_cardId, _addedDamage, _addedShield));
    CardUpgraded(_cardId, _addedDamage, _addedShield);
  }

  function receiveApproval(
    address _sender,
    uint256 _value,
    address _tokenContract,
    bytes _extraData
  ) public {
    require(isTokenAccepted[_tokenContract]);

    uint8 editionNumber = 0;
    if (_extraData.length != 0) editionNumber = uint8(_extraData[0]);

    _processERC20TokenPackPurchase(editionNumber, _tokenContract, _sender);
  }

  function _processERC20TokenPackPurchase(
    uint8   _editionNumber,
    address _tokenAddress,
    address _buyer
  ) internal {
    require(isTokenAccepted[_tokenAddress]);
    ERC20 tokenContract = ERC20(_tokenAddress);
    uint256 costPerPack = tokenCostPerPack[_tokenAddress];

    uint256 ourBalanceBefore = tokenContract.balanceOf(address(this));
    tokenContract.transferFrom(_buyer, address(this), costPerPack);

    uint256 ourBalanceAfter = tokenContract.balanceOf(address(this));
    require(ourBalanceAfter.isAtLeast(ourBalanceBefore.plus(costPerPack)));

    _deliverPack(_buyer, _editionNumber);
  }

  function burnMythexTokens(address _burner, uint256 _amount) public onlyHosts {
    require(_burner != address(0));
    MythereumERC20Token(mythexTokenAddress).burn(_burner, _amount);
  }

  function burnXPTokens(address _burner, uint256 _amount) public onlyHosts {
    require(_burner != address(0));
    MythereumERC20Token(xpTokenAddress).burn(_burner, _amount);
  }

  function grantMythexTokens(address _recipient, uint256 _amount) public onlyHosts {
    require(_recipient != address(0));
    MythereumERC20Token(mythexTokenAddress).mint(_recipient, _amount);
  }

  function grantXPTokens(address _recipient, uint256 _amount) public onlyHosts {
    require(_recipient != address(0));
    MythereumERC20Token(xpTokenAddress).mint(_recipient, _amount);
  }

  function grantPromoPack(
    address _recipient,
    uint8 _editionNumber
  ) public onlyManagement {
    _deliverPack(_recipient, _editionNumber);
  }

  function setTokenAcceptanceRate(
    address _token,
    uint256 _costPerPack
  ) public onlyManagement {
    if (_costPerPack > 0) {
      isTokenAccepted[_token] = true;
      tokenCostPerPack[_token] = _costPerPack;
    } else {
      isTokenAccepted[_token] = false;
      tokenCostPerPack[_token] = 0;
    }
  }

  function transferERC20Tokens(
    address _token,
    address _recipient,
    uint256 _amount
  ) public onlyManagement {
    require(ERC20(_token).transfer(_recipient, _amount));
  }

  function addVIP(address _vip) public onlyManagement {
    isVIP[_vip] = true;
  }

  function removeVIP(address _vip) public onlyManagement {
    isVIP[_vip] = false;
  }

  function setEditionName(
    uint8 _editionNumber,
    string _name
  ) public onlyManagement {
    editions[_editionNumber].name = _name;
  }

  function setEditionSales(
    uint8 _editionNumber,
    uint256 _numSales
  ) public onlyManagement {
    editions[_editionNumber].sales = _numSales;
  }

  function setEditionMaxSales(
    uint8 _editionNumber,
    uint256 _maxSales
  ) public onlyManagement {
    editions[_editionNumber].maxSales = _maxSales;
  }

  function setEditionPackPrice(
    uint8 _editionNumber,
    uint256 _newPrice
  ) public onlyManagement {
    editions[_editionNumber].packPrice = _newPrice;
  }

  function setEditionPackPriceIncrease(
    uint8 _editionNumber,
    uint256 _increase
  ) public onlyManagement {
    editions[_editionNumber].packPriceIncrease = _increase;
  }

  function setEditionPackSize(
    uint8 _editionNumber,
    uint8 _newSize
  ) public onlyManagement {
    editions[_editionNumber].packSize = _newSize;
  }

  function setCardTokenAddress(address _addr) public onlyManagement {
    require(_addr != address(0));
    cardTokenAddress = _addr;
  }

  function setXPTokenAddress(address _addr) public onlyManagement {
    require(_addr != address(0));
    xpTokenAddress = _addr;
  }

  function setMythexTokenAddress(address _addr) public onlyManagement {
    require(_addr != address(0));
    mythexTokenAddress = _addr;
  }

  function setGameHostAddress(address _addr) public onlyManagement {
    require(_addr != address(0));
    gameHostAddress = _addr;
  }

  function claim() public {
    _claim(msg.sender);
  }

  function addShareholder(address _payee, uint256 _shares) public onlyOwner {
    require(_payee != address(0));
    require(_shares.isAtLeast(1));
    require(shares[_payee] == 0);

    shares[_payee] = _shares;
    totalShares = totalShares.plus(_shares);
  }

  function removeShareholder(address _payee) public onlyOwner {
    require(shares[_payee] != 0);
    _claim(_payee);
    _forfeitShares(_payee, shares[_payee]);
  }

  function grantAdditionalShares(
    address _payee,
    uint256 _shares
  ) public onlyOwner {
    require(shares[_payee] != 0);
    require(_shares.isAtLeast(1));

    shares[_payee] = shares[_payee].plus(_shares);
    totalShares = totalShares.plus(_shares);
  }

  function forfeitShares(uint256 _numShares) public {
    _forfeitShares(msg.sender, _numShares);
  }

  function transferShares(address _to, uint256 _numShares) public {
    require(_numShares.isAtLeast(1));
    require(shares[msg.sender].isAtLeast(_numShares));

    shares[msg.sender] = shares[msg.sender].minus(_numShares);
    shares[_to] = shares[_to].plus(_numShares);
  }

  function transferEntireStake(address _to) public {
    transferShares(_to, shares[msg.sender]);
  }

  function _claim(address payee) internal {
    require(shares[payee].isAtLeast(1));

    uint256 totalReceived = address(this).balance.plus(totalReleased);
    uint256 payment = totalReceived.times(shares[payee]).dividedBy(totalShares).minus(released[payee]);

    require(payment != 0);
    require(address(this).balance.isAtLeast(payment));

    released[payee] = released[payee].plus(payment);
    totalReleased = totalReleased.plus(payment);

    payee.transfer(payment);
  }

  function _forfeitShares(address payee, uint256 numShares) internal {
    require(shares[payee].isAtLeast(numShares));
    shares[payee] = shares[payee].minus(numShares);
    totalShares = totalShares.minus(numShares);
  }

  function _deliverPack(address recipient, uint8 editionNumber) internal {
    Edition storage edition = editions[editionNumber];
    require(edition.sales.isLessThan(edition.maxSales.plus(edition.packSize)));

    edition.sales = edition.sales.plus(edition.packSize);
    edition.packPrice = edition.packPrice.plus(edition.packPriceIncrease);

    MythereumCardToken cardToken = MythereumCardToken(cardTokenAddress);
    cardToken.mintRandomCards(recipient, editionNumber, edition.packSize);

    CardsPurchased(editionNumber, edition.packSize, recipient);
  }
}