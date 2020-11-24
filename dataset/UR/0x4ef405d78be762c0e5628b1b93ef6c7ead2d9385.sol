 

pragma solidity ^0.4.11;



 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


contract trustedOracle is Ownable {
	mapping (uint => uint) pricePoints;
	uint public lastTimestamp;

	function submitPrice(uint _timestamp, uint _weiForCent)
		onlyOwner
	{
		pricePoints[_timestamp] = _weiForCent;
		if (_timestamp > lastTimestamp) lastTimestamp = _timestamp;
	}


	function getWeiForCent(uint _timestamp)
		public
		constant
		returns (uint)
	{
		uint stamp = _timestamp;
		if (stamp == 0) stamp = lastTimestamp;
		return pricePoints[stamp];
	}
}