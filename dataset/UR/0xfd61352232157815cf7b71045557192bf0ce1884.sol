  
    function sendClaimPayout(
        uint coverid,
        uint claimid,
        uint sumAssured,
        address payable coverHolder,
        bytes4 coverCurr
    )
        external
        onlyInternal
        noReentrancy
        returns(bool succ)
    {
        
        uint sa = sumAssured.div(DECIMAL1E18);
        bool check;
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));

         
        if (coverCurr == "ETH" && address(this).balance >= sumAssured) {
             
            coverHolder.transfer(sumAssured);
            check = true;
        } else if (coverCurr == "DAI" && erc20.balanceOf(address(this)) >= sumAssured) {
            erc20.transfer(coverHolder, sumAssured);
            check = true;
        }
        
        if (check == true) {
            q2.removeSAFromCSA(coverid, sa);
            pd.changeCurrencyAssetVarMin(coverCurr, 
                pd.getCurrencyAssetVarMin(coverCurr).sub(sumAssured));
            emit Payout(coverHolder, coverid, sumAssured);
            succ = true;
        } else {
            c1.setClaimStatus(claimid, 12);
        }
        _triggerExternalLiquidityTrade();
         

        tf.burnStakerLockedToken(coverid, coverCurr, sumAssured);
    }

     
    function triggerExternalLiquidityTrade() external onlyInternal {
        _triggerExternalLiquidityTrade();
    }

     
    function closeEmergencyPause(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 300000);
        _saveApiDetails(myid, "EP", 0);
    }

     
     
     
    function closeClaimsOraclise(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 3000000);
        _saveApiDetails(myid, "CLA", id);
    }

     
     
     
    function closeCoverOraclise(uint id, uint64 time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", strConcat(
            "http://a1.nexusmutual.io/api/Claims/closeClaim_hash/", uint2str(id)), 1000000);
        _saveApiDetails(myid, "COV", id);
    }

     
     
    function mcrOraclise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https://api.nexusmutual.io/postMCR/M1", 0);
        _saveApiDetails(myid, "MCR", 0);
    }

     
     
    function mcrOracliseFail(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 1000000);
        _saveApiDetails(myid, "MCRF", id);
    }

     
    function saveIADetailsOracalise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https://api.nexusmutual.io/saveIADetails/M1", 0);
        _saveApiDetails(myid, "IARB", 0);
    }
    
     
    function upgradeCapitalPool(address payable newPoolAddress) external noReentrancy onlyInternal {
        for (uint64 i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes4 caName = pd.getCurrenciesByIndex(i);
            _upgradeCapitalPool(caName, newPoolAddress);
        }
        if (address(this).balance > 0) {
            Pool1 newP1 = Pool1(newPoolAddress);
            newP1.sendEther.value(address(this).balance)();
        }
    }

     
    function changeDependentContractAddress() public {
        m1 = MCR(ms.getLatestAddress("MC"));
        tk = NXMToken(ms.tokenAddress());
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        q2 = Quotation(ms.getLatestAddress("QT"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        c1 = Claims(ms.getLatestAddress("CL"));
        td = TokenData(ms.getLatestAddress("TD"));
    }

    function sendEther() public payable {
        
    }

     
    function transferCurrencyAsset(
        bytes4 curr,
        uint amount
    )
        public
        onlyInternal
        noReentrancy
        returns(bool)
    {
    
        return _transferCurrencyAsset(curr, amount);
    } 

     
    function __callback(bytes32 myid, string memory result) public {
        result;  
         
        ms.delegateCallBack(myid);
    }

     
     
    function makeCoverBegin(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMember
        checkPause
        payable
    {
        require(msg.value == coverDetails[1]);
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

      
    function makeCoverUsingCA(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) 
        public
        isMember
        checkPause
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
        require(erc20.transferFrom(msg.sender, address(this), coverDetails[1]), "Transfer failed");
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }

     
    function buyToken() public payable isMember checkPause returns(bool success) {
        require(msg.value > 0);
        uint tokenPurchased = _getToken(address(this).balance, msg.value);
        tc.mint(msg.sender, tokenPurchased);
        success = true;
    }

     
     
     
     
    function transferEther(uint amount, address payable _add) public noReentrancy checkPause returns(bool succ) {
        require(ms.checkIsAuthToGoverned(msg.sender), "Not authorized to Govern");
        succ = _add.send(amount);
    }

     
    function sellNXMTokens(uint _amount) public isMember noReentrancy checkPause returns(bool success) {
        require(tk.balanceOf(msg.sender) >= _amount, "Not enough balance");
        require(!tf.isLockedForMemberVote(msg.sender), "Member voted");
        require(_amount <= m1.getMaxSellTokens(), "exceeds maximum token sell limit");
        uint sellingPrice = _getWei(_amount);
        tc.burnFrom(msg.sender, _amount);
        msg.sender.transfer(sellingPrice);
        success = true;
    }

     
    function getInvestmentAssetBalance() public view returns (uint balance) {
        IERC20 erc20;
        uint currTokens;
        for (uint i = 1; i < pd.getInvestmentCurrencyLen(); i++) {
            bytes4 currency = pd.getInvestmentCurrencyByIndex(i);
            erc20 = IERC20(pd.getInvestmentAssetAddress(currency));
            currTokens = erc20.balanceOf(address(p2));
            if (pd.getIAAvgRate(currency) > 0)
                balance = balance.add((currTokens.mul(100)).div(pd.getIAAvgRate(currency)));
        }

        balance = balance.add(address(p2).balance);
    }

     
    function getWei(uint amount) public view returns(uint weiToPay) {
        return _getWei(amount);
    }

     
    function getToken(uint weiPaid) public view returns(uint tokenToGet) {
        return _getToken((address(this).balance).add(weiPaid), weiPaid);
    }

     
    function _triggerExternalLiquidityTrade() internal {
        if (now > pd.lastLiquidityTradeTrigger().add(pd.liquidityTradeCallbackTime())) {
            pd.setLastLiquidityTradeTrigger();
            bytes32 myid = _oraclizeQuery(4, pd.liquidityTradeCallbackTime(), "URL", "", 300000);
            _saveApiDetails(myid, "ULT", 0);
        }
    }

     
    function _getWei(uint _amount) internal view returns(uint weiToPay) {
        uint tokenPrice;
        uint weiPaid;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calVtpAndMCRtp();

        while (_amount > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);
            tokenPrice = (tokenPrice.mul(975)).div(1000);  
            if (_amount <= td.priceStep().mul(DECIMAL1E18)) {
                weiToPay = weiToPay.add((tokenPrice.mul(_amount)).div(DECIMAL1E18));
                break;
            } else {
                _amount = _amount.sub(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.sub(td.priceStep().mul(DECIMAL1E18));
                weiPaid = (tokenPrice.mul(td.priceStep().mul(DECIMAL1E18))).div(DECIMAL1E18);
                vtp = vtp.sub(weiPaid);
                weiToPay = weiToPay.add(weiPaid);
            }
        }
    }

     
    function _getToken(uint _poolBalance, uint _weiPaid) internal view returns(uint tokenToGet) {
        uint tokenPrice;
        uint superWeiLeft = (_weiPaid).mul(DECIMAL1E18);
        uint tempTokens;
        uint superWeiSpent;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;   
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calculateVtpAndMCRtp((_poolBalance).sub(_weiPaid));

        require(m1.calculateTokenPrice("ETH") > 0, "Token price can not be zero");
        while (superWeiLeft > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);            
            tempTokens = superWeiLeft.div(tokenPrice);
            if (tempTokens <= td.priceStep().mul(DECIMAL1E18)) {
                tokenToGet = tokenToGet.add(tempTokens);
                break;
            } else {
                tokenToGet = tokenToGet.add(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.add(td.priceStep().mul(DECIMAL1E18));
                superWeiSpent = td.priceStep().mul(DECIMAL1E18).mul(tokenPrice);
                superWeiLeft = superWeiLeft.sub(superWeiSpent);
                vtp = vtp.add((td.priceStep().mul(DECIMAL1E18).mul(tokenPrice)).div(DECIMAL1E18));
            }
        }
    }

      
    function _saveApiDetails(bytes32 myid, bytes4 _typeof, uint id) internal {
        pd.saveApiDetails(myid, _typeof, id);
        pd.addInAllApiCall(myid);
    }

     
    function _transferCurrencyAsset(bytes4 _curr, uint _amount) internal returns(bool succ) {
        if (_curr == "ETH") {
            if (address(this).balance < _amount)
                _amount = address(this).balance;
            p2.sendEther.value(_amount)();
            succ = true;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));  
            if (erc20.balanceOf(address(this)) < _amount) 
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(address(p2), _amount)); 
            succ = true;
            
        }
    } 

      
    function _upgradeCapitalPool(
        bytes4 _curr,
        address _newPoolAddress
    ) 
        internal
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }

     
    function _oraclizeQuery(
        uint paramCount,
        uint timestamp,
        string memory datasource,
        string memory arg,
        uint gasLimit
    ) 
        internal
        returns (bytes32 id)
    {
        if (paramCount == 4) {
            id = oraclize_query(timestamp, datasource, arg, gasLimit);   
        } else if (paramCount == 3) {
            id = oraclize_query(timestamp, datasource, arg);   
        } else {
            id = oraclize_query(datasource, arg);
        }
    }
}
