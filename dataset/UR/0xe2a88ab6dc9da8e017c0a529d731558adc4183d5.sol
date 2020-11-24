 

pragma solidity 0.5.10;

contract Receiver {
     
     
     

     
    address public implementation;
    bool public isPayable;

     
    event LogImplementationChanged(address _oldImplementation, address _newImplementation);
    event LogPaymentReceived(address sender, uint256 value);
    event LogForwarded(bool _success, bytes _result);

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
    
    function forward(address _to, bytes memory _data, uint _value)
        public
        payable
        returns (bytes memory _result)
    {
        require(msg.sender == implementation, "Only the implementation may perform this action");
        (bool success, bytes memory result) = _to.call.value(_value + msg.value)(_data);
        emit LogForwarded(
            success,
            result);
        return result;
    }

    function ()
        external
        payable 
    {}
}