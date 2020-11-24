 

pragma solidity ^0.4.11;
 

 
library SafeMath {

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

contract ERC20Token {  
    using SafeMath for uint256;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
    }
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AssetPAXCHANGE is ERC20Token {
    string public name = 'PAXCHANGE TOKEN';
    uint8 public decimals = 18;
    string public symbol = 'PAXCHANGE';
    string public version = '0.1';
    uint256 public totalSupply = 50000000 * (10**uint256(decimals));

    function AssetPAXCHANGE() public {
        balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6] = 50000 * (10**uint256(decimals));  
        balances[this] = 49950000 * (10**uint256(decimals));  
        allowed[this][msg.sender] = 49950000 * (10**uint256(decimals));  
         
        Transfer(0, this, totalSupply);
        Transfer(this, 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6, 50000 * (10**uint256(decimals)));
        Approval(this, msg.sender, 49950000 * (10**uint256(decimals)));

    }
     
    function() public {
        revert();
    }

}