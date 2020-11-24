 

pragma solidity ^0.4.8;

 

 

 
contract PassDao {
    
    struct revision {
         
        address committeeRoom;
         
        address shareManager;
         
        address tokenManager;
         
        uint startDate;
    }
     
    revision[] public revisions;

    struct project {
         
        address contractAddress;
         
        uint startDate;
    }
     
    project[] public projects;

     
    mapping (address => uint) projectID;
    
     
    address metaProject;

    
 

    event Upgrade(uint indexed RevisionID, address CommitteeRoom, address ShareManager, address TokenManager);
    event NewProject(address Project);

 
    
     
    function ActualCommitteeRoom() constant returns (address) {
        return revisions[0].committeeRoom;
    }
    
     
    function MetaProject() constant returns (address) {
        return metaProject;
    }

     
    function ActualShareManager() constant returns (address) {
        return revisions[0].shareManager;
    }

     
    function ActualTokenManager() constant returns (address) {
        return revisions[0].tokenManager;
    }

 

    modifier onlyPassCommitteeRoom {if (msg.sender != revisions[0].committeeRoom  
        && revisions[0].committeeRoom != 0) throw; _;}
    
 

    function PassDao() {
        projects.length = 1;
        revisions.length = 1;
    }
    
 

     
     
     
     
     
    function upgrade(
        address _newCommitteeRoom, 
        address _newShareManager, 
        address _newTokenManager) onlyPassCommitteeRoom returns (uint) {
        
        uint _revisionID = revisions.length++;
        revision r = revisions[_revisionID];

        if (_newCommitteeRoom != 0) r.committeeRoom = _newCommitteeRoom; else r.committeeRoom = revisions[0].committeeRoom;
        if (_newShareManager != 0) r.shareManager = _newShareManager; else r.shareManager = revisions[0].shareManager;
        if (_newTokenManager != 0) r.tokenManager = _newTokenManager; else r.tokenManager = revisions[0].tokenManager;

        r.startDate = now;
        
        revisions[0] = r;
        
        Upgrade(_revisionID, _newCommitteeRoom, _newShareManager, _newTokenManager);
            
        return _revisionID;
    }

     
     
    function addMetaProject(address _projectAddress) onlyPassCommitteeRoom {

        metaProject = _projectAddress;
    }
    
     
     
    function addProject(address _projectAddress) onlyPassCommitteeRoom {

        if (projectID[_projectAddress] == 0) {

            uint _projectID = projects.length++;
            project p = projects[_projectID];
        
            projectID[_projectAddress] = _projectID;
            p.contractAddress = _projectAddress; 
            p.startDate = now;
            
            NewProject(_projectAddress);
        }
    }
    
}

pragma solidity ^0.4.8;

 

 
contract PassTokenManagerInterface {

     
    PassDao public passDao;
     
    address creator;
    
     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
     
    uint256 totalTokenSupply;

     
    bool token;
     
    bool transferable;

     
    address public clonedFrom;
     
    bool initialTokenSupplyDone;

     
    address[] holders;
     
    mapping (address => uint) holderID;
    
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

    struct funding {
         
        address moderator;
         
        uint amountToFund;
         
        uint fundedAmount;
         
        uint startTime; 
         
        uint closingTime;  
         
        uint initialPriceMultiplier;
         
        uint inflationRate; 
         
        uint totalWeiGiven;
    } 
     
    mapping (uint => funding) public fundings;

     
    uint lastProposalID;
     
    uint public lastFueledFundingID;
    
    struct amountsGiven {
        uint weiAmount;
        uint tokenAmount;
    }
     
    mapping (uint => mapping (address => amountsGiven)) public Given;
    
     
    mapping (address => uint) public blockedDeadLine; 

     
    function Client() constant returns (address);
    
     
    function totalSupply() constant external returns (uint256);

     
     
     function balanceOf(address _owner) constant external returns (uint256 balance);

     
    function Transferable() constant external returns (bool);
    
     
     
     
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
    
     
     
    function FundedAmount(uint _proposalID) constant external returns (uint);

     
     
    function AmountToFund(uint _proposalID) constant external returns (uint);
    
     
     
    function priceMultiplier(uint _proposalID) constant internal returns (uint);
    
     
     
     
    function priceDivisor(
        uint _proposalID, 
        uint _saleDate) constant internal returns (uint);
    
     
     
    function actualPriceDivisor(uint _proposalID) constant internal returns (uint);

     
     
     
     
     
    function TokenAmount(
        uint _weiAmount,
        uint _priceMultiplier, 
        uint _priceDivisor) constant internal returns (uint);

     
     
     
     
     
    function weiAmount(
        uint _tokenAmount, 
        uint _priceMultiplier, 
        uint _priceDivisor) constant internal returns (uint);
        
     
     
     
    function TokenPriceInWei(uint _tokenAmount, uint _proposalID) constant returns (uint);
    
     
    function LastProposalID() constant returns (uint);

     
    function numberOfHolders() constant returns (uint);

     
     
    function HolderAddress(uint _index) constant external returns (address);
   
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
     
     
     
     
     
    function initialTokenSupply(
        address _recipient, 
        uint _quantity,
        bool _last) returns (bool success);
        
     
     
     
     
    function cloneTokens(
        uint _from,
        uint _to) returns (bool success);

     
     
    function addHolder(address _holder) internal;
    
     
     
     
    function createTokens(
        address _holder, 
        uint _tokenAmount) internal;
        
     
     
     
     
    function rewardTokensForClient(
        address _recipient, 
        uint _amount) external  returns (uint);
        
     
     
     
     
     
     
     
    function setFundingRules(
        address _moderator,
        uint _initialPriceMultiplier,
        uint _amountToFund,
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _proposalID) external;

     
     
     
     
     
     
     
    function sale(
        uint _proposalID,
        address _recipient, 
        uint _amount,
        uint _saleDate,
        bool _presale
    ) internal returns (bool success);
    
     
     
    function closeFunding(uint _proposalID) internal;
   
     
     
     
     
     
    function sendPendingAmounts(        
        uint _from,
        uint _to,
        address _buyer) returns (bool);
        
     
     
    function withdrawPendingAmounts() returns (bool);
    
     
     
     
    function setFundingStartTime(
        uint _proposalID, 
        uint _startTime) external;
    
     
     
    function setFundingFueled(uint _proposalID) external;

     
    function ableTransfer();

     
    function disableTransfer();

     
     
     
    function blockTransfer(
        address _shareHolder, 
        uint _deadLine) external;
    
     
     
     
     
     
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

     
     
     
     
    function approve(
        address _spender, 
        uint256 _value) returns (bool success);
    
    event TokensCreated(address indexed Sender, address indexed TokenHolder, uint TokenAmount);
    event FundingRulesSet(address indexed Moderator, uint indexed ProposalId, uint AmountToFund, uint indexed StartTime, uint ClosingTime);
    event FundingFueled(uint indexed ProposalID, uint FundedAmount);
    event TransferAble();
    event TransferDisable();
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed Buyer, uint Amount);
    
}    

contract PassTokenManager is PassTokenManagerInterface {

 

    function Client() constant returns (address) {
        return passDao.ActualCommitteeRoom();
    }
   
    function totalSupply() constant external returns (uint256) {
        return totalTokenSupply;
    }
    
    function balanceOf(address _owner) constant external returns (uint256 balance) {
        return balances[_owner];
    }
     
    function Transferable() constant external returns (bool) {
        return transferable;
    }
 
    function allowance(
        address _owner, 
        address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function FundedAmount(uint _proposalID) constant external returns (uint) {
        return fundings[_proposalID].fundedAmount;
    }
  
    function AmountToFund(uint _proposalID) constant external returns (uint) {

        if (now > fundings[_proposalID].closingTime
            || now < fundings[_proposalID].startTime) {
            return 0;   
            } else return fundings[_proposalID].amountToFund;
    }
    
    function priceMultiplier(uint _proposalID) constant internal returns (uint) {
        return fundings[_proposalID].initialPriceMultiplier;
    }
    
    function priceDivisor(uint _proposalID, uint _saleDate) constant internal returns (uint) {
        uint _date = _saleDate;
        
        if (_saleDate > fundings[_proposalID].closingTime) _date = fundings[_proposalID].closingTime;
        if (_saleDate < fundings[_proposalID].startTime) _date = fundings[_proposalID].startTime;

        return 100 + 100*fundings[_proposalID].inflationRate*(_date - fundings[_proposalID].startTime)/(100*365 days);
    }
    
    function actualPriceDivisor(uint _proposalID) constant internal returns (uint) {
        return priceDivisor(_proposalID, now);
    }
    
    function TokenAmount(
        uint _weiAmount, 
        uint _priceMultiplier, 
        uint _priceDivisor) constant internal returns (uint) {
        
        uint _a = _weiAmount*_priceMultiplier;
        uint _multiplier = 100*_a;
        uint _amount = _multiplier/_priceDivisor;
        if (_a/_weiAmount != _priceMultiplier
            || _multiplier/100 != _a) return 0; 
        
        return _amount;
    }
    
    function weiAmount(
        uint _tokenAmount, 
        uint _priceMultiplier, 
        uint _priceDivisor) constant internal returns (uint) {
        
        uint _multiplier = _tokenAmount*_priceDivisor;
        uint _divisor = 100*_priceMultiplier;
        uint _amount = _multiplier/_divisor;
        if (_multiplier/_tokenAmount != _priceDivisor
            || _divisor/100 != _priceMultiplier) return 0; 

        return _amount;
    }
    
    function TokenPriceInWei(uint _tokenAmount, uint _proposalID) constant returns (uint) {
        return weiAmount(_tokenAmount, priceMultiplier(_proposalID), actualPriceDivisor(_proposalID));
    }
    
    function LastProposalID() constant returns (uint) {
        return lastProposalID;
    }
    
    function numberOfHolders() constant returns (uint) {
        return holders.length - 1;
    }
    
    function HolderAddress(uint _index) constant external returns (address) {
        return holders[_index];
    }

 

     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}
      
     
    modifier onlyShareManager {if (token) throw; _;}

     
    modifier onlyTokenManager {if (!token) throw; _;}
  
 

    function PassTokenManager(
        PassDao _passDao,
        address _clonedFrom,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        bool _token,
        bool _transferable,
        uint _initialPriceMultiplier,
        uint _inflationRate) {

        passDao = _passDao;
        creator = msg.sender;
        
        clonedFrom = _clonedFrom;            

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _tokenDecimals;

        token = _token;
        transferable = _transferable;

        fundings[0].initialPriceMultiplier = _initialPriceMultiplier;
        fundings[0].inflationRate = _inflationRate;

        holders.length = 1;
    }

 

    function initialTokenSupply(
        address _recipient, 
        uint _quantity,
        bool _last) returns (bool success) {

        if (initialTokenSupplyDone) throw;
        
        addHolder(_recipient);
        if (_recipient != 0 && _quantity != 0) createTokens(_recipient, _quantity);
        
        if (_last) initialTokenSupplyDone = true;
        
        return true;
    }

    function cloneTokens(
        uint _from,
        uint _to) returns (bool success) {
        
        initialTokenSupplyDone = true;
        if (_from == 0) _from = 1;
        
        PassTokenManager _clonedFrom = PassTokenManager(clonedFrom);
        uint _numberOfHolders = _clonedFrom.numberOfHolders();
        if (_to == 0 || _to > _numberOfHolders) _to = _numberOfHolders;
        
        address _holder;
        uint _balance;

        for (uint i = _from; i <= _to; i++) {
            _holder = _clonedFrom.HolderAddress(i);
            _balance = _clonedFrom.balanceOf(_holder);
            if (balances[_holder] == 0 && _balance != 0) {
                addHolder(_holder);
                createTokens(_holder, _balance);
            }
        }
    }
        
 

    function addHolder(address _holder) internal {
        
        if (holderID[_holder] == 0) {
            
            uint _holderID = holders.length++;
            holders[_holderID] = _holder;
            holderID[_holder] = _holderID;
        }
    }

    function createTokens(
        address _holder, 
        uint _tokenAmount) internal {

        balances[_holder] += _tokenAmount; 
        totalTokenSupply += _tokenAmount;
        TokensCreated(msg.sender, _holder, _tokenAmount);
    }
    
    function rewardTokensForClient(
        address _recipient, 
        uint _amount
        ) external onlyClient returns (uint) {

        uint _tokenAmount = TokenAmount(_amount, priceMultiplier(0), actualPriceDivisor(0));
        if (_tokenAmount == 0) throw;

        addHolder(_recipient);
        createTokens(_recipient, _tokenAmount);

        return _tokenAmount;
    }
    
    function setFundingRules(
        address _moderator,
        uint _initialPriceMultiplier,
        uint _amountToFund,
        uint _minutesFundingPeriod, 
        uint _inflationRate,
        uint _proposalID
    ) external onlyClient {

        if (_moderator == address(this)
            || _moderator == Client()
            || _amountToFund == 0
            || _minutesFundingPeriod == 0
            || fundings[_proposalID].totalWeiGiven != 0
            ) throw;
            
        fundings[_proposalID].moderator = _moderator;

        fundings[_proposalID].amountToFund = _amountToFund;
        fundings[_proposalID].fundedAmount = 0;

        if (_initialPriceMultiplier == 0) {
            if (now < fundings[0].closingTime) {
                fundings[_proposalID].initialPriceMultiplier = 100*priceMultiplier(lastProposalID)/actualPriceDivisor(lastProposalID);
            } else {
                fundings[_proposalID].initialPriceMultiplier = 100*priceMultiplier(lastFueledFundingID)/actualPriceDivisor(lastFueledFundingID);
            }
            fundings[0].initialPriceMultiplier = fundings[_proposalID].initialPriceMultiplier;
        }
        else {
            fundings[_proposalID].initialPriceMultiplier = _initialPriceMultiplier;
            fundings[0].initialPriceMultiplier = _initialPriceMultiplier;
        }
        
        if (_inflationRate == 0) fundings[_proposalID].inflationRate = fundings[0].inflationRate;
        else {
            fundings[_proposalID].inflationRate = _inflationRate;
            fundings[0].inflationRate = _inflationRate;
        }
        
        fundings[_proposalID].startTime = now;
        fundings[0].startTime = now;
        
        fundings[_proposalID].closingTime = now + _minutesFundingPeriod * 1 minutes;
        fundings[0].closingTime = fundings[_proposalID].closingTime;
        
        fundings[_proposalID].totalWeiGiven = 0;
        
        lastProposalID = _proposalID;
        
        FundingRulesSet(_moderator, _proposalID,  _amountToFund, fundings[_proposalID].startTime, fundings[_proposalID].closingTime);
    } 
    
    function sale(
        uint _proposalID,
        address _recipient, 
        uint _amount,
        uint _saleDate,
        bool _presale) internal returns (bool success) {

        if (_saleDate == 0) _saleDate = now;

        if (_saleDate > fundings[_proposalID].closingTime
            || _saleDate < fundings[_proposalID].startTime
            || fundings[_proposalID].totalWeiGiven + _amount > fundings[_proposalID].amountToFund) return;

        uint _tokenAmount = TokenAmount(_amount, priceMultiplier(_proposalID), priceDivisor(_proposalID, _saleDate));
        if (_tokenAmount == 0) return;
        
        addHolder(_recipient);
        if (_presale) {
            Given[_proposalID][_recipient].tokenAmount += _tokenAmount;
        }
        else createTokens(_recipient, _tokenAmount);

        return true;
    }

    function closeFunding(uint _proposalID) internal {
        fundings[_proposalID].fundedAmount = fundings[_proposalID].totalWeiGiven;
        lastFueledFundingID = _proposalID;
        fundings[_proposalID].closingTime = now;
        FundingFueled(_proposalID, fundings[_proposalID].fundedAmount);
    }

    function sendPendingAmounts(        
        uint _from,
        uint _to,
        address _buyer) returns (bool) {
        
        if (_from == 0) _from = 1;
        if (_to == 0) _to = lastProposalID;
        if (_buyer == 0) _buyer = msg.sender;

        uint _amount;
        uint _tokenAmount;
        
        for (uint i = _from; i <= _to; i++) {

            if (now > fundings[i].closingTime && Given[i][_buyer].weiAmount != 0) {
                
                if (fundings[i].fundedAmount == 0) _amount += Given[i][_buyer].weiAmount;
                else _tokenAmount += Given[i][_buyer].tokenAmount;

                fundings[i].totalWeiGiven -= Given[i][_buyer].weiAmount;
                Given[i][_buyer].tokenAmount = 0;
                Given[i][_buyer].weiAmount = 0;
            }
        }

        if (_tokenAmount > 0) {
            createTokens(_buyer, _tokenAmount);
            return true;
        }
        
        if (_amount > 0) {
            if (!_buyer.send(_amount)) throw;
            Refund(_buyer, _amount);
        } else return true;
    }
    

    function withdrawPendingAmounts() returns (bool) {
        
        return sendPendingAmounts(0, 0, msg.sender);
    }        

 

    function setFundingStartTime(uint _proposalID, uint _startTime) external {
        if ((msg.sender !=  fundings[_proposalID].moderator) || now > fundings[_proposalID].closingTime) throw;
        fundings[_proposalID].startTime = _startTime;
    }

    function setFundingFueled(uint _proposalID) external {

        if ((msg.sender !=  fundings[_proposalID].moderator) || now > fundings[_proposalID].closingTime) throw;

        closeFunding(_proposalID);
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
    
    function blockTransfer(address _shareHolder, uint _deadLine) external onlyClient onlyShareManager {
        if (_deadLine > blockedDeadLine[_shareHolder]) {
            blockedDeadLine[_shareHolder] = _deadLine;
        }
    }
    
    function transferFromTo(
        address _from,
        address _to, 
        uint256 _value
        ) internal returns (bool success) {  

        if ((transferable)
            && now > blockedDeadLine[_from]
            && now > blockedDeadLine[_to]
            && _to != address(this)
            && balances[_from] >= _value
            && balances[_to] + _value > balances[_to]) {

            addHolder(_to);
            balances[_from] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;

        } else return false;
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
    


pragma solidity ^0.4.8;

 

 
contract PassManager is PassTokenManager {
    
    struct order {
        address buyer;
        uint weiGiven;
    }
     
    order[] public orders;
     
    uint numberOfOrders;

     
    mapping (uint => bool) orderCloned;
    
    function PassManager(
        PassDao _passDao,
        address _clonedFrom,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        bool _token,
        bool _transferable,
        uint _initialPriceMultiplier,
        uint _inflationRate) 
        PassTokenManager( _passDao, _clonedFrom, _tokenName, _tokenSymbol, _tokenDecimals, 
            _token, _transferable, _initialPriceMultiplier, _inflationRate) { }
    
     
    function () payable onlyShareManager { }
    
     
     
     
     
    function sendTo(
        address _recipient,
        uint _amount
    ) external onlyClient returns (bool) {

        if (_recipient.send(_amount)) return true;
        else return false;
    }

     
     
     
     
     
     
    function buyTokensFor(
        uint _proposalID,
        address _buyer, 
        uint _date,
        bool _presale) internal returns (bool) {

        if (_proposalID == 0 || !sale(_proposalID, _buyer, msg.value, _date, _presale)) throw;

        fundings[_proposalID].totalWeiGiven += msg.value;        
        if (fundings[_proposalID].totalWeiGiven == fundings[_proposalID].amountToFund) closeFunding(_proposalID);

        Given[_proposalID][_buyer].weiAmount += msg.value;
        
        return true;
    }
    
     
     
     
     
    function buyTokensForProposal(
        uint _proposalID, 
        address _buyer) payable returns (bool) {

        if (_buyer == 0) _buyer = msg.sender;

        if (fundings[_proposalID].moderator != 0) throw;

        return buyTokensFor(_proposalID, _buyer, now, true);
    }

     
     
     
     
     
     
    function buyTokenFromModerator(
        uint _proposalID,
        address _buyer, 
        uint _date,
        bool _presale) payable external returns (bool){

        if (msg.sender != fundings[_proposalID].moderator) throw;

        return buyTokensFor(_proposalID, _buyer, _date, _presale);
    }

     
     
     
    function addOrder(
        address _buyer, 
        uint _weiGiven) internal {

        uint i;
        numberOfOrders += 1;

        if (numberOfOrders > orders.length) i = orders.length++;
        else i = numberOfOrders - 1;
        
        orders[i].buyer = _buyer;
        orders[i].weiGiven = _weiGiven;
    }

     
     
    function removeOrder(uint _order) internal {
        
        if (numberOfOrders - 1 < _order) return;

        numberOfOrders -= 1;
        if (numberOfOrders > 0) {
            for (uint i = _order; i <= numberOfOrders - 1; i++) {
                orders[i].buyer = orders[i+1].buyer;
                orders[i].weiGiven = orders[i+1].weiGiven;
            }
        }
        orders[numberOfOrders].buyer = 0;
        orders[numberOfOrders].weiGiven = 0;
    }
    
     
     
    function buyTokens() payable returns (bool) {

        if (!transferable || msg.value < 100 finney) throw;
        
        addOrder(msg.sender, msg.value);
        
        return true;
    }
    
     
     
     
     
     
    function sellTokens(
        uint _tokenAmount,
        uint _from,
        uint _to) returns (uint) {

        if (!transferable 
            || uint(balances[msg.sender]) < _amount 
            || numberOfOrders == 0) throw;
        
        if (_to == 0 || _to > numberOfOrders - 1) _to = numberOfOrders - 1;
        
        
        uint _tokenAmounto;
        uint _amount;
        uint _totalAmount;
        uint o = _from;

        for (uint i = _from; i <= _to; i++) {

            if (_tokenAmount > 0 && orders[o].buyer != msg.sender) {

                _tokenAmounto = TokenAmount(orders[o].weiGiven, priceMultiplier(0), actualPriceDivisor(0));

                if (_tokenAmount >= _tokenAmounto 
                    && transferFromTo(msg.sender, orders[o].buyer, _tokenAmounto)) {
                            
                    _tokenAmount -= _tokenAmounto;
                    _totalAmount += orders[o].weiGiven;
                    removeOrder(o);
                }
                else if (_tokenAmount < _tokenAmounto
                    && transferFromTo(msg.sender, orders[o].buyer, _tokenAmount)) {
                        
                    _amount = weiAmount(_tokenAmount, priceMultiplier(0), actualPriceDivisor(0));
                    orders[o].weiGiven -= _amount;
                    _totalAmount += _amount;
                    i = _to + 1;
                }
                else o += 1;
            } 
            else o += 1;
        }
        
        if (!msg.sender.send(_totalAmount)) throw;
        else return _totalAmount;
    }    

     
     
     
     
    function removeOrders(
        uint _from,
        uint _to) returns (bool) {

        if (_to == 0 || _to > numberOfOrders) _to = numberOfOrders -1;
        
        uint _totalAmount;
        uint o = _from;

        for (uint i = _from; i <= _to; i++) {

            if (orders[o].buyer == msg.sender) {
                
                _totalAmount += orders[o].weiGiven;
                removeOrder(o);

            } else o += 1;
        }

        if (!msg.sender.send(_totalAmount)) throw;
        else return true;
    }
    
}    


pragma solidity ^0.4.8;

 

 
contract PassProject {

     
    PassDao public passDao;
    
     
    string public name;
     
    string public description;
     
    bytes32 public hashOfTheDocument;
     
    address projectManager;

    struct order {
         
        address contractorAddress;
         
        uint contractorProposalID;
         
        uint amount;
         
        uint orderDate;
    }
     
    order[] public orders;
    
     
    uint public totalAmountOfOrders;

    struct resolution {
         
        string name;
         
        string description;
         
        uint creationDate;
    }
     
    resolution[] public resolutions;
    
 

    event OrderAdded(address indexed Client, address indexed ContractorAddress, uint indexed ContractorProposalID, uint Amount, uint OrderDate);
    event ProjectDescriptionUpdated(address indexed By, string NewDescription, bytes32 NewHashOfTheDocument);
    event ResolutionAdded(address indexed Client, uint indexed ResolutionID, string Name, string Description);

 

     
    function Client() constant returns (address) {
        return passDao.ActualCommitteeRoom();
    }
    
     
    function numberOfOrders() constant returns (uint) {
        return orders.length - 1;
    }
    
     
    function ProjectManager() constant returns (address) {
        return projectManager;
    }

     
    function numberOfResolutions() constant returns (uint) {
        return resolutions.length - 1;
    }
    
 

     
    modifier onlyProjectManager {if (msg.sender != projectManager) throw; _;}

     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}

 

    function PassProject(
        PassDao _passDao, 
        string _name,
        string _description,
        bytes32 _hashOfTheDocument) {

        passDao = _passDao;
        name = _name;
        description = _description;
        hashOfTheDocument = _hashOfTheDocument;
        
        orders.length = 1;
        resolutions.length = 1;
    }
    
 

     
     
     
     
     
    function addOrder(

        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _amount, 
        uint _orderDate) internal {

        uint _orderID = orders.length++;
        order d = orders[_orderID];
        d.contractorAddress = _contractorAddress;
        d.contractorProposalID = _contractorProposalID;
        d.amount = _amount;
        d.orderDate = _orderDate;
        
        totalAmountOfOrders += _amount;
        
        OrderAdded(msg.sender, _contractorAddress, _contractorProposalID, _amount, _orderDate);
    }
    
 

     
     
     
     
     
    function cloneOrder(
        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _orderAmount, 
        uint _lastOrderDate) {
        
        if (projectManager != 0) throw;
        
        addOrder(_contractorAddress, _contractorProposalID, _orderAmount, _lastOrderDate);
    }
    
     
     
     
    function setProjectManager(address _projectManager) returns (bool) {

        if (_projectManager == 0 || projectManager != 0) return;
        
        projectManager = _projectManager;
        
        return true;
    }

 

     
     
     
    function updateDescription(string _projectDescription, bytes32 _hashOfTheDocument) onlyProjectManager {
        description = _projectDescription;
        hashOfTheDocument = _hashOfTheDocument;
        ProjectDescriptionUpdated(msg.sender, _projectDescription, _hashOfTheDocument);
    }

 

     
     
     
     
    function newOrder(
        address _contractorAddress, 
        uint _contractorProposalID, 
        uint _amount) onlyClient {
            
        addOrder(_contractorAddress, _contractorProposalID, _amount, now);
    }
    
     
     
     
    function newResolution(
        string _name, 
        string _description) onlyClient {

        uint _resolutionID = resolutions.length++;
        resolution d = resolutions[_resolutionID];
        
        d.name = _name;
        d.description = _description;
        d.creationDate = now;

        ResolutionAdded(msg.sender, _resolutionID, d.name, d.description);
    }
}

contract PassProjectCreator {
    
    event NewPassProject(PassDao indexed Dao, PassProject indexed Project, string Name, string Description, bytes32 HashOfTheDocument);

     
     
     
     
     
    function createProject(
        PassDao _passDao,
        string _name, 
        string _description, 
        bytes32 _hashOfTheDocument
        ) returns (PassProject) {

        PassProject _passProject = new PassProject(_passDao, _name, _description, _hashOfTheDocument);

        NewPassProject(_passDao, _passProject, _name, _description, _hashOfTheDocument);

        return _passProject;
    }
}
    

pragma solidity ^0.4.8;

 

 
contract PassContractor {
    
     
    PassProject passProject;
    
     
    address public creator;
     
    address public recipient;

     
    uint public smartContractStartDate;

    struct proposal {
         
        uint amount;
         
        string description;
         
        bytes32 hashOfTheDocument;
         
        uint dateOfProposal;
         
        uint submittedAmount;
         
        uint orderAmount;
         
        uint dateOfLastOrder;
    }
     
    proposal[] public proposals;

 

    event RecipientUpdated(address indexed By, address LastRecipient, address NewRecipient);
    event Withdrawal(address indexed By, address indexed Recipient, uint Amount);
    event ProposalAdded(address Creator, uint indexed ProposalID, uint Amount, string Description, bytes32 HashOfTheDocument);
    event ProposalSubmitted(address indexed Client, uint Amount);
    event Order(address indexed Client, uint indexed ProposalID, uint Amount);

 

     
    function Client() constant returns (address) {
        return passProject.Client();
    }

     
    function Project() constant returns (PassProject) {
        return passProject;
    }
    
     
     
     
     
     
    function proposalChecked(
        address _sender,
        uint _proposalID, 
        uint _amount) constant external onlyClient returns (bool) {
        if (_sender != recipient && _sender != creator) return;
        if (_amount <= proposals[_proposalID].amount - proposals[_proposalID].submittedAmount) return true;
    }

     
    function numberOfProposals() constant returns (uint) {
        return proposals.length - 1;
    }


 

     
    modifier onlyContractor {if (msg.sender != recipient) throw; _;}
    
     
    modifier onlyClient {if (msg.sender != Client()) throw; _;}

 

    function PassContractor(
        address _creator, 
        PassProject _passProject, 
        address _recipient,
        bool _restore) { 

        if (address(_passProject) == 0) throw;
        
        creator = _creator;
        if (_recipient == 0) _recipient = _creator;
        recipient = _recipient;
        
        passProject = _passProject;
        
        if (!_restore) smartContractStartDate = now;

        proposals.length = 1;
    }

 

     
     
     
     
     
     
     
     
     
    function cloneProposal(
        uint _amount,
        string _description,
        bytes32 _hashOfTheDocument,
        uint _dateOfProposal,
        uint _orderAmount,
        uint _dateOfOrder,
        bool _cloneOrder
    ) returns (bool success) {
            
        if (smartContractStartDate != 0 || recipient == 0
        || msg.sender != creator) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = _dateOfProposal;
        c.orderAmount = _orderAmount;
        c.dateOfLastOrder = _dateOfOrder;

        ProposalAdded(msg.sender, _proposalID, _amount, _description, _hashOfTheDocument);
        
        if (_cloneOrder) passProject.cloneOrder(address(this), _proposalID, _orderAmount, _dateOfOrder);
        
        return true;
    }

     
     
    function closeSetup() returns (bool) {
        
        if (smartContractStartDate != 0 
            || (msg.sender != creator && msg.sender != Client())) return;

        smartContractStartDate = now;

        return true;
    }
    
 

     
     
    function updateRecipient(address _newRecipient) onlyContractor {

        if (_newRecipient == 0) throw;

        RecipientUpdated(msg.sender, recipient, _newRecipient);
        recipient = _newRecipient;
    } 

     
    function () payable { }
    
     
     
    function withdraw(uint _amount) onlyContractor {
        if (!recipient.send(_amount)) throw;
        Withdrawal(msg.sender, recipient, _amount);
    }
    
 

     
     
     
    function updateProjectDescription(string _projectDescription, bytes32 _hashOfTheDocument) onlyContractor {
        passProject.updateDescription(_projectDescription, _hashOfTheDocument);
    }
    
 

     
     
     
     
     
     
    function newProposal(
        address _creator,
        uint _amount,
        string _description, 
        bytes32 _hashOfTheDocument
    ) external returns (uint) {
        
        if (msg.sender == Client() && _creator != recipient && _creator != creator) throw;
        if (msg.sender != Client() && msg.sender != recipient && msg.sender != creator) throw;

        if (_amount == 0) throw;
        
        uint _proposalID = proposals.length++;
        proposal c = proposals[_proposalID];

        c.amount = _amount;
        c.description = _description;
        c.hashOfTheDocument = _hashOfTheDocument; 
        c.dateOfProposal = now;
        
        ProposalAdded(msg.sender, _proposalID, c.amount, c.description, c.hashOfTheDocument);
        
        return _proposalID;
    }
    
     
     
     
     
    function submitProposal(
        address _sender, 
        uint _proposalID, 
        uint _amount) onlyClient {

        if (_sender != recipient && _sender != creator) throw;    
        proposals[_proposalID].submittedAmount += _amount;
        ProposalSubmitted(msg.sender, _amount);
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
        c.dateOfLastOrder = now;
        
        Order(msg.sender, _proposalID, _orderAmount);
        
        return true;
    }
    
}

contract PassContractorCreator {
    
     
    PassDao public passDao;
     
    PassProjectCreator public projectCreator;
    
    struct contractor {
         
        address creator;
         
        PassContractor contractor;
         
        address recipient;
         
        bool metaProject;
         
        PassProject passProject;
         
        string projectName;
         
        string projectDescription;
         
        uint creationDate;
    }
     
    contractor[] public contractors;
    
    event NewPassContractor(address indexed Creator, address indexed Recipient, PassProject indexed Project, PassContractor Contractor);

    function PassContractorCreator(PassDao _passDao, PassProjectCreator _projectCreator) {
        passDao = _passDao;
        projectCreator = _projectCreator;
        contractors.length = 0;
    }

     
    function numberOfContractors() constant returns (uint) {
        return contractors.length;
    }
    
     
     
     
     
     
     
     
     
     
    function createContractor(
        address _creator,
        address _recipient, 
        bool _metaProject,
        PassProject _passProject,
        string _projectName, 
        string _projectDescription,
        bool _restore) returns (PassContractor) {
 
        PassProject _project;

        if (_creator == 0) _creator = msg.sender;
        
        if (_metaProject) _project = PassProject(passDao.MetaProject());
        else if (address(_passProject) == 0) 
            _project = projectCreator.createProject(passDao, _projectName, _projectDescription, 0);
        else _project = _passProject;

        PassContractor _contractor = new PassContractor(_creator, _project, _recipient, _restore);
        if (!_metaProject && address(_passProject) == 0 && !_restore) _project.setProjectManager(address(_contractor));
        
        uint _contractorID = contractors.length++;
        contractor c = contractors[_contractorID];
        c.creator = _creator;
        c.contractor = _contractor;
        c.recipient = _recipient;
        c.metaProject = _metaProject;
        c.passProject = _passProject;
        c.projectName = _projectName;
        c.projectDescription = _projectDescription;
        c.creationDate = now;

        NewPassContractor(_creator, _recipient, _project, _contractor);
 
        return _contractor;
    }
    
}


pragma solidity ^0.4.8;

 

 
contract PassCommitteeRoomInterface {

     
    PassDao public passDao;

    enum ProposalTypes { contractor, resolution, rules, upgrade }

    struct Committee {        
         
        address creator;  
         
        ProposalTypes proposalType;
         
        uint proposalID;
         
        uint setDeadline;
         
        uint fees;
         
        uint totalRewardedAmount;
         
        uint votingDeadline;
         
        bool open; 
         
        uint dateOfExecution;
         
        uint yea; 
         
        uint nay; 
    }
     
    Committee[] public Committees; 
     
    mapping (uint => mapping (address => bool)) hasVoted;

    struct Proposal {
         
        uint committeeID;
         
        PassContractor contractor;
         
        uint contractorProposalID;
         
        uint amount;
         
        address moderator;
         
        uint amountForShares;
         
        uint initialSharePriceMultiplier; 
         
        uint amountForTokens;
         
        uint minutesFundingPeriod;
         
        bool open; 
    }
     
    Proposal[] public Proposals;

    struct Question {
         
        uint committeeID; 
         
        PassProject project;
         
        string name;
         
        string description;
    }
     
    Question[] public ResolutionProposals;
    
    struct Rules {
         
        uint committeeID; 
         
        uint minQuorumDivisor;  
         
        uint minCommitteeFees; 
         
        uint minPercentageOfLikes;
         
        uint minutesSetProposalPeriod; 
         
        uint minMinutesDebatePeriod;
         
        uint feesRewardInflationRate;
         
        uint tokenPriceInflationRate;
         
        uint defaultMinutesFundingPeriod;
    } 
     
    Rules[] public rulesProposals;

    struct Upgrade {
         
        uint committeeID; 
         
        address newCommitteeRoom;
         
        address newShareManager;
         
        address newTokenManager;
    }
     
    Upgrade[] public UpgradeProposals;
    
     
    uint minMinutesPeriods;
     
    uint maxInflationRate;
    
     
    function ShareManager() constant returns (PassManager);

     
    function TokenManager() constant returns (PassManager);

     
    function Balance() constant returns (uint);
    
     
     
     
    function HasVoted(
        uint _committeeID, 
        address _shareHolder) constant external returns (bool);
    
     
    function minQuorum() constant returns (uint);

     
    function numberOfCommittees() constant returns (uint);
    
     
     
     

     
     
     
     
     
     
     
     
     
     
     
    function init(
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _minQuorumDivisor,
        uint _minCommitteeFees,
        uint _minPercentageOfLikes,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        uint _tokenPriceInflationRate,
        uint _defaultMinutesFundingPeriod);

     
     
     
     
     
     
     
     
    function createContractor(
        PassContractorCreator _contractorCreator,
        address _recipient,
        bool _metaProject,
        PassProject _passProject,
        string _projectName, 
        string _projectDescription) returns (PassContractor);
    
     
     
     
     
     
     
     
     
     
     
     
    function contractorProposal(
        uint _amount,
        PassContractor _contractor,
        uint _contractorProposalID,
        string _proposalDescription, 
        bytes32 _hashOfTheContractorProposalDocument,
        address _moderator,
        uint _initialSharePriceMultiplier, 
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod) payable returns (uint);

     
     
     
     
     
     
    function resolutionProposal(
        string _name,
        string _description,
        PassProject _project,
        uint _minutesDebatingPeriod) payable returns (uint);
        
     
     
     
     
     
     
     
     
     
     
    function rulesProposal(
        uint _minQuorumDivisor, 
        uint _minCommitteeFees,
        uint _minPercentageOfLikes,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        uint _defaultMinutesFundingPeriod,
        uint _tokenPriceInflationRate) payable returns (uint);
    
     
     
     
     
     
     
    function upgradeProposal(
        address _newCommitteeRoom,
        address _newShareManager,
        address _newTokenManager,
        uint _minutesDebatingPeriod) payable returns (uint);

     
     
     
     
     
    function newCommittee(
        ProposalTypes _proposalType,
        uint _proposalID, 
        uint _minutesDebatingPeriod) internal returns (uint);
        
     
     
     
    function vote(
        uint _committeeID, 
        bool _supportsProposal);
    
     
     
     
    function executeDecision(uint _committeeID) returns (bool);
    
     
     
     
    function orderToContractor(uint _proposalID) returns (bool);   

     
     
     
    function buySharesForProposal(uint _proposalID) payable returns (bool);
    
     
     
     
     
     
    function sendPendingAmounts(        
        uint _from,
        uint _to,
        address _buyer) returns (bool);
        
     
     
    function withdrawPendingAmounts() returns (bool);

    event CommitteeLimits(uint maxInflationRate, uint minMinutesPeriods);
    
    event ContractorCreated(PassContractorCreator Creator, address indexed Sender, PassContractor Contractor, address Recipient);

    event ProposalSubmitted(uint indexed ProposalID, uint CommitteeID, PassContractor indexed Contractor, uint indexed ContractorProposalID, 
        uint Amount, string Description, address Moderator, uint SharePriceMultiplier, uint MinutesFundingPeriod);
    event ResolutionProposalSubmitted(uint indexed QuestionID, uint indexed CommitteeID, PassProject indexed Project, string Name, string Description);
    event RulesProposalSubmitted(uint indexed rulesProposalID, uint CommitteeID, uint MinQuorumDivisor, uint MinCommitteeFees, uint MinPercentageOfLikes, 
        uint MinutesSetProposalPeriod, uint MinMinutesDebatePeriod, uint FeesRewardInflationRate, uint DefaultMinutesFundingPeriod, uint TokenPriceInflationRate);
    event UpgradeProposalSubmitted(uint indexed UpgradeProposalID, uint indexed CommitteeID, address NewCommitteeRoom, 
        address NewShareManager, address NewTokenManager);

    event Voted(uint indexed CommitteeID, bool Position, address indexed Voter, uint RewardedAmount);

    event ProposalClosed(uint indexed ProposalID, ProposalTypes indexed ProposalType, uint CommitteeID, 
        uint TotalRewardedAmount, bool ProposalExecuted, uint RewardedSharesAmount, uint SentToManager);
    event ContractorProposalClosed(uint indexed ProposalID, uint indexed ContractorProposalID, PassContractor indexed Contractor, uint AmountSent);
    event DappUpgraded(address NewCommitteeRoom, address NewShareManager, address NewTokenManager);

}

contract PassCommitteeRoom is PassCommitteeRoomInterface {

 

    function ShareManager() constant returns (PassManager) {
        return PassManager(passDao.ActualShareManager());
    }
    
    function TokenManager() constant returns (PassManager) {
        return PassManager(passDao.ActualTokenManager());
    }
    
    function Balance() constant returns (uint) {
        return passDao.ActualShareManager().balance;
    }

    function HasVoted(
        uint _committeeID, 
        address _shareHolder) constant external returns (bool) {

        if (_shareHolder == 0) return hasVoted[_committeeID][msg.sender];
        else return hasVoted[_committeeID][_shareHolder];
    }
    
    function minQuorum() constant returns (uint) {
        return (uint(ShareManager().totalSupply()) / rulesProposals[0].minQuorumDivisor);
    }

    function numberOfCommittees() constant returns (uint) {
        return Committees.length - 1;
    }
    
 

    function PassCommitteeRoom(address _passDao) {

        passDao = PassDao(_passDao);
        rulesProposals.length = 1; 
        Committees.length = 1;
        Proposals.length = 1;
        ResolutionProposals.length = 1;
        UpgradeProposals.length = 1;
    }
    
    function init(
        uint _maxInflationRate,
        uint _minMinutesPeriods,
        uint _minQuorumDivisor,
        uint _minCommitteeFees,
        uint _minPercentageOfLikes,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        uint _tokenPriceInflationRate,
        uint _defaultMinutesFundingPeriod) {

        maxInflationRate = _maxInflationRate;
        minMinutesPeriods = _minMinutesPeriods;
        CommitteeLimits(maxInflationRate, minMinutesPeriods);
        
        if (rulesProposals[0].minQuorumDivisor != 0) throw;
        rulesProposals[0].minQuorumDivisor = _minQuorumDivisor;
        rulesProposals[0].minCommitteeFees = _minCommitteeFees;
        rulesProposals[0].minPercentageOfLikes = _minPercentageOfLikes;
        rulesProposals[0].minutesSetProposalPeriod = _minutesSetProposalPeriod;
        rulesProposals[0].minMinutesDebatePeriod = _minMinutesDebatePeriod;
        rulesProposals[0].feesRewardInflationRate = _feesRewardInflationRate;
        rulesProposals[0].tokenPriceInflationRate = _tokenPriceInflationRate;
        rulesProposals[0].defaultMinutesFundingPeriod = _defaultMinutesFundingPeriod;

    }

 

    function createContractor(
        PassContractorCreator _contractorCreator,
        address _recipient,
        bool _metaProject,
        PassProject _passProject,
        string _projectName, 
        string _projectDescription) returns (PassContractor) {

        PassContractor _contractor = _contractorCreator.createContractor(msg.sender, _recipient, 
            _metaProject, _passProject, _projectName, _projectDescription, false);
        ContractorCreated(_contractorCreator, msg.sender, _contractor, _recipient);
        return _contractor;
    }   

 

    function contractorProposal(
        uint _amount,
        PassContractor _contractor,
        uint _contractorProposalID,
        string _proposalDescription, 
        bytes32 _hashOfTheContractorProposalDocument,        
        address _moderator,
        uint _initialSharePriceMultiplier, 
        uint _minutesFundingPeriod,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {

        if (_minutesFundingPeriod == 0) _minutesFundingPeriod = rulesProposals[0].defaultMinutesFundingPeriod;

        if (address(_contractor) != 0 && _contractorProposalID != 0) {
            if (_hashOfTheContractorProposalDocument != 0 
                ||!_contractor.proposalChecked(msg.sender, _contractorProposalID, _amount)) throw;
            else _proposalDescription = "Proposal checked";
        }

        if ((address(_contractor) != 0 && _contractorProposalID == 0 && _hashOfTheContractorProposalDocument == 0)
            || _amount == 0
            || _minutesFundingPeriod < minMinutesPeriods) throw;

        uint _proposalID = Proposals.length++;
        Proposal p = Proposals[_proposalID];

        p.contractor = _contractor;
        
        if (_contractorProposalID == 0 && _hashOfTheContractorProposalDocument != 0) {
            _contractorProposalID = _contractor.newProposal(msg.sender, _amount, _proposalDescription, _hashOfTheContractorProposalDocument);
        }
        p.contractorProposalID = _contractorProposalID;

        if (address(_contractor) == 0) p.amountForShares = _amount;
        else {
            _contractor.submitProposal(msg.sender, _contractorProposalID, _amount);
            if (_contractor.Project().ProjectManager() == address(_contractor)) p.amountForTokens = _amount;
            else {
                p.amount = Balance();
                if (_amount > p.amount) p.amountForShares = _amount - p.amount;
                else p.amount = _amount;
            }
        }
        
        p.moderator = _moderator;

        p.initialSharePriceMultiplier = _initialSharePriceMultiplier;

        p.minutesFundingPeriod = _minutesFundingPeriod;

        p.committeeID = newCommittee(ProposalTypes.contractor, _proposalID, _minutesDebatingPeriod);   

        p.open = true;
        
        ProposalSubmitted(_proposalID, p.committeeID, p.contractor, p.contractorProposalID, p.amount+p.amountForShares+p.amountForTokens, 
            _proposalDescription, p.moderator, p.initialSharePriceMultiplier, p.minutesFundingPeriod);

        return _proposalID;
    }

    function resolutionProposal(
        string _name,
        string _description,
        PassProject _project,
        uint _minutesDebatingPeriod) payable returns (uint) {
        
        if (address(_project) == 0) _project = PassProject(passDao.MetaProject());
        
        uint _questionID = ResolutionProposals.length++;
        Question q = ResolutionProposals[_questionID];
        
        q.project = _project;
        q.name = _name;
        q.description = _description;
        
        q.committeeID = newCommittee(ProposalTypes.resolution, _questionID, _minutesDebatingPeriod);
        
        ResolutionProposalSubmitted(_questionID, q.committeeID, q.project, q.name, q.description);
        
        return _questionID;
    }

    function rulesProposal(
        uint _minQuorumDivisor, 
        uint _minCommitteeFees,
        uint _minPercentageOfLikes,
        uint _minutesSetProposalPeriod,
        uint _minMinutesDebatePeriod,
        uint _feesRewardInflationRate,
        uint _defaultMinutesFundingPeriod,
        uint _tokenPriceInflationRate) payable returns (uint) {

    
        if (_minQuorumDivisor <= 1
            || _minQuorumDivisor > 10
            || _minutesSetProposalPeriod < minMinutesPeriods
            || _minMinutesDebatePeriod < minMinutesPeriods
            || _feesRewardInflationRate > maxInflationRate
            || _tokenPriceInflationRate > maxInflationRate
            || _defaultMinutesFundingPeriod < minMinutesPeriods) throw; 
        
        uint _rulesProposalID = rulesProposals.length++;
        Rules r = rulesProposals[_rulesProposalID];

        r.minQuorumDivisor = _minQuorumDivisor;
        r.minCommitteeFees = _minCommitteeFees;
        r.minPercentageOfLikes = _minPercentageOfLikes;
        r.minutesSetProposalPeriod = _minutesSetProposalPeriod;
        r.minMinutesDebatePeriod = _minMinutesDebatePeriod;
        r.feesRewardInflationRate = _feesRewardInflationRate;
        r.defaultMinutesFundingPeriod = _defaultMinutesFundingPeriod;
        r.tokenPriceInflationRate = _tokenPriceInflationRate;

        r.committeeID = newCommittee(ProposalTypes.rules, _rulesProposalID, 0);

        RulesProposalSubmitted(_rulesProposalID, r.committeeID, _minQuorumDivisor, _minCommitteeFees, 
            _minPercentageOfLikes, _minutesSetProposalPeriod, _minMinutesDebatePeriod, 
            _feesRewardInflationRate, _defaultMinutesFundingPeriod, _tokenPriceInflationRate);

        return _rulesProposalID;
    }
    
    function upgradeProposal(
        address _newCommitteeRoom,
        address _newShareManager,
        address _newTokenManager,
        uint _minutesDebatingPeriod
    ) payable returns (uint) {
        
        uint _upgradeProposalID = UpgradeProposals.length++;
        Upgrade u = UpgradeProposals[_upgradeProposalID];
        
        u.newCommitteeRoom = _newCommitteeRoom;
        u.newShareManager = _newShareManager;
        u.newTokenManager = _newTokenManager;

        u.committeeID = newCommittee(ProposalTypes.upgrade, _upgradeProposalID, _minutesDebatingPeriod);
        
        UpgradeProposalSubmitted(_upgradeProposalID, u.committeeID, u.newCommitteeRoom, u.newShareManager, u.newTokenManager);
        
        return _upgradeProposalID;
    }
    
 

    function newCommittee(
        ProposalTypes _proposalType,
        uint _proposalID, 
        uint _minutesDebatingPeriod
    ) internal returns (uint) {

        if (_minutesDebatingPeriod == 0) _minutesDebatingPeriod = rulesProposals[0].minMinutesDebatePeriod;
        
        if (passDao.ActualCommitteeRoom() != address(this)
            || msg.value < rulesProposals[0].minCommitteeFees
            || now + ((rulesProposals[0].minutesSetProposalPeriod + _minutesDebatingPeriod) * 1 minutes) < now
            || _minutesDebatingPeriod < rulesProposals[0].minMinutesDebatePeriod
            || msg.sender == address(this)) throw;

        uint _committeeID = Committees.length++;
        Committee b = Committees[_committeeID];

        b.creator = msg.sender;

        b.proposalType = _proposalType;
        b.proposalID = _proposalID;

        b.fees = msg.value;
        
        b.setDeadline = now + (rulesProposals[0].minutesSetProposalPeriod * 1 minutes);        
        b.votingDeadline = b.setDeadline + (_minutesDebatingPeriod * 1 minutes); 

        b.open = true; 

        return _committeeID;
    }
    
    function vote(
        uint _committeeID, 
        bool _supportsProposal) {
        
        Committee b = Committees[_committeeID];

        if (hasVoted[_committeeID][msg.sender] 
            || now < b.setDeadline
            || now > b.votingDeadline) throw;
            
        PassManager _shareManager = ShareManager();

        uint _balance = uint(_shareManager.balanceOf(msg.sender));
        if (_balance == 0) throw;
        
        hasVoted[_committeeID][msg.sender] = true;

        _shareManager.blockTransfer(msg.sender, b.votingDeadline);

        if (_supportsProposal) b.yea += _balance;
        else b.nay += _balance; 

        uint _a = 100*b.fees;
        if ((_a/100 != b.fees) || ((_a*_balance)/_a != _balance)) throw;
        uint _multiplier = (_a*_balance)/uint(_shareManager.totalSupply());
        uint _divisor = 100 + 100*rulesProposals[0].feesRewardInflationRate*(now - b.setDeadline)/(100*365 days);
        uint _rewardedamount = _multiplier/_divisor;
        if (b.totalRewardedAmount + _rewardedamount > b.fees) _rewardedamount = b.fees - b.totalRewardedAmount;
        b.totalRewardedAmount += _rewardedamount;
        if (!msg.sender.send(_rewardedamount)) throw;

        Voted(_committeeID, _supportsProposal, msg.sender, _rewardedamount);    
}

 

    function executeDecision(uint _committeeID) returns (bool) {

        Committee b = Committees[_committeeID];
        
        if (now < b.votingDeadline || !b.open) return;
        
        b.open = false;

        PassManager _shareManager = ShareManager();
        uint _quantityOfShares;
        PassManager _tokenManager = TokenManager();

        if (100*b.yea > rulesProposals[0].minPercentageOfLikes * uint(_shareManager.totalSupply())) {       
            _quantityOfShares = _shareManager.rewardTokensForClient(b.creator, rulesProposals[0].minCommitteeFees);
        }        

        uint _sentToDaoManager = b.fees - b.totalRewardedAmount;
        if (_sentToDaoManager > 0) {
            if (!address(_shareManager).send(_sentToDaoManager)) throw;
        }
        
        if (b.yea + b.nay < minQuorum() || b.yea <= b.nay) {
            if (b.proposalType == ProposalTypes.contractor) Proposals[b.proposalID].open = false;
            ProposalClosed(b.proposalID, b.proposalType, _committeeID, b.totalRewardedAmount, false, _quantityOfShares, _sentToDaoManager);
            return;
        }

        b.dateOfExecution = now;

        if (b.proposalType == ProposalTypes.contractor) {

            Proposal p = Proposals[b.proposalID];
    
            if (p.contractorProposalID == 0) p.open = false;
            
            if (p.amountForShares == 0 && p.amountForTokens == 0) orderToContractor(b.proposalID);
            else {
                if (p.amountForShares != 0) {
                    _shareManager.setFundingRules(p.moderator, p.initialSharePriceMultiplier, p.amountForShares, p.minutesFundingPeriod, 0, b.proposalID);
                }

                if (p.amountForTokens != 0) {
                    _tokenManager.setFundingRules(p.moderator, 0, p.amountForTokens, p.minutesFundingPeriod, rulesProposals[0].tokenPriceInflationRate, b.proposalID);
                }
            }

        } else if (b.proposalType == ProposalTypes.resolution) {
            
            Question q = ResolutionProposals[b.proposalID];
            
            q.project.newResolution(q.name, q.description);
            
        } else if (b.proposalType == ProposalTypes.rules) {

            Rules r = rulesProposals[b.proposalID];
            
            rulesProposals[0].committeeID = r.committeeID;
            rulesProposals[0].minQuorumDivisor = r.minQuorumDivisor;
            rulesProposals[0].minMinutesDebatePeriod = r.minMinutesDebatePeriod; 
            rulesProposals[0].minCommitteeFees = r.minCommitteeFees;
            rulesProposals[0].minPercentageOfLikes = r.minPercentageOfLikes;
            rulesProposals[0].minutesSetProposalPeriod = r.minutesSetProposalPeriod;
            rulesProposals[0].feesRewardInflationRate = r.feesRewardInflationRate;
            rulesProposals[0].tokenPriceInflationRate = r.tokenPriceInflationRate;
            rulesProposals[0].defaultMinutesFundingPeriod = r.defaultMinutesFundingPeriod;

        } else if (b.proposalType == ProposalTypes.upgrade) {

            Upgrade u = UpgradeProposals[b.proposalID];

            if ((u.newShareManager != 0) && (u.newShareManager != address(_shareManager))) {
                _shareManager.disableTransfer();
                if (_shareManager.balance > 0) {
                    if (!_shareManager.sendTo(u.newShareManager, _shareManager.balance)) throw;
                }
            }

            if ((u.newTokenManager != 0) && (u.newTokenManager != address(_tokenManager))) {
                _tokenManager.disableTransfer();
            }

            passDao.upgrade(u.newCommitteeRoom, u.newShareManager, u.newTokenManager);
                
            DappUpgraded(u.newCommitteeRoom, u.newShareManager, u.newTokenManager);
            
        }

        ProposalClosed(b.proposalID, b.proposalType, _committeeID , b.totalRewardedAmount, true, _quantityOfShares, _sentToDaoManager);
            
        return true;
    }
    
    function orderToContractor(uint _proposalID) returns (bool) {
        
        Proposal p = Proposals[_proposalID];
        Committee b = Committees[p.committeeID];

        if (b.open || !p.open) return;
        
        uint _amountForShares;
        uint _amountForTokens;

        if (p.amountForShares != 0) {
            _amountForShares = ShareManager().FundedAmount(_proposalID);
            if (_amountForShares == 0 && now <= b.dateOfExecution + (p.minutesFundingPeriod * 1 minutes)) return;
        }

        if (p.amountForTokens != 0) {
            _amountForTokens = TokenManager().FundedAmount(_proposalID);
            if (_amountForTokens == 0 && now <= b.dateOfExecution + (p.minutesFundingPeriod * 1 minutes)) return;
        }
        
        p.open = false;   

        uint _amount = p.amount + _amountForShares + _amountForTokens;

        PassProject _project = PassProject(p.contractor.Project());

        if (_amount == 0) {
            ContractorProposalClosed(_proposalID, p.contractorProposalID, p.contractor, 0);
            return;
        }    

        if (!p.contractor.order(p.contractorProposalID, _amount)) throw;
        
        if (p.amount + _amountForShares > 0) {
            if (!ShareManager().sendTo(p.contractor, p.amount + _amountForShares)) throw;
        }
        if (_amountForTokens > 0) {
            if (!TokenManager().sendTo(p.contractor, _amountForTokens)) throw;
        }

        ContractorProposalClosed(_proposalID, p.contractorProposalID, p.contractor, _amount);
        
        passDao.addProject(_project);
        _project.newOrder(p.contractor, p.contractorProposalID, _amount);
        
        return true;
    }

 

    function buySharesForProposal(uint _proposalID) payable returns (bool) {
        
        return ShareManager().buyTokensForProposal.value(msg.value)(_proposalID, msg.sender);
    }   

    function sendPendingAmounts(
        uint _from,
        uint _to,
        address _buyer) returns (bool) {
        
        return ShareManager().sendPendingAmounts(_from, _to, _buyer);
    }        
    
    function withdrawPendingAmounts() returns (bool) {
        
        if (!ShareManager().sendPendingAmounts(0, 0, msg.sender)) throw;
    }        
            
}