 

pragma solidity ^0.4.19;

 
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;

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

     
    function dateBonus(uint startIco) internal returns (uint256) {

         
        uint daysFromStart = (now - startIco) / DAY_IN_SECONDS + 1;

        if(daysFromStart >= 1  && daysFromStart <= 14) return 20;  
        if(daysFromStart >= 15 && daysFromStart <= 28) return 15;  
        if(daysFromStart >= 29 && daysFromStart <= 42) return 10;  
        if(daysFromStart >= 43)                        return 5;   

         
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


contract ShiftCashToken is StandardToken, SafeMath {
     
    string public constant name = "ShiftCashToken";
    string public constant symbol = "SCASH";
    uint public constant decimals = 18;

     

    address public icoContract = 0x0;
     

    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }

     

     
     
    function ShiftCashToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
        totalSupply = 0;
    }

     
     
     
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
        totalSupply = sub(totalSupply, _value);
    }

     
     
     
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = add(balances[_to], _value);

        totalSupply = add(totalSupply, _value);

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

        Transfer(msg.sender, _to, _value);

    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}


contract ShiftCashIco is SafeMath {
     
    ShiftCashToken public shiftcashToken;
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
    address public bountyOwner;


     
    uint constant BASE = 1000000000000000000;

     
    uint public constant supplyLimit = 5778000 * BASE;

     
    uint public constant bountyOwnersTokens = 86670 * BASE;

     
    uint public constant PRICE = 450;

     
     
    uint public foundersRewardTime = 1530774000;

     
    uint public importedTokens = 0;
     
    uint public soldTokensOnIco = 0;
     
    uint public constant soldTokensOnPreIco = 69990267262342250546086;
     
    bool public sentTokensToFounder = false;
     
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

     
     
     
    function ShiftCashIco(address _icoManager, address _preIcoToken) {
        assert(_preIcoToken != 0x0);
        assert(_icoManager != 0x0);

        shiftcashToken = new ShiftCashToken(this);
        icoManager = _icoManager;
        preIcoToken = AbstractToken(_preIcoToken);
    }

     
     
     
     
    function init(address _founder1, address _escrow) onlyManager {
        assert(currentState != State.Init);
        assert(_founder1 != 0x0);
        assert(_escrow != 0x0);
        founder1 = _founder1;
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

        uint preIcoBalance = preIcoToken.balanceOf(_account);

        if (preIcoBalance > 0) {
            shiftcashToken.emitTokens(_account, preIcoBalance);
            importedTokens = add(importedTokens, preIcoBalance);
        }

        importedFromPreIco[_account] = true;
    }

     
     
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);

        uint tokensToEmit = msg.value * PRICE;
         
        uint bonusPercent = dateBonus(startIcoDate);
         

        if(bonusPercent > 0){
            tokensToEmit =  tokensToEmit + mulByFraction(tokensToEmit, bonusPercent, 100);
        }

        require(add(soldTokensOnIco, tokensToEmit) <= supplyLimit);

        soldTokensOnIco = add(soldTokensOnIco, tokensToEmit);

         
        shiftcashToken.emitTokens(_buyer, tokensToEmit);

        etherRaised = add(etherRaised, msg.value);

        if(this.balance > 0) {
            require(escrow.send(this.balance));
        }

    }

     
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }

     
     
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        shiftcashToken.burnTokens(_from, _value);
    }

     
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        escrow.transfer(_value);
    }

     
    function withdrawAllEther() onlyManager {
        if(this.balance > 0) {
            escrow.transfer(this.balance);
        }
    }

     
    function sendTokensToBountyOwner() onlyManager whenInitialized {
        require(!sentTokensToBountyOwner);

         
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

         
        uint bountyTokens = mulByFraction(tokensSold, 15, 1000);  

        shiftcashToken.emitTokens(bountyOwner, bountyTokens);

        sentTokensToBountyOwner = true;
    }

     
    function sendTokensToFounders() onlyManager whenInitialized {
        require(!sentTokensToFounder && now >= foundersRewardTime);

         
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

         
        uint totalRewardToFounder = mulByFraction(tokensSold, 1000, 10000);  

        shiftcashToken.emitTokens(founder1, totalRewardToFounder);

        sentTokensToFounder = true;
    }
}