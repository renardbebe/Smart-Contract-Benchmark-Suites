 

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
  address public owner;
  address public oldOwner;
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  modifier onlyOldOwner() {
    require(msg.sender == oldOwner || msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    oldOwner = owner;
    owner = newOwner;
  }
  function backToOldOwner() onlyOldOwner public {
    require(oldOwner != address(0));
    owner = oldOwner;
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
    wallet = 0x00B95A5D838F02b12B75BE562aBF7Ee0100410922b;
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
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
   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }
}
contract HeartBoutPreICO is CappedCrowdsale, Ownable {
    using SafeMath for uint256;
    
     
    address public token;
    uint256 public minCount;
     
    mapping(string => address) bindAccountsAddress;
    mapping(address => string) bindAddressAccounts;
    string[] accounts;
    event GetBindTokensAccountEvent(address _address, string _account);
    function HeartBoutPreICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap, uint256 _minCount) public
    CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _cap)
    {
        token = 0x00305cB299cc82a8A74f8da00AFA6453741d9a15Ed;
        minCount = _minCount;
    }
     
    function () payable public {
    }
     
    function buyTokens(string _account) public payable {
        require(!stringEqual(_account, ""));
        require(validPurchase());
        require(msg.value >= minCount);
         
        if(!stringEqual(bindAddressAccounts[msg.sender], "")) {
            require(stringEqual(bindAddressAccounts[msg.sender], _account));
        }
        uint256 weiAmount = msg.value;
         
        uint256 tokens = weiAmount.mul(rate);
         
        require(token.call(bytes4(keccak256("mint(address,uint256)")), msg.sender, tokens));
        bindAccountsAddress[_account] = msg.sender;
        bindAddressAccounts[msg.sender] = _account;
        accounts.push(_account);
         
        weiRaised = weiRaised.add(weiAmount);
        forwardFunds();
    }
    function getEachBindAddressAccount() onlyOwner public {
         
        for (uint i = 0; i < accounts.length; i++) {
            GetBindTokensAccountEvent(bindAccountsAddress[accounts[i]], accounts[i]);
        }
    }
    function getBindAccountAddress(string _account) public constant returns (address) {
        return bindAccountsAddress[_account];
    }
    function getBindAddressAccount(address _accountAddress) public constant returns (string) {
        return bindAddressAccounts[_accountAddress];
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