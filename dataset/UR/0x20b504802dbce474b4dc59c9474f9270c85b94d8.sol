 

pragma solidity ^0.4.18;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
 
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

  
  
  
  
  
  
  
  
  
  
  
  
contract DaRiCpAy is StandardToken {
	using SafeMath for uint256;

     
    event CreatedIRC(address indexed _creator, uint256 _amountOfIRC);

	
	 
	string public constant name = "DaRiC";
	string public constant symbol = "IRC";
	uint256 public constant decimals = 18;
	string public version = "1.0";

	 
	uint256 public maxPresaleSupply; 	 

	 
	uint256 public constant preSaleStartTime = 1516406400; 	 
	uint256 public constant preSaleEndTime = 1518220800 ; 	 
	uint256 public saleStartTime = 1518267600 ;  
	uint256 public saleEndTime = 1522429200;  


	 
	uint256 public lowEtherBonusLimit = 5 * 1 ether;				 
	uint256 public lowEtherBonusValue = 110;						 
	uint256 public midEtherBonusLimit = 24 * 1 ether; 		    	 
	uint256 public midEtherBonusValue = 115;						 
	uint256 public highEtherBonusLimit = 50 * 1 ether; 				 
	uint256 public highEtherBonusValue = 120; 						 
	uint256 public highTimeBonusLimit = 0; 							 
	uint256 public highTimeBonusValue = 115; 						 
	uint256 public midTimeBonusLimit = 1036800; 					 
	uint256 public midTimeBonusValue = 110; 						 
	uint256 public lowTimeBonusLimit = 3124800;						 
	uint256 public lowTimeBonusValue = 105;							 

	 
	uint256 public constant IRC_PER_ETH_PRE_SALE = 10000;  			 
	uint256 public constant IRC_PER_ETH_SALE = 8000;  				 
	
	 
	address public constant ownerAddress = 0x88ce817Efd0dD935Eed8e9d553167d08870AA6e7; 	 

	 
	bool public allowInvestment = true;								 
	uint256 public totalWEIInvested = 0; 							 
	uint256 public totalIRCAllocated = 0;							 
	mapping (address => uint256) public WEIContributed; 			 


	 
	function DaRiCpAy() {
		require(msg.sender == ownerAddress);

		totalSupply = 20*1000000*1000000000000000000; 				 
		uint256 totalIRCReserved = totalSupply.mul(20).div(100);	 
		maxPresaleSupply = totalSupply*8/1000 + totalIRCReserved; 	 

		balances[msg.sender] = totalIRCReserved;
		totalIRCAllocated = totalIRCReserved;				
	}


	 
	function() payable {

		require(allowInvestment);

		 
		uint256 amountOfWei = msg.value;
		require(amountOfWei >= 10000000000000);

		uint256 amountOfIRC = 0;
		uint256 absLowTimeBonusLimit = 0;
		uint256 absMidTimeBonusLimit = 0;
		uint256 absHighTimeBonusLimit = 0;
		uint256 totalIRCAvailable = 0;

		 
		if (now > preSaleStartTime && now < preSaleEndTime) {
			 
			amountOfIRC = amountOfWei.mul(IRC_PER_ETH_PRE_SALE);
			absLowTimeBonusLimit = preSaleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = preSaleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = preSaleStartTime + highTimeBonusLimit;
			totalIRCAvailable = maxPresaleSupply - totalIRCAllocated;
		} else if (now > saleStartTime && now < saleEndTime) {
			 
			amountOfIRC = amountOfWei.mul(IRC_PER_ETH_SALE);
			absLowTimeBonusLimit = saleStartTime + lowTimeBonusLimit;
			absMidTimeBonusLimit = saleStartTime + midTimeBonusLimit;
			absHighTimeBonusLimit = saleStartTime + highTimeBonusLimit;
			totalIRCAvailable = totalSupply - totalIRCAllocated;
		} else {
			 
			revert();
		}

		 
		assert(amountOfIRC > 0);

		 
		if (amountOfWei >= highEtherBonusLimit) {
			amountOfIRC = amountOfIRC.mul(highEtherBonusValue).div(100);
		} else if (amountOfWei >= midEtherBonusLimit) {
			amountOfIRC = amountOfIRC.mul(midEtherBonusValue).div(100);
		} else if (amountOfWei >= lowEtherBonusLimit) {
			amountOfIRC = amountOfIRC.mul(lowEtherBonusValue).div(100);
		}
		if (now >= absLowTimeBonusLimit) {
			amountOfIRC = amountOfIRC.mul(lowTimeBonusValue).div(100);
		} else if (now >= absMidTimeBonusLimit) {
			amountOfIRC = amountOfIRC.mul(midTimeBonusValue).div(100);
		} else if (now >= absHighTimeBonusLimit) {
			amountOfIRC = amountOfIRC.mul(highTimeBonusValue).div(100);
		}

		 
		assert(amountOfIRC <= totalIRCAvailable);

		 
		totalIRCAllocated = totalIRCAllocated + amountOfIRC;

		 
		uint256 balanceSafe = balances[msg.sender].add(amountOfIRC);
		balances[msg.sender] = balanceSafe;

		 
		totalWEIInvested = totalWEIInvested.add(amountOfWei);

		 
		uint256 contributedSafe = WEIContributed[msg.sender].add(amountOfWei);
		WEIContributed[msg.sender] = contributedSafe;

		 
		assert(totalIRCAllocated <= totalSupply);
		assert(totalIRCAllocated > 0);
		assert(balanceSafe > 0);
		assert(totalWEIInvested > 0);
		assert(contributedSafe > 0);

		 
		CreatedIRC(msg.sender, amountOfIRC);
	}
	
	
	 
	function transferEther(address addressToSendTo, uint256 value) {
		require(msg.sender == ownerAddress);
		addressToSendTo;
		addressToSendTo.transfer(value) ;
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