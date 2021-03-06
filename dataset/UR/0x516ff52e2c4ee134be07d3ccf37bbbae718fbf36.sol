 

pragma solidity 0.4.25;
 
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
     
     
     
    return a / b;
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


 
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
      _transfer(msg.sender, _to, _value);
      return true;
    
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract HalaldexCoin is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
  
    address public owner;

   constructor() public {
        decimals = 18;                            
        totalSupply_ =   1000000000 * 10 ** uint256(decimals);                        
        balances[0x02063eFBC5653989BdDeddaCD3949260aC451ee2] = totalSupply_;             
        name = "Halaldex Coin";                                   
        symbol = "HDEX";                              
        owner = 0x02063eFBC5653989BdDeddaCD3949260aC451ee2;
        Transfer(address(0x0), 0x02063eFBC5653989BdDeddaCD3949260aC451ee2 , totalSupply_);

   }
  
   modifier onlyOwner(){
       require(msg.sender == owner);
       _;
   }
    function changeOwner(address _newOwner) public onlyOwner{
       owner = _newOwner;
   }
    
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
  

    function() payable public{
        revert();
    }



}