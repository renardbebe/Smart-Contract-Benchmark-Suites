 

pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}





 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
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










 
contract Operable is Ownable, RBAC {
     
    string public constant ROLE_OPERATOR = "operator";

     
    modifier hasOperatePermission() {
        require(hasRole(msg.sender, ROLE_OPERATOR));
        _;
    }

     
    modifier hasOwnerOrOperatePermission() {
        require(msg.sender == owner || hasRole(msg.sender, ROLE_OPERATOR));
        _;
    }

     
    function operator(address _operator) public view returns (bool) {
        return hasRole(_operator, ROLE_OPERATOR);
    }

     
    function addOperator(address _operator) onlyOwner public {
        addRole(_operator, ROLE_OPERATOR);
    }

     
    function removeOperator(address _operator) onlyOwner public {
        removeRole(_operator, ROLE_OPERATOR);
    }
}





 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract FlipNpikAirdrop is Operable {
     
    ERC20 public token;

     
    constructor (ERC20 _token, address _owner) public {
        require(_token != address(0), "Token address is invalid.");
        token = _token;

        require(_owner != address(0), "Owner address is invalid.");
        owner = _owner;
    }
    
     
    function distribute(address[] _wallets, uint256[] _values) external hasOwnerOrOperatePermission returns(bool) {
        require(_wallets.length == _values.length, "Lists are of different length.");
        for (uint256 j = 0; j < _wallets.length; ++j) {
            token.transferFrom(msg.sender, _wallets[j], _values[j]);
        }
        return true;
    }
}