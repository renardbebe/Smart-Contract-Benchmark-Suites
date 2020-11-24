 

pragma solidity ^0.4.19;

 
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public{
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract WPPToken is ERC20, Ownable {

	using SafeMath for uint256;

	uint256  public  totalSupply = 5000000000 * 1 ether;


	mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;

    string   public  name = "WPPTOKEN";
    string   public  symbol = "WPP";
    uint256  public  decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor () public{
		_balances[owner] = totalSupply;
	}

    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }

}

 


 
 
 
 
 
contract WPPPresale is Ownable{
	using SafeMath for uint256;
	WPPToken public wpp;
	uint256 public tokencap = 250000000 * 1 ether;
	 
	uint256 public  hardcap = 250000000 * 1 ether;
	bool    public  reached = false;
	uint    public  startTime ;
	uint    public  endTime ;
	uint256 public   rate = 2700;
	uint256 public   remain;

	address public multisigwallet;

	mapping(address => bool) public isWhitelisted;
	mapping(address => bool) public isAdminlisted;

	event BuyTokens(address indexed beneficiary, uint256 value, uint256 amount, uint time);
	event WhitelistSet(address indexed _address, bool _state);
	event AdminlistSet(address indexed _address, bool _state);
	event TreatRemainToken();

	constructor(address token, uint _startTime, uint _endTime, address _multi) public{
		wpp = WPPToken(token);
		 
		require (wpp.owner() == msg.sender);
		
		startTime = _startTime;  
		endTime = _endTime;  
		remain = hardcap;
		multisigwallet = _multi;
	}

	modifier onlyOwners() { 
		require (isAdminlisted[msg.sender] == true || msg.sender == owner); 
		_; 
	}

	modifier onlyWhitelisted() { 
		require (isWhitelisted[msg.sender] == true); 
		_; 
	}
	

	   
	function () public payable onlyWhitelisted {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable onlyWhitelisted {
		buyTokens(beneficiary, msg.value);
	}

	 
	function buyTokens(address beneficiary, uint256 weiAmount) internal {
		require(beneficiary != 0x0);
		require(validPurchase(weiAmount));

		 
		uint256 tokens = calcBonus(weiAmount.mul(rate));
		
		if(remain.sub(tokens) <= 0){
			reached = true;

			uint256 real = remain;

			remain = 0;

			uint256 refund = weiAmount - real.mul(100).div(110).div(rate);

			beneficiary.transfer(refund);

			transferToken(beneficiary, real);

			forwardFunds(weiAmount.sub(refund));

			emit BuyTokens(beneficiary, weiAmount.sub(refund), real, now);
		} else{

			remain = remain.sub(tokens);

			transferToken(beneficiary, tokens);

			forwardFunds(weiAmount);

			emit BuyTokens(beneficiary, weiAmount, tokens, now);
		}

	}

	function calcBonus(uint256 token_amount) internal constant returns (uint256) {
		if(now > startTime && now <= (startTime + 3 days))
			return token_amount * 110 / 100;
		return token_amount;
	}

	 
	 
	function transferToken(address beneficiary, uint256 tokenamount) internal {
		wpp.transfer(beneficiary, tokenamount);
		 
	}

	 
	 
	function forwardFunds(uint256 weiAmount) internal {
		multisigwallet.transfer(weiAmount);
	}

	 
	function validPurchase(uint256 weiAmount) internal constant returns (bool) {
		bool withinPeriod = now > startTime && now <= endTime;
		bool nonZeroPurchase = weiAmount >= 0.5 ether;
		bool withinSale = reached ? false : true;
		return withinPeriod && nonZeroPurchase && withinSale;
	} 

	function setAdminlist(address _addr, bool _state) public onlyOwner {
		isAdminlisted[_addr] = _state;
		emit AdminlistSet(_addr, _state);
	}

	function setWhitelist(address _addr) public onlyOwners {
        require(_addr != address(0));
        isWhitelisted[_addr] = true;
        emit WhitelistSet(_addr, true);
    }

     
    function setManyWhitelist(address[] _addr) public onlyOwners {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i]);
        }
    }

	 
	function hasEnded() public constant returns (bool) {
		return now > endTime;
	}

	 
	function hasStarted() public constant returns (bool) {
		return now >= startTime;
	}

	function setRate(uint256 _rate) public onlyOwner returns (bool) {
		require (now >= startTime && now <= endTime);
		rate = _rate;
	}

	function treatRemaintoken() public onlyOwner returns (bool) {
		require(now > endTime);
		require(remain > 0);
		wpp.transfer(multisigwallet, remain);
		remain = 0;
		emit TreatRemainToken();
		return true;

	}

	function kill() public onlyOwner{
        selfdestruct(owner);
    }
	
}