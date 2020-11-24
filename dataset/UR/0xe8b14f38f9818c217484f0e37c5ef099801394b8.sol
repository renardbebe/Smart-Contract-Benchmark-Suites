 

 
pragma solidity 0.4.24;


 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value)
    external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
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


 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed_[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

     
     
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}


 

 
library SafeERC20 {
  function safeTransfer(
    IERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    IERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
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


 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = true;
  }

   
  function remove(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = false;
  }

   
  function check(Role storage _role, address _account)
    internal
    view
  {
    require(has(_role, _account));
  }

   
  function has(Role storage _role, address _account)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_account];
  }
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

   
  function _addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function _removeRole(address _operator, string _role)
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


 

 

library ECDSA {

   
  function recover(bytes32 _hash, bytes _signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (_signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(_hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}


 

 
contract SignatureBouncer is Ownable, RBAC {
  using ECDSA for bytes32;

   
  string private constant ROLE_BOUNCER = "bouncer";
   
   
  uint256 private constant METHOD_ID_SIZE = 4;
   
  uint256 private constant SIGNATURE_SIZE = 96;

   
  modifier onlyValidSignature(bytes _signature)
  {
    require(_isValidSignature(msg.sender, _signature));
    _;
  }

   
  modifier onlyValidSignatureAndMethod(bytes _signature)
  {
    require(_isValidSignatureAndMethod(msg.sender, _signature));
    _;
  }

   
  modifier onlyValidSignatureAndData(bytes _signature)
  {
    require(_isValidSignatureAndData(msg.sender, _signature));
    _;
  }

   
  function isBouncer(address _account) public view returns(bool) {
    return hasRole(_account, ROLE_BOUNCER);
  }

   
  function addBouncer(address _bouncer)
    public
    onlyOwner
  {
    require(_bouncer != address(0));
    _addRole(_bouncer, ROLE_BOUNCER);
  }

   
  function removeBouncer(address _bouncer)
    public
    onlyOwner
  {
    _removeRole(_bouncer, ROLE_BOUNCER);
  }

   
  function _isValidSignature(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address)),
      _signature
    );
  }

   
  function _isValidSignatureAndMethod(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    bytes memory data = new bytes(METHOD_ID_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

   
  function _isValidSignatureAndData(address _address, bytes _signature)
    internal
    view
    returns (bool)
  {
    require(msg.data.length > SIGNATURE_SIZE);
    bytes memory data = new bytes(msg.data.length - SIGNATURE_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), _address, data)),
      _signature
    );
  }

   
  function _isValidDataHash(bytes32 _hash, bytes _signature)
    internal
    view
    returns (bool)
  {
    address signer = _hash
      .toEthSignedMessageHash()
      .recover(_signature);
    return isBouncer(signer);
  }
}


 

contract EscrowedERC20Bouncer is SignatureBouncer {
  using SafeERC20 for IERC20;

  uint256 public nonce;

  modifier onlyBouncer()
  {
    require(isBouncer(msg.sender), "DOES_NOT_HAVE_BOUNCER_ROLE");
    _;
  }

  modifier validDataWithoutSender(bytes _signature)
  {
    require(_isValidSignatureAndData(address(this), _signature), "INVALID_SIGNATURE");
    _;
  }

  constructor(address _bouncer)
    public
  {
    addBouncer(_bouncer);
  }

   
  function withdraw(uint256 _nonce, IERC20 _token, address _to, uint256 _amount, bytes _signature)
    public
    validDataWithoutSender(_signature)
  {
    require(_nonce > nonce, "NONCE_GT_NONCE_REQUIRED");
    nonce = _nonce;
    _token.safeTransfer(_to, _amount);
  }

   
  function withdrawAll(IERC20 _token, address _to)
    public
    onlyBouncer
  {
    _token.safeTransfer(_to, _token.balanceOf(address(this)));
  }
}


 

 
contract ERC20Mintable is ERC20, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    _mint(_to, _amount);
    emit Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


 

contract MintableERC20Bouncer is SignatureBouncer {

  uint256 public nonce;

  modifier validDataWithoutSender(bytes _signature)
  {
    require(_isValidSignatureAndData(address(this), _signature), "INVALID_SIGNATURE");
    _;
  }

  constructor(address _bouncer)
    public
  {
    addBouncer(_bouncer);
  }

   
  function mint(uint256 _nonce, ERC20Mintable _token, address _to, uint256 _amount, bytes _signature)
    public
    validDataWithoutSender(_signature)
  {
    require(_nonce > nonce, "NONCE_GT_NONCE_REQUIRED");
    nonce = _nonce;
    _token.mint(_to, _amount);
  }
}


 

 
contract ERC20Detailed is IERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


 

 
contract ERC20TokenMetadata is IERC20 {
  function tokenURI() external view returns (string);
}


contract ERC20WithMetadata is ERC20TokenMetadata {
  string private tokenURI_ = "";

  constructor(string _tokenURI)
    public
  {
    tokenURI_ = _tokenURI;
  }

  function tokenURI() external view returns (string) {
    return tokenURI_;
  }
}


 

contract KataToken is ERC20, ERC20Detailed, ERC20Mintable, ERC20WithMetadata {
  constructor(
    string _name,
    string _symbol,
    uint8 _decimals,
    string _tokenURI
  )
    ERC20WithMetadata(_tokenURI)
    ERC20Detailed(_name, _symbol, _decimals)
    public
  {}
}


 

contract TokenAndBouncerDeployer is Ownable {
  event Deployed(address indexed token, address indexed bouncer);

  function deploy(
    string _name,
    string _symbol,
    uint8 _decimals,
    string _tokenURI,
    address _signer
  )
    public
    onlyOwner
  {
    MintableERC20Bouncer bouncer = new MintableERC20Bouncer(_signer);
    KataToken token = new KataToken(_name, _symbol, _decimals, _tokenURI);
    token.transferOwnership(address(bouncer));

    emit Deployed(address(token), address(bouncer));

    selfdestruct(msg.sender);
  }
}


 

contract MockToken is ERC20Detailed, ERC20Mintable {
  constructor(string _name, string _symbol, uint8 _decimals)
    ERC20Detailed(_name, _symbol, _decimals)
    ERC20Mintable()
    ERC20()
    public
  {

  }
}


 

 
 


 

 
 
 
 
 

 
 


 

 
 


 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 

 
 
 


 

 
 
 
 

 

 
 
 
 
 
 
 
 