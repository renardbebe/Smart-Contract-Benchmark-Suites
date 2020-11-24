 

pragma solidity ^0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract MultiOwnable {
    address public superOwner;
    mapping (address => bool) owners;
    
    event ChangeSuperOwner(address indexed newSuperOwner);
    event AddOwner(address indexed newOwner);
    event DeleteOwner(address indexed toDeleteOwner);

    constructor() public {
        superOwner = msg.sender;
        owners[superOwner] = true;
    }

    modifier onlySuperOwner() {
        require(superOwner == msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function addOwner(address owner) public onlySuperOwner returns (bool) {
        require(owner != address(0));
        owners[owner] = true;
        emit AddOwner(owner);
        return true;
    }

    function deleteOwner(address owner) public onlySuperOwner returns (bool) {
        
        require(owner != address(0));
        owners[owner] = false;
        
        emit DeleteOwner(owner);
        
        return true;
    }
    function changeSuperOwner(address _superOwner) public onlySuperOwner returns(bool) {
        
        superOwner = _superOwner;
        
        emit ChangeSuperOwner(_superOwner);
        
        return true;
    }

    function chkOwner(address owner) public view returns (bool) {
        return owners[owner];
    }
}

contract HasNoEther is MultiOwnable {
    
     
    constructor() public payable {
        require(msg.value == 0);
    }
    
     
    function() external {
    }
    
     
    function reclaimEther() external onlySuperOwner returns (bool) {
        superOwner.transfer(address(this).balance);

        return true;
    }
}

contract Blacklist is MultiOwnable {
   
    mapping(address => bool) blacklisted;
    
    event TMTG_Blacklisted(address indexed blacklist);
    event TMTG_Whitelisted(address indexed whitelist);

    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }
    
     
    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }

     
    function blacklist(address node) public onlyOwner returns (bool) {
        blacklisted[node] = true;
        emit TMTG_Blacklisted(node);

        return blacklisted[node];
    }

     
    function unblacklist(address node) public onlyOwner returns (bool) {
        blacklisted[node] = false;
        emit TMTG_Whitelisted(node);

        return blacklisted[node];
    }
}

contract PausableToken is StandardToken, HasNoEther, Blacklist {
    bool public paused = true;

     
    mapping(address => bool) public unlockAddrs;

    event Pause(address addr);
    event Unpause(address addr);
    event UnlockAddress(address addr);
    event LockAddress(address addr);
    
     

    modifier checkUnlock(address addr) {
        require(!paused || unlockAddrs[addr]);
        _;
    }

    function unlockAddress (address addr) public onlyOwner returns (bool) {
        unlockAddrs[addr] = true;
        emit UnlockAddress(addr);

        return unlockAddrs[addr];
    }

    function lockAddress (address addr) public onlyOwner returns (bool) {
        unlockAddrs[addr] = false;
        emit LockAddress(addr);

        return unlockAddrs[addr];
    }

    function pause() public onlyOwner returns (bool) {
        paused = true;
        emit Pause(msg.sender);

        return paused;
    }

    function unpause() public onlyOwner returns (bool) {
        paused = false;
        emit Unpause(msg.sender);

        return paused;
    }

    function transfer(address to, uint256 value) public checkUnlock(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public checkUnlock(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

contract lbcCoin is PausableToken {
    string public constant name = "BIO";
    uint8 public constant decimals = 18;
    string public constant symbol = "BIO";
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals)); 

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function destory() onlySuperOwner public returns (bool) {
        
        selfdestruct(superOwner);

        return true;

    }
}