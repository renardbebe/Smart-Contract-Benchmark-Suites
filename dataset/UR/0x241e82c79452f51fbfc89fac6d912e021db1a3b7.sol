 

 

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract GlobalStore {
    Store.State state;
}

contract ExternalFunctions is GlobalStore {

     
     
     

    function batch(
        BatchActions.Action[] memory actions
    )
        public
        payable
    {
        BatchActions.batch(state, actions, msg.value);
    }

     
     
     

    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        Types.Signature calldata signature
    )
        external
        pure
        returns (bool isValid)
    {
        isValid = Signature.isValidSignature(hash, signerAddress, signature);
    }

     
     
     

    function getAllMarketsCount()
        external
        view
        returns (uint256 count)
    {
        count = state.marketsCount;
    }

    function getAsset(address assetAddress)
        external
        view returns (Types.Asset memory asset)
    {
        Requires.requireAssetExist(state, assetAddress);
        asset = state.assets[assetAddress];
    }

    function getAssetOraclePrice(address assetAddress)
        external
        view
        returns (uint256 price)
    {
        Requires.requireAssetExist(state, assetAddress);
        price = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[assetAddress].priceOracle),
            assetAddress
        );
    }

    function getMarket(uint16 marketID)
        external
        view
        returns (Types.Market memory market)
    {
        Requires.requireMarketIDExist(state, marketID);
        market = state.markets[marketID];
    }

     
     
     

    function isAccountLiquidatable(
        address user,
        uint16 marketID
    )
        external
        view
        returns (bool isLiquidatable)
    {
        Requires.requireMarketIDExist(state, marketID);
        isLiquidatable = CollateralAccounts.getDetails(state, user, marketID).liquidatable;
    }

    function getAccountDetails(
        address user,
        uint16 marketID
    )
        external
        view
        returns (Types.CollateralAccountDetails memory details)
    {
        Requires.requireMarketIDExist(state, marketID);
        details = CollateralAccounts.getDetails(state, user, marketID);
    }

    function getAuctionsCount()
        external
        view
        returns (uint32 count)
    {
        count = state.auction.auctionsCount;
    }

    function getCurrentAuctions()
        external
        view
        returns (uint32[] memory)
    {
        return state.auction.currentAuctions;
    }

    function getAuctionDetails(uint32 auctionID)
        external
        view
        returns (Types.AuctionDetails memory details)
    {
        Requires.requireAuctionExist(state, auctionID);
        details = Auctions.getAuctionDetails(state, auctionID);
    }

    function fillAuctionWithAmount(
        uint32 auctionID,
        uint256 amount
    )
        external
    {
        Requires.requireAuctionExist(state, auctionID);
        Requires.requireAuctionNotFinished(state, auctionID);
        Auctions.fillAuctionWithAmount(state, auctionID, amount);
    }

    function liquidateAccount(
        address user,
        uint16 marketID
    )
        external
        returns (bool hasAuction, uint32 auctionID)
    {
        Requires.requireMarketIDExist(state, marketID);
        (hasAuction, auctionID) = Auctions.liquidate(state, user, marketID);
    }

     
     
     

    function getPoolCashableAmount(address asset)
        external
        view
        returns (uint256 cashableAmount)
    {
        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            cashableAmount = address(this).balance - uint256(state.cash[asset]);
        } else {
            cashableAmount = IStandardToken(asset).balanceOf(address(this)) - uint256(state.cash[asset]);
        }
    }

    function getIndex(address asset)
        external
        view
        returns (uint256 supplyIndex, uint256 borrowIndex)
    {
        return LendingPool.getCurrentIndex(state, asset);
    }

    function getTotalBorrow(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getTotalBorrow(state, asset);
    }

    function getTotalSupply(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getTotalSupply(state, asset);
    }

    function getAmountBorrowed(
        address asset,
        address user,
        uint16 marketID
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        amount = LendingPool.getAmountBorrowed(state, asset, user, marketID);
    }

    function getAmountSupplied(
        address asset,
        address user
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = LendingPool.getAmountSupplied(state, asset, user);
    }

    function getInterestRates(
        address asset,
        uint256 extraBorrowAmount
    )
        external
        view
        returns (uint256 borrowInterestRate, uint256 supplyInterestRate)
    {
        Requires.requireAssetExist(state, asset);
        (borrowInterestRate, supplyInterestRate) = LendingPool.getInterestRates(state, asset, extraBorrowAmount);
    }

    function getInsuranceBalance(address asset)
        external
        view
        returns (uint256 amount)
    {
        Requires.requireAssetExist(state, asset);
        amount = state.pool.insuranceBalances[asset];
    }

     
     
     

    function approveDelegate(address delegate)
        external
    {
        Relayer.approveDelegate(state, delegate);
    }

    function revokeDelegate(address delegate)
        external
    {
        Relayer.revokeDelegate(state, delegate);
    }

    function joinIncentiveSystem()
        external
    {
        Relayer.joinIncentiveSystem(state);
    }

    function exitIncentiveSystem()
        external
    {
        Relayer.exitIncentiveSystem(state);
    }

    function canMatchOrdersFrom(address relayer)
        external
        view
        returns (bool canMatch)
    {
        canMatch = Relayer.canMatchOrdersFrom(state, relayer);
    }

    function isParticipant(address relayer)
        external
        view
        returns (bool result)
    {
        result = Relayer.isParticipant(state, relayer);
    }

     
     
     

    function balanceOf(
        address asset,
        address user
    )
        external
        view
        returns (uint256 balance)
    {
        balance = Transfer.balanceOf(state,  BalancePath.getCommonPath(user), asset);
    }

    function marketBalanceOf(
        uint16 marketID,
        address asset,
        address user
    )
        external
        view
        returns (uint256 balance)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        balance = Transfer.balanceOf(state,  BalancePath.getMarketPath(user, marketID), asset);
    }

    function getMarketTransferableAmount(
        uint16 marketID,
        address asset,
        address user
    )
        external
        view
        returns (uint256 amount)
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        amount = CollateralAccounts.getTransferableAmount(state, marketID, user, asset);
    }

     
    function ()
        external
        payable
    {
         
        Transfer.deposit(
            state,
            Consts.ETHEREUM_TOKEN_ADDRESS(),
            msg.value
        );
    }

     
     
     

    function cancelOrder(
        Types.Order calldata order
    )
        external
    {
        Exchange.cancelOrder(state, order);
    }

    function isOrderCancelled(
        bytes32 orderHash
    )
        external
        view
        returns(bool isCancelled)
    {
        isCancelled = state.exchange.cancelled[orderHash];
    }

    function matchOrders(
        Types.MatchParams memory params
    )
        public
    {
        Exchange.matchOrders(state, params);
    }

    function getDiscountedRate(
        address user
    )
        external
        view
        returns (uint256 rate)
    {
        rate = Discount.getDiscountedRate(state, user);
    }

    function getHydroTokenAddress()
        external
        view
        returns (address hydroTokenAddress)
    {
        hydroTokenAddress = state.exchange.hotTokenAddress;
    }

    function getOrderFilledAmount(
        bytes32 orderHash
    )
        external
        view
        returns (uint256 amount)
    {
        amount = state.exchange.filled[orderHash];
    }
}

library OperationsComponent {

    function createMarket(
        Store.State storage state,
        Types.Market memory market
    )
        public
    {
        Requires.requireMarketAssetsValid(state, market);
        Requires.requireMarketNotExist(state, market);
        Requires.requireDecimalLessOrEquanThanOne(market.auctionRatioStart);
        Requires.requireDecimalLessOrEquanThanOne(market.auctionRatioPerBlock);
        Requires.requireDecimalGreaterThanOne(market.liquidateRate);
        Requires.requireDecimalGreaterThanOne(market.withdrawRate);
        require(market.withdrawRate > market.liquidateRate, "WITHDARW_RATE_LESS_OR_EQUAL_THAN_LIQUIDATE_RATE");

        state.markets[state.marketsCount++] = market;
        Events.logCreateMarket(market);
    }

    function updateMarket(
        Store.State storage state,
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        external
    {
        Requires.requireMarketIDExist(state, marketID);
        Requires.requireDecimalLessOrEquanThanOne(newAuctionRatioStart);
        Requires.requireDecimalLessOrEquanThanOne(newAuctionRatioPerBlock);
        Requires.requireDecimalGreaterThanOne(newLiquidateRate);
        Requires.requireDecimalGreaterThanOne(newWithdrawRate);
        require(newWithdrawRate > newLiquidateRate, "WITHDARW_RATE_LESS_OR_EQUAL_THAN_LIQUIDATE_RATE");

        state.markets[marketID].auctionRatioStart = newAuctionRatioStart;
        state.markets[marketID].auctionRatioPerBlock = newAuctionRatioPerBlock;
        state.markets[marketID].liquidateRate = newLiquidateRate;
        state.markets[marketID].withdrawRate = newWithdrawRate;

        Events.logUpdateMarket(
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    function setMarketBorrowUsability(
        Store.State storage state,
        uint16 marketID,
        bool   usability
    )
        external
    {
        Requires.requireMarketIDExist(state, marketID);
        state.markets[marketID].borrowEnable = usability;
        if (usability) {
            Events.logMarketBorrowDisable(
                marketID
            );
        } else {
            Events.logMarketBorrowEnable(
                marketID
            );
        }
    }

    function createAsset(
        Store.State storage state,
        address asset,
        address oracleAddress,
        address interestModelAddress,
        string calldata poolTokenName,
        string calldata poolTokenSymbol,
        uint8 poolTokenDecimals
    )
        external
    {
        Requires.requirePriceOracleAddressValid(oracleAddress);
        Requires.requireAssetNotExist(state, asset);

        LendingPool.initializeAssetLendingPool(state, asset);

        state.assets[asset].priceOracle = IPriceOracle(oracleAddress);
        state.assets[asset].interestModel = IInterestModel(interestModelAddress);
        state.assets[asset].lendingPoolToken = ILendingPoolToken(address(new LendingPoolToken(
            poolTokenName,
            poolTokenSymbol,
            poolTokenDecimals
        )));

        Events.logCreateAsset(
            asset,
            oracleAddress,
            address(state.assets[asset].lendingPoolToken),
            interestModelAddress
        );
    }

    function updateAsset(
        Store.State storage state,
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        external
    {
        Requires.requirePriceOracleAddressValid(oracleAddress);
        Requires.requireAssetExist(state, asset);

        state.assets[asset].priceOracle = IPriceOracle(oracleAddress);
        state.assets[asset].interestModel = IInterestModel(interestModelAddress);

        Events.logUpdateAsset(
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

     
    function updateDiscountConfig(
        Store.State storage state,
        bytes32 newConfig
    )
        external
    {
        state.exchange.discountConfig = newConfig;
        Events.logUpdateDiscountConfig(newConfig);
    }

    function updateAuctionInitiatorRewardRatio(
        Store.State storage state,
        uint256 newInitiatorRewardRatio
    )
        external
    {
        Requires.requireDecimalLessOrEquanThanOne(newInitiatorRewardRatio);

        state.auction.initiatorRewardRatio = newInitiatorRewardRatio;
        Events.logUpdateAuctionInitiatorRewardRatio(newInitiatorRewardRatio);
    }

    function updateInsuranceRatio(
        Store.State storage state,
        uint256 newInsuranceRatio
    )
        external
    {
        Requires.requireDecimalLessOrEquanThanOne(newInsuranceRatio);

        state.pool.insuranceRatio = newInsuranceRatio;
        Events.logUpdateInsuranceRatio(newInsuranceRatio);
    }
}

library Discount {
    using SafeMath for uint256;

     
    function getDiscountedRate(
        Store.State storage state,
        address user
    )
        internal
        view
        returns (uint256 result)
    {
        uint256 hotBalance = AssemblyCall.getHotBalance(
            state.exchange.hotTokenAddress,
            user
        );

        if (hotBalance == 0) {
            return Consts.DISCOUNT_RATE_BASE();
        }

        bytes32 config = state.exchange.discountConfig;
        uint256 count = uint256(uint8(byte(config)));
        uint256 bar;

         
        hotBalance = hotBalance.div(10**18);

        for (uint256 i = 0; i < count; i++) {
            bar = uint256(uint32(bytes4(config << (2 + i * 5) * 8)));

            if (hotBalance < bar) {
                result = uint256(uint8(byte(config << (2 + i * 5 + 4) * 8)));
                break;
            }
        }

         
        if (result == 0) {
            result = uint256(uint8(config[1]));
        }

         
        require(result <= Consts.DISCOUNT_RATE_BASE(), "DISCOUNT_ERROR");
    }
}

library Exchange {
    using SafeMath for uint256;
    using Order for Types.Order;
    using OrderParam for Types.OrderParam;

    uint256 private constant EXCHANGE_FEE_RATE_BASE = 100000;
    uint256 private constant SUPPORTED_ORDER_VERSION = 2;

     
    struct OrderInfo {
        bytes32 orderHash;
        uint256 filledAmount;
        Types.BalancePath balancePath;
    }

     
    function matchOrders(
        Store.State storage state,
        Types.MatchParams memory params
    )
        internal
    {
        require(Relayer.canMatchOrdersFrom(state, params.orderAddressSet.relayer), "INVALID_SENDER");
        require(!params.takerOrderParam.isMakerOnly(), "MAKER_ONLY_ORDER_CANNOT_BE_TAKER");

        bool isParticipantRelayer = Relayer.isParticipant(state, params.orderAddressSet.relayer);
        uint256 takerFeeRate = getTakerFeeRate(state, params.takerOrderParam, isParticipantRelayer);
        OrderInfo memory takerOrderInfo = getOrderInfo(state, params.takerOrderParam, params.orderAddressSet);

         
        Types.MatchResult[] memory results = new Types.MatchResult[](params.makerOrderParams.length);

        for (uint256 i = 0; i < params.makerOrderParams.length; i++) {
            require(!params.makerOrderParams[i].isMarketOrder(), "MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER");
            require(params.takerOrderParam.isSell() != params.makerOrderParams[i].isSell(), "INVALID_SIDE");
            validatePrice(params.takerOrderParam, params.makerOrderParams[i]);

            OrderInfo memory makerOrderInfo = getOrderInfo(state, params.makerOrderParams[i], params.orderAddressSet);

            results[i] = getMatchResult(
                state,
                params.takerOrderParam,
                takerOrderInfo,
                params.makerOrderParams[i],
                makerOrderInfo,
                params.baseAssetFilledAmounts[i],
                takerFeeRate,
                isParticipantRelayer
            );

             
            state.exchange.filled[makerOrderInfo.orderHash] = makerOrderInfo.filledAmount;
        }

         
        state.exchange.filled[takerOrderInfo.orderHash] = takerOrderInfo.filledAmount;

        settleResults(state, results, params.takerOrderParam, params.orderAddressSet);
    }

     
    function cancelOrder(
        Store.State storage state,
        Types.Order memory order
    )
        internal
    {
        require(order.trader == msg.sender, "INVALID_TRADER");

        bytes32 orderHash = order.getHash();
        state.exchange.cancelled[orderHash] = true;

        Events.logOrderCancel(orderHash);
    }

     
    function getOrderInfo(
        Store.State storage state,
        Types.OrderParam memory orderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
        view
        returns (OrderInfo memory orderInfo)
    {
        require(orderParam.getOrderVersion() == SUPPORTED_ORDER_VERSION, "ORDER_VERSION_NOT_SUPPORTED");

        Types.Order memory order = getOrderFromOrderParam(orderParam, orderAddressSet);
        orderInfo.orderHash = order.getHash();
        orderInfo.filledAmount = state.exchange.filled[orderInfo.orderHash];
        uint8 status = uint8(Types.OrderStatus.FILLABLE);

        if (!orderParam.isMarketBuy() && orderInfo.filledAmount >= order.baseAssetAmount) {
            status = uint8(Types.OrderStatus.FULLY_FILLED);
        } else if (orderParam.isMarketBuy() && orderInfo.filledAmount >= order.quoteAssetAmount) {
            status = uint8(Types.OrderStatus.FULLY_FILLED);
        } else if (block.timestamp >= orderParam.getExpiredAtFromOrderData()) {
            status = uint8(Types.OrderStatus.EXPIRED);
        } else if (state.exchange.cancelled[orderInfo.orderHash]) {
            status = uint8(Types.OrderStatus.CANCELLED);
        }

        require(
            status == uint8(Types.OrderStatus.FILLABLE),
            "ORDER_IS_NOT_FILLABLE"
        );

        require(
            Signature.isValidSignature(orderInfo.orderHash, orderParam.trader, orderParam.signature),
            "INVALID_ORDER_SIGNATURE"
        );

        orderInfo.balancePath = orderParam.getBalancePathFromOrderData();
        Requires.requirePathNormalStatus(state, orderInfo.balancePath);

        return orderInfo;
    }

     
    function getOrderFromOrderParam(
        Types.OrderParam memory orderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
        pure
        returns (Types.Order memory order)
    {
        order.trader = orderParam.trader;
        order.baseAssetAmount = orderParam.baseAssetAmount;
        order.quoteAssetAmount = orderParam.quoteAssetAmount;
        order.gasTokenAmount = orderParam.gasTokenAmount;
        order.data = orderParam.data;
        order.baseAsset = orderAddressSet.baseAsset;
        order.quoteAsset = orderAddressSet.quoteAsset;
        order.relayer = orderAddressSet.relayer;
    }

     
    function validatePrice(
        Types.OrderParam memory takerOrderParam,
        Types.OrderParam memory makerOrderParam
    )
        private
        pure
    {
        uint256 left = takerOrderParam.quoteAssetAmount.mul(makerOrderParam.baseAssetAmount);
        uint256 right = takerOrderParam.baseAssetAmount.mul(makerOrderParam.quoteAssetAmount);
        require(takerOrderParam.isSell() ? left <= right : left >= right, "INVALID_MATCH");
    }

     
    function getMatchResult(
        Store.State storage state,
        Types.OrderParam memory takerOrderParam,
        OrderInfo memory takerOrderInfo,
        Types.OrderParam memory makerOrderParam,
        OrderInfo memory makerOrderInfo,
        uint256 baseAssetFilledAmount,
        uint256 takerFeeRate,
        bool isParticipantRelayer
    )
        private
        view
        returns (Types.MatchResult memory result)
    {
        result.baseAssetFilledAmount = baseAssetFilledAmount;
        result.quoteAssetFilledAmount = convertBaseToQuote(makerOrderParam, baseAssetFilledAmount);

        result.takerBalancePath = takerOrderInfo.balancePath;
        result.makerBalancePath = makerOrderInfo.balancePath;

         
        if (takerOrderInfo.filledAmount == 0) {
            result.takerGasFee = takerOrderParam.gasTokenAmount;
        }

        if (makerOrderInfo.filledAmount == 0) {
            result.makerGasFee = makerOrderParam.gasTokenAmount;
        }

        if(!takerOrderParam.isMarketBuy()) {
            takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(result.baseAssetFilledAmount);
            require(takerOrderInfo.filledAmount <= takerOrderParam.baseAssetAmount, "TAKER_ORDER_OVER_MATCH");
        } else {
            takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(result.quoteAssetFilledAmount);
            require(takerOrderInfo.filledAmount <= takerOrderParam.quoteAssetAmount, "TAKER_ORDER_OVER_MATCH");
        }

        makerOrderInfo.filledAmount = makerOrderInfo.filledAmount.add(result.baseAssetFilledAmount);
        require(makerOrderInfo.filledAmount <= makerOrderParam.baseAssetAmount, "MAKER_ORDER_OVER_MATCH");

        result.maker = makerOrderParam.trader;
        result.taker = takerOrderParam.trader;

        if(takerOrderParam.isSell()) {
            result.buyer = result.maker;
        } else {
            result.buyer = result.taker;
        }

        uint256 rebateRate = makerOrderParam.getMakerRebateRateFromOrderData();

        if (rebateRate > 0) {
             
            result.makerFee = 0;

             
            result.makerRebate = result.quoteAssetFilledAmount.mul(takerFeeRate).mul(rebateRate).div(
                EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE()).mul(Consts.REBATE_RATE_BASE())
            );
        } else {
            uint256 makerRawFeeRate = makerOrderParam.getAsMakerFeeRateFromOrderData();
            result.makerRebate = 0;

             
            uint256 makerFeeRate = getFinalFeeRate(
                state,
                makerOrderParam.trader,
                makerRawFeeRate,
                isParticipantRelayer
            );

            result.makerFee = result.quoteAssetFilledAmount.mul(makerFeeRate).div(
                EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE())
            );
        }

        result.takerFee = result.quoteAssetFilledAmount.mul(takerFeeRate).div(
            EXCHANGE_FEE_RATE_BASE.mul(Consts.DISCOUNT_RATE_BASE())
        );
    }

     
    function getTakerFeeRate(
        Store.State storage state,
        Types.OrderParam memory orderParam,
        bool isParticipantRelayer
    )
        private
        view
        returns(uint256)
    {
        uint256 rawRate = orderParam.getAsTakerFeeRateFromOrderData();
        return getFinalFeeRate(state, orderParam.trader, rawRate, isParticipantRelayer);
    }

     
    function getFinalFeeRate(
        Store.State storage state,
        address trader,
        uint256 rate,
        bool isParticipantRelayer
    )
        private
        view
        returns(uint256)
    {
        if (isParticipantRelayer) {
            return rate.mul(Discount.getDiscountedRate(state, trader));
        } else {
            return rate.mul(Consts.DISCOUNT_RATE_BASE());
        }
    }

     
    function convertBaseToQuote(
        Types.OrderParam memory orderParam,
        uint256 amount
    )
        private
        pure
        returns (uint256)
    {
        return SafeMath.getPartialAmountFloor(
            orderParam.quoteAssetAmount,
            orderParam.baseAssetAmount,
            amount
        );
    }

     
    function settleResults(
        Store.State storage state,
        Types.MatchResult[] memory results,
        Types.OrderParam memory takerOrderParam,
        Types.OrderAddressSet memory orderAddressSet
    )
        private
    {
        bool isTakerSell = takerOrderParam.isSell();

        uint256 totalFee = 0;

        Types.BalancePath memory relayerBalancePath = Types.BalancePath({
            user: orderAddressSet.relayer,
            marketID: 0,
            category: Types.BalanceCategory.Common
        });

        for (uint256 i = 0; i < results.length; i++) {
            Transfer.transfer(
                state,
                orderAddressSet.baseAsset,
                isTakerSell ? results[i].takerBalancePath : results[i].makerBalancePath,
                isTakerSell ? results[i].makerBalancePath : results[i].takerBalancePath,
                results[i].baseAssetFilledAmount
            );

            uint256 transferredQuoteAmount;

            if(isTakerSell) {
                transferredQuoteAmount = results[i].quoteAssetFilledAmount.
                    add(results[i].makerFee).
                    add(results[i].makerGasFee).
                    sub(results[i].makerRebate);
            } else {
                transferredQuoteAmount = results[i].quoteAssetFilledAmount.
                    sub(results[i].makerFee).
                    sub(results[i].makerGasFee).
                    add(results[i].makerRebate);
            }

            Transfer.transfer(
                state,
                orderAddressSet.quoteAsset,
                isTakerSell ? results[i].makerBalancePath : results[i].takerBalancePath,
                isTakerSell ? results[i].takerBalancePath : results[i].makerBalancePath,
                transferredQuoteAmount
            );

            Requires.requireCollateralAccountNotLiquidatable(state, results[i].makerBalancePath);

            totalFee = totalFee.add(results[i].takerFee).add(results[i].makerFee);
            totalFee = totalFee.add(results[i].makerGasFee).add(results[i].takerGasFee);
            totalFee = totalFee.sub(results[i].makerRebate);

            Events.logMatch(results[i], orderAddressSet);
        }

        Transfer.transfer(
            state,
            orderAddressSet.quoteAsset,
            results[0].takerBalancePath,
            relayerBalancePath,
            totalFee
        );

        Requires.requireCollateralAccountNotLiquidatable(state, results[0].takerBalancePath);
    }
}

library Relayer {
     
    function approveDelegate(
        Store.State storage state,
        address delegate
    )
        internal
    {
        state.relayer.relayerDelegates[msg.sender][delegate] = true;
        Events.logRelayerApproveDelegate(msg.sender, delegate);
    }

     
    function revokeDelegate(
        Store.State storage state,
        address delegate
    )
        internal
    {
        state.relayer.relayerDelegates[msg.sender][delegate] = false;
        Events.logRelayerRevokeDelegate(msg.sender, delegate);
    }

     
    function canMatchOrdersFrom(
        Store.State storage state,
        address relayer
    )
        internal
        view
        returns(bool)
    {
        return msg.sender == relayer || state.relayer.relayerDelegates[relayer][msg.sender] == true;
    }

     
    function joinIncentiveSystem(
        Store.State storage state
    )
        internal
    {
        delete state.relayer.hasExited[msg.sender];
        Events.logRelayerJoin(msg.sender);
    }

     
    function exitIncentiveSystem(
        Store.State storage state
    )
        internal
    {
        state.relayer.hasExited[msg.sender] = true;
        Events.logRelayerExit(msg.sender);
    }

     
    function isParticipant(
        Store.State storage state,
        address relayer
    )
        internal
        view
        returns(bool)
    {
        return !state.relayer.hasExited[relayer];
    }
}

library Auctions {
    using SafeMath for uint256;
    using SafeMath for int256;
    using Auction for Types.Auction;

     
    function liquidate(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        external
        returns (bool, uint32)
    {
         
        Types.CollateralAccountDetails memory details = CollateralAccounts.getDetails(
            state,
            user,
            marketID
        );

        require(details.liquidatable, "ACCOUNT_NOT_LIQUIDABLE");

        Types.Market storage market = state.markets[marketID];
        Types.CollateralAccount storage account = state.accounts[user][marketID];

        LendingPool.repay(
            state,
            user,
            marketID,
            market.baseAsset,
            account.balances[market.baseAsset]
        );

        LendingPool.repay(
            state,
            user,
            marketID,
            market.quoteAsset,
            account.balances[market.quoteAsset]
        );

        address collateralAsset;
        address debtAsset;

        uint256 leftBaseAssetDebt = LendingPool.getAmountBorrowed(
            state,
            market.baseAsset,
            user,
            marketID
        );

        uint256 leftQuoteAssetDebt = LendingPool.getAmountBorrowed(
            state,
            market.quoteAsset,
            user,
            marketID
        );

        bool hasAution = !(leftBaseAssetDebt == 0 && leftQuoteAssetDebt == 0);

        Events.logLiquidate(
            user,
            marketID,
            hasAution
        );

        if (!hasAution) {
             
            return (false, 0);
        }

        account.status = Types.CollateralAccountStatus.Liquid;

        if(account.balances[market.baseAsset] > 0) {
             
            collateralAsset = market.baseAsset;
            debtAsset = market.quoteAsset;
        } else {
             
            collateralAsset = market.quoteAsset;
            debtAsset = market.baseAsset;
        }

        uint32 newAuctionID = create(
            state,
            marketID,
            user,
            msg.sender,
            debtAsset,
            collateralAsset
        );

        return (true, newAuctionID);
    }

    function fillHealthyAuction(
        Store.State storage state,
        Types.Auction storage auction,
        uint256 ratio,
        uint256 repayAmount
    )
        private
        returns (uint256, uint256)  
    {
        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

         
        uint256 leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = repayAmount;

         
        uint256 actualRepayAmount = LendingPool.repay(
            state,
            auction.borrower,
            auction.marketID,
            auction.debtAsset,
            repayAmount
        );

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = 0;

         
        state.balances[msg.sender][auction.debtAsset] = SafeMath.sub(
            state.balances[msg.sender][auction.debtAsset],
            actualRepayAmount
        );

        uint256 collateralToProcess = leftCollateralAmount.mul(actualRepayAmount).div(leftDebtAmount);
        uint256 collateralForBidder = Decimal.mulFloor(collateralToProcess, ratio);

        uint256 collateralForInitiator = Decimal.mulFloor(collateralToProcess.sub(collateralForBidder), state.auction.initiatorRewardRatio);
        uint256 collateralForBorrower = collateralToProcess.sub(collateralForBidder).sub(collateralForInitiator);

         
        state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset] = SafeMath.sub(
            state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset],
            collateralToProcess
        );

         
        state.balances[msg.sender][auction.collateralAsset] = SafeMath.add(
            state.balances[msg.sender][auction.collateralAsset],
            collateralForBidder
        );

         
        state.balances[auction.initiator][auction.collateralAsset] = SafeMath.add(
            state.balances[auction.initiator][auction.collateralAsset],
            collateralForInitiator
        );

         
        state.balances[auction.borrower][auction.collateralAsset] = SafeMath.add(
            state.balances[auction.borrower][auction.collateralAsset],
            collateralForBorrower
        );

         
        Transfer.withdraw(
            state,
            auction.borrower,
            auction.collateralAsset,
            collateralForBorrower
        );

        return (actualRepayAmount, collateralForBidder);
    }

     
    function fillBadAuction(
        Store.State storage state,
        Types.Auction storage auction,
        uint256 ratio,
        uint256 bidderRepayAmount
    )
        private
        returns (uint256, uint256, uint256)  
    {

        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

        uint256 leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

        uint256 repayAmount = Decimal.mulFloor(bidderRepayAmount, ratio);

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = repayAmount;

        uint256 actualRepayAmount = LendingPool.repay(
            state,
            auction.borrower,
            auction.marketID,
            auction.debtAsset,
            repayAmount
        );

        state.accounts[auction.borrower][auction.marketID].balances[auction.debtAsset] = 0;  

        uint256 actualBidderRepay = bidderRepayAmount;

        if (actualRepayAmount < repayAmount) {
            actualBidderRepay = Decimal.divCeil(actualRepayAmount, ratio);
        }

         
        LendingPool.claimInsurance(state, auction.debtAsset, actualRepayAmount.sub(actualBidderRepay));

        state.balances[msg.sender][auction.debtAsset] = SafeMath.sub(
            state.balances[msg.sender][auction.debtAsset],
            actualBidderRepay
        );

         
        uint256 collateralForBidder = leftCollateralAmount.mul(actualRepayAmount).div(leftDebtAmount);

        state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset] = SafeMath.sub(
            state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset],
            collateralForBidder
        );

         
        state.balances[msg.sender][auction.collateralAsset] = SafeMath.add(
            state.balances[msg.sender][auction.collateralAsset],
            collateralForBidder
        );

        return (actualRepayAmount, actualBidderRepay, collateralForBidder);
    }

     
    function fillAuctionWithAmount(
        Store.State storage state,
        uint32 auctionID,
        uint256 repayAmount
    )
        external
    {
        Types.Auction storage auction = state.auction.auctions[auctionID];
        uint256 ratio = auction.ratio(state);

        uint256 actualRepayAmount;
        uint256 actualBidderRepayAmount;
        uint256 collateralForBidder;

        if (ratio <= Decimal.one()) {
            (actualRepayAmount, collateralForBidder) = fillHealthyAuction(state, auction, ratio, repayAmount);
            actualBidderRepayAmount = actualRepayAmount;
        } else {
            (actualRepayAmount, actualBidderRepayAmount, collateralForBidder) = fillBadAuction(state, auction, ratio, repayAmount);
        }

         
        uint256 leftDebtAmount = LendingPool.getAmountBorrowed(
            state,
            auction.debtAsset,
            auction.borrower,
            auction.marketID
        );

        Events.logFillAuction(auction.id, msg.sender, actualRepayAmount, actualBidderRepayAmount, collateralForBidder, leftDebtAmount);

        if (leftDebtAmount == 0) {
            endAuction(state, auction);
        }
    }

     
    function endAuction(
        Store.State storage state,
        Types.Auction storage auction
    )
        private
    {
        auction.status = Types.AuctionStatus.Finished;

        state.accounts[auction.borrower][auction.marketID].status = Types.CollateralAccountStatus.Normal;

        for (uint i = 0; i < state.auction.currentAuctions.length; i++) {
            if (state.auction.currentAuctions[i] == auction.id) {
                state.auction.currentAuctions[i] = state.auction.currentAuctions[state.auction.currentAuctions.length-1];
                state.auction.currentAuctions.length--;
                return;
            }
        }
    }

     
    function create(
        Store.State storage state,
        uint16 marketID,
        address borrower,
        address initiator,
        address debtAsset,
        address collateralAsset
    )
        private
        returns (uint32)
    {
        uint32 id = state.auction.auctionsCount++;

        Types.Auction memory auction = Types.Auction({
            id: id,
            status: Types.AuctionStatus.InProgress,
            startBlockNumber: uint32(block.number),
            marketID: marketID,
            borrower: borrower,
            initiator: initiator,
            debtAsset: debtAsset,
            collateralAsset: collateralAsset
        });

        state.auction.auctions[id] = auction;
        state.auction.currentAuctions.push(id);

        Events.logAuctionCreate(id);

        return id;
    }

     
    function getAuctionDetails(
        Store.State storage state,
        uint32 auctionID
    )
        external
        view
        returns (Types.AuctionDetails memory details)
    {
        Types.Auction memory auction = state.auction.auctions[auctionID];

        details.borrower = auction.borrower;
        details.marketID = auction.marketID;
        details.debtAsset = auction.debtAsset;
        details.collateralAsset = auction.collateralAsset;

        if (state.auction.auctions[auctionID].status == Types.AuctionStatus.Finished){
            details.finished = true;
        } else {
            details.finished = false;
            details.leftDebtAmount = LendingPool.getAmountBorrowed(
                state,
                auction.debtAsset,
                auction.borrower,
                auction.marketID
            );
            details.leftCollateralAmount = state.accounts[auction.borrower][auction.marketID].balances[auction.collateralAsset];

            details.ratio = auction.ratio(state);

            if (details.leftCollateralAmount != 0 && details.ratio != 0) {
                 
                details.price = Decimal.divFloor(Decimal.divFloor(details.leftDebtAmount, details.leftCollateralAmount), details.ratio);
            }
        }
    }
}

library BatchActions {
    using SafeMath for uint256;
     
    enum ActionType {
        Deposit,    
        Withdraw,   
        Transfer,   
        Borrow,     
        Repay,      
        Supply,     
        Unsupply    
    }

     
    struct Action {
        ActionType actionType;   
        bytes encodedParams;     
    }

     
    function batch(
        Store.State storage state,
        Action[] memory actions,
        uint256 msgValue
    )
        public
    {
        uint256 totalDepositedEtherAmount = 0;

        for (uint256 i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            ActionType actionType = action.actionType;

            if (actionType == ActionType.Deposit) {
                uint256 depositedEtherAmount = deposit(state, action);
                totalDepositedEtherAmount = totalDepositedEtherAmount.add(depositedEtherAmount);
            } else if (actionType == ActionType.Withdraw) {
                withdraw(state, action);
            } else if (actionType == ActionType.Transfer) {
                transfer(state, action);
            } else if (actionType == ActionType.Borrow) {
                borrow(state, action);
            } else if (actionType == ActionType.Repay) {
                repay(state, action);
            } else if (actionType == ActionType.Supply) {
                supply(state, action);
            } else if (actionType == ActionType.Unsupply) {
                unsupply(state, action);
            }
        }

        require(totalDepositedEtherAmount == msgValue, "MSG_VALUE_AND_AMOUNT_MISMATCH");
    }

    function deposit(
        Store.State storage state,
        Action memory action
    )
        private
        returns (uint256)
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        return Transfer.deposit(
            state,
            asset,
            amount
        );
    }

    function withdraw(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Transfer.withdraw(
            state,
            msg.sender,
            asset,
            amount
        );
    }

    function transfer(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            Types.BalancePath memory fromBalancePath,
            Types.BalancePath memory toBalancePath,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                Types.BalancePath,
                Types.BalancePath,
                uint256
            )
        );

        require(fromBalancePath.user == msg.sender, "CAN_NOT_MOVE_OTHER_USER_ASSET");
        require(toBalancePath.user == msg.sender, "CAN_NOT_MOVE_ASSET_TO_OTHER_USER");

        Requires.requirePathNormalStatus(state, fromBalancePath);
        Requires.requirePathNormalStatus(state, toBalancePath);

         
         
         

        if (fromBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            require(
                CollateralAccounts.getTransferableAmount(state, fromBalancePath.marketID, fromBalancePath.user, asset) >= amount,
                "COLLATERAL_ACCOUNT_TRANSFERABLE_AMOUNT_NOT_ENOUGH"
            );
        }

        Transfer.transfer(
            state,
            asset,
            fromBalancePath,
            toBalancePath,
            amount
        );

        if (toBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            Events.logIncreaseCollateral(msg.sender, toBalancePath.marketID, asset, amount);
        }
        if (fromBalancePath.category == Types.BalanceCategory.CollateralAccount) {
            Events.logDecreaseCollateral(msg.sender, fromBalancePath.marketID, asset, amount);
        }
    }

    function borrow(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            uint16 marketID,
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                uint16,
                address,
                uint256
            )
        );

        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketBorrowEnabled(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);
        Requires.requireAccountNormal(state, marketID, msg.sender);
        LendingPool.borrow(
            state,
            msg.sender,
            marketID,
            asset,
            amount
        );
    }

    function repay(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            uint16 marketID,
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                uint16,
                address,
                uint256
            )
        );

        Requires.requireMarketIDExist(state, marketID);
        Requires.requireMarketIDAndAssetMatch(state, marketID, asset);

        LendingPool.repay(
            state,
            msg.sender,
            marketID,
            asset,
            amount
        );
    }

    function supply(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Requires.requireAssetExist(state, asset);
        LendingPool.supply(
            state,
            asset,
            amount,
            msg.sender
        );
    }

    function unsupply(
        Store.State storage state,
        Action memory action
    )
        private
    {
        (
            address asset,
            uint256 amount
        ) = abi.decode(
            action.encodedParams,
            (
                address,
                uint256
            )
        );

        Requires.requireAssetExist(state, asset);
        LendingPool.unsupply(
            state,
            asset,
            amount,
            msg.sender
        );
    }
}

library CollateralAccounts {
    using SafeMath for uint256;

    function getDetails(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        internal
        view
        returns (Types.CollateralAccountDetails memory details)
    {
        Types.CollateralAccount storage account = state.accounts[user][marketID];
        Types.Market storage market = state.markets[marketID];

        details.status = account.status;

        address baseAsset = market.baseAsset;
        address quoteAsset = market.quoteAsset;

        uint256 baseUSDPrice = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[baseAsset].priceOracle),
            baseAsset
        );
        uint256 quoteUSDPrice = AssemblyCall.getAssetPriceFromPriceOracle(
            address(state.assets[quoteAsset].priceOracle),
            quoteAsset
        );

        uint256 baseBorrowOf = LendingPool.getAmountBorrowed(state, baseAsset, user, marketID);
        uint256 quoteBorrowOf = LendingPool.getAmountBorrowed(state, quoteAsset, user, marketID);

        details.debtsTotalUSDValue = SafeMath.add(
            baseBorrowOf.mul(baseUSDPrice),
            quoteBorrowOf.mul(quoteUSDPrice)
        ) / Decimal.one();

        details.balancesTotalUSDValue = SafeMath.add(
            account.balances[baseAsset].mul(baseUSDPrice),
            account.balances[quoteAsset].mul(quoteUSDPrice)
        ) / Decimal.one();

        if (details.status == Types.CollateralAccountStatus.Normal) {
            details.liquidatable = details.balancesTotalUSDValue < Decimal.mulCeil(details.debtsTotalUSDValue, market.liquidateRate);
        } else {
            details.liquidatable = false;
        }
    }

     
    function getTransferableAmount(
        Store.State storage state,
        uint16 marketID,
        address user,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        Types.CollateralAccountDetails memory details = getDetails(state, user, marketID);

         
         

        uint256 assetBalance = state.accounts[user][marketID].balances[asset];

         
        uint256 transferableThresholdUSDValue = Decimal.mulCeil(
            details.debtsTotalUSDValue,
            state.markets[marketID].withdrawRate
        );

        if(transferableThresholdUSDValue > details.balancesTotalUSDValue) {
            return 0;
        } else {
            uint256 transferableUSD = details.balancesTotalUSDValue - transferableThresholdUSDValue;
            uint256 assetUSDPrice = state.assets[asset].priceOracle.getPrice(asset);
            uint256 transferableAmount = Decimal.divFloor(transferableUSD, assetUSDPrice);
            if (transferableAmount > assetBalance) {
                return assetBalance;
            } else {
                return transferableAmount;
            }
        }
    }
}

library LendingPool {
    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 private constant SECONDS_OF_YEAR = 31536000;

     
    function initializeAssetLendingPool(
        Store.State storage state,
        address asset
    )
        internal
    {
         
        state.pool.borrowIndex[asset] = Decimal.one();
        state.pool.supplyIndex[asset] = Decimal.one();

         
        state.pool.indexStartTime[asset] = block.timestamp;
    }

     
    function supply(
        Store.State storage state,
        address asset,
        uint256 amount,
        address user
    )
        internal
    {
         
        updateIndex(state, asset);

         
        Transfer.transferOut(state, asset, BalancePath.getCommonPath(user), amount);

         
         
        uint256 normalizedAmount = Decimal.divFloor(amount, state.pool.supplyIndex[asset]);

         
        state.assets[asset].lendingPoolToken.mint(user, normalizedAmount);

         
        updateInterestRate(state, asset);

        Events.logSupply(user, asset, amount);
    }

     
    function unsupply(
        Store.State storage state,
        address asset,
        uint256 amount,
        address user
    )
        internal
        returns (uint256)
    {
         
        updateIndex(state, asset);

         
         
        uint256 normalizedAmount = Decimal.divCeil(amount, state.pool.supplyIndex[asset]);

        uint256 unsupplyAmount = amount;

         
        if (getNormalizedSupplyOf(state, asset, user) <= normalizedAmount) {
            normalizedAmount = getNormalizedSupplyOf(state, asset, user);
            unsupplyAmount = Decimal.mulFloor(normalizedAmount, state.pool.supplyIndex[asset]);
        }

         
        Transfer.transferIn(state, asset, BalancePath.getCommonPath(user), unsupplyAmount);
        Requires.requireCashLessThanOrEqualContractBalance(state, asset);

         
        state.assets[asset].lendingPoolToken.burn(user, normalizedAmount);

         
        updateInterestRate(state, asset);

        Events.logUnsupply(user, asset, unsupplyAmount);

        return unsupplyAmount;
    }

     
    function borrow(
        Store.State storage state,
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
         
        updateIndex(state, asset);

         
        uint256 normalizedAmount = Decimal.divCeil(amount, state.pool.borrowIndex[asset]);

         
        Transfer.transferIn(state, asset, BalancePath.getMarketPath(user, marketID), amount);
        Requires.requireCashLessThanOrEqualContractBalance(state, asset);

         
        state.pool.normalizedBorrow[user][marketID][asset] = state.pool.normalizedBorrow[user][marketID][asset].add(normalizedAmount);

         
        state.pool.normalizedTotalBorrow[asset] = state.pool.normalizedTotalBorrow[asset].add(normalizedAmount);

         
        updateInterestRate(state, asset);

        Requires.requireCollateralAccountNotLiquidatable(state, user, marketID);

        Events.logBorrow(user, marketID, asset, amount);
    }

     
    function repay(
        Store.State storage state,
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
        returns (uint256)
    {
         
        updateIndex(state, asset);

         
         
        uint256 normalizedAmount = Decimal.divFloor(amount, state.pool.borrowIndex[asset]);

        uint256 repayAmount = amount;

         
        if (state.pool.normalizedBorrow[user][marketID][asset] <= normalizedAmount) {
            normalizedAmount = state.pool.normalizedBorrow[user][marketID][asset];
             
             
            repayAmount = Decimal.mulCeil(normalizedAmount, state.pool.borrowIndex[asset]);
        }

         
        Transfer.transferOut(state, asset, BalancePath.getMarketPath(user, marketID), repayAmount);

         
        state.pool.normalizedBorrow[user][marketID][asset] = state.pool.normalizedBorrow[user][marketID][asset].sub(normalizedAmount);

         
        state.pool.normalizedTotalBorrow[asset] = state.pool.normalizedTotalBorrow[asset].sub(normalizedAmount);

         
        updateInterestRate(state, asset);

        Events.logRepay(user, marketID, asset, repayAmount);

        return repayAmount;
    }

     
    function recognizeLoss(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
    {
        uint256 totalnormalizedSupply = getTotalNormalizedSupply(
            state,
            asset
        );

        uint256 actualSupply = getTotalSupply(
            state,
            asset
        ).sub(amount);

        state.pool.supplyIndex[asset] = Decimal.divFloor(
            actualSupply,
            totalnormalizedSupply
        );

        updateIndex(state, asset);

        Events.logLoss(asset, amount);
    }

     
    function claimInsurance(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
    {
        uint256 insuranceBalance = state.pool.insuranceBalances[asset];

        uint256 compensationAmount = SafeMath.min(amount, insuranceBalance);

        state.cash[asset] = state.cash[asset].add(amount);

         
        state.pool.insuranceBalances[asset] = SafeMath.sub(
            state.pool.insuranceBalances[asset],
            compensationAmount
        );

         
        if (compensationAmount < amount) {
            recognizeLoss(
                state,
                asset,
                amount.sub(compensationAmount)
            );
        }

        Events.logInsuranceCompensation(
            asset,
            compensationAmount
        );

    }

    function updateInterestRate(
        Store.State storage state,
        address asset
    )
        private
    {
        (uint256 borrowInterestRate, uint256 supplyInterestRate) = getInterestRates(state, asset, 0);
        state.pool.borrowAnnualInterestRate[asset] = borrowInterestRate;
        state.pool.supplyAnnualInterestRate[asset] = supplyInterestRate;
    }

     
    function getInterestRates(
        Store.State storage state,
        address asset,
        uint256 extraBorrowAmount
    )
        internal
        view
        returns (uint256 borrowInterestRate, uint256 supplyInterestRate)
    {
        (uint256 currentSupplyIndex, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);

        uint256 _supply = getTotalSupplyWithIndex(state, asset, currentSupplyIndex);

        if (_supply == 0) {
            return (0, 0);
        }

        uint256 _borrow = getTotalBorrowWithIndex(state, asset, currentBorrowIndex).add(extraBorrowAmount);

        uint256 borrowRatio = _borrow.mul(Decimal.one()).div(_supply);

        borrowInterestRate = AssemblyCall.getBorrowInterestRate(
            address(state.assets[asset].interestModel),
            borrowRatio
        );
        require(borrowInterestRate <= 3 * Decimal.one(), "BORROW_INTEREST_RATE_EXCEED_300%");

        uint256 borrowInterest = Decimal.mulCeil(_borrow, borrowInterestRate);
        uint256 supplyInterest = Decimal.mulFloor(borrowInterest, Decimal.one().sub(state.pool.insuranceRatio));

        supplyInterestRate = Decimal.divFloor(supplyInterest, _supply);
    }

     
    function updateIndex(
        Store.State storage state,
        address asset
    )
        private
    {
        if (state.pool.indexStartTime[asset] == block.timestamp) {
            return;
        }

        (uint256 currentSupplyIndex, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);

         
        uint256 normalizedBorrow = state.pool.normalizedTotalBorrow[asset];
        uint256 normalizedSupply = getTotalNormalizedSupply(state, asset);

         
        uint256 recentBorrowInterest = Decimal.mulCeil(
            normalizedBorrow,
            currentBorrowIndex.sub(state.pool.borrowIndex[asset])
        );

        uint256 recentSupplyInterest = Decimal.mulFloor(
            normalizedSupply,
            currentSupplyIndex.sub(state.pool.supplyIndex[asset])
        );

         
        state.pool.insuranceBalances[asset] = state.pool.insuranceBalances[asset].add(recentBorrowInterest.sub(recentSupplyInterest));

         
        Events.logUpdateIndex(
            asset,
            state.pool.borrowIndex[asset],
            currentBorrowIndex,
            state.pool.supplyIndex[asset],
            currentSupplyIndex
        );

        state.pool.supplyIndex[asset] = currentSupplyIndex;
        state.pool.borrowIndex[asset] = currentBorrowIndex;
        state.pool.indexStartTime[asset] = block.timestamp;

    }

    function getAmountSupplied(
        Store.State storage state,
        address asset,
        address user
    )
        internal
        view
        returns (uint256)
    {
        (uint256 currentSupplyIndex, ) = getCurrentIndex(state, asset);
        return Decimal.mulFloor(getNormalizedSupplyOf(state, asset, user), currentSupplyIndex);
    }

    function getAmountBorrowed(
        Store.State storage state,
        address asset,
        address user,
        uint16 marketID
    )
        internal
        view
        returns (uint256)
    {
         
        (, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);
        return Decimal.mulCeil(state.pool.normalizedBorrow[user][marketID][asset], currentBorrowIndex);
    }

    function getTotalSupply(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        (uint256 currentSupplyIndex, ) = getCurrentIndex(state, asset);
        return getTotalSupplyWithIndex(state, asset, currentSupplyIndex);
    }

    function getTotalBorrow(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        (, uint256 currentBorrowIndex) = getCurrentIndex(state, asset);
        return getTotalBorrowWithIndex(state, asset, currentBorrowIndex);
    }

    function getTotalSupplyWithIndex(
        Store.State storage state,
        address asset,
        uint256 currentSupplyIndex
    )
        private
        view
        returns (uint256)
    {
        return Decimal.mulFloor(getTotalNormalizedSupply(state, asset), currentSupplyIndex);
    }

    function getTotalBorrowWithIndex(
        Store.State storage state,
        address asset,
        uint256 currentBorrowIndex
    )
        private
        view
        returns (uint256)
    {
        return Decimal.mulCeil(state.pool.normalizedTotalBorrow[asset], currentBorrowIndex);
    }

     
    function getCurrentIndex(
        Store.State storage state,
        address asset
    )
        internal
        view
        returns (uint256 currentSupplyIndex, uint256 currentBorrowIndex)
    {
        uint256 timeDelta = block.timestamp.sub(state.pool.indexStartTime[asset]);

        uint256 borrowInterestRate = state.pool.borrowAnnualInterestRate[asset]
            .mul(timeDelta).divCeil(SECONDS_OF_YEAR);  

        uint256 supplyInterestRate = state.pool.supplyAnnualInterestRate[asset]
            .mul(timeDelta).div(SECONDS_OF_YEAR);

        currentBorrowIndex = Decimal.mulCeil(state.pool.borrowIndex[asset], Decimal.onePlus(borrowInterestRate));
        currentSupplyIndex = Decimal.mulFloor(state.pool.supplyIndex[asset], Decimal.onePlus(supplyInterestRate));

        return (currentSupplyIndex, currentBorrowIndex);
    }

    function getNormalizedSupplyOf(
        Store.State storage state,
        address asset,
        address user
    )
        private
        view
        returns (uint256)
    {
        return state.assets[asset].lendingPoolToken.balanceOf(user);
    }

    function getTotalNormalizedSupply(
        Store.State storage state,
        address asset
    )
        private
        view
        returns (uint256)
    {
        return state.assets[asset].lendingPoolToken.totalSupply();
    }
}

contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

     
    function transfer(
        address to,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

     
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

     
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

     
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }
}

interface IInterestModel {
    function polynomialInterestModel(
        uint256 borrowRatio
    )
        external
        pure
        returns(uint256);
}

interface ILendingPoolToken {
    function mint(
        address user,
        uint256 value
    )
        external;

    function burn(
        address user,
        uint256 value
    )
        external;

    function balanceOf(
        address user
    )
        external
        view
        returns (uint256);

    function totalSupply()
        external
        view
        returns (uint256);
}

interface IPriceOracle {
     
    function getPrice(
        address asset
    )
        external
        view
        returns (uint256);
}

interface IStandardToken {
    function transfer(
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function balanceOf(
        address _owner)
        external
        view
        returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);
}

library AssemblyCall {
    function getAssetPriceFromPriceOracle(
        address oracleAddress,
        address asset
    )
        internal
        view
        returns (uint256)
    {
         
         

         
        bytes32 functionSelector = 0x41976e0900000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            oracleAddress,
            functionSelector,
            bytes32(uint256(uint160(asset)))
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_ASSET_PRICE_FAILED");
        }

        return result;
    }

     
    function getHotBalance(
        address hotToken,
        address owner
    )
        internal
        view
        returns (uint256)
    {
         
         

         
        bytes32 functionSelector = 0x70a0823100000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            hotToken,
            functionSelector,
            bytes32(uint256(uint160(owner)))
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_HOT_BALANCE_FAILED");
        }

        return result;
    }

    function getBorrowInterestRate(
        address interestModel,
        uint256 borrowRatio
    )
        internal
        view
        returns (uint256)
    {
         
         

         
        bytes32 functionSelector = 0x69e8a15f00000000000000000000000000000000000000000000000000000000;

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            interestModel,
            functionSelector,
            bytes32(borrowRatio)
        );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_BORROW_INTEREST_RATE_FAILED");
        }

        return result;
    }

    function callWith32BytesReturnsUint256(
        address to,
        bytes32 functionSelector,
        bytes32 param1
    )
        private
        view
        returns (uint256 result, bool success)
    {
        assembly {
            let freePtr := mload(0x40)
            let tmp1 := mload(freePtr)
            let tmp2 := mload(add(freePtr, 4))

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), param1)

             
            success := staticcall(
                gas,            
                to,             
                freePtr,        
                36,             
                freePtr,        
                32              
            )

            result := mload(freePtr)

            mstore(freePtr, tmp1)
            mstore(add(freePtr, 4), tmp2)
        }
    }
}

library Consts {
    function ETHEREUM_TOKEN_ADDRESS()
        internal
        pure
        returns (address)
    {
        return 0x000000000000000000000000000000000000000E;
    }

     
    function DISCOUNT_RATE_BASE()
        internal
        pure
        returns (uint256)
    {
        return 100;
    }

    function REBATE_RATE_BASE()
        internal
        pure
        returns (uint256)
    {
        return 100;
    }
}

library Decimal {
    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    function one()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    function onePlus(
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return d.add(BASE);
    }

    function mulFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d) / BASE;
    }

    function mulCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(d).divCeil(BASE);
    }

    function divFloor(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).div(d);
    }

    function divCeil(
        uint256 target,
        uint256 d
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(BASE).divCeil(d);
    }
}

library EIP712 {
    string private constant DOMAIN_NAME = "Hydro Protocol";

     
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked("EIP712Domain(string name)")
    );

    bytes32 private constant DOMAIN_SEPARATOR = keccak256(
        abi.encodePacked(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(DOMAIN_NAME))
        )
    );

     
    function hashMessage(
        bytes32 eip712hash
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, eip712hash));
    }
}

library Events {
     
     
     

     
    event Deposit(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logDeposit(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Deposit(
            user,
            asset,
            amount
        );
    }

     
    event Withdraw(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logWithdraw(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Withdraw(
            user,
            asset,
            amount
        );
    }

     
    event IncreaseCollateral (
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logIncreaseCollateral(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit IncreaseCollateral(
            user,
            marketID,
            asset,
            amount
        );
    }

     
    event DecreaseCollateral (
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logDecreaseCollateral(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit DecreaseCollateral(
            user,
            marketID,
            asset,
            amount
        );
    }

     
     
     

    event UpdateIndex(
        address indexed asset,
        uint256 oldBorrowIndex,
        uint256 newBorrowIndex,
        uint256 oldSupplyIndex,
        uint256 newSupplyIndex
    );

    function logUpdateIndex(
        address asset,
        uint256 oldBorrowIndex,
        uint256 newBorrowIndex,
        uint256 oldSupplyIndex,
        uint256 newSupplyIndex
    )
        internal
    {
        emit UpdateIndex(
            asset,
            oldBorrowIndex,
            newBorrowIndex,
            oldSupplyIndex,
            newSupplyIndex
        );
    }

    event Borrow(
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logBorrow(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Borrow(
            user,
            marketID,
            asset,
            amount
        );
    }

    event Repay(
        address indexed user,
        uint16 indexed marketID,
        address indexed asset,
        uint256 amount
    );

    function logRepay(
        address user,
        uint16 marketID,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Repay(
            user,
            marketID,
            asset,
            amount
        );
    }

    event Supply(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logSupply(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Supply(
            user,
            asset,
            amount
        );
    }

    event Unsupply(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    function logUnsupply(
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        emit Unsupply(
            user,
            asset,
            amount
        );
    }

    event Loss(
        address indexed asset,
        uint256 amount
    );

    function logLoss(
        address asset,
        uint256 amount
    )
        internal
    {
        emit Loss(
            asset,
            amount
        );
    }

    event InsuranceCompensation(
        address indexed asset,
        uint256 amount
    );

    function logInsuranceCompensation(
        address asset,
        uint256 amount
    )
        internal
    {
        emit InsuranceCompensation(
            asset,
            amount
        );
    }

     
     
     

    event CreateMarket(Types.Market market);

    function logCreateMarket(
        Types.Market memory market
    )
        internal
    {
        emit CreateMarket(market);
    }

    event UpdateMarket(
        uint16 indexed marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    );

    function logUpdateMarket(
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        internal
    {
        emit UpdateMarket(
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    event MarketBorrowDisable(
        uint16 indexed marketID
    );

    function logMarketBorrowDisable(
        uint16 marketID
    )
        internal
    {
        emit MarketBorrowDisable(
            marketID
        );
    }

    event MarketBorrowEnable(
        uint16 indexed marketID
    );

    function logMarketBorrowEnable(
        uint16 marketID
    )
        internal
    {
        emit MarketBorrowEnable(
            marketID
        );
    }

    event UpdateDiscountConfig(bytes32 newConfig);

    function logUpdateDiscountConfig(
        bytes32 newConfig
    )
        internal
    {
        emit UpdateDiscountConfig(newConfig);
    }

    event CreateAsset(
        address asset,
        address oracleAddress,
        address poolTokenAddress,
        address interestModelAddress
    );

    function logCreateAsset(
        address asset,
        address oracleAddress,
        address poolTokenAddress,
        address interestModelAddress
    )
        internal
    {
        emit CreateAsset(
            asset,
            oracleAddress,
            poolTokenAddress,
            interestModelAddress
        );
    }

    event UpdateAsset(
        address indexed asset,
        address oracleAddress,
        address interestModelAddress
    );

    function logUpdateAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        internal
    {
        emit UpdateAsset(
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

    event UpdateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    );

    function logUpdateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    )
        internal
    {
        emit UpdateAuctionInitiatorRewardRatio(
            newInitiatorRewardRatio
        );
    }

    event UpdateInsuranceRatio(
        uint256 newInsuranceRatio
    );

    function logUpdateInsuranceRatio(
        uint256 newInsuranceRatio
    )
        internal
    {
        emit UpdateInsuranceRatio(newInsuranceRatio);
    }

     
     
     

    event Liquidate(
        address indexed user,
        uint16 indexed marketID,
        bool indexed hasAuction
    );

    function logLiquidate(
        address user,
        uint16 marketID,
        bool hasAuction
    )
        internal
    {
        emit Liquidate(
            user,
            marketID,
            hasAuction
        );
    }

     
    event AuctionCreate(
        uint256 auctionID
    );

    function logAuctionCreate(
        uint256 auctionID
    )
        internal
    {
        emit AuctionCreate(auctionID);
    }

     
    event FillAuction(
        uint256 indexed auctionID,
        address bidder,
        uint256 repayDebt,
        uint256 bidderRepayDebt,
        uint256 bidderCollateral,
        uint256 leftDebt
    );

    function logFillAuction(
        uint256 auctionID,
        address bidder,
        uint256 repayDebt,
        uint256 bidderRepayDebt,
        uint256 bidderCollateral,
        uint256 leftDebt
    )
        internal
    {
        emit FillAuction(
            auctionID,
            bidder,
            repayDebt,
            bidderRepayDebt,
            bidderCollateral,
            leftDebt
        );
    }

     
     
     

    event RelayerApproveDelegate(
        address indexed relayer,
        address indexed delegate
    );

    function logRelayerApproveDelegate(
        address relayer,
        address delegate
    )
        internal
    {
        emit RelayerApproveDelegate(
            relayer,
            delegate
        );
    }

    event RelayerRevokeDelegate(
        address indexed relayer,
        address indexed delegate
    );

    function logRelayerRevokeDelegate(
        address relayer,
        address delegate
    )
        internal
    {
        emit RelayerRevokeDelegate(
            relayer,
            delegate
        );
    }

    event RelayerExit(
        address indexed relayer
    );

    function logRelayerExit(
        address relayer
    )
        internal
    {
        emit RelayerExit(relayer);
    }

    event RelayerJoin(
        address indexed relayer
    );

    function logRelayerJoin(
        address relayer
    )
        internal
    {
        emit RelayerJoin(relayer);
    }

     
     
     

    event Match(
        Types.OrderAddressSet addressSet,
        address maker,
        address taker,
        address buyer,
        uint256 makerFee,
        uint256 makerRebate,
        uint256 takerFee,
        uint256 makerGasFee,
        uint256 takerGasFee,
        uint256 baseAssetFilledAmount,
        uint256 quoteAssetFilledAmount

    );

    function logMatch(
        Types.MatchResult memory result,
        Types.OrderAddressSet memory addressSet
    )
        internal
    {
        emit Match(
            addressSet,
            result.maker,
            result.taker,
            result.buyer,
            result.makerFee,
            result.makerRebate,
            result.takerFee,
            result.makerGasFee,
            result.takerGasFee,
            result.baseAssetFilledAmount,
            result.quoteAssetFilledAmount
        );
    }

    event OrderCancel(
        bytes32 indexed orderHash
    );

    function logOrderCancel(
        bytes32 orderHash
    )
        internal
    {
        emit OrderCancel(orderHash);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor()
        internal
    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner()
        public
        view
        returns(address)
    {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

     
    function isOwner()
        public
        view
        returns(bool)
    {
        return msg.sender == _owner;
    }

     
    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(
        address newOwner
    )
        public
        onlyOwner
    {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Operations is Ownable, GlobalStore {

    function createMarket(
        Types.Market memory market
    )
        public
        onlyOwner
    {
        OperationsComponent.createMarket(state, market);
    }

    function updateMarket(
        uint16 marketID,
        uint256 newAuctionRatioStart,
        uint256 newAuctionRatioPerBlock,
        uint256 newLiquidateRate,
        uint256 newWithdrawRate
    )
        external
        onlyOwner
    {
        OperationsComponent.updateMarket(
            state,
            marketID,
            newAuctionRatioStart,
            newAuctionRatioPerBlock,
            newLiquidateRate,
            newWithdrawRate
        );
    }

    function setMarketBorrowUsability(
        uint16 marketID,
        bool   usability
    )
        external
        onlyOwner
    {
        OperationsComponent.setMarketBorrowUsability(
            state,
            marketID,
            usability
        );
    }

    function createAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress,
        string calldata poolTokenName,
        string calldata poolTokenSymbol,
        uint8 poolTokenDecimals
    )
        external
        onlyOwner
    {
        OperationsComponent.createAsset(
            state,
            asset,
            oracleAddress,
            interestModelAddress,
            poolTokenName,
            poolTokenSymbol,
            poolTokenDecimals
        );
    }

    function updateAsset(
        address asset,
        address oracleAddress,
        address interestModelAddress
    )
        external
        onlyOwner
    {
        OperationsComponent.updateAsset(
            state,
            asset,
            oracleAddress,
            interestModelAddress
        );
    }

     
    function updateDiscountConfig(
        bytes32 newConfig
    )
        external
        onlyOwner
    {
        OperationsComponent.updateDiscountConfig(
            state,
            newConfig
        );
    }

    function updateAuctionInitiatorRewardRatio(
        uint256 newInitiatorRewardRatio
    )
        external
        onlyOwner
    {
        OperationsComponent.updateAuctionInitiatorRewardRatio(
            state,
            newInitiatorRewardRatio
        );
    }

    function updateInsuranceRatio(
        uint256 newInsuranceRatio
    )
        external
        onlyOwner
    {
        OperationsComponent.updateInsuranceRatio(
            state,
            newInsuranceRatio
        );
    }
}

contract Hydro is GlobalStore, ExternalFunctions, Operations {
    constructor(
        address _hotTokenAddress
    )
        public
    {
        state.exchange.hotTokenAddress = _hotTokenAddress;
        state.exchange.discountConfig = 0x043c000027106400004e205a000075305000009c404600000000000000000000;
    }
}

contract LendingPoolToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    constructor (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    )
        public
    {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
    }

    function mint(
        address user,
        uint256 value
    )
        external
        onlyOwner
    {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
    }

    function burn(
        address user,
        uint256 value
    )
        external
        onlyOwner
    {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
    }

}

library Requires {
    function requireAssetExist(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        require(isAssetExist(state, asset), "ASSET_NOT_EXIST");
    }

    function requireAssetNotExist(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        require(!isAssetExist(state, asset), "ASSET_ALREADY_EXIST");
    }

    function requireMarketIDAndAssetMatch(
        Store.State storage state,
        uint16 marketID,
        address asset
    )
        internal
        view
    {
        require(
            asset == state.markets[marketID].baseAsset || asset == state.markets[marketID].quoteAsset,
            "ASSET_NOT_BELONGS_TO_MARKET"
        );
    }

    function requireMarketNotExist(
        Store.State storage state,
        Types.Market memory market
    )
        internal
        view
    {
        require(!isMarketExist(state, market), "MARKET_ALREADY_EXIST");
    }

    function requireMarketAssetsValid(
        Store.State storage state,
        Types.Market memory market
    )
        internal
        view
    {
        require(market.baseAsset != market.quoteAsset, "BASE_QUOTE_DUPLICATED");
        require(isAssetExist(state, market.baseAsset), "MARKET_BASE_ASSET_NOT_EXIST");
        require(isAssetExist(state, market.quoteAsset), "MARKET_QUOTE_ASSET_NOT_EXIST");
    }

    function requireCashLessThanOrEqualContractBalance(
        Store.State storage state,
        address asset
    )
        internal
        view
    {
        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            if (state.cash[asset] > 0) {
                require(uint256(state.cash[asset]) <= address(this).balance, "CONTRACT_BALANCE_NOT_ENOUGH");
            }
        } else {
            if (state.cash[asset] > 0) {
                require(uint256(state.cash[asset]) <= IStandardToken(asset).balanceOf(address(this)), "CONTRACT_BALANCE_NOT_ENOUGH");
            }
        }
    }

    function requirePriceOracleAddressValid(
        address oracleAddress
    )
        internal
        pure
    {
        require(oracleAddress != address(0), "ORACLE_ADDRESS_NOT_VALID");
    }

    function requireDecimalLessOrEquanThanOne(
        uint256 decimal
    )
        internal
        pure
    {
        require(decimal <= Decimal.one(), "DECIMAL_GREATER_THAN_ONE");
    }

    function requireDecimalGreaterThanOne(
        uint256 decimal
    )
        internal
        pure
    {
        require(decimal > Decimal.one(), "DECIMAL_LESS_OR_EQUAL_THAN_ONE");
    }

    function requireMarketIDExist(
        Store.State storage state,
        uint16 marketID
    )
        internal
        view
    {
        require(marketID < state.marketsCount, "MARKET_NOT_EXIST");
    }

    function requireMarketBorrowEnabled(
        Store.State storage state,
        uint16 marketID
    )
        internal
        view
    {
        require(state.markets[marketID].borrowEnable, "MARKET_BORROW_DISABLED");
    }

    function requirePathNormalStatus(
        Store.State storage state,
        Types.BalancePath memory path
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireAccountNormal(state, path.marketID, path.user);
        }
    }

    function requireAccountNormal(
        Store.State storage state,
        uint16 marketID,
        address user
    )
        internal
        view
    {
        require(
            state.accounts[user][marketID].status == Types.CollateralAccountStatus.Normal,
            "CAN_NOT_OPERATE_LIQUIDATING_COLLATERAL_ACCOUNT"
        );
    }

    function requirePathMarketIDAssetMatch(
        Store.State storage state,
        Types.BalancePath memory path,
        address asset
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireMarketIDExist(state, path.marketID);
            requireMarketIDAndAssetMatch(state, path.marketID, asset);
        }
    }

    function requireCollateralAccountNotLiquidatable(
        Store.State storage state,
        Types.BalancePath memory path
    )
        internal
        view
    {
        if (path.category == Types.BalanceCategory.CollateralAccount) {
            requireCollateralAccountNotLiquidatable(state, path.user, path.marketID);
        }
    }

    function requireCollateralAccountNotLiquidatable(
        Store.State storage state,
        address user,
        uint16 marketID
    )
        internal
        view
    {
        require(
            !CollateralAccounts.getDetails(state, user, marketID).liquidatable,
            "COLLATERAL_ACCOUNT_LIQUIDATABLE"
        );
    }

    function requireAuctionNotFinished(
        Store.State storage state,
        uint32 auctionID
    )
        internal
        view
    {
        require(
            state.auction.auctions[auctionID].status == Types.AuctionStatus.InProgress,
            "AUCTION_ALREADY_FINISHED"
        );
    }

    function requireAuctionExist(
        Store.State storage state,
        uint32 auctionID
    )
        internal
        view
    {
        require(
            auctionID < state.auction.auctionsCount,
            "AUCTION_NOT_EXIST"
        );
    }

    function isAssetExist(
        Store.State storage state,
        address asset
    )
        private
        view
        returns (bool)
    {
        return state.assets[asset].priceOracle != IPriceOracle(address(0));
    }

    function isMarketExist(
        Store.State storage state,
        Types.Market memory market
    )
        private
        view
        returns (bool)
    {
        for(uint16 i = 0; i < state.marketsCount; i++) {
            if (state.markets[i].baseAsset == market.baseAsset && state.markets[i].quoteAsset == market.quoteAsset) {
                return true;
            }
        }

        return false;
    }

}

library SafeERC20 {
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        bool result;

        assembly {
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)

             
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to)
            mstore(36, amount)

             
            let callResult := call(gas, token, 0, 0, 68, 0, 32)
            let returnValue := mload(0)

            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)

             
            result := and (
                eq(callResult, 1),
                or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(returnValue, 0)))
            )
        }

        if (!result) {
            revert("TOKEN_TRANSFER_ERROR");
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bool result;

        assembly {
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)
            let tmp4 := mload(68)

             
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from)
            mstore(36, to)
            mstore(68, amount)

             
            let callResult := call(gas, token, 0, 0, 100, 0, 32)
            let returnValue := mload(0)

            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
            mstore(68, tmp4)

             
            result := and (
                eq(callResult, 1),
                or(eq(returndatasize, 0), and(eq(returndatasize, 32), gt(returnValue, 0)))
            )
        }

        if (!result) {
            revert("TOKEN_TRANSFER_FROM_ERROR");
        }
    }
}

library SafeMath {

     
    function mul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

     
    function div(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

     
    function sub(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function sub(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255-1, "INT256_SUB_ERROR");
        int256 c = a - int256(b);
        require(c <= a, "INT256_SUB_ERROR");
        return c;
    }

     
    function add(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function add(
        int256 a,
        uint256 b
    )
        internal
        pure
        returns (int256)
    {
        require(b <= 2**255 - 1, "INT256_ADD_ERROR");
        int256 c = a + int256(b);
        require(c >= a, "INT256_ADD_ERROR");
        return c;
    }

     
    function mod(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }

     
    function isRoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (bool)
    {
         
        return mul(mod(mul(numerator, multiple), denominator), 1000) >= mul(numerator, multiple);
    }

     
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 multiple
    )
        internal
        pure
        returns (uint256)
    {
        require(!isRoundingError(numerator, denominator, multiple), "ROUNDING_ERROR");
         
        return div(mul(numerator, multiple), denominator);
    }

     
    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

library Signature {

    enum SignatureMethod {
        EthSign,
        EIP712
    }

     
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        Types.Signature memory signature
    )
        internal
        pure
        returns (bool)
    {
        uint8 method = uint8(signature.config[1]);
        address recovered;
        uint8 v = uint8(signature.config[0]);

        if (method == uint8(SignatureMethod.EthSign)) {
            recovered = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v,
                signature.r,
                signature.s
            );
        } else if (method == uint8(SignatureMethod.EIP712)) {
            recovered = ecrecover(hash, v, signature.r, signature.s);
        } else {
            revert("INVALID_SIGN_METHOD");
        }

        return signerAddress == recovered;
    }
}

library Store {

    struct RelayerState {
         
        mapping (address => mapping (address => bool)) relayerDelegates;

         
        mapping (address => bool) hasExited;
    }

    struct ExchangeState {

         
        bytes32 discountConfig;

         
        mapping (bytes32 => uint256) filled;

         
        mapping (bytes32 => bool) cancelled;

        address hotTokenAddress;
    }

    struct LendingPoolState {
        uint256 insuranceRatio;

         
        mapping(address => uint256) insuranceBalances;

        mapping (address => uint256) borrowIndex;  
        mapping (address => uint256) supplyIndex;  
        mapping (address => uint256) indexStartTime;  

        mapping (address => uint256) borrowAnnualInterestRate;  
        mapping (address => uint256) supplyAnnualInterestRate;  

         
        mapping(address => uint256) normalizedTotalBorrow;

         
        mapping (address => mapping (uint16 => mapping(address => uint256))) normalizedBorrow;
    }

    struct AuctionState {

         
        uint32 auctionsCount;

         
        mapping(uint32 => Types.Auction) auctions;

         
        uint32[] currentAuctions;

         
        uint256 initiatorRewardRatio;
    }

    struct State {

        uint16 marketsCount;

        mapping(address => Types.Asset) assets;
        mapping(address => int256) cash;

         
        mapping(address => mapping(uint16 => Types.CollateralAccount)) accounts;

         
        mapping(uint16 => Types.Market) markets;

         
        mapping(address => mapping(address => uint256)) balances;

        LendingPoolState pool;

        ExchangeState exchange;

        RelayerState relayer;

        AuctionState auction;
    }
}

library Transfer {
    using SafeMath for uint256;
    using SafeMath for int256;
    using BalancePath for Types.BalancePath;

     
    function deposit(
        Store.State storage state,
        address asset,
        uint256 amount
    )
        internal
        returns (uint256)
    {
        uint256 depositedEtherAmount = 0;

        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
             
             
             
             
            depositedEtherAmount = amount;
        } else {
            SafeERC20.safeTransferFrom(asset, msg.sender, address(this), amount);
        }

        transferIn(state, asset, BalancePath.getCommonPath(msg.sender), amount);
        Events.logDeposit(msg.sender, asset, amount);

        return depositedEtherAmount;
    }

     
    function withdraw(
        Store.State storage state,
        address user,
        address asset,
        uint256 amount
    )
        internal
    {
        require(state.balances[user][asset] >= amount, "BALANCE_NOT_ENOUGH");

        if (asset == Consts.ETHEREUM_TOKEN_ADDRESS()) {
            address payable payableUser = address(uint160(user));
            payableUser.transfer(amount);
        } else {
            SafeERC20.safeTransfer(asset, user, amount);
        }

        transferOut(state, asset, BalancePath.getCommonPath(user), amount);

        Events.logWithdraw(user, asset, amount);
    }

     
    function balanceOf(
        Store.State storage state,
        Types.BalancePath memory balancePath,
        address asset
    )
        internal
        view
        returns (uint256)
    {
        mapping(address => uint256) storage balances = balancePath.getBalances(state);
        return balances[asset];
    }

     
    function transfer(
        Store.State storage state,
        address asset,
        Types.BalancePath memory fromBalancePath,
        Types.BalancePath memory toBalancePath,
        uint256 amount
    )
        internal
    {

        Requires.requirePathMarketIDAssetMatch(state, fromBalancePath, asset);
        Requires.requirePathMarketIDAssetMatch(state, toBalancePath, asset);

        mapping(address => uint256) storage fromBalances = fromBalancePath.getBalances(state);
        mapping(address => uint256) storage toBalances = toBalancePath.getBalances(state);

        require(fromBalances[asset] >= amount, "TRANSFER_BALANCE_NOT_ENOUGH");

        fromBalances[asset] = fromBalances[asset] - amount;
        toBalances[asset] = toBalances[asset].add(amount);
    }

    function transferIn(
        Store.State storage state,
        address asset,
        Types.BalancePath memory path,
        uint256 amount
    )
        internal
    {
        mapping(address => uint256) storage balances = path.getBalances(state);
        balances[asset] = balances[asset].add(amount);
        state.cash[asset] = state.cash[asset].add(amount);
    }

    function transferOut(
        Store.State storage state,
        address asset,
        Types.BalancePath memory path,
        uint256 amount
    )
        internal
    {
        mapping(address => uint256) storage balances = path.getBalances(state);
        balances[asset] = balances[asset].sub(amount);
        state.cash[asset] = state.cash[asset].sub(amount);
    }
}

library Types {
    enum AuctionStatus {
        InProgress,
        Finished
    }

    enum CollateralAccountStatus {
        Normal,
        Liquid
    }

    enum OrderStatus {
        EXPIRED,
        CANCELLED,
        FILLABLE,
        FULLY_FILLED
    }

     
    struct Signature {
         
        bytes32 config;
        bytes32 r;
        bytes32 s;
    }

    enum BalanceCategory {
        Common,
        CollateralAccount
    }

    struct BalancePath {
        BalanceCategory category;
        uint16          marketID;
        address         user;
    }

    struct Asset {
        ILendingPoolToken  lendingPoolToken;
        IPriceOracle      priceOracle;
        IInterestModel    interestModel;
    }

    struct Market {
        address baseAsset;
        address quoteAsset;

         
        uint256 liquidateRate;

         
        uint256 withdrawRate;

        uint256 auctionRatioStart;
        uint256 auctionRatioPerBlock;

        bool borrowEnable;
    }

    struct CollateralAccount {
        uint32 id;
        uint16 marketID;
        CollateralAccountStatus status;
        address owner;

        mapping(address => uint256) balances;
    }

     
    struct CollateralAccountDetails {
        bool       liquidatable;
        CollateralAccountStatus status;
        uint256    debtsTotalUSDValue;
        uint256    balancesTotalUSDValue;
    }

    struct Auction {
        uint32 id;
        AuctionStatus status;

         
        uint32 startBlockNumber;

        uint16 marketID;

        address borrower;
        address initiator;

        address debtAsset;
        address collateralAsset;
    }

    struct AuctionDetails {
        address borrower;
        uint16  marketID;
        address debtAsset;
        address collateralAsset;
        uint256 leftDebtAmount;
        uint256 leftCollateralAmount;
        uint256 ratio;
        uint256 price;
        bool    finished;
    }

    struct Order {
        address trader;
        address relayer;
        address baseAsset;
        address quoteAsset;
        uint256 baseAssetAmount;
        uint256 quoteAssetAmount;
        uint256 gasTokenAmount;

         
        bytes32 data;
    }

         
    struct OrderParam {
        address trader;
        uint256 baseAssetAmount;
        uint256 quoteAssetAmount;
        uint256 gasTokenAmount;
        bytes32 data;
        Signature signature;
    }


    struct OrderAddressSet {
        address baseAsset;
        address quoteAsset;
        address relayer;
    }

    struct MatchResult {
        address maker;
        address taker;
        address buyer;
        uint256 makerFee;
        uint256 makerRebate;
        uint256 takerFee;
        uint256 makerGasFee;
        uint256 takerGasFee;
        uint256 baseAssetFilledAmount;
        uint256 quoteAssetFilledAmount;
        BalancePath makerBalancePath;
        BalancePath takerBalancePath;
    }
     
    struct MatchParams {
        OrderParam       takerOrderParam;
        OrderParam[]     makerOrderParams;
        uint256[]        baseAssetFilledAmounts;
        OrderAddressSet  orderAddressSet;
    }
}

library Auction {
    using SafeMath for uint256;

    function ratio(
        Types.Auction memory auction,
        Store.State storage state
    )
        internal
        view
        returns (uint256)
    {
        uint256 increasedRatio = (block.number - auction.startBlockNumber).mul(state.markets[auction.marketID].auctionRatioPerBlock);
        uint256 initRatio = state.markets[auction.marketID].auctionRatioStart;
        uint256 totalRatio = initRatio.add(increasedRatio);
        return totalRatio;
    }
}

library BalancePath {

    function getBalances(
        Types.BalancePath memory path,
        Store.State storage state
    )
        internal
        view
        returns (mapping(address => uint256) storage)
    {
        if (path.category == Types.BalanceCategory.Common) {
            return state.balances[path.user];
        } else {
            return state.accounts[path.user][path.marketID].balances;
        }
    }

    function getCommonPath(
        address user
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        return Types.BalancePath({
            user: user,
            category: Types.BalanceCategory.Common,
            marketID: 0
        });
    }

    function getMarketPath(
        address user,
        uint16 marketID
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        return Types.BalancePath({
            user: user,
            category: Types.BalanceCategory.CollateralAccount,
            marketID: marketID
        });
    }
}

library Order {

    bytes32 public constant EIP712_ORDER_TYPE = keccak256(
        abi.encodePacked(
            "Order(address trader,address relayer,address baseAsset,address quoteAsset,uint256 baseAssetAmount,uint256 quoteAssetAmount,uint256 gasTokenAmount,bytes32 data)"
        )
    );

     
    function getHash(
        Types.Order memory order
    )
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = EIP712.hashMessage(_hashContent(order));
        return orderHash;
    }

     
    function _hashContent(
        Types.Order memory order
    )
        internal
        pure
        returns (bytes32 result)
    {
         

        bytes32 orderType = EIP712_ORDER_TYPE;

        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)

             
             
             
             
            mstore(start, orderType)
            result := keccak256(start, 288)

            mstore(start, tmp)
        }

        return result;
    }
}

library OrderParam {
     

    function getOrderVersion(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint8(byte(order.data)));
    }

    function getExpiredAtFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint40(bytes5(order.data << (8*3))));
    }

    function isSell(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[1]) == 1;
    }

    function isMarketOrder(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[2]) == 1;
    }

    function isMakerOnly(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return uint8(order.data[22]) == 1;
    }

    function isMarketBuy(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (bool)
    {
        return !isSell(order) && isMarketOrder(order);
    }

    function getAsMakerFeeRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint16(bytes2(order.data << (8*8))));
    }

    function getAsTakerFeeRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        return uint256(uint16(bytes2(order.data << (8*10))));
    }

    function getMakerRebateRateFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (uint256)
    {
        uint256 makerRebate = uint256(uint16(bytes2(order.data << (8*12))));

         
        return SafeMath.min(makerRebate, Consts.REBATE_RATE_BASE());
    }

    function getBalancePathFromOrderData(
        Types.OrderParam memory order
    )
        internal
        pure
        returns (Types.BalancePath memory)
    {
        Types.BalanceCategory category;
        uint16 marketID;

        if (byte(order.data << (8*23)) == "\x01") {
            category = Types.BalanceCategory.CollateralAccount;
            marketID = uint16(bytes2(order.data << (8*24)));
        } else {
            category = Types.BalanceCategory.Common;
            marketID = 0;
        }

        return Types.BalancePath({
            user: order.trader,
            category: category,
            marketID: marketID
        });
    }
}