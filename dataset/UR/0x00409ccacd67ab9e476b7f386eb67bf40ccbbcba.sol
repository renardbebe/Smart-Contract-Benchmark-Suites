 

pragma solidity 0.4.24;

contract Snickers {
    

   address seed;
   uint256 daily_percent;

   constructor() public {
       seed = msg.sender;
       daily_percent = 5;
   }

   mapping (address => uint256) balances;
   mapping (address => uint256) timestamps;

   function() external payable {
        
       require(msg.value >= 0);

        
       seed.transfer(msg.value / (daily_percent * 2));

       uint block_timestamp = now;

       if (balances[msg.sender] != 0) {
           
            
           uint256 pay_out = balances[msg.sender] * daily_percent / 100 * (block_timestamp - timestamps[msg.sender]) / 86400;

            
           if (address(this).balance < pay_out) pay_out = address(this).balance;

           msg.sender.transfer(pay_out);

            
           emit Payout(msg.sender, pay_out);
       }

       timestamps[msg.sender] = block_timestamp;
       balances[msg.sender] += msg.value;

        
       if (msg.value > 0) emit AcountTopup(msg.sender, balances[msg.sender]);
   }

   event Payout(address receiver, uint256 amount);
   event AcountTopup(address participiant, uint256 ineterest);
}