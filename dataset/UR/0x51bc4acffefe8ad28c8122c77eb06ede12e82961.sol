 

 

 

pragma solidity ^0.4.23;

 
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

 
interface CrowdSale {
  function crowdSaleCheck() external view returns (bool);
}

 
interface InvestorsStorage {
  function newInvestment(address _investor, uint256 _amount) external;
  function getInvestedAmount(address _investor) external view returns (uint256);
}

 
interface TokenContract {

   
  function transfer(address _recipient, uint256 _amount) external returns (bool);

   
  function balanceOf(address _holder) external view returns (uint256);
}

 
contract PreSale  is Ownable {
  using SafeMath for uint256;

   

  TokenContract public tkn;
  CrowdSale public cSale;
  InvestorsStorage public investorsStorage;
  uint256 public levelEndDate;
  uint256 public currentLevel;
  uint256 public levelTokens = 375000;
  uint256 public tokensSold;
  uint256 public weiRised;
  uint256 public ethPrice;
  address[] public investorsList;
  bool public presalePaused;
  bool public presaleEnded;
  uint256[12] private tokenPrice = [4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48];
  uint256 private baseTokens = 375000;
  uint256 private usdCentValue;
  uint256 private minInvestment;

   
  constructor() public {
    tkn = TokenContract(0x5313E9783E5b56389b14Cd2a99bE9d283a03f8c6);                     
    investorsStorage = InvestorsStorage(0x15c7c30B980ef442d3C811A30346bF9Dd8906137);       
    minInvestment = 100 finney;
    updatePrice(5000);
  }

   
  function() payable public {
    require(msg.value >= minInvestment);    
    require(!presalePaused);
    require(!presaleEnded);
    prepareSell(msg.sender, msg.value);
  }

   
  function prepareSell(address _investor, uint256 _amount) private {
    uint256 remaining;
    uint256 pricePerCent;
    uint256 pricePerToken;
    uint256 toSell;
    uint256 amount = _amount;
    uint256 sellInWei;
    address investor = _investor;

    pricePerCent = getUSDPrice();
    pricePerToken = pricePerCent.mul(tokenPrice[currentLevel]);  
    toSell = _amount.div(pricePerToken);  

    if (toSell < levelTokens) {  
      levelTokens = levelTokens.sub(toSell);
      weiRised = weiRised.add(_amount);
      executeSell(investor, toSell, _amount);
      owner.transfer(_amount);
    } else {  
      while (amount > 0) {
        if (toSell > levelTokens) {
          toSell = levelTokens;  
          sellInWei = toSell.mul(pricePerToken);
          amount = amount.sub(sellInWei);
          if (currentLevel < 11) {  
            currentLevel += 1;
            levelTokens = baseTokens;
          } else {
            remaining = amount;
            amount = 0;
          }
        } else {
          sellInWei = amount;
          amount = 0;
        }
        
        executeSell(investor, toSell, sellInWei); 
        weiRised = weiRised.add(sellInWei);
        owner.transfer(amount);
        if (amount > 0) {
          toSell = amount.div(pricePerToken);
        }
        if (remaining > 0) {  
          investor.transfer(remaining);
          owner.transfer(address(this).balance);
          presaleEnded = true;
        }
      }
    }
  }

   
  function executeSell(address _investor, uint256 _tokens, uint256 _weiAmount) private {
    uint256 totalTokens = _tokens * (10 ** 18);
    tokensSold += _tokens;  
    investorsStorage.newInvestment(_investor, _weiAmount);  

    require(tkn.transfer(_investor, totalTokens));  
    emit NewInvestment(_investor, totalTokens);   
  }

   
  function getUSDPrice() private view returns (uint256) {
    return usdCentValue;
  }

   
  function updatePrice(uint256 _ethPrice) private {
    uint256 centBase = 1 * 10 ** 16;
    require(_ethPrice > 0);
    ethPrice = _ethPrice;
    usdCentValue = centBase.div(_ethPrice);
  }

   
  function setUsdEthValue(uint256 _ethPrice) onlyOwner external {  
    updatePrice(_ethPrice);
  }

   
  function setCrowdSaleAddress(address _crowdSale) onlyOwner public {  
    cSale = CrowdSale(_crowdSale);
  }

   
  function setStorageAddress(address _investorsStorage) onlyOwner public {  
    investorsStorage = InvestorsStorage(_investorsStorage);
  }

   
  function pausePresale(bool _paused) onlyOwner public {  
    presalePaused = _paused;
  }

   
  function getFunds() onlyOwner public {  
    owner.transfer(address(this).balance);
  }

  event NewInvestment(address _investor, uint256 tokens);
}