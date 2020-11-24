 

pragma solidity ^0.4.15;

contract Owned {

     
    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
 
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


     
    modifier onlyPayloadSize(uint numArgs) {
        assert(msg.data.length == numArgs * 32 + 4);
        _;
    }


     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;
    

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool success) {

         
        require(balances[msg.sender] >= _value);   

         
        require(balances[_to] + _value > balances[_to]);

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success) {

         
        require(balances[_from] >= _value);

         
        require(balances[_to] + _value > balances[_to]);

         
        require(_value <= allowed[_from][msg.sender]);

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success) {

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

 
contract ZTToken is Owned, StandardToken {

     
    string public standard = "Token 0.2";

     
    string public name = "ZeroTraffic";        
    
     
    string public symbol = "ZTT";

     
    uint8 public decimals = 8;

     
    bool public incentiveDistributed = false;
    uint256 public incentiveDistributionDate = 0;
    uint256 public incentiveDistributionInterval = 2 years;
    
     
    struct Incentive {
        address recipient;
        uint8 percentage;
    }

    Incentive[] public incentives;
    

     
    function ZTToken() {  
        balances[msg.sender] = 0;
        totalSupply = 0;
        incentiveDistributionDate = now + incentiveDistributionInterval;
        incentives.push(Incentive(0x3cAf983aCCccc2551195e0809B7824DA6FDe4EC8, 1));  
    }


     
    function withdrawIncentives() {
        require(!incentiveDistributed);
        require(now > incentiveDistributionDate);

        incentiveDistributed = true;

        uint256 totalSupplyToDate = totalSupply;
        for (uint256 i = 0; i < incentives.length; i++) {

             
            uint256 amount = totalSupplyToDate * incentives[i].percentage / 10**2; 
            address recipient = incentives[i].recipient;

             
            balances[recipient] += amount;
            totalSupply += amount;

             
            Transfer(0, this, amount);
            Transfer(this, recipient, amount);
        }
    }


     
    function issue(address _recipient, uint256 _value) onlyOwner onlyPayloadSize(2) returns (bool success) {

         
        require(_value > 0);

         
        balances[_recipient] += _value;
        totalSupply += _value;

         
        Transfer(0, owner, _value);
        Transfer(owner, _recipient, _value);

        return true;
    }


     
    function () {
        revert();
    }
}