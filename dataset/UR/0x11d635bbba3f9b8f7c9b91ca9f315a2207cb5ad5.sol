 

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


 
contract Ownable {
	address public owner;

	 
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	 
	function Ownable() public {
		owner = msg.sender;
	}


	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

 
contract Timestamped is Ownable {
	uint256 public ts = 0;
	uint256 public plus = 0;

	function getBlockTime() public view returns (uint256) {
		if(ts > 0) {
			return ts + plus;
		} else {
			return block.timestamp + plus; 
		}
	}
}

 
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
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

		bytes memory empty;
		Transfer(msg.sender, _to, _value, empty);
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

		bytes memory empty;
		Transfer(_from, _to, _value, empty);
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

	 
	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}

 
contract ERC223Receiver {
	 
	struct TKN {
		address sender;
		uint256 value;
		bytes data;
		bytes4 sig;
	}
	
	 
	function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
		TKN memory tkn;
		tkn.sender = _from;
		tkn.value = _value;
		tkn.data = _data;
		 
		 
	  
		 
	}
}

 
contract ERC223 {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function transfer(address to, uint256 value, bytes data) public returns (bool);
	function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

 

contract ERC223Token is ERC223, StandardToken {
	using SafeMath for uint256;

	 
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		 
		if(isContract(_to)) {
			 
			require(_to != address(0));
			require(_value <= balances[msg.sender]);

			 
			balances[msg.sender] = balances[msg.sender].sub(_value);
			balances[_to] = balances[_to].add(_value);
	
			 
			assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			Transfer(msg.sender, _to, _value, _data);
			return true;
		}
		else {
			 
			return transferToAddress(_to, _value, _data);
		}
	}
  

	 
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		 
		if(isContract(_to)) {
			 
			return transferToContract(_to, _value, _data);
		}
		else {
			 
			return transferToAddress(_to, _value, _data);
		}
	}
  
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		 
		 
		bytes memory empty;

		 
		if(isContract(_to)) {
			 
			return transferToContract(_to, _value, empty);
		}
		else {
			 
			return transferToAddress(_to, _value, empty);
		}
	}

	 
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return (length > 0);
	}

	 
	function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
		 
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
  
	 
	function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
		 
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		 
		ERC223Receiver receiver = ERC223Receiver(_to);
		receiver.tokenFallback(msg.sender, _value, _data);
		
		 
		Transfer(msg.sender, _to, _value, _data);
		return true;
	}
}

 
contract dHealthToken is ERC223Token, Ownable {

	string public constant name = "dHealth";
	string public constant symbol = "dHt";
	uint256 public constant decimals = 18;

	uint256 constant INITIAL_SUPPLY = 500000000 * 1E18;
	
	 
	function dHealthToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
	}

	 
	function() public payable {
		revert();
	}
}

 
contract dHealthTokenDistributor is Ownable, Timestamped {
	using SafeMath for uint256;

	 
	dHealthToken public token;

	 
	address public communityContract;
	address public foundersContract;
	address public technicalContract;
	address public managementContract;

	 
	uint256 public communityAmount;
	uint256 public foundersAmount;
	uint256 public technicalAmount;
	uint256 public managementAmount;

	 
	function dHealthTokenDistributor(address _token, address _communityContract, address _foundersContract, address _technicalContract, address _managementContract) public {
		 
		token = dHealthToken(_token);

		 
		communityContract = _communityContract;
		foundersContract = _foundersContract;
		technicalContract = _technicalContract;
		managementContract = _managementContract;

		 
		communityAmount = 10000000 * 1E18;
		foundersAmount = 15000000 * 1E18;
		technicalAmount = 55000000 * 1E18;
		managementAmount = 60000000 * 1E18;
	}

	 	
	function distribute() onlyOwner public payable {
		bytes memory empty;

		 
		token.transfer(communityContract, communityAmount, empty);

		 
		token.transfer(foundersContract, foundersAmount, empty);

		 
		token.transfer(technicalContract, technicalAmount, empty);

		 
		token.transfer(managementContract, managementAmount, empty);
	}
}

 
contract dHealthEtherDistributor is Ownable, Timestamped {
	using SafeMath for uint256;

	address public projectContract;	
	address public technologyContract;	
	address public founderContract;	

	uint256 public projectShare;
	uint256 public technologyShare;
	uint256 public founderShare;

	 
	function dHealthEtherDistributor(address _projectContract, address _technologyContract, address _founderContract) public {

		 
		projectContract = _projectContract;	
		technologyContract = _technologyContract;	
		founderContract = _founderContract;	

		 
		projectShare = 72;
		technologyShare = 18;
		founderShare = 10;
	}

	 	
	function distribute() onlyOwner public payable {
		uint256 balance = this.balance;
		
		 
		uint256 founderPart = balance.mul(founderShare).div(100);
		if(founderPart > 0) {
			founderContract.transfer(founderPart);
		}

		 
		uint256 technologyPart = balance.mul(technologyShare).div(100);
		if(technologyPart > 0) {
			technologyContract.transfer(technologyPart);
		}

		 
		uint256 projectPart = this.balance;
		if(projectPart > 0) {
			projectContract.transfer(projectPart);
		}
	}
}

 
contract dHealthTokenIncentive is dHealthTokenDistributor, ERC223Receiver {
	using SafeMath for uint256;

	 
	dHealthToken public token;

	 
	uint256 public maxTokenForHold = 140000000 * 1E18;

	 
	uint256 public contractTimeout = 1555286400;  

	 
	function dHealthTokenIncentive(address _token, address _communityContract, address _foundersContract, address _technicalContract, address _managementContract) 
		dHealthTokenDistributor(_token, _communityContract, _foundersContract, _technicalContract, _managementContract)
		public {
		 
		token = dHealthToken(_token);
	}

	 
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());
		
		 
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}
}

 
contract dHealthTokenGrowth is Ownable, ERC223Receiver, Timestamped {
	using SafeMath for uint256;

	 
	dHealthToken public token;

	 
	uint256 public maxTokenForHold = 180000000 * 1E18;

	 
	address public exchangesWallet;
	uint256 public exchangesTokens = 45000000 * 1E18;
	uint256 public exchangesLockEndingAt = 1523750400;  
	bool public exchangesStatus = false;

	 
	address public countriesWallet;
	uint256 public countriesTokens = 45000000 * 1E18;
	uint256 public countriesLockEndingAt = 1525132800;  
	bool public countriesStatus = false;

	 
	address public acquisitionsWallet;
	uint256 public acquisitionsTokens = 45000000 * 1E18;
	uint256 public acquisitionsLockEndingAt = 1526342400;  
	bool public acquisitionsStatus = false;

	 
	address public coindropsWallet;
	uint256 public coindropsTokens = 45000000 * 1E18;
	uint256 public coindropsLockEndingAt = 1527811200;  
	bool public coindropsStatus = false;

	 
	uint256 public contractTimeout = 1555286400;  

	 
	function dHealthTokenGrowth(address _token, address _exchangesWallet, address _countriesWallet, address _acquisitionsWallet, address _coindropsWallet) public {
		 
		token = dHealthToken(_token);

		 
		exchangesWallet = _exchangesWallet;
		countriesWallet = _countriesWallet;
		acquisitionsWallet = _acquisitionsWallet;
		coindropsWallet = _coindropsWallet;
	}

	 
	function withdrawExchangesToken() public {
		 
		require(exchangesLockEndingAt <= getBlockTime());
		 
		require(exchangesStatus == false);
		
		 
		bytes memory empty;
		token.transfer(exchangesWallet, exchangesTokens, empty);
		exchangesStatus = true;
	}

	 
	function withdrawCountriesToken() public {
		 
		require(countriesLockEndingAt <= getBlockTime());
		 
		require(countriesStatus == false);
		
		 
		bytes memory empty;
		token.transfer(countriesWallet, countriesTokens, empty);
		countriesStatus = true;
	}

	 
	function withdrawAcquisitionsToken() public {
		 
		require(acquisitionsLockEndingAt <= getBlockTime());
		 
		require(acquisitionsStatus == false);
		
		 
		bytes memory empty;
		token.transfer(acquisitionsWallet, acquisitionsTokens, empty);
		acquisitionsStatus = true;
	}

	 
	function withdrawCoindropsToken() public {
		 
		require(coindropsLockEndingAt <= getBlockTime());
		 
		require(coindropsStatus == false);
		
		 
		bytes memory empty;
		token.transfer(coindropsWallet, coindropsTokens, empty);
		coindropsStatus = true;
	}

	 
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());
		
		 
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}
}


 
contract dHealthTokenSale is dHealthEtherDistributor, ERC223Receiver {
	using SafeMath for uint256;

	 
	dHealthToken public token;

	 
	uint256 public maxTokenForSale = 180000000 * 1E18;

	 
	uint256 public phase1StartingAt = 1516924800;  
	uint256 public phase1EndingAt = 1518134399;  
	uint256 public phase1MaxTokenForSale = maxTokenForSale * 1 / 3;
	uint256 public phase1TokenPriceInEth = 0.0005 ether;
	uint256 public phase1TokenSold = 0;

	 
	uint256 public phase2StartingAt = 1518134400;  
	uint256 public phase2EndingAt = 1519343999;  
	uint256 public phase2MaxTokenForSale = maxTokenForSale * 2 / 3;
	uint256 public phase2TokenPriceInEth = 0.000606060606 ether;
	uint256 public phase2TokenSold = 0;

	 
	uint256 public phase3StartingAt = 1519344000;  
	uint256 public phase3EndingAt = 1520553599;  
	uint256 public phase3MaxTokenForSale = maxTokenForSale;
	uint256 public phase3TokenPriceInEth = 0.000769230769 ether;
	uint256 public phase3TokenSold = 0;

	 
	uint256 public contractTimeout = 1520553600;  

	 
	address public growthContract;

	 
	uint256 public maxEthPerTransaction = 1000 ether;

	 
	uint256 public minEthPerTransaction = 0.01 ether;

	 
	uint256 public totalTokenSold;

	 
	uint256 public totalEtherRaised;

	 
	mapping(address => uint256) public etherRaisedPerWallet;

	 
	bool public isClose = false;

	 
	bool public isPaused = false;

	 
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	 
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	 
	function dHealthTokenSale(address _token, address _projectContract, address _technologyContract, address _founderContract, address _growthContract)
		dHealthEtherDistributor(_projectContract, _technologyContract, _founderContract)
		public {
		 
		token = dHealthToken(_token);

		 
		growthContract = _growthContract;
	}

	 
	function validate(uint256 value, uint256 amount) internal constant returns (bool) {
		 
		bool validTimestamp = false;
		bool validAmount = false;

		 
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			 
			validTimestamp = true;

			 
			validAmount = phase1MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		 
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			 
			validTimestamp = true;

			 
			validAmount = phase2MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		 
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			 
			validTimestamp = true;

			 
			validAmount = phase3MaxTokenForSale.sub(totalTokenSold) >= amount;
		}

		 
		bool validValue = value != 0;

		 
		bool validToken = amount != 0;

		 
		return validTimestamp && validAmount && validValue && validToken && !isClose && !isPaused;
	}

	function calculate(uint256 value) internal constant returns (uint256) {
		uint256 amount = 0;
			
		 
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			 
			amount = value.mul(1E18).div(phase1TokenPriceInEth);
		}

		 
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			 
			amount = value.mul(1E18).div(phase2TokenPriceInEth);
		}

		 
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			 
			amount = value.mul(1E18).div(phase3TokenPriceInEth);
		}

		return amount;
	}

	function update(uint256 value, uint256 amount) internal returns (bool) {

		 
		totalTokenSold = totalTokenSold.add(amount);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		 
		if(phase1StartingAt <= getBlockTime() && getBlockTime() <= phase1EndingAt) {
			 
			phase1TokenSold = phase1TokenSold.add(amount);
		}

		 
		if(phase2StartingAt <= getBlockTime() && getBlockTime() <= phase2EndingAt) {
			 
			phase2TokenSold = phase2TokenSold.add(amount);
		}

		 
		if(phase3StartingAt <= getBlockTime() && getBlockTime() <= phase3EndingAt) {
			 
			phase3TokenSold = phase3TokenSold.add(amount);
		}
	}

	 
	function() public payable {
		buy(msg.sender);
	}

	 
	function buy(address beneficiary) public payable {
		require(beneficiary != address(0));

		 
		uint256 value = msg.value;

		 
		require(value >= minEthPerTransaction);

		 
		if(value > maxEthPerTransaction) {
			 
			msg.sender.transfer(value.sub(maxEthPerTransaction));
			value = maxEthPerTransaction;
		}
		
		 
		uint256 tokens = calculate(value);

		 
		require(validate(value , tokens));

		 
		update(value , tokens);
		
		 
		bytes memory empty;
		token.transfer(beneficiary, tokens, empty);
		
		 
		TokenPurchase(msg.sender, beneficiary, value, tokens, now);
	}

	 
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		 
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	 	
	function sendToGrowthContract() onlyOwner public {
		require(contractTimeout <= getBlockTime());

		 
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(growthContract, tokens, empty);
	}

	 	
	function sendToVestingContract() onlyOwner public {
		 
		distribute();
	}

	 	
	function withdraw() onlyOwner public {
		require(contractTimeout <= getBlockTime());

		 
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(growthContract, tokens, empty);

		 
		distribute();
	}

	 	
	function close() onlyOwner public {
		 
		isClose = true;
	}

	 	
	function pause() onlyOwner public {
		 
		isPaused = true;
	}

	 	
	function resume() onlyOwner public {
		 
		isPaused = false;
	}
}

 
contract dHealthEtherVesting is Ownable, Timestamped {
	using SafeMath for uint256;

	 
	address public wallet;

	 
	uint256 public startingAt = 1516924800;  

	 
	uint256 public endingAt = startingAt + 540 days;

	 
	uint256 public vestingAmount = 20;

	 
	uint256 public vestingPeriodLength = 30 days;

	 
	uint256 public contractTimeout = startingAt + 2 years;

	 
	struct VestingStruct {
		uint256 period; 
		bool status;
		address wallet;
		uint256 amount;
		uint256 timestamp;
	}

	 
	mapping (uint256 => VestingStruct) public vestings;

	 
	event Payouts(uint256 indexed period, bool status, address wallet, uint256 amount, uint256 timestamp);

	 
	function dHealthEtherVesting(address _wallet) public {
		wallet = _wallet;
	}

	 
	function() public payable {
		
	}

	 
	function pay(uint256 percentage) public payable {
		 
		percentage = percentage <= vestingAmount ? percentage : vestingAmount;

		 
		var (period, amount) = calculate(getBlockTime() , this.balance , percentage);

		 
		require(period > 0);
		 
		require(vestings[period].status == false);
		 
		require(vestings[period].wallet == address(0));
		 
		require(amount > 0);

		 
		vestings[period].period = period;
		 
		vestings[period].status = true;
		 
		vestings[period].wallet = wallet;
		 
		vestings[period].amount = amount;
		 
		vestings[period].timestamp = getBlockTime();

		 
		wallet.transfer(amount);

		 
		Payouts(period, vestings[period].status, vestings[period].wallet, vestings[period].amount, vestings[period].timestamp);
	}

	 
	function getPeriod(uint256 timestamp) public view returns (uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			 
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return i;
			}
		}

		 
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return 18;
		}

		return 0;
	}

	 
	function getPeriodRange(uint256 timestamp) public view returns (uint256 , uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			 
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return (startTime , endTime);
			}
		}

		 
		uint256 lastStartTime = startingAt + (vestingPeriodLength * (17));
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return (lastStartTime , lastEndTime);
		}

		return (0 , 0);
	}

	 
	function calculate(uint256 timestamp, uint256 balance , uint256 percentage) public view returns (uint256 , uint256) {
		 
		uint256 period = getPeriod(timestamp);
		if(period == 0) {
			 
			return (0 , 0);
		}

		 
		VestingStruct memory vesting = vestings[period];	
		
		 
		if(vesting.status == false) {
			 
			uint256 amount;

			 
			if(period == 18) {
				 
				amount = balance;
			} else {
				 
				amount = balance.mul(percentage).div(100);
			}
			
			return (period, amount);
		} else {
			 
			return (period, 0);
		}		
	}

	 
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
	}

	 
	function withdraw() onlyOwner public payable {
		require(contractTimeout <= getBlockTime());
		owner.transfer(this.balance);
	}	
}


 
contract dHealthTokenVesting is Ownable, Timestamped {
	using SafeMath for uint256;

	 
	dHealthToken public token;

	 
	address public wallet;

	 
	uint256 public maxTokenForHold;

	 
	uint256 public startingAt = 1522281600;  

	 
	uint256 public endingAt = startingAt + 540 days;

	 
	uint256 public vestingAmount = 20;

	 
	uint256 public vestingPeriodLength = 30 days;

	 
	uint256 public contractTimeout = startingAt + 2 years;

	 
	struct VestingStruct {
		uint256 period; 
		bool status;
		address wallet;
		uint256 amount;
		uint256 timestamp;
	}

	 
	mapping (uint256 => VestingStruct) public vestings;

	 
	event Payouts(uint256 indexed period, bool status, address wallet, uint256 amount, uint256 timestamp);

	 
	function dHealthTokenVesting(address _token, address _wallet, uint256 _maxTokenForHold, uint256 _startingAt) public {
		 
		token = dHealthToken(_token);

		 
		wallet = _wallet;

		 
		maxTokenForHold = _maxTokenForHold;	
		
		 
		startingAt = _startingAt;
		endingAt = startingAt + 540 days;
	}

	 
	function() public payable {
		
	}

	 
	function pay(uint256 percentage) public {
		 
		percentage = percentage <= vestingAmount ? percentage : vestingAmount;

		 
		uint256 balance = token.balanceOf(this); 
		
		 
		var (period, amount) = calculate(getBlockTime() , balance , percentage);

		 
		require(period > 0);
		 
		require(vestings[period].status == false);
		 
		require(vestings[period].wallet == address(0));
		 
		require(amount > 0);

		 
		vestings[period].period = period;
		 
		vestings[period].status = true;
		 
		vestings[period].wallet = wallet;
		 
		vestings[period].amount = amount;
		 
		vestings[period].timestamp = getBlockTime();

		 
		bytes memory empty;
		token.transfer(wallet, amount, empty);

		 
		Payouts(period, vestings[period].status, vestings[period].wallet, vestings[period].amount, vestings[period].timestamp);
	}

	 
	function getPeriod(uint256 timestamp) public view returns (uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			 
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return i;
			}
		}

		 
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return 18;
		}

		return 0;
	}

	 
	function getPeriodRange(uint256 timestamp) public view returns (uint256 , uint256) {
		for(uint256 i = 1 ; i <= 18 ; i ++) {
			 
			uint256 startTime = startingAt + (vestingPeriodLength * (i - 1));
			uint256 endTime = startingAt + (vestingPeriodLength * (i));

			if(startTime <= timestamp && timestamp < endTime) {
				return (startTime , endTime);
			}
		}

		 
		uint256 lastStartTime = startingAt + (vestingPeriodLength * (17));
		uint256 lastEndTime = startingAt + (vestingPeriodLength * (18));
		if(lastEndTime <= timestamp) {
			return (lastStartTime , lastEndTime);
		}

		return (0 , 0);
	}

	 
	function calculate(uint256 timestamp, uint256 balance , uint256 percentage) public view returns (uint256 , uint256) {
		 
		uint256 period = getPeriod(timestamp);
		if(period == 0) {
			 
			return (0 , 0);
		}

		 
		VestingStruct memory vesting = vestings[period];	
		
		 
		if(vesting.status == false) {
			 
			uint256 amount;

			 
			if(period == 18) {
				 
				amount = balance;
			} else {
				 
				amount = balance.mul(percentage).div(100);
			}
			
			return (period, amount);
		} else {
			 
			return (period, 0);
		}		
	}

	 
	function setWallet(address _wallet) onlyOwner public {
		wallet = _wallet;
	}

	 
	function withdraw() onlyOwner public payable {
		require(contractTimeout <= getBlockTime());
		
		 
		uint256 tokens = token.balanceOf(this); 
		bytes memory empty;
		token.transfer(owner, tokens, empty);
	}	
}