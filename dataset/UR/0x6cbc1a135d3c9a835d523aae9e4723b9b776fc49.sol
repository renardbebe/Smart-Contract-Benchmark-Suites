 

pragma solidity ^0.4.11;

 

contract ERC20 {
	 
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	
    function allowance(address _owner, address _spender) constant returns (uint remaining);
	function approve(address _spender, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}


contract Owned {
	 
    address public owner;

	 
    function Owned() {
        owner = msg.sender;
    }
	
	 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

	 
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }  

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
  
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


contract StakePool is ERC20, Owned {
      
    using SafeMath for uint256;

	 
	string public name; 
	string public symbol; 
	uint256 public decimals;  
    uint256 public initialSupply; 
	uint256 public totalSupply; 

     
    uint256 multiplier; 
	
	 
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;

     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;
    }

	 
	function StakePool(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 decimalMultiplier, uint256 initialAmount) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = decimalUnits; 
        multiplier = decimalMultiplier; 
        initialSupply = initialAmount; 
		totalSupply = initialSupply;  
	}
	
	 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

	 
    function approve(address _spender, uint256 _value) returns (bool success) {
        uint256 amount = _value.mul(multiplier); 
        allowed[msg.sender][_spender] = amount;
        Approval(msg.sender, _spender, amount);
        return true;
    }

	 
    function balanceOf(address _owner) constant returns (uint256 remainingBalance) {
        return balance[_owner];
    }

     
	function mintToken(address target, uint256 mintedAmount) onlyOwner returns (bool success) {
        uint256 addTokens = mintedAmount.mul(multiplier); 
		if ((totalSupply + addTokens) < totalSupply) {
			revert(); 
		} else {
			balance[target] += addTokens;
			totalSupply += addTokens;
			Transfer(0, target, addTokens);
			return true; 
		}
	}

	 
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        uint256 amount = _value.mul(multiplier); 
        if (balance[msg.sender] >= amount && balance[_to] + amount > balance[_to]) {
            balance[msg.sender] -= amount;
            balance[_to] += amount;
            Transfer(msg.sender, _to, amount);
            return true;
        } else { 
			return false; 
		}
    }
	
	 
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        uint256 amount = _value.mul(multiplier); 
        if (balance[_from] >= amount && allowed[_from][msg.sender] >= amount && balance[_to] + amount > balance[_to]) {
            balance[_to] += amount;
            balance[_from] -= amount;
            allowed[_from][msg.sender] -= amount;
            Transfer(_from, _to, amount);
            return true;
        } else { 
			return false; 
		}
    }
}


contract StakePoolICO is Owned, StakePool {
     
    using SafeMath for uint256;

     
    address public multiSigWallet;                  
    uint256 public amountRaised; 
    uint256 public dividendPayment;
    uint256 public numberOfRecordEntries; 
    uint256 public numberOfTokenHolders; 
    uint256 public startTime; 
    uint256 public stopTime; 
    uint256 public hardcap; 
    uint256 public price;                            

     
    address[] recordTokenHolders; 
    address[] tokenHolders; 
    bool crowdsaleClosed = true; 
    mapping (address => uint256) recordBalance; 
    mapping (address => uint256) recordTokenHolderID;      
    mapping (address => uint256) tokenHolderID;               
    string tokenName = "StakePool"; 
    string tokenSymbol = "POOL"; 
    uint256 initialTokens = 20000000000000000; 
    uint256 multiplier = 10000000000; 
    uint8 decimalUnits = 8;  

   	 
	function StakePoolICO() 
    	StakePool(tokenName, tokenSymbol, decimalUnits, multiplier, initialTokens) {
            balance[msg.sender] = initialTokens;     
            Transfer(0, msg.sender, initialTokens);    
            multiSigWallet = msg.sender;        
            hardcap = 20100000000000000;    
            setPrice(20); 
            dividendPayment = 50000000000000; 
            recordTokenHolders.length = 2; 
            tokenHolders.length = 2; 
            tokenHolders[1] = msg.sender; 
            numberOfTokenHolders++; 
    }

     
    function () payable {
        require((!crowdsaleClosed) 
            && (now < stopTime) 
            && (totalSupply.add(msg.value.mul(getPrice()).mul(multiplier).div(1 ether)) <= hardcap)); 
        address recipient = msg.sender; 
        amountRaised = amountRaised.add(msg.value.div(1 ether)); 
        uint256 tokens = msg.value.mul(getPrice()).mul(multiplier).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balance[recipient] = balance[recipient].add(tokens);
        require(multiSigWallet.send(msg.value)); 
        Transfer(0, recipient, tokens);
        if (tokenHolderID[recipient] == 0) {
            addTokenHolder(recipient); 
        }
    }   

     
    function addRecordEntry(address account) internal {
        if (recordTokenHolderID[account] == 0) {
            recordTokenHolderID[account] = recordTokenHolders.length; 
            recordTokenHolders.length++; 
            recordTokenHolders[recordTokenHolders.length.sub(1)] = account; 
            numberOfRecordEntries++;
        }
    }

     
    function addTokenHolder(address account) returns (bool success) {
        bool status = false; 
        if (balance[account] != 0) {
            tokenHolderID[account] = tokenHolders.length;
            tokenHolders.length++;
            tokenHolders[tokenHolders.length.sub(1)] = account; 
            numberOfTokenHolders++;
            status = true; 
        }
        return status; 
    }  

     
    function createRecord() internal {
        for (uint i = 0; i < (tokenHolders.length.sub(1)); i++ ) {
            address holder = getTokenHolder(i);
            uint256 holderBal = balanceOf(holder); 
            addRecordEntry(holder); 
            recordBalance[holder] = holderBal; 
        }
    }

     
    function getPrice() returns (uint256 result) {
        return price;
    }

     
    function getRecordBalance(address record) constant returns (uint256) {
        return recordBalance[record]; 
    }

     
    function getRecordHolder(uint256 index) constant returns (address) {
        return address(recordTokenHolders[index.add(1)]); 
    }

     
    function getRemainingTime() constant returns (uint256) {
        return stopTime; 
    }

     
	function getTokenHolder(uint256 index) constant returns (address) {
		return address(tokenHolders[index.add(1)]);
	}

     
    function payOutDividend() onlyOwner returns (bool success) { 
        createRecord(); 
        uint256 volume = totalSupply; 
        for (uint i = 0; i < (tokenHolders.length.sub(1)); i++) {
            address payee = getTokenHolder(i); 
            uint256 stake = volume.div(dividendPayment.div(multiplier));    
            uint256 dividendPayout = balanceOf(payee).div(stake).mul(multiplier); 
            balance[payee] = balance[payee].add(dividendPayout);
            totalSupply = totalSupply.add(dividendPayout); 
            Transfer(0, payee, dividendPayout);
        }
        return true; 
    }

     
    function setMultiSigWallet(address wallet) onlyOwner returns (bool success) {
        multiSigWallet = wallet; 
        return true; 
    }

     
    function setPrice(uint256 newPriceperEther) onlyOwner returns (uint256) {
        require(newPriceperEther > 0); 
        price = newPriceperEther; 
        return price; 
    }

     
    function startSale(uint256 saleStart, uint256 saleStop) onlyOwner returns (bool success) {
        require(saleStop > now);     
        startTime = saleStart; 
        stopTime = saleStop; 
        crowdsaleClosed = false; 
        return true; 
    }

     
    function stopSale() onlyOwner returns (bool success) {
        stopTime = now; 
        crowdsaleClosed = true;
        return true; 
    }

}