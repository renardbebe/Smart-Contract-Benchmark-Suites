 

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


 
contract SolClub is Ownable, DetailedERC20("SolClub", "SOL", 0) {
   
  using SafeMath for uint256;
  using SafeMath64 for uint64;

  struct Member {
    bytes20 username;
    uint64 karma; 
    uint16 canWithdrawPeriod;
    uint16 birthPeriod;
  }

   
  mapping(address => Member) public members;
  mapping(bytes20 => address) public usernames;

   
  uint256 public epoch;  
  uint256 dividendPool;  
  uint256 public dividend;  
  uint256 public ownerCut;  
  uint64 public numMembers;  
  uint64 public newMembers;  
  uint16 public currentPeriod = 1;

  address public moderator;

  mapping(address => mapping (address => uint256)) internal allowed;

  event Mint(address indexed to, uint256 amount);
  event PeriodEnd(uint16 period, uint256 amount, uint64 members);
  event Payment(address indexed from, uint256 amount);
  event Withdrawal(address indexed to, uint16 indexed period, uint256 amount);
  event NewMember(address indexed addr, bytes20 username, uint64 endowment);
  event RemovedMember(address indexed addr, bytes20 username, uint64 karma, bytes32 reason);

  modifier onlyMod() {
    require(msg.sender == moderator);
    _;
  }

  function SolClub() public {
    epoch = now;
    moderator = msg.sender;
  }

  function() payable public {
    Payment(msg.sender, msg.value);
  }

   

  function setMod(address _newMod) public onlyOwner {
    moderator = _newMod;
  }

   
   
  function newPeriod(uint256 _ownerCut) public onlyOwner {
    require(now >= epoch + 15 days);
    require(_ownerCut <= 10000);

    uint256 unclaimedDividend = dividendPool;
    uint256 ownerRake = (address(this).balance-unclaimedDividend) * ownerCut / 10000;

    dividendPool = address(this).balance - unclaimedDividend - ownerRake;

     
    uint64 existingMembers = numMembers;
    if (existingMembers == 0) {
      dividend = 0;
    } else {
      dividend = dividendPool / existingMembers;
    }

    numMembers = numMembers.add(newMembers);
    newMembers = 0;
    currentPeriod++;
    epoch = now;
    ownerCut = _ownerCut;

    msg.sender.transfer(ownerRake + unclaimedDividend);
    PeriodEnd(currentPeriod-1, this.balance, existingMembers);
  }

   
   
  function removeMember(address _addr, bytes32 _reason) public onlyOwner {
    require(members[_addr].birthPeriod != 0);
    Member memory m = members[_addr];

    totalSupply = totalSupply.sub(m.karma);
    if (m.birthPeriod == currentPeriod) {
      newMembers--;
    } else {
      numMembers--;
    }

     
    usernames[m.username] = address(0x1);

    delete members[_addr];
    RemovedMember(_addr, m.username, m.karma, _reason);
  }

   
  function deleteUsername(bytes20 _username) public onlyOwner {
    require(usernames[_username] == address(0x1));
    delete usernames[_username];
  }

   

  function createMember(address _addr, bytes20 _username, uint64 _amount) public onlyMod {
    newMember(_addr, _username, _amount);
  }

   
  function mint(address _addr, uint64 _amount) public onlyMod {
    require(members[_addr].canWithdrawPeriod != 0);

    members[_addr].karma = members[_addr].karma.add(_amount);
    totalSupply = totalSupply.add(_amount);
    Mint(_addr, _amount);
  }

   
  function timeout(address _addr) public onlyMod {
    require(members[_addr].canWithdrawPeriod != 0);

    members[_addr].canWithdrawPeriod = currentPeriod + 1;
  }

   

   
   
  function register(bytes20 _username, uint64 _endowment, bytes _sig) public {
    require(recover(keccak256(msg.sender, _username, _endowment), _sig) == owner);
    newMember(msg.sender, _username, _endowment);
  }

   
  function withdraw() public {
    require(members[msg.sender].canWithdrawPeriod != 0);
    require(members[msg.sender].canWithdrawPeriod < currentPeriod);

    members[msg.sender].canWithdrawPeriod = currentPeriod;
    dividendPool -= dividend;
    msg.sender.transfer(dividend);
    Withdrawal(msg.sender, currentPeriod-1, dividend);
  }

   

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return members[_owner].karma;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(members[_to].canWithdrawPeriod != 0);
    require(_value <= members[msg.sender].karma);

     
    members[msg.sender].karma = members[msg.sender].karma.sub(uint64(_value));
    members[_to].karma = members[_to].karma.add(uint64(_value));
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
    require(members[_to].canWithdrawPeriod != 0);
    require(_value <= members[_from].karma);
    require(_value <= allowed[_from][msg.sender]);

    members[_from].karma = members[_from].karma.sub(uint64(_value));
    members[_to].karma = members[_to].karma.add(uint64(_value));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   

   
   
  function newMember(address _addr, bytes20 _username, uint64 _endowment) private {
    require(usernames[_username] == address(0));
    require(members[_addr].canWithdrawPeriod == 0);

    members[_addr].canWithdrawPeriod = currentPeriod + 1;
    members[_addr].birthPeriod = currentPeriod;
    members[_addr].karma = _endowment;
    members[_addr].username = _username;
    usernames[_username] = _addr;

    newMembers = newMembers.add(1);
    totalSupply = totalSupply.add(_endowment);
    NewMember(_addr, _username, _endowment);
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
}