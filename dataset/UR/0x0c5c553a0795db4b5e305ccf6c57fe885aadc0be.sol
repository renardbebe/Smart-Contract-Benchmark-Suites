 

pragma solidity ^0.4.24;

 

 
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
  address[] public refundeesList;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public beneficiaryDeposits;

   
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
    uint256 payment = deposits[_payee];
    RefundeeRecord storage _data = refundees[_payee];

    investorsDepositedToCrowdSaleAmount = investorsDepositedToCrowdSaleAmount.sub(payment);
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

   
  function beneficiaryWithdraw() public {
     
     
     
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