 

pragma solidity ^0.4.16;


 
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


contract ERC20 {
	function totalSupply() constant returns (uint totalSupply);
	function balanceOf(address _owner) constant returns (uint balance);
	function transfer(address _to, uint _value) returns (bool success);
	function transferFrom(address _from, address _to, uint _value) returns (bool success);
	function approve(address _spender, uint _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
     
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract OwnedToken {
	address public owner;  
	function OwnedToken () public {
		owner = msg.sender;
	}
	 
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

 
contract NamedOwnedToken is OwnedToken {
	string public name;  
	string public symbol;  
	function NamedOwnedToken(string tokenName, string tokenSymbol) public
	{
        name = tokenName;                                    
        symbol = tokenSymbol;                                
	}

     
    function changeName(string newName, string newSymbol)public onlyOwner {
		name = newName;
		symbol = newSymbol;
    }
}

contract TSBToken is ERC20, NamedOwnedToken {
	using SafeMath for uint256;

     

    uint256 public _totalSupply = 0;  
	uint8 public decimals = 18;  

    
    mapping (address => uint256) public balances;  
    mapping (address => mapping (address => uint256)) public allowed;  

    mapping (address => uint256) public paidETH;  
	uint256 public accrueDividendsPerXTokenETH = 0;
	uint256 public tokenPriceETH = 0;

    mapping (address => uint256) public paydCouponsETH;
	uint256 public accrueCouponsPerXTokenETH = 0;
	uint256 public totalCouponsUSD = 0;
	uint256 public MaxCouponsPaymentUSD = 150000;

	mapping (address => uint256) public rebuySum;
	mapping (address => uint256) public rebuyInformTime;


	uint256 public endSaleTime;
	uint256 public startRebuyTime;
	uint256 public reservedSum;
	bool public rebuyStarted = false;

	uint public tokenDecimals;
	uint public tokenDecimalsLeft;

     
    function TSBToken(
        string tokenName,
        string tokenSymbol
    ) NamedOwnedToken(tokenName, tokenSymbol) public {
		tokenDecimals = 10**uint256(decimals - 5);
		tokenDecimalsLeft = 10**5;
		startRebuyTime = now + 1 years;
		endSaleTime = now;
    }

     
	function transferDiv(uint startTokens, uint fromTokens, uint toTokens, uint sumPaydFrom, uint sumPaydTo, uint acrued) internal constant returns (uint, uint) {
		uint sumToPayDividendsFrom = fromTokens.mul(acrued);
		uint sumToPayDividendsTo = toTokens.mul(acrued);
		uint sumTransfer = sumPaydFrom.div(startTokens);
		sumTransfer = sumTransfer.mul(startTokens-fromTokens);
		if (sumPaydFrom > sumTransfer) {
			sumPaydFrom -= sumTransfer;
			if (sumPaydFrom > sumToPayDividendsFrom) {
				sumTransfer += sumPaydFrom - sumToPayDividendsFrom;
				sumPaydFrom = sumToPayDividendsFrom;
			}
		} else {
			sumTransfer = sumPaydFrom;
			sumPaydFrom = 0;
		}
		sumPaydTo = sumPaydTo.add(sumTransfer);
		if (sumPaydTo > sumToPayDividendsTo) {
			uint differ = sumPaydTo - sumToPayDividendsTo;
			sumPaydTo = sumToPayDividendsTo;
			sumPaydFrom = sumPaydFrom.add(differ);
			if (sumPaydFrom > sumToPayDividendsFrom) {
				sumPaydFrom = sumToPayDividendsFrom;
			} 
		}
		return (sumPaydFrom, sumPaydTo);
	}



     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));                                
        require(balances[_from] >= _value);                 
        require(balances[_to] + _value > balances[_to]);  
		uint startTokens = balances[_from].div(tokenDecimals);
        balances[_from] -= _value;                          
        balances[_to] += _value;                            

		if (balances[_from] == 0) {
			paidETH[_to] = paidETH[_to].add(paidETH[_from]);
		} else {
			uint fromTokens = balances[_from].div(tokenDecimals);
			uint toTokens = balances[_to].div(tokenDecimals);
			(paidETH[_from], paidETH[_to]) = transferDiv(startTokens, fromTokens, toTokens, paidETH[_from], paidETH[_to], accrueDividendsPerXTokenETH+accrueCouponsPerXTokenETH);
		}
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

     
	function totalSupply() public constant returns (uint totalSupply) {
		return _totalSupply;
	}


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

     
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}


	 
    event Burn(address indexed from, uint256 value);

     
    function burnTo(uint256 _value, address adr) internal returns (bool success) {
        require(balances[adr] >= _value);    
        require(_value > 0);    
		uint startTokens = balances[adr].div(tokenDecimals);
        balances[adr] -= _value;             
		uint endTokens = balances[adr].div(tokenDecimals);

		uint sumToPayFrom = endTokens.mul(accrueDividendsPerXTokenETH + accrueCouponsPerXTokenETH);
		uint divETH = paidETH[adr].div(startTokens);
		divETH = divETH.mul(endTokens);
		if (divETH > sumToPayFrom) {
			paidETH[adr] = sumToPayFrom;
		} else {
			paidETH[adr] = divETH;
		}

		_totalSupply -= _value;                       
        Burn(adr, _value);
        return true;
    }

     
    function deleteTokens(address adr, uint256 amount) public onlyOwner canMint {
        burnTo(amount, adr);
    }

	bool public mintingFinished = false;
	event Mint(address indexed to, uint256 amount);
	event MintFinished();

	 
	modifier canMint() {
		require(!mintingFinished);
		_;
	}
	
	function () public payable {
	}

	 
	function WithdrawLeftToOwner(uint sum) public onlyOwner {
	    owner.transfer(sum);
	}
	
     
	function mintToken(address target, uint256 mintedAmount) public onlyOwner canMint  {
		balances[target] += mintedAmount;
		uint tokensInX = mintedAmount.div(tokenDecimals);
		paidETH[target] += tokensInX.mul(accrueDividendsPerXTokenETH + accrueCouponsPerXTokenETH);
		_totalSupply += mintedAmount;
		Mint(owner, mintedAmount);
		Transfer(0x0, target, mintedAmount);
	}

     
	function finishMinting() public onlyOwner returns (bool) {
		mintingFinished = true;
		endSaleTime = now;
		startRebuyTime = endSaleTime + (180 * 1 days);
		MintFinished();
		return true;
	}

     
	function WithdrawDividendsAndCoupons() public {
		withdrawTo(msg.sender,0);
	}

     
	function WithdrawDividendsAndCouponsTo(address _sendadr) public onlyOwner {
		withdrawTo(_sendadr, tx.gasprice * block.gaslimit);
	}

     
	function withdrawTo(address _sendadr, uint comiss) internal {
		uint tokensPerX = balances[_sendadr].div(tokenDecimals);
		uint sumPayd = paidETH[_sendadr];
		uint sumToPayRes = tokensPerX.mul(accrueCouponsPerXTokenETH+accrueDividendsPerXTokenETH);
		uint sumToPay = sumToPayRes.sub(comiss);
		require(sumToPay>sumPayd);
		sumToPay = sumToPay.sub(sumPayd);
		_sendadr.transfer(sumToPay);
		paidETH[_sendadr] = sumToPayRes;
	}

     
	function accrueDividendandCoupons(uint sumDivFinney, uint sumFinneyCoup) public onlyOwner {
		sumDivFinney = sumDivFinney * 1 finney;
		sumFinneyCoup = sumFinneyCoup * 1 finney;
		uint tokens = _totalSupply.div(tokenDecimals);
		accrueDividendsPerXTokenETH = accrueDividendsPerXTokenETH.add(sumDivFinney.div(tokens));
		accrueCouponsPerXTokenETH = accrueCouponsPerXTokenETH.add(sumFinneyCoup.div(tokens));
	}

     
	function setTokenPrice(uint priceFinney) public onlyOwner {
		tokenPriceETH = priceFinney * 1 finney;
	}

	event RebuyInformEvent(address indexed adr, uint256 amount);

     
	function InformRebuy(uint sum) public {
		_informRebuyTo(sum, msg.sender);
	}

	function InformRebuyTo(uint sum, address adr) public onlyOwner{
		_informRebuyTo(sum, adr);
	}

	function _informRebuyTo(uint sum, address adr) internal{
		require (rebuyStarted || (now >= startRebuyTime));
		require (sum <= balances[adr]);
		rebuyInformTime[adr] = now;
		rebuySum[adr] = sum;
		RebuyInformEvent(adr, sum);
	}

     
	function StartRebuy() public onlyOwner{
		rebuyStarted = true;
	}

     
	function doRebuy() public {
		_doRebuyTo(msg.sender, 0);
	}
     
	function doRebuyTo(address adr) public onlyOwner {
		_doRebuyTo(adr, tx.gasprice * block.gaslimit);
	}
	function _doRebuyTo(address adr, uint comiss) internal {
		require (rebuyStarted || (now >= startRebuyTime));
		require (now >= rebuyInformTime[adr].add(14 days));
		uint sum = rebuySum[adr];
		require (sum <= balances[adr]);
		withdrawTo(adr, 0);
		if (burnTo(sum, adr)) {
			sum = sum.div(tokenDecimals);
			sum = sum.mul(tokenPriceETH);
			sum = sum.div(tokenDecimalsLeft);
			sum = sum.sub(comiss);
			adr.transfer(sum);
			rebuySum[adr] = 0;
		}
	}

}

contract TSBCrowdFundingContract is NamedOwnedToken{
	using SafeMath for uint256;


	enum CrowdSaleState {NotFinished, Success, Failure}
	CrowdSaleState public crowdSaleState = CrowdSaleState.NotFinished;


    uint public fundingGoalUSD = 200000;  
    uint public fundingMaxCapUSD = 500000;  
    uint public priceUSD = 1;  
	uint public USDDecimals = 1 ether;

	uint public startTime;  
    uint public endTime;  
    uint public bonusEndTime;  
    uint public selfDestroyTime = 2 weeks;
    TSBToken public tokenReward;  
	
	uint public ETHPrice = 30000;  
	uint public BTCPrice = 400000;  
	uint public PriceDecimals = 100;

	uint public ETHCollected = 0;  
	uint public BTCCollected = 0;  
	uint public amountRaisedUSD = 0;  
	uint public TokenAmountToPay = 0;  

	mapping(address => uint256) public balanceMapPos;
	struct mapStruct {
		address mapAddress;
		uint mapBalanceETH;
		uint mapBalanceBTC;
		uint bonusTokens;
	}
	mapStruct[] public balanceList;  

    uint public bonusCapUSD = 100000;  
	mapping(bytes32 => uint256) public bonusesMapPos;
	struct bonusStruct {
		uint balancePos;
		bool notempty;
		uint maxBonusETH;
		uint maxBonusBTC;
		uint bonusETH;
		uint bonusBTC;
		uint8 bonusPercent;
	}
	bonusStruct[] public bonusesList;  
	
    bool public fundingGoalReached = false; 
    bool public crowdsaleClosed = false;

    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

	function TSBCrowdFundingContract( 
		uint _startTime,
        uint durationInHours,
        string tokenName,
        string tokenSymbol
	) NamedOwnedToken(tokenName, tokenSymbol) public {
	 
	    SetStartTime(_startTime, durationInHours);
		bonusCapUSD = bonusCapUSD * USDDecimals;
	}

    function SetStartTime(uint startT, uint durationInHours) public onlyOwner {
        startTime = startT;
        bonusEndTime = startT+ 24 hours;
        endTime = startT + (durationInHours * 1 hours);
    }

	function assignTokenContract(address tok) public onlyOwner   {
		tokenReward = TSBToken(tok);
		tokenReward.transferOwnership(address(this));
	}

	function () public payable {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = msg.value != 0;
		require( withinPeriod && nonZeroPurchase && (crowdSaleState == CrowdSaleState.NotFinished));
		uint bonuspos = 0;
		if (now <= bonusEndTime) {
 
			bytes32 code = sha3(msg.data);
			bonuspos = bonusesMapPos[code];
		}
		ReceiveAmount(msg.sender, msg.value, 0, now, bonuspos);

	}

	function CheckBTCtransaction() internal constant returns (bool) {
		return true;
	}

	function AddBTCTransactionFromArray (address[] ETHadress, uint[] BTCnum, uint[] TransTime, bytes4[] bonusdata) public onlyOwner {
        require(ETHadress.length == BTCnum.length); 
        require(TransTime.length == bonusdata.length);
        require(ETHadress.length == bonusdata.length);
        for (uint i = 0; i < ETHadress.length; i++) {
            AddBTCTransaction(ETHadress[i], BTCnum[i], TransTime[i], bonusdata[i]);
        }
	}
     
	function AddBTCTransaction (address ETHadress, uint BTCnum, uint TransTime, bytes4 bonusdata) public onlyOwner {
		require(CheckBTCtransaction());
		require((TransTime >= startTime) && (TransTime <= endTime));
		require(BTCnum != 0);
		uint bonuspos = 0;
		if (TransTime <= bonusEndTime) {
 
			bytes32 code = sha3(bonusdata);
			bonuspos = bonusesMapPos[code];
		}
		ReceiveAmount(ETHadress, 0, BTCnum, TransTime, bonuspos);
	}

	modifier afterDeadline() { if (now >= endTime) _; }

     
	function SetCryptoPrice(uint _ETHPrice, uint _BTCPrice) public onlyOwner {
		ETHPrice = _ETHPrice;
		BTCPrice = _BTCPrice;
	}

     
	function convertToUSD(uint ETH, uint BTC) public constant returns (uint) {
		uint _ETH = ETH.mul(ETHPrice);
		uint _BTC = BTC.mul(BTCPrice);
		return (_ETH+_BTC).div(PriceDecimals);
	}

     
	function collectedSum() public constant returns (uint) {
		return convertToUSD(ETHCollected,BTCCollected);
	}

     
    function checkGoalReached() public afterDeadline {
		amountRaisedUSD = collectedSum();
        if (amountRaisedUSD >= (fundingGoalUSD * USDDecimals) ){
			crowdSaleState = CrowdSaleState.Success;
			TokenAmountToPay = amountRaisedUSD;
            GoalReached(owner, amountRaisedUSD);
        } else {
			crowdSaleState = CrowdSaleState.Failure;
		}
    }

     
    function checkMaxCapReached() public {
		amountRaisedUSD = collectedSum();
        if (amountRaisedUSD >= (fundingMaxCapUSD * USDDecimals) ){
	        crowdSaleState = CrowdSaleState.Success;
			TokenAmountToPay = amountRaisedUSD;
            GoalReached(owner, amountRaisedUSD);
        }
    }

	function ReceiveAmount(address investor, uint sumETH, uint sumBTC, uint TransTime, uint bonuspos) internal {
		require(investor != 0x0);

		uint pos = balanceMapPos[investor];
		if (pos>0) {
			pos--;
			assert(pos < balanceList.length);
			assert(balanceList[pos].mapAddress == investor);
			balanceList[pos].mapBalanceETH = balanceList[pos].mapBalanceETH.add(sumETH);
			balanceList[pos].mapBalanceBTC = balanceList[pos].mapBalanceBTC.add(sumBTC);
		} else {
			mapStruct memory newStruct;
			newStruct.mapAddress = investor;
			newStruct.mapBalanceETH = sumETH;
			newStruct.mapBalanceBTC = sumBTC;
			newStruct.bonusTokens = 0;
			pos = balanceList.push(newStruct);		
			balanceMapPos[investor] = pos;
			pos--;
		}
		
		 
		ETHCollected = ETHCollected.add(sumETH);
		BTCCollected = BTCCollected.add(sumBTC);
		
		checkBonus(pos, sumETH, sumBTC, TransTime, bonuspos);
		checkMaxCapReached();
	}

	uint public DistributionNextPos = 0;

     
	function DistributeNextNTokens(uint n) public payable onlyOwner {
		require(BonusesDistributed);
		require(DistributionNextPos<balanceList.length);
		uint nextpos;
		if (n == 0) {
		    nextpos = balanceList.length;
		} else {
    		nextpos = DistributionNextPos.add(n);
    		if (nextpos > balanceList.length) {
    			nextpos = balanceList.length;
    		}
		}
		uint TokenAmountToPay_local = TokenAmountToPay;
		for (uint i = DistributionNextPos; i < nextpos; i++) {
			uint USDbalance = convertToUSD(balanceList[i].mapBalanceETH, balanceList[i].mapBalanceBTC);
			uint tokensCount = USDbalance.mul(priceUSD);
			tokenReward.mintToken(balanceList[i].mapAddress, tokensCount + balanceList[i].bonusTokens);
			TokenAmountToPay_local = TokenAmountToPay_local.sub(tokensCount);
			balanceList[i].mapBalanceETH = 0;
			balanceList[i].mapBalanceBTC = 0;
		}
		TokenAmountToPay = TokenAmountToPay_local;
		DistributionNextPos = nextpos;
	}

	function finishDistribution()  onlyOwner {
		require ((TokenAmountToPay == 0)||(DistributionNextPos >= balanceList.length));
 
		tokenReward.transferOwnership(owner);
		selfdestruct(owner);
	}

     
    function safeWithdrawal() public afterDeadline {
        require(crowdSaleState == CrowdSaleState.Failure);
		uint pos = balanceMapPos[msg.sender];
		require((pos>0)&&(pos<=balanceList.length));
		pos--;
        uint amount = balanceList[pos].mapBalanceETH;
        balanceList[pos].mapBalanceETH = 0;
        if (amount > 0) {
            msg.sender.transfer(amount);
            FundTransfer(msg.sender, amount, false);
        }
    }

     
	function killContract() public onlyOwner {
		require(now >= endTime + selfDestroyTime);
		tokenReward.transferOwnership(owner);
        selfdestruct(owner);
    }

     
	function AddBonusToListFromArray(bytes32[] bonusCode, uint[] ETHsumInFinney, uint[] BTCsumInFinney) public onlyOwner {
	    require(bonusCode.length == ETHsumInFinney.length);
	    require(bonusCode.length == BTCsumInFinney.length);
	    for (uint i = 0; i < bonusCode.length; i++) {
	        AddBonusToList(bonusCode[i], ETHsumInFinney[i], BTCsumInFinney[i] );
	    }
	}
     
	function AddBonusToList(bytes32 bonusCode, uint ETHsumInFinney, uint BTCsumInFinney) public onlyOwner {
		uint pos = bonusesMapPos[bonusCode];

		if (pos > 0) {
			pos -= 1;
			bonusesList[pos].maxBonusETH = ETHsumInFinney * 1 finney;
			bonusesList[pos].maxBonusBTC = BTCsumInFinney * 1 finney;
		} else {
			bonusStruct memory newStruct;
			newStruct.balancePos = 0;
			newStruct.notempty = false;
			newStruct.maxBonusETH = ETHsumInFinney * 1 finney;
			newStruct.maxBonusBTC = BTCsumInFinney * 1 finney;
			newStruct.bonusETH = 0;
			newStruct.bonusBTC = 0;
			newStruct.bonusPercent = 20;
			pos = bonusesList.push(newStruct);		
			bonusesMapPos[bonusCode] = pos;
		}
	}
	bool public BonusesDistributed = false;
	uint public BonusCalcPos = 0;
 
	function checkBonus(uint newBalancePos, uint sumETH, uint sumBTC, uint TransTime, uint pos) internal {
			if (pos > 0) {
				pos--;
				if (!bonusesList[pos].notempty) {
					bonusesList[pos].balancePos = newBalancePos;
					bonusesList[pos].notempty = true;
				} else {
				    if (bonusesList[pos].balancePos != newBalancePos) return;
				}
				bonusesList[pos].bonusETH = bonusesList[pos].bonusETH.add(sumETH);
				 
				 
				bonusesList[pos].bonusBTC = bonusesList[pos].bonusBTC.add(sumBTC);
				 
				 
			}
	}

     
	function calcNextNBonuses(uint N) public onlyOwner {
		require(crowdSaleState == CrowdSaleState.Success);
		require(!BonusesDistributed);
		uint nextPos = BonusCalcPos + N;
		if (nextPos > bonusesList.length) 
			nextPos = bonusesList.length;
        uint bonusCapUSD_local = bonusCapUSD;    
		for (uint i = BonusCalcPos; i < nextPos; i++) {
			if  ((bonusesList[i].notempty) && (bonusesList[i].balancePos < balanceList.length)) {
				uint maxbonus = convertToUSD(bonusesList[i].maxBonusETH, bonusesList[i].maxBonusBTC);
				uint bonus = convertToUSD(bonusesList[i].bonusETH, bonusesList[i].bonusBTC);
				if (maxbonus < bonus)
				    bonus = maxbonus;
				bonus = bonus.mul(priceUSD);
				if (bonusCapUSD_local >= bonus) {
					bonusCapUSD_local = bonusCapUSD_local - bonus;
				} else {
					bonus = bonusCapUSD_local;
					bonusCapUSD_local = 0;
				}
				bonus = bonus.mul(bonusesList[i].bonusPercent) / 100;
				balanceList[bonusesList[i].balancePos].bonusTokens = bonus;
				if (bonusCapUSD_local == 0) {
					BonusesDistributed = true;
					break;
				}
			}
		}
        bonusCapUSD = bonusCapUSD_local;    
		BonusCalcPos = nextPos;
		if (nextPos >= bonusesList.length) {
			BonusesDistributed = true;
		}
	}

}