 

pragma solidity ^0.4.25;

 
library Safe {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }


}
contract MyCoin{
    uint public totalSupply = 500000000*10**18;   
    uint8 constant public decimals = 18;
    string constant public name = "Payment Alliance chain";
    string constant public symbol = "PAC";
    
    address public owner;


    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

     
    constructor() public{
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

     
     
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = Safe.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = Safe.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
    }

     
     
     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = Safe.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = Safe.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = Safe.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = Safe.safeSub(balanceOf[msg.sender], _value);
        totalSupply = Safe.safeSub(totalSupply,_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
     
     
    function freeze(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = Safe.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = Safe.safeAdd(freezeOf[msg.sender], _value);
        emit Freeze(msg.sender, _value);
        return true;
    }
    
     
     
    function unfreeze(uint256 _value) public returns (bool) {
        require(freezeOf[msg.sender] >= _value);
        require(_value > 0);
        freezeOf[msg.sender] = Safe.safeSub(freezeOf[msg.sender], _value);
        balanceOf[msg.sender] = Safe.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    function() payable public {
        revert();
    }
}