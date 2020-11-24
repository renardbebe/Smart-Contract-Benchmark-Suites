 

pragma solidity 0.4.24;

 
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Role is StandardToken {
    using SafeMath for uint256;

    address public owner;
    address public admin;

    uint256 public contractDeployed = now;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

	   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   

     
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

     
    function transferOwnership(address _newOwner) external  onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function transferAdminship(address _newAdmin) external onlyAdmin {
        _transferAdminship(_newAdmin);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        balances[owner] = balances[owner].sub(balances[owner]);
        balances[_newOwner] = balances[_newOwner].add(balances[owner]);
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

     
    function _transferAdminship(address _newAdmin) internal {
        require(_newAdmin != address(0));
        emit AdminshipTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }
}

 
contract Pausable is Role {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

   
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

   
  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }
  
   
    function notPausable() onlyOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }
}

contract SamToken is Pausable {
  using SafeMath for uint;
 
    uint256 _lockedTokens;
    bool isLocked = true ;
    bool releasedForOwner ;
    uint256 public ownerPercent = 10;
    uint256 public ownerSupply;
    uint256 public adminPercent = 90;
    uint256 public adminSupply ;
    
      
    string public constant name = "SAM Token";
     
    string public constant symbol = "SAM";
     
    uint public constant decimals = 0;

  event Burn(address indexed burner, uint256 value);
  event CompanyTokenReleased( address indexed _company, uint256 indexed _tokens );

  constructor(
        address _owner, 
        address _admin,        
        uint256 _totalsupply
        ) public {
    owner = _owner;
    admin = _admin;

    _totalsupply = _totalsupply ;
    totalSupply_ = totalSupply_.add(_totalsupply);
       
    adminSupply = 900000000 ;  
    ownerSupply = 100000000 ;

    _lockedTokens = _lockedTokens.add(ownerSupply);
    balances[admin] = balances[admin].add(adminSupply);
     isLocked = true;
    emit Transfer(address(0), admin, adminSupply );
    
  }

  modifier onlyPayloadSize(uint numWords) {
    assert(msg.data.length >= numWords * 32 + 4);
    _;
  }

  
    function lockedTokens() public view returns (uint256) {
      return _lockedTokens;
    }

  
    function isContract(address _address) private view returns (bool is_contract) {
      uint256 length;
      assembly {
       
        length := extcodesize(_address)
      }
      return (length > 0);
    }

 
function burn(uint _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
}

 
function burnFrom(address from, uint _value) public returns (bool success) {
    require(balances[from] >= _value);
    require(_value <= allowed[from][msg.sender]);
    balances[from] = balances[from].sub(_value);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(from, _value);
    return true;
}

function () public payable {
    revert();
}

 
function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    require(tokenAddress != address(0));
    require(isContract(tokenAddress));
    return ERC20(tokenAddress).transfer(owner, tokens);
}

 
function companyTokensRelease(address _company) external onlyAdmin returns(bool) {
   require(_company != address(0), "Address is not valid");
   require(!releasedForOwner, "Team release has already done");
    if (now > contractDeployed.add(365 days) && releasedForOwner == false ) {          
          balances[_company] = balances[_company].add(_lockedTokens);
          isLocked = false;
          releasedForOwner = true;
          emit CompanyTokenReleased(_company, _lockedTokens);
          return true;
        }
    }

}