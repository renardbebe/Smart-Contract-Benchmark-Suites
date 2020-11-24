 

 

pragma solidity ^0.4.16;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Presale {
  using SafeMath for uint256;

  mapping (address => uint256) public balances;

   
  uint256 public minGoal;
   
  uint256 public maxGoal;
   
  uint256 public startTime;
   
  uint256 public endTime;
   
  address public projectWallet;

  uint256 private totalRaised;

  function Presale(
    uint256 _minGoal,
    uint256 _maxGoal,
    uint256 _startTime,
    uint256 _endTime,
    address _projectWallet
  )
  {
    require(_minGoal > 0);
    require(_endTime > _startTime);
    require(_projectWallet != address(0x0));
    require(_maxGoal > _minGoal);

    minGoal = _minGoal;
    maxGoal = _maxGoal;
    startTime = _startTime;
    endTime = _endTime;
    projectWallet = _projectWallet;
  }

  function transferToProjectWallet() {
     
    require(this.balance > 0);
     
    require(totalRaised >= minGoal);
    if(!projectWallet.send(this.balance)) {
      revert();
    }
  }

  function refund() {
     
    require(now > endTime);
     
    require(totalRaised < minGoal);
     
    require(now < (endTime + 60 days));
    uint256 amount = balances[msg.sender];
     
    require(amount > 0);
     
    balances[msg.sender] = 0;
    if (!msg.sender.send(amount)) {
      revert();
    }
  }

  function transferRemaining() {
     
    require(totalRaised < minGoal);
     
    require(now >= (endTime + 60 days));
     
    require(this.balance > 0);
    projectWallet.transfer(this.balance);
  }

  function () payable {
     
    require(msg.value > 0);
     
    require(now >= startTime);
     
    require(now <= endTime);
     
    require(totalRaised < maxGoal);

     
     
     
    if (totalRaised.add(msg.value) > maxGoal) {
      var refundAmount = totalRaised + msg.value - maxGoal;
      if (!msg.sender.send(refundAmount)) {
        revert();
      }
      var raised = maxGoal - totalRaised;
      balances[msg.sender] = balances[msg.sender].add(raised);
      totalRaised = totalRaised.add(raised);
    } else {
       
      balances[msg.sender] = balances[msg.sender].add(msg.value);
      totalRaised = totalRaised.add(msg.value);
    }
  }
}

contract OpenMoneyPresale is Presale {
  function OpenMoneyPresale() Presale(83.33 ether,
                                      2000 ether,
                                      1505649600,
                                      1505995200,
                                      address(0x2a00BFd8379786ADfEbb6f2F59011535a4f8d4E4))
                                      {}

}