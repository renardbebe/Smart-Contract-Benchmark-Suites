 

pragma solidity ^0.4.23;

contract ERC20Interface {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

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

 
contract ERC677ReceiverInterface {
    function tokenFallback(address _sender, uint256 _value, bytes _extraData) 
        public returns (bool);
}

contract ERC677SenderInterface {
    function transferAndCall(address _recipient, uint256 _value, bytes _extraData) 
        public returns (bool);
}

 

contract SIDBRIAN is ERC20Interface, ERC677SenderInterface {
    
    using SafeMath for uint256;
    
    constructor()
        public
    {
        owner_ = msg.sender;
        totalSupply_ = 1000000000 * (10**18);
        activateTokens_ = 250000000 * (10**18);
        increasingStep_ = 50000000 * (10**18);
        
        balances_[owner_] = activateTokens_;
    }
    
    address public owner_;
    
    string public name = "SIDBRIAN";
    string public symbol = "SIDB";
    uint8 public decimals = 18;
    
    mapping(address => uint256) private balances_;
    mapping(address => mapping(address => uint256)) private allowed_;
    uint256 private totalSupply_;
    
    uint256 public activateTokens_;
    uint256 public increasingStep_;
    
    bool public isPaused_ = false;
    
    mapping(address => bool) activators_;
    
     
    
    modifier onlyOwner(
        address _address
    )
    {
        require(
            _address == owner_, 
            "This action not allowed because of permission."
        );
        
        _;
    }
    
    modifier onlyActivator(
        address _activator    
    )
    {
        require(
            activators_[_activator] == true, 
            "The action not allowed because of permission."
        );
        _;
    }
    
    modifier onlyUnpaused
    {
        require(
            isPaused_ == false, 
            "This action not allowed when pausing"
        );
        
        _;
    }
    
     
     
    event Pause();
    event Unpause();
    event Activation(
        address activator,
        uint256 activeTokens
    );
    event RemoveActivator(
        address activator
    );
    event AddActivator(
        address activator
    );
    
    event TransferOwnership(
        address newOwner
    );
    
     
    
    function totalSupply() 
        view
        public 
        returns 
        (uint256)
    {
        return totalSupply_;
    }
    
    function balanceOf(
        address _who
    )
        view
        public
        returns
        (uint256)
    {
        return balances_[_who];
    }
    
    function allowance(
        address _who, 
        address _spender
    )
        view
        public
        returns
        (uint256)
    {
        return allowed_[_who][_spender];
    }
    
    function transfer(
        address _to, 
        uint256 _value
    )
        public
        onlyUnpaused
        returns
        (bool)
    {
        require(balances_[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0));
        
        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        
        emit Transfer(
            msg.sender,
            _to,
            _value
        );
        
        return true;
    }
    
    function approve(
        address _spender, 
        uint256 _value
    )
        public
        returns
        (bool)
    {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(
            msg.sender,
            _spender,
            _value
        );
    }
    
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    )
        public
        onlyUnpaused
        returns
        (bool)
    {
        require(balances_[_from] >= _value, "Owner Insufficient balance");
        require(allowed_[_from][msg.sender] >= _value, "Spender Insufficient balance");
        require(_to != address(0), "Don't burn the coin.");
        
        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        
        emit Transfer(
            _from,
            _to,
            _value
        );
    }
    
    function increaseApproval(
        address _spender,
        uint256 _addValue
    )
        public
        returns
        (bool)
    {
        allowed_[msg.sender][_spender] = 
            allowed_[msg.sender][_spender].add(_addValue);
        
        emit Approval(
            msg.sender,
            _spender,
            allowed_[msg.sender][_spender]
        );
    }
    
    function decreaseApproval(
        address _spender,
        uint256 _substractValue
    )
        public
        returns
        (bool)
    {
        uint256 _oldValue = allowed_[msg.sender][_spender];
        if(_oldValue >= _substractValue) {
            allowed_[msg.sender][_spender] = _oldValue.sub(_substractValue);
        } 
        else {
            allowed_[msg.sender][_spender] = 0;    
        }
        
        emit Approval(
            msg.sender,
            _spender,
            allowed_[msg.sender][_spender]
        );
    }
    
     
    
    function isPaused()
        view
        public 
        returns
        (bool)
    {
        return isPaused_;
    }
    
     
     
    function pause()
        public
        onlyOwner(msg.sender)
    {
        isPaused_ = true;
        emit Pause();
    }
    
    function unpaused()
        public
        onlyOwner(msg.sender)
    {
        isPaused_ = false;
        
        emit Unpause();
    }
    
    function addActivator(
        address _activator
    )
        public
        onlyOwner(msg.sender)
    {
        activators_[_activator] = true;
        
        emit AddActivator(_activator);
    }
    
    function removeActivator(
        address _activator
    )
        public
        onlyOwner(msg.sender)
    {
        activators_[_activator] = false;
        
        emit RemoveActivator(_activator);
    }
    
    function transferOwnership(
        address _newOwner    
    )
        public
        onlyOwner(msg.sender)
    {
        owner_ = _newOwner;
        emit TransferOwnership(_newOwner);
    }
    
     
     
     function activateToken()
        public
        onlyActivator(msg.sender)
    {
        require(activateTokens_ <= totalSupply_, "All token have been activated.");
        uint256 _beforeValue = activateTokens_;
        activateTokens_ = _beforeValue.add(increasingStep_);
        
        emit Activation(
            msg.sender,
            activateTokens_
        );
    }
    
     
    function transferAndCall(address _recipient,
                    uint256 _value,
                    bytes _extraData)
        public
        returns
        (bool)
    {
        transfer(_recipient, _value);
        if(isContract(_recipient)) {
            require(ERC677ReceiverInterface(_recipient).tokenFallback(msg.sender, _value, _extraData));
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool) {
        uint len;
        assembly {
            len := extcodesize(_addr)
        }
        return len > 0;
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