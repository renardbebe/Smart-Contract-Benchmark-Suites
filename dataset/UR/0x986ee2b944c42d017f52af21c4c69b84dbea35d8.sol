 

pragma solidity ^0.4.18;
 

 
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


 
contract BMC {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function BMC( uint256 initialSupply, uint8 decimalUnits) public {
        balanceOf[msg.sender] = initialSupply;  
        totalSupply = initialSupply;  
        name = "BitMartToken";    
        symbol = "BMC";     
        decimals = decimalUnits;   
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0));
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

     
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value ); 
        require(balanceOf[_to] + _value >= balanceOf[_to]);  

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  
        balanceOf[_to] = balanceOf[_to].add(_value);   
        Transfer(msg.sender, _to, _value);    
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value ); 
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        require(_value <= allowance[_from][msg.sender]);  

        balanceOf[_from] = balanceOf[_from].sub(_value);    
        balanceOf[_to] = balanceOf[_to].add(_value);   
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf[msg.sender] >= _value); 
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);  
        Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value); 
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);   
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool) {
        require(freezeOf[msg.sender] >= _value);  
        require(_value > 0);

        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);  
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        Unfreeze(msg.sender, _value);
        return true;
    }

     
    function withdrawEther(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

     
    function() payable public {
    }
}