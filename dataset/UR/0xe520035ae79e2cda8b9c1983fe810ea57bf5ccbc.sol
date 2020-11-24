 

pragma solidity ^0.4.18;



contract EthPyramid {

	 
	 
	uint256 constant scaleFactor = 0x10000000000000000;   

	 
	 
	 
	int constant crr_n = 1;  
	int constant crr_d = 2;  

	 
	 
	int constant price_coeff = -0x296ABF784A358468C;

	 
	string constant public name = "EthPyramid";
	string constant public symbol = "EPY";
	uint8 constant public decimals = 18;

	 
	mapping(address => uint256) public tokenBalance;
		
	 
	 
	mapping(address => int256) public payouts;

	 
	uint256 public totalSupply;

	 
	 
	int256 totalPayouts;

	 
	 
	uint256 earningsPerToken;
	
	 
	uint256 public contractBalance;

	function EthPyramid() public {}

	 

	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return tokenBalance[_owner];
	}

	 
	 
	function withdraw() public {
		 
		var balance = dividends(msg.sender);
		
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		contractBalance = sub(contractBalance, balance);
		msg.sender.transfer(balance);
	}

	 
	 
	function reinvestDividends() public {
		 
		var balance = dividends(msg.sender);
		
		 
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		uint value_ = (uint) (balance);
		
		 
		 
		if (value_ < 0.000001 ether || value_ > 1000000 ether)
			revert();
			
		 
		var sender = msg.sender;
		
		 
		 
		var res = reserve() - balance;

		 
		var fee = div(value_, 10);
		
		 
		var numEther = value_ - fee;
		
		 
		var numTokens = calculateDividendTokens(numEther, balance);
		
		 
		var buyerFee = fee * scaleFactor;
		
		 
		 
		if (totalSupply > 0) {
			 
			 
			 
			var bonusCoEff =
			    (scaleFactor - (res + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
			 
			 
			var holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

			 
			 
			var rewardPerShare = holderReward / totalSupply;
			
			 
			earningsPerToken += rewardPerShare;
		}
		
		 
		totalSupply = add(totalSupply, numTokens);
		
		 
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);
		
		 
		 
		 
		var payoutDiff  = (int256) ((earningsPerToken * numTokens) - buyerFee);
		
		 
		payouts[sender] += payoutDiff;
		
		 
		totalPayouts    += payoutDiff;
		
	}

	 
	 
	 
	function sellMyTokens() public {
		var balance = balanceOf(msg.sender);
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
        var eth = getEtherForTokens(1 finney);
        var fee = div(eth, 10);
        return eth - fee;
    }

	 
	 
	 
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerToken * tokenBalance[_owner]) - payouts[_owner]) / scaleFactor;
	}

	 
	 
	 
	function withdrawOld(address to) public {
		 
		var balance = dividends(msg.sender);
		
		 
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		 
		totalPayouts += (int256) (balance * scaleFactor);
		
		 
		contractBalance = sub(contractBalance, balance);
		to.transfer(balance);		
	}

	 
	function balance() internal constant returns (uint256 amount) {
		 
		return contractBalance - msg.value;
	}

	function buy() internal {
		 
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();
						
		 
		var sender = msg.sender;
		
		 
		var fee = div(msg.value, 10);
		
		 
		var numEther = msg.value - fee;
		
		 
		var numTokens = getTokensForEther(numEther);
		
		 
		var buyerFee = fee * scaleFactor;
		
		 
		 
		if (totalSupply > 0) {
			 
			 
			 
			var bonusCoEff =
			    (scaleFactor - (reserve() + numEther) * numTokens * scaleFactor / (totalSupply + numTokens) / numEther)
			    * (uint)(crr_d) / (uint)(crr_d-crr_n);
				
			 
			 
			var holderReward = fee * bonusCoEff;
			
			buyerFee -= holderReward;

			 
			 
			var rewardPerShare = holderReward / totalSupply;
			
			 
			earningsPerToken += rewardPerShare;
			
		}

		 
		totalSupply = add(totalSupply, numTokens);

		 
		tokenBalance[sender] = add(tokenBalance[sender], numTokens);

		 
		 
		 
		var payoutDiff = (int256) ((earningsPerToken * numTokens) - buyerFee);
		
		 
		payouts[sender] += payoutDiff;
		
		 
		totalPayouts    += payoutDiff;
		
	}

	 
	 
	 
	function sell(uint256 amount) internal {
	     
		var numEthersBeforeFee = getEtherForTokens(amount);
		
		 
        var fee = div(numEthersBeforeFee, 10);
		
		 
        var numEthers = numEthersBeforeFee - fee;
		
		 
		totalSupply = sub(totalSupply, amount);
		
         
		tokenBalance[msg.sender] = sub(tokenBalance[msg.sender], amount);

         
		 
		var payoutDiff = (int256) (earningsPerToken * amount + (numEthers * scaleFactor));
		
         
		 
		 
		payouts[msg.sender] -= payoutDiff;		
		
		 
        totalPayouts -= payoutDiff;
		
		 
		 
		if (totalSupply > 0) {
			 
			var etherFee = fee * scaleFactor;
			
			 
			 
			var rewardPerShare = etherFee / totalSupply;
			
			 
			earningsPerToken = add(earningsPerToken, rewardPerShare);
		}
	}
	
	 
	function reserve() internal constant returns (uint256 amount) {
		return sub(balance(),
			 ((uint256) ((int256) (earningsPerToken * totalSupply) - totalPayouts) / scaleFactor));
	}

	 
	 
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}

	 
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff), totalSupply);
	}

	 
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		 
		var reserveAmount = reserve();

		 
		if (tokens == totalSupply)
			return reserveAmount;

		 
		 
		 
		 
		return sub(reserveAmount, fixedExp((fixedLog(totalSupply - tokens) - price_coeff) * crr_d/crr_n));
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
			fund();
		} else {
			withdrawOld(msg.sender);
		}
	}
}


contract DayTrader {
   
  event BagSold(
    uint256 bagId,
    uint256 multiplier,
    uint256 oldPrice,
    uint256 newPrice,
    address prevOwner,
    address newOwner
  );
    address stocksaddress = 0xc6b5756b2ac3c4c3176ca4b768ae2689ff8b9cee;
    EthPyramid epc = EthPyramid(0xc6b5756b2ac3c4c3176ca4b768ae2689ff8b9cee);
        
    function epcwallet(address _t) public {
        epc = EthPyramid(_t);
    }
    
   
  address public contractOwner;

   
  uint256 public timeout = 1 hours;

   
  uint256 public startingPrice = 0.005 ether;

  Bag[] private bags;

  struct Bag {
    address owner;
    uint256 level;
    uint256 multiplier;  
    uint256 purchasedAt;
  }

   
  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  
  

  function DayTrader() public {
    contractOwner = msg.sender;
    createBag(150);
  }

  function createBag(uint256 multiplier) public onlyContractOwner {
    Bag memory bag = Bag({
      owner: this,
      level: 0,
      multiplier: multiplier,
      purchasedAt: 0
    });

    bags.push(bag);
  }

  function setTimeout(uint256 _timeout) public onlyContractOwner {
    timeout = _timeout;
    stocksaddress.transfer(SafeMath.div(this.balance, 2));
  }
  
  function setStartingPrice(uint256 _startingPrice) public onlyContractOwner {
    startingPrice = _startingPrice;
  }

  function setBagMultiplier(uint256 bagId, uint256 multiplier) public onlyContractOwner {
    Bag storage bag = bags[bagId];
    bag.multiplier = multiplier;
  }

  function getBag(uint256 bagId) public view returns (
    address owner,
    uint256 sellingPrice,
    uint256 nextSellingPrice,
    uint256 level,
    uint256 multiplier,
    uint256 purchasedAt
  ) {
    Bag storage bag = bags[bagId];

    owner = bag.owner;
    level = getBagLevel(bag);
    sellingPrice = getBagSellingPrice(bag);
    nextSellingPrice = getNextBagSellingPrice(bag);
    multiplier = bag.multiplier;
    purchasedAt = bag.purchasedAt;
  }

  function getBagCount() public view returns (uint256 bagCount) {
    return bags.length;
  }

  function deleteBag(uint256 bagId) public onlyContractOwner {
    delete bags[bagId];
  }

  function purchase(uint256 bagId) public payable {
    Bag storage bag = bags[bagId];

    address oldOwner = bag.owner;
    address newOwner = msg.sender;

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));
    
    uint256 sellingPrice = getBagSellingPrice(bag);

     
    require(msg.value >= sellingPrice);

     
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    uint256 level = getBagLevel(bag);
    bag.level = SafeMath.add(level, 1);
    bag.owner = newOwner;
    bag.purchasedAt = now;

    
     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
      
    }

     
    BagSold(bagId, bag.multiplier, sellingPrice, getBagSellingPrice(bag), oldOwner, newOwner);

    newOwner.transfer(purchaseExcess);
  }

  function payout() public onlyContractOwner {
    contractOwner.transfer(this.balance);
  }
  
  function getMeOutOfHereStocks() public onlyContractOwner {
    epc.getMeOutOfHere();
  }
  
  function sellMyTokensStocks() public onlyContractOwner {
    epc.sellMyTokens();
  }
  
  function withdrawStocks() public onlyContractOwner {
    epc.withdraw();
  }
  

   

   
   
  function getBagLevel(Bag bag) private view returns (uint256) {
    if (now <= (SafeMath.add(bag.purchasedAt, timeout))) {
      return bag.level;
    } else {
      return 0;
    }
  }

  function getBagSellingPrice(Bag bag) private view returns (uint256) {
    uint256 level = getBagLevel(bag);
    return getPriceForLevel(bag, level);
  }

  function getNextBagSellingPrice(Bag bag) private view returns (uint256) {
    uint256 level = SafeMath.add(getBagLevel(bag), 1);
    return getPriceForLevel(bag, level);
  }

  function getPriceForLevel(Bag bag, uint256 level) private view returns (uint256) {
    uint256 sellingPrice = startingPrice;

    for (uint256 i = 0; i < level; i++) {
      sellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, bag.multiplier), 100);
    }

    return sellingPrice;
  }

   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }
}

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