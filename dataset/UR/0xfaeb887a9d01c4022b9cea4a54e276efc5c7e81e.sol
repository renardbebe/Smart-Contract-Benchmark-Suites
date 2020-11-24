 

contract CafeMakerT3 {

	 
	uint public payed;
	uint public delivered;

	uint public PricePerCafe = 50000000000000000;  
	address public Owner = msg.sender;

 
 
 
 

	function GetFreeCnt() returns (uint cnt) {
		return payed - delivered;
	}

	function CafeDelivered(){
		delivered += 1;
	}


	function CollectMoney(uint amount){
       if (!Owner.send(amount))
            throw;
		
	}


	 
    function () {

		uint addedcafe = msg.value / PricePerCafe;
		payed += addedcafe;

    }
}