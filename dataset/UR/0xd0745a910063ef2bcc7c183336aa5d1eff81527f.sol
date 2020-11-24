 

pragma solidity ^0.4.24;

contract Card {
    
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) allowed;
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 0;
    
    address public owner;
    
    string public firstName;
    string public middleName;
    string public lastName;
    string public league;
    string public team;
    string public position;
    string public sex;
    string public birthday;
    
    constructor(string n, string a, uint256 totalSupplyToUse, string firstNameToUse, string middleNameToUse, string lastNameToUse, string leagueToUse, string teamToUse, string positionToUse, string sexToUse, string birthdayToUse) public {
        name = n;
        symbol = a;
        totalSupply = totalSupplyToUse;
        balanceOf[msg.sender] = totalSupplyToUse;
        owner = msg.sender;
        
        firstName = firstNameToUse;
        middleName = middleNameToUse;
        lastName = lastNameToUse;
        league = leagueToUse;
        team = teamToUse;
        position = positionToUse;
        sex = sexToUse;
        birthday = birthdayToUse;
    }
    
    function transfer(address _to, uint256 _value) payable public returns (bool success) {
        if (balanceOf[msg.sender] < _value) return false;
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) payable public returns (bool success) {
        if (balanceOf[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balanceOf[_to] + _amount > balanceOf[_to]) {
            balanceOf[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balanceOf[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function transferOwnership (address newOwner) public {
        if(msg.sender == owner) {
            owner = newOwner;
        }
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}