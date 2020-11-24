 

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
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        assert(b <= a);
        assert(a == c + b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        assert(a == c - b);
        return c;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract UTOToken {
     
    string public name="UTour";
    string public symbol="UTO";
    uint8 public decimals = 18;
     
    uint256 public totalSupply=3 * 10 ** 26;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);

     
     
    constructor () public {
        balanceOf[msg.sender] = totalSupply;                 
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        
        require(_to != 0x0);
         
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
         
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {   
         
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowance[msg.sender][_spender] = SafeMath.add(allowance[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    } 

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) { 
         
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value); 
         
        totalSupply = SafeMath.sub(totalSupply, _value);                    
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {  
         
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);  
         
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
         
        totalSupply = SafeMath.sub(totalSupply, _value);                           
        emit Burn(_from, _value);
        return true;
    }
}