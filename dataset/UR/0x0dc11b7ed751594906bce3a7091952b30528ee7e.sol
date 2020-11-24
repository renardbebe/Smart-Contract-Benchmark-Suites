 

pragma solidity ^0.4.17;

contract DickMeasurementContest {

    uint lastBlock;
    address owner;

    modifier onlyowner {
        require (msg.sender == owner);
        _;
    }

    function DickMeasurementContest() public {
        owner = msg.sender;
    }

    function () public payable {}

    function mineIsBigger() public payable {
        if (msg.value > this.balance) {
            owner = msg.sender;
            lastBlock = now;
        }
    }

    function withdraw() public onlyowner {
         
         
        require(now > lastBlock + 3 days);
        msg.sender.transfer(this.balance);
    }

    function kill() public onlyowner {
        if(this.balance == 0) {  
            selfdestruct(msg.sender);
        }
    }
}