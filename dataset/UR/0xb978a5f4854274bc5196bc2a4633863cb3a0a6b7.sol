 

pragma solidity ^0.4.0;

contract Pyramid {
    address master;

    address[] memberQueue;
    uint queueFront;

    event Joined(address indexed _member, uint _entries, uint _paybackStartNum);

    modifier onlymaster { if (msg.sender == master) _; }

    function Pyramid() {
        master = msg.sender;
        memberQueue.push(master);
        queueFront = 0;
    }

     
    function(){}

     
    function join() payable {
        require(msg.value >= 100 finney);

        uint entries = msg.value / 100 finney;
        entries = entries > 50 ? 50 : entries;  

        for (uint i = 0; i < entries; i++) {
            memberQueue.push(msg.sender);

            if (memberQueue.length % 2 == 1) {
                queueFront += 1;
                memberQueue[queueFront-1].transfer(194 finney);
            }
        }

        Joined(msg.sender, entries, memberQueue.length * 2);

         
        uint remainder = msg.value - (entries * 100 finney);
        if (remainder > 1 finney) {
            msg.sender.transfer(remainder);
        }
         
    }

    function collectFee() onlymaster {
        master.transfer(this.balance - 200 finney);
    }

    function setMaster(address _master) onlymaster {
        master = _master;
    }

}