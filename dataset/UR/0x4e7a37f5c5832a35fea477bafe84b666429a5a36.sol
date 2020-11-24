 

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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
 
contract ERC20BasicToken is Pausable{
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
    }

     
    function _transfer(address _from, address _to, uint _value) whenNotPaused internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }


     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused onlyPayloadSize(2 * 32) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

     
  	function balanceOf(address _owner) public constant returns (uint balance) {
  		return balances[_owner];
  	}

     
  	function allowance(address _owner, address _spender) public constant returns (uint remaining) {
  		return allowance[_owner][_spender];
  	}
}

contract JWCToken is ERC20BasicToken {
	using SafeMath for uint256;

	string public constant name      = "JWC Blockchain Ventures";    
	string public constant symbol    = "JWC";                        
	uint256 public constant decimals = 18;                           
	string public constant version   = "1.0";                        

	uint256 public constant tokenPreSale         = 100000000 * 10**decimals; 
	uint256 public constant tokenPublicSale      = 400000000 * 10**decimals; 
	uint256 public constant tokenReserve         = 300000000 * 10**decimals; 
	uint256 public constant tokenTeamSupporter   = 120000000 * 10**decimals; 
	uint256 public constant tokenAdvisorPartners = 80000000  * 10**decimals; 

	address public icoContract;

	 
	function JWCToken() public {
		totalSupply = tokenPreSale + tokenPublicSale + tokenReserve + tokenTeamSupporter + tokenAdvisorPartners;
	}

	 
	function setIcoContract(address _icoContract) public onlyOwner {
		if (_icoContract != address(0)) {
			icoContract = _icoContract;
		}
	}

	 
	function sell(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);

		Transfer(0x0, _recipient, _value);
		return true;
	}

	 
	function payBonusAffiliate(address _recipient, uint256 _value) public returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);
		totalSupply = totalSupply.add(_value);

		Transfer(0x0, _recipient, _value);
		return true;
	}
}

 
contract IcoPhase {
  uint256 public constant phasePresale_From = 1516456800; 
  uint256 public constant phasePresale_To = 1517839200; 

  uint256 public constant phasePublicSale1_From = 1519912800; 
  uint256 public constant phasePublicSale1_To = 1520344800; 

  uint256 public constant phasePublicSale2_From = 1520344800; 
  uint256 public constant phasePublicSale2_To = 1520776800; 

  uint256 public constant phasePublicSale3_From = 1520776800; 
  uint256 public constant phasePublicSale3_To = 1521208800; 
}

 
contract Bonus is IcoPhase, Ownable {
	using SafeMath for uint256;

	 
	uint256 constant decimals = 18;

	 
	bool public isBonus;

	 
	uint256 public maxTimeBonus = 225000000*10**decimals;

	 
	uint256 public maxAmountBonus = 125000000*10**decimals;

	 
	mapping(address => uint256) public bonusAccountBalances;
	mapping(uint256 => address) public bonusAccountIndex;
	uint256 public bonusAccountCount;

	uint256 public indexPaidBonus; 

	function Bonus() public {
		isBonus = true;
	}

	 
	function enableBonus() public onlyOwner returns (bool)
	{
		require(!isBonus);
		isBonus=true;
		return true;
	}

	 
	function disableBonus() public onlyOwner returns (bool)
	{
		require(isBonus);
		isBonus=false;
		return true;
	}

	 
	function getTimeBonus() public constant returns(uint256) {
		uint256 bonus = 0;

		if(now>=phasePresale_From && now<phasePresale_To){
			bonus = 40;
		} else if (now>=phasePublicSale1_From && now<phasePublicSale1_To) {
			bonus = 20;
		} else if (now>=phasePublicSale2_From && now<phasePublicSale2_To) {
			bonus = 10;
		} else if (now>=phasePublicSale3_From && now<phasePublicSale3_To) {
			bonus = 5;
		}

		return bonus;
	}

	 
	function getBonusByETH(uint256 _value) public pure returns(uint256) {
		uint256 bonus = 0;

		if(_value>=1500*10**decimals){
			bonus=_value.mul(25)/100;
		} else if(_value>=300*10**decimals){
			bonus=_value.mul(20)/100;
		} else if(_value>=150*10**decimals){
			bonus=_value.mul(15)/100;
		} else if(_value>=30*10**decimals){
			bonus=_value.mul(10)/100;
		} else if(_value>=15*10**decimals){
			bonus=_value.mul(5)/100;
		}

		return bonus;
	}

	 
	function balanceBonusOf(address _owner) public constant returns (uint256 balance)
	{
		return bonusAccountBalances[_owner];
	}

	 
	function payBonus() public onlyOwner returns (bool success);
}


 
contract Affiliate is Ownable {

	 
	bool public isAffiliate;

	 
	uint256 public affiliateLevel = 1;

	 
	mapping(uint256 => uint256) public affiliateRate;

	 
	mapping(address => uint256) public referralBalance; 

	mapping(address => address) public referral; 
	mapping(uint256 => address) public referralIndex; 

	uint256 public referralCount;

	 
	uint256 public indexPaidAffiliate;

	 
	uint256 public maxAffiliate = 100000000*(10**18);

	 
	modifier whenAffiliate() {
		require (isAffiliate);
		_;
	}

	 
	function Affiliate() public {
		isAffiliate=true;
		affiliateLevel=1;
		affiliateRate[0]=10;
	}

	 
	function enableAffiliate() public onlyOwner returns (bool) {
		require (!isAffiliate);
		isAffiliate=true;
		return true;
	}

	 
	function disableAffiliate() public onlyOwner returns (bool) {
		require (isAffiliate);
		isAffiliate=false;
		return true;
	}

	 
	function getAffiliateLevel() public constant returns(uint256)
	{
		return affiliateLevel;
	}

	 
	function setAffiliateLevel(uint256 _level) public onlyOwner whenAffiliate returns(bool)
	{
		affiliateLevel=_level;
		return true;
	}

	 
	function getReferrerAddress(address _referee) public constant returns (address)
	{
		return referral[_referee];
	}

	 
	function getRefereeAddress(address _referrer) public constant returns (address[] _referee)
	{
		address[] memory refereeTemp = new address[](referralCount);
		uint count = 0;
		uint i;
		for (i=0; i<referralCount; i++){
			if(referral[referralIndex[i]] == _referrer){
				refereeTemp[count] = referralIndex[i];

				count += 1;
			}
		}

		_referee = new address[](count);
		for (i=0; i<count; i++)
			_referee[i] = refereeTemp[i];
	}

	 
	function setReferralAddress(address _parent, address _child) public onlyOwner whenAffiliate returns (bool)
	{
		require(_parent != address(0x00));
		require(_child != address(0x00));

		referralIndex[referralCount]=_child;
		referral[_child]=_parent;
		referralCount++;

		referralBalance[_child]=0;

		return true;
	}

	 
	function getAffiliateRate(uint256 _level) public constant returns (uint256 rate)
	{
		return affiliateRate[_level];
	}

	 
	function setAffiliateRate(uint256 _level, uint256 _rate) public onlyOwner whenAffiliate returns (bool)
	{
		affiliateRate[_level]=_rate;
		return true;
	}

	 
	function balanceAffiliateOf(address _referee) public constant returns (uint256)
	{
		return referralBalance[_referee];
	}

	 
	function payAffiliate() public onlyOwner returns (bool success);
}


 
contract IcoContract is IcoPhase, Ownable, Pausable, Affiliate, Bonus {
	using SafeMath for uint256;

	JWCToken ccc;

	uint256 public totalTokenSale;
	uint256 public minContribution = 0.1 ether; 
	uint256 public tokenExchangeRate = 7000; 
	uint256 public constant decimals = 18;

	uint256 public tokenRemainPreSale; 
	uint256 public tokenRemainPublicSale; 

	address public ethFundDeposit = 0x133f29F316Aac08ABC0b39b5CdbD0E7f134671dB; 
	address public tokenAddress;

	bool public isFinalized;

	uint256 public maxGasRefund = 0.0046 ether; 

	 
	function IcoContract(address _tokenAddress) public {
		tokenAddress = _tokenAddress;

		ccc = JWCToken(tokenAddress);
		totalTokenSale = ccc.tokenPreSale() + ccc.tokenPublicSale();

		tokenRemainPreSale = ccc.tokenPreSale(); 
		tokenRemainPublicSale = ccc.tokenPublicSale(); 

		isFinalized=false;
	}

	 
	function changeETH2Token(uint256 _value) public constant returns(uint256) {
		uint256 etherRecev = _value + maxGasRefund;
		require (etherRecev >= minContribution);

		uint256 rate = getTokenExchangeRate();

		uint256 tokens = etherRecev.mul(rate);

		 
		uint256 phaseICO = getCurrentICOPhase();
		uint256 tokenRemain = 0;
		if(phaseICO == 1){ 
			tokenRemain = tokenRemainPreSale;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemain = tokenRemainPublicSale;
		}

		if (tokenRemain < tokens) {
			tokens=tokenRemain;
		}

		return tokens;
	}

	function () public payable whenNotPaused {
		require (!isFinalized);
		require (msg.sender != address(0));

		uint256 etherRecev = msg.value + maxGasRefund;
		require (etherRecev >= minContribution);

		 
		tokenExchangeRate = getTokenExchangeRate();

		uint256 tokens = etherRecev.mul(tokenExchangeRate);

		 
		uint256 phaseICO = getCurrentICOPhase();

		require(phaseICO!=0);

		uint256 tokenRemain = 0;
		if(phaseICO == 1){ 
			tokenRemain = tokenRemainPreSale;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemain = tokenRemainPublicSale;
		}

		 
		require(tokenRemain>0);

		if (tokenRemain < tokens) {
			 

			uint256 tokensToRefund = tokens.sub(tokenRemain);
			uint256 etherToRefund = tokensToRefund / tokenExchangeRate;

			 
			msg.sender.transfer(etherToRefund);

			tokens=tokenRemain;
			etherRecev = etherRecev.sub(etherToRefund);

			tokenRemain = 0;
		} else {
			tokenRemain = tokenRemain.sub(tokens);
		}

		 
		if(phaseICO == 1){ 
			tokenRemainPreSale = tokenRemain;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemainPublicSale = tokenRemain;
		}

		 
		ccc.sell(msg.sender, tokens);
		ethFundDeposit.transfer(this.balance);

		 
		if(isBonus){
			 
			 
			uint256 bonusAmountETH = getBonusByETH(etherRecev);
			 
			uint256 bonusAmountTokens = bonusAmountETH.mul(tokenExchangeRate);

			 
			if(maxAmountBonus>0){
				if(maxAmountBonus>=bonusAmountTokens){
					maxAmountBonus-=bonusAmountTokens;
				} else {
					bonusAmountTokens = maxAmountBonus;
					maxAmountBonus = 0;
				}
			} else {
				bonusAmountTokens = 0;
			}

			 
			uint256 bonusTimeToken = tokens.mul(getTimeBonus())/100;
			 
			if(maxTimeBonus>0){
				if(maxTimeBonus>=bonusTimeToken){
					maxTimeBonus-=bonusTimeToken;
				} else {
					bonusTimeToken = maxTimeBonus;
					maxTimeBonus = 0;
				}
			} else {
				bonusTimeToken = 0;
			}

			 
			if(bonusAccountBalances[msg.sender]==0){ 
				bonusAccountIndex[bonusAccountCount]=msg.sender;
				bonusAccountCount++;
			}

			uint256 bonusTokens=bonusAmountTokens + bonusTimeToken;
			bonusAccountBalances[msg.sender]=bonusAccountBalances[msg.sender].add(bonusTokens);
		}

		 
		if(isAffiliate){
			address child=msg.sender;
			for(uint256 i=0; i<affiliateLevel; i++){
				uint256 giftToken=affiliateRate[i].mul(tokens)/100;

				 
				if(maxAffiliate<=0){
					break;
				} else {
					if(maxAffiliate>=giftToken){
						maxAffiliate-=giftToken;
					} else {
						giftToken = maxAffiliate;
						maxAffiliate = 0;
					}
				}

				address parent = referral[child];
				if(parent != address(0x00)){ 
					referralBalance[child]=referralBalance[child].add(giftToken);
				}

				child=parent;
			}
		}
	}

	 
	function payAffiliate() public onlyOwner returns (bool success) {
		uint256 toIndex = indexPaidAffiliate + 15;
		if(referralCount < toIndex)
			toIndex = referralCount;

		for(uint256 i=indexPaidAffiliate; i<toIndex; i++) {
			address referee = referralIndex[i];
			payAffiliate1Address(referee);
		}

		return true;
	}

	 
	function payAffiliate1Address(address _referee) public onlyOwner returns (bool success) {
		address referrer = referral[_referee];
		ccc.payBonusAffiliate(referrer, referralBalance[_referee]);

		referralBalance[_referee]=0;
		return true;
	}

	 
	function payBonus() public onlyOwner returns (bool success) {
		uint256 toIndex = indexPaidBonus + 15;
		if(bonusAccountCount < toIndex)
			toIndex = bonusAccountCount;

		for(uint256 i=indexPaidBonus; i<toIndex; i++)
		{
			payBonus1Address(bonusAccountIndex[i]);
		}

		return true;
	}

	 
	function payBonus1Address(address _address) public onlyOwner returns (bool success) {
		ccc.payBonusAffiliate(_address, bonusAccountBalances[_address]);
		bonusAccountBalances[_address]=0;
		return true;
	}

	function finalize() external onlyOwner {
		require (!isFinalized);
		 
		isFinalized = true;
		payAffiliate();
		payBonus();
		ethFundDeposit.transfer(this.balance);
	}

	 
	function getTokenExchangeRate() public constant returns(uint256 rate) {
		rate = tokenExchangeRate;
		if(now<phasePresale_To){
			if(now>=phasePresale_From)
				rate = 10000;
		} else if(now<phasePublicSale3_To){
			rate = 7000;
		}
	}

	 
	function getCurrentICOPhase() public constant returns(uint256 phase) {
		phase = 0;
		if(now>=phasePresale_From && now<phasePresale_To){
			phase = 1;
		} else if (now>=phasePublicSale1_From && now<phasePublicSale1_To) {
			phase = 2;
		} else if (now>=phasePublicSale2_From && now<phasePublicSale2_To) {
			phase = 3;
		} else if (now>=phasePublicSale3_From && now<phasePublicSale3_To) {
			phase = 4;
		}
	}

	 
	function getTokenSold() public constant returns(uint256 tokenSold) {
		 
		uint256 phaseICO = getCurrentICOPhase();
		tokenSold = 0;
		if(phaseICO == 1){ 
			tokenSold = ccc.tokenPreSale().sub(tokenRemainPreSale);
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenSold = ccc.tokenPreSale().sub(tokenRemainPreSale) + ccc.tokenPublicSale().sub(tokenRemainPublicSale);
		}
	}

	 
	function setTokenExchangeRate(uint256 _tokenExchangeRate) public onlyOwner returns (bool) {
		require(_tokenExchangeRate>0);
		tokenExchangeRate=_tokenExchangeRate;
		return true;
	}

	 
	function setMinContribution(uint256 _minContribution) public onlyOwner returns (bool) {
		require(_minContribution>0);
		minContribution=_minContribution;
		return true;
	}

	 
	function setEthFundDeposit(address _ethFundDeposit) public onlyOwner returns (bool) {
		require(_ethFundDeposit != address(0));
		ethFundDeposit=_ethFundDeposit;
		return true;
	}

	 
	function setMaxGasRefund(uint256 _maxGasRefund) public onlyOwner returns (bool) {
		require(_maxGasRefund > 0);
		maxGasRefund = _maxGasRefund;
		return true;
	}
}