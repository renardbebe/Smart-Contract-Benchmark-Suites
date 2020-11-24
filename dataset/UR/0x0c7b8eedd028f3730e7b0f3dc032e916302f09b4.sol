 

 
 
 

contract CafeMaker{

	bool public locked = true;

	uint public CafePayed;
	uint public CafeDelivered;


	uint public PricePerCafe = 50000000000000000;  
	address public DeviceOwner = msg.sender;
	address public DeviceAddr;

	function RegisterDevice() {
		DeviceAddr = msg.sender;
	}

	function BookCafe(){

		if(DeviceAddr != msg.sender)
			throw;  

		CafeDelivered += 1;

		if(CafePayed - CafeDelivered < 1)
			locked=true;

	}


	function CollectMoney(uint amount){
       if (!DeviceOwner.send(amount))
            throw;
		
	}


	 
    function () {

		CafePayed += (msg.value / PricePerCafe);

		if(CafePayed - CafeDelivered < 1){
			locked=true;
		} else {
			locked=false;
		}

    }
}