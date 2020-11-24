 

pragma solidity ^0.4.11;

 
contract SafeMath {
    function mul(uint a, uint b) constant internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) constant internal returns (uint) {
        assert(b != 0);  
        uint c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }

    function sub(uint a, uint b) constant internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) constant internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

     
    function volumeBonus(uint etherValue) constant internal returns (uint) {

        if(etherValue >=  500000000000000000000) return 10;  
        if(etherValue >=  300000000000000000000) return 7;   
        if(etherValue >=  100000000000000000000) return 5;   
        if(etherValue >=   50000000000000000000) return 3;   
        if(etherValue >=   20000000000000000000) return 2;   
        if(etherValue >=   10000000000000000000) return 1;   

        return 0;
    }

}


 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint) {}
    function balanceOf(address owner) constant returns (uint balance);
    function transfer(address to, uint value) returns (bool success);
    function transferFrom(address from, address to, uint value) returns (bool success);
    function approve(address spender, uint value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint remaining);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Issuance(address indexed to, uint value);
}

contract IcoLimits {
    uint constant privateSaleStart = 1511740800;  
    uint constant privateSaleEnd   = 1512172799;  

    uint constant presaleStart     = 1512172800;  
    uint constant presaleEnd       = 1513987199;  

    uint constant publicSaleStart  = 1516320000;  
    uint constant publicSaleEnd    = 1521158399;  

    uint constant foundersTokensUnlock = 1558310400;  

    modifier afterPublicSale() {
        require(now > publicSaleEnd);
        _;
    }

    uint constant privateSalePrice = 4000;  
    uint constant preSalePrice     = 3000;  
    uint constant publicSalePrice  = 2000;  

    uint constant privateSaleSupplyLimit =  600  * privateSalePrice * 1000000000000000000;
    uint constant preSaleSupplyLimit     =  1200 * preSalePrice     * 1000000000000000000;
    uint constant publicSaleSupplyLimit  =  5000 * publicSalePrice  * 1000000000000000000;
}

contract StandardToken is AbstractToken, IcoLimits {
     
    mapping (address => uint) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint)) allowed;

    uint public totalSupply;

    address[] public owners;

     
     
     
     
    function transfer(address _to, uint _value) afterPublicSale returns (bool success) {
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

     
     
     
     
    function transferFrom(address _from, address _to, uint _value) afterPublicSale returns (bool success) {
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

     
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract ExoTownToken is StandardToken, SafeMath {

     

    string public constant name = "ExoTown token";
    string public constant symbol = "SNEK";
    uint public constant decimals = 18;

    address public icoContract = 0x0;


     

    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }


     

     
     
    function ExoTownToken(address _icoContract) {
        require(_icoContract != 0x0);
        icoContract = _icoContract;
    }

     
     
     
    function burnTokens(address _from, uint _value) onlyIcoContract {
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
        totalSupply -= _value;
    }

     
     
     
    function emitTokens(address _to, uint _value) onlyIcoContract {
        require(totalSupply + _value >= totalSupply);
        balances[_to] = add(balances[_to], _value);
        totalSupply += _value;

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

        Transfer(0x0, _to, _value);

    }

    function getOwner(uint index) constant returns (address, uint) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}


contract ExoTownIco is SafeMath, IcoLimits {

     
    ExoTownToken public exotownToken;

    enum State {
        Pause,
        Running
    }

    State public currentState = State.Pause;

    uint public privateSaleSoldTokens = 0;
    uint public preSaleSoldTokens     = 0;
    uint public publicSaleSoldTokens  = 0;

    uint public privateSaleEtherRaised = 0;
    uint public preSaleEtherRaised     = 0;
    uint public publicSaleEtherRaised  = 0;

     
    address public icoManager;
    address public founderWallet;

     
    address public buyBack;

     
    address public developmentWallet;
    address public marketingWallet;
    address public teamWallet;

    address public bountyOwner;

     
    address public mediatorWallet;

    bool public sentTokensToBountyOwner = false;
    bool public sentTokensToFounders = false;

    

     

    modifier whenInitialized() {
         
        require(currentState >= State.Running);
        _;
    }

    modifier onlyManager() {
         
        require(msg.sender == icoManager);
        _;
    }

    modifier onIco() {
        require( isPrivateSale() || isPreSale() || isPublicSale() );
        _;
    }

    modifier hasBountyCampaign() {
        require(bountyOwner != 0x0);
        _;
    }

    function isPrivateSale() constant internal returns (bool) {
        return now >= privateSaleStart && now <= privateSaleEnd;
    }

    function isPreSale() constant internal returns (bool) {
        return now >= presaleStart && now <= presaleEnd;
    }

    function isPublicSale() constant internal returns (bool) {
        return now >= publicSaleStart && now <= publicSaleEnd;
    }







    function getPrice() constant internal returns (uint) {
        if (isPrivateSale()) return privateSalePrice;
        if (isPreSale()) return preSalePrice;
        if (isPublicSale()) return publicSalePrice;

        return publicSalePrice;
    }

    function getStageSupplyLimit() constant returns (uint) {
        if (isPrivateSale()) return privateSaleSupplyLimit;
        if (isPreSale()) return preSaleSupplyLimit;
        if (isPublicSale()) return publicSaleSupplyLimit;

        return 0;
    }

    function getStageSoldTokens() constant returns (uint) {
        if (isPrivateSale()) return privateSaleSoldTokens;
        if (isPreSale()) return preSaleSoldTokens;
        if (isPublicSale()) return publicSaleSoldTokens;

        return 0;
    }

    function addStageTokensSold(uint _amount) internal {
        if (isPrivateSale()) privateSaleSoldTokens = add(privateSaleSoldTokens, _amount);
        if (isPreSale())     preSaleSoldTokens = add(preSaleSoldTokens, _amount);
        if (isPublicSale())  publicSaleSoldTokens = add(publicSaleSoldTokens, _amount);
    }

    function addStageEtherRaised(uint _amount) internal {
        if (isPrivateSale()) privateSaleEtherRaised = add(privateSaleEtherRaised, _amount);
        if (isPreSale())     preSaleEtherRaised = add(preSaleEtherRaised, _amount);
        if (isPublicSale())  publicSaleEtherRaised = add(publicSaleEtherRaised, _amount);
    }

    function getStageEtherRaised() constant returns (uint) {
        if (isPrivateSale()) return privateSaleEtherRaised;
        if (isPreSale())     return preSaleEtherRaised;
        if (isPublicSale())  return publicSaleEtherRaised;

        return 0;
    }

    function getTokensSold() constant returns (uint) {
        return
            privateSaleSoldTokens +
            preSaleSoldTokens +
            publicSaleSoldTokens;
    }

    function getEtherRaised() constant returns (uint) {
        return
            privateSaleEtherRaised +
            preSaleEtherRaised +
            publicSaleEtherRaised;
    }















     
     
    function ExoTownIco(address _icoManager) {
        require(_icoManager != 0x0);

        exotownToken = new ExoTownToken(this);
        icoManager = _icoManager;
    }

     
     
     
     
     
     
     

    function init(
        address _founder,
        address _dev,
        address _pr,
        address _team,
        address _buyback,
        address _mediator
    ) onlyManager {
        require(currentState == State.Pause);
        require(_founder != 0x0);
        require(_dev != 0x0);
        require(_pr != 0x0);
        require(_team != 0x0);
        require(_buyback != 0x0);
        require(_mediator != 0x0);

        founderWallet = _founder;
        developmentWallet = _dev;
        marketingWallet = _pr;
        teamWallet = _team;
        buyBack = _buyback;
        mediatorWallet = _mediator;

        currentState = State.Running;

        exotownToken.emitTokens(icoManager, 0);
    }

     
     
    function setState(State _newState) public onlyManager {
        currentState = _newState;
    }

     
     
    function setNewManager(address _newIcoManager) onlyManager {
        require(_newIcoManager != 0x0);
        icoManager = _newIcoManager;
    }

     
     
    function setBountyCampaign(address _bountyOwner) onlyManager {
        require(_bountyOwner != 0x0);
        bountyOwner = _bountyOwner;
    }

     
     
    function setNewMediator(address _mediator) onlyManager {
        require(_mediator != 0x0);
        mediatorWallet = _mediator;
    }


     
     
    function buyTokens(address _buyer) private {
        require(_buyer != 0x0);
        require(msg.value > 0);

        uint tokensToEmit = msg.value * getPrice();
        uint volumeBonusPercent = volumeBonus(msg.value);

        if (volumeBonusPercent > 0) {
            tokensToEmit = mul(tokensToEmit, 100 + volumeBonusPercent) / 100;
        }

        uint stageSupplyLimit = getStageSupplyLimit();
        uint stageSoldTokens = getStageSoldTokens();

        require(add(stageSoldTokens, tokensToEmit) <= stageSupplyLimit);

        exotownToken.emitTokens(_buyer, tokensToEmit);

         
        addStageTokensSold(tokensToEmit);
        addStageEtherRaised(msg.value);

        distributeEtherByStage();

    }

     
    function giftToken(address _to) public payable onIco {
        buyTokens(_to);
    }

     
    function () payable onIco {
        buyTokens(msg.sender);
    }

    function distributeEtherByStage() private {
        uint _balance = this.balance;
        uint _balance_div = _balance / 100;

        uint _devAmount = _balance_div * 65;
        uint _prAmount = _balance_div * 25;

        uint total = _devAmount + _prAmount;
        if (total > 0) {
             
             

            uint _mediatorAmount = _devAmount / 100;
            mediatorWallet.transfer(_mediatorAmount);

            developmentWallet.transfer(_devAmount - _mediatorAmount);
            marketingWallet.transfer(_prAmount);
            teamWallet.transfer(_balance - _devAmount - _prAmount);
        }
    }


     
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        require(_value * 1000000000000000 <= this.balance);
         
        icoManager.transfer(_value * 1000000000000000);  
    }

     
    function sendTokensToBountyOwner() onlyManager whenInitialized hasBountyCampaign afterPublicSale {
        require(!sentTokensToBountyOwner);

         
        uint bountyTokens = getTokensSold() / 40;  

        exotownToken.emitTokens(bountyOwner, bountyTokens);

        sentTokensToBountyOwner = true;
    }

     
    function sendTokensToFounders() onlyManager whenInitialized afterPublicSale {
        require(!sentTokensToFounders);
        require(now >= foundersTokensUnlock);

         
        uint founderReward = getTokensSold() / 10;  

        exotownToken.emitTokens(founderWallet, founderReward);

        sentTokensToFounders = true;
    }

     
    function burnTokens(uint _amount) afterPublicSale {
        exotownToken.burnTokens(buyBack, _amount);
    }
}