 

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;


contract Managed is Ownable {
  mapping (address => bool) public managers;

  modifier onlyManager () {
    require(isManager(), "Only managers may perform this action");
    _;
  }

  modifier onlyManagerOrOwner () {
    require(
      checkManagerStatus(msg.sender) || msg.sender == owner,
      "Only managers or owners may perform this action"
    );
    _;
  }

  function checkManagerStatus (address managerAddress) public view returns (bool) {
    return managers[managerAddress];
  }

  function isManager () public view returns (bool) {
    return checkManagerStatus(msg.sender);
  }

  function addManager (address managerAddress) public onlyOwner {
    managers[managerAddress] = true;
  }

  function removeManager (address managerAddress) public onlyOwner {
    managers[managerAddress] = false;
  }
}

 

pragma solidity ^0.4.24;


contract ManagedWhitelist is Managed {
   
  mapping (address => bool) public coreList;
   
  mapping (address => bool) public civilianList;
   
  mapping (address => bool) public unlockedList;
   
  mapping (address => bool) public verifiedList;
   
  mapping (address => bool) public storefrontList;
   
  mapping (address => bool) public newsroomMultisigList;

   
  function addToCore (address operator) public onlyManagerOrOwner {
    coreList[operator] = true;
  }

   
  function removeFromCore (address operator) public onlyManagerOrOwner {
    coreList[operator] = false;
  }

   
  function addToCivilians (address operator) public onlyManagerOrOwner {
    civilianList[operator] = true;
  }

   
  function removeFromCivilians (address operator) public onlyManagerOrOwner {
    civilianList[operator] = false;
  }
   
  function addToUnlocked (address operator) public onlyManagerOrOwner {
    unlockedList[operator] = true;
  }

   
  function removeFromUnlocked (address operator) public onlyManagerOrOwner {
    unlockedList[operator] = false;
  }

   
  function addToVerified (address operator) public onlyManagerOrOwner {
    verifiedList[operator] = true;
  }
   
  function removeFromVerified (address operator) public onlyManagerOrOwner {
    verifiedList[operator] = false;
  }

   
  function addToStorefront (address operator) public onlyManagerOrOwner {
    storefrontList[operator] = true;
  }
   
  function removeFromStorefront (address operator) public onlyManagerOrOwner {
    storefrontList[operator] = false;
  }

   
  function addToNewsroomMultisigs (address operator) public onlyManagerOrOwner {
    newsroomMultisigList[operator] = true;
  }
   
  function removeFromNewsroomMultisigs (address operator) public onlyManagerOrOwner {
    newsroomMultisigList[operator] = false;
  }

  function checkProofOfUse (address operator) public {

  }

}

 

pragma solidity ^0.4.24;

contract ERC1404 {
   
   
   
   
   
   
  function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

   
   
   
   
  function messageForTransferRestriction (uint8 restrictionCode) public view returns (string);
}

 

pragma solidity ^0.4.24;

library MessagesAndCodes {
  string public constant EMPTY_MESSAGE_ERROR = "Message cannot be empty string";
  string public constant CODE_RESERVED_ERROR = "Given code is already pointing to a message";
  string public constant CODE_UNASSIGNED_ERROR = "Given code does not point to a message";

  struct Data {
    mapping (uint8 => string) messages;
    uint8[] codes;
  }

  function messageIsEmpty (string _message)
      internal
      pure
      returns (bool isEmpty)
  {
    isEmpty = bytes(_message).length == 0;
  }

  function messageExists (Data storage self, uint8 _code)
      internal
      view
      returns (bool exists)
  {
    exists = bytes(self.messages[_code]).length > 0;
  }

  function addMessage (Data storage self, uint8 _code, string _message)
      public
      returns (uint8 code)
  {
    require(!messageIsEmpty(_message), EMPTY_MESSAGE_ERROR);
    require(!messageExists(self, _code), CODE_RESERVED_ERROR);

     
    self.messages[_code] = _message;
    self.codes.push(_code);
    code = _code;
  }

  function autoAddMessage (Data storage self, string _message)
      public
      returns (uint8 code)
  {
    require(!messageIsEmpty(_message), EMPTY_MESSAGE_ERROR);

     
    code = 0;
    while (messageExists(self, code)) {
      code++;
    }

     
    addMessage(self, code, _message);
  }

  function removeMessage (Data storage self, uint8 _code)
      public
      returns (uint8 code)
  {
    require(messageExists(self, _code), CODE_UNASSIGNED_ERROR);

     
    uint8 indexOfCode = 0;
    while (self.codes[indexOfCode] != _code) {
      indexOfCode++;
    }

     
    for (uint8 i = indexOfCode; i < self.codes.length - 1; i++) {
      self.codes[i] = self.codes[i + 1];
    }
    self.codes.length--;

     
    self.messages[_code] = "";
    code = _code;
  }

  function updateMessage (Data storage self, uint8 _code, string _message)
      public
      returns (uint8 code)
  {
    require(!messageIsEmpty(_message), EMPTY_MESSAGE_ERROR);
    require(messageExists(self, _code), CODE_UNASSIGNED_ERROR);

     
    self.messages[_code] = _message;
    code = _code;
  }
}

 

pragma solidity ^0.4.19;

contract Factory {

   
  event ContractInstantiation(address sender, address instantiation);

   
  mapping(address => bool) public isInstantiation;
  mapping(address => address[]) public instantiations;

   
   
   
   
  function getInstantiationCount(address creator)
    public
    view
    returns (uint)
  {
    return instantiations[creator].length;
  }

   
   
   
  function register(address instantiation)
      internal
  {
    isInstantiation[instantiation] = true;
    instantiations[msg.sender].push(instantiation);
    emit ContractInstantiation(msg.sender, instantiation);
  }
}

 

pragma solidity ^0.4.19;

interface IMultiSigWalletFactory {
  function create(address[] _owners, uint _required) public returns (address wallet);
}

 

pragma solidity ^0.4.19;


 
contract ACL is Ownable {
  event RoleAdded(address indexed granter, address indexed grantee, string role);
  event RoleRemoved(address indexed granter, address indexed grantee, string role);

  mapping(string => RoleData) private roles;

  modifier requireRole(string role) {
    require(isOwner(msg.sender) || hasRole(msg.sender, role));
    _;
  }

  function ACL() Ownable() public {
  }

   
  function hasRole(address user, string role) public view returns (bool) {
    return roles[role].actors[user];
  }

   
  function isOwner(address user) public view returns (bool) {
    return user == owner;
  }

  function _addRole(address grantee, string role) internal {
    roles[role].actors[grantee] = true;
    emit RoleAdded(msg.sender, grantee, role);
  }

  function _removeRole(address grantee, string role) internal {
    delete roles[role].actors[grantee];
    emit RoleRemoved(msg.sender, grantee, role);
  }

  struct RoleData {
    mapping(address => bool) actors;
  }
}

 

pragma solidity ^0.4.24;


 

library ECRecovery {

   
  function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (_sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
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

 

pragma solidity ^0.4.19;



 
contract Newsroom is ACL {
  using ECRecovery for bytes32;

  event ContentPublished(address indexed editor, uint indexed contentId, string uri);
  event RevisionSigned(uint indexed contentId, uint indexed revisionId, address indexed author);
  event RevisionUpdated(address indexed editor, uint indexed contentId, uint indexed revisionId, string uri);
  event NameChanged(string newName);

  string private constant ROLE_EDITOR = "editor";

  mapping(uint => Content) private contents;
   
  mapping(bytes32 => UsedSignature) private usedSignatures;

   
  uint public contentCount;
   
  string public name;

  function Newsroom(string newsroomName, string charterUri, bytes32 charterHash) ACL() public {
    setName(newsroomName);
    publishContent(charterUri, charterHash, address(0), "");
  }

   
  function getContent(uint contentId) external view returns (bytes32 contentHash, string uri, uint timestamp, address author, bytes signature) {
    return getRevision(contentId, contents[contentId].revisions.length - 1);
  }

   
  function getRevision(
    uint contentId,
    uint revisionId
  ) public view returns (bytes32 contentHash, string uri, uint timestamp, address author, bytes signature)
  {
    Content storage content = contents[contentId];
    require(content.revisions.length > revisionId);

    Revision storage revision = content.revisions[revisionId];

    return (revision.contentHash, revision.uri, revision.timestamp, content.author, revision.signature);
  }

   
  function revisionCount(uint contentId) external view returns (uint) {
    return contents[contentId].revisions.length;
  }

   
  function isContentSigned(uint contentId) public view returns (bool) {
    return isRevisionSigned(contentId, contents[contentId].revisions.length - 1);
  }

   
  function isRevisionSigned(uint contentId, uint revisionId) public view returns (bool) {
    Revision[] storage revisions = contents[contentId].revisions;
    require(revisions.length > revisionId);
    return revisions[revisionId].signature.length != 0;
  }

   
  function setName(string newName) public onlyOwner() {
    require(bytes(newName).length > 0);
    name = newName;

    emit NameChanged(name);
  }

   
  function addRole(address who, string role) external requireRole(ROLE_EDITOR) {
    _addRole(who, role);
  }

  function addEditor(address who) external requireRole(ROLE_EDITOR) {
    _addRole(who, ROLE_EDITOR);
  }

   
  function removeRole(address who, string role) external requireRole(ROLE_EDITOR) {
    _removeRole(who, role);
  }

   
  function publishContent(
    string contentUri,
    bytes32 contentHash,
    address author,
    bytes signature
  ) public requireRole(ROLE_EDITOR) returns (uint)
  {
    uint contentId = contentCount;
    contentCount++;

    require((author == address(0) && signature.length == 0) || (author != address(0) && signature.length != 0));
    contents[contentId].author = author;
    pushRevision(contentId, contentUri, contentHash, signature);

    emit ContentPublished(msg.sender, contentId, contentUri);
    return contentId;
  }

   
  function updateRevision(uint contentId, string contentUri, bytes32 contentHash, bytes signature) external requireRole(ROLE_EDITOR) {
    pushRevision(contentId, contentUri, contentHash, signature);
  }

   
  function signRevision(uint contentId, uint revisionId, address author, bytes signature) external requireRole(ROLE_EDITOR) {
    require(contentId < contentCount);

    Content storage content = contents[contentId];

    require(content.author == address(0) || content.author == author);
    require(content.revisions.length > revisionId);

    if (contentId == 0) {
      require(isOwner(msg.sender));
    }

    content.author = author;

    Revision storage revision = content.revisions[revisionId];
    revision.signature = signature;

    require(verifyRevisionSignature(author, contentId, revision));

    emit RevisionSigned(contentId, revisionId, author);
  }

  function verifyRevisionSignature(address author, uint contentId, Revision storage revision) internal returns (bool isSigned) {
    if (author == address(0) || revision.signature.length == 0) {
      require(revision.signature.length == 0);
      return false;
    } else {
       
       
       
       
       
      bytes32 hashedMessage = keccak256(
        address(this),
        revision.contentHash
      ).toEthSignedMessageHash();

      require(hashedMessage.recover(revision.signature) == author);

       
      UsedSignature storage lastUsed = usedSignatures[hashedMessage];
      require(lastUsed.wasUsed == false || lastUsed.contentId == contentId);

      lastUsed.wasUsed = true;
      lastUsed.contentId = contentId;

      return true;
    }
  }

  function pushRevision(uint contentId, string contentUri, bytes32 contentHash, bytes signature) internal returns (uint) {
    require(contentId < contentCount);

    if (contentId == 0) {
      require(isOwner(msg.sender));
    }

    Content storage content = contents[contentId];

    uint revisionId = content.revisions.length;

    content.revisions.push(Revision(
      contentHash,
      contentUri,
      now,
      signature
    ));

    if (verifyRevisionSignature(content.author, contentId, content.revisions[revisionId])) {
      emit RevisionSigned(contentId, revisionId, content.author);
    }

    emit RevisionUpdated(msg.sender, contentId, revisionId, contentUri);
  }

  struct Content {
    Revision[] revisions;
    address author;
  }

  struct Revision {
    bytes32 contentHash;
    string uri;
    uint timestamp;
    bytes signature;
  }

   
  struct UsedSignature {
    bool wasUsed;
    uint contentId;
  }
}

 

pragma solidity ^0.4.19;
 




 
contract NewsroomFactory is Factory {
  IMultiSigWalletFactory public multisigFactory;
  mapping (address => address) public multisigNewsrooms;

  function NewsroomFactory(address multisigFactoryAddr) public {
    multisigFactory = IMultiSigWalletFactory(multisigFactoryAddr);
  }

   
  function create(string name, string charterUri, bytes32 charterHash, address[] initialOwners, uint initialRequired)
    public
    returns (Newsroom newsroom)
  {
    address wallet = multisigFactory.create(initialOwners, initialRequired);
    newsroom = new Newsroom(name, charterUri, charterHash);
    newsroom.addEditor(msg.sender);
    newsroom.transferOwnership(wallet);
    multisigNewsrooms[wallet] = newsroom;
    register(newsroom);
  }
}

 

pragma solidity ^0.4.23;

interface TokenTelemetryI {
  function onRequestVotingRights(address user, uint tokenAmount) external;
}

 

pragma solidity ^0.4.24;






contract CivilTokenController is ManagedWhitelist, ERC1404, TokenTelemetryI {
  using MessagesAndCodes for MessagesAndCodes.Data;
  MessagesAndCodes.Data internal messagesAndCodes;

  uint8 public constant SUCCESS_CODE = 0;
  string public constant SUCCESS_MESSAGE = "SUCCESS";

  uint8 public constant MUST_BE_A_CIVILIAN_CODE = 1;
  string public constant MUST_BE_A_CIVILIAN_ERROR = "MUST_BE_A_CIVILIAN";

  uint8 public constant MUST_BE_UNLOCKED_CODE = 2;
  string public constant MUST_BE_UNLOCKED_ERROR = "MUST_BE_UNLOCKED";

  uint8 public constant MUST_BE_VERIFIED_CODE = 3;
  string public constant MUST_BE_VERIFIED_ERROR = "MUST_BE_VERIFIED";

  constructor () public {
    messagesAndCodes.addMessage(SUCCESS_CODE, SUCCESS_MESSAGE);
    messagesAndCodes.addMessage(MUST_BE_A_CIVILIAN_CODE, MUST_BE_A_CIVILIAN_ERROR);
    messagesAndCodes.addMessage(MUST_BE_UNLOCKED_CODE, MUST_BE_UNLOCKED_ERROR);
    messagesAndCodes.addMessage(MUST_BE_VERIFIED_CODE, MUST_BE_VERIFIED_ERROR);

  }

  function detectTransferRestriction (address from, address to, uint value)
      public
      view
      returns (uint8)
  {
     
    if (coreList[from] || unlockedList[from]) {
      return SUCCESS_CODE;
    } else if (storefrontList[from]) {  
       
      if (verifiedList[to] || coreList[to]) {
        return SUCCESS_CODE;
      } else {
         
        return MUST_BE_VERIFIED_CODE;
      }
    } else if (newsroomMultisigList[from]) {  
       
      if ( coreList[to] || civilianList[to]) {
        return SUCCESS_CODE;
      } else {
        return MUST_BE_UNLOCKED_CODE;
      }
    } else if (civilianList[from]) {  
       
      if (coreList[to] || newsroomMultisigList[to]) {
        return SUCCESS_CODE;
      } else {
         
        return MUST_BE_UNLOCKED_CODE;
      }
    } else {
       
      return MUST_BE_A_CIVILIAN_CODE;
    }
  }

  function messageForTransferRestriction (uint8 restrictionCode)
    public
    view
    returns (string message)
  {
    message = messagesAndCodes.messages[restrictionCode];
  }

  function onRequestVotingRights(address user, uint tokenAmount) external {
    addToUnlocked(user);
  }
}

 

pragma solidity ^0.4.24;

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }
}

 

pragma solidity ^0.4.24;


 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor (string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns (string) {
    return _name;
  }

   
  function symbol() public view returns (string) {
    return _symbol;
  }

   
  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

 

pragma solidity ^0.4.24;






 
 
contract CVLToken is ERC20, ERC20Detailed, Ownable, ERC1404 {

  ERC1404 public controller;

  constructor (uint256 _initialAmount,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    ERC1404 _controller
    ) public ERC20Detailed(_tokenName, _tokenSymbol, _decimalUnits) {
    require(address(_controller) != address(0), "controller not provided");
    controller = _controller;
    _mint(msg.sender, _initialAmount);               
  }

  modifier onlyOwner () {
    require(msg.sender == owner, "not owner");
    _;
  }

  function changeController(ERC1404 _controller) public onlyOwner {
    require(address(_controller) != address(0), "controller not provided");
    controller = _controller;
  }

  modifier notRestricted (address from, address to, uint256 value) {
    require(controller.detectTransferRestriction(from, to, value) == 0, "token transfer restricted");
    _;
  }

  function transfer (address to, uint256 value)
      public
      notRestricted(msg.sender, to, value)
      returns (bool success)
  {
    success = super.transfer(to, value);
  }

  function transferFrom (address from, address to, uint256 value)
      public
      notRestricted(from, to, value)
      returns (bool success)
  {
    success = super.transferFrom(from, to, value);
  }

  function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8) {
    return controller.detectTransferRestriction(from, to, value);
  }

  function messageForTransferRestriction (uint8 restrictionCode) public view returns (string) {
    return controller.messageForTransferRestriction(restrictionCode);
  }


}