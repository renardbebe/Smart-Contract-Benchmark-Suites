 

pragma solidity ^0.4.8;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
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

contract PullPayment {
  mapping(address => uint) public payments;
  event RefundETH(address to, uint value);
   
  function asyncSend(address dest, uint amount) internal {
    payments[dest] += amount;
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
    RefundETH(payee,payment);
  }
}

contract Pausable is Ownable {
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


contract RLC is ERC20, SafeMath, Ownable {

     
  string public name;        
  string public symbol;
  uint8 public decimals;     
  string public version = 'v0.1'; 
  uint public initialSupply;
  uint public totalSupply;
  bool public locked;
   

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyUnlocked() {
    if (msg.sender != owner && locked) throw;
    _;
  }

   

  function RLC() {
     
    locked = true;
     

    initialSupply = 87000000000000000;
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply; 
    name = 'iEx.ec Network Token';         
    symbol = 'RLC';                        
    decimals = 9;                         
  }

  function unlock() onlyOwner {
    locked = false;
  }

  function burn(uint256 _value) returns (bool){
    balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
    totalSupply = safeSub(totalSupply, _value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

  function transfer(address _to, uint _value) onlyUnlocked returns (bool) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyUnlocked returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     
  function approveAndCall(address _spender, uint256 _value, bytes _extraData){    
      TokenSpender spender = TokenSpender(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
      }
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}




contract Crowdsale is SafeMath, PullPayment, Pausable {

  	struct Backer {
		uint weiReceived;	 
		string btc_address;   
		uint satoshiReceived;	 
		uint rlcSent;
	}

	RLC 	public rlc;          
	address public owner;        
	address public multisigETH;  
	address public BTCproxy;	 

	uint public RLCPerETH;       
	uint public RLCPerSATOSHI;   
	uint public ETHReceived;     
	uint public BTCReceived;     
	uint public RLCSentToETH;    
	uint public RLCSentToBTC;    
	uint public startBlock;      
	uint public endBlock;        
	uint public minCap;          
	uint public maxCap;          
	bool public maxCapReached;   
	uint public minInvestETH;    
	uint public minInvestBTC;    
	bool public crowdsaleClosed; 

	address public bounty;		 
	address public reserve; 	 
	address public team;		 

	uint public rlc_bounty;		 
	uint public rlc_reserve;	 
	uint public rlc_team;		 
	mapping(address => Backer) public backers;  

	modifier onlyBy(address a){
		if (msg.sender != a) throw;  
		_;
	}

	modifier minCapNotReached() {
		if ((now<endBlock) || RLCSentToETH + RLCSentToBTC >= minCap ) throw;
		_;
	}

	modifier respectTimeFrame() {
		if ((now < startBlock) || (now > endBlock )) throw;
		_;
	}

	 
	event ReceivedETH(address addr, uint value);
	event ReceivedBTC(address addr, string from, uint value, string txid);
	event RefundBTC(string to, uint value);
	event Logs(address indexed from, uint amount, string value);

	 
	 
	function Crowdsale() {
		owner = msg.sender;
		BTCproxy = 0x75c6cceb1a33f177369053f8a0e840de96b4ed0e;
		rlc = RLC(0x607F4C5BB672230e8672085532f7e901544a7375);
		multisigETH = 0xAe307e3871E5A321c0559FBf0233A38c937B826A;
		team = 0xd65380D773208a6Aa49472Bf55186b855B393298;
		reserve = 0x24F6b37770C6067D05ACc2aD2C42d1Bafde95d48;
		bounty = 0x8226a24dA0870Fb8A128E4Fc15228a9c4a5baC29;
		RLCSentToETH = 0;
		RLCSentToBTC = 0;
		minInvestETH = 1 ether;
		minInvestBTC = 5000000;			 
		startBlock = 0 ;            	 
		endBlock =  0;  				 
		RLCPerETH = 200000000000;		 
		RLCPerSATOSHI = 50000;			 
		minCap=12000000000000000;
		maxCap=60000000000000000;
		rlc_bounty=1700000000000000;	 
		rlc_reserve=1700000000000000;	 
		rlc_team=12000000000000000;
	}

	 
	function() payable {
		if (now > endBlock) throw;
		receiveETH(msg.sender);
	}

	 
	function start() onlyBy(owner) {
		startBlock = now ;            
		endBlock =  now + 30 days;    
	}

	 
	function receiveETH(address beneficiary) internal stopInEmergency  respectTimeFrame  {
		if (msg.value < minInvestETH) throw;								 
		uint rlcToSend = bonus(safeMul(msg.value,RLCPerETH)/(1 ether));		 
		if (safeAdd(rlcToSend, safeAdd(RLCSentToETH, RLCSentToBTC)) > maxCap) throw;	

		Backer backer = backers[beneficiary];
		if (!rlc.transfer(beneficiary, rlcToSend)) throw;     				 
		backer.rlcSent = safeAdd(backer.rlcSent, rlcToSend);
		backer.weiReceived = safeAdd(backer.weiReceived, msg.value);		 
		ETHReceived = safeAdd(ETHReceived, msg.value);						 
		RLCSentToETH = safeAdd(RLCSentToETH, rlcToSend);

		emitRLC(rlcToSend);													 
		ReceivedETH(beneficiary,ETHReceived);								 
	}
	
	 
	function receiveBTC(address beneficiary, string btc_address, uint value, string txid) stopInEmergency respectTimeFrame onlyBy(BTCproxy) returns (bool res){
		if (value < minInvestBTC) throw;											 

		uint rlcToSend = bonus(safeMul(value,RLCPerSATOSHI));						 
		if (safeAdd(rlcToSend, safeAdd(RLCSentToETH, RLCSentToBTC)) > maxCap) {		 
			RefundBTC(btc_address , value);
			return false;
		}

		Backer backer = backers[beneficiary];
		if (!rlc.transfer(beneficiary, rlcToSend)) throw;							 
		backer.rlcSent = safeAdd(backer.rlcSent , rlcToSend);
		backer.btc_address = btc_address;
		backer.satoshiReceived = safeAdd(backer.satoshiReceived, value);
		BTCReceived =  safeAdd(BTCReceived, value);									 
		RLCSentToBTC = safeAdd(RLCSentToBTC, rlcToSend);							 
		emitRLC(rlcToSend);
		ReceivedBTC(beneficiary, btc_address, BTCReceived, txid);
		return true;
	}

	 
	function emitRLC(uint amount) internal {
		rlc_bounty = safeAdd(rlc_bounty, amount/10);
		rlc_team = safeAdd(rlc_team, amount/20);
		rlc_reserve = safeAdd(rlc_reserve, amount/10);
		Logs(msg.sender ,amount, "emitRLC");
	}

	 
	function bonus(uint amount) internal constant returns (uint) {
		if (now < safeAdd(startBlock, 10 days)) return (safeAdd(amount, amount/5));    
		if (now < safeAdd(startBlock, 20 days)) return (safeAdd(amount, amount/10));   
		return amount;
	}

	 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) minCapNotReached public {
		if (msg.sender != address(rlc)) throw; 
		if (_extraData.length != 0) throw;								 
		if (_value != backers[_from].rlcSent) throw;					 
		if (!rlc.transferFrom(_from, address(this), _value)) throw ;	 
		if (!rlc.burn(_value)) throw ;									 
		uint ETHToSend = backers[_from].weiReceived;
		backers[_from].weiReceived=0;
		uint BTCToSend = backers[_from].satoshiReceived;
		backers[_from].satoshiReceived = 0;
		if (ETHToSend > 0) {
			asyncSend(_from,ETHToSend);									 
		}
		if (BTCToSend > 0)
			RefundBTC(backers[_from].btc_address ,BTCToSend);			 
	}

	 
	function setRLCPerETH(uint rate) onlyBy(BTCproxy) {
		RLCPerETH=rate;
	}
	
	 
	function finalize() onlyBy(owner) {
		 
		if (RLCSentToETH + RLCSentToBTC < maxCap - 5000000000000 && now < endBlock) throw;	 
		if (RLCSentToETH + RLCSentToBTC < minCap && now < endBlock + 15 days) throw ;		 
		if (!multisigETH.send(this.balance)) throw;											 
		if (rlc_reserve > 6000000000000000){												 
			if(!rlc.transfer(reserve,6000000000000000)) throw;								 
			rlc_reserve = 6000000000000000;
		} else {
			if(!rlc.transfer(reserve,rlc_reserve)) throw;  
		}
		if (rlc_bounty > 6000000000000000){
			if(!rlc.transfer(bounty,6000000000000000)) throw;								 
			rlc_bounty = 6000000000000000;
		} else {
			if(!rlc.transfer(bounty,rlc_bounty)) throw;
		}
		if (!rlc.transfer(team,rlc_team)) throw;
		uint RLCEmitted = rlc_reserve + rlc_bounty + rlc_team + RLCSentToBTC + RLCSentToETH;
		if (RLCEmitted < rlc.totalSupply())													 
			  rlc.burn(rlc.totalSupply() - RLCEmitted);
		rlc.unlock();
		crowdsaleClosed = true;
	}

	 
	function drain() onlyBy(owner) {
		if (!owner.send(this.balance)) throw;
	}
}