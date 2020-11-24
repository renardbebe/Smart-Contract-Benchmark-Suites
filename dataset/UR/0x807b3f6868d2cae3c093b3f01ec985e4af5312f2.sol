 

pragma solidity ^0.5.4;

 
contract SafeMath {

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is SafeMath, Token {
     
    function transfer(address _to, uint256 _value) onlyActive public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyActive public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract PTA is StandardToken {

     
    string public name = "Plant Technology Alliance";
    string public symbol = "PTA";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    uint256 public tokenCreationCap =  1 * (10**9) * 10**decimals;

     
    address public FundAccount;       

     
    event CreateToken(address indexed _to, uint256 _value);

     
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _tokenCreationCap,
        address _FundAccount
    ) public
    {
        name = _name;
        symbol = _symbol;
        tokenCreationCap = _tokenCreationCap * 10**decimals;
        FundAccount = _FundAccount;
        totalSupply = tokenCreationCap;
        balances[FundAccount] = tokenCreationCap;     
        emit CreateToken(FundAccount, tokenCreationCap);     
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}