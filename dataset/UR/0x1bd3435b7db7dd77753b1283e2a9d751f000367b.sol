 

pragma solidity 0.4.24;
  
 
 
 
 
 
 
 
 
 
 
 


 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
   constructor() public {
      owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

   
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr) internal {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr) internal {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr) view internal {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr) view internal returns (bool) {
    return role.bearer[addr];
  }
}

 
contract RBAC is Ownable {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_CEO = "ceo";
  string public constant ROLE_COO = "coo"; 
  string public constant ROLE_CRO = "cro"; 
  string public constant ROLE_MANAGER = "manager"; 
  string public constant ROLE_REVIEWER = "reviewer"; 
  
   
  constructor() public{
    addRole(msg.sender, ROLE_CEO);
  }
  
   
  function checkRole(address addr, string roleName) view internal {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName) view public returns (bool) {
    return roles[roleName].has(addr);
  }

  function ownerAddCeo(address addr) onlyOwner public {
    addRole(addr, ROLE_CEO);
  }
  
  function ownerRemoveCeo(address addr) onlyOwner public{
    removeRole(addr, ROLE_CEO);
  }

  function ceoAddCoo(address addr) onlyCEO public {
    addRole(addr, ROLE_COO);
  }
  
  function ceoRemoveCoo(address addr) onlyCEO public{
    removeRole(addr, ROLE_COO);
  }
  
  function cooAddManager(address addr) onlyCOO public {
    addRole(addr, ROLE_MANAGER);
  }
  
  function cooRemoveManager(address addr) onlyCOO public {
    removeRole(addr, ROLE_MANAGER);
  }
  
  function cooAddReviewer(address addr) onlyCOO public {
    addRole(addr, ROLE_REVIEWER);
  }
  
  function cooRemoveReviewer(address addr) onlyCOO public {
    removeRole(addr, ROLE_REVIEWER);
  }
  
  function cooAddCro(address addr) onlyCOO public {
    addRole(addr, ROLE_CRO);
  }
  
  function cooRemoveCro(address addr) onlyCOO public {
    removeRole(addr, ROLE_CRO);
  }

   
  function addRole(address addr, string roleName) internal {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName) internal {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }


   
  modifier onlyCEO() {
    checkRole(msg.sender, ROLE_CEO);
    _;
  }

   
  modifier onlyCOO() {
    checkRole(msg.sender, ROLE_COO);
    _;
  }
  
   
  modifier onlyCRO() {
    checkRole(msg.sender, ROLE_CRO);
    _;
  }
  
   
  modifier onlyMANAGER() {
    checkRole(msg.sender, ROLE_MANAGER);
    _;
  }
  
   
  modifier onlyREVIEWER() {
    checkRole(msg.sender, ROLE_REVIEWER);
    _;
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract BasicToken is ERC20Basic, RBAC {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  uint256 public basisPointsRate; 
  uint256 public maximumFee; 
  address public assetOwner; 

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
        fee = maximumFee;
    }
    uint256 sendAmount = _value.sub(fee);
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
        balances[assetOwner] = balances[assetOwner].add(fee);
        emit Transfer(msg.sender, assetOwner, fee);
    }
    
    emit Transfer(msg.sender, _to, sendAmount);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken  {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
    uint256 sendAmount = _value.sub(fee);
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (fee > 0) {
            balances[assetOwner] = balances[assetOwner].add(fee);
            emit Transfer(_from, assetOwner, fee);
        }
    emit Transfer(_from, _to, sendAmount);
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
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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




 
contract Pausable is RBAC {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyCEO whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyCEO whenPaused public {
    paused = false;
    emit Unpause();
  }
}



 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract BlackListToken is PausableToken  {

  
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyCRO {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyCRO {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyCEO {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply_ = totalSupply_.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}





 
contract TwoPhaseToken is BlackListToken{
    
     
    struct MethodParam {
        string method;  
        uint value;   
        bool state;   
    }
    
    mapping (string => MethodParam) params;
    
     
    string public constant ISSUE_METHOD = "issue";
    string public constant REDEEM_METHOD = "redeem";
    
    
     
    function submitIssue(uint _value) public onlyMANAGER {
        params[ISSUE_METHOD] = MethodParam(ISSUE_METHOD, _value, true);
        emit SubmitIsses(msg.sender,_value);
    }
    
     
    function comfirmIsses(uint _value) public onlyREVIEWER {
       
        require(params[ISSUE_METHOD].value == _value);
        require(params[ISSUE_METHOD].state == true);
        
        balances[assetOwner]=balances[assetOwner].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        params[ISSUE_METHOD].state=false; 
        emit ComfirmIsses(msg.sender,_value);
    }
    
     
    function submitRedeem(uint _value) public onlyMANAGER {
        params[REDEEM_METHOD] = MethodParam(REDEEM_METHOD, _value, true);
         emit SubmitRedeem(msg.sender,_value);
    }
    
     
    function comfirmRedeem(uint _value) public onlyREVIEWER {
       
       require(params[REDEEM_METHOD].value == _value);
       require(params[REDEEM_METHOD].state == true);
       
       balances[assetOwner]=balances[assetOwner].sub(_value);
       totalSupply_ = totalSupply_.sub(_value);
       params[REDEEM_METHOD].state=false;
       emit ComfirmIsses(msg.sender,_value);
    }
    
     
    function getMethodValue(string _method) public view returns(uint){
        return params[_method].value;
    }
    
     
    function getMethodState(string _method) public view returns(bool) {
      return params[_method].state;
    }
   
     event SubmitRedeem(address submit, uint _value);
     event ComfirmRedeem(address comfirm, uint _value);
     event SubmitIsses(address submit, uint _value);
     event ComfirmIsses(address comfirm, uint _value);

    
}



contract UpgradedStandardToken {
     
    function totalSupplyByLegacy() public view returns (uint256);
    function balanceOfByLegacy(address who) public view returns (uint256);
    function transferByLegacy(address origSender, address to, uint256 value) public returns (bool);
    function allowanceByLegacy(address owner, address spender) public view returns (uint256);
    function transferFromByLegacy(address origSender, address from, address to, uint256 value) public returns (bool);
    function approveByLegacy(address origSender, address spender, uint256 value) public returns (bool);
    function increaseApprovalByLegacy(address origSender, address spender, uint addedValue) public returns (bool);
    function decreaseApprovalByLegacy(address origSende, address spender, uint subtractedValue) public returns (bool);
}




contract WitToken is TwoPhaseToken {
    string  public  constant name = "Wealth in Tokens";
    string  public  constant symbol = "WIT";
    uint8   public  constant decimals = 18;
    address public upgradedAddress;
    bool public deprecated;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    constructor ( uint _totalTokenAmount ) public {
        basisPointsRate = 0;
        maximumFee = 0;
        totalSupply_ = _totalTokenAmount;
        balances[msg.sender] = _totalTokenAmount;
        deprecated = false;
        assetOwner = msg.sender;
        emit Transfer(address(0x0), msg.sender, _totalTokenAmount);
    }
    
    
    
      
     function totalSupply() public view returns (uint256) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).totalSupplyByLegacy();
        } else {
            return totalSupply_;
        }
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOfByLegacy( _owner);
        } else {
           return super.balanceOf(_owner);
        }
    }

    
     
    function transfer(address _to, uint _value) public validDestination(_to) returns (bool) {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
        
    }


     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).allowanceByLegacy(_owner, _spender);
        } else {
           return super.allowance(_owner, _spender);
        }
        
    }


     
    function transferFrom(address _from, address _to, uint _value) public validDestination(_to) returns (bool) {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
       
    }
    
    
      
     function approve(address _spender, uint256 _value) public returns (bool) {
          if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        } 
    }
    
    
     
    function increaseApproval(address _spender, uint _value) public returns (bool) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(msg.sender, _spender, _value);
        } else {
            return super.increaseApproval(_spender, _value);
        } 
    }


     
    function decreaseApproval(address _spender, uint _value) public returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(msg.sender, _spender, _value);
        } else {
            return super.decreaseApproval(_spender, _value);
        } 
   }
   
   
     
    function deprecate(address _upgradedAddress) public onlyCEO whenPaused {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
    
     
    event Deprecate(address newAddress);
    
    
    
    function setFeeParams(uint newBasisPoints, uint newMaxFee) public onlyCEO {
       
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint(10)**decimals);
        emit FeeParams(basisPointsRate, maximumFee);
    }
    

    function transferAssetOwner(address newAssetOwner) public onlyCEO {
      require(newAssetOwner != address(0));
      assetOwner = newAssetOwner;
      emit TransferAssetOwner(assetOwner, newAssetOwner);
    }
    
    event TransferAssetOwner(address assetOwner, address newAssetOwner);
    
      
    event FeeParams(uint feeBasisPoints, uint maxFee);
    
    
    

}