 
contract Comptroller is ComptrollerV1Storage, ComptrollerInterface, ComptrollerErrorReporter, Exponential {
    struct Market {
         
        bool isListed;

         
        uint collateralFactorMantissa;

         
        mapping(address => bool) accountMembership;
    }

     
    mapping(address => Market) public markets;

     
    event MarketListed(CToken cToken);

     
    event MarketEntered(CToken cToken, address account);

     
    event MarketExited(CToken cToken, address account);

     
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

     
    event NewCollateralFactor(CToken cToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

     
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

     
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

     
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

     
    bool public constant isComptroller = true;

     
    uint constant closeFactorMinMantissa = 5e16;  

     
    uint constant closeFactorMaxMantissa = 9e17;  

     
    uint constant collateralFactorMaxMantissa = 9e17;  

     
    uint constant liquidationIncentiveMinMantissa = mantissaOne;

     
    uint constant liquidationIncentiveMaxMantissa = 15e17;  

    constructor() public {
        admin = msg.sender;
    }

     

     
    function getAssetsIn(address account) external view returns (CToken[] memory) {
        CToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

     
    function checkMembership(address account, CToken cToken) external view returns (bool) {
        return markets[address(cToken)].accountMembership[account];
    }

     
    function enterMarkets(address[] memory cTokens) public returns (uint[] memory) {
        uint len = cTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            CToken cToken = CToken(cTokens[i]);
            Market storage marketToJoin = markets[address(cToken)];

            if (!marketToJoin.isListed) {
                 
                results[i] = uint(Error.MARKET_NOT_LISTED);
                continue;
            }

            if (marketToJoin.accountMembership[msg.sender] == true) {
                 
                results[i] = uint(Error.NO_ERROR);
                continue;
            }

            if (accountAssets[msg.sender].length >= maxAssets)  {
                 
                results[i] = uint(Error.TOO_MANY_ASSETS);
                continue;
            }

             
             
             
             
             
            marketToJoin.accountMembership[msg.sender] = true;
            accountAssets[msg.sender].push(cToken);

            emit MarketEntered(cToken, msg.sender);

            results[i] = uint(Error.NO_ERROR);
        }

        return results;
    }

     
    function exitMarket(address cTokenAddress) external returns (uint) {
        CToken cToken = CToken(cTokenAddress);
         
        (uint oErr, uint tokensHeld, uint amountOwed, ) = cToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed");  

         
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

         
        uint allowed = redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(cToken)];

         
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

         
        delete marketToExit.accountMembership[msg.sender];

         
         
        CToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == cToken) {
                assetIndex = i;
                break;
            }
        }

         
        assert(assetIndex < len);

         
        CToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(cToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

     

     
    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint) {
        minter;        
        mintAmount;    

        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

         

        return uint(Error.NO_ERROR);
    }

     
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external {
        cToken;        
        minter;        
        mintAmount;    
        mintTokens;    

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     
    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint) {
        return redeemAllowedInternal(cToken, redeemer, redeemTokens);
    }

    function redeemAllowedInternal(address cToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

         

         
        if (!markets[cToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

         
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, CToken(cToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

     
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        cToken;          
        redeemer;        
        redeemAmount;    
        redeemTokens;    

         
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

     
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint) {
        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

         

        if (!markets[cToken].accountMembership[borrower]) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        if (oracle.getUnderlyingPrice(CToken(cToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, CToken(cToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

     
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external {
        cToken;          
        borrower;        
        borrowAmount;    

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint) {
        payer;          
        borrower;       
        repayAmount;    

        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

         

        return uint(Error.NO_ERROR);
    }

     
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external {
        cToken;         
        payer;          
        borrower;       
        repayAmount;    
        borrowerIndex;  

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint) {
        liquidator;    
        borrower;      
        repayAmount;   

        if (!markets[cTokenBorrowed].isListed || !markets[cTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

         

         
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

         
        uint borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);
        (MathError mathErr, uint maxClose) = mulScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (mathErr != MathError.NO_ERROR) {
            return uint(Error.MATH_ERROR);
        }
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

     
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external {
        cTokenBorrowed;    
        cTokenCollateral;  
        liquidator;        
        borrower;          
        repayAmount;       
        seizeTokens;       

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     
    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint) {
        liquidator;        
        borrower;          
        seizeTokens;       

        if (!markets[cTokenCollateral].isListed || !markets[cTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (CToken(cTokenCollateral).comptroller() != CToken(cTokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }

         

        return uint(Error.NO_ERROR);
    }

     
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external {
        cTokenCollateral;  
        cTokenBorrowed;    
        liquidator;        
        borrower;          
        seizeTokens;       

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     
    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint) {
        cToken;          
        src;             
        dst;             
        transferTokens;  

         

         
         
        return redeemAllowedInternal(cToken, src, transferTokens);
    }

     
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external {
        cToken;          
        src;             
        dst;             
        transferTokens;  

        if (false) {
            maxAssets = maxAssets;  
        }
    }

     

     
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint cTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToEther;
    }

     
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, CToken(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

     
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, CToken(0), 0, 0);
    }

     
    function getHypotheticalAccountLiquidityInternal(
        address account,
        CToken cTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars;  
        uint oErr;
        MathError mErr;

         
        CToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            CToken asset = assets[i];

             
            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) {  
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

             
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

             
            (mErr, vars.tokensToEther) = mulExp3(vars.collateralFactor, vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

             
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToEther, vars.cTokenBalance, vars.sumCollateral);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

             
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

             
            if (asset == cTokenModify) {
                 
                 
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToEther, redeemTokens, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }

                 
                 
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }
            }
        }

         
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

     
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint repayAmount) external view returns (uint, uint) {
         
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(CToken(cTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(CToken(cTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

         
        uint exchangeRateMantissa = CToken(cTokenCollateral).exchangeRateStored();  
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, denominator) = mulExp(priceCollateralMantissa, exchangeRateMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, seizeTokens) = mulScalarTruncate(ratio, repayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        return (uint(Error.NO_ERROR), seizeTokens);
    }

     

     
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
         
        if (!adminOrInitializing()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

         
        PriceOracle oldOracle = oracle;

         
         

         
        oracle = newOracle;

         
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

     
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint256) {
         
        if (!adminOrInitializing()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        Exp memory newCloseFactorExp = Exp({mantissa: newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa: closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({mantissa: closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

     
    function _setCollateralFactor(CToken cToken, uint newCollateralFactorMantissa) external returns (uint256) {
         
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

         
        Market storage market = markets[address(cToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

         
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

         
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(cToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

         
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

         
        emit NewCollateralFactor(cToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

     
    function _setMaxAssets(uint newMaxAssets) external returns (uint) {
         
        if (!adminOrInitializing()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_ASSETS_OWNER_CHECK);
        }

        uint oldMaxAssets = maxAssets;
        maxAssets = newMaxAssets;
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);

        return uint(Error.NO_ERROR);
    }

     
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
         
        if (!adminOrInitializing()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

         
        Exp memory newLiquidationIncentive = Exp({mantissa: newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa: liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa: liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

         
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

         
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

         
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

     
    function _supportMarket(CToken cToken) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[address(cToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        cToken.isCToken();  

        markets[address(cToken)] = Market({isListed: true, collateralFactorMantissa: 0});
        emit MarketListed(cToken);

        return uint(Error.NO_ERROR);
    }

    function _become(Unitroller unitroller, PriceOracle _oracle, uint _closeFactorMantissa, uint _maxAssets, bool reinitializing) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        uint changeStatus = unitroller._acceptImplementation();

        require(changeStatus == 0, "change not authorized");

        if (!reinitializing) {
            Comptroller freshBrainedComptroller = Comptroller(address(unitroller));

             
            uint err = freshBrainedComptroller._setPriceOracle(_oracle);
            require (err == uint(Error.NO_ERROR), "set price oracle error");

             
            err = freshBrainedComptroller._setCloseFactor(_closeFactorMantissa);
            require (err == uint(Error.NO_ERROR), "set close factor error");

             
            err = freshBrainedComptroller._setMaxAssets(_maxAssets);
            require (err == uint(Error.NO_ERROR), "set max asssets error");

             
            err = freshBrainedComptroller._setLiquidationIncentive(liquidationIncentiveMinMantissa);
            require (err == uint(Error.NO_ERROR), "set liquidation incentive error");
        }
    }

     
    function adminOrInitializing() internal view returns (bool) {
        bool initializing = (
                msg.sender == comptrollerImplementation
                &&
                 
                tx.origin == admin
        );
        bool isAdmin = msg.sender == admin;
        return isAdmin || initializing;
    }
}
