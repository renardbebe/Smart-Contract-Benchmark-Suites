 

pragma solidity ^0.4.24;

contract Fees{

	function() public payable {}

	 
	address[2] devs = [0x11e52c75998fe2E7928B191bfc5B25937Ca16741, 0x20C945800de43394F70D789874a4daC9cFA57451];  

	 
	address[3] smallerdevs = [0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae, 0x71009e9E4e5e68e77ECc7ef2f2E95cbD98c6E696, 0x8537aa2911b193e5B377938A723D805bb0865670];  

	function payout() public {
		uint bal = address(this).balance;

		 
		for (uint i=0; i<devs.length; i++){
			devs[i].transfer((bal * 35) / 100);
		}

          
        bal = address(this).balance;

        for (i=0; i<smallerdevs.length-1; i++){
            smallerdevs[i].transfer(bal / 3);
        } 

         
        smallerdevs[smallerdevs.length-1].transfer(address(this).balance);
	}
}