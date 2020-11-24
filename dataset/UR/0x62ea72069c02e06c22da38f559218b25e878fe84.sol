 

pragma solidity ^0.4.11;
	 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }}
	 
contract Ownable {
  address public owner;
	 
  function Ownable() {
    owner = msg.sender;
  }
	 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
	 
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }  }
}
	 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
	 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
	 
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
	 
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}
	 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
	 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
	 
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
	 
  function approve(address _spender, uint256 _value) returns (bool) {
	 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
	 
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
contract BIONEUM is StandardToken, Ownable {
    using SafeMath for uint256;
     
    string  public constant name = "BIONEUM";
    string  public constant symbol = "BIO";
    uint256 public constant decimals = 8;
    uint256 public constant totalSupply = decVal(50000000);
	
     
    address public multisig = 0xFC8b6add05Dd6b5fd91F6559EFF84A20201fD86c;
     
	address public developers = 0x8D9acc27005419E0a260B44d060F7427Cd9739B2;
     
	address public founders = 0xB679919c63799c39d074EEad650889B24C06fdC6;
     
	address public bounty = 0xCF2F450FB7d265fF82D0c2f1737d9f0258ae40A3;
	 
    address public constant tokenAddress = this;
     
    uint256 public startDate;
    uint256 public endDate;
     
    uint256 public weiRaised;
     
    uint256 public etherRaised;
     
	uint256 public tokensSold;
     
    modifier uninitialized() {
        require(multisig == 0x0);
        _;
    }    
	function BIONEUM() {
        startDate = now.add(5 hours);
        endDate = startDate.add(30 days);
		
        balances[founders] 	= decVal(5000000);
        Transfer(0x0, founders	, balances[founders]);
		
        balances[bounty] 	= decVal(1000000);
        Transfer(0x0, bounty	, balances[bounty]);
		
        balances[developers] = decVal(4000000);
        Transfer(0x0, developers	, balances[developers]);
		
		balances[this] = totalSupply.sub(balances[developers].add(balances[founders]).add(balances[bounty]));
        Transfer(0x0, this		, balances[this]);
    }
    function supply() internal returns (uint256) {
        return balances[this];
    }
    function getRateAt(uint256 at) constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < startDate.add(7 days)) {
            return decVal(130);
        } else if (at < startDate.add(14 days)) {
            return decVal(115);
        } else if (at < startDate.add(21 days)) {
            return decVal(105);
        } else if (at < startDate.add(28 days) || at <= endDate) {
            return decVal(100);
        } else {
            return 0;
        }    
	}
	function decVal(uint256 amount) internal returns(uint256){
		return amount * 10 ** uint256(decimals);
	}
     
    function () payable {
        buyTokens(msg.sender, msg.value);
    }
    function buyTokens(address sender, uint256 value) internal {
        require(saleActive());
        require(value >= 0.01 ether);

        uint256 weiAmount = value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

         
        uint256 actualRate = getRateAt(now);
        uint256 amount = weiAmount.mul(actualRate).div(1 ether);

         
        require(supply() >= amount);

         
        balances[this] = balances[this].sub(amount);
        balances[sender] = balances[sender].add(amount);
		Transfer(0x0, sender, amount);
         
        weiRaised = updatedWeiRaised;
		etherRaised = weiRaised.div(1 ether);
		tokensSold = tokensSold.add(amount);
		
         
        multisig.transfer(msg.value);
    }
    function finalize() onlyOwner {
        require(!saleActive());
         
        balances[owner] = balances[owner].add(balances[this]);
		Transfer(0x0, owner, balances[this]);
        balances[this] = 0;
    }
    function saleActive() public constant returns (bool) {
        return (now >= startDate && now < endDate && supply() > 0);
    }
}