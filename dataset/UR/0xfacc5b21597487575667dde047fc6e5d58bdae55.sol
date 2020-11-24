 

pragma solidity ^0.4.15;

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  bool public stopped;

  modifier stopInEmergency {
    require(!stopped);
    _;
  }
  
  modifier onlyInEmergency {
    require(stopped);
    _;
  }

   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

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

contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

   
  function withdrawPayments() {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }
}

contract Crowdsale is Pausable, PullPayment {

    using SafeMath for uint;

  	struct Backer {
		uint weiReceived;  
		uint256 coinSent;
	}


	 
	 
	uint public constant MIN_CAP = 100000 ether;  

	 
	uint public constant MAX_CAP = 8000000 ether;  

	 
	uint public constant MIN_BUY_ETHER = 100 finney;

     
    struct Potential_Investor {
		uint weiReceived;  
		uint256 coinSent;
        uint  profitshare;  
    }
    uint public constant MIN_INVEST_BUY = 2000 ether;

     

    uint  public  MAX_INVEST_SHARE = 4900;  

 
	uint private constant CROWDSALE_PERIOD = 62 days;

	 
	uint public constant COIN_PER_ETHER = 500;  

	uint public constant BIGSELL = COIN_PER_ETHER * 100 ether;  


	 
	 
	DARFtoken public coin;

     
	address public multisigEther;

	 
	uint public etherReceived;

	 
	uint public coinSentToEther;

	 
	uint public invcoinSentToEther;


	 
	uint public startTime;

	 
	uint public endTime;

 	 
	bool public crowdsaleClosed;

	 
	mapping(address => Backer) public backers;

    mapping(address => Potential_Investor) public Potential_Investors;  


	 
	modifier minCapNotReached() {
		require(!((now < endTime) || coinSentToEther >= MIN_CAP ));
		_;
	}

	modifier respectTimeFrame() {
		require(!((now < startTime) || (now > endTime )));
		_;
	}

	 
	event LogReceivedETH(address addr, uint value);
	event LogCoinsEmited(address indexed from, uint amount);
	event LogInvestshare(address indexed from, uint share);

	 
	function Crowdsale(address _DARFtokenAddress, address _to) {
		coin = DARFtoken(_DARFtokenAddress);
		multisigEther = _to;
	}

	 
	function() stopInEmergency respectTimeFrame payable {
		receiveETH(msg.sender);
	}

	 
	function start() onlyOwner {
		require (startTime == 0);

		startTime = now ;
		endTime =  now + CROWDSALE_PERIOD;
	}

	 
	function receiveETH(address beneficiary) internal {
		require(!(msg.value < MIN_BUY_ETHER));  
        if (multisigEther ==  beneficiary) return ;  
    uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER)); 
		require(!(coinToSend.add(coinSentToEther) > MAX_CAP));

        Backer backer = backers[beneficiary];
		coin.transfer(beneficiary, coinToSend);  

		backer.coinSent = backer.coinSent.add(coinToSend);
		backer.weiReceived = backer.weiReceived.add(msg.value);  
        multisigEther.send(msg.value);

        if (backer.weiReceived > MIN_INVEST_BUY) {

             
            uint share = msg.value.mul(10000).div(MIN_INVEST_BUY);  
			 
			LogInvestshare(msg.sender,share);
			if (MAX_INVEST_SHARE > share) {

				Potential_Investor potential_investor = Potential_Investors[beneficiary];
				potential_investor.coinSent = backer.coinSent;
				potential_investor.weiReceived = backer.weiReceived;  
                 
				if (potential_investor.profitshare == 0 ) {
					uint startshare = potential_investor.weiReceived.mul(10000).div(MIN_INVEST_BUY);
					MAX_INVEST_SHARE = MAX_INVEST_SHARE.sub(startshare);
					potential_investor.profitshare = potential_investor.profitshare.add(startshare);
				} else {
					MAX_INVEST_SHARE = MAX_INVEST_SHARE.sub(share);
					potential_investor.profitshare = potential_investor.profitshare.add(share);
					LogInvestshare(msg.sender,potential_investor.profitshare);

				}
            }

        }

		etherReceived = etherReceived.add(msg.value);  
		coinSentToEther = coinSentToEther.add(coinToSend);

		 
		LogCoinsEmited(msg.sender ,coinToSend);
		LogReceivedETH(beneficiary, etherReceived);
	}


	 
	function bonus(uint256 amount) internal constant returns (uint256) {
		 

		if (amount >=  BIGSELL ) {
				amount = amount.add(amount.div(10).mul(3));
		} 
		if (now < startTime.add(16 days)) return amount.add(amount.div(4));    
		if (now < startTime.add(18 days)) return amount.add(amount.div(5));    
		if (now < startTime.add(22 days)) return amount.add(amount.div(20).mul(3));    
		if (now < startTime.add(25 days)) return amount.add(amount.div(10));    
		if (now < startTime.add(28 days)) return amount.add(amount.div(20));    


		return amount;
	}

 
	function finalize() onlyOwner public {

		if (now < endTime) {  
			require (coinSentToEther == MAX_CAP);
		}

		require(!(coinSentToEther < MIN_CAP && now < endTime + 15 days));  

		require(multisigEther.send(this.balance));  

		uint remains = coin.balanceOf(this);
		 
		 
		 
		 
		crowdsaleClosed = true;
	}

	 
	function drain() onlyOwner {
		require(owner.send(this.balance)) ;
	}

	 
	function setMultisig(address addr) onlyOwner public {
		require(addr != address(0)) ;
		multisigEther = addr;
	}

	 
	function backDARFtokenOwner() onlyOwner public {
		coin.transferOwnership(owner);
	}

	 
	function getRemainCoins() onlyOwner public {
		var remains = MAX_CAP - coinSentToEther;
		uint minCoinsToSell = bonus(MIN_BUY_ETHER.mul(COIN_PER_ETHER) / (1 ether));

		require(!(remains > minCoinsToSell));

		Backer backer = backers[owner];
		coin.transfer(owner, remains);  

		backer.coinSent = backer.coinSent.add(remains);


        coinSentToEther = coinSentToEther.add(remains);

		 
		LogCoinsEmited(this ,remains);
		LogReceivedETH(owner, etherReceived);
	}


	 
	function refund(uint _value) minCapNotReached public {

		require (_value == backers[msg.sender].coinSent) ;  

		coin.transferFrom(msg.sender, address(this), _value);  
		 
		 

		uint ETHToSend = backers[msg.sender].weiReceived;
		backers[msg.sender].weiReceived=0;

		if (ETHToSend > 0) {
			asyncSend(msg.sender, ETHToSend);  
		}
	}

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract DARFtoken is StandardToken, Ownable {
  string public constant name = "DARFtoken";
  string public constant symbol = "DAR";
  uint public constant decimals = 18;


   
  function DARFtoken() {
      totalSupply = 84000000 ether;  
      balances[msg.sender] = totalSupply;  
  }

   
  function burn(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

}