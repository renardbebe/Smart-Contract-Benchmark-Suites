 

pragma solidity ^0.4.19;

 

contract OurRoulette{
    struct Bet{
        uint value;
        uint height;  
        uint tier;  
        bytes betdata;
    }
    mapping (address => Bet) bets;
    
     
    function GroupMultiplier(uint number,uint groupID) public pure returns(uint){
        uint80[12] memory groups=[  
            0x30c30c30c30c30c30c0,  
            0x0c30c30c30c30c30c30,  
            0x030c30c30c30c30c30c,  
            0x0000000000003fffffc,  
            0x0000003fffffc000000,  
            0x3fffffc000000000000,  
            0x0000000002aaaaaaaa8,  
            0x2222222222222222220,  
            0x222208888a222088888,  
            0x0888a22220888a22220,  
            0x0888888888888888888,  
            0x2aaaaaaaa8000000000   
        ];
        return (groups[groupID]>>(number*2))&3;  
    }
    
     
    function GetNumber(address adr,uint height) public view returns(uint){
        bytes32 hash1=block.blockhash(height+1);
        bytes32 hash2=block.blockhash(height+2);
        if(hash1==0 || hash2==0)return 69; 
        return ((uint)(keccak256(adr,hash1,hash2)))%37;
    }
    
     
    function BetPayout() public view returns (uint payout) {
        Bet memory tmp = bets[msg.sender];
        
        uint n=GetNumber(msg.sender,tmp.height);
        if(n==69)return 0;  
        
        payout=((uint)(tmp.betdata[n]))*36;  
        for(uint i=37;i<49;i++)payout+=((uint)(tmp.betdata[i]))*GroupMultiplier(n,i-37);  
        
        return payout*tmp.tier;
    }
    
     
    function PlaceBet(uint tier,bytes betdata) public payable {
        Bet memory tmp = bets[msg.sender];
        uint balance=msg.value;  
        require(tier<(realReserve()/12500));  
        
        require((tmp.height+2)<=(block.number-1));  
        if(tmp.height!=0&&((block.number-1)>=(tmp.height+2))){  
            uint win=BetPayout();
            
            if(win>0&&tmp.tier>(realReserve()/12500)){
                 
                 
                
                 
                 
                
                if(realReserve()>=tmp.value){
                    bets[msg.sender].height=0;  
                    contractBalance-=tmp.value;
                    SubFromDividends(tmp.value);
                    msg.sender.transfer(tmp.value+balance);  
                }else msg.sender.transfer(balance);  
                                                     
                                                     

                return;  
            }
            
            balance+=win;  
        }
        
        uint betsz=0;
        for(uint i=0;i<49;i++)betsz+=(uint)(betdata[i]);
        require(betsz<=50);  
        
        betsz*=tier;  
        require(betsz<=balance);  
        
        tmp.height=block.number;  
        tmp.value=betsz;
        tmp.tier=tier;
        tmp.betdata=betdata;
        
        bets[msg.sender]=tmp;  
        
        balance-=betsz;  
        
        if(balance>0){
            contractBalance-=balance;
            if(balance>=msg.value){
                contractBalance-=(balance-msg.value);
                SubFromDividends(balance-msg.value);
            }else{
                contractBalance+=(msg.value-balance);
                AddToDividends(msg.value-balance);
            }

            msg.sender.transfer(balance);  
        }else{
            contractBalance+=msg.value;
            AddToDividends(msg.value);
        }
    }
    
     
    function AddToDividends(uint256 value) internal {
        earningsPerToken+=(int256)((value*scaleFactor)/totalSupply);
    }
    
     
    function SubFromDividends(uint256 value)internal {
        earningsPerToken-=(int256)((value*scaleFactor)/totalSupply);
    }
    
     
    function ClaimMyBet() public{
        Bet memory tmp = bets[msg.sender];
        require((tmp.height+2)<=(block.number-1));  
        
        uint win=BetPayout();
        
        if(win>0){
            if(bets[msg.sender].tier>(realReserve()/12500)){
                 
                 
                
                 
                 
                
                if(realReserve()>=tmp.value){
                    bets[msg.sender].height=0;  
                    contractBalance-=tmp.value;
                    SubFromDividends(tmp.value);
                    msg.sender.transfer(tmp.value);
                }
                
                 
                 
                return;
            }
            
            bets[msg.sender].height=0;  
            contractBalance-=win;
            SubFromDividends(win);
            msg.sender.transfer(win);
        }
    }
    
     
    function GetMyBet() public view returns(uint, uint, uint, uint, bytes){
        return (bets[msg.sender].value,bets[msg.sender].height,bets[msg.sender].tier,BetPayout(),bets[msg.sender].betdata);
    }
    
 

 
    
     
	 
	uint256 constant scaleFactor = 0x10000000000000000;   

	 
	 
	 
	int constant crr_n = 1;  
	int constant crr_d = 2;  

	 
	 
	int constant price_coeff = -0x296ABF784A358468C;

	 
	mapping(address => uint256) public tokenBalance;
		
	 
	 
	mapping(address => int256) public payouts;

	 
	uint256 public totalSupply;

	 
	 
	int256 totalPayouts;

	 
	 
	int256 earningsPerToken;
	
	 
	uint256 public contractBalance;

	 

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return tokenBalance[_owner];
	}

	 
	 
	function withdraw() public {
		 
		uint256 balance = dividends(msg.sender);
		
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		contractBalance = sub(contractBalance, balance);
		msg.sender.transfer(balance);
	}

	 
	 
	function reinvestDividends() public {
		 
		uint256 balance = dividends(msg.sender);
		
		 
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		uint value_ = (uint) (balance);
		
		 
		 
		if (value_ < 0.000001 ether || value_ > 1000000 ether)
			revert();
			
		 
		address sender = msg.sender;
		
		 
		 
		uint256 res = reserve() - balance;

		 
		uint256 fee = div(value_, 10);
		
		 
		uint256 numEther = value_ - fee;
		
		 
		uint256 numTokens = calculateDividendTokens(numEther, balance);
		
		 
		uint256 buyerFee = fee * scaleFactor;
		
		 
		 
		if (totalSupply > 0) {
			 
			 
			 
			uint256 bonusCoEff =
			    (scaleFactor - (res + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
			 
			 
			uint256 holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

			 
			 
			uint256 rewardPerShare = holderReward / totalSupply;
			
			 
			earningsPerToken += (int256)(rewardPerShare);
		}
		
		 
		totalSupply = add(totalSupply, numTokens);
		
		 
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);
		
		 
		 
		 
		int256 payoutDiff  = ((earningsPerToken * (int256)(numTokens)) - (int256)(buyerFee));
		
		 
		payouts[sender] += payoutDiff;
		
		 
		totalPayouts    += payoutDiff;
		
	}

	 
	 
	 
	function sellMyTokens() public {
		uint256 balance = balanceOf(msg.sender);
		sell(balance);
	}

	 
	 
    function getMeOutOfHere() public {
		sellMyTokens();
        withdraw();
	}

	 
	 
	function fund() payable public {
		 
		if (msg.value > 0.000001 ether) {
		    contractBalance = add(contractBalance, msg.value);
			buy();
		} else {
			revert();
		}
    }

	 
	function buyPrice() public constant returns (uint) {
		return getTokensForEther(1 finney);
	}

	 
	function sellPrice() public constant returns (uint) {
        uint256 eth;
        uint256 penalty;
        (eth,penalty) = getEtherForTokens(1 finney);
        
        uint256 fee = div(eth, 10);
        return eth - fee;
    }

	 
	 
	 
	function dividends(address _owner) public constant returns (uint256 amount) {
	    int256 r=((earningsPerToken * (int256)(tokenBalance[_owner])) - payouts[_owner]) / (int256)(scaleFactor);
	    if(r<0)return 0;
		return (uint256)(r);
	}
	
	 
	function realDividends(address _owner) public constant returns (int256 amount) {
	    return (((earningsPerToken * (int256)(tokenBalance[_owner])) - payouts[_owner]) / (int256)(scaleFactor));
	}

	 
	function balance() internal constant returns (uint256 amount) {
		 
		return contractBalance - msg.value;
	}

	function buy() internal {
		 
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();
						
		 
		address sender = msg.sender;
		
		 
		uint256 fee = div(msg.value, 10);
		
		 
		uint256 numEther = msg.value - fee;
		
		 
		uint256 numTokens = getTokensForEther(numEther);
		
		 
		uint256 buyerFee = fee * scaleFactor;
		
		 
		 
		if (totalSupply > 0) {
			 
			 
			 
			uint256 bonusCoEff =
			    (scaleFactor - (reserve() + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
			 
			 
			uint256 holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

			 
			 
			uint256 rewardPerShare = holderReward / totalSupply;
			
			 
			earningsPerToken += (int256)(rewardPerShare);
			
		}

		 
		totalSupply = add(totalSupply, numTokens);

		 
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);

		 
		 
		 
		int256 payoutDiff = ((earningsPerToken * (int256)(numTokens)) - (int256)(buyerFee));
		
		 
		payouts[sender] += payoutDiff;
		
		 
		totalPayouts    += payoutDiff;
		
	}

	 
	 
	 
	function sell(uint256 amount) internal {
	     
		uint256 numEthersBeforeFee;
		uint256 penalty;
		(numEthersBeforeFee,penalty) = getEtherForTokens(amount);
		
		 
		uint256 fee = 0;
		if(amount!=totalSupply) fee = div(numEthersBeforeFee, 10);
		
		 
        uint256 numEthers = numEthersBeforeFee - fee;
		
		 
		totalSupply = sub(totalSupply, amount);
		
         
		tokenBalance[msg.sender] = sub(tokenBalance[msg.sender], amount);

         
		 
		int256 payoutDiff = (earningsPerToken * (int256)(amount) + (int256)(numEthers * scaleFactor));
		
         
		 
		 
		payouts[msg.sender] -= payoutDiff;
		
		 
        totalPayouts -= payoutDiff;
		
		 
		 
		if (totalSupply > 0) {
			 
			uint256 etherFee = fee * scaleFactor;
			
			if(penalty>0)etherFee += (penalty * scaleFactor);  
			
			 
			 
			uint256 rewardPerShare = etherFee / totalSupply;
			
			 
			earningsPerToken += (int256)(rewardPerShare);
		}else payouts[msg.sender]+=(int256)(penalty);  
		
		int256 afterdiv=realDividends(msg.sender);  
		if(afterdiv<0){
		      
		      
		     SubFromDividends((uint256)(afterdiv*-1));
		     totalPayouts -= payouts[msg.sender];
		     payouts[msg.sender]=0;
		      
		      
		      
		}
	}
	
	 
	function totalDiv() public view returns (int256){
	    return ((earningsPerToken * (int256)(totalSupply))-totalPayouts)/(int256)(scaleFactor);
	}
	
	 
	function reserve() internal constant returns (uint256 amount) {
	    int256 divs=totalDiv();
	    
	    if(divs<0)return balance()+(uint256)(divs*-1);
	    return balance()-(uint256)(divs);
	}
	
	 
	function realReserve() public view returns (uint256 amount) {
	    int256 divs=totalDiv();
	    
	    if(divs<0){
	        uint256 udivs=(uint256)(divs*-1);
	        uint256 b=balance();
	        if(b<udivs)return 0;
	        return b-udivs;
	    }
	    return balance()-(uint256)(divs);
	}

	 
	 
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}

	 
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}
	
	 
	function getEtherForTokensOld(uint256 tokens) public constant returns (uint256 ethervalue) {
		 
		uint256 reserveAmount = reserve();

		 
		if (tokens == totalSupply)
			return reserveAmount;

		 
		 
		 
		 
		return sub(reserveAmount, fixedExp((fixedLog(totalSupply - tokens) - price_coeff) * crr_d/crr_n));
	}

	 
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue,uint256 penalty) {
		uint256 eth=getEtherForTokensOld(tokens);
		int256 divs=totalDiv();
		if(divs>=0)return (eth,0);
		
		uint256 debt=(uint256)(divs*-1);
		penalty=(((debt*scaleFactor)/totalSupply)*tokens)/scaleFactor;
		
		if(penalty>eth)return (0,penalty);
		return (eth-penalty,penalty);
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
			fund();
		} else {
			getMeOutOfHere();
		}
	}
}