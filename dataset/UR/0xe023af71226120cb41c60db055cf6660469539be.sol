 

pragma solidity ^0.4.21;

contract ERC20Interface {
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

     
     
}

contract MassERC20Sender   {
    address public owner;

    function MassERC20Sender() public{
        owner = msg.sender;
    }

    function multisend(ERC20Interface _tokenAddr, address[] dests, uint256[] values) public returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            _tokenAddr.transferFrom(msg.sender, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }

    function withdraw() public{
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
}