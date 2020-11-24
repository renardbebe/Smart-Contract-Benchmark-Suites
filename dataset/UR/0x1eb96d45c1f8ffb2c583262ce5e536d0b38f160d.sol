 

pragma solidity ^0.4.11;
 


 
 
 
 
contract Owned {
     
    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier _onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

     
    function transferOwnership(address newOwner) _onlyOwner {
        owner = newOwner;
    }
}

 
 
contract Token is Owned {
     
     
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
    function transfer(address _to, uint256 _value) returns (bool success) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



 
contract HumanStandardToken is StandardToken {

    function() {
         
        revert();
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[msg.sender] = _initialAmount;
         
        totalSupply = _initialAmount;
         
        name = _tokenName;
         
        decimals = _decimalUnits;
         
        symbol = _tokenSymbol;
         
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {revert();}
        return true;
    }
}



contract CapitalMiningToken is HumanStandardToken {

     

     
    uint256 public simulatedBlockNumber;

    uint256 public rewardScarcityFactor;  
    uint256 public rewardReductionRate;  

     
    uint256 public blockInterval;  
    uint256 public rewardValue;  
    uint256 public initialReward;  

     
    mapping (address => Account) public pendingPayouts;  
    mapping (uint => uint) public totalBlockContribution;  
    mapping (uint => bool) public minedBlock;  

     
    struct Account {
        address addr;
        uint blockPayout;
        uint lastContributionBlockNumber;
        uint blockContribution;
    }

    uint public timeOfLastBlock;  

     
    function CapitalMiningToken(string _name, uint8 _decimals, string _symbol, string _version,
    uint256 _initialAmount, uint _simulatedBlockNumber, uint _rewardScarcityFactor,
    uint _rewardHalveningRate, uint _blockInterval, uint _rewardValue)
    HumanStandardToken(_initialAmount, _name, _decimals, _symbol) {
        version = _version;
        simulatedBlockNumber = _simulatedBlockNumber;
        rewardScarcityFactor = _rewardScarcityFactor;
        rewardReductionRate = _rewardHalveningRate;
        blockInterval = _blockInterval;
        rewardValue = _rewardValue;
        initialReward = _rewardValue;
        timeOfLastBlock = now;
    }

     
     
     
    function mine() payable _updateBlockAndRewardRate() _updateAccount() {
         
        require(msg.value >= 50 finney);
        totalBlockContribution[simulatedBlockNumber] += msg.value;
         

        if (pendingPayouts[msg.sender].addr != msg.sender) { 
             
            pendingPayouts[msg.sender] = Account(msg.sender, rewardValue, simulatedBlockNumber,
            pendingPayouts[msg.sender].blockContribution + msg.value);
            minedBlock[simulatedBlockNumber] = true;
        }
        else { 
            require(pendingPayouts[msg.sender].lastContributionBlockNumber == simulatedBlockNumber);
            pendingPayouts[msg.sender].blockContribution += msg.value;
        }
        return;
    }

    modifier _updateBlockAndRewardRate() {
         
        if ((now - timeOfLastBlock) >= blockInterval && minedBlock[simulatedBlockNumber] == true) {
            timeOfLastBlock = now;
            simulatedBlockNumber += 1;
             
            rewardValue = initialReward / (2 ** (simulatedBlockNumber / rewardReductionRate));  
             
        }
        _;
    }

    modifier _updateAccount() {
        if (pendingPayouts[msg.sender].addr == msg.sender && pendingPayouts[msg.sender].lastContributionBlockNumber < simulatedBlockNumber) {
             
            uint payout = pendingPayouts[msg.sender].blockContribution * pendingPayouts[msg.sender].blockPayout / totalBlockContribution[pendingPayouts[msg.sender].lastContributionBlockNumber];  
            pendingPayouts[msg.sender] = Account(0, 0, 0, 0);
             
            totalSupply += payout;
            balances[msg.sender] += payout;
             
            Transfer(0, owner, payout);
             
            Transfer(owner, msg.sender, payout);
        }
        _;
    }

    function updateAccount() _updateBlockAndRewardRate() _updateAccount() {}

    function withdrawEther() _onlyOwner() {
        owner.transfer(this.balance);
    }
}

 
contract Aequitas is CapitalMiningToken {
     
    function Aequitas() CapitalMiningToken(
            "Aequitas",              
            8,                       
            "AQT",                   
            "0.1",                   
            0,                       
            0,                       
            2,                       
            210000,                  
            10 minutes,              
            5000000000               
    ){}
}