 

pragma solidity ^0.4.23; contract PeerLicensing {

	 
	 
	uint256 constant scaleFactor = 0x10000000000000000;   

	 
	 
	 
	uint256 constant trickTax = 3; 
	int constant crr_n = 1;  
	int constant crr_d = 2;  

	 
	 
	int constant price_coeff = -0x2793DB20E4C20163A;

	 
	 
	mapping(address => uint256) public holdings_BULL;
	mapping(address => uint256) public holdings_BEAR;
	 
	mapping(address => uint256) public avgFactor_ethSpent;

	 
	 
		 
	
	 
	 
	mapping(address => address) public reff;
	mapping(address => uint256) public tricklePocket;
	mapping(address => uint256) public trickling;
	mapping(address => int256) public payouts;

	 
	uint256 public totalBondSupply_BULL;
	uint256 public totalBondSupply_BEAR;

	 
	 
	int256 totalPayouts;
	uint256 public tricklingSum;
	uint256 public stakingRequirement = 1e18;
	address public lastGateway;

	 
	uint256 public withdrawSum;
	uint256 public investSum;

	 
	 
	uint256 earningsPerBond_BULL;
	uint256 earningsPerBond_BEAR;

	function PeerLicensing() public {
	}


	event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        bool token
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 totalTokensAtTheTime, 
        uint256 tokensBurned,
        uint256 ethereumEarned,
        bool token,
        uint256 resolved
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        bool token
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );


	 


	 
	function holdingsOf(address _owner) public constant returns (uint256 balance) {
		return holdings_BULL[_owner] + holdings_BEAR[_owner];
	}
	function holdingsOf_BULL(address _owner) public constant returns (uint256 balance) {
		return holdings_BULL[_owner];
	}
	function holdingsOf_BEAR(address _owner) public constant returns (uint256 balance) {
		return holdings_BEAR[_owner];
	}

	 
	 
	function withdraw() public {
		trickleUp();
		 
		var balance = dividends(msg.sender);
		var pocketBalance = tricklePocket[msg.sender];
		tricklePocket[msg.sender] = 0;
		tricklingSum = sub(tricklingSum,pocketBalance);
		uint256 out =add(balance, pocketBalance);
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		withdrawSum = add(withdrawSum,out);
		msg.sender.transfer(out);
		onWithdraw(msg.sender, out);
	}

	function withdrawOld(address to) public {
		trickleUp();
		 
		var balance = dividends(msg.sender);
		var pocketBalance = tricklePocket[msg.sender];
		tricklePocket[msg.sender] = 0;
		tricklingSum = sub(tricklingSum,pocketBalance); 
		uint256 out =add(balance, pocketBalance);
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		withdrawSum = add(withdrawSum,out);
		to.transfer(out);
		onWithdraw(to,out);
	}
	function fullCycleSellBonds(uint256 balance) internal {
		 
		withdrawSum = add(withdrawSum,balance );
		msg.sender.transfer(balance);
		emit onWithdraw(msg.sender, balance);
	}


	 
	 
	 
	function sellBonds(uint256 _amount, bool bondType) public {
		uint256 bondBalance;
		if(bondType){
			bondBalance = holdings_BULL[msg.sender];
		}else{
			bondBalance = holdings_BEAR[msg.sender];
		}
		if(_amount <= bondBalance && _amount > 0){
			sell(_amount,bondType);
		}else{
			if(_amount > bondBalance ){
				sell(bondBalance,bondType);
			}else{
				revert();
			}
		}
	}

	 
	 
    function getMeOutOfHere() public {
		sellBonds( holdings_BULL[msg.sender] ,true);
		sellBonds( holdings_BEAR[msg.sender] ,false);
        withdraw();
	}

	function reffUp(address _reff) internal{
		address sender = msg.sender;
		if (_reff == 0x0000000000000000000000000000000000000000)
			_reff = lastGateway;
			
		if(  add(holdings_BEAR[_reff],holdings_BULL[_reff]) >= stakingRequirement ) {
			 
		}else{
			if(lastGateway == 0x0000000000000000000000000000000000000000){
				lastGateway = sender; 
				_reff = sender; 
			}
			else
				_reff = lastGateway; 
		}

		reff[sender] = _reff;
	}
	 
	 
	 
	 
	 


	function fund(address _reff,bool bondType) payable public {
		 
		reffUp(_reff);
		if (msg.value > 0.000001 ether) {
			investSum = add(investSum,msg.value);

		    buy(bondType );
			lastGateway = msg.sender;
		} else {
			revert();
		}
    }
	 
	function buyPrice() public constant returns (uint) {
		return getTokensForEther(1 finney);
	}

	 
	function sellPrice() public constant returns (uint) {
        var eth = getEtherForTokens(1 finney);
        var fee = fluxFeed(eth, false);
        return eth - fee;
    }
	function fluxFeed(uint256 _eth, bool slim_reinvest) public constant returns (uint256 amount) {
		if (withdrawSum == 0){
			return 0;
		}else{
			if(slim_reinvest){
				return div( mul(_eth , withdrawSum), mul(investSum,3) ); 
			}else{
				return div( mul(_eth , withdrawSum), investSum); 
			}
		}
		 
		 
		 

		 
	}

	 
	 
	 
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerBond_BULL * holdings_BULL[_owner] + earningsPerBond_BEAR * holdings_BEAR[_owner]) - payouts[_owner]) / scaleFactor;
	}
	function cashWallet(address _owner) public constant returns (uint256 amount) {
		return tricklePocket[_owner] + dividends(_owner);
	}

	 
	function balance() internal constant returns (uint256 amount){
		 
		return sub(sub(investSum,withdrawSum) ,add( msg.value , tricklingSum));
	}
				function trickleUp() internal{
					uint256 tricks = trickling[ msg.sender ];
					if(tricks > 0){
						trickling[ msg.sender ] = 0;
						uint256 passUp = div(tricks,trickTax);
						uint256 reward = sub(tricks,passUp); 
						address reffo = reff[msg.sender];
						if( holdingsOf(reffo) < stakingRequirement){
							trickling[ reffo ] = add(trickling[ reffo ],passUp);
							tricklePocket[ reffo ] = add(tricklePocket[ reffo ],reward);
						}else{ 
							trickling[ lastGateway ] = add(trickling[ lastGateway ],passUp);
							tricklePocket[ lastGateway ] = add(tricklePocket[ lastGateway ],reward);
						} 
					}
				}

								function buy(bool bondType ) internal {
									 
									if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
										revert();
													
									 
									var sender = msg.sender;
									
									 
									uint256 fee = 0; 
									uint256 trickle = 0; 
									if(holdings_BULL[sender] != totalBondSupply_BULL){
										fee = fluxFeed(msg.value,false);
										trickle = div(fee, trickTax);
										fee = sub(fee , trickle);
										trickling[sender] = add(trickling[sender],trickle);
									}
									var numEther = sub(msg.value , add(fee , trickle)); 
									var numTokens = getTokensForEther(numEther); 


									 
									var buyerFee = fee * scaleFactor;
									
									if (totalBondSupply_BULL > 0){ 
										 
										 
										 
										uint256 bonusCoEff;
										if(bondType){
											bonusCoEff = (scaleFactor - (reserve() + numEther) * numTokens * scaleFactor / ( totalBondSupply_BULL + totalBondSupply_BEAR + numTokens) / numEther) * (uint)(crr_d) / (uint)(crr_d-crr_n);
										}else{
											bonusCoEff = scaleFactor;
										}
										
										 
										 
										var holderReward = fee * bonusCoEff;
										
										buyerFee -= holderReward;
										
										 
										earningsPerBond_BULL = add(earningsPerBond_BULL,div(holderReward , totalBondSupply_BULL));
										
									}

									 
									avgFactor_ethSpent[msg.sender] = add(avgFactor_ethSpent[msg.sender], numEther);

									int256 payoutDiff;
									if(bondType){
										 
										totalBondSupply_BULL = add(totalBondSupply_BULL, numTokens);
										 
										holdings_BULL[sender] = add(holdings_BULL[sender], numTokens);
										 
										 
										 
										payoutDiff = (int256) ((earningsPerBond_BULL * numTokens) - buyerFee);
									}else{
										totalBondSupply_BEAR = add(totalBondSupply_BEAR, numTokens);
										holdings_BEAR[sender] = add(holdings_BEAR[sender], numTokens);
										payoutDiff = (int256) ((earningsPerBond_BEAR * numTokens) - buyerFee);
									}
									
									 
									payouts[sender] = payouts[sender]+payoutDiff;
									
									 
									totalPayouts = totalPayouts+payoutDiff;

									tricklingSum = add(tricklingSum,trickle); 
									trickleUp();

									if(bondType){
										emit onTokenPurchase(sender,numEther,numTokens, reff[sender],true);
									}else{
										emit onTokenPurchase(sender,numEther,numTokens, reff[sender],false);
									}

									 
									 
								}

								 
								 
								 
								function sell(uint256 amount,bool bondType) internal {
								    var numEthersBeforeFee = getEtherForTokens(amount);
									
									 
									uint256 fee = 0;
									uint256 trickle = 0;
									if(totalBondSupply_BEAR != holdings_BEAR[msg.sender]){
										fee = fluxFeed(numEthersBeforeFee, true);
							        	trickle = div(fee, trickTax);
										fee = sub(fee , trickle);
										trickling[msg.sender] = add(trickling[msg.sender],trickle);
										tricklingSum = add(tricklingSum , trickle);
									} 
									
									 
							        var numEthers = sub(numEthersBeforeFee , add(fee , trickle));

									 
									 
									uint256 resolved = mint(
										calcResolve(msg.sender,amount,numEthers),
										msg.sender
									);

									 
									 

									 
									int256 payoutDiff;
									if(bondType){
										totalBondSupply_BULL = sub(totalBondSupply_BULL, amount);

										avgFactor_ethSpent[msg.sender] = mul( avgFactor_ethSpent[msg.sender] ,sub(holdings_BULL[msg.sender], amount) ) / holdings_BULL[msg.sender];
										 
										holdings_BULL[msg.sender] = sub(holdings_BULL[msg.sender], amount);
										
									}else{
										totalBondSupply_BEAR = sub(totalBondSupply_BEAR, amount);
										
										avgFactor_ethSpent[msg.sender] = mul( avgFactor_ethSpent[msg.sender] ,sub(holdings_BEAR[msg.sender], amount) ) / holdings_BEAR[msg.sender];
										 
										holdings_BEAR[msg.sender] = sub(holdings_BEAR[msg.sender], amount);
									}
									fullCycleSellBonds(numEthers);
									
									 
									 
									if (totalBondSupply_BEAR > 0) {
										 
										var etherFee = mul(fee , scaleFactor);
										
										 
										 
										var rewardPerShare = div(etherFee , totalBondSupply_BEAR);
										
										 
										earningsPerBond_BEAR = add(earningsPerBond_BEAR, rewardPerShare);
									}
									
									trickleUp();
									emit onTokenSell(msg.sender,add(add(holdings_BULL[msg.sender],holdings_BEAR[msg.sender]),amount),amount,numEthers,bondType,resolved);

								}

				 
				 
				function reinvest(bool bondType ) internal {
					 
					var balance = dividends(msg.sender);
					balance = add(balance,tricklePocket[msg.sender]);
					tricklingSum = sub(tricklingSum,tricklePocket[msg.sender]);
					tricklePocket[msg.sender] = 0;

					
					 
					 
					payouts[msg.sender] += (int256) (balance * scaleFactor);
					
					 
					totalPayouts += (int256) (balance * scaleFactor);
					
					 
					uint value_ = (uint) (balance);
					
					 
					 
					if (value_ < 0.000001 ether || value_ > 1000000 ether)
						revert();
						
					 
					 
					


					uint256 fee = 0; 
					uint256 trickle = 0;
					if(holdings_BULL[msg.sender] != totalBondSupply_BULL){
						fee = fluxFeed(value_, true );  
						trickle = div(fee, trickTax);
						fee = sub(fee , trickle);
						trickling[msg.sender] += trickle;
					}
					

					var res = sub(reserve() , balance);
					 
					var numEther = value_ - fee;
					
					 
					var numTokens = calculateDividendTokens(numEther, balance);
					
					 
					var buyerFee = fee * scaleFactor;
					
					 
					 
					if (totalBondSupply_BULL > 0) {
						uint256 bonusCoEff;
						if(bondType){
							 
							 
							 
							bonusCoEff =  (scaleFactor - (res + numEther ) * numTokens * scaleFactor / (totalBondSupply_BULL + totalBondSupply_BEAR  + numTokens) / numEther) * (uint)(crr_d) / (uint)(crr_d-crr_n);
						}else{
							bonusCoEff = scaleFactor;
						}
						
						 
						 
						buyerFee -= fee * bonusCoEff;

						 
						 
						
						 
						earningsPerBond_BULL += fee * bonusCoEff / totalBondSupply_BULL;
					}
					 
					avgFactor_ethSpent[msg.sender] = add(avgFactor_ethSpent[msg.sender], numEther);

					int256 payoutDiff;
					if(bondType){
						 
						totalBondSupply_BULL = add(totalBondSupply_BULL, numTokens);
						 
						holdings_BULL[msg.sender] = add(holdings_BULL[msg.sender], numTokens);
						 
						 
						 
						payoutDiff = (int256) ((earningsPerBond_BULL * numTokens) - buyerFee);
					}else{
						totalBondSupply_BEAR = add(totalBondSupply_BEAR, numTokens);
						holdings_BEAR[msg.sender] = add(holdings_BEAR[msg.sender], numTokens);
						payoutDiff = (int256) ((earningsPerBond_BEAR * numTokens) - buyerFee);
					}
					
					 
					 
					
					 
					payouts[msg.sender] += payoutDiff;
					
					 
					totalPayouts += payoutDiff;

					tricklingSum += trickle; 
					trickleUp();
					if(bondType){
						emit onReinvestment(msg.sender,numEther,numTokens,true);
					}else{
						emit onReinvestment(msg.sender,numEther,numTokens,false);	
					}

					 
					 
				}

	
	 
	function reserve() internal constant returns (uint256 amount){
		return sub(balance(),
			  ((uint256) ((int256) (earningsPerBond_BULL * totalBondSupply_BULL + earningsPerBond_BEAR * totalBondSupply_BEAR) - totalPayouts ) / scaleFactor) 
		);
	}

	 
	 
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff), totalBondSupply_BULL + totalBondSupply_BEAR);
	}

	 
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff), totalBondSupply_BULL + totalBondSupply_BEAR);
	}

	 
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		 
		var reserveAmount = reserve();

		 
		if (tokens == (totalBondSupply_BULL + totalBondSupply_BEAR) )
			return reserveAmount;

		 
		 
		 
		 
		return sub(reserveAmount, fixedExp((fixedLog(totalBondSupply_BULL + totalBondSupply_BEAR - tokens) - price_coeff) * crr_d/crr_n));
	}

	 
	 
	int256  constant one        = 0x10000000000000000;
	uint256 constant sqrt2      = 0x16a09e667f3bcc908;
	uint256 constant sqrtdot5   = 0x0b504f333f9de6484;
	int256  constant ln2        = 0x0b17217f7d1cf79ac;
	int256  constant ln2_64dot5 = 0x2cb53f09f05cc627c8;
	int256  constant c1         = 0x1ffffffffff9dac9b;
	int256  constant c3         = 0x0aaaaaaac16877908;
	int256  constant c5         = 0x0666664e5e9fa0c99;
	int256  constant c7         = 0x049254026a7630acf;
	int256  constant c9         = 0x038bd75ed37753d68;
	int256  constant c11        = 0x03284a0c14610924f;

	 
	 
	 
	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > sqrt2) {
			a /= 2;
			scale++;
		}
		while (a <= sqrtdot5) {
			a *= 2;
			scale--;
		}
		int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
		var z = (s*s) / one;
		return scale * ln2 +
			(s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
				/one))/one))/one))/one))/one);
	}

	int256 constant c2 =  0x02aaaaaaaaa015db0;
	int256 constant c4 = -0x000b60b60808399d1;
	int256 constant c6 =  0x0000455956bccdd06;
	int256 constant c8 = -0x000001b893ad04b3a;
	
	 
	 
	 
	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
		a -= scale*ln2;
		int256 z = (a*a) / one;
		int256 R = ((int256)(2) * one) +
			(z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
		exp = (uint256) (((R + a) * one) / (R - a));
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
	}
	
	 
	 

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

	function () payable public {
		if (msg.value > 0) {
			fund(lastGateway,true);
		} else {
			withdrawOld(msg.sender);
		}
	}

	uint256 public totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name = "0xBabylon";
    uint8 public decimals = 12;
    string public symbol = "PoWHr";
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Resolved(address indexed _owner, uint256 amount);
    event Burned(address indexed _owner, uint256 amount);

    function mint(uint256 amount,address _account) internal returns (uint minted){
    	totalSupply += amount;
    	balances[_account] += amount;
    	Resolved(_account,amount);
    	return amount;
    }

	function burn(uint256 _value) public returns (uint256 amount) {
        require(balances[msg.sender] >= _value);
        totalSupply -= _value;
    	balances[msg.sender] -= _value;
    	Resolved(msg.sender,_value);
    	return _value;
    }

	function calcResolve(address _owner,uint256 amount,uint256 _eth) public constant returns (uint256 calculatedResolveTokens) {
		return div(div(div(mul(mul(amount,amount),avgFactor_ethSpent[_owner]),holdings_BULL[_owner]+holdings_BEAR[_owner]),_eth),1000000);
	}


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function resolveSupply(address _owner) public view returns (uint256 balance) {
        return totalSupply;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}