 

pragma solidity 0.5.11;

contract EtherDie {
    address payable owner;
    uint256 public maxSendPercentage = 5;
    uint256 public prizePercentage = 10;
    uint256 public winPercentage = 60;
    event Winnings(uint256);

    constructor() public payable {
        owner = msg.sender;
    }

     function () external payable {
         
    }

    function send() public payable {
        require(msg.value <= 5 ether && msg.value < address(this).balance * maxSendPercentage / 100, "sending too much");
        if (random() < winPercentage) {
            uint winnings = msg.value * prizePercentage / 100;
            msg.sender.transfer(msg.value + winnings);
            emit Winnings(winnings);
        }
    }

    function withdraw(uint256 _wei) public payable {
        require(owner == msg.sender,  "cannot withdraw");
        owner.transfer(_wei);
    }
    
    function setPrizePercentage(uint256 _prizePercentage) public {
        require(owner == msg.sender,  "cannot set price percentage");
        prizePercentage = _prizePercentage;
    }
    
    function setMaxSendPercentage(uint256 _maxSendPercentage) public {
        require(owner == msg.sender,  "cannot set max send percentage");
        maxSendPercentage = _maxSendPercentage;
    }
    
    function setWinPercentage(uint256 _winPercentage) public {
        require(owner == msg.sender,  "cannot set win percentage");
        winPercentage = _winPercentage;
    }

    function random() private view returns(uint){
        uint source = block.difficulty + now;
        bytes memory source_b = toBytes(source);
        return uint(keccak256(source_b)) % 100;
    }

    function toBytes(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}