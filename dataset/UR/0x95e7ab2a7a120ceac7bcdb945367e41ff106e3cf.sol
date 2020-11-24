 

pragma solidity ^0.5.9;

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
    {}
}