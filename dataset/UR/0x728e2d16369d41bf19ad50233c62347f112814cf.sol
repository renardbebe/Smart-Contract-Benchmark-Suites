 

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

contract Own {
    address public owner;

    function Own() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Pause is Own {
  bool public stopped;

  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }

   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

contract Puller {

  using SafeMath for uint;
  
  mapping(address => uint) public payments;

  event LogRefundETH(address to, uint value);

  function asyncSend(address dest, uint amount) internal {
    payments[dest] = payments[dest].add(amount);
  }

   
  function withdrawPayments() {
    address payee = msg.sender;
    uint payment = payments[payee];
    
    if (payment == 0) {
      throw;
    }

    if (this.balance < payment) {
      throw;
    }

    payments[payee] = 0;

    if (!payee.send(payment)) {
      throw;
    }
    LogRefundETH(payee,payment);
  }
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

contract Token is StandardToken, Own {
  string public constant name = "TribeToken";
  string public constant symbol = "TRIBE";
  uint public constant decimals = 6;

   
  function Token() {
      totalSupply = 200000000000000;
      balances[msg.sender] = totalSupply;  
  }

   
  function burner(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

}

contract Crowdsale is Pause, Puller {
    
    using SafeMath for uint;

  	struct Backer {
		uint weiReceived;  
		uint coinSent;
	}
    
	 
	 
	uint public constant MAX_CAP = 160000000000000;  
	 
	uint public constant MIN_INVEST_ETHER = 100 finney;  
	 
	uint private constant CROWDSALE_PERIOD = 22 days;  
	 
	uint public constant COIN_PER_ETHER = 3000000000;  


	 
	 
	Token public coin;
     
	address public multisigEther;
	 
	uint public etherReceived;
	 
	uint public coinSentToEther;
   
  uint public coinToBurn;
	 
	uint public startTime;
	 
	uint public endTime;
 	 
	bool public crowdsaleClosed;
	 
	bool public refundsOpen;

	 
	mapping(address => Backer) public backers;


	 
	modifier respectTimeFrame() {
		if ((now < startTime) || (now > endTime )) throw;
		_;
	}
	
	modifier refundStatus() {
		if ((refundsOpen != true )) throw;
		_;
	}

	 
	event LogReceivedETH(address addr, uint value);
	event LogCoinsEmited(address indexed from, uint amount);

	 
	function Crowdsale(address _TRIBEAddress, address _to) {
		coin = Token(_TRIBEAddress);
		multisigEther = _to;
	}
	
	 
	function() stopInEmergency respectTimeFrame payable {
		receiveETH(msg.sender);
	}

	 
	 
	function start() onlyOwner {
		if (startTime != 0) throw;  

		startTime = now ;            
		endTime =  now + CROWDSALE_PERIOD;    
	}

	 
	function receiveETH(address beneficiary) internal {
		if (msg.value < MIN_INVEST_ETHER) throw;  
		
		uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether));  
		if (coinToSend.add(coinSentToEther) > MAX_CAP) throw;	

		Backer backer = backers[beneficiary];
		coin.transfer(beneficiary, coinToSend);  

		backer.coinSent = backer.coinSent.add(coinToSend);
		backer.weiReceived = backer.weiReceived.add(msg.value);  

		etherReceived = etherReceived.add(msg.value);  
		coinSentToEther = coinSentToEther.add(coinToSend);

		 
		LogCoinsEmited(msg.sender ,coinToSend);
		LogReceivedETH(beneficiary, etherReceived); 
	}
	

	 
	function bonus(uint amount) internal constant returns (uint) {
		if (now < startTime.add(7 days)) return amount.add(amount.div(5));    
		return amount;
	}

	 
	function finalize() onlyOwner public {

         
    if(coinSentToEther != MAX_CAP){
        if (now < endTime)  throw;  
    }
		
		if (!multisigEther.send(this.balance)) throw;  
		
		uint remains = coin.balanceOf(this);
		if (remains > 0) {
      coinToBurn = coinToBurn.add(remains);
       
      coin.transfer(owner, remains);
		}
		crowdsaleClosed = true;
	}

	 
   
	function drain() onlyOwner {
    if (!multisigEther.send(this.balance)) throw;  
	}
   
  function coinDrain() onlyOwner {
    uint remains = coin.balanceOf(this);
    coin.transfer(owner, remains);  
	}

	 
	function changeMultisig(address addr) onlyOwner public {
		if (addr == address(0)) throw;
		multisigEther = addr;
	}

	 
	function changeTribeOwner() onlyOwner public {
		coin.transferOwnership(owner);
	}

	 
	function setRefundState() onlyOwner public {
		if(refundsOpen == false){
			refundsOpen = true;
		}else{
			refundsOpen = false;
		}
	}

	 
	 
	 
	 
	function refund(uint _value) refundStatus public {
		
		if (_value != backers[msg.sender].coinSent) throw;  

		coin.transferFrom(msg.sender, address(this), _value);  

		uint ETHToSend = backers[msg.sender].weiReceived;
		backers[msg.sender].weiReceived=0;

		if (ETHToSend > 0) {
			asyncSend(msg.sender, ETHToSend);  
		}
	}

}

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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