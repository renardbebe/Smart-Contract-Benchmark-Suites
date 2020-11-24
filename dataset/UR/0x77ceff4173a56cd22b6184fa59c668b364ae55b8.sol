 

pragma solidity ^0.4.11;

 
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;
    uint constant preIcoPrice = 4101;
    uint constant icoPrice = 2255;

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

     
    function presaleVolumeBonus(uint256 price) internal returns (uint256) {

         
        uint256 val = div(price, preIcoPrice);

        if(val >= 100 * BASE) return add(price, price * 1/20);  
        if(val >= 50 * BASE) return add(price, price * 3/100);  
        if(val >= 20 * BASE) return add(price, price * 1/50);   

        return price;
    }

     
    function volumeBonus(uint256 etherValue) internal returns (uint256) {

        if(etherValue >= 1000000000000000000000) return 15; 
        if(etherValue >=  500000000000000000000) return 10;  
        if(etherValue >=  300000000000000000000) return 7;   
        if(etherValue >=  100000000000000000000) return 5;   
        if(etherValue >=   50000000000000000000) return 3;    
        if(etherValue >=   20000000000000000000) return 2;    

        return 0;
    }

     
    function dateBonus(uint startIco) internal returns (uint256) {

         
        uint daysFromStart = (now - startIco) / DAY_IN_SECONDS + 1;

        if(daysFromStart == 1) return 15;  
        if(daysFromStart == 2) return 10;  
        if(daysFromStart == 3) return 10;  
        if(daysFromStart == 4) return 5;   
        if(daysFromStart == 5) return 5;   
        if(daysFromStart == 6) return 5;   

         
        return 0;
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


contract CarTaxiToken is StandardToken, SafeMath {
     
    string public constant name = "CarTaxi";
    string public constant symbol = "CTX";
    uint public constant decimals = 18;

     

    address public icoContract = 0x0;
     

    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }

     

     
     
    function CarTaxiToken(address _icoContract) {
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


contract CarTaxiIco is SafeMath {
     
    CarTaxiToken public cartaxiToken;
    AbstractToken public preIcoToken;

    enum State{
        Pause,
        Init,
        Running,
        Stopped,
        Migrated
    }

    State public currentState = State.Pause;

    uint public startIcoDate = 0;

     
    address public escrow;
     
    address public icoManager;
     
    address public tokenImporter = 0x0;
     
    address public founder1;
    address public founder2;
    address public founder3;
    address public founder4;
    address public bountyOwner;

     
    uint public constant supplyLimit = 487500000000000000000000000;

     
    uint public constant bountyOwnersTokens = 12500000000000000000000000;

     
    uint public constant PRICE = 2255;

     
    uint constant BASE = 1000000000000000000;

     
     
    uint public foundersRewardTime = 1517727600;

     
    uint public importedTokens = 0;
     
    uint public soldTokensOnIco = 0;
     
    uint public constant soldTokensOnPreIco = 12499847802447308000000000;
     
    bool public sentTokensToFounders = false;
     
    bool public sentTokensToBountyOwner = false;

    uint public etherRaised = 0;

     

    modifier whenInitialized() {
         
        require(currentState >= State.Init);
        _;
    }

    modifier onlyManager() {
         
        require(msg.sender == icoManager);
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

    modifier onlyImporter() {
         
        require(msg.sender == tokenImporter);
        _;
    }

     
     
     
    function CarTaxiIco(address _icoManager, address _preIcoToken) {
        assert(_preIcoToken != 0x0);
        assert(_icoManager != 0x0);

        cartaxiToken = new CarTaxiToken(this);
        icoManager = _icoManager;
        preIcoToken = AbstractToken(_preIcoToken);
    }

     
     
     
     
     
     
     
    function init(address _founder1, address _founder2, address _founder3, address _founder4, address _escrow) onlyManager {
        assert(currentState != State.Init);
        assert(_founder1 != 0x0);
        assert(_founder2 != 0x0);
        assert(_founder3 != 0x0);
        assert(_founder4 != 0x0);
        assert(_escrow != 0x0);

        founder1 = _founder1;
        founder2 = _founder2;
        founder3 = _founder3;
        founder4 = _founder4;
        escrow = _escrow;

        currentState = State.Init;
    }

     
     
    function setState(State _newState) public onlyManager
    {
        currentState = _newState;
        if(currentState == State.Running) {
            startIcoDate = now;
        }
    }

     
     
    function setNewManager(address _newIcoManager) onlyManager {
        assert(_newIcoManager != 0x0);
        icoManager = _newIcoManager;
    }

     
     
    function setBountyOwner(address _bountyOwner) onlyManager {
        assert(_bountyOwner != 0x0);
        bountyOwner = _bountyOwner;
    }

     
    mapping (address => bool) private importedFromPreIco;

     
     
    function importTokens(address _account) {
         
        require(msg.sender == icoManager || msg.sender == _account);
        require(!importedFromPreIco[_account]);

        uint preIcoBal = preIcoToken.balanceOf(_account);
        uint preIcoBalance = presaleVolumeBonus(preIcoBal);

        if (preIcoBalance > 0) {
            cartaxiToken.emitTokens(_account, preIcoBalance);
            importedTokens = add(importedTokens, preIcoBalance);
        }

        importedFromPreIco[_account] = true;
    }

     
     
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);

        uint tokensToEmit = msg.value * PRICE;
         
        uint dateBonusPercent = dateBonus(startIcoDate);
         
        uint volumeBonusPercent = volumeBonus(msg.value);
         
        uint totalBonusPercent = dateBonusPercent + volumeBonusPercent;

        if(totalBonusPercent > 0){
            tokensToEmit =  tokensToEmit + mulByFraction(tokensToEmit, totalBonusPercent, 100);
        }

        require(add(soldTokensOnIco, tokensToEmit) <= supplyLimit);

        soldTokensOnIco = add(soldTokensOnIco, tokensToEmit);

         
        cartaxiToken.emitTokens(_buyer, tokensToEmit);

        etherRaised = add(etherRaised, msg.value);
    }

     
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }

     
     
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        cartaxiToken.burnTokens(_from, _value);
    }

     
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        assert(_value <= this.balance);
         
        escrow.transfer(_value * 10000000000000000);  
    }

     
    function withdrawAllEther() onlyManager {
        if(this.balance > 0)
        {
            escrow.transfer(this.balance);
        }
    }

     
    function sendTokensToBountyOwner() onlyManager whenInitialized {
        require(!sentTokensToBountyOwner);

         
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

         
        uint bountyTokens = mulByFraction(tokensSold, 25, 1000);  

        cartaxiToken.emitTokens(bountyOwner, bountyTokens);

        sentTokensToBountyOwner = true;
    }

     
    function sendTokensToFounders() onlyManager whenInitialized {
        require(!sentTokensToFounders && now >= foundersRewardTime);

         
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

         
        uint totalRewardToFounders = mulByFraction(tokensSold, 3166, 10000);  

        uint founderReward = mulByFraction(totalRewardToFounders, 25, 100);  

         
        cartaxiToken.emitTokens(founder1, founderReward);
        cartaxiToken.emitTokens(founder2, founderReward);
        cartaxiToken.emitTokens(founder3, founderReward);
        cartaxiToken.emitTokens(founder4, founderReward);

        sentTokensToFounders = true;
    }
}