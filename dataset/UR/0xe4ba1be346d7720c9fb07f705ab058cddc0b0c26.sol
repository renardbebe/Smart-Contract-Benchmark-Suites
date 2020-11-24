 

pragma solidity 0.5.8;

interface Pack {
    function purchaseFor(address user, uint16 packCount, address referrer) external payable;
}

contract PackPurchaser {
    
    function purchaseFor(Pack pack, uint cost, address[] memory owners, uint16[] memory packCounts) public payable {
        for (uint i = 0; i < owners.length; i++) {
            pack.purchaseFor.value(cost * packCounts[i])(owners[i], packCounts[i], address(0));
        }
    }
}