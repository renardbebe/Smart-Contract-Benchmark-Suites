 

pragma solidity ^0.4.24;


 
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



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



contract Time {
     
    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
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



 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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






contract CosquareToken is Time, StandardToken, DetailedERC20, Ownable {
    using SafeMath for uint256;

     
    struct LockedBalance {
        uint256 expires;
        uint256 value;
    }

     
    mapping(address => LockedBalance[]) public lockedBalances;

     
    address public saleWallet;
     
    address public reserveWallet;
     
    address public teamWallet;
     
    address public strategicWallet;

     
    uint256 public lockEndpoint;

     
    event LockLog(address indexed who, uint256 value, uint256 expires);

     
    constructor(address _saleWallet, address _reserveWallet, address _teamWallet, address _strategicWallet, uint256 _lockEndpoint) 
      DetailedERC20("cosquare", "CSQ", 18) public {
        require(_lockEndpoint > 0, "Invalid global lock end date.");
        lockEndpoint = _lockEndpoint;

        _configureWallet(_saleWallet, 65000000000000000000000000000);  
        saleWallet = _saleWallet;
        _configureWallet(_reserveWallet, 15000000000000000000000000000);  
        reserveWallet = _reserveWallet;
        _configureWallet(_teamWallet, 15000000000000000000000000000);  
        teamWallet = _teamWallet;
        _configureWallet(_strategicWallet, 5000000000000000000000000000);  
        strategicWallet = _strategicWallet;
    }

     
    function _configureWallet(address _wallet, uint256 _amount) private {
        require(_wallet != address(0), "Invalid wallet address.");

        totalSupply_ = totalSupply_.add(_amount);
        balances[_wallet] = _amount;
        emit Transfer(address(0), _wallet, _amount);
    }

     
    modifier notLocked(address _who, uint256 _value) {
        uint256 time = _currentTime();

        if (lockEndpoint > time) {
            uint256 index = 0;
            uint256 locked = 0;
            while (index < lockedBalances[_who].length) {
                if (lockedBalances[_who][index].expires > time) {
                    locked = locked.add(lockedBalances[_who][index].value);
                }

                index++;
            }

            require(_value <= balances[_who].sub(locked), "Not enough unlocked tokens");
        }        
        _;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public notLocked(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public notLocked(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function lockedBalanceOf(address _owner, uint256 _expires) external view returns (uint256) {
        uint256 time = _currentTime();
        uint256 index = 0;
        uint256 locked = 0;

        if (lockEndpoint > time) {       
            while (index < lockedBalances[_owner].length) {
                if (_expires > 0) {
                    if (lockedBalances[_owner][index].expires == _expires) {
                        locked = locked.add(lockedBalances[_owner][index].value);
                    }
                } else {
                    if (lockedBalances[_owner][index].expires >= time) {
                        locked = locked.add(lockedBalances[_owner][index].value);
                    }
                }

                index++;
            }
        }

        return locked;
    }

     
    function lock(address _who, uint256 _value, uint256 _expires) public onlyOwner {
        uint256 time = _currentTime();
        require(_who != address(0) && _value <= balances[_who] && _expires > time, "Invalid lock configuration.");

        uint256 index = 0;
        bool exist = false;
        while (index < lockedBalances[_who].length) {
            if (lockedBalances[_who][index].expires == _expires) {
                exist = true;
                break;
            }

            index++;
        }

        if (exist) {
            lockedBalances[_who][index].value = lockedBalances[_who][index].value.add(_value);
        } else {
            lockedBalances[_who].push(LockedBalance({
                expires: _expires,
                value: _value
            }));
        }

        emit LockLog(_who, _value, _expires);
    }
}