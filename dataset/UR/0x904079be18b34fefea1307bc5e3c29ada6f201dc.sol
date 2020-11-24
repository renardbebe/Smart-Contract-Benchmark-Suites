 

pragma solidity ^0.4.18;

 

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






 
contract Controlled {
    address public controller;

    function Controlled() public {
        controller = msg.sender;
    }

    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    function transferControl(address newController) public onlyController{
        controller = newController;
    }
}

 
contract RefundVault is Controlled {
    using SafeMath for uint256;
    
    enum State { Active, Refunding, Closed }
    
    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;
    
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;        
        state = State.Active;
    }

	function () external payable {
	    revert();
	}
    
    function deposit(address investor) onlyController public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }
    
    function close() onlyController public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }
    
    function enableRefunds() onlyController public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }
    
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}

contract CrowdSale is Moderated {
	using SafeMath for uint256;
	
	 
	Token public tokenContract;
	
     
    uint256 public constant startDate = 1519891200;
     
    uint256 public constant endDate = 1546243140;
    
     
    uint256 public constant crowdsaleTarget = 100000 * 10**18;
    uint256 public constant margin = 1000 * 10**18;
     
    uint256 public tokensSold;
    
     
    uint256 public etherToUSDRate;
    
     
	address public constant etherVault = 0xD8d97E3B5dB13891e082F00ED3fe9A0BC6B7eA01;    
	 
	RefundVault public refundVault;
    
     
	uint256 constant purchaseThreshold = 5 finney;

     
	bool public isFinalized = false;
	
	bool public active = false;
	
	 
	event Finalized();
	
	 
	event Purchased(address indexed purchaser, uint256 indexed tokens);
    
     
    modifier onlyWhileActive {
        require(now >= startDate && now <= endDate && active);
        _;
    }	
	
    function CrowdSale(address _tokenAddr, uint256 price) public {
         
        tokenContract = Token(_tokenAddr);
         
        refundVault = new RefundVault(etherVault);
        
        etherToUSDRate = price;
    }	
	function setRate(uint256 _rate) public onlyModerator returns (bool) {
	    etherToUSDRate = _rate;
	}
	 
	function() external payable {
	    buyTokens(msg.sender);
	}
	
	 
	function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhileActive returns (bool) {
	    require(!targetReached());
	    require(msg.value > purchaseThreshold);
	    refundVault.deposit.value(msg.value)(_purchaser);
	     
	     
	     
	     
		uint256 _tokens = (msg.value).mul(etherToUSDRate).div(50);		
		require(tokenContract.transferFrom(moderator,_purchaser, _tokens));
        tokensSold = tokensSold.add(_tokens);
        Purchased(_purchaser, _tokens);
        return true;
	}	
	
	function initialize() public onlyModerator returns (bool) {
	    require(!active && !isFinalized);
	    require(tokenContract.allowance(moderator,address(this)) == crowdsaleTarget + margin);
	    active = true;
	}
	
	 
    function finalize() public onlyModerator {
         
        require(!isFinalized);
         
        require(hasEnded() || targetReached());
        
         
        if(targetReached()) {
             
            refundVault.close();

         
        } else {
             
            refundVault.enableRefunds();
        }
         
        Finalized();
         
        isFinalized = true;
        
        active = false;

    }
    
	 
    function hasEnded() internal view returns (bool) {
        return (now > endDate);
    }
    
     
    function targetReached() internal view returns (bool) {
        return (tokensSold >= crowdsaleTarget);
    }
    
     
    function claimRefund() public {
         
        require(isFinalized);
         
        require(!targetReached());
         
        refundVault.refund(msg.sender);
    }
}