 

pragma solidity 0.4.18;

 

 
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

 
interface KyberReserveInterface {

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool);

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) public view returns(uint);
}

 

 
contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28);  
    uint  constant internal MAX_RATE  = (PRECISION * 10**6);  
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=>uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS;  
        uint tokenDecimals = decimals[token];
         
         
         
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
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

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);
        
         
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator;  
    }
}

 

contract Utils2 is Utils {

     
     
     
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
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
}

 

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    function PermissionGroups() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[]) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

     
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

     
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        TransferAdminPending(newAdmin);
        AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

     
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]);  
        require(alertersGroup.length < MAX_GROUP_SIZE);

        AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]);  
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                OperatorAdded(operator, false);
                break;
            }
        }
    }
}

 

 
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

     
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

     
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        EtherWithdraw(amount, sendTo);
    }
}

 

contract OtcInterface {
    function getOffer(uint id) public constant returns (uint, ERC20, uint, ERC20);
    function getBestOffer(ERC20 sellGem, ERC20 buyGem) public constant returns(uint);
    function getWorseOffer(uint id) public constant returns(uint);
    function take(bytes32 id, uint128 maxTakeAmount) public;
}


contract WethInterface is ERC20 {
    function deposit() public payable;
    function withdraw(uint) public;
}


contract KyberOasisReserve is KyberReserveInterface, Withdrawable, Utils2 {

    uint constant internal COMMON_DECIMALS = 18;
    address public sanityRatesContract = 0;
    address public kyberNetwork;
    OtcInterface public otc;
    WethInterface public wethToken;
    mapping(address=>bool) public isTokenListed;
    mapping(address=>uint) public tokenMinSrcAmount;
    mapping(address=>uint) public minTokenBalance;
    mapping(address=>uint) public maxTokenBalance;
    mapping(address=>uint) public internalPricePremiumBps;
    mapping(address=>uint) public minOasisSpreadForinternalPricingBps;
    bool public tradeEnabled;
    uint public feeBps;

    function KyberOasisReserve(
        address _kyberNetwork,
        OtcInterface _otc,
        WethInterface _wethToken,
        address _admin,
        uint _feeBps
    )
        public
    {
        require(_admin != address(0));
        require(_kyberNetwork != address(0));
        require(_otc != address(0));
        require(_wethToken != address(0));
        require(_feeBps < 10000);
        require(getDecimals(_wethToken) == COMMON_DECIMALS);

        kyberNetwork = _kyberNetwork;
        otc = _otc;
        wethToken = _wethToken;
        admin = _admin;
        feeBps = _feeBps;
        tradeEnabled = true;

        require(wethToken.approve(otc, 2**255));
    }

    function() public payable {
         
    }

    function listToken(ERC20 token, uint minSrcAmount) public onlyAdmin {
        require(token != address(0));
        require(!isTokenListed[token]);
        require(getDecimals(token) == COMMON_DECIMALS);

        require(token.approve(otc, 2**255));
        isTokenListed[token] = true;
        tokenMinSrcAmount[token] = minSrcAmount;
        minTokenBalance[token] = 2 ** 255;  
        maxTokenBalance[token] = 0;  
        internalPricePremiumBps[token] = 0;  
        minOasisSpreadForinternalPricingBps[token] = 0;  
    }

    function delistToken(ERC20 token) public onlyAdmin {
        require(isTokenListed[token]);

        require(token.approve(otc, 0));
        delete isTokenListed[token];
        delete tokenMinSrcAmount[token];
        delete minTokenBalance[token];
        delete maxTokenBalance[token];
        delete internalPricePremiumBps[token];
        delete minOasisSpreadForinternalPricingBps[token];
    }

    function setInternalPriceAdminParams(ERC20 token,
                                         uint minSpreadBps,
                                         uint premiumBps) public onlyAdmin {
        require(isTokenListed[token]);
        require(premiumBps <= 500);  
        require(minSpreadBps <= 1000);  

        internalPricePremiumBps[token] = premiumBps;
        minOasisSpreadForinternalPricingBps[token] = minSpreadBps;
    }

    function setInternalInventoryMinMax(ERC20 token,
                                        uint  minBalance,
                                        uint  maxBalance) public onlyOperator {
        require(isTokenListed[token]);

         
        minTokenBalance[token] = minBalance;
        maxTokenBalance[token] = maxBalance;
    }

    event TradeExecute(
        address indexed sender,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address destAddress
    );

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool)
    {

        require(tradeEnabled);
        require(msg.sender == kyberNetwork);

        require(doTrade(srcToken, srcAmount, destToken, destAddress, conversionRate, validate));

        return true;
    }

    event TradeEnabled(bool enable);

    function enableTrade() public onlyAdmin returns(bool) {
        tradeEnabled = true;
        TradeEnabled(true);

        return true;
    }

    function disableTrade() public onlyAlerter returns(bool) {
        tradeEnabled = false;
        TradeEnabled(false);

        return true;
    }

    event KyberNetworkSet(address kyberNetwork);

    function setKyberNetwork(address _kyberNetwork) public onlyAdmin {
        require(_kyberNetwork != address(0));

        kyberNetwork = _kyberNetwork;
        KyberNetworkSet(kyberNetwork);
    }

    event FeeBpsSet(uint feeBps);

    function setFeeBps(uint _feeBps) public onlyAdmin {
        require(_feeBps < 10000);

        feeBps = _feeBps;
        FeeBpsSet(feeBps);
    }

    function valueAfterReducingFee(uint val) public view returns(uint) {
        require(val <= MAX_QTY);
        return ((10000 - feeBps) * val) / 10000;
    }

    function valueBeforeFeesWereReduced(uint val) public view returns(uint) {
        require(val <= MAX_QTY);
        return val * 10000 / (10000 - feeBps);
    }

    function valueAfterAddingPremium(ERC20 token, uint val) public view returns(uint) {
        require(val <= MAX_QTY);
        uint premium = internalPricePremiumBps[token];

        return val * (10000 + premium) / 10000;
    }
    function shouldUseInternalInventory(ERC20 token,
                                        uint tokenVal,
                                        uint ethVal,
                                        bool ethToToken) public view returns(bool) {
        require(tokenVal <= MAX_QTY);

        uint tokenBalance = token.balanceOf(this);
        if (ethToToken) {
            if (tokenBalance < tokenVal) return false;
            if (tokenBalance - tokenVal < minTokenBalance[token]) return false;
        }
        else {
            if (this.balance < ethVal) return false;
            if (tokenBalance + tokenVal > maxTokenBalance[token]) return false;
        }

         
        uint x1; uint y1; uint x2; uint y2;
        (,x1,y1) = getMatchingOffer(token, wethToken, 0);
        (,y2,x2) = getMatchingOffer(wethToken, token, 0);

        require(x1 <= MAX_QTY && x2 <= MAX_QTY && y1 <= MAX_QTY && y2 <= MAX_QTY);

         
        if (x1*y2 > x2*y1) return false;

         
        if (10000 * (x2*y1 - x1*y2) < x1*y2*minOasisSpreadForinternalPricingBps[token]) return false;


        return true;
    }

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) public view returns(uint) {
        uint  rate;
        uint  actualSrcQty;
        ERC20 actualSrc;
        ERC20 actualDest;
        uint offerPayAmt;
        uint offerBuyAmt;

        blockNumber;

        if (!tradeEnabled) return 0;
        if (!validTokens(src, dest)) return 0;

        if (src == ETH_TOKEN_ADDRESS) {
            actualSrc = wethToken;
            actualDest = dest;
            actualSrcQty = srcQty;
        } else if (dest == ETH_TOKEN_ADDRESS) {
            actualSrc = src;
            actualDest = wethToken;

            if (srcQty < tokenMinSrcAmount[src]) {
                 
                actualSrcQty = tokenMinSrcAmount[src];
            } else {
                actualSrcQty = srcQty;
            }
        } else {
            return 0;
        }

         
        (, offerPayAmt, offerBuyAmt) = getMatchingOffer(actualDest, actualSrc, actualSrcQty);

         
        if (actualSrcQty > offerBuyAmt) return 0;

        bool tradeFromInventory = false;
        uint valueWithPremium = valueAfterAddingPremium(token, offerPayAmt);
        ERC20 token;
        if (src == ETH_TOKEN_ADDRESS) {
            token = dest;
            tradeFromInventory = shouldUseInternalInventory(token,
                                                            valueWithPremium,
                                                            offerBuyAmt,
                                                            true);
        }
        else {
            token = src;
            tradeFromInventory = shouldUseInternalInventory(token,
                                                            offerBuyAmt,
                                                            valueWithPremium,
                                                            false);
        }

        rate = calcRateFromQty(offerBuyAmt, offerPayAmt, COMMON_DECIMALS, COMMON_DECIMALS);

        if (tradeFromInventory) return valueAfterAddingPremium(token,rate);
        else return valueAfterReducingFee(rate);
    }

    function doTrade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        uint actualDestAmount;

        require(validTokens(srcToken, destToken));

         
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount);
            else
                require(msg.value == 0);
        }

        uint userExpectedDestAmount = calcDstQty(srcAmount, COMMON_DECIMALS, COMMON_DECIMALS, conversionRate);
        require(userExpectedDestAmount > 0);  

        uint destAmountIncludingFees = valueBeforeFeesWereReduced(userExpectedDestAmount);

        if (srcToken == ETH_TOKEN_ADDRESS) {
            if(!shouldUseInternalInventory(destToken,
                                           userExpectedDestAmount,
                                           srcAmount,
                                           true)) {
                wethToken.deposit.value(msg.value)();

                actualDestAmount = takeMatchingOffer(wethToken, destToken, srcAmount);
                require(actualDestAmount >= destAmountIncludingFees);
            }

             
            require(destToken.transfer(destAddress, userExpectedDestAmount));
        } else {
            require(srcToken.transferFrom(msg.sender, this, srcAmount));

            if(!shouldUseInternalInventory(srcToken,
                                           srcAmount,
                                           userExpectedDestAmount,
                                           false)) {
                actualDestAmount = takeMatchingOffer(srcToken, wethToken, srcAmount);
                require(actualDestAmount >= destAmountIncludingFees);
                wethToken.withdraw(actualDestAmount);
            }

             
            destAddress.transfer(userExpectedDestAmount);
        }

        TradeExecute(msg.sender, srcToken, srcAmount, destToken, userExpectedDestAmount, destAddress);

        return true;
    }

    function takeMatchingOffer(
        ERC20 srcToken,
        ERC20 destToken,
        uint srcAmount
    )
        internal
        returns(uint actualDestAmount)
    {
        uint offerId;
        uint offerPayAmt;
        uint offerBuyAmt;

         
        (offerId, offerPayAmt, offerBuyAmt) = getMatchingOffer(destToken, srcToken, srcAmount);

        require(srcAmount <= MAX_QTY);
        require(offerPayAmt <= MAX_QTY);
        actualDestAmount = srcAmount * offerPayAmt / offerBuyAmt;

        require(uint128(actualDestAmount) == actualDestAmount);
        otc.take(bytes32(offerId), uint128(actualDestAmount));   
        return;
    }

    function getMatchingOffer(
        ERC20 offerSellGem,
        ERC20 offerBuyGem,
        uint payAmount
    )
        internal
        view
        returns(
            uint offerId,
            uint offerPayAmount,
            uint offerBuyAmount
        )
    {
        offerId = otc.getBestOffer(offerSellGem, offerBuyGem);
        (offerPayAmount, , offerBuyAmount, ) = otc.getOffer(offerId);
        uint depth = 1;

        while (payAmount > offerBuyAmount) {
            offerId = otc.getWorseOffer(offerId);  
            if (offerId == 0 || ++depth > 7) {
                offerId = 0;
                offerPayAmount = 0;
                offerBuyAmount = 0;
                break;
            }
            (offerPayAmount, , offerBuyAmount, ) = otc.getOffer(offerId);
        }

        return;
    }

    function validTokens(ERC20 src, ERC20 dest) internal view returns (bool valid) {
        return ((isTokenListed[src] && ETH_TOKEN_ADDRESS == dest) ||
                (isTokenListed[dest] && ETH_TOKEN_ADDRESS == src));
    }
}