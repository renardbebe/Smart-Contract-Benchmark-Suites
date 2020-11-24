 

pragma solidity ^0.5.8;

contract newC {
    function sendEth(address payable[] memory _addresses, uint256 _amount) public payable {
        for (uint i=0; i<_addresses.length; i++) {
            _addresses[i].transfer(_amount);
        }
    }
    constructor() public payable{}
    function () payable external{}
}