 
    function addAdmin(address newAdmin)
        external
        onlyAdmin
    {
        administrators[newAdmin] = true;
    }

    function adjustMinRM(uint16 _min)
        external
    {
        require(books[msg.sender] != address(0), "User must have a book");
        require(_min >= 1);
        Book b = Book(books[msg.sender]);
        b.adjustMinRMBook(_min);
    }

     
    function updateFees(uint newClose, int frLong, int frShort)
        external
    {
        require(books[msg.sender] != address(0), "User must have a book");
         
        int longRate = frLong * leverageRatio / 1e2;
        int shortRate = frShort * leverageRatio / 1e2;
        uint closefee = newClose * uint(leverageRatio) / 1e2;
         
        require(closefee <= 250);
        require(longRate <= 250 && longRate >= -250);
        require(shortRate <= 250 && shortRate >= -250);
        Book b = Book(books[msg.sender]);
        b.updateFeesBook(uint8(closefee), int16(longRate), int16(shortRate));
        emit RatesUpdated(msg.sender, uint8(closefee), int16(longRate), int16(shortRate));
    }

    function changeFeeAddress(address payable newAddress)
        external
        onlyAdmin
    {
        feeAddress = newAddress;
    }

    function balanceInput(address recipient)
            external
            payable
    {
        assetSwapBalance[recipient] += msg.value;
    }

     
    function createBook(uint16 _min, uint _closefee, int frLong, int frShort)
        external
        payable
        returns (address newBook)
    {
        require(books[msg.sender] == address(0), "User must not have a preexisting book");
        require(msg.value >= uint(_min) * 10 ether, "Must prep for book");
        require(_min >= 1);
        int16 longRate = int16(frLong * leverageRatio / 1e2);
        int16 shortRate = int16(frShort * leverageRatio / 1e2);
        uint8 closefee = uint8(_closefee * uint(leverageRatio) / 1e2);
        require(longRate <= 250 && longRate >= -250);
        require(shortRate <= 250 && shortRate >= -250);
        require(closefee <= 250);
        books[msg.sender] = address(new Book(msg.sender, address(this), _min, closefee, longRate, shortRate));
        Book b = Book(books[msg.sender]);
        b.fundLPBook.value(msg.value)();
        emit LPNewBook(msg.sender, books[msg.sender]);
        return books[msg.sender];
    }

    function fundLP(address _lp)
        external
        payable
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.fundLPBook.value(msg.value)();
    }

    function fundTaker(address _lp, bytes32 subkID)
        external
        payable
        {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.fundTakerBook.value(msg.value)(subkID);
    }

    function burnTaker(address _lp, bytes32 subkID)
        external
        payable
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        uint refund = b.burnTakerBook(subkID, msg.sender, msg.value);
        emit BurnHist(_lp, subkID, msg.sender, now);
        assetSwapBalance[msg.sender] += refund;
    }

    function burnLP()
        external
        payable
    {
        require(books[msg.sender] != address(0));
        Book b = Book(books[msg.sender]);
        uint refund = b.burnLPBook(msg.value);
        bytes32 abcnull;
        emit BurnHist(msg.sender, abcnull, msg.sender, now);
        assetSwapBalance[msg.sender] += refund;
    }

    function cancel(address _lp, bytes32 subkID, bool closeNow)
        external
        payable
    {
        Book b = Book(books[_lp]);
        uint8 priceDay = oracle.getStartDay();
        uint8 endDay = 5;
        if (closeNow)
            endDay = priceDay;
        b.cancelBook.value(msg.value)(lastOracleSettleTime, subkID, msg.sender, endDay);
    }

    function closeBook(address _lp)
        external
        payable
    {
        require(msg.sender == _lp);
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.closeBookBook.value(msg.value)();
    }

    function redeem(address _lp, bytes32 subkID)
        external
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.redeemBook(subkID, msg.sender);
        emit SubkTracker(_lp, msg.sender, subkID, false);
    }

    function settleParts(address _lp)
        external
        returns (bool isComplete)
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        uint lastBookSettleTime = b.lastBookSettleTime();
        require(now > (lastOracleSettleTime + 24 hours));
        require(lastOracleSettleTime > lastBookSettleTime, "one settle per week");
        uint settleNumb = b.settleNum();
        if (settleNumb < 1e4) {
            b.settleExpiring(assetReturns[1]);
        } else if (settleNumb < 2e4) {
            b.settleRolling(assetReturns[0][0]);
        } else if (settleNumb < 3e4) {
            b.settleNew(assetReturns[0]);
        } else if (settleNumb == 3e4) {
            b.settleFinal();
            isComplete = true;
        }
    }

    function settleBatch(address _lp)
        external
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        uint lastBookSettleTime = b.lastBookSettleTime();
        require(now > (lastOracleSettleTime + 24 hours));
        require(lastOracleSettleTime > lastBookSettleTime, "one settle per week");
         
         
        b.settleExpiring(assetReturns[1]);
         
        b.settleRolling(assetReturns[0][0]);
         
         
        b.settleNew(assetReturns[0]);
        b.settleFinal();
    }

    function take(address _lp, uint rm, bool isTakerLong)
        external
        payable
        returns (bytes32 newsubkID)
    {
        rm = rm * 1 ether;
        require(msg.value >= 3 * rm / 2, "Insuffient ETH for your RM");
        require(hourOfDay() != 16, "Cannot take during 4 PM ET hour");
        uint takerLong;
        if (isTakerLong)
            takerLong = 1;
        else
            takerLong = 0;
         
        uint8 priceDay = oracle.getStartDay();
        Book book = Book(books[_lp]);
        newsubkID = book.takeBook.value(msg.value)(msg.sender, rm, lastOracleSettleTime, priceDay, takerLong);
        emit SubkTracker(_lp, msg.sender, newsubkID, true);
    }

     
    function withdrawLP(uint amount)
        external
    {
        require(amount > 0);
        require(books[msg.sender] != address(0));
        Book b = Book(books[msg.sender]);
        amount = 1 finney * amount;
        b.withdrawLPBook(amount, lastOracleSettleTime);
    }

    function withdrawTaker(uint amount, address _lp, bytes32 subkID)
        external
    {
        require(amount > 0);
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        amount = 1 finney * amount;
        b.withdrawTakerBook(subkID, amount, lastOracleSettleTime, msg.sender);
    }
     

    function withdrawFromAssetSwap()
        external
    {
        uint amount = assetSwapBalance[msg.sender];
        require(amount > 0);
        assetSwapBalance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function inactiveOracle(address _lp)
        external
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.inactiveOracleBook();
    }

    function inactiveLP(address _lp, bytes32 subkID)
        external
    {
        require(books[_lp] != address(0));
        Book b = Book(books[_lp]);
        b.inactiveLPBook(subkID, msg.sender, lastOracleSettleTime);
    }

    function getBookData(address _lp)
        external
        view
        returns (address book,
             
            uint lpMargin,
            uint totalLpLong,
            uint totalLpShort,
            uint lpRM,
             
            uint bookMinimum,
             
             
            int16 longFundingRate,
            int16 shortFundingRate,
            uint8 lpCloseFee,
             
            uint8 bookStatus
            )
    {
        book = books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            lpMargin = b.margin(0);
            totalLpLong = b.margin(1);
            totalLpShort = b.margin(2);
            lpRM = b.margin(3);
            bookMinimum = b.lpMinTakeRM();
            longFundingRate = b.fundingRates(1);
            shortFundingRate = b.fundingRates(0);
            lpCloseFee = b.bookCloseFee();
            bookStatus = b.bookStatus();
        }
    }

    function getSubkData1(address _lp, bytes32 subkID)
        external
        view
        returns (
            address taker,
             
            uint takerMargin,
            uint reqMargin
            )
    {
        address book = books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (taker, takerMargin, reqMargin) = b.getSubkData1Book(subkID);
        }
    }

    function getSubkData2(address _lp, bytes32 subkID)
        external
        view
        returns (
           
            uint8 subkStatus,
           
            uint8 priceDay,
           
            uint8 closeFee,
           
            int16 fundingRate,
           
            bool takerSide
            )
    {
        address book = books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (subkStatus, priceDay, closeFee, fundingRate, takerSide)
                = b.getSubkData2Book(subkID);
        }
    }

    function getSettleInfo(address _lp)
        external
        view
        returns (
           
            uint totalLength,
           
            uint expiringLength,
           
           
            uint newLength,
           
            uint lastBookSettleUTC,
           
           
            uint settleNumber,
           
            uint bookBalance,
           
           
           
            uint bookMaturityUTC
            )
    {
        address book = books[_lp];
        if (book != address(0)) {
            Book b = Book(book);
            (totalLength, expiringLength, newLength, lastBookSettleUTC, settleNumber,
                bookBalance, bookMaturityUTC) = b.getSettleInfoBook();
        }
    }

     
    function updateReturns(int[5] memory assetRetNew, int[5] memory assetRetExp)
            public
        {
        require(msg.sender == address(oracle));
        assetReturns[0] = assetRetNew;
        assetReturns[1] = assetRetExp;
        lastOracleSettleTime = now;
    }

    function hourOfDay()
        public
        view
        returns(uint hour1)
    {
        uint nowTemp = now;
     
        hour1 = (nowTemp % 86400) / 3600 - 5;
        if ((nowTemp > 1583668800 && nowTemp < 1604232000) || (nowTemp > 1615705200 && nowTemp < 1636264800) ||
            (nowTemp > 1647154800 && nowTemp < 1667714400))
            hour1 = hour1 + 1;
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


}
