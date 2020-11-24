 

pragma solidity ^0.4.25;
contract multiSendOxygen {

    function multipleOutputs (address address1, address address2,address address3, uint256 amt1, uint256 amt2,uint256 amt3) public payable {
       
        address1.transfer(amt1);
        address2.transfer(amt2);
       address3.transfer(amt3);
    }
   
}