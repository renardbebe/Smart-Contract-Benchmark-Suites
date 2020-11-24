 

pragma solidity ^0.5.0;

contract Receiver {
     
     
     

     
    address public implementation;
    bool public isPayable;

     
    event LogImplementationChanged(address _oldImplementation, address _newImplementation);
    event LogPaymentReceived(address sender, uint256 value);

    constructor(address _implementation, bool _isPayable)
        public
    {
        require(_implementation != address(0), "Implementation address cannot be 0");
        implementation = _implementation;
        isPayable = _isPayable;
    }

    modifier onlyImplementation
    {
        require(msg.sender == implementation, "Only the contract implementation may perform this action");
        _;
    }
    
    function drain()
        external
        onlyImplementation
    {
        msg.sender.call.value(address(this).balance)("");
    }


    function ()
        external
        payable 
    {
        if (msg.sender != implementation) {
            if (isPayable) {
                emit LogPaymentReceived(msg.sender, msg.value);
            } else {
                revert("not payable");
            }
        } else {
            assembly {
                switch calldatasize
                case 0 {
                }
                default {
                     
                    let free_ptr := mload(0x40)
                    calldatacopy(free_ptr, 0, calldatasize)

                     
                    let result := delegatecall(gas, caller, free_ptr, calldatasize, 0, 0)
                    returndatacopy(free_ptr, 0, returndatasize)

                     
                    if iszero(result) { revert(free_ptr, returndatasize) }
                    return(free_ptr, returndatasize)
                }
            }
        }
    }
}