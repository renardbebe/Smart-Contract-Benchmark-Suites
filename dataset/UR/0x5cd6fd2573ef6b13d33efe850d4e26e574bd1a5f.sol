 

pragma solidity ^0.4.18;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply = 90000000 * 10 ** 18;

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


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
    public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract Ownable {

    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


 
contract ChargCoinContract is StandardToken, Ownable {

    string public standard = "CHG";
    string public name = "Charg Coin";
    string public symbol = "CHG";

    uint public decimals = 18;

    address public multisig = 0x482EFd447bE88748e7625e2b7c522c388970B790;

    struct ChargingData {
    address node;
    uint startTime;
    uint endTime;
    uint256 fixedRate;
    bool initialized;
    uint256 predefinedAmount;
    }

    struct ParkingData {
    address node;
    uint startTime;
    uint endTime;
    uint256 fixedRate;
    bool initialized;
    uint256 predefinedAmount;
    }

    mapping (address => uint256) public authorized;

    mapping (address => uint256) public rateOfCharging;
    mapping (address => uint256) public rateOfParking;

    mapping (address => ChargingData) public chargingSwitches;
    mapping (address => ParkingData) public parkingSwitches;

    mapping (address => uint256) public reservedFundsCharging;
    mapping (address => uint256) public reservedFundsParking;

     
    uint PRICE = 500;

    struct ContributorData {
    uint contributionAmount;
    uint tokensIssued;
    }

    function ChargCoinContract() public {
        balances[msg.sender] = totalSupply;
    }

    mapping (address => ContributorData) public contributorList;

    uint nextContributorIndex;

    mapping (uint => address) contributorIndexes;

    state public crowdsaleState = state.pendingStart;
    enum state {pendingStart, crowdsale, crowdsaleEnded}

    event CrowdsaleStarted(uint blockNumber);

    event CrowdsaleEnded(uint blockNumber);

    event ErrorSendingETH(address to, uint amount);

    event MinCapReached(uint blockNumber);

    event MaxCapReached(uint blockNumber);

    uint public constant BEGIN_TIME = 1513896982;

    uint public constant END_TIME = 1545432981;

    uint public minCap = 1 ether;

    uint public maxCap = 70200 ether;

    uint public ethRaised = 0;

    uint public totalSupply = 90000000 * 10 ** decimals;

    uint crowdsaleTokenCap = 10000000 * 10 ** decimals;  
    uint foundersAndTeamTokens = 9000000 * 10 ** decimals;  
    uint slushFundTokens = 45900000 * 10 ** decimals;  

    bool foundersAndTeamTokensClaimed = false;
    bool slushFundTokensClaimed = false;

    uint nextContributorToClaim;

    mapping (address => bool) hasClaimedEthWhenFail;

    function() payable public {
        require(msg.value != 0);
        require(crowdsaleState != state.crowdsaleEnded);
         

        bool stateChanged = checkCrowdsaleState();
         

        if (crowdsaleState == state.crowdsale) {
            createTokens(msg.sender);
             
        }
        else {
            refundTransaction(stateChanged);
             
        }
    }

     
     
     
    function checkCrowdsaleState() internal returns (bool) {
        if (ethRaised >= maxCap && crowdsaleState != state.crowdsaleEnded) { 
            crowdsaleState = state.crowdsaleEnded;
            CrowdsaleEnded(block.number);
             
            return true;
        }

        if (now >= END_TIME) {
            crowdsaleState = state.crowdsaleEnded;
            CrowdsaleEnded(block.number);
             
            return true;
        }

        if (now >= BEGIN_TIME && now < END_TIME) { 
            if (crowdsaleState != state.crowdsale) { 
                crowdsaleState = state.crowdsale;
                 
                CrowdsaleStarted(block.number);
                 
                return true;
            }
        }

        return false;
    }

     
     
     
    function refundTransaction(bool _stateChanged) internal {
        if (_stateChanged) {
            msg.sender.transfer(msg.value);
        }
        else {
            revert();
        }
    }

    function createTokens(address _contributor) payable public {

        uint _amount = msg.value;

        uint contributionAmount = _amount;
        uint returnAmount = 0;

        if (_amount > (maxCap - ethRaised)) { 
            contributionAmount = maxCap - ethRaised;
             
            returnAmount = _amount - contributionAmount;
             
        }

        if (ethRaised + contributionAmount > minCap && minCap > ethRaised) {
            MinCapReached(block.number);
        }

        if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap) {
            MaxCapReached(block.number);
        }

        if (contributorList[_contributor].contributionAmount == 0) {
            contributorIndexes[nextContributorIndex] = _contributor;
            nextContributorIndex += 1;
        }

        contributorList[_contributor].contributionAmount += contributionAmount;
        ethRaised += contributionAmount;
         

        uint256 tokenAmount = calculateEthToChargcoin(contributionAmount);
         
        if (tokenAmount > 0) {
            transferToContributor(_contributor, tokenAmount);
            contributorList[_contributor].tokensIssued += tokenAmount;
             
        }

        if (!multisig.send(msg.value)) {
            revert();
        }
    }


    function transferToContributor(address _to, uint256 _value)  public {
        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }

    function calculateEthToChargcoin(uint _eth) constant public returns (uint256) {

        uint tokens = _eth.mul(getPrice());
        uint percentage = 0;

        if (ethRaised > 0) {
            percentage = ethRaised * 100 / maxCap;
        }

        return tokens + getAmountBonus(tokens);
    }

    function getAmountBonus(uint tokens) pure public returns (uint) {
        uint amountBonus = 0;

        if (tokens >= 10000) amountBonus = tokens;
        else if (tokens >= 5000) amountBonus = tokens * 60 / 100;
        else if (tokens >= 1000) amountBonus = tokens * 30 / 100;
        else if (tokens >= 500) amountBonus = tokens * 10 / 100;
        else if (tokens >= 100) amountBonus = tokens * 5 / 100;
        else if (tokens >= 10) amountBonus = tokens * 1 / 100;

        return amountBonus;
    }

     
    function getPrice() constant public returns (uint result) {
        return PRICE;
    }

     
     
     
    function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner public {
        require(crowdsaleState != state.crowdsaleEnded);
         
        require(ethRaised < minCap);
         
        address currentParticipantAddress;
        uint contribution;
        for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
            currentParticipantAddress = contributorIndexes[nextContributorToClaim];
             
            if (currentParticipantAddress == 0x0) return;
             
            if (!hasClaimedEthWhenFail[currentParticipantAddress]) { 
                contribution = contributorList[currentParticipantAddress].contributionAmount;
                 
                hasClaimedEthWhenFail[currentParticipantAddress] = true;
                 
                balances[currentParticipantAddress] = 0;
                if (!currentParticipantAddress.send(contribution)) { 
                    ErrorSendingETH(currentParticipantAddress, contribution);
                     
                }
            }
            nextContributorToClaim += 1;
             
        }
    }

     
     
     
    function setMultisigAddress(address _newAddress) onlyOwner public {
        multisig = _newAddress;
    }

     
     
     
    function registerNode(uint256 chargingRate, uint256 parkingRate) public {
        if (authorized[msg.sender] == 1) revert();

        rateOfCharging[msg.sender] = chargingRate;
        rateOfParking[msg.sender] = parkingRate;
        authorized[msg.sender] = 1;
    }

     
     
     
    function blockNode (address node) onlyOwner public {
        authorized[node] = 0;
    }

     
     
     
    function updateChargingRate (uint256 rate) public {
        rateOfCharging[msg.sender] = rate;
    }

     
     
     
    function updateParkingRate (uint256 rate) public {
        rateOfCharging[msg.sender] = rate;
    }

    function chargeOn (address node, uint time) public {
         
        if (authorized[node] == 0) revert();
         
        if (chargingSwitches[msg.sender].initialized) revert();

         
        uint endTime = now + time;

         
        if (endTime <= now) revert();

         
        uint256 predefinedAmount = (endTime - now) * rateOfCharging[node];

        if (balances[msg.sender] < predefinedAmount) revert();

        chargingSwitches[msg.sender] = ChargingData(node, now, endTime, rateOfCharging[node], true, predefinedAmount);
        balances[msg.sender] = balances[msg.sender].sub(predefinedAmount);
        reservedFundsCharging[msg.sender] = reservedFundsCharging[msg.sender].add(predefinedAmount);
    }

    function chargeOff (address node) public {
         
        if (!chargingSwitches[msg.sender].initialized) revert();
         
        uint256 amount = (now - chargingSwitches[msg.sender].startTime) * chargingSwitches[msg.sender].fixedRate;
         
        amount = amount > chargingSwitches[msg.sender].predefinedAmount ? chargingSwitches[msg.sender].predefinedAmount : amount;

         
        balances[node] = balances[node] + amount;
        reservedFundsCharging[msg.sender] = reservedFundsCharging[msg.sender] - amount;

         
        if (reservedFundsCharging[msg.sender] > 0) {
            balances[msg.sender] = balances[msg.sender] + reservedFundsCharging[msg.sender];
            reservedFundsCharging[msg.sender] = 0;
        }

         
        chargingSwitches[msg.sender].node = 0;
        chargingSwitches[msg.sender].startTime = 0;
        chargingSwitches[msg.sender].endTime = 0;
        chargingSwitches[msg.sender].fixedRate = 0;
        chargingSwitches[msg.sender].initialized = false;
        chargingSwitches[msg.sender].predefinedAmount = 0;
    }

    function parkingOn (address node, uint time) public {
         
        if (authorized[node] == 0) revert();
         
        if (parkingSwitches[msg.sender].initialized) revert();

        if (balances[msg.sender] < predefinedAmount) revert();

        uint endTime = now + time;

         
        if (endTime <= now) revert();

        uint256 predefinedAmount = (endTime - now) * rateOfParking[node];

        parkingSwitches[msg.sender] = ParkingData(node, now, endTime, rateOfParking[node], true, predefinedAmount);
        balances[msg.sender] = balances[msg.sender].sub(predefinedAmount);
        reservedFundsParking[msg.sender] = reservedFundsParking[msg.sender].add(predefinedAmount);
    }

     
    function parkingOff (address node) public {
        if (!parkingSwitches[msg.sender].initialized) revert();

         
        uint256 amount = (now - parkingSwitches[msg.sender].startTime) * parkingSwitches[msg.sender].fixedRate;
         
        amount = amount > parkingSwitches[msg.sender].predefinedAmount ? parkingSwitches[msg.sender].predefinedAmount : amount;

        balances[node] = balances[node] + amount;
        reservedFundsParking[msg.sender] = reservedFundsParking[msg.sender] - amount;

         
        if (reservedFundsParking[msg.sender] > 0) {
            balances[msg.sender] = balances[msg.sender] + reservedFundsParking[msg.sender];
             
            reservedFundsParking[msg.sender] = 0;
        }

         
        parkingSwitches[msg.sender].node = 0;
        parkingSwitches[msg.sender].startTime = 0;
        parkingSwitches[msg.sender].endTime = 0;
        parkingSwitches[msg.sender].fixedRate = 0;
        parkingSwitches[msg.sender].initialized = false;
        parkingSwitches[msg.sender].predefinedAmount = 0;
    }
}

contract ChgUsdConverter is Ownable{
    address public contractAddress = 0xC4A86561cb0b7EA1214904f26E6D50FD357C7986;
    address public dashboardAddress = 0x482EFd447bE88748e7625e2b7c522c388970B790;
    uint public ETHUSDPRICE = 810;
    uint public CHGUSDPRICE = 4;  

    function setETHUSDPrice(uint newPrice) public {
        if (msg.sender != dashboardAddress) revert();
        
        ETHUSDPRICE = newPrice;
    }

    function setCHGUSDPrice(uint newPrice) public {
        if (msg.sender != dashboardAddress) revert();

        CHGUSDPRICE = newPrice;
    }

    function calculateCHGAmountToEther(uint etherAmount) view public returns (uint){
        return ((etherAmount * ETHUSDPRICE) / CHGUSDPRICE) * 10;
    }

    function balances(address a) view public returns (uint) {
        ChargCoinContract c = ChargCoinContract(contractAddress);
        return c.balances(a);
    }

    function currentBalance() view public returns (uint) {
        ChargCoinContract c = ChargCoinContract(contractAddress);
        return c.balances(address(this));
    }

    function() payable public {
        uint calculatedAmount = calculateCHGAmountToEther(msg.value);

        ChargCoinContract c = ChargCoinContract(contractAddress);

        if (currentBalance() < calculatedAmount) {
            revert();
        }

        if (!c.transfer(msg.sender, calculatedAmount)) {
            revert();
        }

    }
}