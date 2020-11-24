 

pragma solidity 0.5.11;


contract BulkSender {

    function distribute(address[] calldata addresses, uint256[] calldata amounts) payable external {
        require(addresses.length > 0);
        require(amounts.length == addresses.length);

        for (uint256 i; i < addresses.length; i++) {
            uint256 value = amounts[i];
            address _to = addresses[i];
            require(value > 0);
            address(uint160(_to)).transfer(value);
        }
    }

    function() external payable {
        msg.sender.transfer(address(this).balance);
    }
}