 

pragma solidity ^0.5.0;

contract IChest {
        function purchaseFor(address user, uint count, address referrer) public payable;

}


contract Purchase {
    
    IChest public chest = IChest(0x20D4Cec36528e1C4563c1BFbE3De06aBa70b22B4);
    uint public price = 0.8064 ether;
    
    function purchaseFor(address[] memory users, uint count) public payable {
        require(users.length > 0, "");
        for (uint i = 0; i < users.length; i++) {
            chest.purchaseFor.value(price * count)(users[i], count, address(0));
        }
    }
    
}