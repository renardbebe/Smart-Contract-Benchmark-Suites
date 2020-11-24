 

pragma solidity ^0.4.18;

 

 
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

 

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

   
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

 

 
 
pragma solidity ^0.4.8;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract Leverjbounty is Owned {

  mapping (address => bool) public users;

  mapping (address => uint256) public social;

  uint256 public levPerUser;

  Token public token;

  bool public dropEnabled;

  event Redeemed(address user, uint tokens);

  modifier isDropEnabled{
    require(dropEnabled);
    _;
  }

  function Leverjbounty(address[] owners, address _token, uint256 _levPerUser) public {
    require(_token != address(0x0));
    require(_levPerUser > 0);
    setOwners(owners);
    token = Token(_token);
    levPerUser = _levPerUser;
  }

  function addUsers(address[] _users) onlyOwner public {
    require(_users.length > 0);
    for (uint i = 0; i < _users.length; i++) {
      users[_users[i]] = true;
    }
  }

  function addSocial(address[] _users, uint256[] _tokens) onlyOwner public {
    require(_users.length > 0 && _users.length == _tokens.length);
    for (uint i = 0; i < _users.length; i++) {
      social[_users[i]] = _tokens[i];
    }
  }

  function removeUsers(address[] _users) onlyOwner public {
    require(_users.length > 0);
    for (uint i = 0; i < _users.length; i++) {
      users[_users[i]] = false;
    }
  }

  function toggleDrop() onlyOwner public {
    dropEnabled = !dropEnabled;
  }

  function redeemTokens() isDropEnabled public {
    uint256 balance = balanceOf(msg.sender);
    require(balance > 0);
    users[msg.sender] = false;
    social[msg.sender] = 0;
    token.transfer(msg.sender, balance);
    Redeemed(msg.sender, balance);
  }

  function balanceOf(address user) public constant returns (uint256) {
    uint256 levs = social[user];
    if (users[user]) levs += levPerUser;
    return levs;
  }

  function transferTokens(address _address, uint256 _amount) onlyOwner public {
    token.transfer(_address, _amount);
  }
}