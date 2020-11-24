 

pragma solidity 0.5.7;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Poll {
    mapping (address => bool) public voted;
}

contract Reward {
    
    Poll poll;
    IERC20 dai;
    address public sponsor;
    mapping (address => bool) public claimed;
    
    uint public rewardAmount = 1e18;  
    uint public endTime = block.timestamp + 7 days;
    
    
    constructor() public {
        poll = Poll(0x43FCedE3571C10aCa1d3C12339bF01423b118e81);
        dai = IERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
        sponsor = msg.sender;
    }
    
    function claim() public {
        require(poll.voted(msg.sender), "Reward::claim: Only voters can claim reward");
        require(!claimed[msg.sender], "Reward::claim: Already claimed");
        
        claimed[msg.sender] = true;
        dai.transfer(msg.sender, rewardAmount);
    }
    
    function end() public {
        require(block.timestamp > endTime, "Reward::withdraw: Voting still active");
        
        uint balance = dai.balanceOf(address(this));
        dai.transfer(sponsor, balance);
    }
    
}