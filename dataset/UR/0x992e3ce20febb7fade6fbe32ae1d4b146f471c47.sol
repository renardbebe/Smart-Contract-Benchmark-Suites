 

pragma solidity 0.4.23;

 
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

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 
contract RBACWithAdmin is RBAC {
   
  string public constant ROLE_ADMIN = "admin";

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

 
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract ERC865 {

    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);

    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool);
}

 

contract ERC865Token is ERC865, StandardToken, Ownable {

     
    mapping(bytes => bool) signatures;
     
    mapping (address => uint256) nonces;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    bytes4 internal constant transferSig = 0x48664c16;
    bytes4 internal constant approvalSig = 0xf7ac9c2e;
    bytes4 internal constant increaseApprovalSig = 0xa45f71ff;
    bytes4 internal constant decreaseApprovalSig = 0x59388d78;

     
    function getNonce(address _owner) public view returns (uint256 nonce){
      return nonces[_owner];
    }


     
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _to, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

     
    function approvePreSigned(
        bytes _signature,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), approvalSig, _spender, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(_value.add(_fee) <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] =_value;
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }

     
    function increaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), increaseApprovalSig, _spender, _addedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
        require(allowed[from][_spender].add(_addedValue).add(_fee) <= balances[from]);
         

        nonces[from] = _nonce;
        signatures[_signature] = true;
        allowed[from][_spender] = allowed[from][_spender].add(_addedValue);
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, allowed[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
    function decreaseApprovalPreSigned(
        bytes _signature,
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
        require(_spender != address(0));
        require(signatures[_signature] == false);

        bytes32 hashedTx = recoverPreSignedHash(address(this), decreaseApprovalSig, _spender, _subtractedValue, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(from != address(0));
        require(_nonce == nonces[from].add(1));
         
         
         
        require(_fee <= balances[from]);

        nonces[from] = _nonce;
        signatures[_signature] = true;
        uint oldValue = allowed[from][_spender];
        if (_subtractedValue > oldValue) {
            allowed[from][_spender] = 0;
        } else {
            allowed[from][_spender] = oldValue.sub(_subtractedValue);
        }
        balances[from] = balances[from].sub(_fee);
        balances[msg.sender] = balances[msg.sender].add(_fee);

        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowed[from][_spender], _fee);
        return true;
    }

     
     

          
    function recoverPreSignedHash(
        address _token,
        bytes4 _functionSig,
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
        )
      public pure returns (bytes32)
      {
        return keccak256(_token, _functionSig, _spender, _value, _fee, _nonce);
    }

     
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

       
      if (sig.length != 65) {
        return (address(0));
      }

       
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

       
      if (v < 27) {
        v += 27;
      }

       
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }

}

contract BeepToken is ERC865Token, RBAC{

    string public constant name = "Beepnow Token";
    string public constant symbol = "BPN";
    uint8 public constant decimals = 0;
    
     
    mapping (address => bool) transfersBlacklist;
    string constant ROLE_ADMIN = "admin";
    string constant ROLE_DELEGATE = "delegate";

    bytes4 internal constant transferSig = 0x48664c16;

    event UserInsertedInBlackList(address indexed user);
    event UserRemovedFromBlackList(address indexed user);
    event TransferWhitelistOnly(bool flag);
    event DelegatedEscrow(address indexed guest, address indexed beeper, uint256 total, uint256 nonce, bytes signature);
    event DelegatedRemittance(address indexed guest, address indexed beeper, uint256 value, uint256 _fee, uint256 nonce, bytes signature);

	modifier onlyAdmin() {
        require(hasRole(msg.sender, ROLE_ADMIN));
        _;
    }

    modifier onlyAdminOrDelegates() {
        require(hasRole(msg.sender, ROLE_ADMIN) || hasRole(msg.sender, ROLE_DELEGATE));
        _;
    }

     

    function onlyWhitelisted(bytes _signature, address _from, uint256 _value, uint256 _fee, uint256 _nonce) internal view returns(bool) {
        bytes32 hashedTx = recoverPreSignedHash(address(this), transferSig, _from, _value, _fee, _nonce);
        address from = recover(hashedTx, _signature);
        require(!isUserInBlackList(from));
        return true;
    }

    function addAdmin(address _addr) onlyOwner public {
        addRole(_addr, ROLE_ADMIN);
    }

    function removeAdmin(address _addr) onlyOwner public {
        removeRole(_addr, ROLE_ADMIN);
    }

    function addDelegate(address _addr) onlyAdmin public {
        addRole(_addr, ROLE_DELEGATE);
    }

    function removeDelegate(address _addr) onlyAdmin public {
        removeRole(_addr, ROLE_DELEGATE);
    }

    constructor(address _Admin, address reserve) public {
        require(_Admin != address(0));
        require(reserve != address(0));
        totalSupply_ = 17500000000;
		balances[reserve] = totalSupply_;
        emit Transfer(address(0), reserve, totalSupply_);
        addRole(_Admin, ROLE_ADMIN);
    }

     
    function isUserInBlackList(address _user) public constant returns (bool) {
        require(_user != 0x0);
        return transfersBlacklist[_user];
    }


     
    function whitelistUserForTransfers(address _user) onlyAdmin public {
        require(isUserInBlackList(_user));
        transfersBlacklist[_user] = false;
        emit UserRemovedFromBlackList(_user);
    }

     
    function blacklistUserForTransfers(address _user) onlyAdmin public {
        require(!isUserInBlackList(_user));
        transfersBlacklist[_user] = true;
        emit UserInsertedInBlackList(_user);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isUserInBlackList(msg.sender));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(!isUserInBlackList(_from));
        return super.transferFrom(_from, _to, _value);
    }

    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_to != address(0));
        onlyWhitelisted(_signature, _to, _value, _fee, _nonce);
        return super.transferPreSigned(_signature, _to, _value, _fee, _nonce);
    }

    function approvePreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.approvePreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function increaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.increaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

    function decreaseApprovalPreSigned(bytes _signature, address _spender, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdminOrDelegates public returns (bool){
        require(_spender != address(0));
        onlyWhitelisted(_signature, _spender, _value, _fee, _nonce);
        return super.decreaseApprovalPreSigned(_signature, _spender, _value, _fee, _nonce);
    }

     

     
    function delegatedSignedEscrow(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce); 
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        uint256 _total = _value.add(_fee);
        require(_total <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_total);
        balances[_admin] = balances[_admin].add(_total);

        emit Transfer(_from, _admin, _total);
        emit DelegatedEscrow(_from, _to, _total, _nonce, _signature);
        return true;
    }

     
    function delegatedSignedRemittance(bytes _signature, address _from, address _to, address _admin, uint256 _value, uint256 _fee, uint256 _nonce) onlyAdmin public returns (bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_admin != address(0));
        onlyWhitelisted(_signature, _from, _value, _fee, _nonce);
        require(hasRole(_admin, ROLE_ADMIN));
        require(_nonce == nonces[_from].add(1));
        require(signatures[_signature] == false);
        require(_value.add(_fee) <= balances[_from]);

        nonces[_from] = _nonce;
        signatures[_signature] = true;
        balances[_from] = balances[_from].sub(_value).sub(_fee);
        balances[_admin] = balances[_admin].add(_fee);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _admin, _fee);
        emit DelegatedRemittance(_from, _to, _value, _fee, _nonce, _signature);
        return true;
    }
    
}