 

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
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}


interface IJoySale  {
    function getEndDate() external view returns (uint256);
}


contract JoyToken is ERC20, Ownable {
   
    string public symbol;
    string public  name;
    uint256 public decimals;

    uint256 private _cap;

    address public saleAddress;
    IJoySale public sale;

    bool public unlocked = false;

    bool public sendedToSale;
    bool public sendedToTeam;
    bool public sendedToTeamLock;
    bool public sendedToAdvisors;
    bool public sendedToAdvisorsLock;
    bool public sendedToService;

    uint256 public salePart;
    uint256 public teamPart;
    uint256 public teamPartLock;
    uint256 public advisorsPart;
    uint256 public advisorsPartLock;
    uint256 public servicePart;

    uint256 constant LOCK_TIME = 365 days;
    

    modifier whenUnlocked()  {
        if (msg.sender != saleAddress) {
            require(unlocked);
        }
        _;
    }

    modifier onlySale() {
	    require(msg.sender == saleAddress);
	    _;
	}


    function cap() public view returns(uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap);
        super._mint(account, value);
    }


	function transfer(address _to, uint256 _value) public whenUnlocked() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenUnlocked() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenUnlocked() returns (bool) {
        return super.approve(_spender, _value);
	}


    constructor() public {
        symbol = "JOY";
        name = "Joy coin";
        decimals = 8;

        _cap             =  2400000000 * 10 ** decimals; 

        salePart         =  1625400000 * 10 ** decimals;  
                      
        advisorsPart     =    42000000 * 10 ** decimals;  
        advisorsPartLock =   126000000 * 10 ** decimals;  

        teamPart         =    31650000 * 10 ** decimals;   
        teamPartLock     =    94950000 * 10 ** decimals;  

        servicePart      =   480000000 * 10 ** decimals;  

        require (_cap == salePart + advisorsPart + advisorsPartLock + teamPart + teamPartLock + servicePart);
    }


    function setSaleAddress(address _address) public onlyOwner returns (bool) {
        require(saleAddress == address(0));
        require (!sendedToSale);
        saleAddress = _address;
        sale = IJoySale(saleAddress);
        return true;
	}

	function unlockTokens() public onlyOwner returns (bool)	{
		unlocked = true;
		return true;
	}

	function burnUnsold() public onlySale returns (bool) {
    	_burn(saleAddress, balanceOf(saleAddress));
        return true;
  	}

    function sendTokensToSale() public onlyOwner returns (bool) {
        require (saleAddress != address(0x0));
        require (!sendedToSale);
        sendedToSale = true;
        _mint(saleAddress, salePart);
        return true;
    }

    function sendTokensToTeamLock(address _teamAddress) public onlyOwner returns (bool) {
        require (_teamAddress != address(0x0));
        require (!sendedToTeamLock);
        require (sale.getEndDate() > 0 && now > (sale.getEndDate() + LOCK_TIME) );
        sendedToTeamLock = true;
        _mint(_teamAddress, teamPartLock);
        return true;
    }

    function sendTokensToTeam(address _teamAddress) public onlyOwner returns (bool) {
        require (_teamAddress != address(0x0));
        require (!sendedToTeam);
        require ( sale.getEndDate() > 0 && now > sale.getEndDate() );
        sendedToTeam = true;
        _mint(_teamAddress, teamPart);
        return true;
    }

    function sendTokensToAdvisors(address _advisorsAddress) public onlyOwner returns (bool) {
        require (_advisorsAddress != address(0x0));
        require (!sendedToAdvisors);
        require (sale.getEndDate() > 0 && now > sale.getEndDate());
        sendedToAdvisors = true;
        _mint(_advisorsAddress, advisorsPart);
        return true;
    }

    function sendTokensToAdvisorsLock(address _advisorsAddress) public onlyOwner returns (bool) {
        require (_advisorsAddress != address(0x0));
        require (!sendedToAdvisorsLock);
        require (sale.getEndDate() > 0 && now > (sale.getEndDate() + LOCK_TIME) );
        sendedToAdvisorsLock = true;
        _mint(_advisorsAddress, advisorsPartLock);
        return true;
    }

    function sendTokensToService(address _serviceAddress) public onlyOwner returns (bool) {
        require (_serviceAddress != address(0x0));
        require (!sendedToService);
        sendedToService = true;
        _mint(_serviceAddress, servicePart);
        return true;
    }
}