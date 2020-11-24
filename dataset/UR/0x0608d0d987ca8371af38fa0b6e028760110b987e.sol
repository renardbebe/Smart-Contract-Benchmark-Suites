 

pragma solidity ^0.4.23;

interface token {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address tokenOwner) constant external returns (uint balance);
}

contract DeflatLottoBurn {

  string public name = "DEFLAT LOTTO INVEST";
  string public symbol = "DEFTLI";
  string public prob = "Probability 1 of 10";
  string public comment = "Send 0.002 ETH to burn DEFLAT and try to win 0.018 ETH (-gas), the prize is drawn when the accumulated balance reaches 0.02 ETH";

   
   
   

  address[] internal playerPool;
  address public maincontract = address(0xe36584509F808f865BE1960aA459Ab428fA7A25b);  
  address public burncontract = address(0x731468ca17848717CdcBf2ddc0b8301f270b6D36); 
  token public tokenReward = token(0xe1E0DB951844E7fb727574D7dACa68d1C5D1525b); 
  uint rounds = 10;
  uint quota = 0.002 ether;
  event Payout(address from, address to, uint quantity);
  function () public payable {
    require(msg.value == quota);
    playerPool.push(msg.sender);
    if (playerPool.length >= rounds) {
      uint baserand = (block.number-1)+now+block.difficulty;
      uint winidx = uint(baserand)/10;
      winidx = baserand - (winidx*10);   
      address winner = playerPool[winidx];
      uint amount = address(this).balance;
      if (winner.send(amount)) { emit Payout(this, winner, amount);}
      if (tokenReward.balanceOf(address(this)) > 0) {tokenReward.transfer(burncontract, tokenReward.balanceOf(address(this)));}
      playerPool.length = 0;                
    } 
    else {
       if (playerPool.length == 1) {
           if (maincontract.call.gas(200000).value(address(this).balance)()) { emit Payout(this, maincontract, quota);}           
       }
    } 
  }
}