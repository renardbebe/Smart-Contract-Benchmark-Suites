 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract OwnClaimRenounceable is Claimable {

    function renounceOwnershipForever(uint8 _confirm)
        public
        onlyOwner
    {
        require(_confirm == 73);  
        owner = address(0);
        pendingOwner = address(0);
    }

}

 

 
contract TokenController {
    bytes4 public constant INTERFACE = bytes4(keccak256("TokenController"));

    function allowTransfer(address _sender, address _from, address _to, uint256 _value, bytes _purpose) public returns (bool);
}


 

contract YesController is TokenController {
    function allowTransfer(address  , address  , address  , uint256  , bytes  )
        public returns (bool)
    {
        return true;  
    }
}


contract NoController is TokenController {
    function allowTransfer(address  , address  , address  , uint256  , bytes  )
        public returns (bool)
    {
        return false;  
    }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract Controlled is OwnClaimRenounceable {

    bytes4 public constant TOKEN_CONTROLLER_INTERFACE = bytes4(keccak256("TokenController"));
    TokenController public controller;

    function Controlled() public {}

     
     
    modifier onlyControllerOrOwner {
        require((msg.sender == address(controller)) || (msg.sender == owner));
        _;
    }

     
     
    function changeController(TokenController _newController)
        public onlyControllerOrOwner
    {
        if(address(_newController) != address(0)) {
             
            require(_newController.INTERFACE() == TOKEN_CONTROLLER_INTERFACE);
        }
        controller = _newController;
    }

}


contract ControlledToken is StandardToken, Controlled {

    modifier controllerCallback(address _from, address _to, uint256 _value, bytes _purpose) {
         
        if(address(controller) != address(0)) {
            bool _allow = controller.allowTransfer(msg.sender, _from, _to, _value, _purpose);
            if(!_allow) {
                return;  
            }
        }
        _;  
    }

     
    function transfer(address _to, uint256 _value)
        public
        controllerCallback(msg.sender, _to, _value, hex"")
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        controllerCallback(_from, _to, _value, hex"")
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferWithPurpose(address _to, uint256 _value, bytes _purpose)
        public
        controllerCallback(msg.sender, _to, _value, _purpose)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

}


contract BatchToken is ControlledToken {

     
    function transferBatchIdempotent(address[] _toArray, uint256[] _amountArray, bool _expectZero)
         
        public
    {
         
        uint256 _count = _toArray.length;
        require(_amountArray.length == _count);

        for (uint256 i = 0; i < _count; i++) {
            address _to = _toArray[i];
             
            if(!_expectZero || (balanceOf(_to) == 0)) {
                transfer(_to, _amountArray[i]);
            }
        }
    }

}


 
contract SapienToken is BatchToken {

    string public constant name = "Sapien Network";
    string public constant symbol = "SPN";
    uint256 public constant decimals = 6;
    string public constant website = "https://sapien.network";

     
    uint256 public constant MAX_SUPPLY_USPN = 500 * 1000 * 1000 * (10**decimals);

    function SapienToken() public {
         
        balances[msg.sender] = MAX_SUPPLY_USPN;
        totalSupply_ = MAX_SUPPLY_USPN;
    }

}