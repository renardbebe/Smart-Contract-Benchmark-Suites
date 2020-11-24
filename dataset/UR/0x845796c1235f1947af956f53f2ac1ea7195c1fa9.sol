 

pragma solidity >=0.4.22 <0.6.0;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) public pure  returns (uint256)  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b)public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b)public pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function _assert(bool assertion)public pure {
    assert(!assertion);
  }
}


contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public  decimals;
    uint public totalSupply;
    
    function transfer(address _to, uint256 _value)public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);
    function approve(address _spender, uint256 _value)public returns (bool success);
    function allowance(address _owner, address _spender)public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
contract CAC is ERC20Interface,SafeMath{

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor(string memory _name) public {
        name = _name;  
        symbol = "CAC";
        decimals = 18;
        totalSupply = 10000000000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value)public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[ _to] + _value >= balanceOf[ _to]); 
        
        balanceOf[msg.sender] =SafeMath.safeSub(balanceOf[msg.sender],_value) ;
        balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to],_value) ;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        require(_to != address(0));
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        require(balanceOf[ _to] + _value >= balanceOf[ _to]);
        
        balanceOf[_from] =SafeMath.safeSub(balanceOf[_from],_value) ;
        balanceOf[_to] =SafeMath.safeAdd(balanceOf[_to],_value) ;
        
        allowed[_from][msg.sender] =SafeMath.safeSub(allowed[_from][msg.sender],_value) ;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)public returns (bool success) {
        require((_value==0)||(allowed[msg.sender][_spender]==0));
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}