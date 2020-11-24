 

pragma solidity ^0.4.25;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

contract EthSmart {
     
	using SafeMath for uint256;
     
	address public constant referralAddress = 0x0B4a3ADd0276A0DD311D616DCFDDE5686f4b11A7;
	address public constant advertisementAddress = 0x28C1aA68681d1Cca986CC1eC2fe4dF07d7Fddeef;
	address public constant developerAddress = 0x3f13C78c63cee71224f80d09c58f9c642d7b7b2f;
	
	mapping (address => uint256) deposited;
	mapping (address => uint256) withdrew;
	mapping (address => uint256) refearned;
	mapping (address => uint256) blocklock;
	
      
	uint256 public totalDeposited = 0;
	uint256 public totalWithdrew = 0;
	
      
	function() payable external {
		uint256 referralPercent = msg.value.mul(10).div(100);
		uint256 advertisementPercent = msg.value.mul(7).div(100);
		uint256 developerPercent = msg.value.mul(3).div(100);
        referralAddress.transfer(referralPercent);
	    advertisementAddress.transfer(advertisementPercent);
	    developerAddress.transfer(developerPercent);
    
		if (deposited[msg.sender] != 0) {
			address investor = msg.sender;
			
			 
			uint256 depositsPercents = deposited[msg.sender].mul(5).div(100).mul(block.number-blocklock[msg.sender]).div(5900);
			investor.transfer(depositsPercents);
			withdrew[msg.sender] += depositsPercents;
			totalWithdrew = totalWithdrew.add(depositsPercents);}

	    address referrer = bytesToAddress(msg.data);
		
		 
		if (referrer > 0x0 && referrer != msg.sender) {
			referrer.transfer(referralPercent);
			refearned[referrer] += referralPercent;}
            
        blocklock[msg.sender] = block.number;
		deposited[msg.sender] += msg.value;
        totalDeposited = totalDeposited.add(msg.value);}

	function investorDeposited(address _address) public view returns (uint256) {
		return deposited[_address];}

	function investorWithdrew(address _address) public view returns (uint256) {
		return withdrew[_address];}

	function investorDividends(address _address) public view returns (uint256) {
		return deposited[_address].mul(5).div(100).mul(block.number-blocklock[_address]).div(5900);}

	function investorReferrals(address _address) public view returns (uint256) {
		return refearned[_address];}

	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
			addr := mload(add(bys, 20))}
	}
}