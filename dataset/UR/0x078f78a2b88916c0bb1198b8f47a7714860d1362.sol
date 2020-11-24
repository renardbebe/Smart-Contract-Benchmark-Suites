 

pragma solidity ^0.4.11;

 
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
	
	function toUINT112(uint256 a) internal constant returns(uint112) {
		assert(uint112(a) == a);
		return uint112(a);
	}
	
	function toUINT120(uint256 a) internal constant returns(uint120) {
		assert(uint120(a) == a);
		return uint120(a);
	}
	
	function toUINT128(uint256 a) internal constant returns(uint128) {
		assert(uint128(a) == a);
		return uint128(a);
	}
	
	function percent(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = (b*a/100) ;
		assert(c <= a);
		return c;
	}
}

contract Owned {
	
	address public owner;
	
	function Owned() {
		owner = msg.sender;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	function setOwner(address _newOwner) onlyOwner {
		owner = _newOwner;
	}
}

 
contract ERC20Basic {
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;
	
	struct Account {
		uint256 balances;
		uint256 rawTokens;
		uint32 lastMintedTimestamp;
	}
	
	 
	mapping(address => Account) accounts;
	
	
	 
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= accounts[msg.sender].balances);
		
		 
		accounts[msg.sender].balances = accounts[msg.sender].balances.sub(_value);
		accounts[_to].balances = accounts[_to].balances.add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}
	
	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return accounts[_owner].balances;
	}
	
}

 
contract StandardToken is ERC20, BasicToken {
	
	mapping (address => mapping (address => uint256)) internal allowed;
	
	
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= accounts[_from].balances);
		require(_value <= allowed[_from][msg.sender]);
		
		accounts[_from].balances = accounts[_from].balances.sub(_value);
		accounts[_to].balances = accounts[_to].balances.add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}
	
	 
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
	
	 
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	 
	function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract TTC is StandardToken, Owned {
	string public constant name    = "TECHTRADECOIN";  
	uint8 public constant decimals = 8;               
	string public constant symbol  = "TTC";
	bool public canClaimToken = false;
	uint256 public constant maxSupply  = 300000000*10**uint256(decimals);
	uint256 public constant dateInit=1516924800 ;
	
	 
	uint256 public constant dateICO=dateInit + 50 days;
	uint256 public constant dateRelease3=dateICO + 90 days;
	uint256 public constant dateRelease6=dateRelease3 + 90 days;
	uint256 public constant dateRelease9=dateRelease6 + 90 days;
	uint256 public constant dateRelease12=dateRelease9 + 90 days;
	
	uint256 public constant dateEcoRelease3=dateRelease12 + 90 days;
	uint256 public constant dateEcoRelease6=dateEcoRelease3 + 90 days;
	uint256 public constant dateEcoRelease9=dateEcoRelease6 + 90 days;
	uint256 public constant dateEcoRelease12=dateEcoRelease9 + 90 days;

	bool public isAllocatedICO=false;
	
	bool public isAllocatedLending=false;
	
	bool public isAllocated3=false;
	bool public isAllocated6=false;
	bool public isAllocated9=false;
	bool public isAllocated12=false;
	
	bool public isEcoAllocated3=false;
	bool public isEcoAllocated6=false;
	bool public isEcoAllocated9=false;
	bool public isEcoAllocated12=false;
	
	enum Stage {
		Finalized,
		ICO,
		Release3,
		Release6,
		Release9,
		Release12,
		Eco3,
		Eco6,
		Eco9,
		Eco12
	}
	
	struct Supplies {
		uint256 total;
		uint256 rawTokens;
	}
	
	 
	struct StageRelease {
		uint256 rawTokens;
		uint256 totalRawTokens;
	}
	
	Supplies supplies;
	StageRelease public stageICO=StageRelease(maxSupply.percent(21),maxSupply.percent(21));
	StageRelease public stageLending=StageRelease(maxSupply.percent(25),maxSupply.percent(25));
	StageRelease public stageDevelop=StageRelease(maxSupply.percent(35),maxSupply.percent(35));
	StageRelease public stageMarketing=StageRelease(maxSupply.percent(5),maxSupply.percent(5));
	StageRelease public stageAdmin=StageRelease(maxSupply.percent(2), maxSupply.percent(2));
	StageRelease public stageEco=StageRelease(maxSupply.percent(12), maxSupply.percent(12));
	
	 
	function () {
		revert();
	}
	 
	function totalSupply() public constant returns (uint256 total) {
		return supplies.total;
	}
	
	function mintToken(address _owner, uint256 _amount, bool _isRaw) onlyOwner internal {
		require(_amount.add(supplies.total)<=maxSupply);
		if (_isRaw) {
			accounts[_owner].rawTokens=_amount.add(accounts[_owner].rawTokens);
			supplies.rawTokens=_amount.add(supplies.rawTokens);
			} else {
			accounts[_owner].balances=_amount.add(accounts[_owner].balances);
		}
		supplies.total=_amount.add(supplies.total);
		Transfer(0, _owner, _amount);
	}
	
	function transferRaw(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= accounts[msg.sender].rawTokens);
		
		
		 
		accounts[msg.sender].rawTokens = accounts[msg.sender].rawTokens.sub(_value);
		accounts[_to].rawTokens = accounts[_to].rawTokens.add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}
	
	function setClaimToken(bool approve) onlyOwner public returns (bool) {
		canClaimToken=true;
		return canClaimToken;
	}
	
	function claimToken(address _owner) public returns (bool amount) {
		require(accounts[_owner].rawTokens!=0);
		require(canClaimToken);
		
		uint256 amountToken = accounts[_owner].rawTokens;
		accounts[_owner].rawTokens = 0;
		accounts[_owner].balances = amountToken + accounts[_owner].balances;
		return true;
	}
	
	function balanceOfRaws(address _owner) public constant returns (uint256 balance) {
		return accounts[_owner].rawTokens;
	}
	
	function blockTime() constant returns (uint32) {
		return uint32(block.timestamp);
	}
	
	function stage() constant returns (Stage) {
		
		if(blockTime()<=dateICO) {
			return Stage.ICO;
		}
		
		if(blockTime()<=dateRelease3) {
			return Stage.Release3;
		}
		
		if(blockTime()<=dateRelease6) {
			return Stage.Release6;
		}
		
		if(blockTime()<=dateRelease9) {
			return Stage.Release9;
		}
		
		if(blockTime()<=dateRelease12) {
			return Stage.Release12;
		}
		
		if(blockTime()<=dateEcoRelease3) {
			return Stage.Eco3;
		}
		
		if(blockTime()<=dateEcoRelease6) {
			return Stage.Eco6;
		}
		
		if(blockTime()<=dateEcoRelease9) {
			return Stage.Eco9;
		}
		
		if(blockTime()<=dateEcoRelease12) {
			return Stage.Eco12;
		}
		
		return Stage.Finalized;
	}
	
	function releaseStage (uint256 amount, StageRelease storage stageRelease, bool isRaw) internal returns (uint256) {
		if(stageRelease.rawTokens>0) {
			int256 remain=int256(stageRelease.rawTokens - amount);
			if(remain<0)
			amount=stageRelease.rawTokens;
			stageRelease.rawTokens=stageRelease.rawTokens.sub(amount);
			mintToken(owner, amount, isRaw);
			return amount;
		}
		return 0;
	}
	
	function releaseNotEco(uint256 percent, bool isRaw) internal returns (uint256) {
		
		uint256 amountDevelop = stageDevelop.totalRawTokens.percent(percent);
		uint256 amountMarketing = stageMarketing.totalRawTokens.percent(percent);
		uint256 amountAdmin = stageAdmin.totalRawTokens.percent(percent);
		uint256 amountSum = amountDevelop+amountMarketing+amountAdmin;
		
		releaseStage(amountDevelop, stageDevelop, isRaw);
		releaseStage(amountMarketing, stageMarketing, isRaw);
		releaseStage(amountAdmin, stageAdmin, isRaw);
		return amountSum;
	}
	
	function releaseEco(uint256 percent, bool isRaw) internal returns (uint256) {
		uint256 amountEco = stageEco.totalRawTokens.percent(percent);
		releaseStage(amountEco, stageEco, isRaw);      
		return amountEco;
	}
	
	function release100Percent(bool isRaw, StageRelease storage stageRelease) internal returns (uint256) {
		uint256 amount = stageRelease.totalRawTokens.percent(100);
		releaseStage(amount, stageRelease, isRaw);      
		return amount;
	}
	
	 
	 
	function release(bool isRaw) onlyOwner public returns (uint256) {
		uint256 amountSum=0;
		
		if(stage()==Stage.ICO && isAllocatedICO==false) {
			uint256 amountICO=release100Percent(isRaw, stageICO);
			amountSum=amountSum.add(amountICO);
			isAllocatedICO=true;
			return amountSum;
		}
		
		if(stage()==Stage.Release3 && isAllocated3==false) {
			uint256 amountRelease3=releaseNotEco(30, isRaw);
			amountSum=amountSum.add(amountRelease3);
			 
			amountRelease3=release100Percent(isRaw, stageLending);
			amountSum=amountSum.add(amountRelease3);
			isAllocated3=true;
			return amountSum;
		}
		
		if(stage()==Stage.Release6 && isAllocated6==false) {
			uint256 amountRelease6=releaseNotEco(20, isRaw);
			amountSum=amountSum.add(amountRelease6);
			isAllocated6=true;
			return amountSum;
		}
		
		if(stage()==Stage.Release9 && isAllocated9==false) {
			uint256 amountRelease9=releaseNotEco(28, isRaw);
			amountSum=amountSum.add(amountRelease9);
			isAllocated9=true;
			return amountSum;
		}
		
		if(stage()==Stage.Release12 && isAllocated12==false) {
			uint256 amountRelease12=releaseNotEco(22, isRaw);
			amountSum=amountSum.add(amountRelease12);
			isAllocated12=true;
			return amountSum;
		}
		
		if(stage()==Stage.Eco3 && isEcoAllocated3==false) {
			uint256 amountEcoRelease3=releaseEco(30, isRaw);
			amountSum=amountSum.add(amountEcoRelease3);
			isEcoAllocated3=true;
			return amountSum;
		}
		
		if(stage()==Stage.Eco6 && isEcoAllocated6==false) {
			uint256 amountEcoRelease6=releaseEco(20, isRaw);
			amountSum=amountSum.add(amountEcoRelease6);
			isEcoAllocated6=true;
			return amountSum;
		}
		
		if(stage()==Stage.Eco9 && isEcoAllocated9==false) {
			uint256 amountEcoRelease9=releaseEco(28, isRaw);
			amountSum=amountSum.add(amountEcoRelease9);
			isEcoAllocated9=true;
			return amountSum;
		}
		if(stage()==Stage.Eco12 && isEcoAllocated12==false) {
			uint256 amountEcoRelease12=releaseEco(22, isRaw);
			amountSum=amountSum.add(amountEcoRelease12);
			isEcoAllocated12=true;
			return amountSum;
		}
		return amountSum;
	}
}