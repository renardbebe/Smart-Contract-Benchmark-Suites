 

pragma solidity ^0.4.19;

 
 
 
 
 
 
 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


interface AOCToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract AOCTrader {
    AOCToken AOC = AOCToken(0x73d7B530d181ef957525c6FBE2Ab8F28Bf4f81Cf);  
    address public seller;
    uint256 public price;  
    uint256 public AOC_available;  
    uint256 public Amount_of_AOC_for_One_ETH;  
    uint256 cooldown_start_time;

    function AOCTrader() public {
        seller = 0x0;
        price = 0;
        AOC_available = 0;
        Amount_of_AOC_for_One_ETH = 0;
        cooldown_start_time = 0;
    }

     
    function is_empty() public view returns (bool) {
        return (now - cooldown_start_time > 1 hours) && (this.balance==0) && (AOC.balanceOf(this) == 0);
    }
    
     
     
    function setup(uint256 AOC_amount, uint256 price_in_wei) public {
        require(is_empty());  
        require(AOC.allowance(msg.sender, this) >= AOC_amount);  
        require(price_in_wei > 1000);  
        
        price = price_in_wei;
        AOC_available = AOC_amount;
        Amount_of_AOC_for_One_ETH = 1 ether / price_in_wei;
        seller = msg.sender;

        require(AOC.transferFrom(msg.sender, this, AOC_amount));  
    }

    function() public payable{
        uint256 eth_balance = this.balance;
        uint256 AOC_balance = AOC.balanceOf(this);
        if(msg.sender == seller){
            seller = 0x0;  
            price = 0;  
            AOC_available = 0;  
            Amount_of_AOC_for_One_ETH = 0;  
            cooldown_start_time = now;  

            if(eth_balance > 0) msg.sender.transfer(eth_balance);  
            if(AOC_balance > 0) require(AOC.transfer(msg.sender, AOC_balance));  
        }        
        else{
            require(msg.value > 0);  
            require(price > 0);  
            uint256 num_AOC = msg.value / price;  
            require(AOC_balance >= num_AOC);  
            AOC_available = AOC_balance - num_AOC;  

            require(AOC.transfer(msg.sender, num_AOC));  
        }
    }
}