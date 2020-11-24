 

pragma solidity 0.5.11;


interface ERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
interface KyberReserveInterface {

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        external
        payable
        returns(bool);

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}

contract OtcInterface {
    function getOffer(uint id) external view returns (uint, ERC20, uint, ERC20);
    function getBestOffer(ERC20 sellGem, ERC20 buyGem) external view returns(uint);
    function getWorseOffer(uint id) external view returns(uint);
    function take(bytes32 id, uint128 maxTakeAmount) external;
}

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event TransferAdminPending(address pendingAdmin);

     
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

     
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

     
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

     
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

     
    function withdrawEther(uint amount, address payable sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}


contract WethInterface is ERC20 {
    function deposit() public payable;
    function withdraw(uint) public;
}

interface UniswapExchange {
    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    )
        external
        payable
        returns (uint256  tokens_bought);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    )
        external
        returns (uint256  eth_bought);

    function getEthToTokenInputPrice(
        uint256 eth_sold
    )
        external
        view
        returns (uint256 tokens_bought);

    function getTokenToEthInputPrice(
        uint256 tokens_sold
    )
        external
        view
        returns (uint256 eth_bought);
}


interface UniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}


contract UniswapOasisBridgeReserve is KyberReserveInterface, Withdrawable {

     
    uint constant internal INVALID_ID = uint(-1);
    uint constant internal POW_2_32 = 2 ** 32;
    uint constant internal POW_2_96 = 2 ** 96;
    uint constant internal BPS = 10000;  
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28);  
    uint  constant internal MAX_RATE  = (PRECISION * 10**6);  
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;

     
    address public kyberNetwork;
    bool public tradeEnabled = true;
    uint public feeBps = 50;  

    OtcInterface public otc = OtcInterface(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);
    WethInterface public wethToken = WethInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    UniswapFactory public uniswapFactory = UniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    mapping(address => bool) public isTokenListed;
    mapping(address => address) public tokenExchange;
     
     
    mapping(address => uint) internal tokenBasicData;

    struct BasicDataConfig {
        uint minETHSupport;
        uint maxTraverse;
        uint maxTakes;
    }

    struct OfferData {
        uint payAmount;
        uint buyAmount;
        uint id;
    }

    constructor(address _kyberNetwork, address _admin) public {
        require(wethToken.approve(address(otc), 2**255), "constructor: failed to approve otc (wethToken)");

        kyberNetwork = _kyberNetwork;
        admin = _admin;
        tradeEnabled = true;
    }

    function() external payable {}  

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint) public view returns(uint) {
        if (!tradeEnabled) { return 0; }
        if (srcQty == 0) { return 0; }

        uint firstQty = srcQty / 2;

        (, uint destAmountUni) = getConversionRateUniswap(src, dest, firstQty);
        (, uint destAmountOasis) = getConversionRateOasis(src, dest, srcQty - firstQty);

        uint totalDest = destAmountUni + destAmountOasis;

        (, uint allAmountUni) = getConversionRateUniswap(src, dest, srcQty);
        (, uint allAmountOasis) = getConversionRateOasis(src, dest, srcQty);

        uint destQty = totalDest;
        if (destQty < allAmountUni) {
            destQty = allAmountUni;
        }
        if (destQty < allAmountOasis) {
            destQty = allAmountOasis;
        }
        uint rate = calcRateFromQty(srcQty, destQty, MAX_DECIMALS, MAX_DECIMALS);
        rate -= rate % 4;
        if (rate == 0) { return rate; }
        if (destQty == totalDest) { return rate; }
        if (destQty == allAmountUni) { rate -= 1; }
        if (destQty == allAmountOasis) { rate -= 2; }
        return rate;
    }

    function getConversionRateOasis(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint rate, uint destAmount) {
        if (!tradeEnabled || srcQty == 0) {
            rate = 0;
            destAmount = 0;
            return (rate, destAmount);
        }
         
        ERC20 token = src == ETH_TOKEN_ADDRESS ? dest : src;
        if (!isTokenListed[address(token)]) {
            rate = 0;
            destAmount = 0;
            return (rate, destAmount);
        }
        
        OfferData memory bid;
        OfferData memory ask;
        (bid, ask) = getFirstBidAndAskOrders(token);

        OfferData[] memory offers;

        if (src == ETH_TOKEN_ADDRESS) {
            (destAmount, offers) = findBestOffers(dest, wethToken, srcQty, bid, ask);
        } else {
            (destAmount, offers) = findBestOffers(wethToken, src, srcQty, bid, ask);
        }

        if (offers.length == 0 || destAmount == 0) {
            rate = 0;
            destAmount = 0;
            return (rate, destAmount);
        }

        destAmount = valueAfterReducingFee(destAmount);
        rate = calcRateFromQty(srcQty, destAmount, MAX_DECIMALS, MAX_DECIMALS);

        return (rate, destAmount);
    }

    function getConversionRateUniswap(ERC20 src, ERC20 dest, uint srcQty)
        public
        view
        returns(uint rate, uint destAmount)
    {
        (rate, destAmount) = calcUniswapConversion(src, dest, srcQty);
        return (rate, destAmount);
    }

    function calcUniswapConversion(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
        internal
        view
        returns(uint rate, uint destQty)
    {
        UniswapExchange exchange;
        ERC20 token = src == ETH_TOKEN_ADDRESS ? dest : src;
        if (tokenExchange[address(token)] == address(0)) {
            rate = 0;
            destQty = 0;
            return (rate, destQty);
        }
        if (src == ETH_TOKEN_ADDRESS) {
            exchange = UniswapExchange(tokenExchange[address(dest)]);
            destQty = exchange.getEthToTokenInputPrice(srcQty);
        } else {
            exchange = UniswapExchange(tokenExchange[address(src)]);
            destQty = exchange.getTokenToEthInputPrice(srcQty);
        }

        destQty = valueAfterReducingFee(destQty);

        rate = calcRateFromQty(
            srcQty,  
            destQty,  
            getDecimals(src),  
            getDecimals(dest)  
        );

        return (rate, destQty);
    }

    event TradeExecute(
        address indexed origin,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address payable destAddress
    );

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool
    )
        public
        payable
        returns(bool)
    {
        require(tradeEnabled, "trade: tradeEnabled is false");
        require(msg.sender == kyberNetwork, "trade: not call from kyberNetwork's contract");
        require(srcToken == ETH_TOKEN_ADDRESS || destToken == ETH_TOKEN_ADDRESS, "trade: srcToken or destToken must be ETH");

        ERC20 token = srcToken == ETH_TOKEN_ADDRESS ? destToken : srcToken;
        require(isTokenListed[address(token)], "trade: token is not listed");

        if (srcToken == ETH_TOKEN_ADDRESS) {
            require(msg.value == srcAmount, "trade: ETH amount is not correct");
        } else {
             
            require(srcToken.transferFrom(msg.sender, address(this), srcAmount));
        }

        uint srcBalBefore;
        uint destBalBefore;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            srcBalBefore = address(this).balance;
            destBalBefore = destToken.balanceOf(address(this));
        } else {
            srcBalBefore = srcToken.balanceOf(address(this));
            destBalBefore = address(this).balance;
        }

        uint totalDestAmount;

        if (conversionRate % 4 == 0) {
            uint uniswapDestAmt = doTradeUniswap(srcToken, destToken, srcAmount / 2);
            uint oasisSwapDestAmt = doTradeOasis(srcToken, destToken, srcAmount - srcAmount / 2);
            totalDestAmount = uniswapDestAmt + oasisSwapDestAmt;
        } else if (conversionRate % 2 == 0) {
            totalDestAmount = doTradeOasis(srcToken, destToken, srcAmount);
        } else {
            totalDestAmount = doTradeUniswap(srcToken, destToken, srcAmount);
        }

        uint expectedDestAmount = calcDestAmount(
            srcToken,  
            destToken,  
            srcAmount,  
            conversionRate  
        );

        require(totalDestAmount >= expectedDestAmount, "not enough dest amount");

        uint srcBalAfter;
        uint destBalAfter;

        if (srcToken == ETH_TOKEN_ADDRESS) {
            srcBalAfter = address(this).balance;
            destBalAfter = destToken.balanceOf(address(this));
        } else {
            srcBalAfter = srcToken.balanceOf(address(this));
            destBalAfter = address(this).balance;
        }

        require(srcBalAfter >= srcBalBefore - srcAmount, "src bal is not correct");
        require(destBalAfter >= destBalBefore + expectedDestAmount, "dest bal is not correct");

         
        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(expectedDestAmount);
        } else {
            require(destToken.transfer(destAddress, expectedDestAmount));
        }

        return true;
    }

    event TokenConfigDataSet(
        ERC20 token, uint maxTraverse,
        uint maxTake,
        uint minETHSupport
    );

    function setTokenConfigData(
        ERC20 token,
        uint maxTraverse,
        uint maxTake,
        uint minETHSupport
    )
        public onlyAdmin
    {
        address tokenAddr = address(token);
        require(isTokenListed[tokenAddr]);
        tokenBasicData[tokenAddr] = encodeTokenBasicData(minETHSupport, maxTraverse, maxTake);
        emit TokenConfigDataSet(
            token, maxTraverse,
            maxTake, minETHSupport
        );
    }

    function doTradeUniswap(ERC20 src, ERC20 dest, uint srcQty) internal returns(uint destAmount) {
        UniswapExchange exchange;
        if (src == ETH_TOKEN_ADDRESS) {
             
            if (tokenExchange[address(dest)] == address(0)) {
                destAmount = 0;
            } else {
                exchange = UniswapExchange(tokenExchange[address(dest)]);
                destAmount = exchange.ethToTokenSwapInput.value(srcQty)(
                    1,  
                    2 ** 255  
                );
            }
        } else {
            if (tokenExchange[address(src)] == address(0)) {
                destAmount = 0;
            } else {
                exchange = UniswapExchange(tokenExchange[address(src)]);
                destAmount = exchange.tokenToEthSwapInput(
                    srcQty,
                    1,  
                    2 ** 255  
                );
            }
        }
        return destAmount;
    }

    function doTradeOasis(
        ERC20 srcToken,
        ERC20 destToken,
        uint srcAmount
    )
        internal
        returns(uint)
    {

        uint actualDestAmount;

        OfferData memory bid;
        OfferData memory ask;
        (bid, ask) = getFirstBidAndAskOrders(srcToken == ETH_TOKEN_ADDRESS ? destToken : srcToken);

         
        OfferData[] memory offers;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            (actualDestAmount, offers) = findBestOffers(destToken, wethToken, srcAmount, bid, ask);   
        } else {
            (actualDestAmount, offers) = findBestOffers(wethToken, srcToken, srcAmount, bid, ask);
        }

        if (srcToken == ETH_TOKEN_ADDRESS) {
            wethToken.deposit.value(msg.value)();
            actualDestAmount = takeMatchingOrders(destToken, srcAmount, offers);
        } else {
            actualDestAmount = takeMatchingOrders(wethToken, srcAmount, offers);
            wethToken.withdraw(actualDestAmount);
        }

        return actualDestAmount;
    }

    event TradeEnabled(bool enable);

    function enableTrade(bool isEnabled) public onlyAdmin returns(bool) {
        tradeEnabled = isEnabled;
        emit TradeEnabled(isEnabled);
        return true;
    }

    event ContractsSet(address kyberNetwork, address otc);

    function setContracts(address _kyberNetwork, address _otc, address _uniswapFactory) public onlyAdmin {
        require(_kyberNetwork != address(0), "setContracts: kyberNetwork's address is missing");
        require(_otc != address(0), "setContracts: otc's address is missing");

        kyberNetwork = _kyberNetwork;
        otc = OtcInterface(_otc);
        uniswapFactory = UniswapFactory(_uniswapFactory);

        emit ContractsSet(_kyberNetwork, _otc);
    }

    event TokenListed(ERC20 token);

    function listToken(ERC20 token) public onlyAdmin {
        address tokenAddr = address(token);

        require(tokenAddr != address(0), "listToken: token's address is missing");
        require(!isTokenListed[tokenAddr], "listToken: token's alr listed");
        require(getDecimals(token) == MAX_DECIMALS, "listToken: token's decimals is not MAX_DECIMALS");
        require(token.approve(address(otc), 2**255), "listToken: approve token otc failed");

        address uniswapExchange = uniswapFactory.getExchange(tokenAddr);
        tokenExchange[address(token)] = uniswapExchange;
        if (address(uniswapExchange) != address(0)) {
            require(token.approve(uniswapExchange, 2**255), "listToken: approve token uniswap failed");
        }

        isTokenListed[tokenAddr] = true;

        emit TokenListed(token);
    }

    event TokenDelisted(ERC20 token);

    function delistToken(ERC20 token) public onlyAdmin {
        address tokenAddr = address(token);

        require(isTokenListed[tokenAddr], "delistToken: token is not listed");
        require(token.approve(address(otc), 0), "delistToken: reset approve token failed");
        address uniswapExchange = tokenExchange[tokenAddr];
        if (uniswapExchange != address(0)) {
            require(token.approve(uniswapExchange, 0), "listToken: approve token uniswap failed");
        }

        delete isTokenListed[tokenAddr];
        delete tokenBasicData[tokenAddr];

        emit TokenDelisted(token);
    }

    event FeeBpsSet(uint feeBps);

    function setFeeBps(uint _feeBps) public onlyAdmin {
        feeBps = _feeBps;
        emit FeeBpsSet(feeBps);
    }

    function takeMatchingOrders(ERC20 destToken, uint srcAmount, OfferData[] memory offers)
        internal
        returns(uint actualDestAmount)
    {
        require(destToken != ETH_TOKEN_ADDRESS, "takeMatchingOrders: destToken is ETH");

        uint lastReserveBalance = destToken.balanceOf(address(this));
        uint remainingSrcAmount = srcAmount;

        for (uint i = 0; i < offers.length; i++) {
            if (offers[i].id == 0 || remainingSrcAmount == 0) { break; }

            uint payAmount = minOf(remainingSrcAmount, offers[i].payAmount);
            uint buyAmount = payAmount * offers[i].buyAmount / offers[i].payAmount;

            otc.take(bytes32(offers[i].id), uint128(buyAmount));
            remainingSrcAmount -= payAmount;
        }

         
        require(remainingSrcAmount == 0, "takeMatchingOrders: did not take all src amount");

        uint newReserveBalance = destToken.balanceOf(address(this));

        require(newReserveBalance > lastReserveBalance, "takeMatchingOrders: newReserveBalance <= lastReserveBalance");

        actualDestAmount = newReserveBalance - lastReserveBalance;
    }

    function valueAfterReducingFee(uint val) internal view returns(uint) {
        return ((BPS - feeBps) * val) / BPS;
    }

    function findBestOffers(
        ERC20 dstToken,
        ERC20 srcToken,
        uint srcAmount,
        OfferData memory bid,
        OfferData memory ask
    )
        internal view
        returns(uint totalDestAmount, OfferData[] memory offers)
    {
        uint remainingSrcAmount = srcAmount;
        uint maxOrdersToTake;
        uint maxTraversedOrders;
        uint minPayAmount;
        uint numTakenOffer = 0;
        totalDestAmount = 0;
        ERC20 token = srcToken == wethToken ? dstToken : srcToken;

        (maxOrdersToTake, maxTraversedOrders, minPayAmount) = calcOfferLimitsFromFactorData(
            token,
            (srcToken == wethToken),
            bid,
            ask
        );

        offers = new OfferData[](maxTraversedOrders);

         
        if (maxTraversedOrders == 0 || maxOrdersToTake == 0) {
            return (totalDestAmount, offers);
        }

         
         
        if ((srcToken == wethToken && bid.id == 0) || (dstToken == wethToken && ask.id == 0)) {
            offers[0].id = otc.getBestOffer(dstToken, srcToken);
             
            (offers[0].buyAmount, , offers[0].payAmount, ) = otc.getOffer(offers[0].id);
        } else {
            offers[0] = srcToken == wethToken ? bid : ask;
        }

        uint thisOffer;

        OfferData memory biggestSkippedOffer = OfferData(0, 0, 0);

        for (; maxTraversedOrders > 0; --maxTraversedOrders) {
            thisOffer = numTakenOffer;

             
             
            if (biggestSkippedOffer.payAmount >= remainingSrcAmount) {
                offers[numTakenOffer].id = biggestSkippedOffer.id;
                offers[numTakenOffer].buyAmount = remainingSrcAmount * biggestSkippedOffer.buyAmount / biggestSkippedOffer.payAmount;
                offers[numTakenOffer].payAmount = remainingSrcAmount;
                totalDestAmount += offers[numTakenOffer].buyAmount;
                ++numTakenOffer;
                remainingSrcAmount = 0;
                break;
            } else if (offers[numTakenOffer].payAmount >= remainingSrcAmount) {
                offers[numTakenOffer].buyAmount = remainingSrcAmount * offers[numTakenOffer].buyAmount / offers[numTakenOffer].payAmount;
                offers[numTakenOffer].payAmount = remainingSrcAmount;
                totalDestAmount += offers[numTakenOffer].buyAmount;
                ++numTakenOffer;
                remainingSrcAmount = 0;
                break;
            } else if ((maxOrdersToTake - numTakenOffer) > 1
                        && offers[numTakenOffer].payAmount >= minPayAmount) {
                totalDestAmount += offers[numTakenOffer].buyAmount;
                remainingSrcAmount -= offers[numTakenOffer].payAmount;
                ++numTakenOffer;
            } else if (offers[numTakenOffer].payAmount > biggestSkippedOffer.payAmount) {
                biggestSkippedOffer.payAmount = offers[numTakenOffer].payAmount;
                biggestSkippedOffer.buyAmount = offers[numTakenOffer].buyAmount;
                biggestSkippedOffer.id = offers[numTakenOffer].id;
            }

            offers[numTakenOffer].id = otc.getWorseOffer(offers[thisOffer].id);
            (offers[numTakenOffer].buyAmount, , offers[numTakenOffer].payAmount, ) = otc.getOffer(offers[numTakenOffer].id);
        }

        if (remainingSrcAmount > 0) totalDestAmount = 0;
        if (totalDestAmount == 0) offers = new OfferData[](0);
    }

     
    function calcOfferLimitsFromFactorData(
        ERC20 token,
        bool isEthToToken,
        OfferData memory bid,
        OfferData memory ask
    )
        internal view
        returns(uint maxTakes, uint maxTraverse, uint minPayAmount)
    {
        if (!isEthToToken && (ask.id == 0 || bid.id == 0)) {
             
            maxTakes = 0;
            maxTraverse = 0;
            minPayAmount = 0;
            return (maxTakes, maxTraverse, minPayAmount);
        }

        uint order0Pay = 0;
        uint order0Buy = 0;

        if (!isEthToToken) {
             
            order0Pay = ask.payAmount;
            order0Buy = (ask.buyAmount + ask.payAmount * bid.payAmount / bid.buyAmount) / 2;
        }

        BasicDataConfig memory basicData = getTokenBasicData(token);

        maxTraverse = basicData.maxTraverse;
        maxTakes = basicData.maxTakes;

        uint minETHAmount = basicData.minETHSupport;

         
        minPayAmount = isEthToToken ? minETHAmount : minETHAmount * order0Pay / order0Buy;
    }

     
    function getFirstBidAndAskOrders(ERC20 token)
        internal view
        returns(OfferData memory bid, OfferData memory ask)
    {
         
        (bid.id, bid.payAmount, bid.buyAmount) = getFirstOffer(token, wethToken);
         
        (ask.id, ask.payAmount, ask.buyAmount) = getFirstOffer(wethToken, token);
    }

    function getFirstOffer(ERC20 offerSellGem, ERC20 offerBuyGem)
        internal view
        returns(uint offerId, uint offerPayAmount, uint offerBuyAmount)
    {
        offerId = otc.getBestOffer(offerSellGem, offerBuyGem);
        (offerBuyAmount, , offerPayAmount, ) = otc.getOffer(offerId);
    }

    function getTokenBasicData(ERC20 token) 
        internal view 
        returns(BasicDataConfig memory data)
    {
        (data.minETHSupport, data.maxTraverse, data.maxTakes) = decodeTokenBasicData(tokenBasicData[address(token)]);
    }

    function encodeTokenBasicData(uint ethSize, uint maxTraverse, uint maxTakes) 
        internal pure
        returns(uint data)
    {
        require(maxTakes < POW_2_32, "encodeTokenBasicData: maxTakes is too big");
        require(maxTraverse < POW_2_32, "encodeTokenBasicData: maxTraverse is too big");
        require(ethSize < POW_2_96, "encodeTokenBasicData: ethSize is too big");
        data = maxTakes & (POW_2_32 - 1);
        data |= (maxTraverse & (POW_2_32 - 1)) * POW_2_32;
        data |= (ethSize & (POW_2_96 * POW_2_96 - 1)) * POW_2_32 * POW_2_32;
    }

    function decodeTokenBasicData(uint data) 
        internal pure
        returns(uint ethSize, uint maxTraverse, uint maxTakes)
    {
        maxTakes = data & (POW_2_32 - 1);
        maxTraverse = (data / POW_2_32) & (POW_2_32 - 1);
        ethSize = (data / (POW_2_32 * POW_2_32)) & (POW_2_96 * POW_2_96 - 1);
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS;  
        return token.decimals();
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }

    function minOf(uint x, uint y) internal pure returns(uint) {
        return x > y ? y : x;
    }
}