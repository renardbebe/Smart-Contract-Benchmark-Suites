 

pragma solidity ^0.4.11;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success) {
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
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant onlyPayloadSize(2) returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;
}

contract SolarEclipseToken is StandardToken {
    uint8 public decimals = 18;
    string public name = 'Solar Eclipse Token';
    address owner;
    string public symbol = 'SET';

    uint startTime = 1503330410;  
    uint endTime = 1503349461;  

    uint metersInAstronomicalUnit = 149597870700;
    uint milesInAstronomicalUnit = 92955807;
    uint speedOfLightInMetersPerSecond = 299792458;

    uint public totalSupplyCap = metersInAstronomicalUnit * 1 ether;
    uint public tokensPerETH = milesInAstronomicalUnit;

    uint public ownerTokens = speedOfLightInMetersPerSecond * 10 ether;

    function ownerWithdraw() {
        if (msg.sender != owner) revert();  

        owner.transfer(this.balance);  
    }

    function () payable {
        if (now < startTime) revert();  
        if (now > endTime) revert();  
        if (totalSupply >= totalSupplyCap) revert();  

        uint tokensIssued = msg.value * tokensPerETH;

        if (totalSupply + tokensIssued > totalSupplyCap) {
            tokensIssued = totalSupplyCap - totalSupply;  
        }

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;  
    }

    function SolarEclipseToken() {
        owner = msg.sender;
        totalSupply = ownerTokens;
        balances[owner] = ownerTokens;
    }
}