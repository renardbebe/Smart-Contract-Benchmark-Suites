 

pragma solidity ^0.4.17;


 
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


 
contract ERC20Basic {
   
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

contract GoldFees is Ownable {
    using SafeMath for uint256;
    
     
     
    uint rateN = 9999452054794520548;
    uint rateD = 19;
    uint public maxDays;
    uint public maxRate;

    
    function GoldFees() public {
        calcMax();
    }

    function calcMax() internal {
        maxDays = 1;
        maxRate = rateN;
        
        
        uint pow = 2;
        do {
            uint newN = rateN ** pow;
            if (newN / maxRate != maxRate) {
                maxDays = pow / 2;
                break;
            }
            maxRate = newN;
            pow *= 2;
        } while (pow < 2000);
        
    }

    function updateRate(uint256 _n, uint256 _d) public onlyOwner {
        rateN = _n;
        rateD = _d;
        calcMax();
    }
    
    function rateForDays(uint256 numDays) public view returns (uint256 rate) {
        if (numDays <= maxDays) {
            uint r = rateN ** numDays;
            uint d = rateD * numDays;
            if (d > 18) {
                uint div = 10 ** (d-18);
                rate = r / div;
            } else {
                div = 10 ** (18 - d);
                rate = r * div;
            }
        } else {
            uint256 md1 = numDays / 2;
            uint256 md2 = numDays - md1;
             uint256 r2;

            uint256 r1 = rateForDays(md1);
            if (md1 == md2) {
                r2 = r1;
            } else {
                r2 = rateForDays(md2);
            }
           

             
             
            rate = r1.mul(r2)/(10**18);
        }
        return; 
        
    }

    uint256 constant public UTC2MYT = 1483200000;

    function wotDay(uint256 time) public pure returns (uint256) {
        return (time - UTC2MYT) / (1 days);
    }

     
    function calcFees(uint256 start, uint256 end, uint256 startAmount) public view returns (uint256 amount, uint256 fee) {
        if (startAmount == 0) 
            return;
        uint256 numberOfDays = wotDay(end) - wotDay(start);
        if (numberOfDays == 0) {
            amount = startAmount;
            return;
        }
        amount = (rateForDays(numberOfDays) * startAmount) / (1 ether);
        if ((fee == 0) && (amount != 0)) 
            amount--;
        fee = startAmount.sub(amount);
    }
}


contract Reclaimable is Ownable {
	ERC20Basic constant internal RECLAIM_ETHER = ERC20Basic(0x0);

	function reclaim(ERC20Basic token)
        public
        onlyOwner
    {
        address reclaimer = msg.sender;
        if (token == RECLAIM_ETHER) {
            reclaimer.transfer(this.balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
    }
}


 
contract GBTBasic {

    struct Balance {
        uint256 amount;                  
        uint256 lastUpdated;             
        uint256 nextAllocationIndex;     
        uint256 allocationShare;         
	}

	 
	mapping (address => Balance) public balances;
	
    struct Allocation { 
        uint256     amount;
        uint256     date;
    }
	
	Allocation[]   public allocationsOverTime;
	Allocation[]   public currentAllocations;

	function currentAllocationLength() view public returns (uint256) {
		return currentAllocations.length;
	}

	function aotLength() view public returns (uint256) {
		return allocationsOverTime.length;
	}
}


contract GoldBackedToken is Ownable, ERC20, Pausable, GBTBasic, Reclaimable {
	using SafeMath for uint;

	function GoldBackedToken(GoldFees feeCalc, GBTBasic _oldToken) public {
		uint delta = 3799997201200178500814753;
		feeCalculator = feeCalc;
        oldToken = _oldToken;
		 
		uint x;
		for (x = 0; x < oldToken.aotLength(); x++) {
			Allocation memory al;
			(al.amount, al.date) = oldToken.allocationsOverTime(x);
			allocationsOverTime.push(al);
		}
		allocationsOverTime[3].amount = allocationsOverTime[3].amount.sub(delta);
		for (x = 0; x < oldToken.currentAllocationLength(); x++) {
			(al.amount, al.date) = oldToken.currentAllocations(x);
			al.amount = al.amount.sub(delta);
			currentAllocations.push(al);
		}

		 
		 
		 
		
		 
		 
		 

		 
		 

		mintedGBT.date = 1515700247;
		mintedGBT.amount = 1529313490861692541644;
	}

  function totalSupply() view public returns (uint256) {
	  uint256 minted;
	  uint256 mFees;
	  uint256 uminted;
	  uint256 umFees;
	  uint256 allocated;
	  uint256 aFees;
	  (minted,mFees) = calcFees(mintedGBT.date,now,mintedGBT.amount);
	  (uminted,umFees) = calcFees(unmintedGBT.date,now,unmintedGBT.amount);
	  (allocated,aFees) = calcFees(currentAllocations[0].date,now,currentAllocations[0].amount);
	  if (minted+allocated>uminted) {
	  	return minted.add(allocated).sub(uminted);
	  } else {
		return 0;
	  }
  }

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event DeductFees(address indexed owner,uint256 amount);

  event TokenMinted(address destination, uint256 amount);
  event TokenBurned(address source, uint256 amount);
  
	string public name = "GOLDX";
	string public symbol = "GOLDX";
	uint256 constant public  decimals = 18;   
	uint256 constant public  hgtDecimals = 8;
		
	uint256 constant public allocationPool = 1 * 10**9 * 10**hgtDecimals;       
	uint256	         public	maxAllocation  = 38 * 10**5 * 10**decimals;			 
	uint256	         public	totAllocation;			 
	
	GoldFees		 public feeCalculator;
	address		     public HGT;					 

	function updateMaxAllocation(uint256 newMax) public onlyOwner {
		require(newMax > 38 * 10**5 * 10**decimals);
		maxAllocation = newMax;
	}

	function setFeeCalculator(GoldFees newFC) public onlyOwner {
		feeCalculator = newFC;
	}

	
	 

	function calcFees(uint256 from, uint256 to, uint256 amount) view public returns (uint256 val, uint256 fee) {
		return feeCalculator.calcFees(from,to,amount);
	}

	
	mapping (address => mapping (address => uint)) public allowance;
    mapping (address => bool) updated;

    GBTBasic oldToken;

	function migrateBalance(address where) public {
		if (!updated[where]) {
            uint256 am;
            uint256 lu;
            uint256 ne;
            uint256 al;
            (am,lu,ne,al) = oldToken.balances(where);
            balances[where] = Balance(am,lu,ne,al);
            updated[where] = true;
        }

	}
	
	function update(address where) internal {
        uint256 pos;
		uint256 fees;
		uint256 val;
		migrateBalance(where);
        (val,fees,pos) = updatedBalance(where);
	    balances[where].nextAllocationIndex = pos;
	    balances[where].amount = val;
        balances[where].lastUpdated = now;
	}
	
	function updatedBalance(address where) view public returns (uint val, uint fees, uint pos) {
		uint256 cVal;
		uint256 cFees;
		uint256 cAmount;

        uint256 am;
        uint256 lu;
        uint256 ne;
        uint256 al;
		Balance memory bb;

		 
        if (updated[where]) {
            bb = balances[where];
            am = bb.amount;
            lu = bb.lastUpdated;
            ne = bb.nextAllocationIndex;
            al = bb.allocationShare;
        } else {
            (am,lu,ne,al) = oldToken.balances(where);
        }
		(val,fees) = calcFees(lu,now,am);
		 
	    pos = ne;
		if ((pos < currentAllocations.length) && (al != 0)) {
			cAmount = currentAllocations[ne].amount.mul(al).div( allocationPool);
			(cVal,cFees) = calcFees(currentAllocations[ne].date,now,cAmount);
		} 
	    val = val.add(cVal);
		fees = fees.add(cFees);
		pos = currentAllocations.length;
	}

    function balanceOf(address where) view public returns (uint256 val) {
        uint256 fees;
		uint256 pos;
        (val,fees,pos) = updatedBalance(where);
        return ;
    }

	event GoldAllocation(uint256 amount, uint256 date);
	event FeeOnAllocation(uint256 fees, uint256 date);

	event PartComplete();
	event StillToGo(uint numLeft);
	uint256 public partPos;
	uint256 public partFees;
	uint256 partL;
	Allocation[]   public partAllocations;

	function partAllocationLength() view public returns (uint) {
		return partAllocations.length;
	}

	function addAllocationPartOne(uint newAllocation,uint numSteps) 
		public 
		onlyMinter 
	{
		require(partPos == 0);
		uint256 thisAllocation = newAllocation;

		require(totAllocation < maxAllocation);		 

		if (currentAllocations.length > partAllocations.length) {
			partAllocations = currentAllocations;
		}

		if (totAllocation + thisAllocation > maxAllocation) {
			thisAllocation = maxAllocation.sub(totAllocation);
			log0("max alloc reached");
		}
		totAllocation = totAllocation.add(thisAllocation);

		GoldAllocation(thisAllocation,now);

        Allocation memory newDiv;
        newDiv.amount = thisAllocation;
        newDiv.date = now;
		 
	    allocationsOverTime.push(newDiv);
		 
		partL = partAllocations.push(newDiv);
		 
		if (partAllocations.length < 2) {  
			PartComplete();
			currentAllocations = partAllocations;
			FeeOnAllocation(0,now);
			return;
		}
		 
		 
		 
		 
		for (partPos = partAllocations.length - 2; partPos >= 0; partPos-- ) {
			(partAllocations[partPos].amount,partFees) = calcFees(partAllocations[partPos].date,now,partAllocations[partPos].amount);

			partAllocations[partPos].amount = partAllocations[partPos].amount.add(partAllocations[partL - 1].amount);
			partAllocations[partPos].date = now;
			if ((partPos == 0) || (partPos == partAllocations.length-numSteps)) {
				break; 
			}
		}
		if (partPos != 0) {
			StillToGo(partPos);
			return;  
		}
		PartComplete();
		FeeOnAllocation(partFees,now);
		currentAllocations = partAllocations;
	}

	function addAllocationPartTwo(uint numSteps) 
		public 
		onlyMinter 
	{
		require(numSteps > 0);
		require(partPos > 0);
		for (uint i = 0; i < numSteps; i++ ) {
			partPos--;
			(partAllocations[partPos].amount,partFees) = calcFees(partAllocations[partPos].date,now,partAllocations[partPos].amount);
			partAllocations[partPos].amount = partAllocations[partPos].amount.add(partAllocations[partL - 1].amount);
			partAllocations[partPos].date = now;
			if (partPos == 0) {
				break; 
			}
		}
		if (partPos != 0) {
			StillToGo(partPos);
			return;  
		}
		PartComplete();
		FeeOnAllocation(partFees,now);
		currentAllocations = partAllocations;
	}

	function setHGT(address _hgt) public onlyOwner {
		HGT = _hgt;
	}

	function parentFees(address where) public whenNotPaused {
		require(msg.sender == HGT);
	    update(where);		
	}
	
	function parentChange(address where, uint newValue) public whenNotPaused {  
		require(msg.sender == HGT);
	    balances[where].allocationShare = newValue;
	}
	
	 
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool ok) {
		require(_to != address(0));
	    update(msg.sender);               
		update(_to); 

        balances[msg.sender].amount = balances[msg.sender].amount.sub(_value);
        balances[_to].amount = balances[_to].amount.add(_value);
		Transfer(msg.sender, _to, _value);  
        return true;
	}

	function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool success) {
		require(_to != address(0));
		var _allowance = allowance[_from][msg.sender];

	    update(_from);               
		update(_to); 

		balances[_to].amount = balances[_to].amount.add(_value);
		balances[_from].amount = balances[_from].amount.sub(_value);
		allowance[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

  	function approve(address _spender, uint _value) public whenNotPaused returns (bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
    	allowance[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
  	}

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowance[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowance[msg.sender][_spender] = 0;
    } else {
      allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }

  	function allowance(address _owner, address _spender) public view returns (uint remaining) {
    	return allowance[_owner][_spender];
  	}

	 
	address public authorisedMinter;

	function setMinter(address minter) public onlyOwner {
		authorisedMinter = minter;
	}

	modifier onlyMinter() {
		require(msg.sender == authorisedMinter);
		_;
	}

	Allocation public mintedGBT;		 
	Allocation public unmintedGBT;		 
	
	function mintTokens(address destination, uint256 amount) 
		onlyMinter
		public 
	{
		require(msg.sender == authorisedMinter);
		update(destination);
		balances[destination].amount = balances[destination].amount.add(amount);
		TokenMinted(destination,amount);
		Transfer(0x0,destination,amount);  
		 
		 
		 
		uint256 fees;
		(mintedGBT.amount,fees) = calcFees(mintedGBT.date,now,mintedGBT.amount);
		mintedGBT.amount = mintedGBT.amount.add(amount);
		mintedGBT.date = now;
	}

	function burnTokens(address source, uint256 amount) 
		onlyMinter
		public 
	{
		update(source);
		balances[source].amount = balances[source].amount.sub(amount);
		TokenBurned(source,amount);
		Transfer(source,0x0,amount);  
		 
		 
		 
		uint256 fees;
		(unmintedGBT.amount,fees) = calcFees(unmintedGBT.date,now,unmintedGBT.amount);
		unmintedGBT.date = now;
		unmintedGBT.amount = unmintedGBT.amount.add(amount);
	}

}