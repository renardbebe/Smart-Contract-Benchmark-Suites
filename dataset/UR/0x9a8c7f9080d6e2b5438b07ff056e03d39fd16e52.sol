 

pragma solidity 0.4.23;

 

library SafeMath 
{

   

  function mul(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     if (a == 0) 
     {
     	return 0;
     }
     c = a * b;
     assert(c / a == b);
     return c;
  }

   

  function div(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     return a / b;
  }

   

  function sub(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     assert(b <= a);
     return a - b;
  }

   

  function add(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     c = a + b;
     assert(c >= a);
     return c;
  }
}

contract ERC20
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 

contract OppOpenWiFi is ERC20
{
    using SafeMath for uint256;
   
    uint256 constant public TOKEN_DECIMALS = 10 ** 18;
    string public constant name            = "OppOpenWiFi Token";
    string public constant symbol          = "OPP";
    uint256 public totalTokenSupply        = 4165000000 * TOKEN_DECIMALS;  
    address public owner;
    uint8 public constant decimals = 18;

      
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) balances;
 
     

    modifier onlyOwner() 
    {
       require(msg.sender == owner);
       _;
    }
    
     

    constructor() public
    {
       owner = msg.sender;
       balances[address(this)] = totalTokenSupply;
       emit Transfer(address(0x0), address(this), balances[address(this)]);
    }
    
     

    function totalSupply() public view returns(uint256 _totalSupply) 
    {
       _totalSupply = totalTokenSupply;
       return _totalSupply;
    }

     

    function balanceOf(address _owner) public view returns (uint256 balance) 
    {
       return balances[_owner];
    }

     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)     
    {
       if (_value == 0) 
       {
           emit Transfer(_from, _to, _value);   
           return;
       }

       require(_to != address(0x0));
       require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);

       balances[_from] = balances[_from].sub(_value);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
       balances[_to] = balances[_to].add(_value);
       emit Transfer(_from, _to, _value);
       return true;
    }

     

    function approve(address _spender, uint256 _tokens)public returns(bool)
    {
       require(_spender != address(0x0));

       allowed[msg.sender][_spender] = _tokens;
       emit Approval(msg.sender, _spender, _tokens);
       return true;
    }

     

    function allowance(address _owner, address _spender) public view returns(uint256)
    {
       require(_owner != address(0x0) && _spender != address(0x0));

       return allowed[_owner][_spender];
    }

     

    function transfer(address _address, uint256 _tokens)public returns(bool)
    {
       if (_tokens == 0) 
       {
           emit Transfer(msg.sender, _address, _tokens);   
           return;
       }

       require(_address != address(0x0));
       require(balances[msg.sender] >= _tokens);

       balances[msg.sender] = (balances[msg.sender]).sub(_tokens);
       balances[_address] = (balances[_address]).add(_tokens);
       emit Transfer(msg.sender, _address, _tokens);
       return true;
    }
    
     

    function transferTo(address _address, uint256 _tokens) external onlyOwner returns(bool) 
    {
       require( _address != address(0x0)); 
       require( balances[address(this)] >= _tokens.mul(TOKEN_DECIMALS) && _tokens.mul(TOKEN_DECIMALS) > 0);

       balances[address(this)] = ( balances[address(this)]).sub(_tokens.mul(TOKEN_DECIMALS));
       balances[_address] = (balances[_address]).add(_tokens.mul(TOKEN_DECIMALS));
       emit Transfer(address(this), _address, _tokens.mul(TOKEN_DECIMALS));
       return true;
    }
	
     

    function transferOwnership(address _newOwner)public onlyOwner
    {
       require( _newOwner != address(0x0));

       balances[_newOwner] = (balances[_newOwner]).add(balances[owner]);
       balances[owner] = 0;
       owner = _newOwner;
       emit Transfer(msg.sender, _newOwner, balances[_newOwner]);
   }

    

   function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) 
   {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

    
   function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) 
   {
      uint256 oldValue = allowed[msg.sender][_spender];

      if (_subtractedValue > oldValue) 
      {
         allowed[msg.sender][_spender] = 0;
      }
      else 
      {
         allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

}