 

pragma solidity >=0.5.0 <0.7.0;

 

 
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

 
contract Ownable {
  address private _owner;

   
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "Ownable: Caller is not the owner");
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: New owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
interface IERC20 {

  function balanceOf(address account) external view returns (uint256);
 
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function allowance(address owner, address spender)
    external view returns (uint256);

   
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

  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 public totalSupply;
  
  constructor(uint256 initialSupply) internal {
    require(msg.sender != address(0));
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    emit Transfer(address(0), msg.sender, initialSupply);
  }

   
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function allowance(
    address owner,
    address spender
   )
    external
    view
    returns (uint256)
  {
    return allowed[owner][spender];
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    allowed[msg.sender][spender] = (
      allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
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

    allowed[msg.sender][spender] = (
      allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }
}

 
contract Burnable is ERC20 {

   
  event Burn(
    address indexed from,
    uint256 value
  );
  
   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    require(value <= allowed[from][msg.sender], "Burnable: Amount to be burnt exceeds the account balance");

     
     
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    _burn(from, value);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "Burnable: Burn from the zero address");
    require(amount > 0, "Burnable: Can not burn negative amount");
    require(amount <= balances[account], "Burnable: Amount to be burnt exceeds the account balance");

    totalSupply = totalSupply.sub(amount);
    balances[account] = balances[account].sub(amount);
    emit Burn(account, amount);
  }
}

 
contract Freezable is ERC20 {

  mapping (address => uint256) private _freeze;

   
  event Freeze(
    address indexed from,
    uint256 value
  );

   
  event Unfreeze(
    address indexed from,
    uint256 value
  );

   
  function freezeOf(address account) public view returns (uint256) {
    return _freeze[account];
  }

   
  function freeze(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Freezable: Amount to be frozen exceeds the account balance");
    require(amount > 0, "Freezable: Can not freeze negative amount");
    balances[msg.sender] = balances[msg.sender].sub(amount);
    _freeze[msg.sender] = _freeze[msg.sender].add(amount);
    emit Freeze(msg.sender, amount);
  }

   
  function unfreeze(uint256 amount) public {
    require(_freeze[msg.sender] >= amount, "Freezable: Amount to be unfrozen exceeds the account balance");
    require(amount > 0, "Freezable: Can not unfreeze negative amount");
    _freeze[msg.sender] = _freeze[msg.sender].sub(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    emit Unfreeze(msg.sender, amount);
  }
}

 
contract MinosCoin is ERC20, Burnable, Freezable, Ownable {

  string public constant name = "MinosCoin";
  string public constant symbol = "MNS";
  uint8 public constant decimals = 18;

   
  uint256 private constant _initialSupply = 300000000 * (10 ** uint256(decimals));

   
  constructor() 
    public 
    ERC20(_initialSupply)
  {
    require(msg.sender != address(0), "MinosCoin: Create contract from the zero address");
  }
  
   
  function withdrawEther() public onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "MinosCoin: No ether available to be withdrawn");
    msg.sender.transfer(totalBalance);
  }
}