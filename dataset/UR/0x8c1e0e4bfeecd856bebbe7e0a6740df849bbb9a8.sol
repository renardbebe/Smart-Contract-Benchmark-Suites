 

pragma solidity 0.5.7;
 

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract token {

    function balanceOf(address _owner) public view returns(uint256 balance);
     
     
    function transfer(address _to, uint256 _value) public;

}

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public view returns(uint256 value);

    function transfer(address _to, uint256 _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

    function approve(address _spender, uint256 _value) public returns(bool success);

    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

}

 
contract ERC20Token is ERC20TokenInterface {  

    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;  
    mapping(address => mapping(address => uint256)) allowed;  

     
    function balanceOf(address _owner) public view returns(uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(_to != address(0));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_to != address(0));  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }



     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Asset is ERC20Token {

    string public name = 'Cycle';
    uint8 public decimals = 8;
    string public symbol = 'CYCLE';
    string public version = '1';
    address public owner;  

    constructor(uint initialSupply, address initialOwner) public {
        owner = initialOwner;
        totalSupply = initialSupply * (10 ** uint256(decimals));  
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
    }

     
    function recoverTokens(token _address, address _to) public {
        require(msg.sender == owner);
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(address(this));  
        _address.transfer(_to, remainder);  
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        require(newOwner != address(0));
        owner = newOwner;
    }

     
    function () external {
        revert();
    }

}