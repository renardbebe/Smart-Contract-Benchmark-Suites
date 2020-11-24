 

    function addAdmin(address newAdmin)
        external
        onlyAdmin
    {
        admins[newAdmin] = true;
    }

     
    function addReaders(address newReader)
        external
        onlyAdmin
    {
        readers[newReader] = true;
    }
     

    function addAssetSwaps(address newAS0, address newAS1, address newAS2)
        external
        onlyAdmin
    {
        require(assetSwaps[0] == address(0));
        assetSwaps[0] = newAS0;
        assetSwaps[1] = newAS1;
        assetSwaps[2] = newAS2;
        readers[newAS0] = true;
        readers[newAS1] = true;
        readers[newAS2] = true;
    }

    function removeAdmin(address toRemove)
        external
        onlyAdmin
    {
        require(toRemove != msg.sender);
        admins[toRemove] = false;
    }
     

    function editPrice(uint _ethprice, uint _spxprice, uint _btcprice)
        external
        onlyAdmin
    {
        require(now < lastUpdateTime + 60 minutes);
        prices[0][currentDay] = _ethprice;
        prices[1][currentDay] = _spxprice;
        prices[2][currentDay] = _btcprice;
        emit PriceUpdated(_ethprice, _spxprice, _btcprice, now, currentDay, true);
    }

    function updatePrices(uint ethp, uint spxp, uint btcp, bool _newFinalDay)
        external
        onlyAdmin
    {

              
        require(now > lastUpdateTime + 20 hours);
             
        require(!nextUpdateSettle);
          
        require(now > lastSettleTime + 48 hours, "too soon after last settle");
           
        require(ethp != prices[0][currentDay] && spxp != prices[1][currentDay] && btcp != prices[2][currentDay]);
             
           
        require((ethp * 10 < prices[0][currentDay] * 15) && (ethp * 10 > prices[0][currentDay] * 5));
        require((spxp * 10 < prices[1][currentDay] * 15) && (spxp * 10 > prices[1][currentDay] * 5));
        require((btcp * 10 < prices[2][currentDay] * 15) && (btcp * 10 > prices[2][currentDay] * 5));
        if (currentDay == 5) {
            currentDay = 1;
            nextUpdateSettle = false;
        } else {
            currentDay += 1;
            nextUpdateSettle = _newFinalDay;
        }
        if (currentDay == 4)
            nextUpdateSettle = true;
        updatePriceSingle(0, ethp);
        updatePriceSingle(1, spxp);
        updatePriceSingle(2, btcp);
        emit PriceUpdated(ethp, spxp, btcp, now, currentDay, false);
        lastUpdateTime = now;
    }

    function settlePrice(uint ethp, uint spxp, uint btcp)
        external
        onlyAdmin
    {
        require(nextUpdateSettle);
        require(now > lastUpdateTime + 20 hours);
        require(ethp != prices[0][currentDay] && spxp != prices[1][currentDay] && btcp != prices[2][currentDay]);
        require((ethp * 10 < prices[0][currentDay] * 15) && (ethp * 10 > prices[0][currentDay] * 5));
        require((spxp * 10 < prices[1][currentDay] * 15) && (spxp * 10 > prices[1][currentDay] * 5));
        require((btcp * 10 < prices[2][currentDay] * 15) && (btcp * 10 > prices[2][currentDay] * 5));
        currentDay = 5;
        nextUpdateSettle = false;
        updatePriceSingle(0, ethp);
        updatePriceSingle(1, spxp);
        updatePriceSingle(2, btcp);
        int[5] memory assetReturnsNew;
        int[5] memory assetReturnsExpiring;
        int cap = 975 * 1 ether / 1000;
        for (uint j = 0; j < 3; j++) {
                   
            for (uint i = 0; i < 5; i++) {
                if (prices[0][i] != 0) {
                    int assetRetFwd = int(prices[j][5] * 1 ether / prices[j][i]) - 1 ether;
                    assetReturnsNew[i] = assetRetFwd * int(prices[0][i]) * levRatio[j] /
                        int(prices[0][5]) / 100;
                 
                    assetReturnsNew[i] = bound(assetReturnsNew[i], cap);
                }
                if (prices[0][i+1] != 0) {
                    int assetRetBack = int(prices[j][i+1] * 1 ether / prices[j][0]) - 1 ether;
                    assetReturnsExpiring[i] = assetRetBack * int(prices[0][0]) * levRatio[j] /
                        int(prices[0][i+1]) / 100;

                    assetReturnsExpiring[i] = bound(assetReturnsExpiring[i], cap);
                }
            }
     
     
            AssetSwap asw = AssetSwap(assetSwaps[j]);
            asw.updateReturns(assetReturnsNew, assetReturnsExpiring);
        }
        lastSettleTime = now;
        emit PriceUpdated(ethp, spxp, btcp, now, currentDay, false);
        lastUpdateTime = now;
    }
     

    function getUsdPrices(uint _assetID)
        public
        view
        returns (uint[6] memory _priceHist)
    {
        require(admins[msg.sender] || readers[msg.sender]);
        _priceHist = prices[_assetID];
    }

         
    function getCurrentPrice(uint _assetID)
        public
        view
        returns (uint _price)
    {
        require(admins[msg.sender] || readers[msg.sender]);
        _price = prices[_assetID][currentDay];
    }

     
    function getStartDay()
        public
        view
        returns (uint8 _startDay)
    {
        if (nextUpdateSettle) {
            _startDay = 5;
        } else if (currentDay == 5) {
            _startDay = 1;
        } else {
            _startDay = currentDay + 1;
        }
    }

    function updatePriceSingle(uint _assetID, uint _price)
        internal
    {
        if (currentDay == 1) {
            uint[6] memory newPrices;
            newPrices[0] = prices[_assetID][5];
            newPrices[1] = _price;
            prices[_assetID] = newPrices;
        } else {
            prices[_assetID][currentDay] = _price;
        }
    }

    function bound(int a, int b)
        internal
        pure
        returns (int)
    {
        if (a > b)
            a = b;
        if (a < -b)
            a = -b;
        return a;
    }

}
