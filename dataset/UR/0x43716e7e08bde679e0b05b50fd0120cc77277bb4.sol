 

pragma solidity ^0.4.24;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
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

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract MintableToken is StandardToken, Ownable {
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
contract Escrow is Ownable {
  using SafeMath for uint256;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private deposits;

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

   
  function deposit(address _payee) public onlyOwner payable {
    uint256 amount = msg.value;
    deposits[_payee] = deposits[_payee].add(amount);

    emit Deposited(_payee, amount);
  }

   
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(address(this).balance >= payment);

    deposits[_payee] = 0;

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);
  }
}

 

 
contract ConditionalEscrow is Escrow {
   
  function withdrawalAllowed(address _payee) public view returns (bool);

  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee));
    super.withdraw(_payee);
  }
}

 

 
contract RefundEscrow is Ownable, ConditionalEscrow {
  enum State { Active, Refunding, Closed }

  event Closed();
  event RefundsEnabled();

  State public state;
  address public beneficiary;

   
  constructor(address _beneficiary) public {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    state = State.Active;
  }

   
  function deposit(address _refundee) public payable {
    require(state == State.Active);
    super.deposit(_refundee);
  }

   
  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
  }

   
  function enableRefunds() public onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function beneficiaryWithdraw() public {
    require(state == State.Closed);
    beneficiary.transfer(address(this).balance);
  }

   
  function withdrawalAllowed(address _payee) public view returns (bool) {
    return state == State.Refunding;
  }
}

 

 
contract ClinicAllRefundEscrow is RefundEscrow {
  using Math for uint256;

  struct RefundeeRecord {
    bool isRefunded;
    uint256 index;
  }

  mapping(address => RefundeeRecord) public refundees;
  address[] internal refundeesList;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private deposits;
  mapping(address => uint256) private beneficiaryDeposits;

   
  uint256 public beneficiaryDepositedAmount;

   
  uint256 public investorsDepositedToCrowdSaleAmount;

   
  constructor(address _beneficiary)
  RefundEscrow(_beneficiary)
  public {
  }

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

  function beneficiaryDepositsOf(address _payee) public view returns (uint256) {
    return beneficiaryDeposits[_payee];
  }



   
  function deposit(address _refundee) public payable {
    uint256 amount = msg.value;
    beneficiaryDeposits[_refundee] = beneficiaryDeposits[_refundee].add(amount);
    beneficiaryDepositedAmount = beneficiaryDepositedAmount.add(amount);
  }

   
  function depositFunds(address _refundee, uint256 _value) public onlyOwner {
    require(state == State.Active, "Funds deposition is possible only in the Active state.");

    uint256 amount = _value;
    deposits[_refundee] = deposits[_refundee].add(amount);
    investorsDepositedToCrowdSaleAmount = investorsDepositedToCrowdSaleAmount.add(amount);

    emit Deposited(_refundee, amount);

    RefundeeRecord storage _data = refundees[_refundee];
    _data.isRefunded = false;

    if (_data.index == uint256(0)) {
      refundeesList.push(_refundee);
      _data.index = refundeesList.length.sub(1);
    }
  }

   
  function close() public onlyOwner {
    super.close();
  }

  function withdraw(address _payee) public onlyOwner {
    require(state == State.Refunding, "Funds withdrawal is possible only in the Refunding state.");
    require(depositsOf(_payee) > 0, "An investor should have non-negative deposit for withdrawal.");

    RefundeeRecord storage _data = refundees[_payee];
    require(_data.isRefunded == false, "An investor should not be refunded.");

    uint256 payment = deposits[_payee];
    assert(address(this).balance >= payment);

    deposits[_payee] = 0;

    investorsDepositedToCrowdSaleAmount = investorsDepositedToCrowdSaleAmount.sub(payment);

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);

    _data.isRefunded = true;

    removeRefundeeByIndex(_data.index);
  }

   
  function manualRefund(address _payee) public onlyOwner {
    RefundeeRecord storage _data = refundees[_payee];

    deposits[_payee] = 0;
    _data.isRefunded = true;

    removeRefundeeByIndex(_data.index);
  }

   
  function removeRefundeeByIndex(uint256 _indexToDelete) private {
    if ((refundeesList.length > 0) && (_indexToDelete < refundeesList.length)) {
      uint256 _lastIndex = refundeesList.length.sub(1);
      refundeesList[_indexToDelete] = refundeesList[_lastIndex];
      refundeesList.length--;
    }
  }
   
  function refundeesListLength() public onlyOwner view returns (uint256) {
    return refundeesList.length;
  }

   
  function withdrawChunk(uint256 _txFee, uint256 _chunkLength) public onlyOwner returns (uint256, address[]) {
    require(state == State.Refunding, "Funds withdrawal is possible only in the Refunding state.");

    uint256 _refundeesCount = refundeesList.length;
    require(_chunkLength >= _refundeesCount);
    require(_txFee > 0, "Transaction fee should be above zero.");
    require(_refundeesCount > 0, "List of investors should not be empty.");
    uint256 _weiRefunded = 0;
    require(address(this).balance > (_chunkLength.mul(_txFee)), "Account's ballance should allow to pay all tx fees.");
    address[] memory _refundeesListCopy = new address[](_chunkLength);

    uint256 i;
    for (i = 0; i < _chunkLength; i++) {
      address _refundee = refundeesList[i];
      RefundeeRecord storage _data = refundees[_refundee];
      if (_data.isRefunded == false) {
        if (depositsOf(_refundee) > _txFee) {
          uint256 _deposit = depositsOf(_refundee);
          if (_deposit > _txFee) {
            _weiRefunded = _weiRefunded.add(_deposit);
            uint256 _paymentWithoutTxFee = _deposit.sub(_txFee);
            _refundee.transfer(_paymentWithoutTxFee);
            emit Withdrawn(_refundee, _paymentWithoutTxFee);
            _data.isRefunded = true;
            _refundeesListCopy[i] = _refundee;
          }
        }
      }
    }

    for (i = 0; i < _chunkLength; i++) {
      if (address(0) != _refundeesListCopy[i]) {
        RefundeeRecord storage _dataCleanup = refundees[_refundeesListCopy[i]];
        require(_dataCleanup.isRefunded == true, "Investors in this list should be refunded.");
        removeRefundeeByIndex(_dataCleanup.index);
      }
    }

    return (_weiRefunded, _refundeesListCopy);
  }

   
  function withdrawEverything(uint256 _txFee) public onlyOwner returns (uint256, address[]) {
    require(state == State.Refunding, "Funds withdrawal is possible only in the Refunding state.");
    return withdrawChunk(_txFee, refundeesList.length);
  }

   
  function beneficiaryWithdrawChunk(uint256 _value) public onlyOwner {
    require(_value <= address(this).balance, "Withdraw part can not be more than current balance");
    beneficiaryDepositedAmount = beneficiaryDepositedAmount.sub(_value);
    beneficiary.transfer(_value);
  }

   
  function beneficiaryWithdrawAll() public onlyOwner {
    uint256 _value = address(this).balance;
    beneficiaryDepositedAmount = beneficiaryDepositedAmount.sub(_value);
    beneficiary.transfer(_value);
  }

}

 

 
contract TokenDestructible is Ownable {

  constructor() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
contract TransferableToken is Ownable {
  event TransferOn();
  event TransferOff();

  bool public transferable = false;

   
  modifier whenNotTransferable() {
    require(!transferable);
    _;
  }

   
  modifier whenTransferable() {
    require(transferable);
    _;
  }

   
  function transferOn() onlyOwner whenNotTransferable public {
    transferable = true;
    emit TransferOn();
  }

   
  function transferOff() onlyOwner whenTransferable public {
    transferable = false;
    emit TransferOff();
  }

}

 

contract ClinicAllToken is MintableToken, DetailedERC20, CappedToken, PausableToken, BurnableToken, TokenDestructible, TransferableToken {
  constructor
  (
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _cap
  )
  DetailedERC20(_name, _symbol, _decimals)
  CappedToken(_cap)
  public
  {

  }

   
  function burnAfterRefund(address _who) public onlyOwner {
    uint256 _value = balances[_who];
    _burn(_who, _value);
  }

   
  function transfer(
    address _to,
    uint256 _value
  )
  public
  whenTransferable
  returns (bool)
  {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  whenTransferable
  returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function transferToPrivateInvestor(
    address _from,
    address _to,
    uint256 _value
  )
  public
  onlyOwner
  returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function burnPrivateSale(address privateSaleWallet, uint256 _value) public onlyOwner {
    _burn(privateSaleWallet, _value);
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

 

 
contract Managed is Ownable, RBAC {
  string public constant ROLE_MANAGER = "manager";

   
  modifier onlyManager() {
    checkRole(msg.sender, ROLE_MANAGER);
    _;
  }

   
  function setManager(address _operator) public onlyOwner {
    addRole(_operator, ROLE_MANAGER);
  }

   
  function removeManager(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_MANAGER);
  }
}

 

 
contract Limited is Managed {
  using SafeMath for uint256;
  mapping(address => uint256) public limitsList;

   
  modifier isLimited(address _payee) {
    require(limitsList[_payee] > 0, "An investor is limited if it has a limit.");
    _;
  }


   
  modifier doesNotExceedLimit(address _payee, uint256 _tokenAmount, uint256 _tokenBalance, uint256 kycLimitEliminator) {
    if(_tokenBalance.add(_tokenAmount) >= kycLimitEliminator) {
      require(_tokenBalance.add(_tokenAmount) <= getLimit(_payee), "An investor should not exceed its limit on buying.");
    }
    _;
  }

   
  function getLimit(address _payee)
  public view returns (uint256)
  {
    return limitsList[_payee];
  }

   
  function addAddressesLimits(address[] _payees, uint256[] _limits) public
  onlyManager
  {
    require(_payees.length == _limits.length, "Array sizes should be equal.");
    for (uint256 i = 0; i < _payees.length; i++) {
      addLimit(_payees[i], _limits[i]);
    }
  }


   
  function addLimit(address _payee, uint256 _limit) public
  onlyManager
  {
    limitsList[_payee] = _limit;
  }


   
  function removeLimit(address _payee) external
  onlyManager
  {
    limitsList[_payee] = 0;
  }

}

 

 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

 
contract ManagedWhitelist is Managed, Whitelist {
   
  function addAddressToWhitelist(address _operator) public onlyManager {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators) public onlyManager {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator) public onlyManager {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators) public onlyManager {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }
}

 

 
 
contract ClinicAllCrowdsale is Crowdsale, FinalizableCrowdsale, MintedCrowdsale, ManagedWhitelist, Limited {
  constructor
  (
    uint256 _tokenLimitSupply,
    uint256 _rate,
    address _wallet,
    address _privateSaleWallet,
    ERC20 _token,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _discountTokenAmount,
    uint256 _discountTokenPercent,
    uint256 _preSaleClosingTime,
    uint256 _softCapLimit,
    ClinicAllRefundEscrow _vault,
    uint256 _buyLimitSupplyMin,
    uint256 _buyLimitSupplyMax,
    uint256 _kycLimitEliminator
  )
  Crowdsale(_rate, _wallet, _token)
  TimedCrowdsale(_openingTime, _closingTime)
  public
  {
    privateSaleWallet = _privateSaleWallet;
    tokenSupplyLimit = _tokenLimitSupply;
    discountTokenAmount = _discountTokenAmount;
    discountTokenPercent = _discountTokenPercent;
    preSaleClosingTime = _preSaleClosingTime;
    softCapLimit = _softCapLimit;
    vault = _vault;
    buyLimitSupplyMin = _buyLimitSupplyMin;
    buyLimitSupplyMax = _buyLimitSupplyMax;
    kycLimitEliminator = _kycLimitEliminator;
  }

  using SafeMath for uint256;

   
  ClinicAllRefundEscrow public vault;

   
   
   
  uint256 public tokenSupplyLimit;
   
  uint256 public discountTokenAmount;
   
  uint256 public discountTokenPercent;
   
  uint256 public preSaleClosingTime;
   
  uint256 public softCapLimit;
   
  uint256 public buyLimitSupplyMin;
   
  uint256 public buyLimitSupplyMax;
   
  uint256 public kycLimitEliminator;
   
  address public privateSaleWallet;
   
  uint256 public privateSaleSupplyLimit;

   

   
  function updateRate(uint256 _rate) public
  onlyManager
  {
    require(_rate != 0, "Exchange rate should not be 0.");
    rate = _rate;
  }

   
  function updateBuyLimitRange(uint256 _min, uint256 _max) public
  onlyOwner
  {
    require(_min != 0, "Minimal buy limit should not be 0.");
    require(_max != 0, "Maximal buy limit should not be 0.");
    require(_max > _min, "Maximal buy limit should be greater than minimal buy limit.");
    buyLimitSupplyMin = _min;
    buyLimitSupplyMax = _max;
  }

   
  function updateKycLimitEliminator(uint256 _value) public
  onlyOwner
  {
    require(_value != 0, "Kyc Eliminator should not be 0.");
    kycLimitEliminator = _value;
  }

   
  function claimRefund() public {
    require(isFinalized, "Claim refunds is only possible if the ICO is finalized.");
    require(!goalReached(), "Claim refunds is only possible if the soft cap goal has not been reached.");
    uint256 deposit = vault.depositsOf(msg.sender);
    vault.withdraw(msg.sender);
    weiRaised = weiRaised.sub(deposit);
    ClinicAllToken(token).burnAfterRefund(msg.sender);
  }

   
  function claimRefundChunk(uint256 _txFee, uint256 _chunkLength) public onlyOwner {
    require(isFinalized, "Claim refunds is only possible if the ICO is finalized.");
    require(!goalReached(), "Claim refunds is only possible if the soft cap goal has not been reached.");
    uint256 _weiRefunded;
    address[] memory _refundeesList;
    (_weiRefunded, _refundeesList) = vault.withdrawChunk(_txFee, _chunkLength);
    weiRaised = weiRaised.sub(_weiRefunded);
    for (uint256 i = 0; i < _refundeesList.length; i++) {
      ClinicAllToken(token).burnAfterRefund(_refundeesList[i]);
    }
  }


   
  function refundeesListLength() public onlyOwner view returns (uint256) {
    return vault.refundeesListLength();
  }

   
  function hasClosed() public view returns (bool) {
    return ((block.timestamp > closingTime) || tokenSupplyLimit <= token.totalSupply());
  }

   
  function goalReached() public view returns (bool) {
    return token.totalSupply() >= softCapLimit;
  }

   
  function supplyRest() public view returns (uint256) {
    return (tokenSupplyLimit.sub(token.totalSupply()));
  }

   

  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
  internal
  doesNotExceedLimit(_beneficiary, _tokenAmount, token.balanceOf(_beneficiary), kycLimitEliminator)
  {
    super._processPurchase(_beneficiary, _tokenAmount);
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
  internal
  onlyIfWhitelisted(_beneficiary)
  isLimited(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 tokens = _getTokenAmount(_weiAmount);
    require(tokens.add(token.totalSupply()) <= tokenSupplyLimit, "Total amount fo sold tokens should not exceed the total supply limit.");
    require(tokens >= buyLimitSupplyMin, "An investor can buy an amount of tokens only above the minimal limit.");
    require(tokens.add(token.balanceOf(_beneficiary)) <= buyLimitSupplyMax, "An investor cannot buy tokens above the maximal limit.");
  }

   
  function _getTokenAmount(uint256 _weiAmount)
  internal view returns (uint256)
  {
    if (isDiscount()) {
      return _getTokensWithDiscount(_weiAmount);
    }
    return _weiAmount.mul(rate);
  }
   
  function getTokenAmount(uint256 _weiAmount)
  public view returns (uint256)
  {
    return _getTokenAmount(_weiAmount);
  }

   
  function _getTokensWithDiscount(uint256 _weiAmount)
  internal view returns (uint256)
  {
    uint256 tokens = 0;
    uint256 restOfDiscountTokens = discountTokenAmount.sub(token.totalSupply());
    uint256 discountTokensMax = _getDiscountTokenAmount(_weiAmount);
    if (restOfDiscountTokens < discountTokensMax) {
      uint256 discountTokens = restOfDiscountTokens;
       
      uint256 _rate = _getDiscountRate();
      uint256 _discointWeiAmount = discountTokens.div(_rate);
      uint256 _restOfWeiAmount = _weiAmount.sub(_discointWeiAmount);
      uint256 normalTokens = _restOfWeiAmount.mul(rate);
      tokens = discountTokens.add(normalTokens);
    } else {
      tokens = discountTokensMax;
    }

    return tokens;
  }

   
  function _getDiscountTokenAmount(uint256 _weiAmount)
  internal view returns (uint256)
  {
    require(_weiAmount != 0, "It should be possible to buy tokens only by providing non zero ETH.");
    uint256 _rate = _getDiscountRate();
    return _weiAmount.mul(_rate);
  }

   
  function _getDiscountRate()
  internal view returns (uint256)
  {
    require(isDiscount(), "Getting discount rate should be possible only below the discount tokens limit.");
    return rate.add(rate.mul(discountTokenPercent).div(100));
  }

   
  function getRate()
  public view returns (uint256)
  {
    if (isDiscount()) {
      return _getDiscountRate();
    }

    return rate;
  }

   
  function isDiscount()
  public view returns (bool)
  {
    return (preSaleClosingTime >= block.timestamp);
  }

   

  function transferTokensToReserve(address _beneficiary) private
  {
    require(tokenSupplyLimit < CappedToken(token).cap(), "Token's supply limit should be less that token' cap limit.");
     
    uint256 _tokenCap = CappedToken(token).cap();
    uint256 tokens = _tokenCap.sub(tokenSupplyLimit);

    _deliverTokens(_beneficiary, tokens);
  }

   
  function transferOn() public onlyOwner
  {
    ClinicAllToken(token).transferOn();
  }

   
  function transferOff() public onlyOwner
  {
    ClinicAllToken(token).transferOff();
  }

   
  function finalization() internal {
    if (goalReached()) {
      transferTokensToReserve(wallet);
      vault.close();
    } else {
      vault.enableRefunds();
    }
    MintableToken(token).finishMinting();
    super.finalization();
  }

   
  function _forwardFunds() internal {
    super._forwardFunds();
    vault.depositFunds(msg.sender, msg.value);
  }

   
  modifier onlyPrivateSaleWallet() {
    require(privateSaleWallet == msg.sender, "Wallet should be the same as private sale wallet.");
    _;
  }

   
  function transferToPrivateInvestor(
    address _beneficiary,
    uint256 _value
  )
  public
  onlyPrivateSaleWallet
  onlyIfWhitelisted(_beneficiary)
  returns (bool)
  {
    ClinicAllToken(token).transferToPrivateInvestor(msg.sender, _beneficiary, _value);
  }

   
  function redeemPrivateSaleFunds()
  public
  onlyPrivateSaleWallet
  {
    uint256 _balance = ClinicAllToken(token).balanceOf(msg.sender);
    privateSaleSupplyLimit = privateSaleSupplyLimit.sub(_balance);
    ClinicAllToken(token).burnPrivateSale(msg.sender, _balance);
  }

   
  function allocatePrivateSaleFunds(uint256 privateSaleSupplyAmount) public onlyOwner
  {
    require(privateSaleSupplyLimit.add(privateSaleSupplyAmount) < tokenSupplyLimit, "Token's private sale supply limit should be less that token supply limit.");
    privateSaleSupplyLimit = privateSaleSupplyLimit.add(privateSaleSupplyAmount);
    _deliverTokens(privateSaleWallet, privateSaleSupplyAmount);
  }

   
  function beneficiaryWithdrawChunk(uint256 _value) public onlyOwner {
    vault.beneficiaryWithdrawChunk(_value);
  }

   
  function beneficiaryWithdrawAll() public onlyOwner {
    vault.beneficiaryWithdrawAll();
  }

   
  function manualRefund(address _payee) public onlyOwner {

    uint256 deposit = vault.depositsOf(_payee);
    vault.manualRefund(_payee);
    weiRaised = weiRaised.sub(deposit);
    ClinicAllToken(token).burnAfterRefund(_payee);
  }

}