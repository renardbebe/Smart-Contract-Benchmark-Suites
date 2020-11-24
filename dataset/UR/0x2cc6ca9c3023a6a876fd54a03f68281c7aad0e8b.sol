 

pragma solidity ^0.4.13;

contract ComplianceService {
	function validate(address _from, address _to, uint256 _amount) public returns (bool allowed) {
		return true;
	}
}

contract ERC20 {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _amount) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
	function totalSupply() public constant returns (uint);
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

contract RefundVault is HardcodedWallets, System {
	using SafeMath for uint256;

	enum State { Active, Refunding, Closed }


	 

	mapping (address => uint256) public deposited;
	mapping (address => uint256) public tokensAcquired;
	State public state;

	 
	address public addressSCICO;
	
	

	 

	 
	modifier onlyICOContract() {
		if (msg.sender != addressSCICO) {
			error('RefundVault: onlyICOContract function called by user that is not ICOContract');
		} else {
			_;
		}
	}


	 

	 
	constructor() public {
		state = State.Active;
	}

	function weisDeposited(address _investor) public constant returns (uint256) {
		return deposited[_investor];
	}

	function getTokensAcquired(address _investor) public constant returns (uint256) {
		return tokensAcquired[_investor];
	}

	 
	function deposit(address _investor, uint256 _tokenAmount) onlyICOContract public payable returns (bool) {
		if (state != State.Active) {
			error('deposit: state != State.Active');
			return false;
		}
		deposited[_investor] = deposited[_investor].add(msg.value);
		tokensAcquired[_investor] = tokensAcquired[_investor].add(_tokenAmount);

		return true;
	}

	 
	function close() onlyICOContract public returns (bool) {
		if (state != State.Active) {
			error('close: state != State.Active');
			return false;
		}
		state = State.Closed;

		walletFounder1.transfer(address(this).balance.mul(33).div(100));  
		walletFounder2.transfer(address(this).balance.mul(50).div(100));  
		walletFounder3.transfer(address(this).balance);                   

		emit Closed();  

		return true;
	}

	 
	function enableRefunds() onlyICOContract public returns (bool) {
		if (state != State.Active) {
			error('enableRefunds: state != State.Active');
			return false;
		}
		state = State.Refunding;

		emit RefundsEnabled();  

		return true;
	}

	 
	function refund(address _investor) onlyICOContract public returns (bool) {
		if (state != State.Refunding) {
			error('refund: state != State.Refunding');
			return false;
		}
		if (deposited[_investor] == 0) {
			error('refund: no deposit to refund');
			return false;
		}
		uint256 depositedValue = deposited[_investor];
		deposited[_investor] = 0;
		tokensAcquired[_investor] = 0;  
		_investor.transfer(depositedValue);

		emit Refunded(_investor, depositedValue);  

		return true;
	}

	 
	function isRefunding() public constant returns (bool) {
		return (state == State.Refunding);
	}

	 
	function setMyICOContract(address _SCICO) public onlyOwner {
		require(address(this).balance == 0);
		addressSCICO = _SCICO;
	}



	 

	 
	event Closed();

	 
	event RefundsEnabled();

	 
	event Refunded(address indexed beneficiary, uint256 weiAmount);
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

contract ICO is HardcodedWallets, Haltable {
	 

	 
	Tokens public SCTokens;	 
	RefundVault public SCRefundVault;	 
	Whitelist public SCWhitelist;	 
	Escrow public SCEscrow;  

	 
	uint256 public startTime;
	uint256 public endTime;
	bool public isFinalized = false;

	uint256 public weisPerBigToken;  
	uint256 public weisPerEther;
	uint256 public tokensPerEther;  
	uint256 public bigTokensPerEther;  

	uint256 public weisRaised;  
	uint256 public etherHardCap;  
	uint256 public tokensHardCap;  
	uint256 public weisHardCap;  
	uint256 public weisMinInvestment;  
	uint256 public etherSoftCap;  
	uint256 public tokensSoftCap;  
	uint256 public weisSoftCap;  

	uint256 public discount;  
	uint256 discountedPricePercentage;
	uint8 ICOStage;



	 

	
	 

	 
	function () payable public {
		buyTokens();
	}
	

	 
	function buyTokens() public stopInEmergency payable returns (bool) {
		if (msg.value == 0) {
			error('buyTokens: ZeroPurchase');
			return false;
		}

		uint256 tokenAmount = buyTokensLowLevel(msg.sender, msg.value);

		 
		if (!SCRefundVault.deposit.value(msg.value)(msg.sender, tokenAmount)) {
			revert('buyTokens: unable to transfer collected funds from ICO contract to Refund Vault');  
			 
			 
		}

		emit BuyTokens(msg.sender, msg.value, tokenAmount);  

		return true;
	}

	 
	 

	 
	function buyTokensLowLevel(address _beneficiary, uint256 _weisAmount) private stopInEmergency returns (uint256 tokenAmount) {
		if (_beneficiary == 0x0) {
			revert('buyTokensLowLevel: _beneficiary == 0x0');  
			 
			 
		}
		if (timestamp() < startTime || timestamp() > endTime) {
			revert('buyTokensLowLevel: Not withinPeriod');  
			 
			 
		}
		if (!SCWhitelist.isInvestor(_beneficiary)) {
			revert('buyTokensLowLevel: Investor is not registered on the whitelist');  
			 
			 
		}
		if (isFinalized) {
			revert('buyTokensLowLevel: ICO is already finalized');  
			 
			 
		}

		 
		if (_weisAmount < weisMinInvestment) {
			revert('buyTokensLowLevel: Minimal investment not reached. Not enough ethers to perform the minimal purchase');  
			 
			 
		}

		 
		if (weisRaised.add(_weisAmount) > weisHardCap) {
			revert('buyTokensLowLevel: HardCap reached. Not enough tokens on ICO contract to perform this purchase');  
			 
			 
		}

		 
		tokenAmount = _weisAmount.mul(weisPerEther).div(weisPerBigToken);

		 
		tokenAmount = tokenAmount.mul(100).div(discountedPricePercentage);

		 
		weisRaised = weisRaised.add(_weisAmount);

		 
		if (!SCTokens.transfer(_beneficiary, tokenAmount)) {
			revert('buyTokensLowLevel: unable to transfer tokens from ICO contract to beneficiary');  
			 
			 
		}
		emit BuyTokensLowLevel(msg.sender, _beneficiary, _weisAmount, tokenAmount);  

		return tokenAmount;
	}

	 
	 

	 
	function updateEndTime(uint256 _endTime) onlyOwner public returns (bool) {
		endTime = _endTime;

		emit UpdateEndTime(_endTime);  
	}


	 
	function finalize(bool _forceRefund) onlyOwner public returns (bool) {
		if (isFinalized) {
			error('finalize: ICO is already finalized.');
			return false;
		}

		if (weisRaised >= weisSoftCap && !_forceRefund) {
			if (!SCRefundVault.close()) {
				error('finalize: SCRefundVault.close() failed');
				return false;
			}
		} else {
			if (!SCRefundVault.enableRefunds()) {
				error('finalize: SCRefundVault.enableRefunds() failed');
				return false;
			}
			if(_forceRefund) {
				emit ForceRefund();  
			}
		}

		 
		uint256 balanceAmount = SCTokens.balanceOf(this);
		if (!SCTokens.transfer(address(SCEscrow), balanceAmount)) {
			error('finalize: unable to return remaining ICO tokens');
			return false;
		}
		 
		if(!SCEscrow.deposit(balanceAmount)) {
			error('finalize: unable to return remaining ICO tokens');
			return false;
		}

		isFinalized = true;

		emit Finalized();  

		return true;
	}

	 
	function claimRefund() public stopInEmergency returns (bool) {
		if (!isFinalized) {
			error('claimRefund: ICO is not yet finalized.');
			return false;
		}

		if (!SCRefundVault.isRefunding()) {
			error('claimRefund: RefundVault state != State.Refunding');
			return false;
		}

		 
		uint256 tokenAmount = SCRefundVault.getTokensAcquired(msg.sender);
		emit GetBackTokensOnRefund(msg.sender, this, tokenAmount);  
		if (!SCTokens.refundTokens(msg.sender, tokenAmount)) {
			error('claimRefund: unable to transfer investor tokens to ICO contract before refunding');
			return false;
		}

		if (!SCRefundVault.refund(msg.sender)) {
			error('claimRefund: SCRefundVault.refund() failed');
			return false;
		}

		return true;
	}

	function fundICO() public onlyOwner {
		if (!SCEscrow.fundICO(tokensHardCap, ICOStage)) {
			revert('ICO funding failed');
		}
	}




 

	 
	event BuyTokens(address indexed _purchaser, uint256 _value, uint256 _amount);

	 
	event BuyTokensOraclePayIn(address indexed _purchaser, address indexed _beneficiary, uint256 _weisAmount, uint256 _tokenAmount);

	 
	event BuyTokensLowLevel(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);

	 
	event Finalized();

	 
	event ForceRefund();

	 
	 

	 
	event GetBackTokensOnRefund(address _from, address _to, uint256 _amount);

	 
	event UpdateEndTime(uint256 _endTime);
}

contract ICOPreSale is ICO {
	 
	constructor(address _SCEscrow, address _SCTokens, address _SCWhitelist, address _SCRefundVault) public {
		if (_SCTokens == 0x0) {
			revert('Tokens Constructor: _SCTokens == 0x0');
		}
		if (_SCWhitelist == 0x0) {
			revert('Tokens Constructor: _SCWhitelist == 0x0');
		}
		if (_SCRefundVault == 0x0) {
			revert('Tokens Constructor: _SCRefundVault == 0x0');
		}
		
		SCTokens = Tokens(_SCTokens);
		SCWhitelist = Whitelist(_SCWhitelist);
		SCRefundVault = RefundVault(_SCRefundVault);
		
		weisPerEther = 1 ether;  

		 
		startTime = timestamp();
		endTime = timestamp().add(24 days);  

		 
		bigTokensPerEther = 7500;  
		tokensPerEther = bigTokensPerEther.mul(weisPerEther);  

		discount = 45;  
		discountedPricePercentage = 100;
		discountedPricePercentage = discountedPricePercentage.sub(discount);

		weisMinInvestment = weisPerEther.mul(1);

		 
		 
		 
		 

		 
		 
		  
		etherHardCap = 8067;  
		tokensHardCap = tokensPerEther.mul(etherHardCap).mul(100).div(discountedPricePercentage);

		weisPerBigToken = weisPerEther.div(bigTokensPerEther);
		 
		weisHardCap = weisPerEther.mul(etherHardCap);

		 
		etherSoftCap = 750;  
		weisSoftCap = weisPerEther.mul(etherSoftCap);

		SCEscrow = Escrow(_SCEscrow);

		ICOStage = 0;
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

contract Whitelist is HardcodedWallets, System {
	 

	mapping (address => bool) public walletsICO;
	mapping (address => bool) public managers;

	 
	function isInvestor(address _wallet) public constant returns (bool) {
		return (walletsICO[_wallet]);
	}

	 
	function addInvestor(address _wallet) external isManager returns (bool) {
		 
		if (walletsICO[_wallet]) {
			error('addInvestor: this wallet has been previously granted as ICO investor');
			return false;
		}

		walletsICO[_wallet] = true;

		emit AddInvestor(_wallet, timestamp());  
		return true;
	}

	modifier isManager(){
		if (managers[msg.sender] || msg.sender == owner) {
			_;
		} else {
			error("isManager: called by user that is not owner or manager");
		}
	}

	 
	function addManager(address _managerAddr) external onlyOwner returns (bool) {
		if(managers[_managerAddr]){
			error("addManager: manager account already exists.");
			return false;
		}

		managers[_managerAddr] = true;

		emit AddManager(_managerAddr, timestamp());
	}

	 
	function delManager(address _managerAddr) external onlyOwner returns (bool) {
		if(!managers[_managerAddr]){
			error("delManager: manager account not found.");
			return false;
		}

		delete managers[_managerAddr];

		emit DelManager(_managerAddr, timestamp());
	}

	 

	 
	event AddInvestor(address indexed _wallet, uint256 _timestamp);
	 
	event AddManager(address indexed _managerAddr, uint256 _timestamp);
	 
	event DelManager(address indexed _managerAddr, uint256 _timestamp);
}