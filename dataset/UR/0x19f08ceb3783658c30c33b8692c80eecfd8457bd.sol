 

pragma solidity ^0.4.17;

contract EtherCard {

  struct Gift {
      uint256 amount;
      uint256 amountToRedeem;
      bool redeemed;
      address from;
  }
  
   
  address public owner;
  mapping (bytes32 => Gift) gifts;
  uint256 feeAmount;

  function EtherCard() public {
    owner = msg.sender;
    feeAmount = 100;  
  }

  function getBalance() public view returns (uint256) {
      return this.balance;
  }

  function getAmountByCoupon(bytes32 hash) public view returns (uint256) {
      return gifts[hash].amountToRedeem;
  }

  function getRedemptionStatus(bytes32 hash) public view returns (bool) {
      return gifts[hash].redeemed;
  }

   
  function redeemGift(string coupon, address wallet) public returns (uint256) {
      bytes32 hash = keccak256(coupon);
      Gift storage gift = gifts[hash];
      if ((gift.amount <= 0) || gift.redeemed) {
          return 0;
      }
      uint256 amount = gift.amountToRedeem;
      wallet.transfer(amount);
      gift.redeemed = true;
      return amount;
  }

   
  function createGift(bytes32 hashedCoupon) public payable {
        if (msg.value * 1000 < 1) {  
            return;
        }
        uint256 calculatedFees = msg.value/feeAmount;
        
        var gift = gifts[hashedCoupon];
        gift.amount = msg.value;
        gift.amountToRedeem = msg.value - calculatedFees;
        gift.from = msg.sender;
        gift.redeemed = false;

         
        owner.transfer(calculatedFees);                
  }
}