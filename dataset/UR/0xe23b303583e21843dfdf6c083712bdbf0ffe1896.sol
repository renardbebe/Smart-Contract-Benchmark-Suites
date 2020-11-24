 

pragma solidity >=0.4.21 <0.6.0;

contract BurnFactory {

    address public owner;
    address[] public burners;

    constructor() public {
        owner = msg.sender;
    }

    function createBurner() public returns(address) {
        require(msg.sender == owner);
        address newBurner = address(new Burner());
        burners.push(newBurner);
        return newBurner;
    }

    function getBurners() public view returns(address[] memory) {
        return burners;
    }
}

contract Burner {

    address public origin;

    constructor() public {
        origin = msg.sender;
    }
}