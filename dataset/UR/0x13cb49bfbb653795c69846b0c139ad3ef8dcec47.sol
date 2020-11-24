 

pragma solidity ^0.4.24;

contract KICKPriceOracle {

    mapping (address => bool) admins;

     
    uint256 public ETHPrice = 8954340000000000000000;

    event PriceChanged(uint256 newPrice);

    constructor() public {
        admins[msg.sender] = true;
    }

    function updatePrice(uint256 _newPrice) public {
        require(_newPrice > 0);
        require(admins[msg.sender] == true);
        ETHPrice = _newPrice;
        emit PriceChanged(_newPrice);
    }

    function setAdmin(address _newAdmin, bool _value) public {
        require(admins[msg.sender] == true);
        admins[_newAdmin] = _value;
    }
}