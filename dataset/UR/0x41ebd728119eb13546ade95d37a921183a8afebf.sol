 

contract Freemoney {
    bool public drained;

    function Freemoney() public payable
    {
        require(msg.value == 0.01 ether);
        drained = false;
    }

    function extractMoney() public
    {
        if (!drained) {
            drained = true;
            msg.sender.transfer(this.balance);
        }
    }

}