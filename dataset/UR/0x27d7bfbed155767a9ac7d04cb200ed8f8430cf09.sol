 

pragma solidity ^0.4.19;

 
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

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable(address _owner) public {
    owner = _owner;
  }

   
  modifier onlyOwner() {
    require(tx.origin == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.19;

contract Stoppable is Ownable {
  bool public halted;

  event SaleStopped(address owner, uint256 datetime);

  function Stoppable(address owner) public Ownable(owner) {}

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

  function hasHalted() public view returns (bool isHalted) {
  	return halted;
  }

    
  function stopICO() external onlyOwner {
    halted = true;
    SaleStopped(msg.sender, now);
  }
}

pragma solidity ^0.4.19;

 
contract SALE_mtf is Stoppable {
  using SafeMath for uint256;

  bool private approval = false;

  mtfToken public token;
  uint256 public rate;

  uint256 public startTime;
  uint256 public endTime;

  uint256 public weiRaised;
  uint256 public tokensSent;

  mapping(address => uint256) public balanceOf;
  mapping(address => uint256) public tokenBalanceOf;

  address public iconemy_wallet;
  uint256 public commission; 

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 datetime);
  event BeneficiaryWithdrawal(address beneficiary, uint256 amount, uint256 datetime);
  event CommissionCollected(address beneficiary, uint256 amount, uint256 datetime);

   
  function SALE_mtf(address _token, uint256 _rate, uint256 _startTime, uint256 _endTime, address _iconemy, address _owner) public Stoppable(_owner) {
    require(_startTime > now);
    require(_startTime < _endTime);

    token = mtfToken(_token);

    rate = _rate;
    startTime = _startTime;
    endTime = _endTime;
    iconemy_wallet = _iconemy;
  }

   
   
   
  function receiveApproval() onlyOwner external {
    approval = true;
    uint256 allowance = allowanceOf();

     
    commission = allowance / 100;
  }

   
  function allowanceOf() public view returns(uint256) {
    return token.allowanceOf(owner, this);
  }

   
  function hasApproval() public view returns(bool) {
    return approval;
  }

  function getPrice() public view returns(uint256) {
    return rate;
  }

    
  function buyTokens() public stopInEmergency payable {
    uint256 weiAmount = msg.value;

     
    uint256 tokens = tokensToRecieve(weiAmount);

    validPurchase(tokens);

    finalizeSale(msg.sender, weiAmount, tokens);

    TokenPurchase(msg.sender, msg.value, tokens, now);
  }

   
  function checkAllowance(uint256 _tokens) public view {
    uint256 allowance = allowanceOf();

    allowance = allowance - commission;

    require(allowance >= _tokens);
  }

   
  function finalizeSale(address from, uint256 _weiAmount, uint256 _tokens) internal {
    require(token.transferFrom(owner, from, _tokens));

    balanceOf[from] = balanceOf[from].add(_weiAmount);
    tokenBalanceOf[from] = tokenBalanceOf[from].add(_tokens);

    weiRaised = weiRaised.add(_weiAmount);
    tokensSent = tokensSent.add(_tokens);
  }

   
  function tokensToRecieve(uint256 _wei) internal view returns (uint256 tokens) {
    return _wei.div(rate);
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime || halted;
  }

   
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    require(!hasEnded());

    checkAllowance(_tokens);

    bool withinPeriod = now >= startTime && now <= endTime;

    bool nonZeroPurchase = msg.value != 0;

    require(withinPeriod && nonZeroPurchase);
  }

   
   
  function refundAvailable() public view returns(bool) {
    return balanceOf[msg.sender] > 0 && hasHalted();
  }

   
  function collectRefund() public onlyInEmergency {
    uint256 balance = balanceOf[msg.sender];

    require(balance > 0);

    balanceOf[msg.sender] = 0;

    msg.sender.transfer(balance);
  }

   
  function collectInvestment() public onlyOwner stopInEmergency returns(bool) {
    require(hasEnded());

    owner.transfer(weiRaised);
    BeneficiaryWithdrawal(owner, weiRaised, now);
  }

   
  function collectCommission() public stopInEmergency returns(bool) {
    require(msg.sender == iconemy_wallet);
    require(hasEnded());

    uint256 one_percent = tokensSent / 100;

    finalizeSale(iconemy_wallet, 0, one_percent);

    CommissionCollected(iconemy_wallet, one_percent, now);
  }
}  

 
contract mtfToken { 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success); 
  function allowanceOf(address _owner, address _spender) public constant returns (uint256 remaining);
}