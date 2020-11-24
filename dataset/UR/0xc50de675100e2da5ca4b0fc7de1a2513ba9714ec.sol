 

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


 
contract Controller {
    
    address private _owner;
    bool private _paused;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    
    mapping(address => bool) private owners;
    
     
    constructor() internal {
        setOwner(msg.sender);
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function setOwner(address addr) internal returns(bool) {
        if (!owners[addr]) {
          owners[addr] = true;
          _owner = addr;
          return true; 
        }
    }

        
    function changeOwner(address newOwner) onlyOwner public returns(bool) {
        require (!owners[newOwner]);
          owners[newOwner];
          _owner = newOwner;
          emit OwnershipTransferred(_owner, newOwner);
          return; 
        }

     
    function Owner() public view returns (address) {
        return _owner;
    }
    
     
    function paused() public view returns(bool) {
    return _paused;
    }
    
     
    modifier whenNotPaused() {
    require(!_paused);
    _;
    }
    
     
    modifier whenPaused() {
    require(_paused);
    _;
    }
    
     
    function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
    }
    
     
    function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
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

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
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
    _transfer(msg.sender, to, value);
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
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value); 
  }
}


contract LobefyToken is ERC20, Controller {
    
    using SafeMath for uint256;
    
    string private _name = "Lobefy Token";
    string private _symbol = "CRWD";
    uint8 private _decimals = 18;
    
    address private team1 = 0xDA19316953D19f5f8C6361d68C6D0078c06285d3;
    address private team2 = 0x928bdD2F7b286Ff300b054ac0897464Ffe5455b2;
    address private team3 = 0x327d33e81988425B380B7f91C317961e3797Eedf;
    address private team4 = 0x4d76022f6df7D007119FDffc310984b1F1E30660;
    address private team5 = 0xA8534e7645003708B10316Dd5B6166b90649F4da;
    address private team6 = 0xfF3005C63FD5633c3bd5D3D4f34b0491D0a564E5;
    address private team7 = 0xb3FCDed4A67E56621F06dB5ff72bf8D93afeCb12;
    address private reserve = 0x6Fc693855Ef50fDf378Add1bf487dB12772F4c8f;
    
    uint256 private team1Balance = 50 * (10 ** 6) * (10 ** 18);
    uint256 private team2Balance = 50 * (10 ** 6) * (10 ** 18);
    uint256 private team3Balance = 25 * (10 ** 6) * (10 ** 18);
    uint256 private team4Balance = 15 * (10 ** 6) * (10 ** 18);
    uint256 private team5Balance = 25 * (10 ** 6) * (10 ** 18);
    uint256 private team6Balance = 25 * (10 ** 6) * (10 ** 18);
    uint256 private team7Balance = 25 * (10 ** 6) * (10 ** 18);
    uint256 private reserveBalance = 35 * (10 ** 6) * (10 ** 18);
    
    
    constructor() public {
        mint(team1,team1Balance);
        mint(team2,team2Balance);
        mint(team3,team3Balance);
        mint(team4,team4Balance);
        mint(team5,team5Balance);
        mint(team6,team6Balance);
        mint(team7,team7Balance);
        mint(reserve,reserveBalance);
    }

     
    function name() public view returns(string) {
        return _name;
    }

     
    function symbol() public view returns(string) {
        return _symbol;
    }

     
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }

     
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance( address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance( address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
    
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
}