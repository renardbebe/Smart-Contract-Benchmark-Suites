 

pragma solidity ^0.4.19;

 

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract ERC223Basic is StandardToken {
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract ERC223BasicToken is ERC223Basic {
    using SafeMath for uint;

     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

     
    function transfer(address to, uint value, bytes data) onlyPayloadSize(2 * 32) public {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            receiver.tokenFallback(msg.sender, value, data);
        }
        Transfer(msg.sender, to, value);   
        Transfer(msg.sender, to, value, data);   
    }

     
     
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32)  public returns (bool) {
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
            bytes memory empty;
            receiver.tokenFallback(msg.sender, value, empty);
        }
        Transfer(msg.sender, to, value);   
        return true;
    }
}

 

 
contract DogRacingToken is ERC223BasicToken {
  using SafeMath for uint256;

  string constant public name = "Dog Racing";
  string constant public symbol = "DGR";
  uint8 constant public decimals = 3;
  uint256 constant public totalSupply 	= 326250000 * 1000;	 

  address public owner;    

  modifier onlyOwner {
    require(owner == msg.sender);
    _;
  }

  function DogRacingToken() public {
    owner = msg.sender;
    balances[owner] = totalSupply;    
  }

   
  function burnTokens(uint256 amount) onlyOwner external {
    balances[owner] = balances[owner].sub(amount);
  }
}

 

 
contract DogRacingCrowdsale {
  using SafeMath for uint256;

  DogRacingToken public token;		 

  uint256 public stage1_start;		 
  uint256 public stage2_start;
  uint256 public stage3_start;
  uint256 public stage4_start;
  uint256 public crowdsale_end;

  uint256 public stage1_price;		 
  uint256 public stage2_price;		
  uint256 public stage3_price;		
  uint256 public stage4_price;

  uint256 public hard_cap_wei;		 

  address public owner;   			 

  uint256 public wei_raised;		 

  event TokenPurchase(address buyer, uint256 weiAmount, uint256 tokensAmount);

  modifier onlyOwner {
    require(owner == msg.sender);
   _;
  }

  modifier withinCrowdsaleTime {
	require(now >= stage1_start && now < crowdsale_end);
	_;
  }

  modifier afterCrowdsale {
	require(now >= crowdsale_end);
	_;
  }

  modifier withinCap {
  	require(wei_raised < hard_cap_wei);
	_;
  }

   
  function DogRacingCrowdsale(DogRacingToken _token,
  							  uint256 _stage1_start, uint256 _stage2_start, uint256 _stage3_start, uint256 _stage4_start, uint256 _crowdsale_end,
  							  uint256 _stage1_price, uint256 _stage2_price, uint256 _stage3_price, uint256 _stage4_price,
  							  uint256 _hard_cap_wei) public {
  	require(_stage1_start > now);
  	require(_stage2_start > _stage1_start);
  	require(_stage3_start > _stage2_start);
  	require(_stage4_start > _stage3_start);
  	require(_crowdsale_end > _stage4_start);
  	require(_stage1_price > 0);
  	require(_stage2_price < _stage1_price);
  	require(_stage3_price < _stage2_price);
  	require(_stage4_price < _stage3_price);
  	require(_hard_cap_wei > 0);
    require(_token != address(0));

  	owner = msg.sender;

  	token = _token;

  	stage1_start = _stage1_start;
  	stage2_start = _stage2_start;
  	stage3_start = _stage3_start;
  	stage4_start = _stage4_start;
  	crowdsale_end = _crowdsale_end;

  	stage1_price = _stage1_price;
  	stage2_price = _stage2_price;
  	stage3_price = _stage3_price;
  	stage4_price = _stage4_price;

  	hard_cap_wei = _hard_cap_wei;
  }

   
  function getCurrentPrice() public view withinCrowdsaleTime returns (uint256) {
  	if (now < stage2_start) {
  		return stage1_price;
  	} else if (now < stage3_start) {
  		return stage2_price;
  	} else if (now < stage4_start) {
  		return stage3_price;
  	} else {
  		return stage4_price;
  	}
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    uint256 price = getCurrentPrice();
    return weiAmount.mul(price).div(1 ether);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function tokenFallback(address, uint256, bytes) external pure {
  }

   
  function buyTokens(address beneficiary) public withinCrowdsaleTime withinCap payable {
   	uint256 wei_amount = msg.value;
    
    require(beneficiary != address(0));
    require(wei_amount != 0);
 
     
    uint256 tokens = getTokenAmount(wei_amount);

     
    wei_raised = wei_raised.add(wei_amount);
    require(wei_raised <= hard_cap_wei);

     
    token.transfer(beneficiary, tokens);

    TokenPurchase(beneficiary, wei_amount, tokens);

     
    owner.transfer(msg.value);
  }

   
  function withdrawTokens() external onlyOwner afterCrowdsale {
  	uint256 tokens_remaining = token.balanceOf(address(this));
  	token.transfer(owner, tokens_remaining);
  }

}