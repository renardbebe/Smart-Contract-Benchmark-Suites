 

pragma solidity ^0.4.13;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract ERC827 is ERC20 {
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);

  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
}

contract ERC827Token is ERC827, StandardToken {

   
  function approveAndCall(
    address _spender,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.approve(_spender, _value);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function transferAndCall(
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_to != address(this));

    super.transfer(_to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function increaseApprovalAndCall(
    address _spender,
    uint _addedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function decreaseApprovalAndCall(
    address _spender,
    uint _subtractedValue,
    bytes _data
  )
    public
    payable
    returns (bool)
  {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}

contract TucToken is ERC827Token, Ownable {

    mapping(address => uint256) preApprovedBalances;
    mapping(address => bool) approvedAccounts;

    address admin1;
    address admin2;

    address public accountPubICOSale;
    uint8 public decimals;
	string public name;
	string public symbol;
	
	uint constant pubICOStartsAt = 1541030400;  

    modifier onlyKycTeam {
        require(msg.sender == admin1 || msg.sender == admin2);
        _;
    }
	
	modifier PubICOstarted {
		require(now >= pubICOStartsAt );
		_;
	}

     
    constructor (
        address _admin1,
        address _admin2,
		address _accountFounder,
		address _accountPrivPreSale,
		address _accountPubPreSale,
        address _accountPubICOSale,
		address _accountSalesMgmt,
		address _accountTucWorld
		)
    public 
    payable
    {
        admin1 = _admin1;
        admin2 = _admin2;
        accountPubICOSale = _accountPubICOSale;
        decimals = 18;  
		totalSupply_ = 12000000000000000000000000000;
		 
		balances[_accountFounder]     = 1024000000000000000000000000 ;  
        balances[_accountPrivPreSale] = 1326000000000000000000000000 ;  
        balances[_accountPubPreSale]  = 1500000000000000000000000000 ;  
		balances[_accountPubICOSale]  = 4150000000000000000000000000 ;  
        balances[_accountSalesMgmt]   = 2000000000000000000000000000 ;  
        balances[_accountTucWorld]    = 2000000000000000000000000000 ;  
		emit Transfer(0, _accountFounder, 		balances[_accountFounder]);
		emit Transfer(0, _accountPrivPreSale, 	balances[_accountPrivPreSale]);
		emit Transfer(0, _accountPubPreSale, 	balances[_accountPubPreSale]);
		emit Transfer(0, _accountPubICOSale, 	balances[_accountPubICOSale]);
		emit Transfer(0, _accountSalesMgmt, 	balances[_accountSalesMgmt]);
		emit Transfer(0, _accountTucWorld, 		balances[_accountTucWorld]);
		
		name = "TUC.World";
		symbol = "TUC";
    }

     
    function buyToken()
    payable
    external
	PubICOstarted
    {
        uint256 tucAmount = (msg.value * 1000000000000000000) / 5400000000000;
        require(balances[accountPubICOSale] >= tucAmount);
		
        if (approvedAccounts[msg.sender]) {
             
            balances[msg.sender] += tucAmount;
			emit Transfer(accountPubICOSale, msg.sender, tucAmount);
        } else {
             
            preApprovedBalances[msg.sender] += tucAmount;
        }
        balances[accountPubICOSale] -= tucAmount;
    }

     
    function kycApprove(address _user)
    external
    onlyKycTeam
    {
         
        approvedAccounts[_user] = true;
         
        balances[_user] += preApprovedBalances[_user];
         
        preApprovedBalances[_user] = 0;
		emit Transfer(accountPubICOSale, _user, balances[_user]);
    }

     
    function kycRefuse(address _user)
    external
    onlyKycTeam
    {
		require(approvedAccounts[_user] == false);
        uint256 tucAmount = preApprovedBalances[_user];
        uint256 weiAmount = (tucAmount * 5400000000000) / 1000000000000000000;
         
        approvedAccounts[_user] = false;
         
        balances[accountPubICOSale] += tucAmount;
         
        preApprovedBalances[_user] = 0;
         
        _user.transfer(weiAmount);
    }

     
    function retrieveEth(address _safe, uint256 _value)
    external
    onlyOwner
    {
        _safe.transfer(_value);
    }
}