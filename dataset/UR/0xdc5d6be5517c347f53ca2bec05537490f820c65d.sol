 

pragma solidity ^0.4.19;

 

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



 
contract Moderated {
    
    address public moderator;
    
    bool public unrestricted;
    
    modifier onlyModerator {
        require(msg.sender == moderator);
        _;
    }
    
    modifier ifUnrestricted {
        require(unrestricted);
        _;
    }
    
    modifier onlyPayloadSize(uint256 numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }    
    
    function Moderated() public {
        moderator = msg.sender;
        unrestricted = true;
    }
    
    function reassignModerator(address newModerator) public onlyModerator {
        moderator = newModerator;
    }
    
    function restrict() public onlyModerator {
        unrestricted = false;
    }
    
    function unrestrict() public onlyModerator {
        unrestricted = true;
    }  
    
     
     
    function extract(address _token) public returns (bool) {
        require(_token != address(0x0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        return token.transfer(moderator, balance);
    }
    
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return (size > 0);
    }  
    
    function getModerator() public view returns (address) {
        return moderator;
    }
} 

 
contract Token { 

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);    
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);    
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);    

}







 

contract LEON is Moderated {	
	using SafeMath for uint256;

		string public name = "LEONS Coin";	
		string public symbol = "LEONS";			
		uint8 public decimals = 18;
		
		mapping(address => uint256) internal balances;
		mapping (address => mapping (address => uint256)) internal allowed;

		uint256 internal totalSupply_;

		 
		uint256 public constant maximumTokenIssue = 200000000 * 10**18;
		
		event Approval(address indexed owner, address indexed spender, uint256 value); 
		event Transfer(address indexed from, address indexed to, uint256 value);		

		 
		function totalSupply() public view returns (uint256) {
			return totalSupply_;
		}

		 
		function transfer(address _to, uint256 _value) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
		    return _transfer(msg.sender, _to, _value);
		}

		 
		function transferFrom(address _from, address _to, uint256 _value) public ifUnrestricted onlyPayloadSize(3) returns (bool) {
		    require(_value <= allowed[_from][msg.sender]);
		    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		    return _transfer(_from, _to, _value);
		}		

		function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
			 
			require(_to != address(0x0) && _to != address(this));
			 
			require(_value <= balances[_from]);
			 
			balances[_from] = balances[_from].sub(_value);	
			 
			balances[_to] = balances[_to].add(_value);		
			 
			Transfer(_from, _to, _value);
			return true;
		}

		 
		function balanceOf(address _owner) public view returns (uint256) {
			return balances[_owner];
		}

		 
		function approve(address _spender, uint256 _value) public ifUnrestricted onlyPayloadSize(2) returns (bool sucess) {
			 
			require(allowed[msg.sender][_spender] == 0 || _value == 0);
			allowed[msg.sender][_spender] = _value;
			Approval(msg.sender, _spender, _value);
			return true;
		}

		 
		function allowance(address _owner, address _spender) public view returns (uint256) {
			return allowed[_owner][_spender];
		}

		 
		function increaseApproval(address _spender, uint256 _addedValue) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
			require(_addedValue > 0);
			allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

		 
		function decreaseApproval(address _spender, uint256 _subtractedValue) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
			uint256 oldValue = allowed[msg.sender][_spender];
			require(_subtractedValue > 0);
			if (_subtractedValue > oldValue) {
				allowed[msg.sender][_spender] = 0;
			} else {
				allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
			}
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

		 
		function generateTokens(address _to, uint _amount) public onlyModerator returns (bool) {
		    require(isContract(moderator));
			require(totalSupply_.add(_amount) <= maximumTokenIssue);
			totalSupply_ = totalSupply_.add(_amount);
			balances[_to] = balances[_to].add(_amount);
			Transfer(address(0x0), _to, _amount);
			return true;
		}
		 		
    	function () external payable {
    	    revert();
    	}		
}


contract CrowdSale is Moderated {
    using SafeMath for uint256;
    
     
    LEON public tokenContract;
    
     
    uint256 public constant crowdsaleTarget = 10000000 * 10**18;
     
    uint256 public tokensSold;
     
    uint256 public weiRaised;

     
    uint256 public constant etherToLEONRate = 13000;
     
    address public constant etherVault = 0xD8d97E3B5dB13891e082F00ED3fe9A0BC6B7eA01;    
     
    address public constant bountyVault = 0x96B083a253A90e321fb9F53645483745630be952;
     
    VestingVault public vestingContract;
     
    uint256 constant purchaseMinimum = 1 ether;
     
    uint256 constant purchaseMaximum = 65 ether;
    
     
    bool public isFinalized;
     
    bool public active;
    
     
    mapping (address => bool) internal whitelist;   
    
     
    event Finalized(uint256 sales, uint256 raised);
     
    event Purchased(address indexed purchaser, uint256 tokens, uint256 totsales, uint256 ethraised);
     
    event Whitelisted(address indexed participant);
     
    event Revoked(address indexed participant);
    
     
    modifier onlyWhitelist {
        require(whitelist[msg.sender]);
        _;
    }
     
    modifier whileActive {
        require(active);
        _;
    }
    
     
     
    function CrowdSale(address _tokenAddr) public {
        tokenContract = LEON(_tokenAddr);
    }   

     
    function() external payable {
        buyTokens(msg.sender);
    }
    
     
    function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhitelist whileActive {
         
        require(msg.value > purchaseMinimum && msg.value < purchaseMaximum);
         
        etherVault.transfer(msg.value);
         
        weiRaised = weiRaised.add(msg.value);
         
        uint256 _tokens = (msg.value).mul(etherToLEONRate); 
         
        require(tokenContract.generateTokens(_purchaser, _tokens));
         
        tokensSold = tokensSold.add(_tokens);
         
        Purchased(_purchaser, _tokens, tokensSold, weiRaised);
    }
    
    function initialize() external onlyModerator {
         
        require(!isFinalized && !active);
         
        require(tokenContract.getModerator() == address(this));
         
        tokenContract.restrict();
         
        active = true;
    }
    
     
    function finalize() external onlyModerator {
         
        require(!isFinalized && active);
         
        uint256 teamAllocation = tokensSold.mul(9000).div(10000);
         
        uint256 bountyAllocation = tokensSold.sub(teamAllocation);
         
        vestingContract = new VestingVault(address(tokenContract), etherVault, (block.timestamp + 26 weeks));
         
        require(tokenContract.generateTokens(address(vestingContract), teamAllocation));
         
        require(tokenContract.generateTokens(bountyVault, bountyAllocation));
         
        Finalized(tokensSold, weiRaised);
         
        isFinalized = true;
         
        active = false;
    }
    
     
    function migrate(address _moderator) external onlyModerator {
         
        require(isFinalized);
         
        require(isContract(_moderator));
         
        tokenContract.reassignModerator(_moderator);    
    }
    
     
    function verifyParticipant(address participant) external onlyModerator {
         
        whitelist[participant] = true;
         
        Whitelisted(participant);
    }
    
     
    function revokeParticipation(address participant) external onlyModerator {
         
        whitelist[participant] = false;
         
        Revoked(participant);
    }
    
     
    function checkParticipantStatus(address participant) external view returns (bool whitelisted) {
        return whitelist[participant];
    }
}   

 
contract VestingVault {

     
    LEON public tokenContract; 
     
    address public beneficiary;
     
    uint256 public releaseDate;
    
     
    function VestingVault(address _token, address _beneficiary, uint256 _time) public {
        tokenContract = LEON(_token);
        beneficiary = _beneficiary;
        releaseDate = _time;
    }
    
     
    function checkBalance() constant public returns (uint256 tokenBalance) {
        return tokenContract.balanceOf(this);
    }

     
    function claim() external {
         
        require(msg.sender == beneficiary);
         
        require(block.timestamp > releaseDate);
         
        uint256 balance = tokenContract.balanceOf(this);
         
        tokenContract.transfer(beneficiary, balance);
    }
    
     
    function changeBeneficiary(address _newBeneficiary) external {
         
        require(msg.sender == beneficiary);
         
        beneficiary = _newBeneficiary;
    }
    
     
     
    function extract(address _token) public returns (bool) {
        require(_token != address(0x0) || _token != address(tokenContract));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        return token.transfer(beneficiary, balance);
    }   
    
    function() external payable {
        revert();
    }
}