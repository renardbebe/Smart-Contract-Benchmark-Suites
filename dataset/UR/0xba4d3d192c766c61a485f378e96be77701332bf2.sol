 

pragma solidity ^0.4.15;

contract P4PDonationSplitter {
    address public constant epicenter_works_addr = 0x883702a1b9B29119acBaaa0E7E0a2997FB8EBcd3;
    address public constant max_schrems_addr = 0x9abd6265Eaca022c1ccF931a7E9150dA0E7Db7Ec;

     
    function () payable public {}

     
    function payout() payable public {
        var share = this.balance / 2;
        epicenter_works_addr.transfer(share);
        max_schrems_addr.transfer(share);
    }
}