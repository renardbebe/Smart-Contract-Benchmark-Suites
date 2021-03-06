 

pragma solidity ^0.4.11;

pragma solidity ^0.4.11;

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ICOBuyer is Ownable {

   
   

   
  event EtherReceived(address indexed _contributor, uint256 _amount);
  event EtherWithdrawn(uint256 _amount);
  event TokensWithdrawn(uint256 _balance);
  event ICOPurchased(uint256 _amount);

   
  event ICOStartBlockChanged(uint256 _icoStartBlock);
  event ICOStartTimeChanged(uint256 _icoStartTime);
  event ExecutorChanged(address _executor);
  event CrowdSaleChanged(address _crowdSale);
  event TokenChanged(address _token);
  event PurchaseCapChanged(uint256 _purchaseCap);
  event MinimumContributionChanged(uint256 _minimumContribution);

   
   
  uint256 public icoStartBlock;
   
  uint256 public icoStartTime;
   
  address public crowdSale;
   
  address public executor;
   
  uint256 public purchaseCap;
   
  uint256 public minimumContribution = 0.1 ether;

  modifier onlyExecutorOrOwner() {
    require((msg.sender == executor) || (msg.sender == owner));
    _;
  }

  function ICOBuyer(address _executor, address _crowdSale, uint256 _icoStartBlock, uint256 _icoStartTime, uint256 _purchaseCap) {
    executor = _executor;
    crowdSale = _crowdSale;
    icoStartBlock = _icoStartBlock;
    icoStartTime = _icoStartTime;
    purchaseCap = _purchaseCap;
  }

  function changeCrowdSale(address _crowdSale) onlyExecutorOrOwner {
    crowdSale = _crowdSale;
    CrowdSaleChanged(crowdSale);
  }

  function changeICOStartBlock(uint256 _icoStartBlock) onlyExecutorOrOwner {
    icoStartBlock = _icoStartBlock;
    ICOStartBlockChanged(icoStartBlock);
  }

  function changeMinimumContribution(uint256 _minimumContribution) onlyExecutorOrOwner {
    minimumContribution = _minimumContribution;
    MinimumContributionChanged(minimumContribution);
  }

  function changeICOStartTime(uint256 _icoStartTime) onlyExecutorOrOwner {
    icoStartTime = _icoStartTime;
    ICOStartTimeChanged(icoStartTime);
  }

  function changePurchaseCap(uint256 _purchaseCap) onlyExecutorOrOwner {
    purchaseCap = _purchaseCap;
    PurchaseCapChanged(purchaseCap);
  }

  function changeExecutor(address _executor) onlyOwner {
    executor = _executor;
    ExecutorChanged(_executor);
  }

   
  function withdrawEther() onlyOwner {
    require(this.balance != 0);
    owner.transfer(this.balance);
    EtherWithdrawn(this.balance);
  }

   
  function withdrawTokens(address _token) onlyOwner {
    ERC20Basic token = ERC20Basic(_token);
     
    uint256 contractTokenBalance = token.balanceOf(address(this));
     
    require(contractTokenBalance != 0);
     
    assert(token.transfer(owner, contractTokenBalance));
    TokensWithdrawn(contractTokenBalance);
  }

   
  function buyICO() {
     
    if ((icoStartBlock != 0) && (getBlockNumber() < icoStartBlock)) return;
     
    if ((icoStartTime != 0) && (getNow() < icoStartTime)) return;
     
    if (this.balance < minimumContribution) return;

     
    uint256 purchaseAmount = Math.min256(this.balance, purchaseCap);
    assert(crowdSale.call.value(purchaseAmount)());
    ICOPurchased(purchaseAmount);
  }

   
   
  function () payable {
    EtherReceived(msg.sender, msg.value);
  }

   
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

   
  function getNow() internal constant returns (uint256) {
    return now;
  }

}