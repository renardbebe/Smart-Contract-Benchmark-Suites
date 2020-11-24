 

 

pragma solidity ^0.5.11;

contract Oracle {

     
    constructor (uint ethPrice) public {
        admins[msg.sender] = true;
        addAsset("ETHUSD", ethPrice);
    }
    Asset[] public assets;
    uint[8][] private prices;
    mapping(address => bool) public admins;
    mapping(address => bool) public readers;
     
     
    uint public constant UPDATE_TIME_MIN = 0 hours;
     
    uint public constant SETTLE_TIME_MIN1 = 0 days;     
     
    uint public constant SETTLE_TIME_MIN2 = 46 hours;    
     
    uint public constant EDIT_TIME_MAX = 30 minutes;   

    struct Asset {
        bytes32 name;
        uint8 currentDay;
        uint lastUpdateTime;
        uint lastSettleTime;
        bool isFinalDay;
    }

    event PriceUpdated(
        uint indexed id,
        bytes32 indexed name,
        uint price,
        uint timestamp,
        uint8 dayNumber,
        bool isCorrection
    );

        modifier onlyAdmin()
    {
        require(admins[msg.sender]);
        _;
    }

     
    function addAdmin(address newAdmin)
        public
        onlyAdmin
    {
        admins[newAdmin] = true;
    }

     
    function addAsset(bytes32 _name, uint _startPrice)
        public
        returns (uint _assetID)
    {
        require (admins[msg.sender] || msg.sender == address(this));
         
        Asset memory asset;
        asset.name = _name;
        asset.currentDay = 0;
        asset.lastUpdateTime = now;
        asset.lastSettleTime = now - 5 days;
        assets.push(asset);
        uint[8] memory _prices;
        _prices[0] = _startPrice;
        prices.push(_prices);
        return assets.length - 1;
    }
     

    function editPrice(uint _assetID, uint _newPrice)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
        require(now < asset.lastUpdateTime + EDIT_TIME_MAX);
        prices[_assetID][asset.currentDay] = _newPrice;
        emit PriceUpdated(_assetID, asset.name, _newPrice, now, asset.currentDay, true);
    }

     
    function addReader(address newReader)
        public
        onlyAdmin
    {
        readers[newReader] = true;
    }

     
    function getPrices(uint _assetID)
        public
        view
        returns (uint[8] memory _priceHist)
    {
        require (admins[msg.sender] || readers[msg.sender]);
        _priceHist = prices[_assetID];
    }

     
    function getStalePrices(uint _assetID)
        public
        view
        returns (uint[8] memory _priceHist)
    {
        _priceHist = prices[_assetID];
        _priceHist[assets[_assetID].currentDay]=0;
    }

     
    function getCurrentPrice(uint _assetID)
        public
        view
        returns (uint _price)
    {
        require (admins[msg.sender] || readers[msg.sender]);
        _price =  prices[_assetID][assets[_assetID].currentDay];
    }

     
    function getLastUpdateTime(uint _assetID)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[_assetID].lastUpdateTime;
    }

     
    function getLastSettleTime(uint _assetID)
        public
        view
        returns (uint timestamp)
    {
        timestamp = assets[_assetID].lastSettleTime;
    }

     
    function getStartDay(uint _assetID)
        public
        view
        returns (uint8 _startDay)
    {
        if (assets[_assetID].isFinalDay) _startDay = 7;
        else if (assets[_assetID].currentDay == 7) _startDay = 1;
        else _startDay = assets[_assetID].currentDay + 1;
    }

      
    function isFinalDay(uint _assetID)
        public
        view
        returns (bool)
    {
        return assets[_assetID].isFinalDay;
    }

     
    function isSettleDay(uint _assetID)
        public
        view
        returns (bool)
    {
        return (assets[_assetID].currentDay == 7);
    }

     
    function removeAdmin(address toRemove)
        public
        onlyAdmin
    {
        require(toRemove != msg.sender);
        admins[toRemove] = false;
    }

      
    function setIntraWeekPrice(uint _assetID, uint _price, bool finalDayStatus)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
         
        require(now > asset.lastUpdateTime + UPDATE_TIME_MIN);
         
        require(!asset.isFinalDay);
        if (asset.currentDay == 7) {
            require(now > asset.lastSettleTime + SETTLE_TIME_MIN2,
                "Sufficient time must pass after settlement update.");
             asset.currentDay = 1;
             uint[8] memory newPrices;
              
             newPrices[0] = prices[_assetID][7];
             newPrices[1] = _price;
             prices[_assetID] = newPrices;
        } else {
            asset.currentDay = asset.currentDay + 1;
            prices[_assetID][asset.currentDay] = _price;
            asset.isFinalDay = finalDayStatus;
        }
        asset.lastUpdateTime = now;
        emit PriceUpdated(_assetID, asset.name, _price, now, asset.currentDay, false);
    }

     
    function setSettlePrice(uint _assetID, uint _price)
        public
        onlyAdmin
    {
        Asset storage asset = assets[_assetID];
         
        require(now > asset.lastUpdateTime + UPDATE_TIME_MIN);
         
        require(asset.isFinalDay);
         
        require(now > asset.lastSettleTime + SETTLE_TIME_MIN1,
            "Sufficient time must pass between weekly price updates.");
             
             asset.currentDay = 7;
             prices[_assetID][7] = _price;
             asset.lastSettleTime = now;
             asset.isFinalDay = false;
        asset.lastUpdateTime = now;
        emit PriceUpdated(_assetID, asset.name, _price, now, 7, false);

    }

}

 


pragma solidity ^0.5.11;

contract Book {

     
     constructor(address user, address  admin, uint minBalance)
        public
    {
        assetSwap = AssetSwap(admin);
        lp = user;
        minRM = minBalance * 1 finney;
        lastBookSettleTime = now - 7 days;
    }

    address public lp;
    AssetSwap public assetSwap;
    bool public bookDefaulted;
    uint public settleNum;
    uint public LPMargin;
    uint public LPLongMargin;     
    uint public LPShortMargin;    
    uint public LPRequiredMargin;    
    uint public lastBookSettleTime;
    uint public minRM;
    uint public debitAcct;
    uint internal constant BURN_DEF_FEE = 2;  
     
     
     
    uint internal constant ORACLE_MAX_ABSENCE = 1 days;
     
     
    uint internal constant NO_DOUBLE_SETTLES = 1 days;
     
    uint internal constant MAX_SUBCONTRACTS = 225;
    uint internal constant CLOSE_FEE = 200;
    uint internal constant LP_MAX_SETTLE = 0 days;
    bytes32[] public shortTakerContracts;  
    bytes32[] public longTakerContracts;   
    mapping(bytes32 => Subcontract) public subcontracts;
    address payable internal constant BURN_ADDRESS = address(0xdead);   

    struct Subcontract {
        uint index;
		address taker;
		uint takerMargin;    
		uint reqMargin;      
        uint8 startDay;      
        bool takerCloseDisc;
		bool LPSide;         
		bool isCancelled;
		bool takerBurned;
		bool LPBurned;
		bool takerDefaulted;
        bool isActive;
	}


    modifier onlyAdmin()
    {
        require(msg.sender == address(assetSwap));
        _;
    }

     
    function adjustMinRM(uint _min)
        public
        onlyAdmin
    {
        minRM = _min * 1 finney;
    }

     
    function adminCancel(bytes32 subkID)
        public
        payable
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        k.isCancelled = true;
    }

     
    function adminStop()
        public
        payable
        onlyAdmin
    {
        bookDefaulted = true;
        LPRequiredMargin = 0;
    }

     
    function balanceSend(uint amount, address recipient)
        internal
    {
        assetSwap.balanceTransfer.value(amount)(recipient);
    }

     
    function bookBurn( bytes32 subkID, address sender, uint amount)
        public
        payable
        onlyAdmin
        returns (uint)
    {
        Subcontract storage k = subcontracts[subkID];
        require(sender == lp || sender == k.taker, "must by party to his subcontract");
         
		uint burnFee = k.reqMargin / BURN_DEF_FEE;
		require (amount >= burnFee);
		if (sender == lp)
		    k.LPBurned = true;
		else
		    k.takerBurned = true;
		return burnFee;
    }

      
    function bookCancel(uint lastOracleSettleTime, bytes32 subkID, address sender)
        public
        payable
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
		require(sender == k.taker || sender == lp, "Canceller not LP or taker");
        require(!k.isCancelled, "Subcontract already cancelled");
        uint fee;
        fee =(k.reqMargin * CLOSE_FEE)/1e4 ;
        if (k.takerCloseDisc || (sender == lp))
           fee = 3 * fee / 2;
		require(msg.value >= fee, "Insufficient cancel fee");
        k.isCancelled = true;
        balanceSend(msg.value - fee, sender);
        balanceSend(fee, assetSwap.feeAddress());
    }

     
    function fundLPMargin()
        public
        payable
    {
        LPMargin = add(LPMargin,msg.value);
    }

     
    function fundTakerMargin(bytes32 subkID)
        public
        payable
    {
        Subcontract storage k = subcontracts[subkID];
        require (k.reqMargin > 0);
        k.takerMargin= add(k.takerMargin,msg.value);
    }

     
        function getSubkData(bytes32 subkID)
        public
        view
        returns (uint _takerMargin, uint _reqMargin,
          bool _lpside, bool isCancelled, bool isActive, uint8 _startDay)
    {
        Subcontract storage k = subcontracts[subkID];
        _takerMargin = k.takerMargin;
        _reqMargin = k.reqMargin;
        _lpside = k.LPSide;
        isCancelled = k.isCancelled;
        isActive = k.isActive;
        _startDay = k.startDay;
    }


     

      function getSubkDetail(bytes32 subkID)
        public
        view
        returns (bool closeDisc, bool takerBurned, bool LPBurned, bool takerDefaulted)
    {
        Subcontract storage k = subcontracts[subkID];
        closeDisc = k.takerCloseDisc;
        takerBurned = k.takerBurned;
        LPBurned = k.LPBurned;
        takerDefaulted = k.takerDefaulted;
    }


     

     function inactiveOracle()
        public
        {
          require(now > (lastBookSettleTime + ORACLE_MAX_ABSENCE));

          bookDefaulted = true;
          LPRequiredMargin = 0;
        }

     

    function inactiveLP(uint _lastOracleSettleTime, bytes32 subkID)
        public
    {
          require(_lastOracleSettleTime > lastBookSettleTime);
          require( now > (_lastOracleSettleTime + LP_MAX_SETTLE));
          require(!bookDefaulted);
          Subcontract storage k = subcontracts[subkID];
          uint LPfee = min(LPMargin,k.reqMargin);
          uint defPay = subzero(LPRequiredMargin/2,LPfee);
          LPMargin = subzero(LPMargin,add(LPfee,defPay));
          k.takerMargin = add(k.takerMargin,LPfee);
          bookDefaulted = true;
          LPRequiredMargin = 0;
    }
     
    function redeemSubcontract(bytes32 subkID)
        public
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        require(!k.isActive || bookDefaulted);
        uint tMargin = k.takerMargin;
        if (k.takerDefaulted) {
            uint defPay = k.reqMargin / BURN_DEF_FEE;
            tMargin = subzero(tMargin,defPay);
        BURN_ADDRESS.transfer(defPay);
        }
        k.takerMargin = 0;
        balanceSend(tMargin, k.taker);
        uint index = k.index;
        if (k.LPSide) {
            Subcontract storage lastShort = subcontracts[shortTakerContracts[shortTakerContracts.length - 1]];
            lastShort.index = index;
            shortTakerContracts[index] = shortTakerContracts[shortTakerContracts.length - 1];
            shortTakerContracts.pop();
        } else {
            Subcontract storage lastLong = subcontracts[longTakerContracts[longTakerContracts.length - 1]];
            lastLong.index = index;
            longTakerContracts[index] = longTakerContracts[longTakerContracts.length - 1];
            longTakerContracts.pop();
        }
        Subcontract memory blank;
        subcontracts[subkID] = blank;
    }

     
  function settleLong(int[8] memory takerLongRets, uint topLoop)
        public
        onlyAdmin
    {
         
       require(settleNum < longTakerContracts.length);
        
       require(now > lastBookSettleTime + NO_DOUBLE_SETTLES);
       topLoop = min(longTakerContracts.length, topLoop);
        LPRequiredMargin = add(LPLongMargin,LPShortMargin);
         for (settleNum; settleNum < topLoop; settleNum++) {
             settleSubcontract(longTakerContracts[settleNum], takerLongRets);
        }
    }

     
 function settleShort(int[8] memory takerShortRets, uint topLoop)
        public
        onlyAdmin
    {
        require(settleNum >= longTakerContracts.length);
        topLoop = min(shortTakerContracts.length, topLoop);
        for (uint i = settleNum - longTakerContracts.length; i < topLoop; i++) {
             settleSubcontract(shortTakerContracts[i], takerShortRets);
        }
        settleNum = topLoop + longTakerContracts.length;
        
        if (settleNum == longTakerContracts.length + shortTakerContracts.length) {
            LPMargin = subzero(LPMargin,debitAcct);
            if (LPShortMargin > LPLongMargin) LPRequiredMargin = subzero(LPShortMargin,LPLongMargin);
                else LPRequiredMargin = subzero(LPLongMargin,LPShortMargin);
            debitAcct = 0;
            lastBookSettleTime = now;
            settleNum = 0;
            if (LPMargin < LPRequiredMargin) {
                bookDefaulted = true;
                uint defPay = min(LPMargin, LPRequiredMargin/BURN_DEF_FEE);
                LPMargin = subzero(LPMargin,defPay);
            }
        }
    }

     function MarginCheck()
        public
        view
        returns (uint playerMargin, uint bookETH)
    {
        playerMargin = 0;

            for (uint i = 0; i < longTakerContracts.length; i++) {
             Subcontract storage k = subcontracts[longTakerContracts[i]];
             playerMargin = playerMargin + k.takerMargin ;
            }
             for (uint i = 0; i < shortTakerContracts.length; i++) {
             Subcontract storage k = subcontracts[shortTakerContracts[i]];
             playerMargin = playerMargin + k.takerMargin ;
            }

            playerMargin  = playerMargin + LPMargin;
            bookETH = address(this).balance;


    }

       


    function settleSubcontract(bytes32 subkID, int[8] memory subkRets)
     internal
    {
        Subcontract storage k = subcontracts[subkID];
         
        if (k.isActive && (k.startDay != 7)) {

            uint absolutePNL;

            bool lpprof;
            if (subkRets[k.startDay] < 0) {
                lpprof = true;
                absolutePNL = uint(-1 * subkRets[k.startDay]) * k.reqMargin / 1 finney;
            }
            else {
                absolutePNL = uint(subkRets[k.startDay]) * k.reqMargin / 1 finney;
            }
            absolutePNL = min(k.reqMargin,absolutePNL);
            if (lpprof) {
                k.takerMargin = subzero(k.takerMargin,absolutePNL);
                if (!k.takerBurned) LPMargin = add(LPMargin,absolutePNL);
            } else {
                if (absolutePNL>LPMargin) debitAcct = add(debitAcct,subzero(absolutePNL,LPMargin));
                LPMargin = subzero(LPMargin,absolutePNL);
                if (!k.LPBurned) k.takerMargin = add(k.takerMargin,absolutePNL);
            }
            if (k.LPBurned || k.takerBurned || k.isCancelled) {
                if (k.LPSide) LPLongMargin = subzero(LPLongMargin,k.reqMargin);
                else LPShortMargin = subzero(LPShortMargin,k.reqMargin);
                k.isActive = false;
            } else if (k.takerMargin < k.reqMargin)
            {
                if (k.LPSide) LPLongMargin = subzero(LPLongMargin,k.reqMargin);
                else LPShortMargin = subzero(LPShortMargin,k.reqMargin);
                k.isActive = false;
                k.takerDefaulted = true;
            }
        }
        k.startDay = 0;
    }


       
	 function take(address taker, uint amount, uint sizeDiscCut, uint8 startDay, uint lastOracleSettleTime, bool takerLong)
        public
        payable
        onlyAdmin
        returns (bytes32 subkID)
    {
        require(amount * 1 finney >= minRM, "must be greater than book min");
        require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        Subcontract memory order;
        order.reqMargin = amount * 1 finney;
        order.takerMargin = msg.value;
        order.taker = taker;
        order.isActive = true;
        order.startDay = startDay;
        if (!takerLong) order.LPSide = true;
        if (takerLong) {
            require(longTakerContracts.length < MAX_SUBCONTRACTS, "bookMaxedOut");
            subkID = keccak256(abi.encodePacked(lp, now, longTakerContracts.length));   
            order.index = longTakerContracts.length;
            longTakerContracts.push(subkID);
            LPShortMargin = add(LPShortMargin,order.reqMargin);
            if (subzero(LPShortMargin,LPLongMargin) > LPRequiredMargin)
                LPRequiredMargin = subzero(LPShortMargin,LPLongMargin);
            } else {
            require(shortTakerContracts.length < MAX_SUBCONTRACTS, "bookMaxedOut");
            subkID = keccak256(abi.encodePacked(shortTakerContracts.length,lp, now));   
            order.index = shortTakerContracts.length;
            shortTakerContracts.push(subkID);
            LPLongMargin = add(LPLongMargin,order.reqMargin);
             if (subzero(LPLongMargin,LPShortMargin) > LPRequiredMargin)
            LPRequiredMargin = subzero(LPLongMargin,LPShortMargin);
             }
        if (add(LPLongMargin,LPShortMargin) >= sizeDiscCut) order.takerCloseDisc = true;
        subcontracts[subkID] = order;
        return subkID;
    }


      
    function withdrawalLP(uint amount, uint lastOracleSettleTime)
        public
        onlyAdmin
    {
        if (bookDefaulted) {
            require (LPMargin >= amount, "Cannot withdraw more than the margin");
        } else {
            require (LPMargin >= add(LPRequiredMargin,amount),"Cannot to w/d more than excess margin");
            require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        }
        LPMargin = subzero(LPMargin,amount);
        balanceSend(amount, lp);
    }

     
    function withdrawalTaker(bytes32 subkID, uint amount, uint lastOracleSettleTime, address sender)
        public
        onlyAdmin
    {
        require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        Subcontract storage k = subcontracts[subkID];
        require(k.takerMargin >= add(k.reqMargin,amount),"must have sufficient margin");
        require(sender == k.taker, "Must be taker to call this function");
        k.takerMargin = subzero(k.takerMargin,amount);
        balanceSend(amount, k.taker);
    }


     
    function min(uint a, uint b)
        internal
        pure
        returns (uint)
    {
        if (a <= b)
            return a;
        else
            return b;
    }


    function subzero(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        if (_b >= _a)
            return 0;
        else
            return _a - _b;
    }

    function add(uint _a, uint _b)
        internal
        pure
        returns (uint)
        {
        uint c = _a + _b;
        assert(c >= _a);
        return c;
        }

}

 

pragma solidity ^0.5.11;



contract AssetSwap {

     

    constructor (address priceOracle)
        public
    {
        admins[msg.sender] = true;
        feeAddress = msg.sender;
        oracle = Oracle(priceOracle);
    }

    Oracle public oracle;

    bool public _isDST;   
    bool public _isFreeMargin;  
    int public _LongRate;  
    int public _ShortRate;  
    uint public GLOBAL_SIZE_DISC;  
    uint public GLOBAL_RM_MIN;    
    int public constant TOP_BASIS = 200;  
    uint public constant MIN_SETTLE_TIME = 0 hours;   
    uint public constant NO_TAKE_HOUR = 1;   
    uint public constant TOP_TARGET = 100;   
    uint public constant ASSET_ID = 1;  
    uint public constant _leverageRatio = 1000;  
    uint public _lastWeeklyReturnsTime;
    int[8] private takerLongReturns;
    int[8] private takerShortReturns;
    mapping(address => address) public _books;   
    mapping(address => uint) public _withdrawBalances;   
    mapping(address => bool) public admins;   
    address payable public feeAddress;    
    address payable constant constant BURN_ADDRESS = address(0xdead);   


    event subkTracker(
        address indexed e_lp,
        address indexed e_taker,
        bytes32 e_subkID,
        bool e_open);
    event BurnHist(
        address e_lp,
        bytes32 e_subkID,
        address e_sender,
        uint e_time);
    event RatesUpdated(
        uint e_target,
        int e_basis);
    event LPNewBook(
        address e_lp,
        address e_lpBook);
    event SizeDiscUpdated(
        uint e_minLPGrossForDisc);


    modifier onlyAdmin()
    {
        require(admins[msg.sender], "admin only");
        _;
    }

     
    function addAdmin(address newAdmin)
        public
        onlyAdmin
    {
        admins[newAdmin] = true;
    }

     
     function adjDST(bool _isDaylightSav)
        public
        onlyAdmin
    {
       _isDST = _isDaylightSav;
    }

      
     function adjRMMin(uint _RMMin)
        public
        onlyAdmin
    {
       GLOBAL_RM_MIN = _RMMin;
    }

        
     function adjisFreeMargin(bool _freeMargin)
        public
        onlyAdmin
    {
       _isFreeMargin = _freeMargin;
    }

      
    function adjustMinRM(uint _min)
        public
    {
        require (_books[msg.sender] != address(0), "User must have a book");
        require (_min > GLOBAL_RM_MIN);
        Book b = Book(_books[msg.sender]);
        b.adjustMinRM(_min);
    }

     
    function adminCancel(address _lp, bytes32 subkID)
        public
        onlyAdmin
    {
        Book b = Book(_books[_lp]);
        b.adminCancel(subkID);
    }

        
    function adminKill(address _lp)
        public
        onlyAdmin
    {
        Book b = Book(_books[_lp]);
        b.adminStop();
    }

       
    function balanceTransfer(address recipient)
        public
        payable
    {
        _withdrawBalances[recipient] = add(_withdrawBalances[recipient],msg.value);
    }

     
    function changeFeeAddress(address payable newAddress)
        public
        onlyAdmin
    {
        feeAddress = newAddress;
    }

     
        function createBook(uint _min)
        public
        payable
        returns (address newBook)
    {
        require (_books[msg.sender] == address(0), "User must not have a preexisting book");
        require (msg.value >= _min * 2 finney, "Must prep for 2-sided book");
        _books[msg.sender] = address(new Book(msg.sender, address(this), _min));
        Book b = Book(_books[msg.sender]);
        b.fundLPMargin.value(msg.value)();
        emit LPNewBook(msg.sender, _books[msg.sender]);
        return _books[msg.sender];
    }

         
    function getBookData(address _lp)
        public
        view
        returns (address _book,
            uint _lpMargin,
            uint _totalLpLong,
            uint _totalLpShort,
            uint _lpRM,
            uint _bookMinimum,
            uint _lastBookSettleTime,
            uint _settleNum,
            bool _bookDefaulted
            )
    {
            _book = _books[_lp];
            Book b = Book(_book);
            _lpMargin = b.LPMargin();
            _totalLpLong = b.LPLongMargin();
            _totalLpShort = b.LPShortMargin();
            _lpRM = b.LPRequiredMargin();
            _bookMinimum = b.minRM();
            _lastBookSettleTime = b.lastBookSettleTime();
            _settleNum = b.settleNum();
            _bookDefaulted = b.bookDefaulted();
    }

     


    function getSubcontractData(address _lp, bytes32 subkID)
        public
        view
        returns (
            uint _takerMargin,
            uint _reqMargin,
            bool _lpSide,
            bool _isCancelled,
            bool _isActive,
            uint8 _startDay)
    {
        address book = _books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (_takerMargin, _reqMargin, _lpSide, _isCancelled, _isActive, _startDay) = b.getSubkData(subkID);
        }
    }

       

    function getSubcontractStatus(address _lp, bytes32 subkID)
        public
        view
        returns (
            bool _closeDisc,
            bool _takerBurned,
            bool _lpBurned,
            bool _takerDefaulted)
    {
        address book = _books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (_closeDisc, _takerBurned, _lpBurned, _takerDefaulted) = b.getSubkDetail(subkID);
        }
    }

     function getBookBalance(address _lp)
        public
        view
        returns (
            uint playerMargin,
            uint bookETH
            )
    {
        address book = _books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (playerMargin, bookETH) = b.MarginCheck();
        }
    }



     

      
    function lpFund(address _lp)
        public
        payable
    {
        require(msg.sender == _lp);
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        b.fundLPMargin.value(msg.value)();
    }

     
    function burn(address _lp, bytes32 subkID)
        public
        payable
    {
        Book b = Book(_books[_lp]);
        uint fee = b.bookBurn(subkID, msg.sender, msg.value);
        if (msg.value > fee) {
            BURN_ADDRESS.transfer(fee);
            _withdrawBalances[msg.sender] = add(_withdrawBalances[msg.sender],msg.value - fee);
            emit BurnHist(_lp, subkID, msg.sender, now);
         }
    }

     
    function cancel(address _lp, bytes32 subkID)
        public
        payable
    {
        Book b = Book(_books[_lp]);
        uint lastSettleTime = oracle.getLastSettleTime(ASSET_ID);
        b.bookCancel.value(msg.value)(lastSettleTime, subkID, msg.sender);
    }
     
    function inactiveOracle(address _lp)
        public
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        b.inactiveOracle();
    }
     
     function inactiveLP(address _lp, bytes32 subkID)
        public
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        uint lastSettleTime = oracle.getLastSettleTime(ASSET_ID);
        b.inactiveLP(lastSettleTime, subkID);
    }
     

    function redeem(address _lp, bytes32 subkID)
        public
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        b.redeemSubcontract(subkID);
        emit subkTracker(_lp, msg.sender, subkID, false);
    }

     
    function removeAdmin(address toRemove)
        public
        onlyAdmin
    {
        require(toRemove != msg.sender, "You may not remove yourself as an admin.");
        admins[toRemove] = false;
    }

      function setSizeDiscCut(uint sizeDiscCut)
        public
        onlyAdmin
    {
         
        GLOBAL_SIZE_DISC = sizeDiscCut * 1 finney;
        emit SizeDiscUpdated(sizeDiscCut);
    }

      

    function setRates(uint target, int basis)
        public
        onlyAdmin
    {
         
         
         
        require(target <= TOP_TARGET, "Target must be between 0 and 1%");
        require(-TOP_BASIS <= basis && basis <= TOP_BASIS, "Basis must be between -2 and 2%");
        require(!oracle.isSettleDay(ASSET_ID));
        _LongRate = int(target) + basis;
        _ShortRate = int(target) - basis;
        emit RatesUpdated(target, basis);
    }

     

    function settle(address _lp, bool _settleLong, uint _topLoop)
        public
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
         
         require(oracle.isSettleDay(ASSET_ID));
        uint _lastSettle = oracle.getLastSettleTime(ASSET_ID);
         
        require(_lastWeeklyReturnsTime > _lastSettle);
          
        require (now > _lastSettle + MIN_SETTLE_TIME, "Give players more time");
        if (_settleLong) b.settleLong(takerLongReturns, _topLoop); else b.settleShort(takerShortReturns, _topLoop);
    }

     
    function takerFund(address _lp, bytes32 subkID)
        public
        payable
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        b.fundTakerMargin.value(msg.value)(subkID);
    }

     
    function take(address _lp, uint amount, bool isTakerLong)
        public
        payable
    {
        require(msg.value >= amount * (1 finney), "Insuffient ETH for this RM");  
        require(hourOfDay() != NO_TAKE_HOUR, "Cannot take during 4 PM ET hour");   
        require(amount > GLOBAL_RM_MIN);
        Book book = Book(_books[_lp]);
        uint lpLong = book.LPLongMargin();
        uint lpShort = book.LPShortMargin();
        uint freeMargin = 0;
        uint8 startDay = oracle.getStartDay(ASSET_ID);
        uint lastOracleSettleTime = oracle.getLastSettleTime(ASSET_ID);
        if (_isFreeMargin) {
        if (isTakerLong) freeMargin = subzero(lpLong,lpShort);
        else freeMargin = subzero(lpShort,lpLong);
        }
        require(amount * 1 finney <= subzero(book.LPMargin(),book.LPRequiredMargin())/2 + freeMargin, "RM to large for this LP on this side");
        bytes32 newsubkID = book.take.value(msg.value)(msg.sender, amount, GLOBAL_SIZE_DISC, startDay, lastOracleSettleTime, isTakerLong);
        emit subkTracker(_lp, msg.sender, newsubkID,true);
    }


 
 
 
    function weeklyReturns()
        public
        onlyAdmin
    {
         
       require(oracle.isSettleDay(ASSET_ID));

        uint[8] memory assetPrice  = oracle.getPrices(ASSET_ID);
        uint[8] memory ethPrice = oracle.getPrices(0);

        for (uint i = 0; i < 7; i++)
        {
            if (assetPrice[i] == 0 || ethPrice[i] == 0) continue;
            int assetReturn = int((assetPrice[7] * (1 finney)) / assetPrice[i] ) - 1 finney;
            takerLongReturns[i] = assetReturn - ((1 finney) * int(_LongRate))/1e4;
            takerShortReturns[i] = (-1 * assetReturn) - ((1 finney) * int(_ShortRate))/1e4;
            takerLongReturns[i] = (takerLongReturns[i] * int(_leverageRatio * ethPrice[i]))/int(ethPrice[7] * 100);
            takerShortReturns[i] = (takerShortReturns[i] * int(_leverageRatio * ethPrice[i]))/int(ethPrice[7] * 100);
        }
         _lastWeeklyReturnsTime = now;

    }



     
    function withdrawalLP(uint amount)
        public
    {
        require(_books[msg.sender] != address(0));
        Book b = Book(_books[msg.sender]);
        uint lastOracleSettleTime= oracle.getLastSettleTime(ASSET_ID);
         
        b.withdrawalLP(amount, lastOracleSettleTime);
    }

     
    function withdrawalTaker(uint amount, address _lp, bytes32 subkID)
        public
    {
        require(_books[_lp] != address(0));
        Book b = Book(_books[_lp]);
        uint lastOracleSettleTime = oracle.getLastSettleTime(ASSET_ID);
         
        b.withdrawalTaker(subkID, amount, lastOracleSettleTime, msg.sender);
    }

     
    function withdrawBalance()
        public
    {
        uint amount = _withdrawBalances[msg.sender];
        _withdrawBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

     
    function hourOfDay()
        public
        view
        returns(uint hour1)
    {
        hour1= (now  % 86400) / 3600 - 5;
        if (_isDST) hour1=hour1 + 1;
    }
     

    function subzero(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        if (_b >= _a) {
        return 0;
    }
        return _a - _b;
    }
     

    function add(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        uint c = _a + _b;
        assert(c >= _a);
        return c;
    }

}