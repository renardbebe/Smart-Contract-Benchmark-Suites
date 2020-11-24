 

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
    uint public constant NO_TAKE_HOUR = 1600;   
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
        emit subkTracker(_lp, msg.sender, newsubkID, true);
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
