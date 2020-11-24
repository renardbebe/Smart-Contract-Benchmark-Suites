 

pragma solidity ^0.4.18;

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

contract TTTToken is ERC20, Ownable {
	using SafeMath for uint;

	string public constant name = "The Tip Token";
	string public constant symbol = "TTT";

	uint8 public decimals = 18;

	mapping(address=>uint256) balances;
	mapping(address=>mapping(address=>uint256)) allowed;

	 
	uint256 public totalSupply_;
	uint256 public presaleSupply;
	uint256 public crowdsaleSupply;
	uint256 public privatesaleSupply;
	uint256 public airdropSupply;
	uint256 public teamSupply;
	uint256 public ecoSupply;

	 
	uint256 public firstVestStartsAt;
	uint256 public secondVestStartsAt;
	uint256 public firstVestAmount;
	uint256 public secondVestAmount;
	uint256 public currentVestedAmount;

	uint256 public crowdsaleBurnAmount;

	 
	address public privatesaleAddress;
	address public presaleAddress;
	address public crowdsaleAddress;
	address public teamSupplyAddress;
	address public ecoSupplyAddress;
	address public crowdsaleAirdropAddress;
	address public crowdsaleBurnAddress;
	address public tokenSaleAddress;

	 
	bool public privatesaleFinalized;
	bool public presaleFinalized;
	bool public crowdsaleFinalized;

	event PrivatesaleFinalized(uint tokensRemaining);
	event PresaleFinalized(uint tokensRemaining);
	event CrowdsaleFinalized(uint tokensRemaining);
	event Burn(address indexed burner, uint256 value);
	event TokensaleAddressSet(address tSeller, address from);

	modifier onlyTokenSale() {
		require(msg.sender == tokenSaleAddress);
		_;
	}

	modifier canItoSend() {
		require(crowdsaleFinalized == true || (crowdsaleFinalized == false && msg.sender == ecoSupplyAddress));
		_;
	}

	function TTTToken() {
		 
		 
		 
		 
		 
		 
		totalSupply_ = 600000000 * 10**uint(decimals);
		privatesaleSupply = 90000000 * 10**uint(decimals);
		presaleSupply = 120000000 * 10**uint(decimals);
		crowdsaleSupply = 180000000 * 10**uint(decimals);
		ecoSupply = 90000000 * 10**uint(decimals);
		teamSupply = 120000000 * 10**uint(decimals);

		firstVestAmount = teamSupply.div(2);
		secondVestAmount = firstVestAmount;
		currentVestedAmount = 0;

		privatesaleAddress = 0xE67EE1935bf160B48BA331074bb743630ee8aAea;
		presaleAddress = 0x4A41D67748D16aEB12708E88270d342751223870;
		crowdsaleAddress = 0x2eDf855e5A90DF003a5c1039bEcf4a721C9c3f9b;
		teamSupplyAddress = 0xc4146EcE2645038fbccf79784a6DcbE3C6586c03;
		ecoSupplyAddress = 0xdBA99B92a18930dA39d1e4B52177f84a0C27C8eE;
		crowdsaleAirdropAddress = 0x6BCb947a8e8E895d1258C1b2fc84A5d22632E6Fa;
		crowdsaleBurnAddress = 0xDF1CAf03FA89AfccdAbDd55bAF5C9C4b9b1ceBaB;

		addToBalance(privatesaleAddress, privatesaleSupply);
		addToBalance(presaleAddress, presaleSupply);
		addToBalance(crowdsaleAddress, crowdsaleSupply);
		addToBalance(teamSupplyAddress, teamSupply);
		addToBalance(ecoSupplyAddress, ecoSupply);

		 
		firstVestStartsAt = 1543622400;
		 
		secondVestStartsAt = 1559347200;
	}

	 
	function transfer(address _to, uint256 _amount) public canItoSend returns (bool success) {
		require(balanceOf(msg.sender) >= _amount);
		addToBalance(_to, _amount);
		decrementBalance(msg.sender, _amount);
		Transfer(msg.sender, _to, _amount);
		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _amount) public canItoSend returns (bool success) {
		require(allowance(_from, msg.sender) >= _amount);
		decrementBalance(_from, _amount);
		addToBalance(_to, _amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
		Transfer(_from, _to, _amount);
		return true;
	}

	 
	function transferFromTokenSell(address _to, address _from, uint256 _amount) external onlyTokenSale returns (bool success) {
		require(_amount > 0);
		require(_to != 0x0);
		require(balanceOf(_from) >= _amount);
		decrementBalance(_from, _amount);
		addToBalance(_to, _amount);
		Transfer(_from, _to, _amount);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		require((_value == 0) || (allowance(msg.sender, _spender) == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	 
	function totalSupply() public view returns (uint256 totalSupply) {
		return totalSupply_;
	}

	 
	function setTokenSaleAddress(address _tokenSaleAddress) external onlyOwner {
		require(tokenSaleAddress == 0x0);
		tokenSaleAddress = _tokenSaleAddress;
		TokensaleAddressSet(tokenSaleAddress, msg.sender);
	}

	 
	function finalizePrivatesale() external onlyTokenSale returns (bool success) {
		require(privatesaleFinalized == false);
		uint256 amount = balanceOf(privatesaleAddress);
		if (amount != 0) {
			addToBalance(presaleAddress, amount);
			decrementBalance(privatesaleAddress, amount);
		}
		privatesaleFinalized = true;
		PrivatesaleFinalized(amount);
		return true;
	}

	 
	function finalizePresale() external onlyTokenSale returns (bool success) {
		require(presaleFinalized == false && privatesaleFinalized == true);
		uint256 amount = balanceOf(presaleAddress);
		if (amount != 0) {
			addToBalance(crowdsaleAddress, amount);
			decrementBalance(presaleAddress, amount);
		}
		presaleFinalized = true;
		PresaleFinalized(amount);
		return true;
	}

	 
	function finalizeCrowdsale(uint256 _burnAmount, uint256 _ecoAmount, uint256 _airdropAmount) external onlyTokenSale returns(bool success) {
		require(presaleFinalized == true && crowdsaleFinalized == false);
		uint256 amount = balanceOf(crowdsaleAddress);
		assert((_burnAmount.add(_ecoAmount).add(_airdropAmount)) == amount);
		if (amount > 0) {
			crowdsaleBurnAmount = _burnAmount;
			addToBalance(ecoSupplyAddress, _ecoAmount);
			addToBalance(crowdsaleBurnAddress, crowdsaleBurnAmount);
			addToBalance(crowdsaleAirdropAddress, _airdropAmount);
			decrementBalance(crowdsaleAddress, amount);
			assert(balanceOf(crowdsaleAddress) == 0);
		}
		crowdsaleFinalized = true;
		CrowdsaleFinalized(amount);
		return true;
	}

	 
	function burn(uint256 _value) public onlyOwner {
		require(_value <= balances[msg.sender]);
		require(crowdsaleFinalized == true);
		 
		 

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		Burn(burner, _value);
		Transfer(burner, address(0), _value);
	}

	 
	function transferFromVest(uint256 _amount) public onlyOwner {
		require(block.timestamp > firstVestStartsAt);
		require(crowdsaleFinalized == true);
		require(_amount > 0);
		if(block.timestamp > secondVestStartsAt) {
			 
			require(_amount <= teamSupply);
			require(_amount <= balanceOf(teamSupplyAddress));
		} else {
			 
			require(_amount <= (firstVestAmount - currentVestedAmount));
			require(_amount <= balanceOf(teamSupplyAddress));
		}
		currentVestedAmount = currentVestedAmount.add(_amount);
		addToBalance(msg.sender, _amount);
		decrementBalance(teamSupplyAddress, _amount);
		Transfer(teamSupplyAddress, msg.sender, _amount);
	}

	 
	function addToBalance(address _address, uint _amount) internal {
		balances[_address] = balances[_address].add(_amount);
	}

	 
	function decrementBalance(address _address, uint _amount) internal {
		balances[_address] = balances[_address].sub(_amount);
	}

}

contract TTTTokenSell is Whitelist, Pausable {
	using SafeMath for uint;

	uint public decimals = 18;

	 
	address public tokenAddress;
	address public wallet;
	 
	address public privatesaleAddress;
	address public presaleAddress;
	address public crowdsaleAddress;

	 
	uint256 public weiRaised;

	 
	uint256 public startsAt;
	uint256 public endsAt;

	 
	uint256 public ethMin;
	uint256 public ethMax;

	enum CurrentPhase { Privatesale, Presale, Crowdsale, None }

	CurrentPhase public currentPhase;
	uint public currentPhaseRate;
	address public currentPhaseAddress;

	TTTToken public token;

	event AmountRaised(address beneficiary, uint amountRaised);
	event TokenPurchased(address indexed purchaser, uint256 value, uint256 wieAmount);
	event TokenPhaseStarted(CurrentPhase phase, uint256 startsAt, uint256 endsAt);
	event TokenPhaseEnded(CurrentPhase phase);

	modifier tokenPhaseIsActive() {
		assert(now >= startsAt && now <= endsAt);
		_;
	}

	function TTTTokenSell() {
		wallet = 0xE6CB27F5fA75e0B75422c9B8A8da8697C9631cC6;

		privatesaleAddress = 0xE67EE1935bf160B48BA331074bb743630ee8aAea;
		presaleAddress = 0x4A41D67748D16aEB12708E88270d342751223870;
		crowdsaleAddress = 0x2eDf855e5A90DF003a5c1039bEcf4a721C9c3f9b;

		currentPhase = CurrentPhase.None;
		currentPhaseAddress = privatesaleAddress;
		startsAt = 0;
		endsAt = 0;
		ethMin = 0;
		ethMax = numToWei(1000, decimals);
	}

	function setTokenAddress(address _tokenAddress) external onlyOwner {
		require(tokenAddress == 0x0);
		tokenAddress = _tokenAddress;
		token = TTTToken(tokenAddress);
	}

	function startPhase(uint _phase, uint _currentPhaseRate, uint256 _startsAt, uint256 _endsAt) external onlyOwner {
		require(_phase >= 0 && _phase <= 2);
		require(_startsAt > endsAt && _endsAt > _startsAt);
		require(_currentPhaseRate > 0);
		currentPhase = CurrentPhase(_phase);
		currentPhaseAddress = getPhaseAddress();
		assert(currentPhaseAddress != 0x0);
		currentPhaseRate = _currentPhaseRate;
		if(currentPhase == CurrentPhase.Privatesale) ethMin = numToWei(10, decimals);
		else {
			ethMin = 0;
			ethMax = numToWei(15, decimals);
		}
		startsAt = _startsAt;
		endsAt = _endsAt;
		TokenPhaseStarted(currentPhase, startsAt, endsAt);
	}

	function buyTokens(address _to) tokenPhaseIsActive whenNotPaused payable {
		require(whitelist[_to]);
		require(msg.value >= ethMin && msg.value <= ethMax);
		require(_to != 0x0);
		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(currentPhaseRate);
		 
		if(currentPhase == CurrentPhase.Privatesale) tokens = tokens.add(tokens);
		weiRaised = weiRaised.add(weiAmount);
		wallet.transfer(weiAmount);
		if(!token.transferFromTokenSell(_to, currentPhaseAddress, tokens)) revert();
		TokenPurchased(_to, tokens, weiAmount);
	}

	 
	 
	function () payable {
		buyTokens(msg.sender);
	}

	function finalizePhase() external onlyOwner {
		if(currentPhase == CurrentPhase.Privatesale) token.finalizePrivatesale();
		else if(currentPhase == CurrentPhase.Presale) token.finalizePresale();
		endsAt = block.timestamp;
		currentPhase = CurrentPhase.None;
		TokenPhaseEnded(currentPhase);
	}

	function finalizeIto(uint256 _burnAmount, uint256 _ecoAmount, uint256 _airdropAmount) external onlyOwner {
		token.finalizeCrowdsale(numToWei(_burnAmount, decimals), numToWei(_ecoAmount, decimals), numToWei(_airdropAmount, decimals));
		endsAt = block.timestamp;
		currentPhase = CurrentPhase.None;
		TokenPhaseEnded(currentPhase);
	}

	function getPhaseAddress() internal view returns (address phase) {
		if(currentPhase == CurrentPhase.Privatesale) return privatesaleAddress;
		else if(currentPhase == CurrentPhase.Presale) return presaleAddress;
		else if(currentPhase == CurrentPhase.Crowdsale) return crowdsaleAddress;
		return 0x0;
	}

	function numToWei(uint256 _num, uint _decimals) internal pure returns (uint256 w) {
		return _num.mul(10**_decimals);
	}
}