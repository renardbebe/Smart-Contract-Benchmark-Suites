 

pragma solidity ^0.4.19;

 
interface KittyCoreI {
    function giveBirth(uint256 _matronId) public;
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract KittyBirther is Ownable {
    KittyCoreI constant kittyCore = KittyCoreI(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);

    function KittyBirther() public {}

    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function birth(uint blockNumber, uint64[] kittyIds) public {
        if (blockNumber < block.number) {
            return;
        }

        if (kittyIds.length == 0) {
            return;
        }

        for (uint i = 0; i < kittyIds.length; i ++) {
            kittyCore.giveBirth(kittyIds[i]);
        }
    }
}