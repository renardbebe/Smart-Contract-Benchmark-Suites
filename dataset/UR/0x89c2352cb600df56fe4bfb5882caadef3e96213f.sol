 

contract TwoAndAHalfPonzi {

  uint public constant VALUE = 1001 finney;
  uint public constant VALUEBACK = 2500 finney;

  struct Payout {
    address addr;
    uint yield;
  }

  Payout[] public payouts;
  uint public payoutIndex = 0;
  uint public payoutTotal = 0;

  function TwoAndAHalfPonzi() {
  }

  function() {
    if (msg.value != VALUE) {
      throw;
    }

    uint entryIndex = payouts.length;
    payouts.length += 1;
    payouts[entryIndex].addr = msg.sender;
    payouts[entryIndex].yield = VALUEBACK;

    while (payouts[payoutIndex].yield < this.balance) {
      payoutTotal += payouts[payoutIndex].yield;
      payouts[payoutIndex].addr.send(payouts[payoutIndex].yield);
      payoutIndex += 1;
    }
  }
}