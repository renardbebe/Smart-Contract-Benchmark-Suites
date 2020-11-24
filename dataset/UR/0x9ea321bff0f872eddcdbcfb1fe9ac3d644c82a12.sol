 

pragma solidity 0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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







 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  ERC20 public token;
  uint256 private transactionNum;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;
  uint256 public discountRate = 3333;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = ERC20(_token);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens;
    if(transactionNum < 100) {
      tokens = weiAmount.mul(discountRate);
    } else {
      tokens = weiAmount.mul(rate);
    }


    uint256 tokenBalance = token.balanceOf(this);
    require(tokenBalance >= tokens);

    transactionNum = transactionNum + 1;
     
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }



   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;

    return withinPeriod && nonZeroPurchase;
  }

  function finalization() internal {
    token.transfer(owner, token.balanceOf(this));
  }

}




contract PreICO is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  bool public isFinalized;

  uint256 public minContribution = 100000000000000000;
  uint256 public maxContribution = 1000 ether;
  function PreICO(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, address _wallet, address _token) public
  Crowdsale(_startTime, _endTime, _rate, _wallet, _token)
  {
      cap = _cap;
  }

  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

   
   
  function validPurchase() internal view returns (bool) {
     
    bool withinRange = msg.value >= minContribution && msg.value <= maxContribution;
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinRange && withinCap && super.validPurchase();
  }

  function changeMinContribution(uint256 _minContribution) public onlyOwner {
    require(_minContribution > 0);
    minContribution = _minContribution;
  }

  function changeMaxContribution(uint256 _maxContribution) public onlyOwner {
    require(_maxContribution > 0);
    maxContribution = _maxContribution;
  }

  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    super.finalization();
    isFinalized = true;
  }

  function setNewWallet(address _newWallet) onlyOwner public {
    wallet = _newWallet;
  }

}