 

pragma solidity ^0.4.24;
 
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
    address public owner;
     
      constructor() public {
     owner = msg.sender;
  }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
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
contract ERC20 is IERC20,Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  
   
  
  mapping (address => bool)  private _frozenAccount;
  
   
  event FrozenFunds(address target, bool frozen);
  
   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  
   
  function isAccountFreezed(address _address) public view returns (bool) {
    return _frozenAccount[_address];
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
    require(!_frozenAccount[msg.sender]);   
    require(!_frozenAccount[to]);   
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
     require(!_frozenAccount[from]);   
    require(!_frozenAccount[to]);   
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }
 
   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  
   
   
  function _freezeAccount(address target, bool freeze) internal {
    _frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
    }
  
}
contract BitsrentToken is ERC20{
    string public constant name = "Bitsrent";
    string public constant symbol = "BTR";
    uint8 public constant decimals = 18;
     
    uint256 public constant INITIAL_SUPPLY=20000000000*(10 ** uint256(decimals));
    
 
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
    
  function burnToken( uint256 amount)  public {
      _burn(msg.sender,amount);
  }
  
    
  function freeze(address freezingAddress,bool decision)  onlyOwner public {
      _freezeAccount(freezingAddress,decision);
  }
  
}