 

pragma solidity ^0.5.0;

 

contract Syndicate {

  mapping (address => uint256) public balances;

  struct Payment {
    address sender;
    address payable receiver;
    uint256 timestamp;
    uint256 time;
    uint256 weiValue;
    uint256 weiPaid;
  }

  Payment[] public payments;

  event PaymentUpdated(uint256 index);
  event PaymentCreated(uint256 index);

   
  function deposit(address payable _receiver, uint256 _time) external payable {
    balances[msg.sender] += msg.value;
    pay(_receiver, msg.value, _time);
  }

   
  function pay(address payable _receiver, uint256 _weiValue, uint256 _time) public {
     
    require(_weiValue <= balances[msg.sender] && _weiValue > 0);
     
    require(_time > 0);
    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: _time,
      weiValue: _weiValue,
      weiPaid: 0
    }));
     
    balances[msg.sender] -= _weiValue;
    emit PaymentCreated(payments.length - 1);
  }

   
  function paymentSettle(uint256 index) public {
    uint256 owedWei = paymentWeiOwed(index);
    balances[payments[index].receiver] += owedWei;
    payments[index].weiPaid += owedWei;
    emit PaymentUpdated(index);
  }

   
  function paymentWeiOwed(uint256 index) public view returns (uint256) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];
     
    return payment.weiValue * min(block.timestamp - payment.timestamp, payment.time) / payment.time - payment.weiPaid;
  }

   
  function isPaymentSettled(uint256 index) public view returns (bool) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];
    return payment.weiValue == payment.weiPaid;
  }

   
  function assertPaymentIndexInRange(uint256 index) public view {
    require(index < payments.length);
  }

   
  function withdraw(address payable target, uint256 weiValue) public {
    require(balances[target] >= weiValue);
    balances[target] -= weiValue;
    target.transfer(weiValue);
  }

   
  function withdraw(address payable target) public {
    withdraw(target, balances[target]);
  }

   
  function withdraw() public {
    withdraw(msg.sender, balances[msg.sender]);
  }

   
  function paymentCount() public view returns (uint) {
    return payments.length;
  }

   
  function min(uint a, uint b) private pure returns (uint) {
    return a < b ? a : b;
  }
}