 

pragma solidity ^0.4.18;

 
library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

library SafeMath64 {
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a);
    return a - b;
  }

  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a);
    return c;
  }
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


 
contract Karma is Ownable, DetailedERC20("KarmaToken", "KARMA", 0) {
   
  using SafeMath for uint256;
  using SafeMath64 for uint64;

   
  struct User {
    bytes20 username;
    uint64 karma; 
    uint16 canWithdrawPeriod;
    uint16 birthPeriod;
  }

   
  mapping(address => User) public users;
  mapping(bytes20 => address) public usernames;

   
  uint256 public epoch;
  uint256 public dividend;
  uint64 public numUsers;
  uint64 public newUsers;
  uint16 public currentPeriod = 1;

  address public moderator;

  mapping(address => mapping (address => uint256)) internal allowed;

  event Mint(address indexed to, uint256 amount);
  event PeriodEnd(uint16 period, uint256 amount, uint64 users);
  event Donation(address indexed from, uint256 amount);
  event Withdrawal(address indexed to, uint16 indexed period, uint256 amount);
  event NewUser(address addr, bytes20 username, uint64 endowment);

  modifier onlyMod() {
    require(msg.sender == moderator);
    _;
  }

  function Karma(uint256 _startEpoch) public {
    epoch = _startEpoch;
    moderator = msg.sender;
  }

  function() payable public {
    Donation(msg.sender, msg.value);
  }

   

  function setMod(address _newMod) public onlyOwner {
    moderator = _newMod;
  }

   
  function newPeriod() public onlyOwner {
    require(now >= epoch + 28 days);

     
    uint64 existingUsers = numUsers;
    if (existingUsers == 0) {
      dividend = 0;
    } else {
      dividend = this.balance / existingUsers;
    }

    numUsers = numUsers.add(newUsers);
    newUsers = 0;
    currentPeriod++;
    epoch = now;

    PeriodEnd(currentPeriod-1, this.balance, existingUsers);
  }

   

  function createUser(address _addr, bytes20 _username, uint64 _amount) public onlyMod {
    newUser(_addr, _username, _amount);
  }

   
  function mint(address _addr, uint64 _amount) public onlyMod {
    require(users[_addr].canWithdrawPeriod != 0);

    users[_addr].karma = users[_addr].karma.add(_amount);
    totalSupply = totalSupply.add(_amount);
    Mint(_addr, _amount);
  }

   
  function timeout(address _addr) public onlyMod {
    require(users[_addr].canWithdrawPeriod != 0);

    users[_addr].canWithdrawPeriod = currentPeriod + 1;
  }

   

   
   
  function register(bytes20 _username, uint64 _endowment, bytes _sig) public {
    require(recover(keccak256(msg.sender, _username, _endowment), _sig) == owner);
    newUser(msg.sender, _username, _endowment);
  }

   
  function withdraw() public {
    require(users[msg.sender].canWithdrawPeriod != 0);
    require(users[msg.sender].canWithdrawPeriod < currentPeriod);

    users[msg.sender].canWithdrawPeriod = currentPeriod;
    msg.sender.transfer(dividend);
    Withdrawal(msg.sender, currentPeriod-1, dividend);
  }

   

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return users[_owner].karma;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(users[_to].canWithdrawPeriod != 0);
    require(_value <= users[msg.sender].karma);

     
    users[msg.sender].karma = users[msg.sender].karma.sub(uint64(_value));
    users[_to].karma = users[_to].karma.add(uint64(_value));
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(users[_to].canWithdrawPeriod != 0);
    require(_value <= users[_from].karma);
    require(_value <= allowed[_from][msg.sender]);

    users[_from].karma = users[_from].karma.sub(uint64(_value));
    users[_to].karma = users[_to].karma.add(uint64(_value));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   

   
  function recover(bytes32 hash, bytes sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

   
   
  function newUser(address _addr, bytes20 _username, uint64 _endowment) private {
    require(usernames[_username] == address(0));
    require(users[_addr].canWithdrawPeriod == 0);

    users[_addr].canWithdrawPeriod = currentPeriod + 1;
    users[_addr].birthPeriod = currentPeriod;
    users[_addr].karma = _endowment;
    users[_addr].username = _username;
    usernames[_username] = _addr;

    newUsers = newUsers.add(1);
    totalSupply = totalSupply.add(_endowment);
    NewUser(_addr, _username, _endowment);
  }
}