 

contract Owned {

     
    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
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

     
    bool public locked;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;
    

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        if (balances[msg.sender] < _value) { 
            throw;
        }        

         
        if (balances[_to] + _value < balances[_to])  { 
            throw;
        }

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

          
        if (locked) {
            throw;
        }

         
        if (balances[_from] < _value) { 
            throw;
        }

         
        if (balances[_to] + _value < balances[_to]) { 
            throw;
        }

         
        if (_value > allowed[_from][msg.sender]) { 
            throw;
        }

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

 
contract DRPToken is Owned, StandardToken {

     
    string public standard = "Token 0.1";

     
    string public name = "DCORP";        
    
     
    string public symbol = "DRP";

     
    uint8 public decimals = 2;

     
    bool public incentiveDistributionStarted = false;
    uint256 public incentiveDistributionDate = 0;
    uint256 public incentiveDistributionRound = 1;
    uint256 public incentiveDistributionMaxRounds = 3;
    uint256 public incentiveDistributionInterval = 1 years;
    uint256 public incentiveDistributionRoundDenominator = 2;
    
     
    struct Incentive {
        address recipient;
        uint8 percentage;
    }

    Incentive[] public incentives;
    

     
    function DRPToken() {  
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = true;

        incentives.push(Incentive(0x3cAf983aCCccc2551195e0809B7824DA6FDe4EC8, 49));  
        incentives.push(Incentive(0x11666F3492F03c930682D0a11c93BF708d916ad7, 19));  
        incentives.push(Incentive(0x6c31dE34b5df94F681AFeF9757eC3ed1594F7D9e, 19));  
        incentives.push(Incentive(0x5becE8B6Cb3fB8FAC39a09671a9c32872ACBF267, 9));   
        incentives.push(Incentive(0x00DdD4BB955e0C93beF9b9986b5F5F330Fd016c6, 5));   
    }


     
    function startIncentiveDistribution() onlyOwner returns (bool success) {
        if (!incentiveDistributionStarted) {
            incentiveDistributionDate = now + incentiveDistributionInterval;
            incentiveDistributionStarted = true;
        }

        return incentiveDistributionStarted;
    }


     
    function withdrawIncentives() {

         
        if (!incentiveDistributionStarted) {
            throw;
        }

         
        if (incentiveDistributionRound > incentiveDistributionMaxRounds) {
            throw;
        }

         
        if (now < incentiveDistributionDate) {
            throw;
        }

        uint256 totalSupplyToDate = totalSupply;
        uint256 denominator = 1;

         
        if (incentiveDistributionRound > 1) {
            denominator = incentiveDistributionRoundDenominator**(incentiveDistributionRound - 1);
        }

        for (uint256 i = 0; i < incentives.length; i++) {

             
            uint256 amount = totalSupplyToDate * incentives[i].percentage / 10**3 / denominator; 
            address recipient =  incentives[i].recipient;

             
            balances[recipient] += amount;
            totalSupply += amount;

             
            Transfer(0, this, amount);
            Transfer(this, recipient, amount);
        }

         
        incentiveDistributionDate = now + incentiveDistributionInterval;
        incentiveDistributionRound++;
    }


     
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }


     
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

         
        if (_value < 0) {
            throw;
        }

         
        balances[_recipient] += _value;
        totalSupply += _value;

         
        Transfer(0, owner, _value);
        Transfer(owner, _recipient, _value);

        return true;
    }


     
    function () {
        throw;
    }
}