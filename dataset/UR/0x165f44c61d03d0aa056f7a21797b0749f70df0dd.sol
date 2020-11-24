 

pragma solidity ^0.4.19;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


interface ChiToken {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract ChiTrader {
    ChiToken Chi = ChiToken(0x71E1f8E809Dc8911FCAC95043bC94929a36505A5);  
    address public seller;
    uint256 public price;  
    uint256 public Chi_available;  
    uint256 public Amount_of_Chi_for_One_ETH;  
    uint256 cooldown_start_time;

    function ChiTrader() public {
        seller = 0x0;
        price = 0;
        Chi_available = 0;
        Amount_of_Chi_for_One_ETH = 0;
        cooldown_start_time = 0;
    }

     
    function is_empty() public view returns (bool) {
        return (now - cooldown_start_time > 1 hours) && (this.balance==0) && (Chi.balanceOf(this) == 0);
    }
    
     
     
    function setup(uint256 chi_amount, uint256 price_in_wei) public {
        require(is_empty());  
        require(Chi.allowance(msg.sender, this) >= chi_amount);  
        require(price_in_wei > 1000);  
        
        price = price_in_wei;
        Chi_available = chi_amount;
        Amount_of_Chi_for_One_ETH = 1 ether / price_in_wei;
        seller = msg.sender;

        require(Chi.transferFrom(msg.sender, this, chi_amount));  
    }

    function() public payable{
        uint256 eth_balance = this.balance;
        uint256 chi_balance = Chi.balanceOf(this);
        if(msg.sender == seller){
            seller = 0x0;  
            price = 0;  
            Chi_available = 0;  
            Amount_of_Chi_for_One_ETH = 0;  
            cooldown_start_time = now;  

            if(eth_balance > 0) msg.sender.transfer(eth_balance);  
            if(chi_balance > 0) require(Chi.transfer(msg.sender, chi_balance));  
        }        
        else{
            require(msg.value > 0);  
            require(price > 0);  
            uint256 num_chi = msg.value / price;  
            require(chi_balance >= num_chi);  
            Chi_available = chi_balance - num_chi;  

            require(Chi.transfer(msg.sender, num_chi));  
        }
    }
}