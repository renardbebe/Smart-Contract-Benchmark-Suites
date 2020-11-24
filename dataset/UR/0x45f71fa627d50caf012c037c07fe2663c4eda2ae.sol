 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

interface IERC223Receiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) external;
}


 
 
contract SmartToken is BurnableToken, CappedToken, PausableToken {
  constructor(uint256 _cap) public CappedToken(_cap) {}

  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) 
  {
    bytes memory empty;
    return transferFrom(
      _from, 
      _to, 
      _value, 
      empty
    );
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) public returns (bool)
  {
    require(_value <= allowed[_from][msg.sender], "Used didn't allow sender to interact with balance");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (isContract(_to)) {
      return transferToContract(
        _from, 
        _to, 
        _value, 
        _data
      ); 
    } else {
      return transferToAddress(
        _from, 
        _to, 
        _value, 
        _data
      );
    }
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(
        msg.sender,
        _to,
        _value,
        _data
      );
    } else {
      return transferToAddress(
        msg.sender,
        _to,
        _value,
        _data
      );
    }
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    bytes memory empty;
    return transfer(_to, _value, empty);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 length;
     
    assembly {
       
      length := extcodesize(_addr)
    } 
    return (length>0);
  }

  function moveTokens(address _from, address _to, uint256 _value) internal returns (bool success) {
    require(balanceOf(_from) >= _value, "Balance isn't enough");
    balances[_from] = balanceOf(_from).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);

    return true;
  }

  function transferToAddress(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value), "Tokens movement was failed");
    emit Transfer(_from, _to, _value);
    emit Transfer(
      _from,
      _to,
      _value,
      _data
    );
    return true;
  }
  
   
  function transferToContract(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) internal returns (bool success) 
  {
    require(moveTokens(_from, _to, _value), "Tokens movement was failed");
    IERC223Receiver(_to).tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value);
    emit Transfer(
      _from,
      _to,
      _value,
      _data
    );
    return true;
  }
}

 

contract SmartMultichainToken is SmartToken {
  event BlockchainExchange(
    address indexed from, 
    uint256 value, 
    uint256 indexed newNetwork, 
    bytes32 adr
  );

  constructor(uint256 _cap) public SmartToken(_cap) {}
   
   
   
   
  function blockchainExchange(
    uint256 _amount, 
    uint256 _network, 
    bytes32 _adr
  ) public 
  {
    burn(_amount);
    cap.sub(_amount);
    emit BlockchainExchange(
      msg.sender, 
      _amount, 
      _network, 
      _adr
    );
  }

   
   
   
   
   
  function blockchainExchangeFrom(
    address _from,
    uint256 _amount, 
    uint256 _network, 
    bytes32 _adr
  ) public 
  {
    require(_amount <= allowed[_from][msg.sender], "Used didn't allow sender to interact with balance");
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    _burn(_from, _amount);
    emit BlockchainExchange(
      msg.sender, 
      _amount, 
      _network,
      _adr
    );
  }
}

 

contract Blacklist is BurnableToken, Ownable {
  mapping (address => bool) public blacklist;

  event DestroyedBlackFunds(address _blackListedUser, uint _balance);
  event AddedBlackList(address _user);
  event RemovedBlackList(address _user);

  function isBlacklisted(address _maker) public view returns (bool) {
    return blacklist[_maker];
  }

  function addBlackList(address _evilUser) public onlyOwner {
    blacklist[_evilUser] = true;
    emit AddedBlackList(_evilUser);
  }

  function removeBlackList(address _clearedUser) public onlyOwner {
    blacklist[_clearedUser] = false;
    emit RemovedBlackList(_clearedUser);
  }

  function destroyBlackFunds(address _blackListedUser) public onlyOwner {
    require(blacklist[_blackListedUser], "User isn't blacklisted");
    uint dirtyFunds = balanceOf(_blackListedUser);
    _burn(_blackListedUser, dirtyFunds);
    emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
  }
}

 

contract TransferTokenPolicy is SmartToken {
  modifier isTransferAllowed(address _from, address _to, uint256 _value) {
    require(_allowTransfer(_from, _to, _value), "Transfer isn't allowed");
    _;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public isTransferAllowed(_from, _to, _value) returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  ) public isTransferAllowed(_from, _to, _value) returns (bool)
  {
    return super.transferFrom(
      _from,
      _to,
      _value,
      _data
    );
  }

  function transfer(address _to, uint256 _value, bytes _data) public isTransferAllowed(msg.sender, _to, _value) returns (bool success) {
    return super.transfer(_to, _value, _data);
  }

  function transfer(address _to, uint256 _value) public isTransferAllowed(msg.sender, _to, _value) returns (bool success) {
    return super.transfer(_to, _value);
  }

  function burn(uint256 _amount) public isTransferAllowed(msg.sender, address(0x0), _amount) {
    super.burn(_amount);
  }

  function _allowTransfer(address, address, uint256) internal returns(bool);
}

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

contract L2 is TransferTokenPolicy, SmartMultichainToken, Blacklist, DetailedERC20 {
  uint256 private precision = 4; 
  constructor() public
    DetailedERC20(
      "L2",
      "L2",
      uint8(precision)
    )
    SmartMultichainToken(
      40 * 10 ** (7 + precision)  
    ) {
  }

  function _allowTransfer(address _from, address _to, uint256) internal returns(bool) {
    return !isBlacklisted(_from) && !isBlacklisted(_to);
  }
}