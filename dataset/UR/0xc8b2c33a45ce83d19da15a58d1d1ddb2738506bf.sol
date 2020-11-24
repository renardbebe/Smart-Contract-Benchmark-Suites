 

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