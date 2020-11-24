 

pragma solidity 0.5.11;


contract Sacrifice {
    constructor(address payable _recipient) public payable {
        selfdestruct(_recipient);
    }
}


contract MultiSender {

    uint256 internal constant ARRAY_LIMIT = 200;

    event MultiSent(address payable[] receivers, uint256[] amounts);

    function multiSend(address payable[] calldata receivers, uint256[] calldata amounts) external payable {
        require(receivers.length <= ARRAY_LIMIT, "Array length limit");
        require(receivers.length == amounts.length, "Arrays lengths are different");
        uint256 total = msg.value;

        uint256 i = 0;
        uint256 length = receivers.length;
        for (i; i < length; i++) {
            require(total >= amounts[i], "msg.value is less than sum of amounts");
            total = total - amounts[i];
            safeTransfer(receivers[i], amounts[i]);
        }

        if (total > 0) {
            safeTransfer(msg.sender, total);
        }

        emit MultiSent(receivers, amounts);
    }

    function safeTransfer(address payable receiver, uint256 amount) internal {
        if (!receiver.send(amount)) {
            (new Sacrifice).value(amount)(receiver);
        }
    }
}