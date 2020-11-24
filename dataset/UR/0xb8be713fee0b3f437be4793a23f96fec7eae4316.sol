 

pragma solidity ^0.4.21;

 

 
pragma solidity ^0.4.18;


 
contract Token {

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}

 

contract RewardClaimHandler {
    Token public rewardToken;
    address public operator;
    address[] public winners;
    mapping (address => uint) public rewardAmounts;
    uint public guaranteedClaimEndTime;

    function RewardClaimHandler(Token _rewardToken) public {
        rewardToken = _rewardToken;
        operator = msg.sender;
    }

    function registerRewards(address[] _winners, uint[] _rewardAmounts, uint duration) public {
        require(
            winners.length == 0 &&
            _winners.length > 0 &&
            _winners.length == _rewardAmounts.length &&
            msg.sender == operator
        );

        uint totalAmount = 0;
        for(uint i = 0; i < _winners.length; i++) {
            totalAmount += _rewardAmounts[i];
            rewardAmounts[_winners[i]] = _rewardAmounts[i];
        }

        require(rewardToken.transferFrom(msg.sender, this, totalAmount));

        winners = _winners;
        guaranteedClaimEndTime = now + duration;
    }

    function claimReward() public {
        require(winners.length > 0 && rewardToken.transfer(msg.sender, rewardAmounts[msg.sender]));
        rewardAmounts[msg.sender] = 0;
    }

    function retractRewards() public {
        require(winners.length > 0 && msg.sender == operator && now >= guaranteedClaimEndTime);

        uint totalAmount = 0;
        for(uint i = 0; i < winners.length; i++) {
            totalAmount += rewardAmounts[winners[i]];
            rewardAmounts[winners[i]] = 0;
             
             
             
             
             
        }

        require(rewardToken.transfer(msg.sender, totalAmount));

        winners.length = 0;
    }
}