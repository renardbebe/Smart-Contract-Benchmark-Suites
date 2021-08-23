/* @Labeled: [25] */
pragma solidity >=0.5.0;

contract Bank{
/*Contract that stores user balances. This is the vulnerable contract. This contract contains 
the basic actions necessary to interact with its users, such as: get balance, add to balance,
and withdraw balance */

   mapping(address=>uint) userBalances;/*mapping is a variable
   type that saves the relation between the user and the amount contributed to
   this contract. An address (account) is a unique indentifier in the blockchain*/

   function getUserBalance(address user) returns(uint) {
     return userBalances[user];
   }/*This function returns the amount (balance) that the user has contributed
   to this contract (this information is saved in the userBalances variable)*/

   function addToBalance() {
     userBalances[msg.sender] = userBalances[msg.sender] + msg.value;
   }/*This function assigns the value sent by the user to the userBalances variable.
   The msg variable is a global variable*/

   function withdrawBalance() {
     uint amountToWithdraw = userBalances[msg.sender];
     if (msg.sender.call.value(amountToWithdraw)() == false) {
         throw;
     }
     userBalances[msg.sender] = 0;
   }
}