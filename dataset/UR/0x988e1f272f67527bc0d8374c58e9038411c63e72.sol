 

pragma solidity 0.4.24;

 
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract MatterToken is DetailedERC20, StandardToken, PausableToken, CappedToken, BurnableToken {
  using SafeMath for uint256;

  event MintApprovalChanged(address indexed minter, uint256 newValue);
  event MintWithData(address indexed to, uint256 amount, bytes data);

  mapping (address => uint256) mintApprovals;

   
   
  modifier hasMintPermission() {
    _;
  }

  constructor(uint256 _cap, address[] _holders, uint256[] _amounts)
    DetailedERC20("Matter", "MTR", 18)
    CappedToken(_cap)
    public
  {
    require(
      _holders.length == _amounts.length,
      "_holers and _amounts contain different number of items"
    );

    for (uint256 i = 0; i < _holders.length; ++i) {
      address holder = _holders[i];
      uint256 amount = _amounts[i];
      totalSupply_ = totalSupply_.add(amount);
      balances[holder] = balances[holder].add(amount);
      emit Mint(holder, amount);
      emit Transfer(address(0), holder, amount);
    }

    require(totalSupply_ <= _cap, "initial total supply is more than cap");
  }

  function burn(uint256 _value) public whenNotPaused {
    super.burn(_value);
  }

  function batchTransfer(address[] _to, uint256[] _amounts) public whenNotPaused {
    require(_to.length == _amounts.length, "_to and _amounts contain different number of items");

    for (uint256 i = 0; i < _to.length; ++i) {
      transfer(_to[i], _amounts[i]);
    }
  }

  function batchMint(address[] _to, uint256[] _amounts) public whenNotPaused {
    require(_to.length == _amounts.length, "_to and _amounts contain different number of items");

    uint256 totalAmount = 0;

    for (uint256 i = 0; i < _to.length; ++i) {
      totalAmount = totalAmount.add(_amounts[i]);
      super.mint(_to[i], _amounts[i]);
    }

    _decreaseMintApprovalAfterMint(msg.sender, totalAmount);
  }

  function batchMintWithData(address[] _to, uint256[] _amounts, bytes _data) public whenNotPaused {
    require(_to.length == _amounts.length, "_to and _amounts contain different number of items");

    uint256 totalAmount = 0;

    for (uint256 i = 0; i < _to.length; ++i) {
      emit MintWithData(_to[i], _amounts[i], _data);
      totalAmount = totalAmount.add(_amounts[i]);
      super.mint(_to[i], _amounts[i]);
    }

    _decreaseMintApprovalAfterMint(msg.sender, totalAmount);
  }

  function mint(address _to, uint256 _amount)
    public
    whenNotPaused
    returns (bool)
  {
    _decreaseMintApprovalAfterMint(msg.sender, _amount);
    return super.mint(_to, _amount);
  }

  function mintWithData(address _to, uint256 _amount, bytes _data)
    public
    whenNotPaused
    returns (bool)
  {
    _decreaseMintApprovalAfterMint(msg.sender, _amount);
    emit MintWithData(_to, _amount, _data);
    return super.mint(_to, _amount);
  }

  function _decreaseMintApprovalAfterMint(address _minter, uint256 _mintedAmount) internal {
    if (_minter != owner) {
      uint256 approval = mintApprovals[_minter];
      require(approval >= _mintedAmount, "mint approval is insufficient to mint this amount");
      mintApprovals[_minter] = approval.sub(_mintedAmount);
    }
  }

  function increaseMintApproval(address _minter, uint256 _addedValue)
    public
    whenNotPaused
    onlyOwner
  {
    require(_minter != owner, "cannot set mint approval for owner");
    mintApprovals[_minter] = mintApprovals[_minter].add(_addedValue);
    emit MintApprovalChanged(_minter, mintApprovals[_minter]);
  }

  function decreaseMintApproval(address _minter, uint256 _subtractedValue)
    public
    whenNotPaused
    onlyOwner
  {
    require(_minter != owner, "cannot set mint approval for owner");
    uint256 approval = mintApprovals[_minter];
    if (_subtractedValue >= approval) {
      mintApprovals[_minter] = 0;
    } else {
      mintApprovals[_minter] = approval.sub(_subtractedValue);
    }
    emit MintApprovalChanged(_minter, mintApprovals[_minter]);
  }

  function getMintApproval(address _minter) public view returns (uint256) {
    return mintApprovals[_minter];
  }

  function getMintLimit(address _minter) public view returns (uint256) {
    uint256 capLeft = cap.sub(totalSupply_);

    if (_minter == owner) {
      return capLeft;
    }

    uint256 approval = mintApprovals[_minter];
    return approval < capLeft ? approval : capLeft;
  }
}