 

pragma solidity ^0.4.23;

 
 

contract miner_winner_basic {  

    address public owner;
    address public reward_winaddr;
    uint256 public deadline;
    uint256 public time;
    uint256 public price;
    uint256 public reward_value;
    token public token_reward;
    address[] public plyr;
    uint256 public next_count;
}

contract miner_winner is miner_winner_basic {

    constructor(address _token_reward_address) public {

        owner = msg.sender;
        reward_winaddr = address(0);
        time = 8 * 60 minutes;
        deadline = now + time;
        price = 1 ether;
        reward_value = 0;
        token_reward = token(_token_reward_address);
        plyr = new address[](0);
        plyr.push(msg.sender);
        next_count = 0;
    }

    function() public payable {

        require(msg.value >= price);

        plyr.push(msg.sender);

        if( next_count >= plyr.length) {
            next_count = 0;
        }
        plyr[next_count].transfer(price * 20/100);
        next_count++;
        
        if( next_count >= plyr.length) {
            next_count = 0;
        }
        plyr[next_count].transfer(price * 20/100);
        next_count++;    

        reward_value = token_reward.balanceOf(address(this));

        uint256 _pvalue = plyr.length * price;

        if(reward_value >= _pvalue){
            token_reward.transfer(msg.sender, _pvalue);
        }
        
        uint256 _now = now;

        if( _now > deadline) {

            if( reward_winaddr == address(0)) {
                reward_winaddr = plyr[plyr.length - 1];
            }

            for(uint256 i = plyr.length - 9; i < plyr.length; i++) {

                if(token_reward.balanceOf(plyr[i]) > token_reward.balanceOf(reward_winaddr)){
                    reward_winaddr = plyr[i];
                }
            }

            if(address(this).balance > 3 ether){
                reward_winaddr.transfer(3 ether);
            }
        }

        deadline = _now + time;
    }
}

contract token{

    function transfer(address receiver, uint amount) public;
    function balanceOf(address receiver) constant public returns (uint balance);
}