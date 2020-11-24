 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
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

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns(bool) {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool) {
    super.transferFrom(_from, _to, _value);
  }
}


 
contract CMBToken is PausableToken {

  using SafeMath for uint256;
  string public constant name = "Creatanium";
  string public constant symbol = "CMB";
  uint8 public constant decimals = 18;

  uint256 public constant initialSupply_ = 2000000000 * (10 ** uint256(decimals));
  uint256 public mintedSupply_ = 0;
  mapping(address => uint256) lockedBalances;
  
  event Mint(address _to, uint256 amount);
  event TokensLocked(address beneficiary, uint256 amount);
  event TokensUnlocked(address beneficiary, uint256 amount);
  
  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }
  
   
  constructor() public {
    totalSupply_ = initialSupply_;
    balances[msg.sender] = balances[msg.sender].add(initialSupply_);
    emit Transfer(address(0), msg.sender, initialSupply_);
  }
  
   
  function mint(
    uint256 _amount
  )
    public
    hasMintPermission
    whenNotPaused
    returns (bool)
  {
    require(mintedSupply_.add(_amount)<=totalSupply_);
    require(_amount > 0);
    mintedSupply_ = mintedSupply_.add(_amount);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    emit Mint(msg.sender, _amount);
    emit Transfer(address(0), msg.sender, _amount);
    return true;
  }
  
  function setTotalSupply(uint256 _value) public onlyOwner {
    require(_value >= totalSupply_);
    totalSupply_= 0;
    totalSupply_ = totalSupply_.add(_value);
  }
  
  function sendToInvestor(address _to, uint256 _value) public onlyOwner {
    transfer(_to, _value);
  }
  
  function lockedBalanceOf(address _owner) public view returns (uint256) {
    return lockedBalances[_owner];
  }
  
  function lockTokens(address _beneficiary, uint _value) public onlyOwner {
    require(_value <= balances[_beneficiary]);
    require(_beneficiary != address(0));

    balances[_beneficiary] = balances[_beneficiary].sub(_value);
    lockedBalances[_beneficiary] = lockedBalances[_beneficiary].add(_value);
    emit TokensLocked(_beneficiary, _value);
  }
  
  function unlockTokens(address _beneficiary, uint _value) public onlyOwner {
    require(_value <= lockedBalances[_beneficiary]);
    require(_beneficiary != address(0));

    lockedBalances[_beneficiary] = lockedBalances[_beneficiary].sub(_value);
    balances[_beneficiary] = balances[_beneficiary].add(_value);
    emit TokensUnlocked(_beneficiary, _value);
  }
  
  function () external payable {
    require(owner.send(msg.value));
  }
  
}