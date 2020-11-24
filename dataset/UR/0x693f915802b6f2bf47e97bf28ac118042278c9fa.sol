 

pragma solidity ^0.4.13;

contract TokenInterface {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
    function approve(address _spender, uint256 _amount) returns (bool success);
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}

contract DynamicToken is TokenInterface {
  bool public isClosed;
  bool public isMaxSupplyLocked;
  bool public isLockedOpen;
  bool public isContractOwnerLocked;

  uint256 public maxSupply;

  address public upgradedContract;
  address public contractOwner;
  address[] public accounts;

  string[] public proofIds;

  mapping (address => bool) public accountExists;
  mapping (string => bool) proofIdExists;

  event TransferFrom(address indexed _from, address indexed _to,  address indexed _spender, uint256 _amount);
  event Issue(address indexed _from, address indexed _to, uint256 _amount, string _proofId);
  event Burn(address indexed _burnFrom, uint256 _amount);
  event Close(address indexed _closedBy);
  event Upgrade(address indexed _upgradedContract);
  event LockOpen(address indexed _by);
  event LockContractOwner(address indexed _by);
  event TransferContractOwnership(address indexed _by, address indexed _to);
  event MaxSupply(address indexed _by, uint256 _newMaxSupply, bool _isMaxSupplyLocked);

  function DynamicToken() {
    contractOwner = msg.sender;      
    maxSupply = 10**7;
    totalSupply = 0;

    isClosed = false;
    isMaxSupplyLocked = false;
    isLockedOpen = false;
    isContractOwnerLocked = false;
  }

   
  modifier onlyContractOwner {
    if (msg.sender != contractOwner) revert();
    _;
  }

   
  modifier notClosed {
    if (isClosed) revert();
    _;
  }

  modifier notLockedOpen {
    if (isLockedOpen) revert();
    _;
  }

   
  modifier noEther() {if (msg.value > 0) revert(); _;}

   

  function getAccounts() noEther constant returns (address[] _accounts) {
    return accounts;
  }

  function balanceOf(address _owner) noEther constant returns(uint256 balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) noEther constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   

   
  function issue(address _to, uint256 _amount, string _proofId) notClosed onlyContractOwner noEther returns (bool success) {
    if (balances[_to] + _amount < balances[_to]) revert();  
    if (totalSupply + _amount < totalSupply) revert();      

    if (proofIdExists[_proofId]) return false;
    if (totalSupply + _amount > maxSupply) return false;

    balances[_to] += _amount;
    totalSupply += _amount;
    _indexAccount(_to);
    _indexProofId(_proofId);
    Issue(msg.sender, _to, _amount, _proofId);
    return true;
  }

  function setMaxSupply(uint256 _maxSupply) notClosed onlyContractOwner noEther returns (bool success) {
    if (_maxSupply < totalSupply) revert();
    if (isMaxSupplyLocked) return false;

    maxSupply = _maxSupply;
    MaxSupply(msg.sender, _maxSupply, isMaxSupplyLocked);
    return true;
  }

   
  function lockMaxSupply() notClosed onlyContractOwner noEther returns(bool success) {
    isMaxSupplyLocked = true;
    MaxSupply(msg.sender, maxSupply, isMaxSupplyLocked);
    return true;
  }

  function transfer(address _to, uint256 _amount) notClosed noEther returns (bool success) {
    return _transfer(msg.sender, _to, _amount);
  }

  function approve(address _spender, uint256 _amount) notClosed noEther returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amount) notClosed noEther returns (bool success) {
    if (_amount > allowed[_from][msg.sender]) return false;

    if (allowed[_from][msg.sender] - _amount > allowed[_from][msg.sender]) revert();   

    if (_transfer(_from, _to, _amount)) {
      allowed[_from][msg.sender] -= _amount;
      TransferFrom(_from, _to, msg.sender, _amount);
      return true;
    } else {
      return false;
    }
  }

  function burn(uint256 _amount) notClosed noEther returns (bool success) {
    if (_amount > balances[msg.sender]) return false;

    if (_amount > totalSupply) revert();
    if (balances[msg.sender] - _amount > balances[msg.sender]) revert();      
    if (totalSupply - _amount > totalSupply) revert();                      

    balances[msg.sender] -= _amount;
    totalSupply -= _amount;
    Burn(msg.sender, _amount);
    return true;
  }

   

   
  function lockContractOwner() notClosed onlyContractOwner noEther returns(bool success) {
    isContractOwnerLocked = true;
    LockContractOwner(msg.sender);
    return true;
  }

  function transferContractOwnership(address _newOwner) notClosed onlyContractOwner noEther returns (bool success) {
    if(isContractOwnerLocked) revert();

    contractOwner = _newOwner;
    TransferContractOwnership(msg.sender, _newOwner);
    return true;
  }

   
  function lockOpen() notClosed onlyContractOwner noEther returns (bool success) {
    isLockedOpen = true;
    LockOpen(msg.sender);
    return true;
  }

  function upgrade(address _upgradedContract) notLockedOpen notClosed onlyContractOwner noEther returns (bool success) {
    upgradedContract = _upgradedContract;
    close();
    Upgrade(_upgradedContract);
    return true;
  }

  function close() notLockedOpen notClosed onlyContractOwner noEther returns (bool success) {
    isClosed = true;
    Close(msg.sender);
    return true;
  }

  function destroyContract() notLockedOpen onlyContractOwner noEther {
    selfdestruct(contractOwner);
  }

   

  function _transfer(address _from, address _to, uint256 _amount) notClosed private returns (bool success) {
    if (_amount > balances[_from]) return false;

    if (balances[_to] + _amount < balances[_to]) revert();       
    if (balances[_from] - _amount > balances[_from]) revert();   

    balances[_to] += _amount;
    balances[_from] -= _amount;
    _indexAccount(_to);
    Transfer(_from, _to, _amount);
    return true;
  }

  function _indexAccount(address _account) notClosed private returns (bool success) {
    if (accountExists[_account]) return;
    accountExists[_account] = true;
    accounts.push(_account);
    return true;
  }

  function _indexProofId(string _proofId) notClosed private returns (bool success) {
    if (proofIdExists[_proofId]) return;
    proofIdExists[_proofId] = true;
    proofIds.push(_proofId);
    return true;
  }

   
  function () {
    revert();
  }
}