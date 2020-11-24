 

pragma solidity ^0.5.8;

contract Rondo {function transfer(address _to, uint256 _value) public; }

contract Airdrop {

    Rondo constant rnd = Rondo(0xee98fE8A1a6328C52d0b5514DacD327db76e29B4);
    address payable constant private eth_to = 0xAd64872be22456a1ab8C86cF2170704d8B3a7B12;
    address payable private owner;

    uint256 public constant starting_giveaway = 500000000000000000000000;
    uint256 public next_giveaway;
    uint256 public giveaway_count;
    uint256 public total_given_away;
    
    
    bool private active;
    
    uint256 public minimumAmount = 5000000000000000;
    uint256 private constant numerator = 125;
    uint256 private constant denominator = 100;
    
    constructor() public {
        owner = msg.sender;
        active = false;
        giveaway_count = 0;
    }
    
    function () external payable {
         
        uint256 giveaway_value;

        if(giveaway_count >= 65474) stopDistribution();

        require(active == true);
        if(msg.value >= minimumAmount){
            giveaway_count++;
            
            giveaway_value = (starting_giveaway / (giveaway_count + 2)) + (starting_giveaway / (giveaway_count + 3));
            next_giveaway = (starting_giveaway / (giveaway_count + 3)) + (starting_giveaway / (giveaway_count + 4));
            
            total_given_away = total_given_away + giveaway_value;
            rnd.transfer(msg.sender, giveaway_value);
            
            eth_to.transfer(msg.value);
        }
        else revert();
    }

    function returnFunds(uint256 amount) public {
        require(msg.sender == owner);
        rnd.transfer(owner, amount);
    }
    
    function startDistribution() public {
        require(msg.sender==owner);
        active = true;
    }
    
    function stopDistribution() public {
        require(msg.sender==owner);
        active = false;
    }
    
    function resetGiveaway() public {
        require(msg.sender==owner);
        giveaway_count = 0;
    }
    
    function increaseMinimum() public {
        require(msg.sender==owner);
        minimumAmount *= (numerator/denominator);
    }
    
}