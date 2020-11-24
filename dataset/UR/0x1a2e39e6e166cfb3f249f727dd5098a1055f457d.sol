 

 


 



interface SecurityTransferAgent {
  function verify(address from, address to, uint256 value) external view returns (uint256 newValue);
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


interface ERC677Receiver {
  function tokenFallback(address from, uint256 amount, bytes data) returns (bool success);
}

interface ERC677 {

   
  event ERC677Transfer(address from, address receiver, uint256 amount, bytes data);

  function transferAndCall(ERC677Receiver receiver, uint amount, bytes data) returns (bool success);
}



contract ERC677Token is ERC20, ERC677 {
  function transferAndCall(ERC677Receiver receiver, uint amount, bytes data) returns (bool success) {
    require(transfer(address(receiver), amount));

    ERC677Transfer(msg.sender, address(receiver), amount, data);

    require(receiver.tokenFallback(msg.sender, amount, data));
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


 
contract CheckpointToken is ERC677Token {
  using SafeMath for uint256;  

   
  string public name;
   
  string public symbol;
   
  uint256 public decimals;
   
  SecurityTransferAgent public transactionVerifier;

   
   
  struct Checkpoint {
    uint256 checkpointID;
    uint256 value;
  }
   
  mapping (address => Checkpoint[]) public tokenBalances;
   
  Checkpoint[] public tokensTotal;
   
   
  uint256 public currentCheckpointID;

   
  mapping (address => mapping (address => uint256)) public allowed;

   
  function CheckpointToken(string _name, string _symbol, uint256 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

   

   
  function allowance(address owner, address spender) public view returns (uint256) {
    return allowed[owner][spender];
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= allowed[from][msg.sender]);

    value = verifyTransaction(from, to, value);

    transferInternal(from, to, value);
    Transfer(from, to, value);
    return true;
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    value = verifyTransaction(msg.sender, to, value);

    transferInternal(msg.sender, to, value);
    Transfer(msg.sender, to, value);
    return true;
  }

   
  function totalSupply() public view returns (uint256 tokenCount) {
    tokenCount = balanceAtCheckpoint(tokensTotal, currentCheckpointID);
  }

   
  function totalSupplyAt(uint256 checkpointID) public view returns (uint256 tokenCount) {
    tokenCount = balanceAtCheckpoint(tokensTotal, checkpointID);
  }

   
  function balanceOf(address owner) public view returns (uint256 balance) {
    balance = balanceAtCheckpoint(tokenBalances[owner], currentCheckpointID);
  }

   
  function balanceAt(address owner, uint256 checkpointID) public view returns (uint256 balance) {
    balance = balanceAtCheckpoint(tokenBalances[owner], checkpointID);
  }

   
  function increaseApproval(address spender, uint addedValue) public returns (bool) {
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][spender];
    if (subtractedValue > oldValue) {
      allowed[msg.sender][spender] = 0;
    } else {
      allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

   
  function increaseApproval(address spender, uint addedValue, bytes data) public returns (bool) {
    require(spender != address(this));

    increaseApproval(spender, addedValue);

    require(spender.call(data));

    return true;
  }

   
  function decreaseApproval(address spender, uint subtractedValue, bytes data) public returns (bool) {
    require(spender != address(this));

    decreaseApproval(spender, subtractedValue);

    require(spender.call(data));

    return true;
  }

   

  function balanceAtCheckpoint(Checkpoint[] storage checkpoints, uint256 checkpointID) internal returns (uint256 balance) {
    uint256 currentCheckpointID;
    (currentCheckpointID, balance) = getCheckpoint(checkpoints, checkpointID);
  }

  function verifyTransaction(address from, address to, uint256 value) internal returns (uint256) {
    if (address(transactionVerifier) != address(0)) {
      value = transactionVerifier.verify(from, to, value);
    }

     
    return value;
  }

  function transferInternal(address from, address to, uint256 value) internal {
    uint256 fromBalance = balanceOf(from);
    uint256 toBalance = balanceOf(to);

    setCheckpoint(tokenBalances[from], fromBalance.sub(value));
    setCheckpoint(tokenBalances[to], toBalance.add(value));
  }

  function createCheckpoint() internal returns (uint256 checkpointID) {
    currentCheckpointID = currentCheckpointID + 1;
    return currentCheckpointID;
  }


   

  function setCheckpoint(Checkpoint[] storage checkpoints, uint256 newValue) internal {
    if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].checkpointID < currentCheckpointID)) {
      checkpoints.push(Checkpoint(currentCheckpointID, newValue));
    } else {
       checkpoints[checkpoints.length.sub(1)] = Checkpoint(currentCheckpointID, newValue);
    }
  }

  function getCheckpoint(Checkpoint[] storage checkpoints, uint256 checkpointID) internal returns (uint256 checkpointID_, uint256 value) {
    if (checkpoints.length == 0) {
      return (0, 0);
    }

     
    if (checkpointID >= checkpoints[checkpoints.length.sub(1)].checkpointID) {
      return (checkpoints[checkpoints.length.sub(1)].checkpointID, checkpoints[checkpoints.length.sub(1)].value);
    }

    if (checkpointID < checkpoints[0].checkpointID) {
      return (0, 0);
    }

     
    uint256 min = 0;
    uint256 max = checkpoints.length.sub(1);
    while (max > min) {
      uint256 mid = (max.add(min.add(1))).div(2);
      if (checkpoints[mid].checkpointID <= checkpointID) {
        min = mid;
      } else {
        max = mid.sub(1);
      }
    }

    return (checkpoints[min].checkpointID, checkpoints[min].value);
  }
}

 




contract ERC20SnapshotMixin is CheckpointToken {
   
  event Snapshot(uint256 id);

   
  function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256) {
    return balanceAt(account, snapshotId);
  }
}




 
  mapping(bytes => bool) signatures;

  event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
  event Debug(address from, bytes32 hash);

   
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
    bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);
    address from = recover(hashedTx, _signature);
    require(from != address(0));

    _value = verifyTransaction(from, _to, _value);
    _fee = verifyTransaction(from, msg.sender, _fee);

    transferInternal(from, _to, _value);
    transferInternal(from, msg.sender, _fee);

    signatures[_signature] = true;
    TransferPreSigned(from, _to, msg.sender, _value, _fee);
    Transfer(from, _to, _value);
    Transfer(from, msg.sender, _fee);
    return true;
  }

   
  function transferPreSignedHashing(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce
  )
    public
    pure
    returns (bytes32)
  {
     
    return keccak256(bytes4(0x48664c16), _token, _to, _value, _fee, _nonce);
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

 

interface Announcement {
  function announcementName() public view returns (bytes32);
  function announcementURI() public view returns (bytes32);
  function announcementType() public view returns (uint256);
  function announcementHash() public view returns (uint256);
}


 




 
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



contract Recoverable is Ownable {

   
  function Recoverable() {
  }

   
   
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

   
   
   
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
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

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
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

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}



 
contract SecurityToken is CheckpointToken, RBAC, Recoverable, ERC865, ERC20SnapshotMixin {
  using SafeMath for uint256;  

  string public constant ROLE_ANNOUNCE = "announce()";
  string public constant ROLE_FORCE = "forceTransfer()";
  string public constant ROLE_ISSUE = "issueTokens()";
  string public constant ROLE_BURN = "burnTokens()";
  string public constant ROLE_INFO = "setTokenInformation()";
  string public constant ROLE_SETVERIFIER = "setTransactionVerifier()";
  string public constant ROLE_CHECKPOINT = "checkpoint()";

   
  string public version = 'TM-01 0.3';

   
   
  string public url;

   
   
  event Issued(address indexed to, uint256 value);
   
  event Burned(address indexed burner, uint256 value);
   
  event Forced(address indexed from, address indexed to, uint256 value);
   
  event Announced(address indexed announcement, uint256 indexed announcementType, bytes32 indexed announcementName, bytes32 announcementURI, uint256 announcementHash);
   
  event UpdatedTokenInformation(string newName, string newSymbol, string newUrl);
   
  event UpdatedTransactionVerifier(address newVerifier);
   
  event Checkpointed(uint256 checkpointID);

   
   
   
  address[] public announcements;
   
   
  mapping(address => uint256) public announcementsByAddress;

   
  function SecurityToken(string _name, string _symbol, string _url) CheckpointToken(_name, _symbol, 18) public {
    url = _url;

    addRole(msg.sender, ROLE_ANNOUNCE);
    addRole(msg.sender, ROLE_FORCE);
    addRole(msg.sender, ROLE_ISSUE);
    addRole(msg.sender, ROLE_BURN);
    addRole(msg.sender, ROLE_INFO);
    addRole(msg.sender, ROLE_SETVERIFIER);
    addRole(msg.sender, ROLE_CHECKPOINT);
  }

   
  function announce(Announcement announcement) external onlyRole(ROLE_ANNOUNCE) {
    announcements.push(announcement);
    announcementsByAddress[address(announcement)] = announcements.length;
    Announced(address(announcement), announcement.announcementType(), announcement.announcementName(), announcement.announcementURI(), announcement.announcementHash());
  }

   
  function forceTransfer(address from, address to, uint256 value) external onlyRole(ROLE_FORCE) {
    transferInternal(from, to, value);

    Forced(from, to, value);
  }

   
  function issueTokens(uint256 value) external onlyRole(ROLE_ISSUE) {
    address issuer = msg.sender;
    uint256 blackHoleBalance = balanceOf(address(0));
    uint256 totalSupplyNow = totalSupply();

    setCheckpoint(tokenBalances[address(0)], blackHoleBalance.add(value));
    transferInternal(address(0), issuer, value);
    setCheckpoint(tokensTotal, totalSupplyNow.add(value));

    Issued(issuer, value);
  }

   
  function burnTokens(uint256 value) external onlyRole(ROLE_BURN) {
    address burner = address(this);
    uint256 burnerBalance = balanceOf(burner);
    uint256 totalSupplyNow = totalSupply();

    transferInternal(burner, address(0), value);
    setCheckpoint(tokenBalances[address(0)], burnerBalance.sub(value));
    setCheckpoint(tokensTotal, totalSupplyNow.sub(value));

    Burned(burner, value);
  }

   
  function setTokenInformation(string _name, string _symbol, string _url) external onlyRole(ROLE_INFO) {
    name = _name;
    symbol = _symbol;
    url = _url;

    UpdatedTokenInformation(name, symbol, url);
  }

   
  function setTransactionVerifier(SecurityTransferAgent newVerifier) external onlyRole(ROLE_SETVERIFIER) {
    transactionVerifier = newVerifier;

    UpdatedTransactionVerifier(newVerifier);
  }

   
  function checkpoint() external onlyRole(ROLE_CHECKPOINT) returns (uint256 checkpointID) {
    checkpointID = createCheckpoint();
    emit Snapshot(checkpointID);
    emit Checkpointed(checkpointID);
  }
}