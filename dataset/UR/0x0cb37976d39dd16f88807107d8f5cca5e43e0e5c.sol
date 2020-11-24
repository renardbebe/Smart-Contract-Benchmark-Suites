 

pragma solidity ^0.5.0;

contract IChest {
        function purchaseFor(address user, uint count, address referrer) public payable;

}


contract Purchase {
    
    function purchaseFor(IChest chest, address[] memory users, uint[] memory counts) public payable {
        require(users.length > 0, "");
        require(users.length == counts.length, "");
        for (uint i = 0; i < users.length; i++) {
            chest.purchaseFor.value(msg.value)(users[i], counts[i], address(0));
        }
    }
    
}