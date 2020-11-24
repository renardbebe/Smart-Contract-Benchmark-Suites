 

pragma solidity ^0.4.6;

 

 
contract PassManagerInterface {

    struct proposal {
         
        uint amount;
         
        string description;
         
        bytes32 hashOfTheDocument;
         
        uint dateOfProposal;
         
        uint lastClientProposalID;
         
        uint orderAmount;
         
        uint dateOfOrder;
    }
        
     
    proposal[] public proposals;

    struct fundingData {
         
        bool publicCreation; 
         
        address mainPartner;
         
        uint maxAmountToFund;
         
        uint fundedAmount;
         
        uint startTime; 
         
        uint closingTime;  
         
        uint initialPriceMultiplier;
         
        uint inflationRate; 
         
        uint proposalID;
    } 
    
     
    fundingData[2] public FundingRules;

     
    address public clonedFrom;
     
    uint closingTimeForCloning;
     
    uint public smartContractStartDate;

     
    address public creator;
     
    address client;
     
    address public recipient;
     
    PassManager public daoManager;
    
     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;

     
    bool initialTokenSupplyDone;
    
     
    uint256 totalTokenSupply;

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

     
    mapping (uint => uint) fundedAmount;

     
    address[] holders;
     
    mapping (address => uint) public holderID;

     
    bool public transferable;
     
    mapping (address => uint) public blockedDeadLine; 

     
    function Client() constant returns (address);
    
     
    function ClosingTimeForCloning() constant returns (uint);
    
     
    function totalSupply() constant external returns (uint256);

     
     
     function balanceOf(address _owner) constant external returns (uint256 balance);

     
     
     
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

     
     
    function FundedAmount(uint _proposalID) constant external returns (uint);

     
     
    function priceDivisor(uint _saleDate) constant internal returns (uint);
    
     
    function actualPriceDivisor() constant external returns (uint);

     
     
    function fundingMaxAmount(address _mainPartner) constant external returns (uint);
    
     
    function numberOfHolders() constant returns (uint);

     
     
    function HolderAddress(uint _index) constant returns (address);

     
    function numberOfProposals() constant returns (uint);
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
     
     
     
     
    function initialTokenSupply(
        address _recipient, 
        uint _quantity,
        bool _last) returns (bool success);
        
     
     
     
     
     
     
     
     
     
    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _lastClientProposalID,
        uint _orderAmount,
        uint _dateOfOrder) returns (bool success);
    
     
     
     
     
    function cloneTokens(
        uint _from,
        uint _to) returns (bool success);
    
     
    function closeSetup();

     
     
    function updateRecipient(address _newRecipient);

     
    function () payable;
    
     
     
    function withdraw(uint _amount);

     
    function updateClient(address _newClient);
    
     
     
     
     
     
    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) returns (uint);
        
     
     
     
     
     
    function order(
        uint _clientProposalID,
        uint _proposalID,
        uint _amount
    ) external returns (bool) ;
    
     
     
     
     
    function sendTo(
        address _recipient, 
        uint _amount
    ) external returns (bool);
    
     
     
    function addHolder(address _holder) internal;
    
     
     
     
     
    function createInitialTokens(address _holder, uint _quantity) internal returns (bool success) ;
    
     
     
     
     
    function setTokenPriceProposal(        
        uint _initialPriceMultiplier, 
        uint _inflationRate,
        uint _closingTime
    );

     
     
     
     
     
     
     
     
    function setFundingRules(
        address _mainPartner,
        bool _publicCreation, 
        uint _initialPriceMultiplier, 
        uint _maxAmountToFund, 
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _proposalID
    ) external;
    
     
     
     
     
     
    function createToken(
        address _recipient, 
        uint _amount,
        uint _saleDate
    ) internal returns (bool success);

     
     
    function setFundingStartTime(uint _startTime) external;

     
     
     
     
     
    function rewardToken(
        address _recipient, 
        uint _amount,
        uint _date
        ) external;

     
    function closeFunding() internal;
    
     
    function setFundingFueled() external;

     
    function ableTransfer();

     
     
    function disableTransfer(uint _closingTime);

     
     
     
    function blockTransfer(address _shareHolder, uint _deadLine) external;

     
     
    function buyShares() payable;
    
     
     
    function buySharesFor(address _recipient) payable;
    
     
     
     
     
     
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool success);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

    event FeesReceived(address indexed From, uint Amount);
    event AmountReceived(address indexed From, uint Amount);
    event paymentReceived(address indexed daoManager, uint Amount);
    event ProposalCloned(uint indexed LastClientProposalID, uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event ClientUpdated(address LastClient, address NewClient);
    event RecipientUpdated(address LastRecipient, address NewRecipient);
    event ProposalAdded(uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event Order(uint indexed clientProposalID, uint indexed ProposalID, uint Amount);
    event Withdawal(address indexed Recipient, uint Amount);
    event TokenPriceProposalSet(uint InitialPriceMultiplier, uint InflationRate, uint ClosingTime);
    event holderAdded(uint Index, address Holder);
    event TokensCreated(address indexed Sender, address indexed TokenHolder, uint Quantity);
    event FundingRulesSet(address indexed MainPartner, uint indexed FundingProposalId, uint indexed StartTime, uint ClosingTime);
    event FundingFueled(uint indexed FundingProposalID, uint FundedAmount);
    event TransferAble();
    event TransferDisable(uint closingTime);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}    

contract PassManager is PassManagerInterface {

 

    function Client() constant returns (address) {
        if (recipient == 0) return client;
        else return daoManager.Client();
    }
    
    function ClosingTimeForCloning() constant returns (uint) {
        if (recipient == 0) return closingTimeForCloning;
        else return daoManager.ClosingTimeForCloning();
    }
    
    function totalSupply() constant external returns (uint256) {
        return totalTokenSupply;
    }

     function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
     }

    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function FundedAmount(uint _proposalID) constant external returns (uint) {
        return fundedAmount[_proposalID];
    }

    function priceDivisor(uint _saleDate) constant internal returns (uint) {
        uint _date = _saleDate;
        
        if (_saleDate > FundingRules[0].closingTime) _date = FundingRules[0].closingTime;
        if (_saleDate < FundingRules[0].startTime) _date = FundingRules[0].startTime;

        return 100 + 100*FundingRules[0].inflationRate*(_date - FundingRules[0].startTime)/(100*365 days);
    }
    
    function actualPriceDivisor() constant external returns (uint) {
        return priceDivisor(now);
    }

    function fundingMaxAmount(address _mainPartner) constant external returns (uint) {
        
        if (now > FundingRules[0].closingTime
            || now < FundingRules[0].startTime
            || _mainPartner != FundingRules[0].mainPartner) {
            return 0;   
        } else {
            return FundingRules[0].maxAmountToFund;
        }
        
    }

    function numberOfHolders() constant returns (uint) {
        return holders.length - 1;
    }
    
    function HolderAddress(uint _index) constant returns (address) {
        return holders[_index];
    }

    function numberOfProposals() constant returns (uint) {
        return proposals.length - 1;
    }

 

     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}
    
     
    modifier onlyMainPartner {if (msg.sender !=  FundingRules[0].mainPartner) throw; _;}
    
     
    modifier onlyContractor {if (recipient == 0 || (msg.sender != recipient && msg.sender != creator)) throw; _;}
    
     
    modifier onlyDao {if (recipient != 0) throw; _;}
    
 

    function PassManager(
        address _client,
        address _daoManager,
        address _recipient,
        address _clonedFrom,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        bool _transferable
    ) {

        if ((_recipient == 0 && _client == 0)
            || _client == _recipient) throw;

        creator = msg.sender; 
        client = _client;
        recipient = _recipient;
        
        if (_recipient !=0) daoManager = PassManager(_daoManager);

        clonedFrom = _clonedFrom;            
        
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;
          
        if (_transferable) {
            transferable = true;
            TransferAble();
        } else {
            transferable = false;
            TransferDisable(0);
        }

        holders.length = 1;
        proposals.length = 1;
        
    }

 

    function initialTokenSupply(
        address _recipient, 
        uint _quantity,
        bool _last) returns (bool success) {

        if (smartContractStartDate != 0 || initialTokenSupplyDone) throw;
        
        if (_recipient != 0 && _quantity != 0) {
            return (createInitialTokens(_recipient, _quantity));
        }
        
        if (_last) initialTokenSupplyDone = true;
            
    }

    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _lastClientProposalID,
        uint _orderAmount,
        uint _dateOfOrder
    ) returns (bool success) {
            
        if (smartContractStartDate != 0 || recipient == 0
        || msg.sender != creator) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = _dateOfProposal;
        c.lastClientProposalID = _lastClientProposalID;
        c.orderAmount = _orderAmount;
        c.dateOfOrder = _dateOfOrder;
        
        ProposalCloned(_lastClientProposalID, _proposalID, c.amount, c.description, c.hashOfTheDocument);
        
        return true;
            
    }

    function cloneTokens(
        uint _from,
        uint _to) returns (bool success) {
        
        if (smartContractStartDate != 0) throw;
        
        PassManager _clonedFrom = PassManager(clonedFrom);
        
        if (_from < 1 || _to > _clonedFrom.numberOfHolders()) throw;

        address _holder;

        for (uint i = _from; i <= _to; i++) {
            _holder = _clonedFrom.HolderAddress(i);
            if (balances[_holder] == 0) {
                createInitialTokens(_holder, _clonedFrom.balanceOf(_holder));
            }
        }

        return true;
        
    }

    function closeSetup() {
        
        if (smartContractStartDate != 0 || msg.sender != creator) throw;

        smartContractStartDate = now;

    }

 

    function () payable {
        AmountReceived(msg.sender, msg.value);
    }
    
 

    function updateRecipient(address _newRecipient) onlyContractor {

        if (_newRecipient == 0 
            || _newRecipient == client) throw;

        RecipientUpdated(recipient, _newRecipient);
        recipient = _newRecipient;

    } 

    function withdraw(uint _amount) onlyContractor {
        if (!recipient.send(_amount)) throw;
        Withdawal(recipient, _amount);
    }
    
 

    function updateClient(address _newClient) onlyClient {
        
        if (_newClient == 0 
            || _newClient == recipient) throw;

        ClientUpdated(client, _newClient);
        client = _newClient;        

    }

    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) onlyContractor returns (uint) {

        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = now;
        
        ProposalAdded(_proposalID, c.amount, c.description, c.hashOfTheDocument);
        
        return _proposalID;
        
    }
    
    function order(
        uint _clientProposalID,
        uint _proposalID,
        uint _orderAmount
    ) external onlyClient returns (bool) {
    
        proposal c = proposals[_proposalID];
        
        uint _sum = c.orderAmount + _orderAmount;
        if (_sum > c.amount
            || _sum < c.orderAmount
            || _sum < _orderAmount) return; 

        c.lastClientProposalID =  _clientProposalID;
        c.orderAmount = _sum;
        c.dateOfOrder = now;
        
        Order(_clientProposalID, _proposalID, _orderAmount);
        
        return true;

    }

    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient onlyDao returns (bool) {

        if (_recipient.send(_amount)) return true;
        else return false;

    }
    
 
    
    function addHolder(address _holder) internal {
        
        if (holderID[_holder] == 0) {
            
            uint _holderID = holders.length++;
            holders[_holderID] = _holder;
            holderID[_holder] = _holderID;
            holderAdded(_holderID, _holder);

        }
        
    }
    
    function createInitialTokens(
        address _holder, 
        uint _quantity
    ) internal returns (bool success) {

        if (_quantity > 0 && balances[_holder] == 0) {
            addHolder(_holder);
            balances[_holder] = _quantity; 
            totalTokenSupply += _quantity;
            TokensCreated(msg.sender, _holder, _quantity);
            return true;
        }
        
    }
    
    function setTokenPriceProposal(        
        uint _initialPriceMultiplier, 
        uint _inflationRate,
        uint _closingTime
    ) onlyContractor {
        
        if (_closingTime < now 
            || now < FundingRules[1].closingTime) throw;
        
        FundingRules[1].initialPriceMultiplier = _initialPriceMultiplier;
        FundingRules[1].inflationRate = _inflationRate;
        FundingRules[1].startTime = now;
        FundingRules[1].closingTime = _closingTime;
        
        TokenPriceProposalSet(_initialPriceMultiplier, _inflationRate, _closingTime);
    }
    
    function setFundingRules(
        address _mainPartner,
        bool _publicCreation, 
        uint _initialPriceMultiplier,
        uint _maxAmountToFund, 
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _proposalID
    ) external onlyClient {

        if (now < FundingRules[0].closingTime
            || _mainPartner == address(this)
            || _mainPartner == client
            || (!_publicCreation && _mainPartner == 0)
            || (_publicCreation && _mainPartner != 0)
            || (recipient == 0 && _initialPriceMultiplier == 0)
            || (recipient != 0 
                && (FundingRules[1].initialPriceMultiplier == 0
                    || _inflationRate < FundingRules[1].inflationRate
                    || now < FundingRules[1].startTime
                    || FundingRules[1].closingTime < now + (_minutesFundingPeriod * 1 minutes)))
            || _maxAmountToFund == 0
            || _minutesFundingPeriod == 0
            ) throw;

        FundingRules[0].startTime = now;
        FundingRules[0].closingTime = now + _minutesFundingPeriod * 1 minutes;
            
        FundingRules[0].mainPartner = _mainPartner;
        FundingRules[0].publicCreation = _publicCreation;
        
        if (recipient == 0) FundingRules[0].initialPriceMultiplier = _initialPriceMultiplier;
        else FundingRules[0].initialPriceMultiplier = FundingRules[1].initialPriceMultiplier;
        
        if (recipient == 0) FundingRules[0].inflationRate = _inflationRate;
        else FundingRules[0].inflationRate = FundingRules[1].inflationRate;
        
        FundingRules[0].fundedAmount = 0;
        FundingRules[0].maxAmountToFund = _maxAmountToFund;

        FundingRules[0].proposalID = _proposalID;

        FundingRulesSet(_mainPartner, _proposalID, FundingRules[0].startTime, FundingRules[0].closingTime);
            
    } 
    
    function createToken(
        address _recipient, 
        uint _amount,
        uint _saleDate
    ) internal returns (bool success) {

        if (now > FundingRules[0].closingTime
            || now < FundingRules[0].startTime
            ||_saleDate > FundingRules[0].closingTime
            || _saleDate < FundingRules[0].startTime
            || FundingRules[0].fundedAmount + _amount > FundingRules[0].maxAmountToFund) return;

        uint _a = _amount*FundingRules[0].initialPriceMultiplier;
        uint _multiplier = 100*_a;
        uint _quantity = _multiplier/priceDivisor(_saleDate);
        if (_a/_amount != FundingRules[0].initialPriceMultiplier
            || _multiplier/100 != _a
            || totalTokenSupply + _quantity <= totalTokenSupply 
            || totalTokenSupply + _quantity <= _quantity) return;

        addHolder(_recipient);
        balances[_recipient] += _quantity;
        totalTokenSupply += _quantity;
        FundingRules[0].fundedAmount += _amount;

        TokensCreated(msg.sender, _recipient, _quantity);
        
        if (FundingRules[0].fundedAmount == FundingRules[0].maxAmountToFund) closeFunding();
        
        return true;

    }

    function setFundingStartTime(uint _startTime) external onlyMainPartner {
        if (now > FundingRules[0].closingTime) throw;
        FundingRules[0].startTime = _startTime;
    }
    
    function rewardToken(
        address _recipient, 
        uint _amount,
        uint _date
        ) external onlyMainPartner {

        uint _saleDate;
        if (_date == 0) _saleDate = now; else _saleDate = _date;

        if (!createToken(_recipient, _amount, _saleDate)) throw;

    }

    function closeFunding() internal {
        if (recipient == 0) fundedAmount[FundingRules[0].proposalID] = FundingRules[0].fundedAmount;
        FundingRules[0].closingTime = now;
    }
    
    function setFundingFueled() external onlyMainPartner {
        if (now > FundingRules[0].closingTime) throw;
        closeFunding();
        if (recipient == 0) FundingFueled(FundingRules[0].proposalID, FundingRules[0].fundedAmount);
    }
    
    function ableTransfer() onlyClient {
        if (!transferable) {
            transferable = true;
            closingTimeForCloning = 0;
            TransferAble();
        }
    }

    function disableTransfer(uint _closingTime) onlyClient {
        if (transferable && _closingTime == 0) transferable = false;
        else closingTimeForCloning = _closingTime;
            
        TransferDisable(_closingTime);
    }
    
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient onlyDao {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    function buySharesFor(address _recipient) payable onlyDao {
        
        if (!FundingRules[0].publicCreation 
            || !createToken(_recipient, msg.value, now)) throw;

    }
    
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool success) {  

        if ((transferable && now > ClosingTimeForCloning())
            && now > blockedDeadLine[_from]
            && now > blockedDeadLine[_to]
            && _to != address(this)
            && balances[_from] >= _value
            && balances[_to] + _value > balances[_to]
            && balances[_to] + _value >= _value
        ) {
            balances[_from] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            addHolder(_to);
            return true;
        } else {
            return false;
        }
        
    }

    function transfer(address _to, uint256 _value) returns (bool success) {  
        if (!transferFromTo(msg.sender, _to, _value)) throw;
        return true;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) { 
        
        if (allowed[_from][msg.sender] < _value
            || !transferFromTo(_from, _to, _value)) throw;
            
        allowed[_from][msg.sender] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
    
}