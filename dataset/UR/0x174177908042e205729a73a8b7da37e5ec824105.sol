 

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

contract admined {  
    address public admin;  

    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        TransferAdminship(admin);
    }


     
    event SetLock(uint timeInMins);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

contract Token is admined {

    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

    function balanceOf(address _owner) public constant returns (uint256 bal) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
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

     
     
     
    function batch(address[] data,uint256 amount) onlyAdmin public {  
        uint256 length = data.length;
        for (uint i=0; i<length; i++) {  
            transfer(data[i],amount);  
        }
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Asset is admined, Token {

    string public name;
    uint8 public decimals = 18;
    string public symbol;
    string public version = '0.1';

    function Asset(
        string _tokenName,
        string _tokenSymbol,
        uint256 _initialAmount
        ) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;  
        name = _tokenName;  
        symbol = _tokenSymbol;  
        Transfer(0, this, _initialAmount);
        Transfer(this, msg.sender, _initialAmount);
    }

    function() public {
        revert();
    }

}