 

pragma solidity ^0.4.11;
 
 
 
 
 
 

 
contract RegistrarFakeInterface {
     
    mapping (address => mapping(bytes32 => address)) public sealedBids;
     
     

     
    function cancelBid(address bidder, bytes32 seal);
}

 
 
contract Cancelot {
    address public owner;
    RegistrarFakeInterface registrar;

    modifier only_owner {
        if (msg.sender == owner) _;
    }

    function Cancelot(address _owner, address _registrar) {
        owner = _owner;
        registrar = RegistrarFakeInterface(_registrar);
    }

    function cancel(address bidder, bytes32 seal) {
        if (registrar.sealedBids(bidder, seal) != 0)
            registrar.cancelBid.gas(msg.gas)(bidder, seal);
    }

    function withdraw() {
        owner.transfer(this.balance);
    }

    function sweep(address bidder, bytes32 seal) {
        cancel(bidder, seal);
        withdraw();
    }

    function () payable {}

    function terminate() only_owner {
        selfdestruct(owner);
    }
}