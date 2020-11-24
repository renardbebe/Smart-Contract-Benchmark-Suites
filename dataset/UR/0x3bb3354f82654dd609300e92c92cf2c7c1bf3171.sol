 

 

 

pragma solidity ^0.4.23;

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}
 
contract System {
	using SafeMath for uint256;
	
	address owner;
	
	 

	 
	modifier onlyOwner() {
		if (msg.sender != owner) {
			error('System: onlyOwner function called by user that is not owner');
		} else {
			_;
		}
	}

	 
	
	 
	function error(string _error) internal {
		revert(_error);
		 
		 
		 
	}

	 
	function whoAmI() public constant returns (address) {
		return msg.sender;
	}
	
	 
	function timestamp() public constant returns (uint256) {
		return block.timestamp;
	}
	
	 
	function contractBalance() public constant returns (uint256) {
		return address(this).balance;
	}
	
	 
	constructor() public {
		 
		owner = msg.sender;
		
		 
		if(owner == 0x0) error('System constructor: Owner address is 0x0');  
	}
	
	 

	 
	event Error(string _error);

	 
	event DebugUint256(uint256 _data);

}

 
contract Haltable is System {
	bool public halted;
	
	 

	modifier stopInEmergency {
		if (halted) {
			error('Haltable: stopInEmergency function called and contract is halted');
		} else {
			_;
		}
	}

	modifier onlyInEmergency {
		if (!halted) {
			error('Haltable: onlyInEmergency function called and contract is not halted');
		} {
			_;
		}
	}

	 
	
	 
	function halt() external onlyOwner {
		halted = true;
		emit Halt(true, msg.sender, timestamp());  
	}

	 
	function unhalt() external onlyOwner onlyInEmergency {
		halted = false;
		emit Halt(false, msg.sender, timestamp());  
	}
	
	 
	 
	event Halt(bool _switch, address _halter, uint256 _timestamp);
}

 
contract HardcodedWallets {
	 

	address public walletFounder1;  
	address public walletFounder2;  
	address public walletFounder3;  
	address public walletCommunityReserve;	 
	address public walletCompanyReserve;	 
	address public walletTeamAdvisors;		 
	address public walletBountyProgram;		 


	 

	 
	constructor() public {
		 
		walletFounder1             = 0x5E69332F57Ac45F5fCA43B6b007E8A7b138c2938;  
		walletFounder2             = 0x852f9a94a29d68CB95Bf39065BED6121ABf87607;  
		walletFounder3             = 0x0a339965e52dF2c6253989F5E9173f1F11842D83;  

		 
		walletCommunityReserve = 0xB79116a062939534042d932fe5DF035E68576547;
		walletCompanyReserve = 0xA6845689FE819f2f73a6b9C6B0D30aD6b4a006d8;
		walletTeamAdvisors = 0x0227038b2560dF1abf3F8C906016Af0040bc894a;
		walletBountyProgram = 0xdd401Df9a049F6788cA78b944c64D21760757D73;

	}
}

 
contract ERC20 {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _amount) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	function totalSupply() public constant returns (uint);
}

 
contract Escrow is System, HardcodedWallets {
	using SafeMath for uint256;

	 
	mapping (address => uint256) public deposited;
	uint256 nextStage;

	 
	address public addressSCICO;

	 
	address public addressSCTokens;
	Tokens public SCTokens;


	 

	 
	constructor() public {
		 
		uint256 totalSupply = 1350000000 ether;


		deposited[this] = totalSupply.mul(50).div(100);
		deposited[walletCommunityReserve] = totalSupply.mul(20).div(100);
		deposited[walletCompanyReserve] = totalSupply.mul(14).div(100);
		deposited[walletTeamAdvisors] = totalSupply.mul(15).div(100);
		deposited[walletBountyProgram] = totalSupply.mul(1).div(100);
	}

	function deposit(uint256 _amount) public returns (bool) {
		 
		if (msg.sender != addressSCICO) {
			error('Escrow: not allowed to deposit');
			return false;
		}
		deposited[this] = deposited[this].add(_amount);
		return true;
	}

	 
	function withdraw(address _address, uint256 _amount) public onlyOwner returns (bool) {
		if (deposited[_address]<_amount) {
			error('Escrow: not enough balance');
			return false;
		}
		deposited[_address] = deposited[_address].sub(_amount);
		return SCTokens.transfer(_address, _amount);
	}

	 
	function fundICO(uint256 _amount, uint8 _stage) public returns (bool) {
		if(nextStage !=_stage) {
			error('Escrow: ICO stage already funded');
			return false;
		}

		if (msg.sender != addressSCICO || tx.origin != owner) {
			error('Escrow: not allowed to fund the ICO');
			return false;
		}
		if (deposited[this]<_amount) {
			error('Escrow: not enough balance');
			return false;
		}
		bool success = SCTokens.transfer(addressSCICO, _amount);
		if(success) {
			deposited[this] = deposited[this].sub(_amount);
			nextStage++;
			emit FundICO(addressSCICO, _amount);
		}
		return success;
	}

	 
	function setMyICOContract(address _SCICO) public onlyOwner {
		addressSCICO = _SCICO;
	}

	 
	function setTokensContract(address _addressSCTokens) public onlyOwner {
		addressSCTokens = _addressSCTokens;
		SCTokens = Tokens(_addressSCTokens);
	}

	 
	function balanceOf(address _address) public constant returns (uint256 balance) {
		return deposited[_address];
	}


	 

	 
	event FundICO(address indexed _addressICO, uint256 _amount);


}

contract ComplianceService {
	function validate(address _from, address _to, uint256 _amount) public returns (bool allowed) {
		return true;
	}
}



 
contract Tokens is HardcodedWallets, ERC20, Haltable {

	 

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint256 public _totalSupply; 

	 
	string public name;
	string public symbol;
	uint8 public decimals;
	string public standard = 'H0.1';  

	 
	uint256 public timelockEndTime;

	 
	address public addressSCICO;

	 
	address public addressSCEscrow;

	 
	address public addressSCComplianceService;
	ComplianceService public SCComplianceService;

	 

	 
	modifier notTimeLocked() {
		if (now < timelockEndTime && msg.sender != addressSCICO && msg.sender != addressSCEscrow) {
			error('notTimeLocked: Timelock still active. Function is yet unavailable.');
		} else {
			_;
		}
	}


	 
	 
	constructor(address _addressSCEscrow, address _addressSCComplianceService) public {
		name = "TheRentalsToken";
		symbol = "TRT";
		decimals = 18;  

		 
        _totalSupply = 1350000000 ether;  

		timelockEndTime = timestamp().add(45 days);  

		addressSCEscrow = _addressSCEscrow;
		addressSCComplianceService = _addressSCComplianceService;
		SCComplianceService = ComplianceService(addressSCComplianceService);

		 
		balances[_addressSCEscrow] = _totalSupply;
		emit Transfer(0x0, _addressSCEscrow, _totalSupply);

	}

     
    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	 
	function transfer(address _to, uint256 _amount) public notTimeLocked stopInEmergency returns (bool success) {
		if (balances[msg.sender] < _amount) {
			error('transfer: the amount to transfer is higher than your token balance');
			return false;
		}

		if(!SCComplianceService.validate(msg.sender, _to, _amount)) {
			error('transfer: not allowed by the compliance service');
			return false;
		}

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		emit Transfer(msg.sender, _to, _amount);  

		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _amount) public notTimeLocked stopInEmergency returns (bool success) {
		if (balances[_from] < _amount) {
			error('transferFrom: the amount to transfer is higher than the token balance of the source');
			return false;
		}
		if (allowed[_from][msg.sender] < _amount) {
			error('transferFrom: the amount to transfer is higher than the maximum token transfer allowed by the source');
			return false;
		}

		if(!SCComplianceService.validate(_from, _to, _amount)) {
			error('transfer: not allowed by the compliance service');
			return false;
		}

		balances[_from] = balances[_from].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
		emit Transfer(_from, _to, _amount);  

		return true;
	}

	 
	function approve(address _spender, uint256 _amount) public returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		emit Approval(msg.sender, _spender, _amount);  

		return true;
	}

	 
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	 
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	 
	function refundTokens(address _from, uint256 _amount) public notTimeLocked stopInEmergency returns (bool success) {
        if (tx.origin != _from) {
            error('refundTokens: tx.origin did not request the refund directly');
            return false;
        }

        if (addressSCICO != msg.sender) {
            error('refundTokens: caller is not the current ICO address');
            return false;
        }

        if (balances[_from] < _amount) {
            error('refundTokens: the amount to transfer is higher than your token balance');
            return false;
        }

        if(!SCComplianceService.validate(_from, addressSCICO, _amount)) {
			error('transfer: not allowed by the compliance service');
			return false;
		}

		balances[_from] = balances[_from].sub(_amount);
		balances[addressSCICO] = balances[addressSCICO].add(_amount);
		emit Transfer(_from, addressSCICO, _amount);  

		return true;
	}

	 
	function setMyICOContract(address _SCICO) public onlyOwner {
		addressSCICO = _SCICO;
	}

	function setComplianceService(address _addressSCComplianceService) public onlyOwner {
		addressSCComplianceService = _addressSCComplianceService;
		SCComplianceService = ComplianceService(addressSCComplianceService);
	}

	 
	function updateTimeLock(uint256 _timelockEndTime) onlyOwner public returns (bool) {
		timelockEndTime = _timelockEndTime;

		emit UpdateTimeLock(_timelockEndTime);  

		return true;
	}


	 

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _amount);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

	 
	event UpdateTimeLock(uint256 _timelockEndTime);
}