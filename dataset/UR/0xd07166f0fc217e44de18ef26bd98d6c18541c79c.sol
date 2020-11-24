 

contract MultiTransfer {
    function multiTransfer(address[] _addresses, uint256 amount) payable {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].call.value(amount).gas(21000)();
        }
    }
    function() payable {}
}