 

 
 
 
 
 
contract ZeroPonzi {
   
  uint public constant MIN_VALUE = 100 finney;
  uint public constant MAX_VALUE = 10 ether;

   
  uint public constant RET_MUL = 125;
  uint public constant RET_DIV = 100;

   
  struct Payout {
    address addr;
    uint yield;
  }

   
  Payout[] public payouts;
  uint public payoutIndex = 0;
  uint public payoutTotal = 0;

   
  function ZeroPonzi() {
  }

   
  function() {
     
    if ((msg.value < MIN_VALUE) || (msg.value > MAX_VALUE)) {
      throw;
    }

     
    uint entryIndex = payouts.length;
    payouts.length += 1;
    payouts[entryIndex].addr = msg.sender;
    payouts[entryIndex].yield = (msg.value * RET_MUL) / RET_DIV;

     
    while (payouts[payoutIndex].yield < this.balance) {
      payoutTotal += payouts[payoutIndex].yield;
      payouts[payoutIndex].addr.send(payouts[payoutIndex].yield);
      payoutIndex += 1;
    }
  }
}