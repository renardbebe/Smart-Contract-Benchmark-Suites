 

pragma solidity ^0.5.8;

contract Zuckbucks {function transfer(address _to, uint256 _value) public; }


contract Airdrop {

    address private owner;
    address[] private addresses;
    Zuckbucks zbux;

    constructor() public {
        owner = msg.sender;
        zbux = Zuckbucks(0x7090a6e22c838469c9E67851D6489ba9c933a43F);
    }

    function() external payable{}
    
    function airdrop(uint256 amount) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < addresses.length; i++) {
            zbux.transfer(addresses[i],amount);
        }
    }
    
    function AddressArray(address[] memory addresses_) public {
        require(msg.sender == owner);
        for (uint i = 0; i < addresses_.length; i++) {
            addresses.push(addresses_[i]);
        }
    }

    function returnFunds(uint256 amount) public {
        require(msg.sender == owner);
        zbux.transfer(owner, amount);
    }
    
    function deleteAddresses() public {
        require(msg.sender==owner);
        delete addresses;
    }
    
}