 

pragma solidity ^0.4.24;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract MultiSigTransfer is Ownable {
  string public name = "MultiSigTransfer";
  string public symbol = "MST";
  bool public complete = false;
  bool public denied = false;
  uint32 public quantity;
  address public targetAddress;
  address public requesterAddress;

   
  constructor(
    uint32 _quantity,
    address _targetAddress,
    address _requesterAddress
  ) public {
    quantity = _quantity;
    targetAddress = _targetAddress;
    requesterAddress = _requesterAddress;
  }

   
  function approveTransfer() public onlyOwner {
    require(denied == false, "cannot approve a denied transfer");
    require(complete == false, "cannot approve a complete transfer");
    complete = true;
  }

   
  function denyTransfer() public onlyOwner {
    require(denied == false, "cannot deny a transfer that is already denied");
    denied = true;
  }

   
  function isPending() public view returns (bool) {
    return !complete;
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
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

contract KinesisVelocityToken is BasicToken, Ownable, RBAC {
  string public name = "KinesisVelocityToken";
  string public symbol = "KVT";
  uint8 public decimals = 0;
  string public constant ADMIN_ROLE = "ADMIN";

  address[] public transfers;

  uint public constant INITIAL_SUPPLY = 300000;
  uint public totalSupply = 0;

  bool public isTransferable = false;
  bool public toggleTransferablePending = false;
  address public transferToggleRequester = address(0);

  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    addRole(msg.sender, ADMIN_ROLE);
  }

   
  function isOwner(address _address) public view returns (bool) {
    return owner == _address;
  }

   
  function getTransfers() public view returns (address[]) {
    return transfers;
  }

   
  function isAdmin(address _address) public view returns (bool) {
    return hasRole(_address, ADMIN_ROLE);
  }

   
  function setAdmin(address _newAdmin) public onlyOwner {
    return addRole(_newAdmin, ADMIN_ROLE);
  }

   
  function removeAdmin(address _oldAdmin) public onlyOwner {
    return removeRole(_oldAdmin, ADMIN_ROLE);
  }

   
  function setTransferable(bool _toState) public onlyRole(ADMIN_ROLE) {
    require(isTransferable != _toState, "to init a transfer toggle, the toState must change");
    toggleTransferablePending = true;
    transferToggleRequester = msg.sender;
  }

   
  function approveTransferableToggle() public onlyRole(ADMIN_ROLE) {
    require(toggleTransferablePending == true, "transfer toggle not in pending state");
    require(transferToggleRequester != msg.sender, "the requester cannot approve the transfer toggle");
    isTransferable = !isTransferable;
    toggleTransferablePending = false;
    transferToggleRequester = address(0);
  }

   
  function _transfer(address _to, address _from, uint256 _value) private returns (bool) {
    require(_value <= balances[_from], "the balance in the from address is smaller than the tx value");

     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "cannot transfer to the zero address");

     
    if (_to != owner && msg.sender != crowdsale) {
      require(isTransferable == true, "kvt is not yet transferable");
    }

     
    require(msg.sender != owner, "the owner of the kvt contract cannot transfer");

    return _transfer(_to, msg.sender, _value);
  }

   
  function adminTransfer(address _to, uint32 _quantity) public onlyRole(ADMIN_ROLE) {
    address newTransfer = new MultiSigTransfer(_quantity, _to, msg.sender);
    transfers.push(newTransfer);
  }

   
  function approveTransfer(address _approvedTransfer) public onlyRole(ADMIN_ROLE) returns (bool) {
    MultiSigTransfer transferToApprove = MultiSigTransfer(_approvedTransfer);

    uint32 transferQuantity = transferToApprove.quantity();
    address deliveryAddress = transferToApprove.targetAddress();
    address requesterAddress = transferToApprove.requesterAddress();

    require(msg.sender != requesterAddress, "a requester cannot approve an admin transfer");

    transferToApprove.approveTransfer();
    return _transfer(deliveryAddress, owner, transferQuantity);
  }

   
  function denyTransfer(address _approvedTransfer) public onlyRole(ADMIN_ROLE) returns (bool) {
    MultiSigTransfer transferToApprove = MultiSigTransfer(_approvedTransfer);
    transferToApprove.denyTransfer();
  }

  address public crowdsale = address(0);

   
  function setCrowdsaleAddress(address _crowdsaleAddress) public onlyRole(ADMIN_ROLE) {
    crowdsale = _crowdsaleAddress;
  }
}