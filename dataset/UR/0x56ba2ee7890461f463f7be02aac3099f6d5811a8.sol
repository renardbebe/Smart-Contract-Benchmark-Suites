 

pragma solidity^0.4.11;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract CATToken is StandardToken {
	using SafeMath for uint256;
	
	 
	string public constant HIDDEN_CAP = "0xd22f19d54193ff5e08e7ba88c8e52ec1b9fc8d4e0cf177e1be8a764fa5b375fa";
	
	 
	event CreatedCAT(address indexed _creator, uint256 _amountOfCAT);
	event CATRefundedForWei(address indexed _refunder, uint256 _amountOfWei);
	
	 
	string public constant name = "BlockCAT Token";
	string public constant symbol = "CAT";
	uint256 public constant decimals = 18;   
	string public version = "1.0";
	
	 
	address public executor;
	address public devETHDestination;
	address public devCATDestination;
	address public reserveCATDestination;
	
	 
	bool public saleHasEnded;
	bool public minCapReached;
	bool public allowRefund;
	mapping (address => uint256) public ETHContributed;
	uint256 public totalETHRaised;
	uint256 public saleStartBlock;
	uint256 public saleEndBlock;
	uint256 public saleFirstEarlyBirdEndBlock;
	uint256 public saleSecondEarlyBirdEndBlock;
	uint256 public constant DEV_PORTION = 20;   
	uint256 public constant RESERVE_PORTION = 1;   
	uint256 public constant ADDITIONAL_PORTION = DEV_PORTION + RESERVE_PORTION;
	uint256 public constant SECURITY_ETHER_CAP = 1000000 ether;
	uint256 public constant CAT_PER_ETH_BASE_RATE = 300;   
	uint256 public constant CAT_PER_ETH_FIRST_EARLY_BIRD_RATE = 330;
	uint256 public constant CAT_PER_ETH_SECOND_EARLY_BIRD_RATE = 315;
	
	function CATToken(
		address _devETHDestination,
		address _devCATDestination,
		address _reserveCATDestination,
		uint256 _saleStartBlock,
		uint256 _saleEndBlock
	) {
		 
		if (_devETHDestination == address(0x0)) throw;
		if (_devCATDestination == address(0x0)) throw;
		if (_reserveCATDestination == address(0x0)) throw;
		 
		if (_saleEndBlock <= block.number) throw;
		 
		if (_saleEndBlock <= _saleStartBlock) throw;

		executor = msg.sender;
		saleHasEnded = false;
		minCapReached = false;
		allowRefund = false;
		devETHDestination = _devETHDestination;
		devCATDestination = _devCATDestination;
		reserveCATDestination = _reserveCATDestination;
		totalETHRaised = 0;
		saleStartBlock = _saleStartBlock;
		saleEndBlock = _saleEndBlock;
		saleFirstEarlyBirdEndBlock = saleStartBlock + 6171;   
		saleSecondEarlyBirdEndBlock = saleFirstEarlyBirdEndBlock + 12342;   

		totalSupply = 0;
	}
	
	function createTokens() payable external {
		 
		if (saleHasEnded) throw;
		if (block.number < saleStartBlock) throw;
		if (block.number > saleEndBlock) throw;
		 
		uint256 newEtherBalance = totalETHRaised.add(msg.value);
		if (newEtherBalance > SECURITY_ETHER_CAP) throw; 
		 
		if (0 == msg.value) throw;
		
		 
		uint256 curTokenRate = CAT_PER_ETH_BASE_RATE;
		if (block.number < saleFirstEarlyBirdEndBlock) {
			curTokenRate = CAT_PER_ETH_FIRST_EARLY_BIRD_RATE;
		}
		else if (block.number < saleSecondEarlyBirdEndBlock) {
			curTokenRate = CAT_PER_ETH_SECOND_EARLY_BIRD_RATE;
		}
		
		 
		uint256 amountOfCAT = msg.value.mul(curTokenRate);
		
		 
		uint256 totalSupplySafe = totalSupply.add(amountOfCAT);
		uint256 balanceSafe = balances[msg.sender].add(amountOfCAT);
		uint256 contributedSafe = ETHContributed[msg.sender].add(msg.value);

		 
		totalSupply = totalSupplySafe;
		balances[msg.sender] = balanceSafe;

		totalETHRaised = newEtherBalance;
		ETHContributed[msg.sender] = contributedSafe;

		CreatedCAT(msg.sender, amountOfCAT);
	}
	
	function endSale() {
		 
		if (saleHasEnded) throw;
		 
		if (!minCapReached) throw;
		 
		if (msg.sender != executor) throw;
		
		saleHasEnded = true;

		 
		uint256 additionalCAT = (totalSupply.mul(ADDITIONAL_PORTION)).div(100 - ADDITIONAL_PORTION);
		uint256 totalSupplySafe = totalSupply.add(additionalCAT);

		uint256 reserveShare = (additionalCAT.mul(RESERVE_PORTION)).div(ADDITIONAL_PORTION);
		uint256 devShare = additionalCAT.sub(reserveShare);

		totalSupply = totalSupplySafe;
		balances[devCATDestination] = devShare;
		balances[reserveCATDestination] = reserveShare;
		
		CreatedCAT(devCATDestination, devShare);
		CreatedCAT(reserveCATDestination, reserveShare);

		if (this.balance > 0) {
			if (!devETHDestination.call.value(this.balance)()) throw;
		}
	}

	 
	function withdrawFunds() {
		 
		if (!minCapReached) throw;
		if (0 == this.balance) throw;

		if (!devETHDestination.call.value(this.balance)()) throw;
	}
	
	 
	function triggerMinCap() {
		if (msg.sender != executor) throw;

		minCapReached = true;
	}

	 
	function triggerRefund() {
		 
		if (saleHasEnded) throw;
		 
		if (minCapReached) throw;
		 
		if (block.number < saleEndBlock) throw;
		if (msg.sender != executor) throw;

		allowRefund = true;
	}

	function refund() external {
		 
		if (!allowRefund) throw;
		 
		if (0 == ETHContributed[msg.sender]) throw;

		 
		uint256 etherAmount = ETHContributed[msg.sender];
		ETHContributed[msg.sender] = 0;

		CATRefundedForWei(msg.sender, etherAmount);
		if (!msg.sender.send(etherAmount)) throw;
	}

	function changeDeveloperETHDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devETHDestination = _newAddress;
	}
	
	function changeDeveloperCATDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		devCATDestination = _newAddress;
	}
	
	function changeReserveCATDestinationAddress(address _newAddress) {
		if (msg.sender != executor) throw;
		reserveCATDestination = _newAddress;
	}
	
	function transfer(address _to, uint _value) {
		 
		if (!minCapReached) throw;
		
		super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint _value) {
		 
		if (!minCapReached) throw;
		
		super.transferFrom(_from, _to, _value);
	}
}