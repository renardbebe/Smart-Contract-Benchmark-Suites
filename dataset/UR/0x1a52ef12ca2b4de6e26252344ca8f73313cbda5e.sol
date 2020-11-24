 

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

	string public constant name      = "JWC";  
	string public constant symbol    = "JWC";  
	uint256 public constant decimals = 18;     
	string public constant version   = "1.0";  

	uint256 public tokenPreSale         = 100000000 * 10**decimals; 
	uint256 public tokenPublicSale      = 400000000 * 10**decimals; 
	uint256 public tokenReserve         = 300000000 * 10**decimals; 
	uint256 public tokenTeamSupporter   = 120000000 * 10**decimals; 
	uint256 public tokenAdvisorPartners = 80000000  * 10**decimals; 

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

	 
	function sellSpecialTokensForPreSale(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);
		tokenPreSale = tokenPreSale.add(_value);
		totalSupply = totalSupply.add(_value);

		Transfer(0x0, _recipient, _value);
		return true;
	}

	 
	function sellSpecialTokensForPublicSale(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);

		balances[_recipient] = balances[_recipient].add(_value);
		tokenPublicSale = tokenPublicSale.add(_value);
		totalSupply = totalSupply.add(_value);

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
  uint256 public constant phasePresale_From = 1517493600; 
  uint256 public constant phasePresale_To = 1518703200; 

  uint256 public constant phasePublicSale1_From = 1520690400; 
  uint256 public constant phasePublicSale1_To = 1521122400; 

  uint256 public constant phasePublicSale2_From = 1521122400; 
  uint256 public constant phasePublicSale2_To = 1521554400; 

  uint256 public constant phasePublicSale3_From = 1521554400; 
  uint256 public constant phasePublicSale3_To = 1521986400; 
}

 
contract Affiliate is Ownable {

	 
	bool public isAffiliate;

	 
	uint256 public affiliateLevel = 1;

	 
	mapping(uint256 => uint256) public affiliateRate;

	 
	mapping(address => uint256) public referralBalance; 

	mapping(address => address) public referral; 
	mapping(uint256 => address) public referralIndex; 

	uint256 public referralCount;

	 
	modifier whenAffiliate() {
		require (isAffiliate);
		_;
	}

	 
	function Affiliate() public {
		isAffiliate=true;
		affiliateLevel=1;
		affiliateRate[0]=6;
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

	 
	function payAffiliateToAddress(address _referee) public onlyOwner returns (bool success);
}

 
contract Bonus is IcoPhase, Ownable {
	using SafeMath for uint256;

	 
	uint256 constant decimals = 18;

	 
	bool public isBonus;

	 
	mapping(address => uint256) public bonusAccountBalances;
	mapping(uint256 => address) public bonusAccountIndex;
	uint256 public bonusAccountCount;

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

	 
	function getBonusByTime() public constant returns(uint256) {
		uint256 bonus = 0;

		if(now>=phasePresale_From && now<phasePresale_To){
			bonus = 10;
		} else if (now>=phasePublicSale1_From && now<phasePublicSale1_To) {
			bonus = 6;
		} else if (now>=phasePublicSale2_From && now<phasePublicSale2_To) {
			bonus = 3;
		} else if (now>=phasePublicSale3_From && now<phasePublicSale3_To) {
			bonus = 1;
		}

		return bonus;
	}

	 
	function getBonusByETH(uint256 _value) public constant returns(uint256) {
		uint256 bonus = 0;

		if(now>=phasePresale_From && now<phasePresale_To){
			if(_value>=400*10**decimals){
				bonus=_value.mul(10).div(100);
			} else if(_value>=300*10**decimals){
				bonus=_value.mul(5).div(100);
			}
		}

		return bonus;
	}

	 
	function balanceBonusOf(address _owner) public constant returns (uint256 balance)
	{
		return bonusAccountBalances[_owner];
	}

	 
	function payBonusToAddress(address _address) public onlyOwner returns (bool success);
}

 
contract IcoContract is IcoPhase, Ownable, Pausable, Affiliate, Bonus {
	using SafeMath for uint256;

	JWCToken ccc;

	uint256 public totalTokenSale;
	uint256 public minContribution = 0.5 ether; 
	uint256 public tokenExchangeRate = 10000; 
	uint256 public constant decimals = 18;

	uint256 public tokenRemainPreSale; 
	uint256 public tokenRemainPublicSale; 

	address public ethFundDeposit = 0x1Eb0fAaC52ED0AfCcbf1F3E67A399Da5440351cf; 
	address public tokenAddress;

	bool public isFinalized;

	uint256 public maxGasRefund = 0.004 ether; 

	 
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

		uint256 tokens = etherRecev.mul(tokenExchangeRate);

		 
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
			 
			uint256 tokensToIncrease = tokens.sub(tokenRemain);
			ccc.sell(msg.sender, tokenRemain);

			if(phaseICO == 1){ 
				ccc.sellSpecialTokensForPreSale(msg.sender, tokensToIncrease);
			} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
				ccc.sellSpecialTokensForPublicSale(msg.sender, tokensToIncrease);
			}

			tokenRemain = 0;
		} else {
			ccc.sell(msg.sender, tokens);
			tokenRemain = tokenRemain.sub(tokens);
		}

		 
		if(phaseICO == 1){ 
			tokenRemainPreSale = tokenRemain;
		} else if (phaseICO == 2 || phaseICO == 3 || phaseICO == 4) {
			tokenRemainPublicSale = tokenRemain;
		}

		ethFundDeposit.transfer(this.balance);

		 
		if(isBonus){
			 
			 
			uint256 bonusByETH = getBonusByETH(etherRecev);
			 
			uint256 bonusTokenByETH = bonusByETH.mul(tokenExchangeRate);

			 
			uint256 bonusTokenByTime = tokens.mul(getBonusByTime()).div(100);

			 
			if(bonusAccountBalances[msg.sender]==0){ 
				bonusAccountIndex[bonusAccountCount]=msg.sender;
				bonusAccountCount++;
			}

			uint256 bonusToken=bonusTokenByTime+bonusTokenByETH;
			bonusAccountBalances[msg.sender]=bonusAccountBalances[msg.sender].add(bonusToken);
		}

		 
		if(isAffiliate){
			address child=msg.sender;
			for(uint256 i=0; i<affiliateLevel; i++){
				uint256 giftToken=affiliateRate[i].mul(tokens).div(100);

				address parent = referral[child];
				if(parent != address(0x00)){ 
					referralBalance[child]=referralBalance[child].add(giftToken);
				}

				child=parent;
			}
		}
	}

	 
	function payAffiliateToAddress(address _referee) public onlyOwner returns (bool success) {
		address referrer = referral[_referee];
		ccc.payBonusAffiliate(referrer, referralBalance[_referee]);

		referralBalance[_referee]=0;
		return true;
	}

	 
	function payBonusToAddress(address _address) public onlyOwner returns (bool success) {
		ccc.payBonusAffiliate(_address, bonusAccountBalances[_address]);
		bonusAccountBalances[_address]=0;
		return true;
	}

	function finalize() external onlyOwner {
		require (!isFinalized);
		 
		isFinalized = true;
		ethFundDeposit.transfer(this.balance);
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