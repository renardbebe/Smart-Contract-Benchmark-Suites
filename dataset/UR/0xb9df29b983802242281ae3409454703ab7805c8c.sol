 

pragma solidity 0.4.19;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


contract PrivateSale {
  using SafeMath for uint256;

   
  address public owner;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  bool public isAcceptingPayments;

   
  mapping (address => bool) public whitelistAdmins;

   
  mapping (address => bool) public whitelist;
  uint256 public whitelistCount;

   
  mapping (address => uint256) public weiPaid;

  uint256 public HARD_CAP = 6666 ether;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyWhitelistAdmin() {
    require(whitelistAdmins[msg.sender]);
    _;
  }

   
  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  modifier acceptingPayments() {
    require(isAcceptingPayments);
    _;
  }

   
  function PrivateSale(address _wallet) public {
    require(_wallet != address(0));
    owner = msg.sender;
    wallet = _wallet;
    whitelistAdmins[msg.sender] = true;
  }

   
  function () isWhitelisted acceptingPayments payable public {
    require(msg.value >= 0.2 ether);
    require(msg.value <= 500 ether);
    require(msg.sender != address(0));
    
    uint256 contribution = msg.value;
     
    weiPaid[msg.sender] += msg.value;

     
    weiRaised = weiRaised.add(msg.value);

    if (weiRaised > HARD_CAP) {
      uint256 refundAmount = weiRaised.sub(HARD_CAP);
      msg.sender.transfer(refundAmount);
      contribution = contribution.sub(refundAmount);
      refundAmount = 0;
      weiRaised = HARD_CAP;
      isAcceptingPayments = false;
    }

     
    wallet.transfer(contribution);
  }

   
  function acceptPayments() onlyOwner public  {
    isAcceptingPayments = true;
  }

   
  function rejectPayments() onlyOwner public  {
    isAcceptingPayments = false;
  }

   
  function addWhitelistAdmin(address _admin) onlyOwner public {
    whitelistAdmins[_admin] = true;
  }

   
  function removeWhitelistAdmin(address _admin) onlyOwner public {
    whitelistAdmins[_admin] = false;
  }

   
  function whitelistAddress(address _user) onlyWhitelistAdmin public  {
    whitelist[_user] = true;
  }

   
  function whitelistAddresses(address[] _users) onlyWhitelistAdmin public {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelist[_users[i]] = true;
    }
  }

   
  function unWhitelistAddress(address _user) onlyWhitelistAdmin public  {
    whitelist[_user] = false;
  }

   
  function unWhitelistAddresses(address[] _users) onlyWhitelistAdmin public {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelist[_users[i]] = false;
    }
  }
}