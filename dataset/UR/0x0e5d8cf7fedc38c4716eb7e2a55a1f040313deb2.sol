 

pragma solidity 0.4.25;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 internal _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract Cryptocoin is ERC20, Claimable {
  using SafeMath for uint256;

  string  public name;
  string  public symbol;
  uint8   public decimals;
  address public accICO;

  constructor (
      address _accICO, 
      uint256 _initialSupply)
  public 
  {
      require(_accICO         != address(0)); 
      require(_initialSupply  > 0);
      name           = "Cryptocoin";
      symbol         = "CCIN";
      decimals       = 18;
      accICO         = _accICO;
      _totalSupply   = _initialSupply * (10 ** uint256(decimals));
       
      _balances[_accICO]         = totalSupply();
      emit Transfer(address(0), _accICO, totalSupply());
  }

  
  function burn(uint256 amount) external {
    require(amount <= _balances[msg.sender]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

  function() public { }  


   
   
  function reclaimToken(ERC20 token) external onlyOwner {
      require(address(token) != address(0));
      uint256 balance = token.balanceOf(address(this));
      token.transfer(owner, balance);
      
  }

   
   
   
   
   
   
   
   
}