 

pragma solidity ^0.4.11;

contract ZweiGehenReinEinerKommtRaus {

	address public player1 = address(0);
	
	event NewPlayer(address token, uint amount);
	event Winner(address token, uint amount);

	function Bet() public payable {
		address player = msg.sender;
		require(msg.value == 1 szabo );
		NewPlayer(player, msg.value);
		
		if( player1==address(0) ){
			 
			player1 = player;
		}else{
			 
			 
			uint random = now;
			address winner = player1;
			if( random/2*2 == random ){
				 
				winner = player;
			}
			
			 
            player1=address(0);

             
            uint amount = this.balance;
			winner.transfer(amount);
			Winner(winner, amount);
		}
	}
}