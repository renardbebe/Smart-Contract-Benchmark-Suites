 

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

contract ifoodToken is ERC20 {
  using SafeMath for uint256;
  
   
  address public ifoodDev = 0x4E471f031D03E5856125993dc3D59520229141Ce;
   
  address public ifoodCommunity = 0x0d72e931932356FcCf8CFF3f83390e24BE72771d;

  struct TokensWithLock {
    uint256 value;
    uint256 blockNumber;
  }
   
  mapping(address => uint256) balances;
   
   
   
  mapping(address => TokensWithLock) lockTokens;
   
  mapping(address => mapping (address => uint256)) allowed;
 
   
  string public name = "Ifoods Token";
  string public symbol = "IFOOD";
  uint8 public decimals = 18;
  
   
  uint256 public totalSupplyCap = 10**10 * 10**uint256(decimals);
   
  bool public mintingFinished = false;
   
  uint256 public deployBlockNumber = getCurrentBlockNumber();
   
  uint256 public constant TIMETHRESHOLD = 7200;
   
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
  event SetifoodDevAddress(address indexed _old, address indexed _new);
  event SetifoodCommunityAddress(address indexed _old, address indexed _new);
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

   
  function approve(address _spender, uint _value) public returns (bool success) {
     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
        revert();
    }
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
   
  function setTransferable(bool _transferable) only(ifoodDev) public {
    require(canSetTransferable == true);
    transferable = _transferable;
    SetTransferable(msg.sender, _transferable);
  }

   
  function disableSetTransferable() only(ifoodDev) public {
    transferable = true;
    canSetTransferable = false;
    DisableSetTransferable(msg.sender, false);
  }

   
  function setifoodDevAddress(address _ifoodDev) only(ifoodDev) nonZeroAddress(ifoodDev) public {
    ifoodDev = _ifoodDev;
    SetifoodDevAddress(msg.sender, _ifoodDev);
  }

   
  function setifoodCommunityAddress(address _ifoodCommunity) only(ifoodCommunity) nonZeroAddress(_ifoodCommunity) public {
    ifoodCommunity = _ifoodCommunity;
    SetifoodCommunityAddress(msg.sender, _ifoodCommunity);
  }
  
   
  function setDurationOfLock(uint256 _durationOfLock) canMint only(ifoodCommunity) public {
    require(_durationOfLock >= TIMETHRESHOLD);
    durationOfLock = _durationOfLock;
    SetDurationOfLock(msg.sender);
  }
  
   
   function getLockTokens(address _owner) nonZeroAddress(_owner) view public returns (uint256 value, uint256 blockNumber) {
     return (lockTokens[_owner].value, lockTokens[_owner].blockNumber);
   }

   
  function approveMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(ifoodCommunity) public returns (bool) {
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

   
  function withdrawMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(ifoodCommunity) public returns (bool) {
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
  
   
  function mintTokens(address _owner) canMint only(ifoodDev) nonZeroAddress(_owner) public returns (bool) {
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

   
  function finishMinting() only(ifoodDev) canMint public returns (bool) {
    mintingFinished = true;
    MintFinished(msg.sender);
    return true;
  }

  function getCurrentBlockNumber() private view returns (uint256) {
    return block.number;
  }

  function () public payable {
    revert();
  }

}