 

 
contract Relay {
  function relayReceiveApproval(address _caller, address _spender, uint256 _amount, bytes _extraData) returns (bool success);
}

contract DVIPBackend {
  uint8 public decimals;
  function assert(bool assertion) {
    if (!assertion) throw;
  }
  address public owner;
  event SetOwner(address indexed previousOwner, address indexed newOwner);
  modifier onlyOwner {
    assert(msg.sender == owner);
    _
  }
  function setOwner(address newOwner) onlyOwner {
    SetOwner(owner, newOwner);
    owner = newOwner;
  }
  bool internal locked;
  event Locked(address indexed from);
  event PropertySet(address indexed from);
  modifier onlyIfUnlocked {
    assert(!locked);
    _
  }
  modifier setter {
    _
    PropertySet(msg.sender);
  }
  modifier onlyOwnerUnlocked {
    assert(!locked && msg.sender == owner);
    _
  }
  function lock() onlyOwner onlyIfUnlocked {
    locked = true;
    Locked(msg.sender);
  }
  function isLocked() returns (bool status) {
    return locked;
  }
  bytes32 public standard = 'Token 0.1';
  bytes32 public name;
  bytes32 public symbol;
  bool public allowTransactions;
  uint256 public totalSupply;

  event Approval(address indexed from, address indexed spender, uint256 amount);

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);

  function () {
    throw;
  }

  uint256 public expiry;
  uint8 public feeDecimals;
  mapping (address => uint256) public validAfter;
  uint256 public mustHoldFor;
  address public hotwalletAddress;
  address public frontendAddress;
  mapping (address => bool) public frozenAccount;
  mapping (address => uint256) public exportFee;

  event FeeSetup(address indexed from, address indexed target, uint256 amount);
  event Processed(address indexed sender);

  modifier onlyAsset {
    if (msg.sender != frontendAddress) throw;
    _
  }

   
  function DVIPBackend(address _hotwalletAddress, address _frontendAddress) {
    owner = msg.sender;
    hotwalletAddress = _hotwalletAddress;
    frontendAddress = _frontendAddress;
    allowTransactions = true;
    totalSupply = 0;
    name = "DVIP";
    symbol = "DVIP";
    feeDecimals = 6;
    expiry = 1514764800;  
    mustHoldFor = 86400;
  }

  function setHotwallet(address _address) onlyOwnerUnlocked {
    hotwalletAddress = _address;
    PropertySet(msg.sender);
  }

  function setFrontend(address _address) onlyOwnerUnlocked {
    frontendAddress = _address;
    PropertySet(msg.sender);
  } 

   
  function transfer(address caller, address _to, uint256 _amount) onlyAsset returns (bool success) {
    assert(allowTransactions);
    assert(balanceOf[caller] >= _amount);
    assert(balanceOf[_to] + _amount >= balanceOf[_to]);
    assert(!frozenAccount[caller]);
    assert(!frozenAccount[_to]);
    balanceOf[caller] -= _amount;
    uint256 preBalance = balanceOf[_to];
    balanceOf[_to] += _amount;
    if (preBalance <= 1 && balanceOf[_to] >= 1) {
      validAfter[_to] = now + mustHoldFor;
    }
    Transfer(caller, _to, _amount);
    return true;
  }

   
  function transferFrom(address caller, address _from, address _to, uint256 _amount) onlyAsset returns (bool success) {
    assert(allowTransactions);
    assert(balanceOf[_from] >= _amount);
    assert(balanceOf[_to] + _amount >= balanceOf[_to]);
    assert(_amount <= allowance[_from][caller]);
    assert(!frozenAccount[caller]);
    assert(!frozenAccount[_from]);
    assert(!frozenAccount[_to]);
    balanceOf[_from] -= _amount;
    uint256 preBalance = balanceOf[_to];
    balanceOf[_to] += _amount;
    allowance[_from][caller] -= _amount;
    if (balanceOf[_to] >= 1 && preBalance <= 1) {
      validAfter[_to] = now + mustHoldFor;
    }
    Transfer(_from, _to, _amount);
    return true;
  }

   
  function approveAndCall(address caller, address _spender, uint256 _amount, bytes _extraData) onlyAsset returns (bool success) {
    assert(allowTransactions);
    allowance[caller][_spender] = _amount;
    Relay(frontendAddress).relayReceiveApproval(caller, _spender, _amount, _extraData);
    Approval(caller, _spender, _amount);
    return true;
  }

   
  function approve(address caller, address _spender, uint256 _amount) onlyAsset returns (bool success) {
    assert(allowTransactions);
    allowance[caller][_spender] = _amount;
    Approval(caller, _spender, _amount);
    return true;
  }

   



   
  function setExpiry(uint256 ts) onlyOwner {
    expiry = ts;
    Processed(msg.sender);
  }

   
  function mint(uint256 mintedAmount) onlyOwner {
    balanceOf[hotwalletAddress] += mintedAmount;
    totalSupply += mintedAmount;
    Processed(msg.sender);
  }

  function freezeAccount(address target, bool frozen) onlyOwner {
    frozenAccount[target] = frozen;
    Processed(msg.sender);
  }

  function seizeTokens(address target, uint256 amount) onlyOwner {
    assert(balanceOf[target] >= amount);
    assert(frozenAccount[target]);
    balanceOf[target] -= amount;
    balanceOf[hotwalletAddress] += amount;
    Transfer(target, hotwalletAddress, amount);
  }

  function destroyTokens(uint256 amt) onlyOwner {
    assert(balanceOf[hotwalletAddress] >= amt);
    balanceOf[hotwalletAddress] -= amt;
    Processed(msg.sender);
  }

   
  function setExportFee(address addr, uint256 fee) onlyOwner {
    exportFee[addr] = fee;
    Processed(msg.sender);
  }

  function setHoldingPeriod(uint256 ts) onlyOwner {
    mustHoldFor = ts;
    Processed(msg.sender);
  }

  function setAllowTransactions(bool allow) onlyOwner {
    allowTransactions = allow;
    Processed(msg.sender);
  }

   


   
  function feeFor(address from, address to, uint256 amount) constant external returns (uint256 value) {
    uint256 fee = exportFee[from];
    if (fee == 0) return 0;
    if ((exportFee[from] == 0 && balanceOf[from] != 0 && now < expiry && validAfter[from] <= now) || (balanceOf[to] != 0 && now < expiry && validAfter[to] <= now)) return 0;
    return div10(amount*fee, feeDecimals);
  }
  function div10(uint256 a, uint8 b) internal returns (uint256 result) {
    for (uint8 i = 0; i < b; i++) {
      a /= 10;
    }
    return a;
  }
}