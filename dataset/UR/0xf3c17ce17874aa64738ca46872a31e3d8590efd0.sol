 

pragma solidity ^0.5.0;

 

contract Syndicate {

  struct Payment {
    address sender;
    address payable receiver;
    uint256 timestamp;
    uint256 time;
    uint256 weiValue;
    uint256 weiPaid;
    bool isFork;
    uint256 parentIndex;
    bool isForked;
    uint256 fork1Index;
    uint256 fork2Index;
  }

  Payment[] public payments;

  event PaymentUpdated(uint256 index);
  event PaymentCreated(uint256 index);

  mapping(address => mapping (address => bool)) public delegates;

   
  function delegate(address _delegate, bool delegated) public {
    delegates[msg.sender][_delegate] = delegated;
  }

   
  function paymentCreate(address payable _receiver, uint256 _time) public payable {
     
    require(msg.value > 0);
     
    require(_time > 0);
    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: _time,
      weiValue: msg.value,
      weiPaid: 0,
      isFork: false,
      parentIndex: 0,
      isForked: false,
      fork1Index: 0,
      fork2Index: 0
    }));
    emit PaymentCreated(payments.length - 1);
  }

   
  function paymentSettle(uint256 index) public {
    requirePaymentIndexInRange(index);
    Payment storage payment = payments[index];
    requireExecutionAllowed(payment.receiver);
    uint256 owedWei = paymentWeiOwed(index);
    payment.weiPaid += owedWei;
    payment.receiver.transfer(owedWei);
    emit PaymentUpdated(index);
  }

   
  function paymentWeiOwed(uint256 index) public view returns (uint256) {
    requirePaymentIndexInRange(index);
    Payment memory payment = payments[index];
     
    return max(payment.weiPaid, payment.weiValue * min(block.timestamp - payment.timestamp, payment.time) / payment.time) - payment.weiPaid;
  }

   
  function paymentFork(uint256 index, address payable _receiver, uint256 _weiValue) public {
    requirePaymentIndexInRange(index);
    Payment storage payment = payments[index];
     
    requireExecutionAllowed(payment.receiver);

    uint256 remainingWei = payment.weiValue - payment.weiPaid;
    uint256 remainingTime = max(0, payment.time - (block.timestamp - payment.timestamp));

     
    require(remainingWei > _weiValue);
    require(_weiValue > 0);

     
     
    payment.weiValue = payment.weiPaid;
    emit PaymentUpdated(index);

    payments.push(Payment({
      sender: payment.receiver,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index,
      isForked: false,
      fork1Index: 0,
      fork2Index: 0
    }));
    payment.fork1Index = payments.length - 1;
    emit PaymentCreated(payments.length - 1);

    payments.push(Payment({
      sender: payment.receiver,
      receiver: payment.receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: remainingWei - _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index,
      isForked: false,
      fork1Index: 0,
      fork2Index: 0
    }));
    payment.fork2Index = payments.length - 1;
    emit PaymentCreated(payments.length - 1);

    payment.isForked = true;
  }

   
  function isPaymentSettled(uint256 index) public view returns (bool) {
    requirePaymentIndexInRange(index);
    return payments[index].weiValue == payments[index].weiPaid;
  }

   
  function requirePaymentIndexInRange(uint256 index) public view {
    require(index < payments.length);
  }

   
  function requireExecutionAllowed(address payable receiver) public view {
    require(msg.sender == receiver || delegates[receiver][msg.sender] == true);
  }

   
  function paymentCount() public view returns (uint) {
    return payments.length;
  }

   
  function min(uint a, uint b) private pure returns (uint) {
    return a < b ? a : b;
  }

   
  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }
}