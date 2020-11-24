 

 

contract Assertive {
  function assert(bool assertion) {
    if (!assertion) throw;
  }
}

contract Owned is Assertive {
  address public owner;
  event SetOwner(address indexed previousOwner, address indexed newOwner);
  function Owned () {
    owner = msg.sender;
  }
  modifier onlyOwner {
    assert(msg.sender == owner);
    _
  }
  function setOwner(address newOwner) onlyOwner {
    SetOwner(owner, newOwner);
    owner = newOwner;
  }
}

contract StateTransferrable is Owned {
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
}

contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract Relay {
  function relayReceiveApproval(address _caller, address _spender, uint256 _amount, bytes _extraData) returns (bool success);
}

contract TokenBase is Owned {
    bytes32 public standard = 'Token 0.1';
    bytes32 public name;
    bytes32 public symbol;
    bool public allowTransactions;
    uint256 public totalSupply;

    event Approval(address indexed from, address indexed spender, uint256 amount);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function () {
        throw;
    }
}

contract TrustEvents {
  event AuthInit(address indexed from);
  event AuthComplete(address indexed from, address indexed with);
  event AuthPending(address indexed from);
  event Unauthorized(address indexed from);
  event InitCancel(address indexed from);
  event NothingToCancel(address indexed from);
  event SetMasterKey(address indexed from);
  event AuthCancel(address indexed from, address indexed with);
}

contract Trust is StateTransferrable, TrustEvents {

  mapping (address => bool) public masterKeys;
  mapping (address => bytes32) public nameRegistry;
  address[] public masterKeyIndex;
  mapping (address => bool) public masterKeyActive;
  mapping (address => bool) public trustedClients;
  mapping (uint256 => address) public functionCalls;
  mapping (address => uint256) public functionCalling;

   

  modifier multisig (bytes32 hash) {
    if (!masterKeys[msg.sender]) {
      Unauthorized(msg.sender);
    } else if (functionCalling[msg.sender] == 0) {
      if (functionCalls[uint256(hash)] == 0x0) {
        functionCalls[uint256(hash)] = msg.sender;
        functionCalling[msg.sender] = uint256(hash);
        AuthInit(msg.sender);
      } else {
        AuthComplete(functionCalls[uint256(hash)], msg.sender);
        resetAction(uint256(hash));
        _
      }
    } else {
      AuthPending(msg.sender);
    }
  }

   

   
  function setMasterKey(address addr) onlyOwnerUnlocked {
    assert(!masterKeys[addr]);
    activateMasterKey(addr);
    masterKeys[addr] = true;
    SetMasterKey(msg.sender);
  }

   
  function setTrustedClient(address addr) onlyOwnerUnlocked setter {
    trustedClients[addr] = true;
  }

   



   

   
  function untrustClient(address addr) multisig(sha3(msg.data)) {
    trustedClients[addr] = false;
  }

   
  function trustClient(address addr) multisig(sha3(msg.data)) {
    trustedClients[addr] = true;
  }

   
  function voteOutMasterKey(address addr) multisig(sha3(msg.data)) {
    assert(masterKeys[addr]);
    masterKeys[addr] = false;
  }

   
  function voteInMasterKey(address addr) multisig(sha3(msg.data)) {
    assert(!masterKeys[addr]);
    activateMasterKey(addr);
    masterKeys[addr] = true;
  }

   


   
  function authCancel(address from) external returns (uint8 status) {
    if (!masterKeys[from] || !trustedClients[msg.sender]) {
      Unauthorized(from);
      return 0;
    }
    uint256 call = functionCalling[from];
    if (call == 0) {
      NothingToCancel(from);
      return 1;
    } else {
      AuthCancel(from, from);
      functionCalling[from] = 0;
      functionCalls[call] = 0x0;
      return 2;
    }
  }

   
  function authCall(address from, bytes32 hash) external returns (uint8 code) {
    if (!masterKeys[from] || !trustedClients[msg.sender]) {
      Unauthorized(from);
      return 0;
    }
    if (functionCalling[from] == 0) {
      if (functionCalls[uint256(hash)] == 0x0) {
        functionCalls[uint256(hash)] = from;
        functionCalling[from] = uint256(hash);
        AuthInit(from);
        return 1;
      } else {
        AuthComplete(functionCalls[uint256(hash)], from);
        resetAction(uint256(hash));
        return 2;
      }
    } else {
      AuthPending(from);
      return 3;
    }
  }

   

   
  function cancel() returns (uint8 code) {
    if (!masterKeys[msg.sender]) {
      Unauthorized(msg.sender);
      return 0;
    }
    uint256 call = functionCalling[msg.sender];
    if (call == 0) {
      NothingToCancel(msg.sender);
      return 1;
    } else {
      AuthCancel(msg.sender, msg.sender);
      uint256 hash = functionCalling[msg.sender];
      functionCalling[msg.sender] = 0x0;
      functionCalls[hash] = 0;
      return 2;
    }
  }

   

  function resetAction(uint256 hash) internal {
    address addr = functionCalls[hash];
    functionCalls[hash] = 0x0;
    functionCalling[addr] = 0;
  }

  function activateMasterKey(address addr) internal {
    if (!masterKeyActive[addr]) {
      masterKeyActive[addr] = true;
      masterKeyIndex.push(addr);
    }
  }

   

  function extractMasterKeyIndexLength() returns (uint256 length) {
    return masterKeyIndex.length;
  }

}


contract TrustClient is StateTransferrable, TrustEvents {

  address public trustAddress;

  modifier multisig (bytes32 hash) {
    assert(trustAddress != address(0x0));
    address current = Trust(trustAddress).functionCalls(uint256(hash));
    uint8 code = Trust(trustAddress).authCall(msg.sender, hash);
    if (code == 0) Unauthorized(msg.sender);
    else if (code == 1) AuthInit(msg.sender);
    else if (code == 2) {
      AuthComplete(current, msg.sender);
      _
    }
    else if (code == 3) {
      AuthPending(msg.sender);
    }
  }
  
  function setTrust(address addr) setter onlyOwnerUnlocked {
    trustAddress = addr;
  }

  function cancel() returns (uint8 status) {
    assert(trustAddress != address(0x0));
    uint8 code = Trust(trustAddress).authCancel(msg.sender);
    if (code == 0) Unauthorized(msg.sender);
    else if (code == 1) NothingToCancel(msg.sender);
    else if (code == 2) AuthCancel(msg.sender, msg.sender);
    return code;
  }

}

contract DVIPBackend {
  uint8 public decimals;
  function assert(bool assertion) {
    if (!assertion) throw;
  }
  bytes32 public standard = 'Token 0.1';
  bytes32 public name;
  bytes32 public symbol;
  bool public allowTransactions;
  uint256 public totalSupply;

  event Approval(address indexed from, address indexed spender, uint256 amount);
  event PropertySet(address indexed from);

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

 

 

  event Transfer(address indexed from, address indexed to, uint256 value);

  uint256 public baseFeeDivisor;
  uint256 public feeDivisor;
  uint256 public singleDVIPQty;

  function () {
    throw;
  }

  bool public locked;
  address public owner;

  modifier onlyOwnerUnlocked {
    assert(msg.sender == owner && !locked);
    _
  }

  modifier onlyOwner {
    assert(msg.sender == owner);
    _
  }

  function lock() onlyOwnerUnlocked returns (bool success) {
    locked = true;
    PropertySet(msg.sender);
    return true;
  }

  function setOwner(address _address) onlyOwner returns (bool success) {
    owner = _address;
    PropertySet(msg.sender);
    return true;
  }

  uint256 public expiry;
  uint8 public feeDecimals;

  struct Validity {
    uint256 last;
    uint256 ts;
  }

  mapping (address => Validity) public validAfter;
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
    decimals = 1;
    expiry = 1514764800;  
    mustHoldFor = 604800;
    precalculate();
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
    bool alreadyMax = preBalance >= singleDVIPQty;
    if (!alreadyMax) {
      if (now >= validAfter[_to].ts + mustHoldFor) validAfter[_to].last = preBalance;
      validAfter[_to].ts = now;
    }
    if (validAfter[caller].last > balanceOf[caller]) validAfter[caller].last = balanceOf[caller];
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
    bool alreadyMax = preBalance >= singleDVIPQty;
    if (!alreadyMax) {
      if (now >= validAfter[_to].ts + mustHoldFor) validAfter[_to].last = preBalance;
      validAfter[_to].ts = now;
    }
    if (validAfter[_from].last > balanceOf[_from]) validAfter[_from].last = balanceOf[_from];
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
    if (now >= expiry) return amount*fee / baseFeeDivisor;
    uint256 amountHeld;
    if (balanceOf[to] != 0) {
      if (validAfter[to].ts + mustHoldFor < now) amountHeld = balanceOf[to];
      else amountHeld = validAfter[to].last;
      if (amountHeld >= singleDVIPQty) return 0;
      return amount*fee*(singleDVIPQty - amountHeld) / feeDivisor;
    } else return amount*fee / baseFeeDivisor;
  }
  function precalculate() internal returns (bool success) {
    baseFeeDivisor = pow10(1, feeDecimals);
    feeDivisor = pow10(1, feeDecimals + decimals);
    singleDVIPQty = pow10(1, decimals);
  }
  function div10(uint256 a, uint8 b) internal returns (uint256 result) {
    for (uint8 i = 0; i < b; i++) {
      a /= 10;
    }
    return a;
  }
  function pow10(uint256 a, uint8 b) internal returns (uint256 result) {
    for (uint8 i = 0; i < b; i++) {
      a *= 10;
    }
    return a;
  }
   
}

 
contract DVIP is TokenBase, StateTransferrable, TrustClient, Relay {

   address public backendContract;

    
   function DVIP(address _backendContract) {
     backendContract = _backendContract;
   }

   function standard() constant returns (bytes32 std) {
     return DVIPBackend(backendContract).standard();
   }

   function name() constant returns (bytes32 nm) {
     return DVIPBackend(backendContract).name();
   }

   function symbol() constant returns (bytes32 sym) {
     return DVIPBackend(backendContract).symbol();
   }

   function decimals() constant returns (uint8 precision) {
     return DVIPBackend(backendContract).decimals();
   }
  
   function allowance(address from, address to) constant returns (uint256 res) {
     return DVIPBackend(backendContract).allowance(from, to);
   }


    


    
   function setBackend(address _backendContract) multisig(sha3(msg.data)) {
     backendContract = _backendContract;
   }
   function setBackendOwner(address _backendContract) onlyOwnerUnlocked {
     backendContract = _backendContract;
   }

    

    
   function balanceOf(address _address) constant returns (uint256 balance) {
      return DVIPBackend(backendContract).balanceOf(_address);
   }

    
   function totalSupply() constant returns (uint256 balance) {
      return DVIPBackend(backendContract).totalSupply();
   }

   
   function transfer(address _to, uint256 _amount) returns (bool success)  {
      if (!DVIPBackend(backendContract).transfer(msg.sender, _to, _amount)) throw;
      Transfer(msg.sender, _to, _amount);
      return true;
   }

   
   function approveAndCall(address _spender, uint256 _amount, bytes _extraData) returns (bool success) {
      if (!DVIPBackend(backendContract).approveAndCall(msg.sender, _spender, _amount, _extraData)) throw;
      Approval(msg.sender, _spender, _amount);
      return true;
   }

   
   function approve(address _spender, uint256 _amount) returns (bool success) {
      if (!DVIPBackend(backendContract).approve(msg.sender, _spender, _amount)) throw;
      Approval(msg.sender, _spender, _amount);
      return true;
   }

   
  function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
      if (!DVIPBackend(backendContract).transferFrom(msg.sender, _from, _to, _amount)) throw;
      Transfer(_from, _to, _amount);
      return true;
  }

   
  function feeFor(address _from, address _to, uint256 _amount) constant returns (uint256 amount) {
      return DVIPBackend(backendContract).feeFor(_from, _to, _amount);
  }

   

  function relayReceiveApproval(address _caller, address _spender, uint256 _amount, bytes _extraData) returns (bool success) {
     assert(msg.sender == backendContract);
     TokenRecipient spender = TokenRecipient(_spender);
     spender.receiveApproval(_caller, _amount, this, _extraData);
     return true;
  }

}