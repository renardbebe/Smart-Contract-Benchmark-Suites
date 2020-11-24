 

pragma solidity 0.4.21;

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}
 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
 
	contract TrypCrowdsale is StandardToken, Ownable {
	
    using SafeMath for uint256;

	string public name = "the Tryp"; 
	string public symbol = "Tryp";
	uint public decimals = 0;   
	uint256 public constant INITIAL_SUPPLY = 1000000;

   

	StandardToken public token = this;

   

	address private constant prizewallet = (0x6eFd9391Db718dEff494C2199CD83E0EFc8102f6);
	address private constant prize2wallet = (0x426570e5b796A2845C700B4b49058E097f7dCb54);
	address private constant adminwallet = (0xe7d718cc663784480EBB62A672180fbB68f89424);

   

    uint256 public weiPerToken = 16000000000000000;

   

	uint256 public weiRaised;
    uint256 public remainingSupply_;
 
   

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


	
    function TrypCrowdsale () public payable {
		
		totalSupply_ = INITIAL_SUPPLY;
		remainingSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
			
	}


   
   
   

   

    function () external payable {
        buyTokens(msg.sender);
    }

   
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

     
        uint256 tokens = _getTokenAmount(weiAmount);
        require(tokens <= remainingSupply_);

     
        weiRaised = weiRaised.add(weiAmount);

        _deliverTokens(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds();

    }

   
   
   

   

    function setRate (uint256 _ethPriceToday) public onlyOwner {

        require(_ethPriceToday != 0);
        weiPerToken = _ethPriceToday.mul(1e18).div(1000);
    }    

   

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

   

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {

        token.transfer(_beneficiary, _tokenAmount);
        remainingSupply_ = remainingSupply_.sub(_tokenAmount);
    }

   
  
    function deliverTokensAdmin(address _beneficiary, uint256 _tokenAmount) public onlyOwner {

        token.transfer(_beneficiary, _tokenAmount);
        remainingSupply_ = remainingSupply_.sub(_tokenAmount);
    }


   
   
    

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		uint256 _tokens = _weiAmount.div(weiPerToken);
        return (_tokens);
    }
    
   
   
    function _forwardFunds() internal {

    	uint256 total_eth = (msg.value);
    	uint256 prize_pool = total_eth.mul(50).div(100);
    	uint256 prize_pool_sec = total_eth.mul(10).div(100);
    	uint256 admin_pool = total_eth.sub(prize_pool).sub(prize_pool_sec);

    	require(prizewallet == (0x6eFd9391Db718dEff494C2199CD83E0EFc8102f6));
    	prizewallet.transfer(prize_pool);
	    require(prize2wallet == (0x426570e5b796A2845C700B4b49058E097f7dCb54));
    	prize2wallet.transfer(prize_pool_sec);
	    require(adminwallet == (0xe7d718cc663784480EBB62A672180fbB68f89424));
    	adminwallet.transfer(admin_pool);
    }


     
    function withdraw() public onlyOwner {
         uint bal = address(this).balance;
         address(owner).transfer(bal);
    }

}