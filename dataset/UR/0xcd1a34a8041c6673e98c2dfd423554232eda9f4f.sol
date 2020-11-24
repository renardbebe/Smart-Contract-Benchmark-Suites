 

 


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

 

 
contract IMintable {
  function mintingFinished() public view returns (bool);

  function mint(address _to, uint256 _amount) public returns (bool);
  function finishMinting() public returns (bool);
 
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
}

 

 
contract IMintableByLot is IMintable {
  function minterLotId(address _minter) public view returns (uint256);
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

 

 
contract ISeizable {
  function seize(address _account, uint256 _value) public;
  event Seize(address account, uint256 amount);
}

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
contract SeizableToken is BasicToken, Authority, ISeizable {
  using SafeMath for uint256;

   
   
   
  uint256 public allTimeSeized = 0;  

   
  function seize(address _account, uint256 _value)
    public onlyAuthority
  {
    require(_account != owner, "ST01");

    balances[_account] = balances[_account].sub(_value);
    balances[authority] = balances[authority].add(_value);

    allTimeSeized += _value;
    emit Seize(_account, _value);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 

 
contract IProvableOwnership {
  function proofLength(address _holder) public view returns (uint256);
  function proofAmount(address _holder, uint256 _proofId)
    public view returns (uint256);

  function proofDateFrom(address _holder, uint256 _proofId)
    public view returns (uint256);

  function proofDateTo(address _holder, uint256 _proofId)
    public view returns (uint256);

  function createProof(address _holder) public;
  function checkProof(address _holder, uint256 _proofId, uint256 _at)
    public view returns (uint256);

  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
    ) public returns (bool);

  function transferFromWithProofs(
    address _from,
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
    ) public returns (bool);

  event ProofOfOwnership(address indexed holder, uint256 proofId);
}

 

 
contract IAuditableToken {
  function lastTransactionAt(address _address) public view returns (uint256);
  function lastReceivedAt(address _address) public view returns (uint256);
  function lastSentAt(address _address) public view returns (uint256);
  function transactionCount(address _address) public view returns (uint256);
  function receivedCount(address _address) public view returns (uint256);
  function sentCount(address _address) public view returns (uint256);
  function totalReceivedAmount(address _address) public view returns (uint256);
  function totalSentAmount(address _address) public view returns (uint256);
}

 

 
contract AuditableToken is IAuditableToken, StandardToken {

    
    
    
    
  struct Audit {
    uint256 createdAt;
    uint256 lastReceivedAt;
    uint256 lastSentAt;
    uint256 receivedCount;  
    uint256 sentCount;  
    uint256 totalReceivedAmount;  
    uint256 totalSentAmount;  
  }
  mapping(address => Audit) internal audits;

   
  function auditCreatedAt(address _address) public view returns (uint256) {
    return audits[_address].createdAt;
  }

   
  function lastTransactionAt(address _address) public view returns (uint256) {
    return ( audits[_address].lastReceivedAt > audits[_address].lastSentAt ) ?
      audits[_address].lastReceivedAt : audits[_address].lastSentAt;
  }

   
  function lastReceivedAt(address _address) public view returns (uint256) {
    return audits[_address].lastReceivedAt;
  }

   
  function lastSentAt(address _address) public view returns (uint256) {
    return audits[_address].lastSentAt;
  }

   
  function transactionCount(address _address) public view returns (uint256) {
    return audits[_address].receivedCount + audits[_address].sentCount;
  }

   
  function receivedCount(address _address) public view returns (uint256) {
    return audits[_address].receivedCount;
  }

   
  function sentCount(address _address) public view returns (uint256) {
    return audits[_address].sentCount;
  }

   
  function totalReceivedAmount(address _address)
    public view returns (uint256)
  {
    return audits[_address].totalReceivedAmount;
  }

   
  function totalSentAmount(address _address) public view returns (uint256) {
    return audits[_address].totalSentAmount;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (!super.transfer(_to, _value)) {
      return false;
    }
    updateAudit(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool)
  {
    if (!super.transferFrom(_from, _to, _value)) {
      return false;
    }

    updateAudit(_from, _to, _value);
    return true;
  }

  
  function currentTime() internal view returns (uint256) {
     
    return now;
  }

   
  function updateAudit(address _sender, address _receiver, uint256 _value)
    private returns (uint256)
  {
    Audit storage senderAudit = audits[_sender];
    senderAudit.lastSentAt = currentTime();
    senderAudit.sentCount++;
    senderAudit.totalSentAmount += _value;
    if (senderAudit.createdAt == 0) {
      senderAudit.createdAt = currentTime();
    }

    Audit storage receiverAudit = audits[_receiver];
    receiverAudit.lastReceivedAt = currentTime();
    receiverAudit.receivedCount++;
    receiverAudit.totalReceivedAmount += _value;
    if (receiverAudit.createdAt == 0) {
      receiverAudit.createdAt = currentTime();
    }
  }
}

 

 
contract ProvableOwnershipToken is IProvableOwnership, AuditableToken, Ownable {
  struct Proof {
    uint256 amount;
    uint256 dateFrom;
    uint256 dateTo;
  }
  mapping(address => mapping(uint256 => Proof)) internal proofs;
  mapping(address => uint256) internal proofLengths;

   
  function proofLength(address _holder) public view returns (uint256) {
    return proofLengths[_holder];
  }

   
  function proofAmount(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].amount;
  }

   
  function proofDateFrom(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].dateFrom;
  }

   
  function proofDateTo(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].dateTo;
  }

   
  function checkProof(address _holder, uint256 _proofId, uint256 _at)
    public view returns (uint256)
  {
    if (_proofId < proofLengths[_holder]) {
      Proof storage proof = proofs[_holder][_proofId];

      if (proof.dateFrom <= _at && _at <= proof.dateTo) {
        return proof.amount;
      }
    }
    return 0;
  }

   
  function createProof(address _holder) public {
    createProofInternal(
      _holder,
      balanceOf(_holder),
      lastTransactionAt(_holder)
    );
  }

   
  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofSender,
    bool _proofReceiver
  ) public returns (bool)
  {
    uint256 balanceBeforeFrom = balanceOf(msg.sender);
    uint256 beforeFrom = lastTransactionAt(msg.sender);
    uint256 balanceBeforeTo = balanceOf(_to);
    uint256 beforeTo = lastTransactionAt(_to);

    if (!super.transfer(_to, _value)) {
      return false;
    }

    transferPostProcessing(
      msg.sender,
      balanceBeforeFrom,
      beforeFrom,
      _proofSender
    );
    transferPostProcessing(
      _to,
      balanceBeforeTo,
      beforeTo,
      _proofReceiver
    );
    return true;
  }

   
  function transferFromWithProofs(
    address _from,
    address _to, 
    uint256 _value,
    bool _proofSender, bool _proofReceiver)
    public returns (bool)
  {
    uint256 balanceBeforeFrom = balanceOf(_from);
    uint256 beforeFrom = lastTransactionAt(_from);
    uint256 balanceBeforeTo = balanceOf(_to);
    uint256 beforeTo = lastTransactionAt(_to);

    if (!super.transferFrom(_from, _to, _value)) {
      return false;
    }

    transferPostProcessing(
      _from,
      balanceBeforeFrom,
      beforeFrom,
      _proofSender
    );
    transferPostProcessing(
      _to,
      balanceBeforeTo,
      beforeTo,
      _proofReceiver
    );
    return true;
  }

   
  function createProofInternal(
    address _holder, uint256 _amount, uint256 _from) internal
  {
    uint proofId = proofLengths[_holder];
     
    proofs[_holder][proofId] = Proof(_amount, _from, currentTime());
    proofLengths[_holder] = proofId+1;
    emit ProofOfOwnership(_holder, proofId);
  }

   
  function transferPostProcessing(
    address _holder,
    uint256 _balanceBefore,
    uint256 _before,
    bool _proof) private
  {
    if (_proof) {
      createProofInternal(_holder, _balanceBefore, _before);
    }
  }

  event ProofOfOwnership(address indexed holder, uint256 proofId);
}

 

 
interface IClaimable {
  function hasClaimsSince(address _address, uint256 at)
    external view returns (bool);
}

 

 
contract IWithClaims {
  function claimableLength() public view returns (uint256);
  function claimable(uint256 _claimableId) public view returns (IClaimable);
  function hasClaims(address _holder) public view returns (bool);
  function defineClaimables(IClaimable[] _claimables) public;

  event ClaimablesDefined(uint256 count);
}

 

 
contract TokenWithClaims is IWithClaims, ProvableOwnershipToken {

  IClaimable[] claimables;

   
  constructor(IClaimable[] _claimables) public {
    claimables = _claimables;
  }

   
  function claimableLength() public view returns (uint256) {
    return claimables.length;
  }

   
  function claimable(uint256 _claimableId) public view returns (IClaimable) {
    return claimables[_claimableId];
  }

   
  function hasClaims(address _holder) public view returns (bool) {
    uint256 lastTransaction = lastTransactionAt(_holder);
    for (uint256 i = 0; i < claimables.length; i++) {
      if (claimables[i].hasClaimsSince(_holder, lastTransaction)) {
        return true;
      }
    }
    return false;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    bool proofFrom = hasClaims(msg.sender);
    bool proofTo = hasClaims(_to);

    return super.transferWithProofs(
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool)
  {
    bool proofFrom = hasClaims(_from);
    bool proofTo = hasClaims(_to);

    return super.transferFromWithProofs(
      _from,
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

   
  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
  ) public returns (bool)
  {
    bool proofFrom = _proofFrom || hasClaims(msg.sender);
    bool proofTo = _proofTo || hasClaims(_to);

    return super.transferWithProofs(
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

   
  function transferFromWithProofs(
    address _from,
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
  ) public returns (bool)
  {
    bool proofFrom = _proofFrom || hasClaims(_from);
    bool proofTo = _proofTo || hasClaims(_to);

    return super.transferFromWithProofs(
      _from,
      _to,
      _value,
      proofFrom,
      proofTo
    );
  }

   
  function defineClaimables(IClaimable[] _claimables) public onlyOwner {
    claimables = _claimables;
    emit ClaimablesDefined(claimables.length);
  }
}

 

 
interface IRule {
  function isAddressValid(address _address) external view returns (bool);
  function isTransferValid(address _from, address _to, uint256 _amount)
    external view returns (bool);
}

 

 
contract IWithRules {
  function ruleLength() public view returns (uint256);
  function rule(uint256 _ruleId) public view returns (IRule);
  function validateAddress(address _address) public view returns (bool);
  function validateTransfer(address _from, address _to, uint256 _amount)
    public view returns (bool);

  function defineRules(IRule[] _rules) public;

  event RulesDefined(uint256 count);
}

 

 
contract WithRules is IWithRules, Ownable {

  IRule[] internal rules;

   
  constructor(IRule[] _rules) public {
    rules = _rules;
  }

   
  function ruleLength() public view returns (uint256) {
    return rules.length;
  }

   
  function rule(uint256 _ruleId) public view returns (IRule) {
    return rules[_ruleId];
  }

   
  function validateAddress(address _address) public view returns (bool) {
    for (uint256 i = 0; i < rules.length; i++) {
      if (!rules[i].isAddressValid(_address)) {
        return false;
      }
    }
    return true;
  }

   
  function validateTransfer(address _from, address _to, uint256 _amount)
    public view returns (bool)
  {
    for (uint256 i = 0; i < rules.length; i++) {
      if (!rules[i].isTransferValid(_from, _to, _amount)) {
        return false;
      }
    }
    return true;
  }

   
  modifier whenAddressRulesAreValid(address _address) {
    require(validateAddress(_address), "WR01");
    _;
  }

   
  modifier whenTransferRulesAreValid(
    address _from,
    address _to,
    uint256 _amount)
  {
    require(validateTransfer(_from, _to, _amount), "WR02");
    _;
  }

   
  function defineRules(IRule[] _rules) public onlyOwner {
    rules = _rules;
    emit RulesDefined(rules.length);
  }
}

 

 
contract TokenWithRules is StandardToken, WithRules {

   
  constructor(IRule[] _rules) public WithRules(_rules) { }

   
  function transfer(address _to, uint256 _value)
    public whenTransferRulesAreValid(msg.sender, _to, _value)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
    public whenTransferRulesAreValid(_from, _to, _value)
    whenAddressRulesAreValid(msg.sender)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }
}

 

 
contract BridgeToken is TokenWithRules, TokenWithClaims, SeizableToken {
  string public name;
  string public symbol;

   
  constructor(string _name, string _symbol) 
    TokenWithRules(new IRule[](0))
    TokenWithClaims(new IClaimable[](0)) public
  {
    name = _name;
    symbol = _symbol;
  }
}

 

 
contract MintableToken is StandardToken, Ownable, IMintable {

  bool public mintingFinished = false;

  function mintingFinished() public view returns (bool) {
    return mintingFinished;
  }

  modifier canMint() {
    require(!mintingFinished, "MT01");
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  ) public canMint onlyOwner returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public canMint onlyOwner returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
}

 

 
contract MintableBridgeToken is BridgeToken, MintableToken {

  string public name;
  string public symbol;

   
  constructor(string _name, string _symbol)
    BridgeToken(_name, _symbol) public
  {
    name = _name;
    symbol = _symbol;
  }
}

 

 
contract ISaleConfig {

  struct Tokensale {
    uint256 lotId;
    uint256 tokenPriceCHFCent;
  }

  function tokenSupply() public pure returns (uint256);
  function tokensaleLotSupplies() public view returns (uint256[]);

  function tokenizedSharePercent() public pure returns (uint256); 
  function tokenPriceCHF() public pure returns (uint256);

  function minimalCHFInvestment() public pure returns (uint256);
  function maximalCHFInvestment() public pure returns (uint256);

  function tokensalesCount() public view returns (uint256);
  function lotId(uint256 _tokensaleId) public view returns (uint256);
  function tokenPriceCHFCent(uint256 _tokensaleId)
    public view returns (uint256);
}

 

 
contract TokenMinter is IMintableByLot, Ownable {
  using SafeMath for uint256;

  struct MintableLot {
    uint256 mintableSupply;
    address vault;
    mapping(address => bool) minters;
    uint8 activeMinters;
  }

  MintableLot[] private mintableLots;
  mapping(address => uint256) public minterLotIds;

  uint256 public totalMintableSupply;
  address public finalTokenOwner;

  uint8 public activeLots;

  ISaleConfig public config;
  MintableBridgeToken public token;

   
  constructor(
    ISaleConfig _config,
    address _finalTokenOwner,
    address[] _vaults) public
  {
    require(address(_config) != 0, "TM01");
    require(_finalTokenOwner != 0, "TM02");

    uint256[] memory lots = _config.tokensaleLotSupplies();
    require(lots.length > 0, "TM03");
    require(_vaults.length == lots.length, "TM04");

    config = _config;
    finalTokenOwner = _finalTokenOwner;

    for (uint256 i = 0; i < lots.length; i++) {
      require(_vaults[i] != 0, "TM05");
      uint256 mintableSupply = lots[i];
      mintableLots.push(MintableLot(mintableSupply, _vaults[i], 0));
      totalMintableSupply = totalMintableSupply.add(mintableSupply);
      activeLots++;
      emit LotCreated(i+1, mintableSupply);
    }
  }

   
  function minterLotId(address _minter) public view returns (uint256) {
    return minterLotIds[_minter];
  }

   
  function lotMintableSupply(uint256 _lotId) public view returns (uint256) {
    return mintableLots[_lotId].mintableSupply;
  }

   
  function lotVault(uint256 _lotId) public view returns (address) {
    return mintableLots[_lotId].vault;
  }

   
  function isLotMinter(uint256 _lotId, address _minter)
    public view returns (bool)
  {
    return mintableLots[_lotId].minters[_minter];
  }

   
  function lotActiveMinters(uint256 _lotId) public view returns (uint256) {
    return mintableLots[_lotId].activeMinters;
  }

   
  function mintingFinished() public view returns (bool) {
    return token.mintingFinished();
  }

   
  function setup(MintableBridgeToken _token, address[] _minters)
    public onlyOwner
  {
    require(address(_token) != 0, "TM06");
    require(address(token) == 0, "TM07");
     
     
    require(_token.owner() == address(this), "TM08");
    token = _token;
    
     
    require(token.totalSupply() == 0, "TM09");
    require(!token.mintingFinished(), "TM10");
    
    require(_minters.length == config.tokensalesCount(), "TM11");
    for (uint256 i = 0; i < _minters.length; i++) {
      if (_minters[i] != address(0)) {
        setupMinter(_minters[i], i);
      }
    }
  }

   
  function setupMinter(address _minter, uint256 _tokensaleId)
    public onlyOwner
  {
    uint256 lotId = config.lotId(_tokensaleId);
    require(lotId < mintableLots.length, "TM12");
    MintableLot storage lot = mintableLots[lotId];
    require(!lot.minters[_minter], "TM13");
    lot.minters[_minter] = true;
    lot.activeMinters++;
    minterLotIds[_minter] = lotId;
    emit MinterAdded(lotId, _minter);
  }

   
  function mint(address _to, uint256 _amount)
    public returns (bool)
  {
    require(address(token) != 0, "TM14");
    require(_amount > 0, "TM15");
    
    uint256 lotId = minterLotIds[msg.sender];
    MintableLot storage lot = mintableLots[lotId];

    require(lot.mintableSupply >= _amount, "TM16");

    lot.mintableSupply = lot.mintableSupply.sub(_amount);
    totalMintableSupply = totalMintableSupply.sub(_amount);
    return token.mint(_to, _amount);
  }

   
  function finishMinting() public returns (bool) {
    return finishMintingInternal(msg.sender);
  }

   
  function finishMintingRestricted(address _minter)
    public onlyOwner returns (bool)
  {
    return finishMintingInternal(_minter);
  }

   
  function finishMintingInternal(address _minter)
    public returns (bool)
  {
    uint256 lotId = minterLotIds[_minter];
    MintableLot storage lot = mintableLots[lotId];
    require(lot.minters[_minter], "TM17");

    lot.minters[_minter] = false;
    lot.activeMinters--;

    if (lot.activeMinters == 0 && lot.mintableSupply == 0) {
      finishLotMintingPrivate(lotId);
    }
    return true;
  }

   
  function mintRemainingLot(uint256 _lotId)
    public returns (bool)
  {
    MintableLot storage lot = mintableLots[_lotId];
    require(lot.activeMinters == 0, "TM18");
    require(lot.mintableSupply > 0, "TM19");

    require(token.mint(lot.vault, lot.mintableSupply), "TM20");
    totalMintableSupply = totalMintableSupply.sub(lot.mintableSupply);
    lot.mintableSupply = 0;
 
    finishLotMintingPrivate(_lotId);
    return true;
  }

   
  function mintAllRemaining() public onlyOwner returns (bool) {
    require(!token.mintingFinished(), "TM21");
    require(activeLots > 0, "TM22");
   
    if (totalMintableSupply > 0) {
      for (uint256 i = 0; i < mintableLots.length; i++) {
        MintableLot storage lot = mintableLots[i];
        if (lot.mintableSupply > 0) {
          mintRemainingLot(i);
        }
      }
    }
    return true;
  }

   
  function finishTokenMinting() public onlyOwner returns (bool) {
    require(totalMintableSupply == 0, "TM23");
    require(!token.mintingFinished(), "TM24");
    require(token.finishMinting(), "TM25");
    
    require(token.mintingFinished(), "TM26");
    token.transferOwnership(finalTokenOwner);
    emit TokenReleased();
  }

   
  function finishLotMintingPrivate(uint256 _lotId) private {
    activeLots--;
    emit LotMinted(_lotId);
  }

  event LotCreated(uint256 lotId, uint256 tokenSupply);
  event MinterAdded(uint256 lotId, address minter);
  event LotMinted(uint256 lotId);
  event TokenReleased();
}