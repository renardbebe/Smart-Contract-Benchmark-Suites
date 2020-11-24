 

pragma solidity ^0.4.18;

 
 
 

contract CompanyAccessControl {
    
    address public ceoAddress;
    address public cfoAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function setCEO(address _newCEO) 
    onlyCEO 
    external {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) 
    onlyCEO 
    external {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() 
    onlyCLevel
    external 
    whenNotPaused {
        paused = true;
    }

    function unpause() 
    onlyCLevel 
    whenPaused 
    external {
        paused = false;
    }
}

 
contract BookKeeping {
    
    struct ShareHolders {
        mapping(address => uint) ownerAddressToShares;
        uint numberOfShareHolders;
    }
    
     
    function _sharesBought(ShareHolders storage _shareHolders, address _owner, uint _amount) 
    internal {
         
        if (_shareHolders.ownerAddressToShares[_owner] == 0) {
            _shareHolders.numberOfShareHolders += 1;
        }
        _shareHolders.ownerAddressToShares[_owner] += _amount;
        
    }

     
    function _sharesSold(ShareHolders storage _shareHolders, address _owner, uint _amount) 
    internal {
        _shareHolders.ownerAddressToShares[_owner] -= _amount;
        
         
        if (_shareHolders.ownerAddressToShares[_owner] == 0) {
            _shareHolders.numberOfShareHolders -= 1;
        }
    }
}


contract CompanyConstants {
     
    uint constant TRADING_COMPETITION_PERIOD = 5 days;
    
     
    uint constant MAX_PERCENTAGE_SHARE_RELEASE = 5;
    
    uint constant MAX_CLAIM_SHARES_PERCENTAGE = 5;
    
     
     
    uint constant MIN_COOLDOWN_TIME = 10;  
    uint constant MAX_COOLDOWN_TIME = 255;
    
     
     
     
    uint constant INIT_MAX_SHARES_IN_CIRCULATION = 10000;
    uint constant INIT_MIN_SHARES_IN_CIRCULATION = 100;
    uint constant MAX_SHARES_RELEASE_IN_ONE_CYCLE = 500;
    
     
    uint constant SALES_CUT = 10;
    
     
    uint constant ORDER_CUT = 2;
    
     
    enum OrderType {Buy, Sell}
    
     
    event Listed(uint companyId, string companyName, uint sharesInCirculation, uint pricePerShare,
    uint percentageSharesToRelease, uint nextSharesReleaseTime, address owner);
    
     
    event Claimed(uint companyId, uint numberOfShares, address owner);
    
     
    event Transfer(uint companyId, address from, address to, uint numberOfShares);
    
     
    event CEOChanged(uint companyId, address previousCEO, address newCEO);
    
     
    event SharesReleased(uint companyId, address ceo, uint numberOfShares, uint nextSharesReleaseTime);
    
     
    event OrderPlaced(uint companyId, uint orderIndex, uint amount, uint pricePerShare, OrderType orderType, address owner);
    
     
    event OrderFilled(uint companyId, uint orderIndex, uint amount, address buyer);
    
     
    event OrderCancelled(uint companyId, uint orderIndex);
    
    event TradingWinnerAnnounced(uint companyId, address winner, uint sharesAwarded);
}

contract CompanyBase is BookKeeping, CompanyConstants {

    struct Company {
         
        bytes32 companyNameHash;

         
         
        uint32 percentageSharesToRelease;

         
         
         
        uint32 coolDownTime;
        
         
        uint32 sharesInCirculation; 

         
        uint32 unclaimedShares; 
        
         
        address ceoOfCompany; 

         
        address ownedBy; 
        
         
         
        uint nextSharesReleaseTime; 

         
        uint pricePerShare; 

         
        ShareHolders shareHolders;
    }

    Company[] companies;
    
    function getCompanyDetails(uint _companyId) 
    view
    external 
    returns (
        bytes32 companyNameHash,
        uint percentageSharesToRelease,
        uint coolDownTime,
        uint nextSharesReleaseTime,
        uint sharesInCirculation,
        uint unclaimedShares,
        uint pricePerShare,
        uint sharesRequiredToBeCEO,
        address ceoOfCompany,     
        address owner,
        uint numberOfShareHolders) {

        Company storage company = companies[_companyId];

        companyNameHash = company.companyNameHash;
        percentageSharesToRelease = company.percentageSharesToRelease;
        coolDownTime = company.coolDownTime;
        nextSharesReleaseTime = company.nextSharesReleaseTime;
        sharesInCirculation = company.sharesInCirculation;
        unclaimedShares = company.unclaimedShares;
        pricePerShare = company.pricePerShare; 
        sharesRequiredToBeCEO = (sharesInCirculation/2) + 1;
        ceoOfCompany = company.ceoOfCompany;
        owner = company.ownedBy;
        numberOfShareHolders = company.shareHolders.numberOfShareHolders;
    }

    function getNumberOfShareHolders(uint _companyId) 
    view
    external
    returns (uint) {
        return companies[_companyId].shareHolders.numberOfShareHolders;
    }

    function getNumberOfSharesForAddress(uint _companyId, address _user) 
    view
    external 
    returns(uint) {
        return companies[_companyId].shareHolders.ownerAddressToShares[_user];
    }
    
    function getTotalNumberOfRegisteredCompanies()
    view
    external
    returns (uint) {
        return companies.length;
    }
}

contract TradingVolume is CompanyConstants {
    
    struct Traders {
        uint relaseTime;
        address winningTrader;
        mapping (address => uint) sharesTraded;
    }
    
    mapping (uint => Traders) companyIdToTraders;
    
     
    function _addNewCompanyTraders(uint _companyId) 
    internal {
        Traders memory traders = Traders({
            winningTrader : 0x0,
            relaseTime : now + TRADING_COMPETITION_PERIOD 
        });
        
        companyIdToTraders[_companyId] = traders;
    }
    
     
    function _updateTradingVolume(Traders storage _traders, address _from, address _to, uint _amount) 
    internal {
        _traders.sharesTraded[_from] += _amount;
        _traders.sharesTraded[_to] += _amount;
        
        if (_traders.sharesTraded[_from] > _traders.sharesTraded[_traders.winningTrader]) {
            _traders.winningTrader = _from;
        } 
        
        if (_traders.sharesTraded[_to] > _traders.sharesTraded[_traders.winningTrader]) {
            _traders.winningTrader = _to;
        } 
    }
    
     
    function _clearWinner(Traders storage _traders) 
    internal {
        delete _traders.sharesTraded[_traders.winningTrader];
        delete _traders.winningTrader;
        _traders.relaseTime = now + TRADING_COMPETITION_PERIOD;
    }
}

contract ApprovalContract is CompanyAccessControl {
     
     
    mapping(bytes32 => address) public approvedToLaunch;
    
     
    mapping(bytes32 => bool) public registredCompanyNames;
    
     
     
     
     
    function addApprover(address _owner, string _companyName) 
    onlyCLevel
    whenNotPaused
    external {
        approvedToLaunch[keccak256(_companyName)] = _owner;
    }
}

contract CompanyMain is CompanyBase, ApprovalContract, TradingVolume {
    uint public withdrawableBalance;
    
     
     
    function _computeSalesCut(uint _price) 
    pure
    internal 
    returns (uint) {
        return (_price * SALES_CUT)/100;
    }
    
     
    function _updateCEOIfRequired(Company storage _company, uint _companyId, address _to) 
    internal {
        uint sharesRequiredToBecomeCEO = (_company.sharesInCirculation/2 ) + 1;
        address currentCEO = _company.ceoOfCompany;
        
        if (_company.shareHolders.ownerAddressToShares[currentCEO] >= sharesRequiredToBecomeCEO) {
            return;
        } 
        
        if (_to != address(this) && _company.shareHolders.ownerAddressToShares[_to] >= sharesRequiredToBecomeCEO) {
            _company.ceoOfCompany = _to;
            emit CEOChanged(_companyId, currentCEO, _to);
            return;
        }
        
        if (currentCEO == 0x0) {
            return;
        }
        _company.ceoOfCompany = 0x0;
        emit CEOChanged(_companyId, currentCEO, 0x0);
    }
    

     
     
     
    function _transfer(uint _companyId, address _from, address _to, uint _numberOfTokens) 
    internal {
        Company storage company = companies[_companyId];
        
        _sharesSold(company.shareHolders, _from, _numberOfTokens);
        _sharesBought(company.shareHolders, _to, _numberOfTokens);

        _updateCEOIfRequired(company, _companyId, _to);
        
        emit Transfer(_companyId, _from, _to, _numberOfTokens);
    }
    
    function transferPromotionalShares(uint _companyId, address _to, uint _amount)
    onlyCLevel
    whenNotPaused
    external
    {
        Company storage company = companies[_companyId];
         
        require(company.pricePerShare == 0);
        require(companies[_companyId].shareHolders.ownerAddressToShares[msg.sender] >= _amount);
        _transfer(_companyId, msg.sender, _to, _amount);
    }
    
    function addPromotionalCompany(string _companyName, uint _precentageSharesToRelease, uint _coolDownTime, uint _sharesInCirculation)
    onlyCLevel
    whenNotPaused 
    external
    {
        bytes32 companyNameHash = keccak256(_companyName);
        
         
        require(registredCompanyNames[companyNameHash] == false);
        
         
         
         
        require(_precentageSharesToRelease <= MAX_PERCENTAGE_SHARE_RELEASE);
        
         
        require(_coolDownTime >= MIN_COOLDOWN_TIME && _coolDownTime <= MAX_COOLDOWN_TIME);

        uint _companyId = companies.length;
        uint _nextSharesReleaseTime = now + _coolDownTime * 1 days;
        
        Company memory company = Company({
            companyNameHash: companyNameHash,
            
            percentageSharesToRelease : uint32(_precentageSharesToRelease),
            coolDownTime : uint32(_coolDownTime),
            
            sharesInCirculation : uint32(_sharesInCirculation),
            nextSharesReleaseTime : _nextSharesReleaseTime,
            unclaimedShares : 0,
            
            pricePerShare : 0,
            
            ceoOfCompany : 0x0,
            ownedBy : msg.sender,
            shareHolders : ShareHolders({numberOfShareHolders : 0})
            });

        companies.push(company);
        _addNewCompanyTraders(_companyId);
         
        registredCompanyNames[companyNameHash] = true;
        _sharesBought(companies[_companyId].shareHolders, msg.sender, _sharesInCirculation);
        emit Listed(_companyId, _companyName, _sharesInCirculation, 0, _precentageSharesToRelease, _nextSharesReleaseTime, msg.sender);
    }

     
    function addNewCompany(string _companyName, uint _precentageSharesToRelease, uint _coolDownTime, uint _sharesInCirculation, uint _pricePerShare) 
    external 
    whenNotPaused 
    {
        bytes32 companyNameHash = keccak256(_companyName);
        
         
        require(registredCompanyNames[companyNameHash] == false);
        
         
        require(approvedToLaunch[companyNameHash] == msg.sender);
        
         
         
         
        require(_precentageSharesToRelease <= MAX_PERCENTAGE_SHARE_RELEASE);
        
         
        require(_coolDownTime >= MIN_COOLDOWN_TIME && _coolDownTime <= MAX_COOLDOWN_TIME);
        
        require(_sharesInCirculation >= INIT_MIN_SHARES_IN_CIRCULATION &&
        _sharesInCirculation <= INIT_MAX_SHARES_IN_CIRCULATION);

        uint _companyId = companies.length;
        uint _nextSharesReleaseTime = now + _coolDownTime * 1 days;

        Company memory company = Company({
            companyNameHash: companyNameHash,
            
            percentageSharesToRelease : uint32(_precentageSharesToRelease),
            nextSharesReleaseTime : _nextSharesReleaseTime,
            coolDownTime : uint32(_coolDownTime),
            
            sharesInCirculation : uint32(_sharesInCirculation),
            unclaimedShares : uint32(_sharesInCirculation),
            
            pricePerShare : _pricePerShare,
            
            ceoOfCompany : 0x0,
            ownedBy : msg.sender,
            shareHolders : ShareHolders({numberOfShareHolders : 0})
            });

        companies.push(company);
        _addNewCompanyTraders(_companyId);
         
        registredCompanyNames[companyNameHash] = true;
        emit Listed(_companyId, _companyName, _sharesInCirculation, _pricePerShare, _precentageSharesToRelease, _nextSharesReleaseTime, msg.sender);
    }
    
     
     
     
    function claimShares(uint _companyId, uint _numberOfShares) 
    whenNotPaused
    external 
    payable {
        Company storage company = companies[_companyId];
        
        require (_numberOfShares > 0 &&
            _numberOfShares <= (company.sharesInCirculation * MAX_CLAIM_SHARES_PERCENTAGE)/100);

        require(company.unclaimedShares >= _numberOfShares);
        
        uint totalPrice = company.pricePerShare * _numberOfShares;
        require(msg.value >= totalPrice);

        company.unclaimedShares -= uint32(_numberOfShares);

        _sharesBought(company.shareHolders, msg.sender, _numberOfShares);
        _updateCEOIfRequired(company, _companyId, msg.sender);

        if (totalPrice > 0) {
            uint salesCut = _computeSalesCut(totalPrice);
            withdrawableBalance += salesCut;
            uint sellerProceeds = totalPrice - salesCut;

            company.ownedBy.transfer(sellerProceeds);
        } 

        emit Claimed(_companyId, _numberOfShares, msg.sender);
    }
    
     
     
    function releaseNextShares(uint _companyId) 
    external 
    whenNotPaused {

        Company storage company = companies[_companyId];
        
        require(company.ceoOfCompany == msg.sender);
        
         
        require(company.unclaimedShares == 0 );
        
        require(now >= company.nextSharesReleaseTime);

        company.nextSharesReleaseTime = now + company.coolDownTime * 1 days;
        
         
         
         
         
        uint sharesToRelease = (company.sharesInCirculation * company.percentageSharesToRelease)/100;
        
         
        if (sharesToRelease > MAX_SHARES_RELEASE_IN_ONE_CYCLE) {
            sharesToRelease = MAX_SHARES_RELEASE_IN_ONE_CYCLE;
        }
        
        if (sharesToRelease > 0) {
            company.sharesInCirculation += uint32(sharesToRelease);
            _sharesBought(company.shareHolders, company.ceoOfCompany, sharesToRelease);
            emit SharesReleased(_companyId, company.ceoOfCompany, sharesToRelease, company.nextSharesReleaseTime);
        }
    }
    
    function _updateTradingVolume(uint _companyId, address _from, address _to, uint _amount) 
    internal {
        Traders storage traders = companyIdToTraders[_companyId];
        _updateTradingVolume(traders, _from, _to, _amount);
        
        if (now < traders.relaseTime) {
            return;
        }
        
        Company storage company = companies[_companyId];
        uint _newShares = company.sharesInCirculation/100;
        if (_newShares > MAX_SHARES_RELEASE_IN_ONE_CYCLE) {
            _newShares = 100;
        }
        company.sharesInCirculation += uint32(_newShares);
         _sharesBought(company.shareHolders, traders.winningTrader, _newShares);
        _updateCEOIfRequired(company, _companyId, traders.winningTrader);
        emit TradingWinnerAnnounced(_companyId, traders.winningTrader, _newShares);
        _clearWinner(traders);
    }
}

contract MarketBase is CompanyMain {
    
    function MarketBase() public {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
    }
    
    struct Order {
         
        address owner;
                
         
        uint32 amount;
        
         
        uint32 amountFilled;
        
         
        OrderType orderType;
        
         
        uint pricePerShare;
    }
    
     
    mapping (uint => Order[]) companyIdToOrders;
    
     
    function _createOrder(uint _companyId, uint _amount, uint _pricePerShare, OrderType _orderType) 
    internal {
        Order memory order = Order({
            owner : msg.sender,
            pricePerShare : _pricePerShare,
            amount : uint32(_amount),
            amountFilled : 0,
            orderType : _orderType
        });
        
        uint index = companyIdToOrders[_companyId].push(order) - 1;
        emit OrderPlaced(_companyId, index, order.amount, order.pricePerShare, order.orderType, msg.sender);
    }
    
     
    function placeSellRequest(uint _companyId, uint _amount, uint _pricePerShare) 
    whenNotPaused
    external {
        require (_amount > 0);
        require (_pricePerShare > 0);

         
        _verifyOwnershipOfTokens(_companyId, msg.sender, _amount);

        _transfer(_companyId, msg.sender, this, _amount);
        _createOrder(_companyId, _amount, _pricePerShare, OrderType.Sell);
    }
    
     
    function placeBuyRequest(uint _companyId, uint _amount, uint _pricePerShare) 
    external 
    payable 
    whenNotPaused {
        require(_amount > 0);
        require(_pricePerShare > 0);
        require(_amount == uint(uint32(_amount)));
        
         
        require(msg.value >= _amount * _pricePerShare);

        _createOrder(_companyId, _amount, _pricePerShare, OrderType.Buy);
    }
    
     
    function cancelRequest(uint _companyId, uint _orderIndex) 
    external {        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        
        require(order.owner == msg.sender);
        
        uint sharesRemaining = _getRemainingSharesInOrder(order);
        
        require(sharesRemaining > 0);

        order.amountFilled += uint32(sharesRemaining);
        
        if (order.orderType == OrderType.Buy) {

              
            uint price = _getTotalPrice(order, sharesRemaining);
            
             
            msg.sender.transfer(price);
        } else {
            
             
            _transfer(_companyId, this, msg.sender, sharesRemaining);
        }

        emit OrderCancelled(_companyId, _orderIndex);
    }
    
     
    function fillSellOrder(uint _companyId, uint _orderIndex, uint _amount) 
    whenNotPaused
    external 
    payable {
        require(_amount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Sell);
        
        require(msg.sender != order.owner);
       
        _verifyRemainingSharesInOrder(order, _amount);

        uint price = _getTotalPrice(order, _amount);
        require(msg.value >= price);

        order.amountFilled += uint32(_amount);
        
         
        _transfer(_companyId, this, msg.sender, _amount);
        
         
        _transferOrderMoney(price, order.owner);  
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, _amount);
        
        emit OrderFilled(_companyId, _orderIndex, _amount, msg.sender);
    }
    
     
    function fillSellOrderPartially(uint _companyId, uint _orderIndex, uint _maxAmount) 
    whenNotPaused
    external 
    payable {
        require(_maxAmount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Sell);
        
        require(msg.sender != order.owner);
       
        uint buyableShares = _getRemainingSharesInOrder(order);
        require(buyableShares > 0);
        
        if (buyableShares > _maxAmount) {
            buyableShares = _maxAmount;
        }

        uint price = _getTotalPrice(order, buyableShares);
        require(msg.value >= price);

        order.amountFilled += uint32(buyableShares);
        
         
        _transfer(_companyId, this, msg.sender, buyableShares);
        
         
        _transferOrderMoney(price, order.owner); 
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, buyableShares);
        
        uint buyerProceeds = msg.value - price;
        msg.sender.transfer(buyerProceeds);
        
        emit OrderFilled(_companyId, _orderIndex, buyableShares, msg.sender);
    }

     
    function fillBuyOrder(uint _companyId, uint _orderIndex, uint _amount) 
    whenNotPaused
    external {
        require(_amount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Buy);
        
        require(msg.sender != order.owner);
        
         
        _verifyRemainingSharesInOrder(order, _amount);
        
         
        _verifyOwnershipOfTokens(_companyId, msg.sender, _amount);
        
        order.amountFilled += uint32(_amount);
        
         
        _transfer(_companyId, msg.sender, order.owner, _amount);
        
        uint price = _getTotalPrice(order, _amount);
        
         
        _transferOrderMoney(price , msg.sender);
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, _amount);

        emit OrderFilled(_companyId, _orderIndex, _amount, msg.sender);
    }
    
     
    function fillBuyOrderPartially(uint _companyId, uint _orderIndex, uint _maxAmount) 
    whenNotPaused
    external {
        require(_maxAmount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Buy);
        
        require(msg.sender != order.owner);
        
         
        uint buyableShares = _getRemainingSharesInOrder(order);
        require(buyableShares > 0);
        
        if ( buyableShares > _maxAmount) {
            buyableShares = _maxAmount;
        }
        
         
        _verifyOwnershipOfTokens(_companyId, msg.sender, buyableShares);
        
        order.amountFilled += uint32(buyableShares);
        
         
        _transfer(_companyId, msg.sender, order.owner, buyableShares);
        
        uint price = _getTotalPrice(order, buyableShares);
        
         
        _transferOrderMoney(price , msg.sender);
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, buyableShares);

        emit OrderFilled(_companyId, _orderIndex, buyableShares, msg.sender);
    }

     
    function _transferOrderMoney(uint _price, address _owner) 
    internal {
        uint priceCut = (_price * ORDER_CUT)/100;
        _owner.transfer(_price - priceCut);
        withdrawableBalance += priceCut;
    }

     
     
     
    function _getTotalPrice(Order storage _order, uint _amount) 
    view
    internal 
    returns (uint) {
        return _amount * _order.pricePerShare;
    }
    
     
    function _getRemainingSharesInOrder(Order storage _order) 
    view
    internal 
    returns (uint) {
        return _order.amount - _order.amountFilled;
    }

     
     
    function _verifyRemainingSharesInOrder(Order storage _order, uint _amount) 
    view
    internal {
        require(_getRemainingSharesInOrder(_order) >= _amount);
    }

     
     
    function _verifyOwnershipOfTokens(uint _companyId, address _owner, uint _amount) 
    view
    internal {
        require(companies[_companyId].shareHolders.ownerAddressToShares[_owner] >= _amount);
    }
    
     
    function getNumberOfOrders(uint _companyId) 
    view
    external 
    returns (uint numberOfOrders) {
        numberOfOrders = companyIdToOrders[_companyId].length;
    }

    function getOrderDetails(uint _comanyId, uint _orderIndex) 
    view
    external 
    returns (address _owner,
        uint _pricePerShare,
        uint _amount,
        uint _amountFilled,
        OrderType _orderType) {
            Order storage order =  companyIdToOrders[_comanyId][_orderIndex];
            
            _owner = order.owner;
            _pricePerShare = order.pricePerShare;
            _amount = order.amount;
            _amountFilled = order.amountFilled;
            _orderType = order.orderType;
    }
    
    function withdrawBalance(address _address) 
    onlyCLevel
    external {
        require(_address != 0x0);
        uint balance = withdrawableBalance;
        withdrawableBalance = 0;
        _address.transfer(balance);
    }
    
     
    function kill(address _address) 
    onlyCLevel
    whenPaused
    external {
        require(_address != 0x0);
        selfdestruct(_address);
    }
}