 

pragma solidity 0.4.18;

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

 
contract SvdPreSale is Pausable {
    using SafeMath for uint256;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    address public whitelister;

     
    mapping(address => uint256) public investments;

     
    uint256 public weiRaised;

    uint256 public minWeiWhitelistInvestment;

    uint256 public minWeiInvestment;
    uint256 public maxWeiInvestment;

    mapping (address => bool) public investorWhitelist;

     
    event Investment(address indexed purchaser,
        address indexed beneficiary,
        uint256 value);

     
    event Whitelisted(address investor, bool status);

     
    function SvdPreSale(uint256 _startTime,
        uint256 _endTime,
        uint256 _minWeiInvestment,
        uint256 _maxWeiInvestment,
        uint256 _minWeiWhitelistInvestment,
        address _whitelister,
        address _wallet) public {
         
        require(_endTime > _startTime);
        require(_minWeiInvestment > 0);
        require(_maxWeiInvestment > _minWeiInvestment);
        require(_wallet != address(0));

        startTime = _startTime;
        endTime = _endTime;

        whitelister = _whitelister;

        minWeiInvestment = _minWeiInvestment;
        maxWeiInvestment = _maxWeiInvestment;
        minWeiWhitelistInvestment = _minWeiWhitelistInvestment;

        wallet = _wallet;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public whenNotPaused payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        if (weiAmount >= minWeiWhitelistInvestment) {
            require(investorWhitelist[beneficiary]);
        }

         
        weiRaised = weiRaised.add(weiAmount);

         
        investments[beneficiary] = investments[beneficiary].add(weiAmount);

        Investment(msg.sender, beneficiary, weiAmount);

        forwardFunds();
    }

     
    function hasStarted() public view returns (bool) {
        return now >= startTime;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
    function setInvestorWhitelist(address addr, bool status) public {
        require(msg.sender == whitelister);
        investorWhitelist[addr] = status;
        Whitelisted(addr, status);
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
     
    function validPurchase() internal view returns (bool) {
        if (msg.value < minWeiInvestment || msg.value > maxWeiInvestment) {
            return false;
        }
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

}