 

pragma solidity ^0.4.18;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  address public admin;
   
  function Ownable() public {
    admin = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }
}
 
 contract Crowdsale {
  using SafeMath for uint256;
   
  uint256 public startTime;
  uint256 public endTime;
   
  address public wallet;
   
  uint256 public rate;
   
  uint256 public weiRaised;
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = 0x00b95a5d838f02b12b75be562abf7ee0100410922b;
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function validMintPurchase(uint256 _value) internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = _value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
}
 
 contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  function CappedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap) public
  Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_cap > 0);
    cap = _cap;
  }
   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }
   
   
  function validMintPurchase(uint256 _value) internal constant returns (bool) {
    bool withinCap = weiRaised.add(_value) <= cap;
    return super.validMintPurchase(_value) && withinCap;
  }
   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }
}
contract HeartBoutToken {
   function mint(address _to, uint256 _amount, string _account) public returns (bool);
}
contract HeartBoutPreICO is CappedCrowdsale, Ownable {
    using SafeMath for uint256;
    
     
    address public token;
    uint256 public minCount;
    function HeartBoutPreICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap, uint256 _minCount) public
    CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _cap)
    {
        token = 0x00f5b36df8732fb5a045bd90ab40082ab37897b841;
        minCount = _minCount;
    }
     
    function () payable public {}
     
    function buyTokens(string _account) public payable {
        require(!stringEqual(_account, ""));
        require(validPurchase());
        require(msg.value >= minCount);
        uint256 weiAmount = msg.value;
         
        uint256 tokens = weiAmount.mul(rate);
         
        HeartBoutToken token_contract = HeartBoutToken(token);
        token_contract.mint(msg.sender, tokens, _account);
         
        weiRaised = weiRaised.add(weiAmount);
        forwardFunds();
    }
     
    function mintTokens(address _to, uint256 _amount, string _account) onlyOwner public {
        require(!stringEqual(_account, ""));
        require(validMintPurchase(_amount));
        require(_amount >= minCount);
        uint256 weiAmount = _amount;
         
        uint256 tokens = weiAmount.mul(rate);
         
        HeartBoutToken token_contract = HeartBoutToken(token);
        token_contract.mint(_to, tokens, _account);
         
        weiRaised = weiRaised.add(weiAmount);
    }
     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    function stringEqual(string _a, string _b) internal pure returns (bool) {
        return keccak256(_a) == keccak256(_b);
    }
     
    function changeWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    }
     
    function removeContract() onlyOwner public {
        selfdestruct(wallet);
    }
}