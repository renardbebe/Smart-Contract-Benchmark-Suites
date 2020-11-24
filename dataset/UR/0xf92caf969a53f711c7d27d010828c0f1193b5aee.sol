 

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

contract Owned {
  constructor() public { owner = msg.sender; }

  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

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

  mapping (address => mapping (address => uint256)) internal _allowances;

  uint256 internal _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }


   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

   
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

   
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _approve(address owner, address spender, uint256 value) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
  }
}


contract Wisdom is ERC20, Owned {

  string public constant name = "Wisdom";
  string public constant symbol = "WISDOM";
  uint8 public constant decimals = 2;

  mapping(address => bool) _admins;
  mapping(address => bool) _locked;

   
  function addAdmin(address somebody) public onlyOwner {
    _admins[somebody] = true;
  }

   
  function removeAdmin(address somebody) public onlyOwner {
    _admins[somebody] = false;
  }

   
  function isAdmin(address somebody) public view returns(bool) {
    return _admins[somebody] || somebody == owner;
  }

   
  function lock(address account) public {
    require(isAdmin(msg.sender));
    _locked[account] = true;
  }

   
  function unlock(address account) public {
    require(isAdmin(msg.sender));
    _locked[account] = false;
  }

   
  function isLocked(address somebody) public view returns(bool) {
    return _locked[somebody];
  }

   
  function mint(address account, uint256 amount) public {
    require(isAdmin(msg.sender));
    _mint(account, amount);
  }

   
  function burn(uint256 amount) public {
    require(!_locked[msg.sender]);
    _burn(msg.sender, amount);
  }

   
  function burnFrom(address account, uint256 amount) public {
    require(!_locked[msg.sender]);
    require(!_locked[account]);
    _burnFrom(account, amount);
  }

   
  function transfer(address recipient, uint256 amount) public returns (bool) {
    require(!_locked[msg.sender]);
    _transfer(msg.sender, recipient, amount);
    return true;
  }

   
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(!_locked[msg.sender]);
    require(!_locked[sender]);
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
    return true;
  }
}