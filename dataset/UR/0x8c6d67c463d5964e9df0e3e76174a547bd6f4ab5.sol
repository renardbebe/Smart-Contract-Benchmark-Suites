 

pragma solidity ^0.5.3;


 
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
 
contract Ownable {

  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner, "Only the Contract owner can perform this action");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner cannot be current owner");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {

   
  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _amount) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 value);

}

 
contract ERC20 is ERC20Basic {

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

  function approve(address _spender, uint256 _amount) public returns (bool success);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;
  uint balanceOfParticipant;
  uint lockedAmount;
  uint allowedAmount;
  bool lockupIsActive = false;
  uint256 lockupStartTime;

   
  mapping(address => uint256) balances;

  struct Lockup {
    uint256 lockupAmount;
  }
  Lockup lockup;
  mapping(address => Lockup) lockupParticipants;
  event LockupStarted(uint256 indexed lockupStartTime);

  function requireWithinLockupRange(address _spender, uint256 _amount) internal {
    if (lockupIsActive) {
      uint timePassed = now - lockupStartTime;
      balanceOfParticipant = balances[_spender];
      lockedAmount = lockupParticipants[_spender].lockupAmount;
      allowedAmount = lockedAmount;
      if (timePassed < 92 days) {
        allowedAmount = lockedAmount.mul(5).div(100);
      } else if (timePassed >= 92 days && timePassed < 183 days) {
        allowedAmount = lockedAmount.mul(30).div(100);
      } else if (timePassed >= 183 days && timePassed < 365 days) {
        allowedAmount = lockedAmount.mul(55).div(100);
      }
      require(
        balanceOfParticipant.sub(_amount) >= lockedAmount.sub(allowedAmount),
        "Must maintain correct % of PVC during lockup periods"
      );
    }
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != msg.sender, "Cannot transfer to self");
    require(_to != address(this), "Cannot transfer to Contract");
    require(_to != address(0), "Cannot transfer to 0x0");
    require(
      balances[msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to],
      "Cannot transfer (Not enough balance)"
    );

    requireWithinLockupRange(msg.sender, _amount);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_from != msg.sender, "Cannot transfer from self, use transfer function instead");
    require(_from != address(this) && _to != address(this), "Cannot transfer from or to Contract");
    require(_to != address(0), "Cannot transfer to 0x0");
    require(balances[_from] >= _amount, "Not enough balance to transfer from");
    require(allowed[_from][msg.sender] >= _amount, "Not enough allowance to transfer from");
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to], "Amount must be > 0 to transfer from");

    requireWithinLockupRange(_from, _amount);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    require(_spender != msg.sender, "Cannot approve an allowance to self");
    require(_spender != address(this), "Cannot approve contract an allowance");
    require(_spender != address(0), "Cannot approve 0x0 an allowance");
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken, Ownable {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public onlyOwner {
    require(_value <= balances[msg.sender], "Not enough balance to burn");
     
     

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
  }

}

 
contract GTX_TOKEN is BurnableToken {

  string public name;
  string public symbol;
  uint8 public decimals = 18;
  
   
  function() external payable {
    revert("Cannot send Ether to this contract");
  }
    
   
  constructor(address wallet) public {
    owner = wallet;
    totalSupply = uint(389000000).mul(10 ** uint256(decimals));  
    name = "GTX Token";
    symbol = "GTX";
    balances[wallet] = totalSupply;
    
     
    emit Transfer(address(0), msg.sender, totalSupply);
  }
    
   
  function getTokenDetail() public view returns (string memory, string memory, uint256) {
    return (name, symbol, totalSupply);
  }

  function vest(address[] memory _owners, uint[] memory _amounts) public onlyOwner {
    require(_owners.length == _amounts.length, "Length of addresses & token amounts are not the same");
    for (uint i = 0; i < _owners.length; i++) {
      _amounts[i] = _amounts[i].mul(10 ** 18);
      require(_owners[i] != address(0), "Vesting funds cannot be sent to 0x0");
      require(_amounts[i] > 0, "Amount must be > 0");
      require(balances[owner] > _amounts[i], "Not enough balance to vest");
      require(balances[_owners[i]].add(_amounts[i]) > balances[_owners[i]], "Internal vesting error");

       
      balances[owner] = balances[owner].sub(_amounts[i]);
      balances[_owners[i]] = balances[_owners[i]].add(_amounts[i]);
      emit Transfer(owner, _owners[i], _amounts[i]);
      lockup = Lockup({ lockupAmount: _amounts[i] });
      lockupParticipants[_owners[i]] = lockup;
    }
  }

  function initiateLockup() public onlyOwner {
    uint256 currentTime = now;
    lockupIsActive = true;
    lockupStartTime = currentTime;
    emit LockupStarted(currentTime);
  }

  function lockupActive() public view returns (bool) {
    return lockupIsActive;
  }

  function lockupAmountOf(address _owner) public view returns (uint256) {
    return lockupParticipants[_owner].lockupAmount;
  }

}