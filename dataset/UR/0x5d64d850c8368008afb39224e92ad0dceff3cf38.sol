 

pragma solidity ^0.4.21;

 
library SafeMath {
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract TokenERC20 {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
     
    address public owner;

     
    mapping(address => bool)   public  frozenAccount;
     
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address tokenOwner
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
         
        balanceOf[msg.sender] = totalSupply;
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
        require(tokenOwner != address(0));
        owner = tokenOwner;
    }




     
    function batchTransfer(address[] destinations, uint256[] amounts) public returns (bool success){
        require(destinations.length == amounts.length);
        for (uint256 index = 0; index < destinations.length; index++) {
            _transfer(msg.sender, destinations[index], amounts[index]);
        }
        return true;
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
         
        allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
    }


     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
         
        totalSupply = totalSupply.sub(_value);
         
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
         
        totalSupply = totalSupply.sub(_value);
         
        emit Burn(_from, _value);
        return true;
    }
}