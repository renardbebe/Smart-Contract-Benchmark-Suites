 

pragma solidity 0.4.24;

 
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
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _amount)public returns (bool ok);
  function approve(address _spender, uint _amount)public returns (bool ok);
  function transfer(address _to, uint _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
}


contract MicrosoftCorporationNASDAQMSFT is ERC20
{using SafeMath for uint256;
   string public constant symbol = "Microsoft.Corporation(NASDAQ:MSFT)";
     string public constant name = "Microsoft.Corporation.(NASDAQ: MSFT):Microsoft Corporation is an American multinational technology company with headquarters in Redmond, Washington. It develops, manufactures, licenses, supports, and sells computer software, consumer electronics, personal computers, and related services";
     uint public constant decimals = 18;
     uint256 _totalSupply = 999000000000000000000 * 10 ** 18;  
     
      
     address public owner;
     
   
     mapping(address => uint256) balances;
  
      
     mapping(address => mapping (address => uint256)) allowed;
  
      
     modifier onlyOwner() {
         if (msg.sender != owner) {
             revert();
         }
         _;
     }
  
      
     constructor () public {
         owner = msg.sender;
         balances[owner] = _totalSupply;
        emit Transfer(0, owner, _totalSupply);
     }
     
     function burntokens(uint256 tokens) public onlyOwner {
         _totalSupply = (_totalSupply).sub(tokens);
     }
  
     
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalSupply;
     }
        
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
  
      
     function transfer(address _to, uint256 _amount)public returns (bool ok) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
             return true;
         }
         
     
      
      
      
      
      
     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool ok) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
     emit Transfer(_from, _to, _amount);
     return true;
         }
 
      
      
     function approve(address _spender, uint256 _amount)public returns (bool ok) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
   }
        
      
	function transferOwnership(address newOwner) external onlyOwner
	{
	    uint256 x = balances[owner];
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, x);
	}
  
	
  

}