 

pragma solidity ^0.4.18;


 
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

 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AElfToken is ERC20, Ownable {
  using SafeMath for uint256;

  
   
  address public aelfDevMultisig = 0x6d3E0B5abFc141cAa674a3c11e1580e6fff2a0B9;
   
  address public aelfCommunityMultisig = 0x4885B422656D4B316C9C7Abc0c0Ab31A2677d9f0;

  struct TokensWithLock {
    uint256 value;
    uint256 blockNumber;
  }
   
  mapping(address => uint256) balances;
   
   
   
  mapping(address => TokensWithLock) lockTokens;
  
   
  mapping(address => mapping (address => uint256)) allowed;
   
  uint256 public totalSupplyCap = 1e27;
   
  string public name = "ELF Token";
  string public symbol = "ELF";
  uint8 public decimals = 18;

  bool public mintingFinished = false;
   
  uint256 public deployBlockNumber = getCurrentBlockNumber();
   
  uint256 public constant TIMETHRESHOLD = 7200;
   
  uint256 public constant MINTTIME = 216000;
   
  uint256 public durationOfLock = 7200;
   
  bool public transferable = false;
   
  bool public canSetTransferable = true;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier only(address _address) {
    require(msg.sender == _address);
    _;
  }

  modifier nonZeroAddress(address _address) {
    require(_address != address(0));
    _;
  }

  modifier canTransfer() {
    require(transferable == true);
    _;
  }

  event SetDurationOfLock(address indexed _caller);
  event ApproveMintTokens(address indexed _owner, uint256 _amount);
  event WithdrawMintTokens(address indexed _owner, uint256 _amount);
  event MintTokens(address indexed _owner, uint256 _amount);
  event BurnTokens(address indexed _owner, uint256 _amount);
  event MintFinished(address indexed _caller);
  event SetTransferable(address indexed _address, bool _transferable);
  event SetAElfDevMultisig(address indexed _old, address indexed _new);
  event SetAElfCommunityMultisig(address indexed _old, address indexed _new);
  event DisableSetTransferable(address indexed _address, bool _canSetTransferable);

   
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) canTransfer public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   
  function setTransferable(bool _transferable) only(aelfDevMultisig) public {
    require(canSetTransferable == true);
    transferable = _transferable;
    SetTransferable(msg.sender, _transferable);
  }

   
  function disableSetTransferable() only(aelfDevMultisig) public {
    transferable = true;
    canSetTransferable = false;
    DisableSetTransferable(msg.sender, false);
  }

   
  function setAElfDevMultisig(address _aelfDevMultisig) only(aelfDevMultisig) nonZeroAddress(_aelfDevMultisig) public {
    aelfDevMultisig = _aelfDevMultisig;
    SetAElfDevMultisig(msg.sender, _aelfDevMultisig);
  }
   
  function setAElfCommunityMultisig(address _aelfCommunityMultisig) only(aelfCommunityMultisig) nonZeroAddress(_aelfCommunityMultisig) public {
    aelfCommunityMultisig = _aelfCommunityMultisig;
    SetAElfCommunityMultisig(msg.sender, _aelfCommunityMultisig);
  }
   
  function setDurationOfLock(uint256 _durationOfLock) canMint only(aelfCommunityMultisig) public {
    require(_durationOfLock >= TIMETHRESHOLD);
    durationOfLock = _durationOfLock;
    SetDurationOfLock(msg.sender);
  }
   
   function getLockTokens(address _owner) nonZeroAddress(_owner) view public returns (uint256 value, uint256 blockNumber) {
     return (lockTokens[_owner].value, lockTokens[_owner].blockNumber);
   }

   
  function approveMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfCommunityMultisig) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens + _amount >= previousLockTokens);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply);  
    require(curTotalSupply + _amount <= totalSupplyCap);   
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    lockTokens[_owner].value = previousLockTokens.add(_amount);
    uint256 curBlockNumber = getCurrentBlockNumber();
    lockTokens[_owner].blockNumber = curBlockNumber.add(durationOfLock);
    ApproveMintTokens(_owner, _amount);
    return true;
  }
   
  function withdrawMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfCommunityMultisig) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens - _amount >= 0);
    lockTokens[_owner].value = previousLockTokens.sub(_amount);
    if (previousLockTokens - _amount == 0) {
      lockTokens[_owner].blockNumber = 0;
    }
    WithdrawMintTokens(_owner, _amount);
    return true;
  }
   
  function mintTokens(address _owner) canMint only(aelfDevMultisig) nonZeroAddress(_owner) public returns (bool) {
    require(lockTokens[_owner].blockNumber <= getCurrentBlockNumber());
    uint256 _amount = lockTokens[_owner].value;
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply);  
    require(curTotalSupply + _amount <= totalSupplyCap);   
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    lockTokens[_owner].value = 0;
    lockTokens[_owner].blockNumber = 0;
    MintTokens(_owner, _amount);
    Transfer(0, _owner, _amount);
    return true;
  }
   
  function mintTokensWithinTime(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfDevMultisig) public returns (bool) {
    require(_amount > 0);
    require(getCurrentBlockNumber() < (deployBlockNumber + MINTTIME));
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply);  
    require(curTotalSupply + _amount <= totalSupplyCap);   
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo);  
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    MintTokens(_owner, _amount);
    Transfer(0, _owner, _amount);
    return true;
  }
   
  function transferForMultiAddresses(address[] _addresses, uint256[] _amounts) canTransfer public returns (bool) {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_amounts[i] <= balances[msg.sender]);
      require(_amounts[i] > 0);

       
      balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
      Transfer(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }

   
  function burnTokens(uint256 _amount) public returns (bool) {
    require(_amount > 0);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply >= _amount);
    uint256 previousBalanceTo = balanceOf(msg.sender);
    require(previousBalanceTo >= _amount);
    totalSupply = curTotalSupply.sub(_amount);
    balances[msg.sender] = previousBalanceTo.sub(_amount);
    BurnTokens(msg.sender, _amount);
    Transfer(msg.sender, 0, _amount);
    return true;
  }
   
  function finishMinting() only(aelfDevMultisig) canMint public returns (bool) {
    mintingFinished = true;
    MintFinished(msg.sender);
    return true;
  }

  function getCurrentBlockNumber() private view returns (uint256) {
    return block.number;
  }
}