 

pragma solidity ^0.4.25;

contract OasisInterface {
      function createAndBuyAllAmountPayEth(address factory, address otc, address buyToken, uint buyAmt) public payable returns (address proxy, uint wethAmt);
}

contract testExchange {

    OasisInterface public exchange;
    event DaiDeposited(address indexed sender, uint amount);

    function buyDaiPayEth (uint buyAmt) public payable returns (uint amount ) {
       
      exchange = OasisInterface(0x793EbBe21607e4F04788F89c7a9b97320773Ec59);
       
       
      exchange.createAndBuyAllAmountPayEth(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4,0x14FBCA95be7e99C15Cc2996c6C9d841e54B79425,0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359, buyAmt);
      emit DaiDeposited(msg.sender, amount);

    } 

}