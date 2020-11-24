 

pragma solidity 0.4.18;

 
contract Math {

     
    function Mul(uint a, uint b) pure internal returns (uint) {
      uint c = a * b;
       
      assert(a == 0 || c / a == b);
      return c;
    }

     
    function Div(uint a, uint b) pure internal returns (uint) {
       
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

     
    function Sub(uint a, uint b) pure internal returns (uint) {
       
      assert(b <= a);
      return a - b;
    }

     
    function Add(uint a, uint b) pure internal returns (uint) {
      uint c = a + b;
       
      assert(c>=a && c>=b);
      return c;
    }
}

  contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract etherecash is ERC20,Math
{
   string public constant symbol = "ECH";
     string public constant name = "EtherEcash";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = Mul(360000000,(10 **18));
     
      
     address public owner;
     
     address central_account;
  
      
     mapping(address => uint256) balances;
  
      
     mapping(address => mapping (address => uint256)) allowed;
     
     
  
      
     modifier onlyOwner() {
         require (msg.sender == owner);
         _;
     }
      modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }
  
      
     function etherecash() public {
         owner = msg.sender;
         balances[owner] = _totalSupply;
     }
  
  function set_centralAccount(address central_Acccount) external onlyOwner
    {
        require(central_Acccount != 0x0);
        central_account = central_Acccount;
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
           balances[msg.sender] = Sub(balances[msg.sender], _amount);
             balances[_to] = Add(balances[_to], _amount);
             Transfer(msg.sender, _to, _amount);
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
        balances[_from] = Sub(balances[_from], _amount);
             allowed[_from][msg.sender] = Sub(allowed[_from][msg.sender], _amount);
             balances[_to] = Add(balances[_to], _amount);
             Transfer(_from, _to, _amount);
             return true;
             }
 
      
      
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         return allowed[_owner][_spender];
   }
   
   event check1(uint taxtoken, uint totalToken);
   event check2(uint comtoken, uint totalToken);
    
    function zero_fee_transaction(address _from, address _to, uint256 _amount, uint tax) external onlycentralAccount returns(bool success) {
        require(_to != 0x0 && tax >=0);

      uint256 taxToken = Div((Mul(tax,  _amount)), 10000); 
      uint256 totalToken = Add(_amount, taxToken);
      check1(taxToken,totalToken);
       require (balances[_from] >= totalToken  &&
            totalToken > 0 &&
            balances[_to] + totalToken > balances[_to]);
            balances[_from] = Sub(balances[_from], totalToken);
            balances[_to] = Add(balances[_to], _amount);
            balances[owner] = Add(balances[owner], taxToken);
            Transfer(_from, _to, _amount);
            Transfer(_from, owner, taxToken);
            return true;
           }

    
    function com_fee_transaction(address _from,address _to,address _taxCollector, uint256 _amount, uint commision) external onlycentralAccount returns(bool success) {
      require(_to != 0x0 && _taxCollector != 0x0 && commision >=0); 
      uint256 comToken = Div((Mul(commision,  _amount)), 10000); 
      uint256 totalToken = Sub(_amount, comToken);
       check1(comToken,totalToken);
      require (balances[_from] >= _amount &&
            totalToken >=0 &&
        balances[_to] + totalToken > balances[_to]);
           balances[_from] = Sub(balances[_from], _amount);
           balances[_to] = Add(balances[_to], totalToken);
            balances[_taxCollector] = Add(balances[_taxCollector], comToken);
            Transfer(_from, _to, totalToken);
            Transfer(_from, _taxCollector, comToken);
            return true;
       }

 
    
	 
	function transferOwnership(address newOwner)public onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = Add(balances[newOwner],balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	}

}