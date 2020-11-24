 

 

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

    modifier onlyPayloadSize(uint numWords) {
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

 

contract Touch is Moderated {
	using SafeMath for uint256;

		string public name = "Touch. Token";
		string public symbol = "TST";
		uint8 public decimals = 18;

        uint256 public maximumTokenIssue = 1000000000 * 10**18;

		mapping(address => uint256) internal balances;
		mapping (address => mapping (address => uint256)) internal allowed;

		uint256 internal totalSupply_;

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

		 
		function generateTokens(address _to, uint _amount) internal returns (bool) {
			totalSupply_ = totalSupply_.add(_amount);
			balances[_to] = balances[_to].add(_amount);
			Transfer(address(0x0), _to, _amount);
			return true;
		}
		 
    	function () external payable {
    	    revert();
    	}

    	function Touch () public {
    		generateTokens(msg.sender, maximumTokenIssue);
    	}

}

contract CrowdSale is Moderated {
	using SafeMath for uint256;

        address public recipient1 = 0x375D7f6bf5109E8e7d27d880EC4E7F362f77D275;  
        address public recipient2 = 0x2D438367B806537a76B97F50B94086898aE5C518;  
        address public recipient3 = 0xd198258038b2f96F8d81Bb04e1ccbfC2B3c46760;  
        uint public percentageRecipient1 = 35;
        uint public percentageRecipient2 = 35;
        uint public percentageRecipient3 = 30;

	 
	Touch public tokenContract;

    uint256 public startDate;

    uint256 public endDate;

     
    uint256 public constant crowdsaleTarget = 22289 ether;
     
    uint256 public etherRaised;

     
	address public etherVault;

     
	uint256 constant purchaseThreshold = 5 finney;

     
	bool public isFinalized = false;

	bool public active = false;

	 
	event Finalized();

	 
	event Purchased(address indexed purchaser, uint256 indexed tokens);

     
    modifier onlyWhileActive {
        require(now >= startDate && now <= endDate && active);
        _;
    }

    function CrowdSale( address _tokenAddr,
                        uint256 start,
                        uint256 end) public {
        require(_tokenAddr != address(0x0));
        require(now < start && start < end);
         
        tokenContract = Touch(_tokenAddr);

        etherVault = msg.sender;

        startDate = start;
        endDate = end;
    }

	 
	function () external payable {
	    buyTokens(msg.sender);
	}

	function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhileActive returns (bool) {
	    require(!targetReached());
	    require(msg.value > purchaseThreshold);
	    
	   splitPayment();

	    uint256 _tokens = calculate(msg.value);
         
        require(tokenContract.transferFrom(moderator,_purchaser,_tokens));
		 
        Purchased(_purchaser, _tokens);
        return true;
	}

	function calculate(uint256 weiAmount) internal returns(uint256) {
	    uint256 excess;
	    uint256 numTokens;
	    uint256 excessTokens;
        if(etherRaised < 5572 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 5572 ether) {
                excess = etherRaised.sub(5572 ether);
                numTokens = weiAmount.sub(excess).mul(5608);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(5608);
            }
        } else if(etherRaised < 11144 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 11144 ether) {
                excess = etherRaised.sub(11144 ether);
                numTokens = weiAmount.sub(excess).mul(4807);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(4807);
            }
        } else if(etherRaised < 16716 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 16716 ether) {
                excess = etherRaised.sub(16716 ether);
                numTokens = weiAmount.sub(excess).mul(4206);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(4206);
            }
        } else if(etherRaised < 22289 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 22289 ether) {
                excess = etherRaised.sub(22289 ether);
                numTokens = weiAmount.sub(excess).mul(3738);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(3738);
            }
        } else {
            etherRaised = etherRaised.add(weiAmount);
            return weiAmount.mul(3738);
        }
	}


    function changeEtherVault(address newEtherVault) public onlyModerator {
        require(newEtherVault != address(0x0));
        etherVault = newEtherVault;

}


    function initialize() public onlyModerator {
         
         
        require(tokenContract.allowance(moderator, address(this)) == 102306549000000000000000000);
        active = true;
         
         
    }

	 
    function finalize() public onlyModerator {
         
        require(!isFinalized);
         
        require(hasEnded() || targetReached());

        active = false;

         
        Finalized();
         
        isFinalized = true;
    }

	 
    function hasEnded() internal view returns (bool) {
        return (now > endDate);
    }

     
    function targetReached() internal view returns (bool) {
        return (etherRaised >= crowdsaleTarget);
    }
    function splitPayment() internal {
        recipient1.transfer(msg.value * percentageRecipient1 / 100);
        recipient2.transfer(msg.value * percentageRecipient2 / 100);
        recipient3.transfer(msg.value * percentageRecipient3 / 100);
    }

}