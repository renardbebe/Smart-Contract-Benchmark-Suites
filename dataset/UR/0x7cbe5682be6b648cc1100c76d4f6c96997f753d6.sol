 
    function changeUniswapFactoryAddress(address newFactoryAddress) external onlyInternal {
         
        uniswapFactoryAddress = newFactoryAddress;
        factory = Factory(uniswapFactoryAddress);
    }

     
    function upgradeInvestmentPool(address payable newPoolAddress) external onlyInternal noReentrancy {
        uint len = pd.getInvestmentCurrencyLen();
        for (uint64 i = 1; i < len; i++) {
            bytes4 iaName = pd.getInvestmentCurrencyByIndex(i);
            _upgradeInvestmentPool(iaName, newPoolAddress);
        }

        if (address(this).balance > 0) {
            Pool2 newP2 = Pool2(newPoolAddress);
            newP2.sendEther.value(address(this).balance)();
        }
    }

      
    function internalLiquiditySwap(bytes4 curr) external onlyInternal noReentrancy {
        uint caBalance;
        uint baseMin;
        uint varMin;
        (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
        caBalance = _getCurrencyAssetsBalance(curr);

        if (caBalance > uint(baseMin).add(varMin).mul(2)) {
            _internalExcessLiquiditySwap(curr, baseMin, varMin, caBalance);
        } else if (caBalance < uint(baseMin).add(varMin)) {
            _internalInsufficientLiquiditySwap(curr, baseMin, varMin, caBalance);
            
        }
    }

      
    function saveIADetails(bytes4[] calldata curr, uint64[] calldata rate, uint64 date, bool bit) 
    external checkPause noReentrancy {
        bytes4 maxCurr;
        bytes4 minCurr;
        uint64 maxRate;
        uint64 minRate;
         
        require(pd.isnotarise(msg.sender));
        (maxCurr, maxRate, minCurr, minRate) = _calculateIARank(curr, rate);
        pd.saveIARankDetails(maxCurr, maxRate, minCurr, minRate, date);
        pd.updatelastDate(date);
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            pd.updateIAAvgRate(curr[i], rate[i]);
        }
        if (bit)    
            _rebalancingLiquidityTrading(maxCurr, maxRate);
        p1.saveIADetailsOracalise(pd.iaRatesTime());
    }

      
    function externalLiquidityTrade() external onlyInternal {
        
        bool triggerTrade;
        bytes4 curr;
        bytes4 minIACurr;
        bytes4 maxIACurr;
        uint amount;
        uint minIARate;
        uint maxIARate;
        uint baseMin;
        uint varMin;
        uint caBalance;


        (maxIACurr, maxIARate, minIACurr, minIARate) = pd.getIARankDetailsByDate(pd.getLastDate());
        uint len = pd.getAllCurrenciesLen();
        for (uint64 i = 0; i < len; i++) {
            curr = pd.getCurrenciesByIndex(i);
            (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
            caBalance = _getCurrencyAssetsBalance(curr);

            if (caBalance > uint(baseMin).add(varMin).mul(2)) {  
                amount = caBalance.sub(((uint(baseMin).add(varMin)).mul(3)).div(2));  
                triggerTrade = _externalExcessLiquiditySwap(curr, minIACurr, amount);
            } else if (caBalance < uint(baseMin).add(varMin)) {  
                amount = (((uint(baseMin).add(varMin)).mul(3)).div(2)).sub(caBalance);
                triggerTrade = _externalInsufficientLiquiditySwap(curr, maxIACurr, amount);
            }

            if (triggerTrade) {
                p1.triggerExternalLiquidityTrade();
            }
        }
    }

     
    function changeDependentContractAddress() public onlyInternal {
        m1 = MCR(ms.getLatestAddress("MC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
    }

    function sendEther() public payable {
        
    }

        
    function _getCurrencyAssetsBalance(bytes4 _curr) public view returns(uint caBalance) {
        if (_curr == "ETH") {
            caBalance = address(p1).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
            caBalance = erc20.balanceOf(address(p1));
        }
    }

      
    function _transferInvestmentAsset(
        bytes4 _curr,
        address _transferTo,
        uint _amount
    ) 
        internal
    {
        if (_curr == "ETH") {
            if (_amount > address(this).balance)
                _amount = address(this).balance;
            p1.sendEther.value(_amount)();
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            if (_amount > erc20.balanceOf(address(this)))
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(_transferTo, _amount));
        }
    }

     
    function _rebalancingLiquidityTrading(
        bytes4 iaCurr,
        uint64 iaRate
    ) 
        internal
        checkPause
    {
        uint amountToSell;
        uint totalRiskBal = pd.getLastVfull();
        uint intermediaryEth;
        uint ethVol = pd.ethVolumeLimit();

        totalRiskBal = (totalRiskBal.mul(100000)).div(DECIMAL1E18);
        Exchange exchange;
        if (totalRiskBal > 0) {
            amountToSell = ((totalRiskBal.mul(2).mul(
                iaRate)).mul(pd.variationPercX100())).div(100 * 100 * 100000);
            amountToSell = (amountToSell.mul(
                10**uint(pd.getInvestmentAssetDecimals(iaCurr)))).div(100);  

            if (iaCurr != "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) { 
                exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(iaCurr)));
                intermediaryEth = exchange.getTokenToEthInputPrice(amountToSell);
                if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                    intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                    amountToSell = (exchange.getEthToTokenInputPrice(intermediaryEth).mul(995)).div(1000);
                }
                IERC20 erc20;
                erc20 = IERC20(pd.getCurrencyAssetAddress(iaCurr));
                erc20.approve(address(exchange), amountToSell);
                exchange.tokenToEthSwapInput(amountToSell, (exchange.getTokenToEthInputPrice(
                    amountToSell).mul(995)).div(1000), pd.uniswapDeadline().add(now));
            } else if (iaCurr == "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) {

                _transferInvestmentAsset(iaCurr, ms.getLatestAddress("P1"), amountToSell);
            }
            emit Rebalancing(iaCurr, amountToSell); 
        }
    }

      
    function _checkTradeConditions(
        bytes4 curr,
        uint64 iaRate,
        uint totalRiskBal
    )
        internal
        view
        returns(bool check)
    {
        if (iaRate > 0) {
            uint iaBalance =  _getInvestmentAssetBalance(curr).div(DECIMAL1E18);
            if (iaBalance > 0 && totalRiskBal > 0) {
                uint iaMax;
                uint iaMin;
                uint checkNumber;
                uint z;
                (iaMin, iaMax) = pd.getInvestmentAssetHoldingPerc(curr);
                z = pd.variationPercX100();
                checkNumber = (iaBalance.mul(100 * 100000)).div(totalRiskBal.mul(iaRate));
                if ((checkNumber > ((totalRiskBal.mul(iaMax.add(z))).mul(100000)).div(100)) ||
                    (checkNumber < ((totalRiskBal.mul(iaMin.sub(z))).mul(100000)).div(100)))
                    check = true;  
            }
        }
    }    

      
    function _getIARank(
        bytes4 curr,
        uint64 rateX100,
        uint totalRiskPoolBalance
    ) 
        internal
        view
        returns (int rhsh, int rhsl)  
    {

        uint currentIAmaxHolding;
        uint currentIAminHolding;
        uint iaBalance = _getInvestmentAssetBalance(curr);
        (currentIAminHolding, currentIAmaxHolding) = pd.getInvestmentAssetHoldingPerc(curr);
        
        if (rateX100 > 0) {
            uint rhsf;
            rhsf = (iaBalance.mul(1000000)).div(totalRiskPoolBalance.mul(rateX100));
            rhsh = int(rhsf - currentIAmaxHolding);
            rhsl = int(rhsf - currentIAminHolding);
        }
    }

       
    function _calculateIARank(
        bytes4[] memory curr,
        uint64[] memory rate
    )
        internal
        view
        returns(
            bytes4 maxCurr,
            uint64 maxRate,
            bytes4 minCurr,
            uint64 minRate
        )  
    {
        int max = 0;
        int min = -1;
        int rhsh;
        int rhsl;
        uint totalRiskPoolBalance;
        (totalRiskPoolBalance, ) = m1.calVtpAndMCRtp();
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            rhsl = 0;
            rhsh = 0;
            if (pd.getInvestmentAssetStatus(curr[i])) {
                (rhsh, rhsl) = _getIARank(curr[i], rate[i], totalRiskPoolBalance);
                if (rhsh > max || i == 0) {
                    max = rhsh;
                    maxCurr = curr[i];
                    maxRate = rate[i];
                }
                if (rhsl < min || rhsl == 0 || i == 0) {
                    min = rhsl;
                    minCurr = curr[i];
                    minRate = rate[i];
                }
            }
        }
    }

     
    function _getInvestmentAssetBalance(bytes4 _curr) internal view returns (uint balance) {
        if (_curr == "ETH") {
            balance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            balance = erc20.balanceOf(address(this));
        }
    }

       
    function _internalExcessLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {
         
        bytes4 minIACurr;
         
        
        (, , minIACurr, ) = pd.getIARankDetailsByDate(pd.getLastDate());
        if (_curr == minIACurr) {
             
            p1.transferCurrencyAsset(_curr, _caBalance.sub(((_baseMin.add(_varMin)).mul(3)).div(2)));
        } else {
            p1.triggerExternalLiquidityTrade();
        }
    }

      
    function _internalInsufficientLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {
        
        bytes4 maxIACurr;
        uint amount;
        
        (maxIACurr, , , ) = pd.getIARankDetailsByDate(pd.getLastDate());
        
        if (_curr == maxIACurr) {
            amount = (((_baseMin.add(_varMin)).mul(3)).div(2)).sub(_caBalance);
            _transferInvestmentAsset(_curr, ms.getLatestAddress("P1"), amount);
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            if ((maxIACurr == "ETH" && address(this).balance > 0) || 
            (maxIACurr != "ETH" && erc20.balanceOf(address(this)) > 0))
                p1.triggerExternalLiquidityTrade();
            
        }
    }

       
    function _externalExcessLiquiditySwap(
        bytes4 curr,
        bytes4 minIACurr,
        uint256 amount
    )
        internal
        returns (bool trigger)
    {
        uint intermediaryEth;
        Exchange exchange;
        IERC20 erc20;
        uint ethVol = pd.ethVolumeLimit();
        if (curr == minIACurr) {
            p1.transferCurrencyAsset(curr, amount);
        } else if (curr == "ETH" && minIACurr != "ETH") {
            
            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(minIACurr)));
            if (amount > (address(exchange).balance.mul(ethVol)).div(100)) {  
                amount = (address(exchange).balance.mul(ethVol)).div(100);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
            exchange.ethToTokenSwapInput.value(amount)
            (exchange.getEthToTokenInputPrice(amount).mul(995).div(1000), pd.uniswapDeadline().add(now));    
        } else if (curr != "ETH" && minIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                intermediaryEth = exchange.getTokenToEthInputPrice(amount);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
             
            erc20.approve(address(exchange), amount);
            
            exchange.tokenToEthSwapInput(amount, (
                intermediaryEth.mul(995)).div(1000), pd.uniswapDeadline().add(now));   
        } else {
            
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;
            }
            
            Exchange tmp = Exchange(factory.getExchange(
                pd.getInvestmentAssetAddress(minIACurr)));  

            if (intermediaryEth > address(tmp).balance.mul(ethVol).div(100)) { 
                intermediaryEth = address(tmp).balance.mul(ethVol).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;   
            }
            p1.transferCurrencyAsset(curr, amount);
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            erc20.approve(address(exchange), amount);
            
            exchange.tokenToTokenSwapInput(amount, (tmp.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), (intermediaryEth.mul(995)).div(1000), 
                    pd.uniswapDeadline().add(now), pd.getInvestmentAssetAddress(minIACurr));
        }
    }

      
    function _externalInsufficientLiquiditySwap(
        bytes4 curr,
        bytes4 maxIACurr,
        uint256 amount
    ) 
        internal
        returns (bool trigger)
    {   

        Exchange exchange;
        IERC20 erc20;
        uint intermediaryEth;
         
        if (curr == maxIACurr) {
            _transferInvestmentAsset(curr, ms.getLatestAddress("P1"), amount);
        } else if (curr == "ETH" && maxIACurr != "ETH") { 
            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));
            intermediaryEth = exchange.getEthToTokenInputPrice(amount);


            if (amount > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) { 
                amount = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                 
                intermediaryEth = exchange.getEthToTokenInputPrice(amount);
                trigger = true;
            }
            
            erc20 = IERC20(pd.getCurrencyAssetAddress(maxIACurr));
            if (intermediaryEth > erc20.balanceOf(address(this))) {
                intermediaryEth = erc20.balanceOf(address(this));
            }
             
            erc20.approve(address(exchange), intermediaryEth);
            exchange.tokenToEthTransferInput(intermediaryEth, (
                exchange.getTokenToEthInputPrice(intermediaryEth).mul(995)).div(1000), 
                pd.uniswapDeadline().add(now), address(p1)); 

        } else if (curr != "ETH" && maxIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > address(this).balance)
                intermediaryEth = address(this).balance;
            if (intermediaryEth > (address(exchange).balance.mul
            (pd.ethVolumeLimit())).div(100)) {  
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            exchange.ethToTokenTransferInput.value(intermediaryEth)((exchange.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), pd.uniswapDeadline().add(now), address(p1));   
        } else {
            address currAdd = pd.getCurrencyAssetAddress(curr);
            exchange = Exchange(factory.getExchange(currAdd));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) { 
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            Exchange tmp = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));

            if (intermediaryEth > address(tmp).balance.mul(pd.ethVolumeLimit()).div(100)) { 
                intermediaryEth = address(tmp).balance.mul(pd.ethVolumeLimit()).div(100);
                 
                trigger = true;
            }

            uint maxIAToSell = tmp.getEthToTokenInputPrice(intermediaryEth);

            erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            uint maxIABal = erc20.balanceOf(address(this));
            if (maxIAToSell > maxIABal) {
                maxIAToSell = maxIABal;
                intermediaryEth = tmp.getTokenToEthInputPrice(maxIAToSell);
                 
            }
            amount = exchange.getEthToTokenInputPrice(intermediaryEth);
            erc20.approve(address(tmp), maxIAToSell);
            tmp.tokenToTokenTransferInput(maxIAToSell, (
                amount.mul(995)).div(1000), (
                    intermediaryEth), pd.uniswapDeadline().add(now), address(p1), currAdd);
        }
    }

      
    function _upgradeInvestmentPool(
        bytes4 _curr,
        address _newPoolAddress
    ) 
        internal
    {
        IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }
}