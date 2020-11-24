 

pragma solidity ^0.5.0;

contract IChest {
        function purchaseFor(address user, uint count, address referrer) public payable;

}


contract Purchase {
    
    IChest public chest = IChest(0xEE85966b4974d3C6F71A2779cC3B6F53aFbc2B68);
    uint public price = 0.0864 ether;
    
    function purchaseFor(address[] memory users, uint count) public payable {
        require(users.length > 0, "");
        for (uint i = 0; i < users.length; i++) {
            chest.purchaseFor.value(price * count)(users[i], count, address(0));
        }
    }
    
}