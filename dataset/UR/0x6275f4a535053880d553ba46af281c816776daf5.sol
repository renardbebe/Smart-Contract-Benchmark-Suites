 

pragma solidity 0.4.23;

 
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
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract SoarUSD is ERC20
{ using SafeMath for uint256;
     
    string public constant name = "SoarUSD";

     
    string public constant symbol = "SoarUSD";
    uint8 public constant decimals = 5;
    uint public Totalsupply;
    address public owner;   
    address public central_account;
    uint256 no_of_tokens;
    bool stopped = false;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }


    constructor() public
    {
        owner = msg.sender;
       
    }
  
    
     
    function mintTokens(address seller, uint256 _amount) external onlyOwner{
       
        require( seller != 0x0 && _amount > 0);
        balances[seller] = (balances[seller]).add(_amount);
        Totalsupply = (Totalsupply).add(_amount);
        emit Transfer(0, seller, _amount);
       }
    
    function set_centralAccount(address _central_Acccount) external onlyOwner
    {
        require(_central_Acccount != 0x0);
        central_account = _central_Acccount;
    }
    
      
    function burnTokens(address seller,uint256 _amount) external onlyOwner{
        require(balances[seller] >= _amount);
        require( seller != 0x0 && _amount > 0);
        balances[seller] = (balances[seller]).sub(_amount);
        Totalsupply = Totalsupply.sub(_amount);
        emit Transfer(seller, 0, _amount);
    }
    
   
     
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = Totalsupply;
     }
    
     
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
    
     
      
      
      
      
      
     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
     emit Transfer(_from, _to, _amount);
     return true;
         }
    
    
      
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
   }

      
     function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
             return true;
         }
    
      
          
    function TransferBy(address _from,address _to,uint256 _amount) external onlycentralAccount returns(bool success) {
        require( _to != 0x0 && _from !=0x0); 
        require (balances[_from] >= _amount && _amount > 0);
        balances[_from] = (balances[_from]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

}