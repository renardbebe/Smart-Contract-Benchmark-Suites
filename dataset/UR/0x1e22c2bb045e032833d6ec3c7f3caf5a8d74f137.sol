 

pragma solidity ^0.5.10;

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
    require(b != 0);
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

contract GMAM is IERC20, Owned {
    using SafeMath for uint256;
    
     
    constructor() public {
        owner = 0xb636a5A167b603d4f75E485E4657e1dD5C2372aa;
        _balances[0xb636a5A167b603d4f75E485E4657e1dD5C2372aa] = supply;
        emit Transfer(address(0), 0xb636a5A167b603d4f75E485E4657e1dD5C2372aa, supply);
    }
    
     
    string public constant name = "Growmore Token";
    string public constant symbol = "GMAM";
    uint256 public constant decimals = 5;
    uint256 public supply = 1000000000 * 10 ** decimals;
    
     
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
        require(_balances[msg.sender] >= value);
        require(to != address(this) || to != address(0));
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from));
        require(value <= allowance(from, to));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][to] = _allowed[from][to].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        supply = supply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _balances[to] = _balances[to].add(amount);
        supply = supply.add(amount);
        emit Transfer(address(0), to, amount);
    }
}