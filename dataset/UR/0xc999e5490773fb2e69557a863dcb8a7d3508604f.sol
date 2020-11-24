 

 
pragma solidity ^0.4.21;

contract SaiContest_Gaia {
	address public owner;
	uint public start;       
	uint public last_roll;   
	uint public last_jack;    
	address public week_winner;  
	address public jack_winner;  
	uint public week_max;    
	uint public jack_max;    
	uint public jack_pot;    
	uint public jack_nonce;  
	struct JVal {
        	uint nonce;
        	uint64 count;
	}
	mapping (address => JVal) public jacks;  

	uint public constant min_payment= 1 finney;  
	
	function SaiContest_Gaia() public {
		owner = msg.sender;		
		start = now;
		last_roll = now;
		last_jack = now;
		jack_nonce = 1;
	}

	function kill(address addr) public { 
	    if (msg.sender == owner && now > start + 1 years){
	        selfdestruct(addr);
	    }
	}
	
	function getBalance() public view returns (uint bal) {
	    bal = address(this).balance;
	}

	function () public payable{
	    Paid(msg.value);
	}
	
	function Paid(uint value) private {
	    uint WeekPay;
	    uint JackPay;
	    uint oPay;
	    uint CurBal;
	    uint JackPot;
	    uint CurNonce;
	    address WeekWinner;
	    address JackWinner;
	    uint64 JackValCount;
	    uint JackValNonce;
	    
	    require(value >= min_payment);
	    oPay = value * 5 / 100;  
	    CurBal = address(this).balance - oPay;
	    JackPot = jack_pot;

	    if (now > last_roll + 7 days) {
	        WeekPay = CurBal - JackPot;
	        WeekWinner = week_winner;
	        last_roll = now;
	        week_max = value;
	        week_winner = msg.sender;
	    } else {
	        if (value > week_max) {
    	        week_winner = msg.sender;
	            week_max = value;
	        }
	    }
	    if (now > last_jack + 30 days) {
	        JackWinner = jack_winner;
	        if (JackPot > CurBal) {
	            JackPay = CurBal;
	        } else {
	            JackPay = JackPot;
	        }
    	    jack_pot = value * 10 / 100;  
	        jack_winner = msg.sender;
	        jack_max = 1;
	        CurNonce = jack_nonce + 1; 
	        jacks[msg.sender].nonce = CurNonce;
	        jacks[msg.sender].count = 1;
	        jack_nonce = CurNonce;
	    } else {
    	    jack_pot = JackPot + value * 10 / 100;  
	        CurNonce = jack_nonce; 
	        JackValNonce = jacks[msg.sender].nonce;
	        JackValCount = jacks[msg.sender].count;
	        if (JackValNonce < CurNonce) {
	            jacks[msg.sender].nonce = CurNonce;
	            jacks[msg.sender].count = 1;
    	        if (jack_max == 0) {
        	        jack_winner = msg.sender;
    	            jack_max = 1;
    	        }
	        } else {
	            JackValCount = JackValCount + 1;
	            jacks[msg.sender].count = JackValCount;
    	        if (JackValCount > jack_max) {
        	        jack_winner = msg.sender;
    	            jack_max = JackValCount;
    	        }
	        }
	        
	    }

	    owner.transfer(oPay);
	    if (WeekPay > 0) {
	        WeekWinner.transfer(WeekPay);
	    }
	    if (JackPay > 0) {
	        JackWinner.transfer(JackPay);
	    }
	}
}