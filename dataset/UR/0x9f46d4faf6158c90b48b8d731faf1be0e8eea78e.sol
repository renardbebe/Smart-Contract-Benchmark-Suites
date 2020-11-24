 

pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract MilitaryPay is StandardToken {
	using SafeMath for uint256;

     
    event CreatedMTP(address indexed _creator, uint256 _amountOfMTP);

	
	 
	string public constant name = "MilitaryPay";
	string public constant symbol = "MTP";
	uint256 public constant decimals = 18;
	string public version = "1.0";

	 
	uint256 public maxPresaleSupply; 														 

	 
	uint256 public constant preSaleStartTime = 1503130673; 									 
	uint256 public constant preSaleEndTime = 1505894400; 									 
	uint256 public saleStartTime = 1509696000; 												 
	uint256 public saleEndTime = 1514707200; 												 


	 
	uint256 public lowEtherBonusLimit = 5 * 1 ether; 										 
	uint256 public lowEtherBonusValue = 110;												 
	uint256 public midEtherBonusLimit = 24 * 1 ether; 										 
	uint256 public midEtherBonusValue = 115;												 
	uint256 public highEtherBonusLimit = 50 * 1 ether; 										 
	uint256 public highEtherBonusValue = 120; 												 
	uint256 public highTimeBonusLimit = 0; 													 
	uint256 public highTimeBonusValue = 120; 												 
	uint256 public midTimeBonusLimit = 1036800; 											 
	uint256 public midTimeBonusValue = 115; 												 
	uint256 public lowTimeBonusLimit = 2073600;												 
	uint256 public lowTimeBonusValue = 110;													 

	 
	uint256 public constant MTP_PER_ETH_PRE_SALE = 4000;  								 
	uint256 public constant MTP_PER_ETH_SALE = 2000;  									 
	
	 
	address public constant ownerAddress = 0x144EFeF99F7F126987c2b5cCD717CF6eDad1E67d; 		 

	 
	bool public allowInvestment = true;														 
	uint256 public totalWEIInvested = 0; 													 
	uint256 public totalMTPAllocated = 0;												 
	mapping (address => uint256) public WEIContributed; 									 


	 
	function MTPToken() {
		require(msg.sender == ownerAddress);

		totalSupply = 99631*1000000*1000000000000000000; 										 
		uint256 totalMTPReserved = totalSupply.mul(99).div(100);							 
		maxPresaleSupply = totalSupply*8/1000 + totalMTPReserved; 						 

		balances[msg.sender] = totalMTPReserved;
		totalMTPAllocated = totalMTPReserved;				
	}


	 
	function() payable {

		require(allowInvestment);

		 
		uint256 amountOfWei = msg.value;
		require(amountOfWei >= 10000000000000);

		uint256 amountOfMTP = 0;
		uint256 absLowTimeBonusLimit = 0;
		uint256 absMidTimeBonusLimit = 0;
		uint256 absHighTimeBonusLimit = 0;
		uint256 totalMTPAvailable = 0;

		 
		if (block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) {
			 
			amountOfMTP = amountOfWei.mul(MTP_PER_ETH_PRE_SALE);
			absLowTimeBonusLimit = preSaleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = preSaleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = preSaleStartTime + highTimeBonusLimit;
			totalMTPAvailable = maxPresaleSupply - totalMTPAllocated;
		} else if (block.timestamp > saleStartTime && block.timestamp < saleEndTime) {
			 
			amountOfMTP = amountOfWei.mul(MTP_PER_ETH_SALE);
			absLowTimeBonusLimit = saleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = saleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = saleStartTime + highTimeBonusLimit;
			totalMTPAvailable = totalSupply - totalMTPAllocated;
		} else {
			 
			revert();
		}

		 
		assert(amountOfMTP > 0);

		 
		if (amountOfWei >= highEtherBonusLimit) {
			amountOfMTP = amountOfMTP.mul(highEtherBonusValue).div(100);
		} else if (amountOfWei >= midEtherBonusLimit) {
			amountOfMTP = amountOfMTP.mul(midEtherBonusValue).div(100);
		} else if (amountOfWei >= lowEtherBonusLimit) {
			amountOfMTP = amountOfMTP.mul(lowEtherBonusValue).div(100);
		}
		if (block.timestamp >= absLowTimeBonusLimit) {
			amountOfMTP = amountOfMTP.mul(lowTimeBonusValue).div(100);
		} else if (block.timestamp >= absMidTimeBonusLimit) {
			amountOfMTP = amountOfMTP.mul(midTimeBonusValue).div(100);
		} else if (block.timestamp >= absHighTimeBonusLimit) {
			amountOfMTP = amountOfMTP.mul(highTimeBonusValue).div(100);
		}

		 
		assert(amountOfMTP <= totalMTPAvailable);

		 
		totalMTPAllocated = totalMTPAllocated + amountOfMTP;

		 
		uint256 balanceSafe = balances[msg.sender].add(amountOfMTP);
		balances[msg.sender] = balanceSafe;

		 
		totalWEIInvested = totalWEIInvested.add(amountOfWei);

		 
		uint256 contributedSafe = WEIContributed[msg.sender].add(amountOfWei);
		WEIContributed[msg.sender] = contributedSafe;

		 
		assert(totalMTPAllocated <= totalSupply);
		assert(totalMTPAllocated > 0);
		assert(balanceSafe > 0);
		assert(totalWEIInvested > 0);
		assert(contributedSafe > 0);

		 
		CreatedMTP(msg.sender, amountOfMTP);
	}
	
	
	 
	function transferEther(address addressToSendTo, uint256 value) {
		require(msg.sender == ownerAddress);
		addressToSendTo.transfer(value);
	}	
	function changeAllowInvestment(bool _allowInvestment) {
		require(msg.sender == ownerAddress);
		allowInvestment = _allowInvestment;
	}
	function changeSaleTimes(uint256 _saleStartTime, uint256 _saleEndTime) {
		require(msg.sender == ownerAddress);
		saleStartTime = _saleStartTime;
		saleEndTime	= _saleEndTime;
	}
	function changeEtherBonuses(uint256 _lowEtherBonusLimit, uint256 _lowEtherBonusValue, uint256 _midEtherBonusLimit, uint256 _midEtherBonusValue, uint256 _highEtherBonusLimit, uint256 _highEtherBonusValue) {
		require(msg.sender == ownerAddress);
		lowEtherBonusLimit = _lowEtherBonusLimit;
		lowEtherBonusValue = _lowEtherBonusValue;
		midEtherBonusLimit = _midEtherBonusLimit;
		midEtherBonusValue = _midEtherBonusValue;
		highEtherBonusLimit = _highEtherBonusLimit;
		highEtherBonusValue = _highEtherBonusValue;
	}
	function changeTimeBonuses(uint256 _highTimeBonusLimit, uint256 _highTimeBonusValue, uint256 _midTimeBonusLimit, uint256 _midTimeBonusValue, uint256 _lowTimeBonusLimit, uint256 _lowTimeBonusValue) {
		require(msg.sender == ownerAddress);
		highTimeBonusLimit = _highTimeBonusLimit;
		highTimeBonusValue = _highTimeBonusValue;
		midTimeBonusLimit = _midTimeBonusLimit;
		midTimeBonusValue = _midTimeBonusValue;
		lowTimeBonusLimit = _lowTimeBonusLimit;
		lowTimeBonusValue = _lowTimeBonusValue;
	}

}