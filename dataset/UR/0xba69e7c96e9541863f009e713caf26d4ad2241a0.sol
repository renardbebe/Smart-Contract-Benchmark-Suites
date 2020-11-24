 

 

contract Managed {

  address public currentManager;

  function Managed() {
    currentManager = msg.sender;
  }

  modifier onlyManager {
    if (msg.sender != currentManager) throw;
    _
  }

}


contract OfficialWebsite is Managed {
  string officialWebsite;

  function setOfficialWebsite(string url) onlyManager {
    officialWebsite = url;
  }

}


contract SmartRevshare is OfficialWebsite {

  struct Investor {
    address addr;
    uint value;
    uint lastDay;
    uint8 leftPayDays;
  }

  Investor[] public investors;
  uint payoutIdx = 0;

  address public currentManager;
  uint public balance;

   
  event Invest(address investor, uint value);
  event Payout(address investor, uint value);

   
  modifier manager {
    if (msg.sender == currentManager) _
  }

  function SmartRevshare() {
     
    currentManager = msg.sender;
     
    balance += msg.value;
  }

  function found() onlyManager {
     
    balance += msg.value;
  }

  function() {
     
    if (msg.value < 100 finney) throw;

    invest();
    payout();
  }

  function invest() {

     
    investors.push(Investor({
      addr: msg.sender,
      value: msg.value,
      leftPayDays: calculateROI(),
      lastDay: getDay()
    }));

     
    balance += msg.value * 99 / 100;

     
    currentManager.send(msg.value / 100);

     
    Invest(msg.sender, msg.value);
  }

  function payout() internal {
    uint payoutValue;
    uint currDay = getDay();  

    for (uint idx = payoutIdx; idx < investors.length; idx += 1) {
       
      payoutValue = investors[idx].value / 100;

      if (balance < payoutValue) {
         
        break;
      }

      if (investors[idx].lastDay >= currDay) {
         
         
        continue;
      }

      if (investors[idx].leftPayDays <= 0) {
         
        payoutIdx = idx;
      }

       
      investors[idx].addr.send(payoutValue);
       
      investors[idx].lastDay = currDay;
       
      investors[idx].leftPayDays -= 1;

       
      balance -= payoutValue;

       
      Payout(investors[idx].addr, payoutValue);
    }

  }

   
  function getDay() internal returns (uint) {
    return now / 1 days;
  }

   
  function calculateROI() internal returns (uint8) {
    if (msg.value <=   1 ether) return 110;  
    if (msg.value <=  10 ether) return 120;  
    if (msg.value <= 100 ether) return 130;  
    return 0;
  }

}