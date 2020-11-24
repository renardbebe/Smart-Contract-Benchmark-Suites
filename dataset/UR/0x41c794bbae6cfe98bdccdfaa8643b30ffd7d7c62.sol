 

pragma solidity ^0.4.15;


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract IRateOracle {
    function converted(uint256 weis) external constant returns (uint256);
}

contract RateOracle is IRateOracle, Ownable {

    uint32 public constant delimiter = 100;
    uint32 public rate;

    event RateUpdated(uint32 indexed newRate);

    function setRate(uint32 _rate) external onlyOwner {
        rate = _rate;
        RateUpdated(rate);
    }

    function converted(uint256 weis) external constant returns (uint256)  {
        return weis * rate / delimiter;
    }
}