 

pragma solidity ^0.4.25;

 
contract X3ProfitMainFundTransfer {   

     
     
	uint public constant maxBalance = 340282366920938463463374607431768211456 wei;  
    address public constant ADDRESS_EIFP2_CONTRACT = 0xf85D337017D9e6600a433c5036E0D18EdD0380f3;
    address public constant ADDRESS_ADMIN =          0x6249046Af9FB588bb4E70e62d9403DD69239bdF5;

	bool private isResend = false;

     
    function () external payable {
        if(msg.value == 0 || (msg.sender == ADDRESS_EIFP2_CONTRACT && 
                              msg.value >= 0.1 ether && !isResend)){
            
             
             
            if(ADDRESS_EIFP2_CONTRACT.balance > maxBalance)
            {
                ADDRESS_ADMIN.transfer(address(this).balance);
                return;
            }
			isResend = msg.sender == ADDRESS_EIFP2_CONTRACT;
            if(!ADDRESS_EIFP2_CONTRACT.call.value(address(this).balance)())
                revert();
			isResend = false;
        }
	}
}