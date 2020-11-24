 

pragma solidity ^0.4.18;

 
library SafeMath {
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

 
 
 
 
 
 
 
 
 
 
contract RoyalForkToken is Ownable, DetailedERC20("RoyalForkToken", "RFT", 0) {
  using SafeMath for uint256;

  struct Hodler {
    bytes16 username;
    uint64 balance;
    uint16 canWithdrawPeriod;
  }

  mapping(address => Hodler) public hodlers;
  mapping(bytes16 => address) public usernames;

  uint256 public epoch = now;
  uint16 public currentPeriod = 1;
  uint64 public numHodlers;
  uint64 public prevHodlers;
  uint256 public prevBalance;

  address minter;

  mapping(address => mapping (address => uint256)) internal allowed;

  event Mint(address indexed to, uint256 amount);
  event PeriodEnd(uint16 indexed period, uint256 amount, uint64 hodlers);
  event Donation(address indexed from, uint256 amount);
  event Withdrawal(address indexed to, uint16 indexed period, uint256 amount);

  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
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

   
   
  function newHodler(address user, bytes16 username, uint64 endowment) private {
    require(usernames[username] == address(0));
    require(hodlers[user].canWithdrawPeriod == 0);

    hodlers[user].canWithdrawPeriod = currentPeriod;
    hodlers[user].balance = endowment;
    hodlers[user].username = username;
    usernames[username] = user;

    numHodlers += 1;
    totalSupply += endowment;
    Mint(user, endowment);
  }

   
  function setMinter(address newMinter) public onlyOwner {
    minter = newMinter;
  }

   
  function newPeriod() public onlyOwner {
    require(now >= epoch + 28 days);
    currentPeriod++;
    prevHodlers = numHodlers;
    prevBalance = this.balance;
    PeriodEnd(currentPeriod-1, prevBalance, prevHodlers);
  }

   
  function createHodler(address to, bytes16 username, uint64 amount) public onlyMinter {
    newHodler(to, username, amount);
  }

   
  function mint(address user, uint64 amount) public onlyMinter {
    require(hodlers[user].canWithdrawPeriod != 0);
    require(hodlers[user].balance + amount > hodlers[user].balance);

    hodlers[user].balance += amount;
    totalSupply += amount;
    Mint(user, amount);
  }

   
   
   
  function create(bytes16 username, uint64 endowment, bytes sig) public {
    require(recover(keccak256(endowment, msg.sender), sig) == owner);
    newHodler(msg.sender, username, endowment);
  }

   
  function withdraw() public {
    require(hodlers[msg.sender].canWithdrawPeriod != 0);
    require(hodlers[msg.sender].canWithdrawPeriod < currentPeriod);

    hodlers[msg.sender].canWithdrawPeriod = currentPeriod;
    uint256 payment = prevBalance / prevHodlers;
    prevHodlers -= 1;
    prevBalance -= payment;
    msg.sender.send(payment);
    Withdrawal(msg.sender, currentPeriod-1, payment);
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return hodlers[_owner].balance;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(hodlers[_to].canWithdrawPeriod != 0);
    require(_value <= hodlers[msg.sender].balance);
    require(hodlers[_to].balance + uint64(_value) > hodlers[_to].balance);

    hodlers[msg.sender].balance -= uint64(_value);
    hodlers[_to].balance += uint64(_value);
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
    require(hodlers[_to].canWithdrawPeriod != 0);
    require(_value <= hodlers[_from].balance);
    require(_value <= allowed[_from][msg.sender]);
    require(hodlers[_to].balance + uint64(_value) > hodlers[_to].balance);

    hodlers[_from].balance -= uint64(_value);
    hodlers[_to].balance += uint64(_value);
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

   
  function RoyalForkToken() public {
    minter = msg.sender;
  }

  function() payable public {
    Donation(msg.sender, msg.value);
  }
}