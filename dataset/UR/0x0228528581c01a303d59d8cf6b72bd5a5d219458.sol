 

pragma solidity ^0.4.25;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}


 
 

contract Token {
     
     
     
    function totalSupply()  public view returns (uint256 supply);

     
     
    function balanceOf(address _owner)  public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value)  public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value)  public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender)  public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract OKNC is Token{
    using SafeMath for uint256;

    string public name = "Ok Node Community Token";  
    string public symbol = "OKNC"; 
    uint8 public decimals = 4;
    uint256 public totalSupply;
	address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


     
    constructor() public {
        totalSupply = 21000000000 * 10 ** uint256(decimals);                         
        balanceOf[msg.sender] = totalSupply;               
    
        owner = msg.sender;
    }

    function totalSupply() public view returns (uint256 supply){
        return totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool){
        require(_to != address(0));                               
		
        require(_value <= balanceOf[msg.sender]);            
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                      
        balanceOf[_to] = balanceOf[_to].add(_value);                             
        emit Transfer(msg.sender, _to, _value);                    
    
        return true;
    }

     
    function approve(address _spender, uint256 _value)public
        returns (bool success) {
		
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));                                 
		
        require(_value <= balanceOf[_from]);                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        require(_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = balanceOf[_from].sub(_value);                            
        balanceOf[_to] = balanceOf[_to].add(_value);                              
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }    
    
    function allowance(address _owner, address _spender)  public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }


}