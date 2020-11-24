 

pragma solidity ^0.4.2;

 

 
contract PassTokenManagerInterface {
    
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

     
    address public creator;
     
    address public client;
     
    address public recipient;
    
     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;

     
    uint256 totalSupply;

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

     
    mapping (uint => uint) fundedAmount;
    
     
    bool public transferable;
     
    mapping (address => uint) public blockedDeadLine; 

     
    fundingData[2] public FundingRules;
    
     
    function TotalSupply() constant external returns (uint256);

     
     
     function balanceOf(address _owner) constant external returns (uint256 balance);

     
     
     
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);

     
     
    function FundedAmount(uint _proposalID) constant external returns (uint);

     
     
    function priceDivisor(uint _saleDate) constant internal returns (uint);
    
     
    function actualPriceDivisor() constant external returns (uint);

     
     
    function fundingMaxAmount(address _mainPartner) constant external returns (uint);

     
    modifier onlyClient {if (msg.sender != client) throw; _;}

     
    modifier onlyMainPartner {if (msg.sender !=  FundingRules[0].mainPartner) throw; _;}
    
     
    modifier onlyContractor {if (recipient == 0 || (msg.sender != recipient && msg.sender != creator)) throw; _;}
    
     
    modifier onlyDao {if (recipient != 0) throw; _;}
    
     
     
     
     
     
         
         
         
     

     
     
     
     
     
     
    function initToken(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        address _initialSupplyRecipient,
        uint256 _initialSupply,
        bool _transferable
       );

     
     
     
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

     
    function disableTransfer();

     
     
     
    function blockTransfer(address _shareHolder, uint _deadLine) external;

     
     
     
     
     
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool);

     
     
     
    function transfer(address _to, uint256 _value);

     
     
     
     
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

    event TokensCreated(address indexed Sender, address indexed TokenHolder, uint Quantity);
    event FundingRulesSet(address indexed MainPartner, uint indexed FundingProposalId, uint indexed StartTime, uint ClosingTime);
    event FundingFueled(uint indexed FundingProposalID, uint FundedAmount);
    event TransferAble();
    event TransferDisable();

}    

contract PassTokenManager is PassTokenManagerInterface {
    
    function TotalSupply() constant external returns (uint256) {
        return totalSupply;
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

    function PassTokenManager(
        address _creator,
        address _client,
        address _recipient
    ) {
        
        if (_creator == 0 
            || _client == 0 
            || _client == _recipient 
            || _client == address(this) 
            || _recipient == address(this)) throw;

        creator = _creator; 
        client = _client;
        recipient = _recipient;
        
    }
   
    function initToken(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        address _initialSupplyRecipient,
        uint256 _initialSupply,
        bool _transferable) {
           
        if (_initialSupplyRecipient == address(this)
            || decimals != 0
            || msg.sender != creator
            || totalSupply != 0) throw;
            
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;
          
        if (_transferable) {
            transferable = true;
            TransferAble();
        } else {
            transferable = false;
            TransferDisable();
        }
        
        balances[_initialSupplyRecipient] = _initialSupply; 
        totalSupply = _initialSupply;
        TokensCreated(msg.sender, _initialSupplyRecipient, _initialSupply);
           
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
            || totalSupply + _quantity <= totalSupply 
            || totalSupply + _quantity <= _quantity) return;

        balances[_recipient] += _quantity;
        totalSupply += _quantity;
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
            TransferAble();
        }
    }

    function disableTransfer() onlyClient {
        if (transferable) {
            transferable = false;
            TransferDisable();
        }
    }
    
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient onlyDao {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool) {  

        if (transferable
            && now > blockedDeadLine[_from]
            && now > blockedDeadLine[_to]
            && _to != address(this)
            && balances[_from] >= _value
            && balances[_to] + _value > balances[_to]
            && balances[_to] + _value >= _value
        ) {
            balances[_from] -= _value;
            balances[_to] += _value;
            return true;
        } else {
            return false;
        }
        
    }

    function transfer(address _to, uint256 _value) {  
        if (!transferFromTo(msg.sender, _to, _value)) throw;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
        ) returns (bool success) { 
        
        if (allowed[_from][msg.sender] < _value
            || !transferFromTo(_from, _to, _value)) throw;
            
        allowed[_from][msg.sender] -= _value;

    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

}    
  

pragma solidity ^0.4.2;

 

 
contract PassManagerInterface is PassTokenManagerInterface {

    struct proposal {
         
        uint amount;
         
        string description;
         
        bytes32 hashOfTheDocument;
         
        uint dateOfProposal;
         
        uint orderAmount;
         
        uint dateOfOrder;
    }
        
     
    proposal[] public proposals;
    
     
     
     
     
     
         
         
         
     
         
         
         

     
    function () payable;
    
     
     
    function updateRecipient(address _newRecipient);

     
     
    function buyShares() payable;
    
     
     
    function buySharesFor(address _recipient) payable;

     
     
     
     
     
    function newProposal(
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) returns (uint);
    
     
     
     
     
    function order(
        uint _proposalID,
        uint _amount
    ) external returns (bool) ;
    
     
     
     
     
    function sendTo(
        address _recipient, 
        uint _amount
    ) external returns (bool);

     
     
    function withdraw(uint _amount);
    
    event ProposalAdded(uint indexed ProposalID, uint Amount, string Description);
    event Order(uint indexed ProposalID, uint Amount);
    event Withdawal(address indexed Recipient, uint Amount);

}    

contract PassManager is PassManagerInterface, PassTokenManager {

    function PassManager(
        address _creator,
        address _client,
        address _recipient
    ) PassTokenManager(
        _creator,
        _client,
        _recipient
        ) {
        proposals.length = 1;
    }

    function () payable {}

    function updateRecipient(address _newRecipient) onlyContractor {

        if (_newRecipient == 0 
            || _newRecipient == client) throw;

        recipient = _newRecipient;
    } 

    function buyShares() payable {
        buySharesFor(msg.sender);
    } 
    
    function buySharesFor(address _recipient) payable onlyDao {
        
        if (!FundingRules[0].publicCreation 
            || !createToken(_recipient, msg.value, now)) throw;

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
        
        ProposalAdded(_proposalID, c.amount, c.description);
        
        return _proposalID;
        
    }
    
    function order(
        uint _proposalID,
        uint _orderAmount
    ) external onlyClient returns (bool) {
    
        proposal c = proposals[_proposalID];
        
        uint _sum = c.orderAmount + _orderAmount;
        if (_sum > c.amount
            || _sum < c.orderAmount
            || _sum < _orderAmount) return; 

        c.orderAmount = _sum;
        c.dateOfOrder = now;
        
        Order(_proposalID, _orderAmount);
        
        return true;

    }

    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient onlyDao returns (bool) {
    
        if (_recipient.send(_amount)) return true;
        else return false;

    }
   
    function withdraw(uint _amount) onlyContractor {
        if (!recipient.send(_amount)) throw;
        Withdawal(recipient, _amount);
    }
    
}    

contract PassManagerCreator {
    event NewPassManager(address Creator, address Client, address Recipient, address PassManager);
    function createManager(
        address _client,
        address _recipient
        ) returns (PassManager) {
        PassManager _passManager = new PassManager(
            msg.sender,
            _client,
            _recipient
        );
        NewPassManager(msg.sender, _client, _recipient, _passManager);
        return _passManager;
    }
}

pragma solidity ^0.4.2;

 

 

 
contract PassDaoInterface {

    struct BoardMeeting {        
         
        address creator;  
         
        uint proposalID;
         
        uint daoRulesProposalID; 
         
        uint setDeadline;
         
        uint fees;
         
        uint totalRewardedAmount;
         
        uint votingDeadline;
         
        bool open; 
         
        uint dateOfExecution;
         
        uint yea; 
         
        uint nay; 
         
        mapping (address => bool) hasVoted;  
    }

    struct Proposal {
         
        uint boardMeetingID;
         
        PassManager contractorManager;
         
        uint contractorProposalID;
         
        uint amount; 
         
        bool tokenCreation;
         
        bool publicShareCreation; 
         
        address mainPartner;
         
        uint initialSharePriceMultiplier; 
         
        uint inflationRate;
         
        uint minutesFundingPeriod;
         
        bool open; 
    }

    struct Rules {
         
        uint boardMeetingID;  
         
        uint minQuorumDivisor;  
         
        uint minBoardMeetingFees; 
         
        uint minutesSetProposalPeriod; 
         
        uint minMinutesDebatePeriod;
         
        uint feesRewardInflationRate;
         
        bool transferable;
    } 

     
    address creator;
     
    uint public minMinutesPeriods;
     
    uint public maxMinutesProposalPeriod;
     
    uint public maxMinutesFundingPeriod;
     
    uint public maxInflationRate;

     
    PassManager public daoManager;
    
     
    mapping (address => uint) public pendingFeesWithdrawals;

     
    BoardMeeting[] public BoardMeetings; 
     
    Proposal[] public Proposals;
     
    Rules[] public DaoRulesProposals;
     
    Rules public DaoRules; 
    
     
     

     
     
     
     
     
     
     
     
     
     
     
    function initDao(
        address _daoManager,
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod,
        uint _minQuorumDivisor,
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate
        );
    
     
     
     
     
     
    function newBoardMeeting(
        uint _proposalID, 
        uint _daoRulesProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint);
    
     
     
     
     
     
     
     
     
     
     
     
     
     
    function newProposal(
        address _contractorManager,
        uint _contractorProposalID,
        uint _amount, 
        bool _publicShareCreation,
        bool _tokenCreation,
        address _mainPartner,
        uint _initialSharePriceMultiplier, 
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod
    ) payable returns (uint);

     
     
     
     
     
     
     
     
    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        bool _transferable,
        uint _minutesDebatingPeriod
    ) payable returns (uint);
    
     
     
     
    function vote(
        uint _boardMeetingID, 
        bool _supportsProposal
    );

     
     
     
    function executeDecision(uint _boardMeetingID) returns (bool);
    
     
     
     
    function orderContractorProposal(uint _proposalID) returns (bool);   

     
     
    function withdrawBoardMeetingFees() returns (bool);

     
    function minQuorum() constant returns (uint);
    
    event ProposalAdded(uint indexed ProposalID, address indexed ContractorManager, uint ContractorProposalID, 
            uint amount, address indexed MainPartner, uint InitialSharePriceMultiplier, uint MinutesFundingPeriod);
    event DaoRulesProposalAdded(uint indexed DaoRulesProposalID, uint MinQuorumDivisor, uint MinBoardMeetingFees, 
            uint MinutesSetProposalPeriod, uint MinMinutesDebatePeriod, uint FeesRewardInflationRate, bool Transferable);
    event SentToContractor(uint indexed ContractorProposalID, address indexed ContractorManagerAddress, uint AmountSent);
    event BoardMeetingClosed(uint indexed BoardMeetingID, uint FeesGivenBack, bool ProposalExecuted);
    
}

contract PassDao is PassDaoInterface {

    function PassDao() {}
    
    function initDao(
        address _daoManager,
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _maxMinutesFundingPeriod,
        uint _maxMinutesProposalPeriod,
        uint _minQuorumDivisor,
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate
        ) {
            
        
        if (DaoRules.minQuorumDivisor != 0) throw;

        daoManager = PassManager(_daoManager);

        maxInflationRate = _maxInflationRate;
        minMinutesPeriods = _minMinutesPeriods;
        maxMinutesFundingPeriod = _maxMinutesFundingPeriod;
        maxMinutesProposalPeriod = _maxMinutesProposalPeriod;
        
        DaoRules.minQuorumDivisor = _minQuorumDivisor;
        DaoRules.minBoardMeetingFees = _minBoardMeetingFees;
        DaoRules.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        DaoRules.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        DaoRules.feesRewardInflationRate = _feesRewardInflationRate;

        BoardMeetings.length = 1; 
        Proposals.length = 1;
        DaoRulesProposals.length = 1;
        
    }
    
    function newBoardMeeting(
        uint _proposalID, 
        uint _daoRulesProposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint) {

        if (msg.value < DaoRules.minBoardMeetingFees
            || DaoRules.minutesSetProposalPeriod + _minutesDebatingPeriod > maxMinutesProposalPeriod
            || now + ((DaoRules.minutesSetProposalPeriod + _minutesDebatingPeriod) * 1 minutes) < now
            || _minutesDebatingPeriod < DaoRules.minMinutesDebatePeriod
            || msg.sender == address(this)) throw;

        uint _boardMeetingID = BoardMeetings.length++;
        BoardMeeting b = BoardMeetings[_boardMeetingID];

        b.creator = msg.sender;

        b.proposalID = _proposalID;
        b.daoRulesProposalID = _daoRulesProposalID;

        b.fees = msg.value;
        
        b.setDeadline = now + (DaoRules.minutesSetProposalPeriod * 1 minutes);        
        b.votingDeadline = b.setDeadline + (_minutesDebatingPeriod * 1 minutes); 

        b.open = true; 

        return _boardMeetingID;

    }

    function newProposal(
        address _contractorManager,
        uint _contractorProposalID,
        uint _amount, 
        bool _tokenCreation,
        bool _publicShareCreation,
        address _mainPartner,
        uint _initialSharePriceMultiplier, 
        uint _inflationRate,
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {

        if ((_contractorManager != 0 && _contractorProposalID == 0)
            || (_contractorManager == 0 
                && (_initialSharePriceMultiplier == 0
                    || _contractorProposalID != 0)
            || (_tokenCreation && _publicShareCreation)
            || (_initialSharePriceMultiplier != 0
                && (_minutesFundingPeriod < minMinutesPeriods
                    || _inflationRate > maxInflationRate
                    || _minutesFundingPeriod > maxMinutesFundingPeriod)))) throw;

        uint _proposalID = Proposals.length++;
        Proposal p = Proposals[_proposalID];

        p.contractorManager = PassManager(_contractorManager);
        p.contractorProposalID = _contractorProposalID;
        
        p.amount = _amount;
        p.tokenCreation = _tokenCreation;

        p.publicShareCreation = _publicShareCreation;
        p.mainPartner = _mainPartner;
        p.initialSharePriceMultiplier = _initialSharePriceMultiplier;
        p.inflationRate = _inflationRate;
        p.minutesFundingPeriod = _minutesFundingPeriod;

        p.boardMeetingID = newBoardMeeting(_proposalID, 0, _minutesDebatingPeriod);   

        p.open = true;
        
        ProposalAdded(_proposalID, p.contractorManager, p.contractorProposalID, p.amount, p.mainPartner, 
            p.initialSharePriceMultiplier, _minutesFundingPeriod);

        return _proposalID;
        
    }

    function newDaoRulesProposal(
        uint _minQuorumDivisor, 
        uint _minBoardMeetingFees,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        bool _transferable,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {
    
        if (_minQuorumDivisor <= 1
            || _minQuorumDivisor > 10
            || _minutesSetProposalPeriod < minMinutesPeriods
            || _minMinutesDebatePeriod < minMinutesPeriods
            || _minutesSetProposalPeriod + _minMinutesDebatePeriod > maxMinutesProposalPeriod
            || _feesRewardInflationRate > maxInflationRate
            ) throw; 
        
        uint _DaoRulesProposalID = DaoRulesProposals.length++;
        Rules r = DaoRulesProposals[_DaoRulesProposalID];

        r.minQuorumDivisor = _minQuorumDivisor;
        r.minBoardMeetingFees = _minBoardMeetingFees;
        r.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.feesRewardInflationRate = _feesRewardInflationRate;
        r.transferable = _transferable;
        
        r.boardMeetingID = newBoardMeeting(0, _DaoRulesProposalID, _minutesDebatingPeriod);     

        DaoRulesProposalAdded(_DaoRulesProposalID, _minQuorumDivisor, _minBoardMeetingFees, 
            _minutesSetProposalPeriod, _minMinutesDebatePeriod, _feesRewardInflationRate ,_transferable);

        return _DaoRulesProposalID;
        
    }
    
    function vote(
        uint _boardMeetingID, 
        bool _supportsProposal
    ) {
        
        BoardMeeting b = BoardMeetings[_boardMeetingID];

        if (b.hasVoted[msg.sender] 
            || now < b.setDeadline
            || now > b.votingDeadline) throw;

        uint _balance = uint(daoManager.balanceOf(msg.sender));
        if (_balance == 0) throw;
        
        b.hasVoted[msg.sender] = true;

        if (_supportsProposal) b.yea += _balance;
        else b.nay += _balance; 

        if (b.fees > 0 && b.proposalID != 0 && Proposals[b.proposalID].contractorProposalID != 0) {

            uint _a = 100*b.fees;
            if ((_a/100 != b.fees) || ((_a*_balance)/_a != _balance)) throw;
            uint _multiplier = (_a*_balance)/uint(daoManager.TotalSupply());

            uint _divisor = 100 + 100*DaoRules.feesRewardInflationRate*(now - b.setDeadline)/(100*365 days);

            uint _rewardedamount = _multiplier/_divisor;
            
            if (b.totalRewardedAmount + _rewardedamount > b.fees) _rewardedamount = b.fees - b.totalRewardedAmount;
            b.totalRewardedAmount += _rewardedamount;
            pendingFeesWithdrawals[msg.sender] += _rewardedamount;
        }

        daoManager.blockTransfer(msg.sender, b.votingDeadline);

    }

    function executeDecision(uint _boardMeetingID) returns (bool) {

        BoardMeeting b = BoardMeetings[_boardMeetingID];
        Proposal p = Proposals[b.proposalID];
        
        if (now < b.votingDeadline || !b.open) throw;
        
        b.open = false;
        if (p.contractorProposalID == 0) p.open = false;

        uint _fees;
        uint _minQuorum = minQuorum();

        if (b.fees > 0
            && (b.proposalID == 0 || p.contractorProposalID == 0)
            && b.yea + b.nay >= _minQuorum) {
                    _fees = b.fees;
                    b.fees = 0;
                    pendingFeesWithdrawals[b.creator] += _fees;
        }        

        if (b.fees - b.totalRewardedAmount > 0) {
            if (!daoManager.send(b.fees - b.totalRewardedAmount)) throw;
        }
        
        if (b.yea + b.nay < _minQuorum || b.yea <= b.nay) {
            p.open = false;
            BoardMeetingClosed(_boardMeetingID, _fees, false);
            return;
        }

        b.dateOfExecution = now;

        if (b.proposalID != 0) {
            
            if (p.initialSharePriceMultiplier != 0) {

                daoManager.setFundingRules(p.mainPartner, p.publicShareCreation, p.initialSharePriceMultiplier, 
                    p.amount, p.minutesFundingPeriod, p.inflationRate, b.proposalID);

                if (p.contractorProposalID != 0 && p.tokenCreation) {
                    p.contractorManager.setFundingRules(p.mainPartner, p.publicShareCreation, 0, 
                        p.amount, p.minutesFundingPeriod, maxInflationRate, b.proposalID);
                }

            }

        } else {

            Rules r = DaoRulesProposals[b.daoRulesProposalID];
            DaoRules.boardMeetingID = r.boardMeetingID;

            DaoRules.minQuorumDivisor = r.minQuorumDivisor;
            DaoRules.minMinutesDebatePeriod = r.minMinutesDebatePeriod; 
            DaoRules.minBoardMeetingFees = r.minBoardMeetingFees;
            DaoRules.minutesSetProposalPeriod = r.minutesSetProposalPeriod;
            DaoRules.feesRewardInflationRate = r.feesRewardInflationRate;

            DaoRules.transferable = r.transferable;
            if (r.transferable) daoManager.ableTransfer();
            else daoManager.disableTransfer();
        }
            
        BoardMeetingClosed(_boardMeetingID, _fees, true);

        return true;
        
    }
    
    function orderContractorProposal(uint _proposalID) returns (bool) {
        
        Proposal p = Proposals[_proposalID];
        BoardMeeting b = BoardMeetings[p.boardMeetingID];

        if (b.open || !p.open) throw;
        
        uint _amount = p.amount;

        if (p.initialSharePriceMultiplier != 0) {
            _amount = daoManager.FundedAmount(_proposalID);
            if (_amount == 0 && now < b.dateOfExecution + (p.minutesFundingPeriod * 1 minutes)) return;
        }
        
        p.open = false;   

        if (_amount == 0 || !p.contractorManager.order(p.contractorProposalID, _amount)) return;
        
        if (!daoManager.sendTo(p.contractorManager, _amount)) throw;
        SentToContractor(p.contractorProposalID, address(p.contractorManager), _amount);
        
        return true;

    }
    
    function withdrawBoardMeetingFees() returns (bool) {

        uint _amount = pendingFeesWithdrawals[msg.sender];

        pendingFeesWithdrawals[msg.sender] = 0;

        if (msg.sender.send(_amount)) {
            return true;
        } else {
            pendingFeesWithdrawals[msg.sender] = _amount;
            return false;
        }

    }

    function minQuorum() constant returns (uint) {
        return (uint(daoManager.TotalSupply()) / DaoRules.minQuorumDivisor);
    }
    
}