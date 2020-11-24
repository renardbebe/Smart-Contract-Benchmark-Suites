 

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

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}

 
contract StandardToken is ERC20, BasicToken {

     
    string public standard = 'ERC20';

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    address public owner;

    mapping (address => mapping (address => uint256)) internal allowed;

    function StandardToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        balances[msg.sender] = initialSupply;
         
        totalSupply = initialSupply;
         
        name = tokenName;
         
        symbol = tokenSymbol;
         
        decimals = decimalUnits;
         

        owner=msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
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

    function multiApprove(address[] _spender, uint256[] _value) public returns (bool){
        require(_spender.length == _value.length);
        for(uint i=0;i<=_spender.length;i++){
            allowed[msg.sender][_spender[i]] = _value[i];
            Approval(msg.sender, _spender[i], _value[i]);
        }
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function multiIncreaseApproval(address[] _spender, uint[] _addedValue) public returns (bool) {
        require(_spender.length == _addedValue.length);
        for(uint i=0;i<=_spender.length;i++){
            allowed[msg.sender][_spender[i]] = allowed[msg.sender][_spender[i]].add(_addedValue[i]);
            Approval(msg.sender, _spender[i], allowed[msg.sender][_spender[i]]);
        }
        return true;
    }
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function multiDecreaseApproval(address[] _spender, uint[] _subtractedValue) public returns (bool) {
        require(_spender.length == _subtractedValue.length);
        for(uint i=0;i<=_spender.length;i++){
            uint oldValue = allowed[msg.sender][_spender[i]];
            if (_subtractedValue[i] > oldValue) {
                allowed[msg.sender][_spender[i]] = 0;
            } else {
                allowed[msg.sender][_spender[i]] = oldValue.sub(_subtractedValue[i]);
            }
            Approval(msg.sender, _spender[i], allowed[msg.sender][_spender[i]]);
        }
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}