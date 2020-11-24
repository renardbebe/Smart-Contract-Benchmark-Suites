 

pragma solidity ^0.5.11;

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
    require(b != 0, 'Cannot divide by zero');
    return a % b;
  }
}

contract Owned {
    address public owner;
    address public newOwner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

contract Token is IERC20, Owned {
    using SafeMath for uint256;

     
    constructor() public {
        owner = 0x08d19746Ee0c0833FC5EAF98181eB91DAEEb9abB;
        _balances[owner] = 10000000000000000000;
        emit Transfer(address(0), owner, 10000000000000000000);
    }

     
    string public constant name = "i Trade";
    string public constant symbol = "iTR";
    uint256 public constant decimals = 5;
    uint256 public supply = 10000000000000000000;

     
    event Burn(address from, uint256 amount);
    event Mint(address to, uint256 amount);

     
    mapping(address => uint256) _balances;

     
    mapping(address => mapping (address => uint256)) public _allowed;

     
    function totalSupply() public view returns (uint) {
        return supply;
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }

     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

     
    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value, 'Sender does not have suffencient balance');
        require(to != address(this) || to != address(0), 'Cannot send to yourself or 0x0');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        if (to == address(0)) {
            supply = supply.sub(value);
            emit Burn(msg.sender, value);
        } else {
            _balances[to] = _balances[to].add(value);
        }
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from), "Token Holder does not have enough balance");
        require(value <= allowance(from, msg.sender), "Transfer not approved by token holder");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 amount) public onlyOwner {
        require(_balances[msg.sender] >= amount, "Not enough balance");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        supply = supply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }
}