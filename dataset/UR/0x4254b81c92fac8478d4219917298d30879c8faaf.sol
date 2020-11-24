 

pragma solidity ^0.5.0;



contract AirDropContract{

    constructor () public {
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }
    
    function transfer(address contract_address, address[] memory tos,  uint[] memory vs)
        public 
        validAddress(contract_address)
        returns (bool){

        require(tos.length > 0);
        require(vs.length > 0);
        require(tos.length == vs.length);
        for(uint i = 0 ; i < tos.length; i++){
            (bool success, bytes memory data) = contract_address.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",
                 msg.sender, tos[i], vs[i]));
            require(success == true, "transferFrom Error ");
        }
        return true;
    }
}