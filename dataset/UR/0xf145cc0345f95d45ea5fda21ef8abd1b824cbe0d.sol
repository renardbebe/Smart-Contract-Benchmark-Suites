 

pragma solidity ^0.4.18;

 
contract ERC721 {
   
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
   
   
  function transfer(address _to, uint256 _tokenId) external;
   

   
  event Transfer(address from, address to, uint256 tokenId);
   
}

 
contract DivisibleFirstCommonsForumToken is ERC721 {

   
  address private contractOwner;

   
  mapping(uint => ParticipationToken) participationStorage;

   
  uint public totalSupply = 19;
  bool public tradable = false;
  uint firstCommonsForumId = 1;

   
  mapping(address => mapping(uint => uint)) ownerToTokenShare;

   
  mapping(uint => mapping(address => uint)) tokenToOwnersHoldings;

   
  mapping(uint => bool) firstCommonsForumCreated;

  string public name;
  string public symbol;
  uint8 public decimals = 0;
  string public version = "1.0";

   
  struct ParticipationToken {
    uint256 participationId;
  }

   
  function DivisibleFirstCommonsForumToken() public {
    contractOwner = msg.sender;
    name = "FirstCommonsForum";
    symbol = "FCFT";

     
    ParticipationToken memory newParticipation = ParticipationToken({ participationId: firstCommonsForumId });
    participationStorage[firstCommonsForumId] = newParticipation;

    firstCommonsForumCreated[firstCommonsForumId] = true;
    _addNewOwnerHoldingsToToken(contractOwner, firstCommonsForumId, totalSupply);
    _addShareToNewOwner(contractOwner, firstCommonsForumId, totalSupply);
  }

   
  function() public {
    revert();
  }

  function totalSupply() public view returns (uint256 total) {
    return totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerToTokenShare[_owner][firstCommonsForumId];
  }

   
  function transfer(address _to, uint256 _tokenId) external {

     
    require(tradable == true);
    require(_to != address(0));
    require(msg.sender != _to);

     
    uint256 _divisibility = _tokenId;

     
    require(tokenToOwnersHoldings[firstCommonsForumId][msg.sender] >= _divisibility);

     
    _removeShareFromLastOwner(msg.sender, firstCommonsForumId, _divisibility);
    _removeLastOwnerHoldingsFromToken(msg.sender, firstCommonsForumId, _divisibility);

     
    _addNewOwnerHoldingsToToken(_to, firstCommonsForumId, _divisibility);
    _addShareToNewOwner(_to, firstCommonsForumId, _divisibility);

     
    Transfer(msg.sender, _to, firstCommonsForumId);
  }

   
  function assignSharedOwnership(address _to, uint256 _divisibility) onlyOwner external returns (bool success) {

    require(_to != address(0));
    require(msg.sender != _to);
    require(_to != address(this));

     
    require(tokenToOwnersHoldings[firstCommonsForumId][msg.sender] >= _divisibility);

     
    _removeLastOwnerHoldingsFromToken(msg.sender, firstCommonsForumId, _divisibility);
    _removeShareFromLastOwner(msg.sender, firstCommonsForumId, _divisibility);

     
    _addShareToNewOwner(_to, firstCommonsForumId, _divisibility);
    _addNewOwnerHoldingsToToken(_to, firstCommonsForumId, _divisibility);

     
    Transfer(msg.sender, _to, firstCommonsForumId);

    return true;
  }

  function getFirstCommonsForum() public view returns(uint256 _firstCommonsForumId) {
    return participationStorage[firstCommonsForumId].participationId;
  }

   
  function turnOnTradable() public onlyOwner {
    tradable = true;
  }

   

   
  function _addShareToNewOwner(address _owner, uint _tokenId, uint _units) internal {
    ownerToTokenShare[_owner][_tokenId] += _units;
  }

   
  function _addNewOwnerHoldingsToToken(address _owner, uint _tokenId, uint _units) internal {
    tokenToOwnersHoldings[_tokenId][_owner] += _units;
  }

   
  function _removeShareFromLastOwner(address _owner, uint _tokenId, uint _units) internal {
    ownerToTokenShare[_owner][_tokenId] -= _units;
  }

   
  function _removeLastOwnerHoldingsFromToken(address _owner, uint _tokenId, uint _units) internal {
    tokenToOwnersHoldings[_tokenId][_owner] -= _units;
  }

   
  function withdrawEther() onlyOwner public returns(bool) {
    return contractOwner.send(this.balance);
  }

   

  modifier onlyExistentToken(uint _tokenId) {
    require(firstCommonsForumCreated[_tokenId] == true);
    _;
  }

  modifier onlyOwner(){
    require(msg.sender == contractOwner);
    _;
  }

}


 
contract MultiSigWallet {

  uint constant public MAX_OWNER_COUNT = 50;

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint required);
  event CoinCreation(address coin);

  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;
  bool flag = true;

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  modifier onlyWallet() {
    if (msg.sender != address(this))
    revert();
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    if (isOwner[owner])
    revert();
    _;
  }

  modifier ownerExists(address owner) {
    if (!isOwner[owner])
    revert();
    _;
  }

  modifier transactionExists(uint transactionId) {
    if (transactions[transactionId].destination == 0)
    revert();
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    if (!confirmations[transactionId][owner])
    revert();
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    if (confirmations[transactionId][owner])
    revert();
    _;
  }

  modifier notExecuted(uint transactionId) {
    if (transactions[transactionId].executed)
    revert();
    _;
  }

  modifier notNull(address _address) {
    if (_address == 0)
    revert();
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    if (ownerCount > MAX_OWNER_COUNT || _required > ownerCount || _required == 0 || ownerCount == 0)
      revert();
      _;
  }

   
  function() payable {
    if (msg.value > 0)
    Deposit(msg.sender, msg.value);
  }

   
  function MultiSigWallet(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
    for (uint i=0; i<_owners.length; i++) {
      if (isOwner[_owners[i]] || _owners[i] == 0)
      revert();
      isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
  }

   
  function addOwner(address owner) public onlyWallet ownerDoesNotExist(owner) notNull(owner) validRequirement(owners.length + 1, required) {
    isOwner[owner] = true;
    owners.push(owner);
    OwnerAddition(owner);
  }

   
  function removeOwner(address owner) public onlyWallet ownerExists(owner) {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)

    if (owners[i] == owner) {
      owners[i] = owners[owners.length - 1];
      break;
    }
    owners.length -= 1;

    if (required > owners.length)
    changeRequirement(owners.length);
    OwnerRemoval(owner);
  }

   
  function replaceOwner(address owner, address newOwner) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
    for (uint i=0; i<owners.length; i++)
    if (owners[i] == owner) {
      owners[i] = newOwner;
      break;
    }
    isOwner[owner] = false;
    isOwner[newOwner] = true;
    OwnerRemoval(owner);
    OwnerAddition(newOwner);
  }

   
  function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
    required = _required;
    RequirementChange(_required);
  }

   
  function submitTransaction(address destination, uint value, bytes data) public returns (uint transactionId) {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

   
  function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
    confirmations[transactionId][msg.sender] = true;
    Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

   
  function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
    confirmations[transactionId][msg.sender] = false;
    Revocation(msg.sender, transactionId);
  }

   
  function executeTransaction(uint transactionId) public notExecuted(transactionId) {
    if (isConfirmed(transactionId)) {
      Transaction tx = transactions[transactionId];
      tx.executed = true;
      if (tx.destination.call.value(tx.value)(tx.data))
      Execution(transactionId);
      else {
        ExecutionFailure(transactionId);
        tx.executed = false;
      }
    }
  }

   
  function isConfirmed(uint transactionId) public constant returns (bool) {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
      count += 1;
      if (count == required)
      return true;
    }
  }

   
  function addTransaction(address destination, uint value, bytes data) internal notNull(destination) returns (uint transactionId) {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination: destination,
      value: value,
      data: data,
      executed: false
    });
    transactionCount += 1;
    Submission(transactionId);
  }

   
  function getConfirmationCount(uint transactionId) public constant returns (uint count) {
    for (uint i=0; i<owners.length; i++)
    if (confirmations[transactionId][owners[i]])
    count += 1;
  }

   
  function getTransactionCount(bool pending, bool executed) public constant returns (uint count) {
    for (uint i=0; i<transactionCount; i++)
    if (   pending && !transactions[i].executed || executed && transactions[i].executed)
      count += 1;
  }

   
  function getOwners() public constant returns (address[]) {
    return owners;
  }

   
  function getConfirmations(uint transactionId) public constant returns (address[] _confirmations) {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
    if (confirmations[transactionId][owners[i]]) {
      confirmationsTemp[count] = owners[i];
      count += 1;
    }
    _confirmations = new address[](count);
    for (i=0; i<count; i++)
    _confirmations[i] = confirmationsTemp[i];
  }

   
  function getTransactionIds(uint from, uint to, bool pending, bool executed) public constant returns (uint[] _transactionIds) {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;
    for (i=0; i<transactionCount; i++)
    if (pending && !transactions[i].executed || executed && transactions[i].executed) {
        transactionIdsTemp[count] = i;
        count += 1;
    }
      _transactionIds = new uint[](to - from);
      for (i=from; i<to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  modifier onlyOwner() {
    require(isOwner[msg.sender] == true);
    _;
  }

   
  function createFirstCommonsForum() external onlyWallet {
    require(flag == true);
    CoinCreation(new DivisibleFirstCommonsForumToken());
    flag = false;
  }
}