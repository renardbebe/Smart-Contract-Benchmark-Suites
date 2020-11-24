 

pragma solidity ^0.4.11;


 
library SafeMath {
	function mul(uint a, uint b) internal returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function safeSub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function div(uint a, uint b) internal returns (uint) {
		assert(b > 0);
		uint c = a / b;
		assert(a == b * c + a % b);
		return c;
	}
	function sub(uint a, uint b) internal returns (uint) {
		assert(b <= a);
		return a - b;
	}
	function add(uint a, uint b) internal returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}
	function max64(uint64 a, uint64 b) internal constant returns (uint64) {
		return a >= b ? a : b;
	}
	function min64(uint64 a, uint64 b) internal constant returns (uint64) {
		return a < b ? a : b;
	}
	function max256(uint256 a, uint256 b) internal constant returns (uint256) {
		return a >= b ? a : b;
	}
	function min256(uint256 a, uint256 b) internal constant returns (uint256) {
		return a < b ? a : b;
	}
	function assert(bool assertion) internal {
		if (!assertion) {
			throw;
		}
	}
}


 
contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


 
contract Pausable is Ownable {
	bool public stopped;
	modifier stopInEmergency {
		if (stopped) {
			throw;
		}
		_;
	}

	modifier onlyInEmergency {
		if (!stopped) {
		  throw;
		}
	_;
	}
	 
	function emergencyStop() external onlyOwner {
		stopped = true;
	}
	 
	function release() external onlyOwner onlyInEmergency {
		stopped = false;
	}
}



 
contract PullPayment {
	using SafeMath for uint;

	mapping(address => uint) public payments;
	event LogRefundETH(address to, uint value);
	 
	function asyncSend(address dest, uint amount) internal {
		payments[dest] = payments[dest].add(amount);
	}
	 
	function withdrawPayments() {
		address payee = msg.sender;
		uint payment = payments[payee];

		if (payment == 0) {
			throw;
		}
		if (this.balance < payment) {
		    throw;
		}
		payments[payee] = 0;
		if (!payee.send(payment)) {
		    throw;
		}
		LogRefundETH(payee,payment);
	}
}



 
contract ERC20Basic {
	uint public totalSupply;
	function balanceOf(address who) constant returns (uint);
	function transfer(address to, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) constant returns (uint);
	function transferFrom(address from, address to, uint value);
	function approve(address spender, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract BasicToken is ERC20Basic {
  
	using SafeMath for uint;

	mapping(address => uint) balances;

	 
	modifier onlyPayloadSize(uint size) {
	   if(msg.data.length < size + 4) {
	     throw;
	   }
	 _;
	}
	function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
	}
	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}
}


 
contract StandardToken is BasicToken, ERC20 {
	mapping (address => mapping (address => uint)) allowed;
	function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
		var _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
    }
	function approve(address _spender, uint _value) {
		if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}
	function allowance(address _owner, address _spender) constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}
}


 
contract ClusterToken is StandardToken, PullPayment, Ownable, Pausable {
	
  using SafeMath for uint;
  
  struct Backer {
        address buyer;
        uint contribution;
        uint withdrawnAtSegment;
        uint withdrawnAtCluster;
        bool state;
    }
    
     
    string public constant name = "ClusterToken";
    string public constant symbol = "CLRT";
    uint256 public constant decimals = 18;
    uint256 private buyPriceEth = 10000000000000000;
    
    uint256 public initialBlockCount;
    uint256 private testBlockEnd;
    uint256 public contributors;
    
    uint256 private minedBlocks;
    uint256 private ClusterCurrent;
    uint256 private SegmentCurrent;
    uint256 private UnitCurrent;
  
  
    mapping(address => Backer) public backers;
    
   
      
    function ClusterToken() {
    totalSupply = 750000000000000000000;
    balances[msg.sender] = totalSupply;
    
    initialBlockCount = 4086356;

    contributors = 0;
    }
    
    
      
    function currentCluster() constant returns (uint256 currentCluster)
    {
    	uint blockCount = block.number - initialBlockCount;
    	uint result = blockCount.div(1000000);
    	return result;
    }
    
    
      
    function currentSegment() constant returns (uint256 currentSegment)
    {
    	uint blockCount = block.number - initialBlockCount;
    	uint newSegment = currentCluster().mul(1000);
    	uint result = blockCount.div(1000).sub(newSegment);

    	return result;
    }
    
    
      
    function currentUnit() constant returns (uint256 currentUnit)
    {
    	uint blockCount = block.number - initialBlockCount;
    	uint getClusters = currentCluster().mul(1000000);
        uint newUnit = currentSegment().mul(1000);
    	return blockCount.sub(getClusters).sub(newUnit);      
    	
    }
    
    
      
    function currentBlock() constant returns (uint256 blockNumber)
    {
    	return block.number - initialBlockCount;
    }



      
    function buyClusterToken() payable returns (uint amount) {
        
        if (balances[this] < amount) throw;                          
        amount = msg.value.mul(buyPriceEth).div(1 ether);
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        
        Backer backer = backers[msg.sender];
        backer.contribution = backer.contribution.add(amount);
        backer.withdrawnAtSegment = backer.withdrawnAtSegment.add(0);
        backer.withdrawnAtCluster = backer.withdrawnAtCluster.add(0);
        backer.state = backer.state = true;
        
        contributors++;
        
        return amount;
    }
    
    
     
    function claimClusters() public returns (uint amount) {
        
        if (currentSegment() == 0) throw;
        if (!backers[msg.sender].state) throw; 
        
        uint previousWithdraws = backers[msg.sender].withdrawnAtCluster;
        uint entitledToClusters = currentCluster().sub(previousWithdraws);
        
        if (entitledToClusters == 0) throw;
        if (!isEntitledForCluster(msg.sender)) throw;
        
        uint userShares = backers[msg.sender].contribution.div(1 finney);
        uint amountForPayout = buyPriceEth.div(contributors);
        
        amount =  amountForPayout.mul(userShares).mul(1000);                           
        
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        
        backers[msg.sender].withdrawnAtCluster = currentCluster(); 
        
        return amount;
    }
    
    
     
    function claimSegments() public returns (uint amount) {
        
        if (currentSegment() == 0) throw;
        if (!backers[msg.sender].state) throw;  
        
        
        uint previousWithdraws = currentCluster().add(backers[msg.sender].withdrawnAtSegment);
        uint entitledToSegments = currentCluster().add(currentSegment().sub(previousWithdraws));
        
        if (entitledToSegments == 0 ) throw;
        
        uint userShares = backers[msg.sender].contribution.div(1 finney);
        uint amountForPayout = buyPriceEth.div(contributors);
        
        amount =  amountForPayout.mul(userShares).div(10).div(2);                           
        
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        
        backers[msg.sender].withdrawnAtSegment = currentSegment(); 
        
        return amount;
    }

    
      
    function() payable {
        if (msg.sender != owner) {
            buyClusterToken();
        }
    }
    
    
      
    function Drain() onlyOwner public {
        if(this.balance > 0) {
            if (!owner.send(this.balance)) throw;
        }
    }
    
    
    
     
    function burn(uint _value) onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        return true;
    }
    
    
      
    function isEntitledForCluster(address _sender) private constant returns (bool) {
        
        uint t1 = currentCluster().mul(1000).add(currentSegment()); 
        uint t2 = backers[_sender].withdrawnAtSegment;      

        if (t1.sub(t2) >= 1000) { return true; }
        return false;
        
    }
    
}