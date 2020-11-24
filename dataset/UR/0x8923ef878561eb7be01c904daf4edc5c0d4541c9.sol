 

 

pragma solidity ^0.4.11;



 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

}
 


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 

 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        if (halted) throw;
        _;
    }

    modifier stopNonOwnersInEmergency {
        if (halted && msg.sender != owner) throw;
        _;
    }

    modifier onlyInEmergency {
        if (!halted) throw;
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}


 

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



 



 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, SafeMath {

     
    event Minted(address receiver, uint amount);

     
    mapping(address => uint) balances;

     
    mapping (address => mapping (address => uint)) allowed;

     
    function isToken() public constant returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint _value) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {

         
         
         
         
        require ((_value != 0) && (allowed[msg.sender][_spender] != 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

 





 



 
contract UpgradeAgent {

    uint public originalSupply;

     
    function isUpgradeAgent() public constant returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

     
    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

     
    uint256 public totalUpgraded;

     
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event UpgradeAgentSet(address agent);

     
    function UpgradeableToken(address _upgradeMaster) {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
        require(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));

         
        require (value == 0);

        balances[msg.sender] = safeSub(balances[msg.sender], value);

         
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function setUpgradeAgent(address agent) external {

        require(!canUpgrade());  

        require(agent == 0x0);
         
        require(msg.sender != upgradeMaster);
         
        require(getUpgradeState() == UpgradeState.Upgrading);

        upgradeAgent = UpgradeAgent(agent);

         
        require(!upgradeAgent.isUpgradeAgent());
         
        require(upgradeAgent.originalSupply() != totalSupply);

        UpgradeAgentSet(upgradeAgent);
    }

     
    function getUpgradeState() public constant returns(UpgradeState) {
        if(!canUpgrade()) return UpgradeState.NotAllowed;
        else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        require(master == 0x0);
        require(msg.sender != upgradeMaster);
        upgradeMaster = master;
    }

     
    function canUpgrade() public constant returns(bool) {
        return true;
    }

}

 




 
contract MintableTokenExt is StandardToken, Ownable {

    using SMathLib for uint;

    bool public mintingFinished = false;

     
    mapping (address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state  );

     
    struct ReservedTokensData {
        uint inTokens;
        uint inPercentageUnit;
        uint inPercentageDecimals;
    }

    mapping (address => ReservedTokensData) public reservedTokensList;
    address[] public reservedTokensDestinations;
    uint public reservedTokensDestinationsLen = 0;

    function setReservedTokensList(address addr, uint inTokens, uint inPercentageUnit, uint inPercentageDecimals) onlyOwner {
        reservedTokensDestinations.push(addr);
        reservedTokensDestinationsLen++;
        reservedTokensList[addr] = ReservedTokensData({inTokens:inTokens, inPercentageUnit:inPercentageUnit, inPercentageDecimals: inPercentageDecimals});
    }

    function getReservedTokensListValInTokens(address addr) constant returns (uint inTokens) {
        return reservedTokensList[addr].inTokens;
    }

    function getReservedTokensListValInPercentageUnit(address addr) constant returns (uint inPercentageUnit) {
        return reservedTokensList[addr].inPercentageUnit;
    }

    function getReservedTokensListValInPercentageDecimals(address addr) constant returns (uint inPercentageDecimals) {
        return reservedTokensList[addr].inPercentageDecimals;
    }

    function setReservedTokensListMultiple(address[] addrs, uint[] inTokens, uint[] inPercentageUnit, uint[] inPercentageDecimals) onlyOwner {
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            setReservedTokensList(addrs[iterator], inTokens[iterator], inPercentageUnit[iterator], inPercentageDecimals[iterator]);
        }
    }

     
    function mint(address receiver, uint amount) onlyMintAgent canMint public {
        totalSupply = totalSupply.plus(amount);
        balances[receiver] = balances[receiver].plus(amount);

         
         
        Transfer(0, receiver, amount);
    }

     
    function setMintAgent(address addr, bool state) onlyOwner canMint public {
        mintAgents[addr] = state;
        MintingAgentChanged(addr, state);
    }

    modifier onlyMintAgent() {
         
        if(!mintAgents[msg.sender]) {
            revert();
        }
        _;
    }

     
    modifier canMint() {
        if(mintingFinished) {
            revert();
        }
        _;
    }
}
 



 
contract ReleasableToken is ERC20, Ownable {

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {

        if(!released) {
            if(!transferAgents[_sender]) {
                revert();
            }
        }

        _;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

         
        releaseAgent = addr;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        transferAgents[addr] = state;
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

     
    modifier inReleaseState(bool releaseState) {
        if(releaseState != released) {
            revert();
        }
        _;
    }

     
    modifier onlyReleaseAgent() {
        if(msg.sender != releaseAgent) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

}

 






contract BurnableToken is StandardToken {

    using SMathLib for uint;
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].minus(_value);
        totalSupply = totalSupply.minus(_value);
        Burn(burner, _value);
    }
}




 
contract CrowdsaleTokenExt is ReleasableToken, MintableTokenExt, BurnableToken, UpgradeableToken {

     
    event UpdatedTokenInformation(string newName, string newSymbol);

    string public name;

    string public symbol;

    uint public decimals;

     
    uint public minCap;


     
    function CrowdsaleTokenExt(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap)
    UpgradeableToken(msg.sender) {

         
         
         
        owner = msg.sender;

        name = _name;
        symbol = _symbol;

        totalSupply = _initialSupply;

        decimals = _decimals;

        minCap = _globalMinCap;

         
        balances[owner] = totalSupply;

        if(totalSupply > 0) {
            Minted(owner, totalSupply);
        }

         
        if(!_mintable) {
            mintingFinished = true;
            if(totalSupply == 0) {
                revert();  
            }
        }
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        super.releaseTokenTransfer();
    }

     
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade();
    }

     
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name;
        symbol = _symbol;

        UpdatedTokenInformation(name, symbol);
    }

}


contract MjtToken is CrowdsaleTokenExt {

    uint public ownersProductCommissionInPerc = 5;

    uint public operatorProductCommissionInPerc = 25;

    event IndependentSellerJoined(address sellerWallet, uint amountOfTokens, address operatorWallet);
    event OwnersProductAdded(address ownersWallet, uint amountOfTokens, address operatorWallet);
    event OperatorProductCommissionChanged(uint _value);
    event OwnersProductCommissionChanged(uint _value);


    function setOperatorCommission(uint _value) public onlyOwner {
        require(_value >= 0);
        operatorProductCommissionInPerc = _value;
        OperatorProductCommissionChanged(_value);
    }

    function setOwnersCommission(uint _value) public onlyOwner {
        require(_value >= 0);
        ownersProductCommissionInPerc = _value;
        OwnersProductCommissionChanged(_value);
    }


     
    function independentSellerJoined(address sellerWallet, uint amountOfTokens, address operatorWallet) public onlyOwner canMint {
        require(amountOfTokens > 100);
        require(sellerWallet != address(0));
        require(operatorWallet != address(0));

        uint operatorCommission = amountOfTokens.divides(100).times(operatorProductCommissionInPerc);
        uint sellerAmount = amountOfTokens.minus(operatorCommission);

        if (operatorCommission > 0) {
            mint(operatorWallet, operatorCommission);
        }

        if (sellerAmount > 0) {
            mint(sellerWallet, sellerAmount);
        }
        IndependentSellerJoined(sellerWallet, amountOfTokens, operatorWallet);
    }


     
    function ownersProductAdded(address ownersWallet, uint amountOfTokens, address operatorWallet) public onlyOwner canMint {
        require(amountOfTokens > 100);
        require(ownersWallet != address(0));
        require(operatorWallet != address(0));

        uint ownersComission = amountOfTokens.divides(100).times(ownersProductCommissionInPerc);
        uint operatorAmount = amountOfTokens.minus(ownersComission);


        if (ownersComission > 0) {
            mint(ownersWallet, ownersComission);
        }

        if (operatorAmount > 0) {
            mint(operatorWallet, operatorAmount);
        }

        OwnersProductAdded(ownersWallet, amountOfTokens, operatorWallet);
    }

    function MjtToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap)
    CrowdsaleTokenExt(_name, _symbol, _initialSupply, _decimals, _mintable, _globalMinCap) {}

}




 
contract FinalizeAgent {

    function isFinalizeAgent() public constant returns(bool) {
        return true;
    }

     
    function isSane() public constant returns (bool);

     
    function finalizeCrowdsale();

}

 


 
contract PricingStrategy {

     
    function isPricingStrategy() public constant returns (bool) {
        return true;
    }

     
    function isSane(address crowdsale) public constant returns (bool) {
        return true;
    }

     
    function isPresalePurchase(address purchaser) public constant returns (bool) {
        return false;
    }

     
    function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}



 
contract MilestonePricing is PricingStrategy, Ownable {

    using SMathLib for uint;

    uint public constant MAX_MILESTONE = 10;

     
    mapping (address => uint) public preicoAddresses;

     
    struct Milestone {

         
        uint time;

         
        uint price;
    }

     
     
     
    Milestone[10] public milestones;

     
    uint public milestoneCount;

     
     
    function MilestonePricing(uint[] _milestones) {
         
        if(_milestones.length % 2 == 1 || _milestones.length >= MAX_MILESTONE*2) {
            throw;
        }

        milestoneCount = _milestones.length / 2;

        uint lastTimestamp = 0;

        for(uint i=0; i<_milestones.length/2; i++) {
            milestones[i].time = _milestones[i*2];
            milestones[i].price = _milestones[i*2+1];

             
            if((lastTimestamp != 0) && (milestones[i].time <= lastTimestamp)) {
                throw;
            }

            lastTimestamp = milestones[i].time;
        }

         
        if(milestones[milestoneCount-1].price != 0) {
            throw;
        }
    }

     
     
     
     
    function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
    {
        preicoAddresses[preicoAddress] = pricePerToken;
    }

     
     
    function getMilestone(uint n) public constant returns (uint, uint) {
        return (milestones[n].time, milestones[n].price);
    }

    function getFirstMilestone() private constant returns (Milestone) {
        return milestones[0];
    }

    function getLastMilestone() private constant returns (Milestone) {
        return milestones[milestoneCount-1];
    }

    function getPricingStartsAt() public constant returns (uint) {
        return getFirstMilestone().time;
    }

    function getPricingEndsAt() public constant returns (uint) {
        return getLastMilestone().time;
    }

    function isSane(address _crowdsale) public constant returns(bool) {
        CrowdsaleExt crowdsale = CrowdsaleExt(_crowdsale);
        return crowdsale.startsAt() == getPricingStartsAt() && crowdsale.endsAt() == getPricingEndsAt();
    }

     
     
    function getCurrentMilestone() private constant returns (Milestone) {
        uint i;

        for(i=0; i<milestones.length; i++) {
            if(now < milestones[i].time) {
                return milestones[i-1];
            }
        }
    }

     
     
    function getCurrentPrice() public constant returns (uint result) {
        return getCurrentMilestone().price;
    }

     
    function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

        uint multiplier = 10 ** decimals;

         
        if(preicoAddresses[msgSender] > 0) {
            return value.times(multiplier) / preicoAddresses[msgSender];
        }

        uint price = getCurrentPrice();
        return value.times(multiplier) / price;
    }

    function isPresalePurchase(address purchaser) public constant returns (bool) {
        if(preicoAddresses[purchaser] > 0)
            return true;
        else
            return false;
    }

    function() payable {
        throw;  
    }

}



 
contract FractionalERC20Ext is ERC20 {

    uint public decimals;
    uint public minCap;

}



 
contract CrowdsaleExt is Haltable {

     
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SMathLib for uint;

     
    FractionalERC20Ext public token;

     
    MilestonePricing public pricingStrategy;

     
    FinalizeAgent public finalizeAgent;

     
    address public multisigWallet;

     
    uint public minimumFundingGoal;

     
    uint public startsAt;

     
    uint public endsAt;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public presaleWeiRaised = 0;

     
    uint public investorCount = 0;

     
    uint public loadedRefund = 0;

     
    uint public weiRefunded = 0;

     
    bool public finalized;

     
    bool public requireCustomerId;

    bool public isWhiteListed;

    address[] public joinedCrowdsales;
    uint public joinedCrowdsalesLen = 0;

    address public lastCrowdsale;

     
    bool public requiredSignedAddress;

     
    address public signerAddress;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

    struct WhiteListData {
        bool status;
        uint minCap;
        uint maxCap;
    }

     
    bool public isUpdatable;

     
    mapping (address => WhiteListData) public earlyParticipantWhitelist;

     
    uint public ownerTestValue;

     
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

     
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

     
    event Refund(address investor, uint weiAmount);

     
    event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

     
    event Whitelisted(address addr, bool status);

     
    event StartsAtChanged(uint newStartsAt);

     
    event EndsAtChanged(uint newEndsAt);

    function CrowdsaleExt(address _token, MilestonePricing _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, bool _isUpdatable, bool _isWhiteListed) {

        owner = msg.sender;

        token = FractionalERC20Ext(_token);

        setPricingStrategy(_pricingStrategy);

        multisigWallet = _multisigWallet;
        if(multisigWallet == 0) {
            throw;
        }

        if(_start == 0) {
            throw;
        }

        startsAt = _start;

        if(_end == 0) {
            throw;
        }

        endsAt = _end;

         
        if(startsAt >= endsAt) {
            throw;
        }

         
        minimumFundingGoal = _minimumFundingGoal;

        isUpdatable = _isUpdatable;

        isWhiteListed = _isWhiteListed;
    }

     
    function() payable {
        throw;
    }

     
    function investInternal(address receiver, uint128 customerId) stopInEmergency private {

         
        if(getState() == State.PreFunding) {
             
            throw;
        } else if(getState() == State.Funding) {
             
             
            if(isWhiteListed) {
                if(!earlyParticipantWhitelist[receiver].status) {
                    throw;
                }
            }
        } else {
             
            throw;
        }

        uint weiAmount = msg.value;

         
        uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

        if(tokenAmount == 0) {
             
            throw;
        }

        if(isWhiteListed) {
            if(tokenAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
                 
                throw;
            }
            if(tokenAmount > earlyParticipantWhitelist[receiver].maxCap) {
                 
                throw;
            }

             
            if (isBreakingInvestorCap(receiver, tokenAmount)) {
                throw;
            }
        } else {
            if(tokenAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
                throw;
            }
        }

        if(investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

         
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        if(pricingStrategy.isPresalePurchase(receiver)) {
            presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
        }

         
        if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
            throw;
        }

        assignTokens(receiver, tokenAmount);

         
        if(!multisigWallet.send(weiAmount)) throw;

        if (isWhiteListed) {
            uint num = 0;
            for (var i = 0; i < joinedCrowdsalesLen; i++) {
                if (this == joinedCrowdsales[i])
                    num = i;
            }

            if (num + 1 < joinedCrowdsalesLen) {
                for (var j = num + 1; j < joinedCrowdsalesLen; j++) {
                    CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
                    crowdsale.updateEarlyParicipantWhitelist(msg.sender, this, tokenAmount);
                }
            }
        }

         
        Invested(receiver, weiAmount, tokenAmount, customerId);
    }

     
    function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

        uint tokenAmount = fullTokens * 10**token.decimals();
        uint weiAmount = weiPrice * fullTokens;  

        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

        assignTokens(receiver, tokenAmount);

         
        Invested(receiver, weiAmount, tokenAmount, 0);
    }

     
    function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
        bytes32 hash = sha256(addr);
        if (ecrecover(hash, v, r, s) != signerAddress) throw;
        if(customerId == 0) throw;   
        investInternal(addr, customerId);
    }

     
    function investWithCustomerId(address addr, uint128 customerId) public payable {
        if(requiredSignedAddress) throw;  
        if(customerId == 0) throw;   
        investInternal(addr, customerId);
    }

     
    function invest(address addr) public payable {
        if(requireCustomerId) throw;  
        if(requiredSignedAddress) throw;  
        investInternal(addr, 0);
    }

     
    function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
        investWithSignedAddress(msg.sender, customerId, v, r, s);
    }

     
    function buyWithCustomerId(uint128 customerId) public payable {
        investWithCustomerId(msg.sender, customerId);
    }

     
    function buy() public payable {
        invest(msg.sender);
    }

     
    function finalize() public inState(State.Success) onlyOwner stopInEmergency {

         
        if(finalized) {
            throw;
        }

         
        if(address(finalizeAgent) != 0) {
            finalizeAgent.finalizeCrowdsale();
        }

        finalized = true;
    }

     
    function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
        finalizeAgent = addr;

         
        if(!finalizeAgent.isFinalizeAgent()) {
            throw;
        }
    }

     
    function setRequireCustomerId(bool value) onlyOwner {
        requireCustomerId = value;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

     
    function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
        requiredSignedAddress = value;
        signerAddress = _signerAddress;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

     
    function setEarlyParicipantWhitelist(address addr, bool status, uint minCap, uint maxCap) onlyOwner {
        if (!isWhiteListed) throw;
        earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
        Whitelisted(addr, status);
    }

    function setEarlyParicipantsWhitelist(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) onlyOwner {
        if (!isWhiteListed) throw;
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            setEarlyParicipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
        }
    }

    function updateEarlyParicipantWhitelist(address addr, address contractAddr, uint tokensBought) {
        if (tokensBought < earlyParticipantWhitelist[addr].minCap) throw;
        if (!isWhiteListed) throw;
        if (addr != msg.sender && contractAddr != msg.sender) throw;
        uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
        newMaxCap = newMaxCap.minus(tokensBought);
        earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
    }

    function updateJoinedCrowdsales(address addr) onlyOwner {
        joinedCrowdsales[joinedCrowdsalesLen++] = addr;
    }

    function setLastCrowdsale(address addr) onlyOwner {
        lastCrowdsale = addr;
    }

    function clearJoinedCrowdsales() onlyOwner {
        joinedCrowdsalesLen = 0;
    }

    function updateJoinedCrowdsalesMultiple(address[] addrs) onlyOwner {
        clearJoinedCrowdsales();
        for (uint iter = 0; iter < addrs.length; iter++) {
            if(joinedCrowdsalesLen == joinedCrowdsales.length) {
                joinedCrowdsales.length += 1;
            }
            joinedCrowdsales[joinedCrowdsalesLen++] = addrs[iter];
            if (iter == addrs.length - 1)
                setLastCrowdsale(addrs[iter]);
        }
    }

    function setStartsAt(uint time) onlyOwner {
        if (finalized) throw;

        if (!isUpdatable) throw;

        if(now > time) {
            throw;  
        }

        if(time > endsAt) {
            throw;
        }

        CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
        if (lastCrowdsaleCntrct.finalized()) throw;

        startsAt = time;
        StartsAtChanged(startsAt);
    }

     
    function setEndsAt(uint time) onlyOwner {
        if (finalized) throw;

        if (!isUpdatable) throw;

        if(now > time) {
            throw;  
        }

        if(startsAt > time) {
            throw;
        }

        CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
        if (lastCrowdsaleCntrct.finalized()) throw;

        uint num = 0;
        for (var i = 0; i < joinedCrowdsalesLen; i++) {
            if (this == joinedCrowdsales[i])
                num = i;
        }

        if (num + 1 < joinedCrowdsalesLen) {
            for (var j = num + 1; j < joinedCrowdsalesLen; j++) {
                CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
                if (time > crowdsale.startsAt()) throw;
            }
        }

        endsAt = time;
        EndsAtChanged(endsAt);
    }

     
    function setPricingStrategy(MilestonePricing _pricingStrategy) onlyOwner {
        pricingStrategy = _pricingStrategy;

         
        if(!pricingStrategy.isPricingStrategy()) {
            throw;
        }
    }

     
    function setMultisig(address addr) public onlyOwner {

         
        if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
            throw;
        }

        multisigWallet = addr;
    }

     
    function loadRefund() public payable inState(State.Failure) {
        if(msg.value == 0) throw;
        loadedRefund = loadedRefund.plus(msg.value);
    }

     
    function refund() public inState(State.Refunding) {
        uint256 weiValue = investedAmountOf[msg.sender];
        if (weiValue == 0) throw;
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.plus(weiValue);
        Refund(msg.sender, weiValue);
        if (!msg.sender.send(weiValue)) throw;
    }

     
    function isMinimumGoalReached() public constant returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

     
    function isFinalizerSane() public constant returns (bool sane) {
        return finalizeAgent.isSane();
    }

     
    function isPricingSane() public constant returns (bool sane) {
        return pricingStrategy.isSane(address(this));
    }

     
    function getState() public constant returns (State) {
        if(finalized) return State.Finalized;
        else if (address(finalizeAgent) == 0) return State.Preparing;
        else if (!finalizeAgent.isSane()) return State.Preparing;
        else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
        else if (block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
        else if (isMinimumGoalReached()) return State.Success;
        else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
        else return State.Failure;
    }

     
    function setOwnerTestValue(uint val) onlyOwner {
        ownerTestValue = val;
    }

     
    function isCrowdsale() public constant returns (bool) {
        return true;
    }

     
     
     

     
    modifier inState(State state) {
        if(getState() != state) throw;
        _;
    }


     
     
     

     
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

    function isBreakingInvestorCap(address receiver, uint tokenAmount) constant returns (bool limitBroken);

     
    function isCrowdsaleFull() public constant returns (bool);

     
    function assignTokens(address receiver, uint tokenAmount) private;
}


 


contract MintedTokenCappedCrowdsaleExt is CrowdsaleExt {

     
    uint public maximumSellableTokens;

    function MintedTokenCappedCrowdsaleExt(address _token, MilestonePricing _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _maximumSellableTokens, bool _isUpdatable, bool _isWhiteListed) CrowdsaleExt(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal, _isUpdatable, _isWhiteListed) {
        maximumSellableTokens = _maximumSellableTokens;
    }

     
    event MaximumSellableTokensChanged(uint newMaximumSellableTokens);

     
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
        return tokensSoldTotal > maximumSellableTokens;
    }

    function isBreakingInvestorCap(address addr, uint tokenAmount) constant returns (bool limitBroken) {
        if (!isWhiteListed) throw;
        uint maxCap = earlyParticipantWhitelist[addr].maxCap;
        return (tokenAmountOf[addr].plus(tokenAmount)) > maxCap;
    }

    function isCrowdsaleFull() public constant returns (bool) {
        return tokensSold >= maximumSellableTokens;
    }

     
    function assignTokens(address receiver, uint tokenAmount) private {
        CrowdsaleTokenExt mintableToken = CrowdsaleTokenExt(token);
        mintableToken.mint(receiver, tokenAmount);
    }

    function setMaximumSellableTokens(uint tokens) onlyOwner {
        if (finalized) throw;

        if (!isUpdatable) throw;

        CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
        if (lastCrowdsaleCntrct.finalized()) throw;

        maximumSellableTokens = tokens;
        MaximumSellableTokensChanged(maximumSellableTokens);
    }
}

 



 
library SMathLib {

    function times(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a);
        return c;
    }

}



 
contract PreICOProxyBuyer is Ownable, Haltable {
    using SMathLib for uint;

     
    uint public investorCount;

     
    uint public weiRaised;

     
    address[] public investors;

     
    mapping(address => uint) public balances;

     
    mapping(address => uint) public claimed;

     
    uint public freezeEndsAt;

     
    uint public weiMinimumLimit;

     
    uint public weiMaximumLimit;

     
    uint public weiCap;

     
    uint public tokensBought;

     
    uint public claimCount;

    uint public totalClaimed;

     
    uint public timeLock;

     
    bool public forcedRefund;

     
    CrowdsaleExt public crowdsale;

     
    enum State{Unknown, Funding, Distributing, Refunding}

     
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

     
    event Refunded(address investor, uint value);

     
    event TokensBoughts(uint count);

     
    event Distributed(address investor, uint count);

     
    function PreICOProxyBuyer(address _owner, uint _freezeEndsAt, uint _weiMinimumLimit, uint _weiMaximumLimit, uint _weiCap) {

        owner = _owner;

         
        if(_freezeEndsAt == 0) {
            throw;
        }

         
        if(_weiMinimumLimit == 0) {
            throw;
        }

        if(_weiMaximumLimit == 0) {
            throw;
        }

        weiMinimumLimit = _weiMinimumLimit;
        weiMaximumLimit = _weiMaximumLimit;
        weiCap = _weiCap;
        freezeEndsAt = _freezeEndsAt;
    }

     
    function getToken() public constant returns(FractionalERC20Ext) {
        if(address(crowdsale) == 0)  {
            throw;
        }

        return crowdsale.token();
    }

     
    function invest(uint128 customerId) private {

         
        if(getState() != State.Funding) throw;

        if(msg.value == 0) throw;  

        address investor = msg.sender;

        bool existing = balances[investor] > 0;

        balances[investor] = balances[investor].plus(msg.value);

         
        if(balances[investor] < weiMinimumLimit || balances[investor] > weiMaximumLimit) {
            throw;
        }

         
        if(!existing) {
            investors.push(investor);
            investorCount++;
        }

        weiRaised = weiRaised.plus(msg.value);
        if(weiRaised > weiCap) {
            throw;
        }

         
         
        Invested(investor, msg.value, 0, customerId);
    }

    function buyWithCustomerId(uint128 customerId) public stopInEmergency payable {
        invest(customerId);
    }

    function buy() public stopInEmergency payable {
        invest(0x0);
    }


     
    function buyForEverybody() stopNonOwnersInEmergency public {

        if(getState() != State.Funding) {
             
            throw;
        }

         
        if(address(crowdsale) == 0) throw;

         
        crowdsale.invest.value(weiRaised)(address(this));

         
        tokensBought = getToken().balanceOf(address(this));

        if(tokensBought == 0) {
             
            throw;
        }

        TokensBoughts(tokensBought);
    }

     
    function getClaimAmount(address investor) public constant returns (uint) {

         
        if(getState() != State.Distributing) {
            throw;
        }
        return balances[investor].times(tokensBought) / weiRaised;
    }

     
    function getClaimLeft(address investor) public constant returns (uint) {
        return getClaimAmount(investor).minus(claimed[investor]);
    }

     
    function claimAll() {
        claim(getClaimLeft(msg.sender));
    }

     
    function claim(uint amount) stopInEmergency {
        require (now > timeLock);

        address investor = msg.sender;

        if(amount == 0) {
            throw;
        }

        if(getClaimLeft(investor) < amount) {
             
            throw;
        }

         
        if(claimed[investor] == 0) {
            claimCount++;
        }

        claimed[investor] = claimed[investor].plus(amount);
        totalClaimed = totalClaimed.plus(amount);
        getToken().transfer(investor, amount);

        Distributed(investor, amount);
    }

     
    function refund() stopInEmergency {

         
        if(getState() != State.Refunding) throw;

        address investor = msg.sender;
        if(balances[investor] == 0) throw;
        uint amount = balances[investor];
        delete balances[investor];
        if(!(investor.call.value(amount)())) throw;
        Refunded(investor, amount);
    }

     
    function setCrowdsale(CrowdsaleExt _crowdsale) public onlyOwner {
        crowdsale = _crowdsale;

         
        if(!crowdsale.isCrowdsale()) true;
    }

     
     
    function setTimeLock(uint _timeLock) public onlyOwner {
        timeLock = _timeLock;
    }

     
     
    function forceRefund() public onlyOwner {
        forcedRefund = true;
    }

     
     
     
    function loadRefund() public payable {
        if(getState() != State.Refunding) throw;
    }

     
    function getState() public view returns(State) {
        if (forcedRefund)
            return State.Refunding;

        if(tokensBought == 0) {
            if(now >= freezeEndsAt) {
                return State.Refunding;
            } else {
                return State.Funding;
            }
        } else {
            return State.Distributing;
        }
    }

     
    function isPresale() public constant returns (bool) {
        return true;
    }

     
    function() payable {
        throw;
    }
}