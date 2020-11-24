 

pragma solidity ^0.4.11;

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract StandardToken is ERC20Token ,Controlled{

    bool public showValue=true;

     
    bool public transfersEnabled;

    function transfer(address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        if(!showValue)
        return 0;
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(!transfersEnabled) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        if(!transfersEnabled) throw;
        return allowed[_owner][_spender];
    }

     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }
    function enableShowValue(bool _showValue) onlyController {
        showValue = _showValue;
    }

    function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        if (curTotalSupply + _amount < curTotalSupply) throw;  
        totalSupply=curTotalSupply + _amount;

        balances[_owner]+=_amount;

        Transfer(0, _owner, _amount);
        return true;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MiniMeTokenSimple is StandardToken {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
    address public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
    address public tokenFactory;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeTokenSimple(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }
     
     
     

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

}

contract PFC is MiniMeTokenSimple {

    function PFC(address _tokenFactory)
    MiniMeTokenSimple(
    _tokenFactory,
    0x0,                      
    0,                        
    "Power Fans Token",       
    18,                       
    "PFC",                    
    false                     
    ) {}
}