 

pragma solidity ^0.5.4;

contract Ownable {
    
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = 0x54cC607cEB124F161DdC8BEC63F83b0022F6fbDf;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





 
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





contract ERC20_Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);   
}




contract SVS is ERC20_Interface, Ownable {
    
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    
    constructor() public {
        _totalSupply = 1000000000e18; 
        _decimals = 18;
        _name = "Salvus";
        _symbol = "SVS";
        
        _balances[_owner] = 50000000e18;
        emit Transfer(address(this), _owner, 50000000e18);
        
        _balances[0xa8336A32749BeEc90B96472f1aa3a6eD407faE46] = 700000000e18;
        emit Transfer(address(this), 0xa8336A32749BeEc90B96472f1aa3a6eD407faE46, 700000000e18);
        
        _balances[0x575690EF2dcA0fD5c391a5F02280688Bd98717db] = 250000000e18;
        emit Transfer(address(this), 0x575690EF2dcA0fD5c391a5F02280688Bd98717db, 250000000e18);
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    

    function decimals() public view returns(uint8) {
        return _decimals;
    }
    

    function name() public view returns(string memory) {
        return _name;
    }
    
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }


    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}