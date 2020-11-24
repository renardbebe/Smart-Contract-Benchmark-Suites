 

pragma solidity ^0.4.11;

 

contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;

    function mul(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b != 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }

    function sub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

     
    function dateBonus(uint roundIco, uint endIco, uint256 amount) internal returns (uint256) {
        if(endIco >= now && roundIco == 0){
            return add(amount,mulByFraction(amount, 15, 100));
        }else{
            return amount;
        }
    }

}


 
 
contract AbstractToken {
     
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
     
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    address[] public owners;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
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
}


contract RobotTradingToken is StandardToken, SafeMath {
     
     
    string public constant name = "Robot Trading";
    string public constant symbol = "RTD";
    uint public constant decimals = 18;

     

    address public icoContract = 0x0;
     

    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }

     

     
     
    function RobotTradingToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }

     
     
     
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
    }

     
     
     
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = add(balances[_to], _value);

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}


contract RobotTradingIco is SafeMath {
     
    RobotTradingToken public robottradingToken;

    enum State{
        Init,
        Pause,
        Running,
        Stopped,
        Migrated
    }

    State public currentState = State.Pause;

    string public constant name = "Robot Trading ICO";

     
    address public accManager;
    address public accFounder;
    address public accPartner;
    address public accCompany;
    address public accRecive;

     
    uint public supplyLimit = 10000000000000000000000000000;

     
    uint constant BASE = 1000000000000000000;

     
    uint public roundICO = 0;

    struct RoundStruct {
        uint round; 
        uint price; 
        uint supply; 
        uint recive; 
        uint soldTokens; 
        uint sendTokens; 
        uint dateStart; 
        uint dateEnd;  
    }

    RoundStruct[] public roundData;

    bool public sentTokensToFounder = false;
    bool public sentTokensToPartner = false;
    bool public sentTokensToCompany = false;

    uint public tokensToFunder = 0;
    uint public tokensToPartner = 0;
    uint public tokensToCompany = 0;
    uint public etherRaised = 0;

     

    modifier whenInitialized() {
         
        require(currentState >= State.Init);
        _;
    }

    modifier onlyManager() {
         
        require(msg.sender == accManager);
        _;
    }

    modifier onIcoRunning() {
         
        require(currentState == State.Running);
        _;
    }

    modifier onIcoStopped() {
         
        require(currentState == State.Stopped);
        _;
    }

    modifier notMigrated() {
         
        require(currentState != State.Migrated);
        _;
    }

     
     
    function RobotTradingIco(address _accManager) {
        assert(_accManager != 0x0);

        robottradingToken = new RobotTradingToken(this);
        accManager = _accManager;
    }

     
     
     
     
     
     
    function init(address _founder, address _partner, address _company, address _recive) onlyManager {
        assert(currentState != State.Init);
        assert(_founder != 0x0);
        assert(_recive != 0x0);

        accFounder = _founder;
        accPartner = _partner;
        accCompany = _company;
        accRecive = _recive;

        currentState = State.Init;
    }

     
     
    function setState(State _newState) public onlyManager
    {
        currentState = _newState;
        if(currentState == State.Running) {
            roundData[roundICO].dateStart = now;
        }
    }
     
    function setNewIco(uint _round, uint _price, uint _startDate, uint _endDate,  uint _newAmount) public onlyManager  whenInitialized {
 
        require(roundData.length == _round);

        RoundStruct memory roundStruct;
        roundData.push(roundStruct);

        roundICO = _round;  
        roundData[_round].round = _round;
        roundData[_round].price = _price;
        roundData[_round].supply = mul(_newAmount, BASE);  
        roundData[_round].recive = 0;
        roundData[_round].soldTokens = 0;
        roundData[_round].sendTokens = 0;
        roundData[_round].dateStart = _startDate;
        roundData[_round].dateEnd = _endDate;

    }


     
     
    function setManager(address _accManager) onlyManager {
        assert(_accManager != 0x0);
        accManager = _accManager;
    }

     
     
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0 && roundData[roundICO].dateEnd >= now && roundData[roundICO].dateStart <= now);
        require(msg.value > 0);

        uint tokensToEmit =  mul(msg.value, roundData[roundICO].price);

        if(roundICO==0){
            tokensToEmit =  dateBonus(roundICO, roundData[roundICO].dateEnd, tokensToEmit);
        }
        require(add(roundData[roundICO].soldTokens, tokensToEmit) <= roundData[roundICO].supply);
        roundData[roundICO].soldTokens = add(roundData[roundICO].soldTokens, tokensToEmit);
 
         
        robottradingToken.emitTokens(_buyer, tokensToEmit);
        etherRaised = add(etherRaised, msg.value);
    }

     
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }

     
     
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        robottradingToken.burnTokens(_from, _value);
    }

     
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        assert(_value <= this.balance);
         
        accRecive.transfer(_value * 10000000000000000);  
    }

     
    function withdrawAllEther() onlyManager {
        if(this.balance > 0)
        {
            accRecive.transfer(this.balance);
        }
    }

     
    function sendTokensToPartner() onlyManager whenInitialized {
        require(!sentTokensToPartner);

        uint tokensSold = add(roundData[0].soldTokens, roundData[1].soldTokens);
        uint partnerTokens = mulByFraction(supplyLimit, 11, 100);  

        tokensToPartner = sub(partnerTokens,tokensSold);
        robottradingToken.emitTokens(accPartner, partnerTokens);
        sentTokensToPartner = true;
    }

     
    function sendLimitTokensToPartner(uint _value) onlyManager whenInitialized {
        require(!sentTokensToPartner);
        uint partnerLimit = mulByFraction(supplyLimit, 11, 100);  
        uint partnerReward = sub(partnerLimit, tokensToPartner);  
        uint partnerValue = mul(_value, BASE);  

        require(partnerReward >= partnerValue);
        tokensToPartner = add(tokensToPartner, partnerValue);
        robottradingToken.emitTokens(accPartner, partnerValue);
    }

     
    function sendTokensToCompany() onlyManager whenInitialized {
        require(!sentTokensToCompany);

         
        uint companyLimit = mulByFraction(supplyLimit, 30, 100);  
        uint companyReward = sub(companyLimit, tokensToCompany);  

        require(companyReward > 0);

        tokensToCompany = add(tokensToCompany, companyReward);

        robottradingToken.emitTokens(accCompany, companyReward);
        sentTokensToCompany = true;
    }

     
    function sendLimitTokensToCompany(uint _value) onlyManager whenInitialized {
        require(!sentTokensToCompany);
        uint companyLimit = mulByFraction(supplyLimit, 30, 100);  
        uint companyReward = sub(companyLimit, tokensToCompany);  
        uint companyValue = mul(_value, BASE);  

        require(companyReward >= companyValue);
        tokensToCompany = add(tokensToCompany, companyValue);
        robottradingToken.emitTokens(accCompany, companyValue);
    }

     
    function sendAllTokensToFounder(uint _round) onlyManager whenInitialized {
        require(roundData[_round].soldTokens>=1);

        uint icoToken = add(roundData[_round].soldTokens,roundData[_round].sendTokens);
        uint icoSupply = roundData[_round].supply;

        uint founderValue = sub(icoSupply, icoToken);

        roundData[_round].sendTokens = add(roundData[_round].sendTokens, founderValue);
        tokensToFunder = add(tokensToFunder,founderValue);
        robottradingToken.emitTokens(accFounder, founderValue);
    }

     
    function sendLimitTokensToFounder(uint _round, uint _value) onlyManager whenInitialized {
        require(roundData[_round].soldTokens>=1);

        uint icoToken = add(roundData[_round].soldTokens,roundData[_round].sendTokens);
        uint icoSupply = roundData[_round].supply;

        uint founderReward = sub(icoSupply, icoToken);
        uint founderValue = mul(_value, BASE);  

        require(founderReward >= founderValue);

        roundData[_round].sendTokens = add(roundData[_round].sendTokens, founderValue);
        tokensToFunder = add(tokensToFunder,founderValue);
        robottradingToken.emitTokens(accFounder, founderValue);
    }

     
    function incSupply(uint _percent) onlyManager whenInitialized {
        require(_percent<=35);
        supplyLimit = add(supplyLimit,mulByFraction(supplyLimit, _percent, 100));
    }

}