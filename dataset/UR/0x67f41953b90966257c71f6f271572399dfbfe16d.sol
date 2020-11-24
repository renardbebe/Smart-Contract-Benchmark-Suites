 

pragma solidity ^0.4.23; 
contract PeerLicensing{
	 
	 
	uint256 constant scaleFactor = 0x10000000000000000; 

	 
	 
	 
	uint256 constant trickTax = 3; 
	int constant crr_n = 1;  
	int constant crr_d = 2;  

	int constant price_coeff = 0x57ea9ce452cde449f;

	 
	mapping(address => uint256) public holdings;
	 
	mapping(address => uint256) public avgFactor_ethSpent;

	mapping(address => uint256) public souleculeR;
	mapping(address => uint256) public souleculeG;
	mapping(address => uint256) public souleculeB;

	 
	 
	mapping(address => address) public reff;
	mapping(address => uint256) public tricklingFlo;
	mapping(address => uint256) public pocket;
	mapping(address => int256) public payouts;

	 
	uint256 public totalBondSupply;

	 
	 
	int256 totalPayouts;
	uint256 public trickleSum;
	uint256 public stakingRequirement = 1e18;
	
	address public lastGateway;

	 
	uint256 public withdrawSum;
	uint256 public investSum;

	 
	 
	uint256 earningsPerBond;

	constructor() public {}

	event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
	event onBoughtFor(
        address indexed buyerAddress,
        address indexed forWho,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 totalTokensAtTheTime, 
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint256 resolved
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    event onCashDividends(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    event onColor(
        address indexed customerAddress,
        uint256 oldR,
        uint256 oldG,
        uint256 oldB,
        uint256 newR,
        uint256 newG,
        uint256 newB
    );


	 


	 
	function holdingsOf(address _owner) public constant returns (uint256 balance) {
		return holdings[_owner];
	}

	 
	 
	function withdraw(address to) public {
		trickleUp();
		 
		uint256 balance = dividends(msg.sender);
		 
		 
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);

		uint256 pocketETH = pocket[msg.sender];
		pocket[msg.sender] = 0;
		trickleSum -= pocketETH;

		balance += pocketETH;
		 
		withdrawSum += balance;
		to.transfer(balance);
		emit onCashDividends(to,balance);
	}
	function fullCycleSellBonds(uint256 balance) internal {
		 
		withdrawSum += balance;
		msg.sender.transfer(balance);
		emit onWithdraw(msg.sender, balance);
	}


	 
	 
	 
	function sellBonds(uint256 _amount) public {
		uint256 bondBalance = holdings[msg.sender];
		if(_amount <= bondBalance && _amount > 0){
			sell(_amount);
		}else{
			sell(bondBalance);
		}
	}

	 
	 
    function getMeOutOfHere() public {
		sellBonds( holdings[msg.sender] );
        withdraw(msg.sender);
	}

	function reffUp(address _reff) internal{
		address sender = msg.sender;
		if (_reff == 0x0000000000000000000000000000000000000000 || _reff == msg.sender)
			_reff = lastGateway;
			
		if(  holdings[_reff] >= stakingRequirement ) {
			 
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
	function rgbLimit(uint256 _rgb)internal pure returns(uint256){
		if(_rgb > 255)
			return 255;
		else
			return _rgb;
	}
	 
	 
	 
	function edgePigment(uint8 C)internal view returns (uint256 x)
	{	
		uint256 holding = holdings[msg.sender];
		if(holding==0)
			return 0;
		else{
			if(C==0){
				return 255 * souleculeR[msg.sender]/holding;
			}else if(C==1){
				return 255 * souleculeG[msg.sender]/holding;
			}else if(C==2){
				return 255 * souleculeB[msg.sender]/holding;
			}
		} 
	}
	function fund(address reffo, address forWho) payable public {
		fund_color( reffo, forWho, edgePigment(0),edgePigment(1),edgePigment(2) );
	}
	function fund_color( address _reff, address forWho,uint256 soulR,uint256 soulG,uint256 soulB) payable public {
		 
		reffUp(_reff);
		if (msg.value > 0.000001 ether){
			investSum += msg.value;
			soulR=rgbLimit(soulR);
			soulG=rgbLimit(soulG);
			soulB=rgbLimit(soulB);
		    buy( forWho ,soulR,soulG,soulB);
			lastGateway = msg.sender;
		} else {
			revert();
		}
    }

    function reinvest_color(uint256 soulR,uint256 soulG,uint256 soulB) public {
    	soulR=rgbLimit(soulR);
		soulG=rgbLimit(soulG);
		soulB=rgbLimit(soulB);
		processReinvest( soulR,soulG,soulB);
	}
    function reinvest() public {
		processReinvest( edgePigment(0),edgePigment(1),edgePigment(2) );
	}

	 
	function price(bool buyOrSell) public constant returns (uint) {
        if(buyOrSell){
        	return getTokensForEther(1 finney);
        }else{
        	uint256 eth = getEtherForTokens(1 finney);
	        uint256 fee = fluxFeed(eth, false, false);
	        return eth - fee;
        }
    }

	function fluxFeed(uint256 _eth, bool slim_reinvest,bool buyOrSell) public constant returns (uint256 amount) {	
		uint8 bonus;
		if(slim_reinvest){
			bonus = 3;
			 
		}else{
			bonus = 1;
		}
		if(buyOrSell)
			return  _eth/bonus * withdrawSum/(investSum); 
		else
			return  _eth/bonus * (withdrawSum + _eth)/investSum;
	
		 
		 
		 

		 
	}

	 
	 
	 
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)( earningsPerBond * holdings[_owner] ) - payouts[_owner] ) / scaleFactor;
	}
	function cashWallet(address _owner) public constant returns (uint256 amount) {
		return dividends(_owner)+pocket[_owner];
	}

	 
	function contractBalance() internal constant returns (uint256 amount){
		 
		return investSum - withdrawSum - msg.value - trickleSum;
	}
				function trickleUp() internal{
					uint256 tricks = tricklingFlo[ msg.sender ]; 
					if(tricks > 0){
						tricklingFlo[ msg.sender ] = 0; 
						uint256 passUp = tricks/trickTax; 
						uint256 reward = tricks-passUp; 
						address finalReff; 
						address reffo =  reff[msg.sender]; 
						if( holdings[reffo] >= stakingRequirement){
							finalReff = reffo; 
						}else{
							finalReff = lastGateway; 
						}
						tricklingFlo[ finalReff ] += passUp; 
						pocket[ msg.sender ] += reward; 
					}
				}
								function buy(address forWho,uint256 soulR,uint256 soulG,uint256 soulB) internal {
									 
									if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
										revert();	
									
									 
									uint256 fee = 0; 
									uint256 trickle = 0; 
									if(holdings[forWho] != totalBondSupply){
										fee = fluxFeed(msg.value,false,true);
										trickle = fee/trickTax;
										fee = fee - trickle;
										tricklingFlo[forWho] += trickle;
									}
									uint256 numEther = msg.value - (fee+trickle); 
									uint256 numTokens = getTokensForEther(numEther); 

									buyCalcAndPayout( forWho, fee, numTokens, numEther, reserve() );

									addPigment(numTokens,soulR,soulG,soulB);

									trickleSum += trickle; 
									trickleUp();
								
									emit onTokenPurchase(forWho, numEther ,numTokens , reff[msg.sender]);
									
									if(forWho != msg.sender){ 
										 
										if(reff[forWho] == 0x0000000000000000000000000000000000000000)
											{reff[forWho] = msg.sender;}
											emit onBoughtFor(msg.sender, forWho,numEther,numTokens,reff[msg.sender]);
									}
								}
													function buyCalcAndPayout(address forWho,uint256 fee,uint256 numTokens,uint256 numEther,uint256 res)internal{
														 
														uint256 buyerFee = fee * scaleFactor;
														
														if (totalBondSupply > 0){ 
															 
															 
															 
															uint256 bonusCoEff = (scaleFactor - (res + numEther) * numTokens * scaleFactor / ( totalBondSupply  + numTokens) / numEther)
									 						*(uint)(crr_d) / (uint)(crr_d-crr_n);
															
															 
															 
															uint256 holderReward = fee * bonusCoEff;
															
															buyerFee -= holderReward;
															
															 
															earningsPerBond +=  holderReward / totalBondSupply;
														}
														 
														avgFactor_ethSpent[forWho] += numEther;

														 
														totalBondSupply += numTokens;
														 
														holdings[forWho] += numTokens;
														 
														 
														 
														int256 payoutDiff = (int256) ((earningsPerBond * numTokens) - buyerFee);
														 
														payouts[forWho] += payoutDiff;
														
														 
														totalPayouts += payoutDiff;
													}
								 
								 
								 
								function TOKEN_scaleDown(uint256 value,uint256 reduce) internal view returns(uint256 x){
									uint256 holdingsOfSender = holdings[msg.sender];
									return value * ( holdingsOfSender - reduce) / holdingsOfSender;
								}
								function sell(uint256 amount) internal {
								    uint256 numEthersBeforeFee = getEtherForTokens(amount);
									
									 
									uint256 fee = 0;
									uint256 trickle = 0;
									if(totalBondSupply != holdings[msg.sender]){
										fee = fluxFeed(numEthersBeforeFee, false,false);
							        	trickle = fee/ trickTax;
										fee -= trickle;
										tricklingFlo[msg.sender] +=trickle;
									}
									
									 
							        uint256 numEthers = numEthersBeforeFee - (fee+trickle);

									 
									 
									uint256 resolved = mint(
										calcResolve(msg.sender,amount,numEthersBeforeFee),
										msg.sender
									);

									 
									avgFactor_ethSpent[msg.sender] = TOKEN_scaleDown(avgFactor_ethSpent[msg.sender] , amount);

									souleculeR[msg.sender] = TOKEN_scaleDown(souleculeR[msg.sender] , amount);
									souleculeG[msg.sender] = TOKEN_scaleDown(souleculeG[msg.sender] , amount);
									souleculeB[msg.sender] = TOKEN_scaleDown(souleculeB[msg.sender] , amount);
									
									totalBondSupply -= amount;
									 
									holdings[msg.sender] -= amount;

									int256 payoutDiff = (int256) (earningsPerBond * amount); 
		
							         
									 
									 
									payouts[msg.sender] -= payoutDiff;		
									
									 
							        totalPayouts -= payoutDiff;
							        

									 
									 
									if (totalBondSupply > 0) {
										 
										uint256 etherFee = fee * scaleFactor;
										
										 
										 
										uint256 rewardPerShare = etherFee / totalBondSupply;
										
										 
										earningsPerBond +=  rewardPerShare;
									}
									fullCycleSellBonds(numEthers);
								
									trickleSum += trickle;
									trickleUp();
									emit onTokenSell(msg.sender,holdings[msg.sender]+amount,amount,numEthers,resolved);
								}

				 
				 
				function processReinvest(uint256 soulR,uint256 soulG,uint256 soulB) internal{
					 
					uint256 balance = dividends(msg.sender);

					 
					 
					payouts[msg.sender] += (int256) (balance * scaleFactor);
					
					 
					totalPayouts += (int256) (balance * scaleFactor);					
						
					 
					uint256 pocketETH = pocket[msg.sender];
					uint value_ = (uint) (balance + pocketETH);
					pocket[msg.sender] = 0;
					
					 
					 
					if (value_ < 0.000001 ether || value_ > 1000000 ether)
						revert();

					uint256 fee = 0; 
					uint256 trickle = 0;
					if(holdings[msg.sender] != totalBondSupply){
						fee = fluxFeed(value_, true,true ); 
						trickle = fee/ trickTax;
						fee = fee - trickle;
						tricklingFlo[msg.sender] += trickle;
					}
					
					 
					 
					uint256 res = reserve() - balance;

					 
					uint256 numEther = value_ - (fee+trickle);
					
					 
					uint256 numTokens = calculateDividendTokens(numEther, balance);
					
					buyCalcAndPayout( msg.sender, fee, numTokens, numEther, res );

					addPigment(numTokens,soulR,soulG,soulB);
										
					trickleUp();
					 
					trickleSum += trickle - pocketETH;
					emit onReinvestment(msg.sender,numEther,numTokens);
					if(msg.sender != msg.sender){ 
						 
						if(reff[msg.sender] == 0x0000000000000000000000000000000000000000)
							{reff[msg.sender] = msg.sender;}
							emit onBoughtFor(msg.sender, msg.sender,numEther,numTokens,reff[msg.sender]);
					}
				}
	
	function addPigment(uint256 tokens,uint256 r,uint256 g,uint256 b) internal{
		souleculeR[msg.sender] += tokens * r / 255;
		souleculeG[msg.sender] += tokens * g / 255;
		souleculeB[msg.sender] += tokens * b / 255;
		emit onColor(msg.sender,r,g,b,souleculeR[msg.sender] ,souleculeG[msg.sender] ,souleculeB[msg.sender] );
	}
	 
	function reserve() internal constant returns (uint256 amount){
		return contractBalance()-((uint256) ((int256) (earningsPerBond * totalBondSupply) - totalPayouts ) / scaleFactor);
	}

	 
	 
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff) - totalBondSupply ;
	}

	 
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff) -  totalBondSupply;
	}

	 
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		 
		uint256 reserveAmount = reserve();

		 
		if (tokens == totalBondSupply )
			return reserveAmount;

		 
		 
		 
		 
		return reserveAmount - fixedExp((fixedLog(totalBondSupply  - tokens) - price_coeff) * crr_d/crr_n);
	}

	function () payable public {
		if (msg.value > 0) {
			fund(lastGateway,msg.sender);
		} else {
			withdraw(msg.sender);
		}
	}

										address public resolver = this;
										uint256 public totalSupply;
										uint256 public totalBurned;
									    uint256 constant private MAX_UINT256 = 2**256 - 1;
									    mapping (address => uint256) public balances;
									    mapping (address => uint256) public burned;
									    mapping (address => mapping (address => uint256)) public allowed;
									    
									    string public name = "0xBabylon"; 
									    uint8 public decimals = 18;
									    string public symbol = "PoWHr"; 
									    
									    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
									    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
									    event Resolved(address indexed _owner, uint256 amount);
									    event Burned(address indexed _owner, uint256 amount);

									    function mint(uint256 amount,address _account) internal returns (uint minted){
									    	totalSupply += amount;
									    	balances[_account] += amount;
									    	emit Resolved(_account,amount);
									    	return amount;
									    }

									    function balanceOf(address _owner) public view returns (uint256 balance) {
									        return balances[_owner]-burned[_owner];
									    }
									    
										function burn(uint256 _value) public returns (uint256 amount) {
									        require( balanceOf(msg.sender) >= _value);
									        totalBurned += _value;
									    	burned[msg.sender] += _value;
									    	emit Burned(msg.sender,_value);
									    	return _value;
									    }

										function calcResolve(address _owner,uint256 amount,uint256 _eth) public constant returns (uint256 calculatedResolveTokens) {
											return amount*amount*avgFactor_ethSpent[_owner]/holdings[_owner]/_eth;
										}


									    function transfer(address _to, uint256 _value) public returns (bool success) {
									        require( balanceOf(msg.sender) >= _value);
									        balances[msg.sender] -= _value;
									        balances[_to] += _value;
									        emit Transfer(msg.sender, _to, _value);
									        return true;
									    }
										
									    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
									        uint256 allowance = allowed[_from][msg.sender];
									        require(    balanceOf(_from)  >= _value && allowance >= _value );
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

									    function resolveSupply() public view returns (uint256 balance) {
									        return totalSupply-totalBurned;
									    }

									    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
									        return allowed[_owner][_spender];
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
		int256 z = (s*s) / one;
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
}