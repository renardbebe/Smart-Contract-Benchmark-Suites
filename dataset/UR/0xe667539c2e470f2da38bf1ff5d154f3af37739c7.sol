 

pragma solidity 0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

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

contract ERC20 {
  function totalSupply()public view returns (uint256 total_Supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint256 remaining);
  function transferFrom(address _from, address _to, uint256 _amount)public returns (bool ok);
  function approve(address _spender, uint256 _amount)public returns (bool ok);
  function transfer(address _to, uint256 _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}

contract DCLINIC is ERC20
{
    using SafeMath for uint256;
    string public constant symbol = "DHC";
    string public constant name = "DCLINIC";
    uint8 public constant decimals = 6;
    uint256 public _totalSupply = 5000000000 * 10 ** uint256(decimals);      
     
    mapping(address => uint256) balances;  
    mapping (address => mapping (address => uint)) allowed;
    
     
    address public owner;
    uint256 public owner_balance = _totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    modifier onlyOwner() {
      if (msg.sender != owner) {
            revert();
        }
        _;
        }
    
    constructor () public
    {
        owner = msg.sender;
        balances[owner] = owner_balance;  
        emit Transfer(0x00, owner, owner_balance);
    }
    
     
    function () public payable 
    {
        revert();
    }

    
      
    function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalSupply;
     }
  
      
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
  
      
     function transfer(address _to, uint256 _amount)public returns (bool success) {
         require( _to != 0x0);
         require(balances[msg.sender] >= _amount 
             && _amount >= 0
             && balances[_to] + _amount >= balances[_to]);
             balances[msg.sender] = balances[msg.sender].sub(_amount);
             balances[_to] = balances[_to].add(_amount);
             emit Transfer(msg.sender, _to, _amount);
             return true;
     }
  
      
      
      
      
      
      
     function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     )public returns (bool success) {
        require(_to != 0x0); 
         require(balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount >= 0
             && balances[_to] + _amount >= balances[_to]);
             balances[_from] = balances[_from].sub(_amount);
             allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
             balances[_to] = balances[_to].add(_amount);
             emit Transfer(_from, _to, _amount);
             return true;
             }
 
      
      
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         return allowed[_owner][_spender];
   }
   
   	 
	function transferOwnership(address newOwner)public onlyOwner
	{
	    require( newOwner != 0x0);
	    uint256 transferredBalance = balances[owner];
	    balances[newOwner] = balances[newOwner].add(balances[owner]);
	    balances[owner] = 0;
	    address oldOwner = owner;
	    owner = newOwner;
	    emit Transfer(oldOwner, owner, transferredBalance);
	}
	
	  
    function burntokens(uint256 burn_amount) external onlyOwner {
        require(burn_amount >0 && burn_amount <= balances[owner]);
         _totalSupply = (_totalSupply).sub(burn_amount);
         balances[owner] = (balances[owner].sub(burn_amount));
          emit Transfer(owner, 0x00, burn_amount);
     }
    
     
    
        function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}