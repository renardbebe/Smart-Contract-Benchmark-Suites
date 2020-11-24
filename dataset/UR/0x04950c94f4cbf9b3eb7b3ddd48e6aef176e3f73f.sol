 

pragma solidity ^0.4.24;

 

contract WhaleKiller {
    address WhaleAddr;
    uint constant interest = 5;
    uint constant whalefee = 1;
    uint constant maxRoi = 150;
    mapping (address => uint256) invested;
    mapping (address => uint256) timeInvest;
    mapping (address => uint256) rewards;

    constructor() public {
        WhaleAddr = msg.sender;
    }
    function () external payable {
        address sender = msg.sender;
        uint256 amount = 0;        
        if (invested[sender] != 0) {
            amount = invested[sender] * interest / 100 * (now - timeInvest[sender]) / 1 days;
            if (msg.value == 0) {
                if (amount >= address(this).balance) {
                    amount = (address(this).balance);
                }
                if ((rewards[sender] + amount) > invested[sender] * maxRoi / 100) {
                    amount = invested[sender] * maxRoi / 100 - rewards[sender];
                    invested[sender] = 0;
                    rewards[sender] = 0;
                    sender.transfer(amount);
                    return;
                } else {
                    sender.transfer(amount);
                    rewards[sender] += amount;
                    amount = 0;
                }
            }
        }
        timeInvest[sender] = now;
        invested[sender] += (msg.value + amount);
        
        if (msg.value != 0) {
            WhaleAddr.transfer(msg.value * whalefee / 100);
            if (invested[sender] > invested[WhaleAddr]) {
                WhaleAddr = sender;
            }  
        }
    }
    function ShowDepositInfo(address _dep) public view returns(uint256 _invested, uint256 _rewards, uint256 _unpaidInterest) {
        _unpaidInterest = invested[_dep] * interest / 100 * (now - timeInvest[_dep]) / 1 days;
        return (invested[_dep], rewards[_dep], _unpaidInterest);
    }
    function ShowWhaleAddress() public view returns(address) {
        return WhaleAddr;
    }
}