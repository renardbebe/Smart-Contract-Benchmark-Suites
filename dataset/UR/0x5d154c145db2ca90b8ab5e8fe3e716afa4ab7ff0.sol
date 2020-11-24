 

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


 
contract KyberUniswapReserve is KyberReserveInterface, Withdrawable, Utils2 {
     
    uint public constant DEFAULT_FEE_BPS = 25;

    UniswapFactory public uniswapFactory;
    address public kyberNetwork;

    uint public feeBps = DEFAULT_FEE_BPS;

     
     
    mapping (address => address) public tokenExchange;

     
     
    mapping (address => uint) public internalInventoryMin;
    mapping (address => uint) public internalInventoryMax;

     
     
    mapping (address => uint) public internalActivationMinSpreadBps;

     
     
    mapping (address => uint) public internalPricePremiumBps;

    bool public tradeEnabled = true;

     
    function KyberUniswapReserve(
        UniswapFactory _uniswapFactory,
        address _admin,
        address _kyberNetwork
    )
        public
    {
        require(address(_uniswapFactory) != 0);
        require(_admin != 0);
        require(_kyberNetwork != 0);

        uniswapFactory = _uniswapFactory;
        admin = _admin;
        kyberNetwork = _kyberNetwork;
    }

    function() public payable {
         
    }

     
    function getConversionRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty,
        uint blockNumber
    )
        public
        view
        returns(uint)
    {
         
        blockNumber;
        if (!isValidTokens(src, dest)) return 0;
        if (!tradeEnabled) return 0;
        if (srcQty == 0) return 0;

        ERC20 token;
        if (src == ETH_TOKEN_ADDRESS) {
            token = dest;
        } else if (dest == ETH_TOKEN_ADDRESS) {
            token = src;
        } else {
             
            revert();
        }

        uint convertedQuantity;
        uint rateSrcDest;
        uint rateDestSrc;
        (convertedQuantity, rateSrcDest) = calcUniswapConversion(src, dest, srcQty);
        (, rateDestSrc) = calcUniswapConversion(dest, src, convertedQuantity);

        uint quantityWithPremium = addPremium(token, convertedQuantity);

        bool useInternalInventory = shouldUseInternalInventory(
            src,  
            srcQty,  
            dest,  
            quantityWithPremium,  
            rateSrcDest,  
            rateDestSrc  
        );

        uint rate;
        if (useInternalInventory) {
             
            rate = calcRateFromQty(
                srcQty,  
                quantityWithPremium,  
                getDecimals(src),  
                getDecimals(dest)  
            );
        } else {
             
            rate = rateSrcDest;
        }
        return applyInternalInventoryHintToRate(rate, useInternalInventory);
    }

    function applyInternalInventoryHintToRate(
        uint rate,
        bool useInternalInventory
    )
        internal
        pure
        returns(uint)
    {
        return rate % 2 == (useInternalInventory ? 1 : 0)
            ? rate
            : rate - 1;
    }


    event TradeExecute(
        address indexed sender,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address destAddress,
        bool useInternalInventory
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
        require(isValidTokens(srcToken, destToken));

        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount);
            else
                require(msg.value == 0);
        }

         
         
         
        if (srcToken != ETH_TOKEN_ADDRESS)
            require(srcToken.transferFrom(msg.sender, address(this), srcAmount));

        uint expectedDestAmount = calcDestAmount(
            srcToken,  
            destToken,  
            srcAmount,  
            conversionRate  
        );

        bool useInternalInventory = conversionRate % 2 == 1;

        uint destAmount;
        UniswapExchange exchange;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            if (!useInternalInventory) {
                 
                uint quantity = deductFee(srcAmount);
                exchange = UniswapExchange(tokenExchange[address(destToken)]);
                destAmount = exchange.ethToTokenSwapInput.value(quantity)(
                    1,  
                    2 ** 255  
                );
                require(destAmount >= expectedDestAmount);
            }

             
            require(destToken.transfer(destAddress, expectedDestAmount));
        } else {
            if (!useInternalInventory) {
                exchange = UniswapExchange(tokenExchange[address(srcToken)]);
                destAmount = exchange.tokenToEthSwapInput(
                    srcAmount,
                    1,  
                    2 ** 255  
                );
                 
                destAmount = deductFee(destAmount);
                require(destAmount >= expectedDestAmount);
            }

             
            destAddress.transfer(expectedDestAmount);
        }

        TradeExecute(
            msg.sender,  
            srcToken,  
            srcAmount,  
            destToken,  
            expectedDestAmount,  
            destAddress,  
            useInternalInventory  
        );
        return true;
    }

    event FeeUpdated(
        uint bps
    );

    function setFee(
        uint bps
    )
        public
        onlyAdmin
    {
        require(bps <= 10000);

        feeBps = bps;

        FeeUpdated(bps);
    }

    event InternalActivationConfigUpdated(
        ERC20 token,
        uint minSpreadBps,
        uint premiumBps
    );

    function setInternalActivationConfig(
        ERC20 token,
        uint minSpreadBps,
        uint premiumBps
    )
        public
        onlyAdmin
    {
        require(tokenExchange[address(token)] != address(0));
        require(minSpreadBps <= 1000);  
        require(premiumBps <= 500);  

        internalActivationMinSpreadBps[address(token)] = minSpreadBps;
        internalPricePremiumBps[address(token)] = premiumBps;

        InternalActivationConfigUpdated(token, minSpreadBps, premiumBps);
    }

    event InternalInventoryLimitsUpdated(
        ERC20 token,
        uint minBalance,
        uint maxBalance
    );

    function setInternalInventoryLimits(
        ERC20 token,
        uint minBalance,
        uint maxBalance
    )
        public
        onlyOperator
    {
        require(tokenExchange[address(token)] != address(0));

        internalInventoryMin[address(token)] = minBalance;
        internalInventoryMax[address(token)] = maxBalance;

        InternalInventoryLimitsUpdated(token, minBalance, maxBalance);
    }

    event TokenListed(
        ERC20 token,
        UniswapExchange exchange
    );

    function listToken(ERC20 token)
        public
        onlyAdmin
    {
        require(address(token) != 0);

        UniswapExchange uniswapExchange = UniswapExchange(
            uniswapFactory.getExchange(token)
        );
        tokenExchange[address(token)] = address(uniswapExchange);
        setDecimals(token);

        require(token.approve(uniswapExchange, 2 ** 255));

         
        internalInventoryMin[address(token)] = 2 ** 255;
        internalInventoryMax[address(token)] = 0;
        internalActivationMinSpreadBps[address(token)] = 0;
        internalPricePremiumBps[address(token)] = 0;

        TokenListed(token, uniswapExchange);
    }

    event TokenDelisted(ERC20 token);

    function delistToken(ERC20 token)
        public
        onlyAdmin
    {
        require(tokenExchange[address(token)] != address(0));

        delete tokenExchange[address(token)];
        delete internalInventoryMin[address(token)];
        delete internalInventoryMax[address(token)];
        delete internalActivationMinSpreadBps[address(token)];
        delete internalPricePremiumBps[address(token)];

        TokenDelisted(token);
    }

    function isValidTokens(
        ERC20 src,
        ERC20 dest
    )
        public
        view
        returns(bool)
    {
        return (
            (
                src == ETH_TOKEN_ADDRESS &&
                tokenExchange[address(dest)] != address(0)
            ) ||
            (
                tokenExchange[address(src)] != address(0) &&
                dest == ETH_TOKEN_ADDRESS
            )
        );
    }

    event TradeEnabled(
        bool enable
    );

    function enableTrade()
        public
        onlyAdmin
        returns(bool)
    {
        tradeEnabled = true;
        TradeEnabled(true);
        return true;
    }

    function disableTrade()
        public
        onlyAlerter
        returns(bool)
    {
        tradeEnabled = false;
        TradeEnabled(false);
        return true;
    }

    event KyberNetworkSet(
        address kyberNetwork
    );

    function setKyberNetwork(
        address _kyberNetwork
    )
        public
        onlyAdmin
    {
        require(_kyberNetwork != 0);
        kyberNetwork = _kyberNetwork;
        KyberNetworkSet(kyberNetwork);
    }

     
    function shouldUseInternalInventory(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        uint destAmount,
        uint rateSrcDest,
        uint rateDestSrc
    )
        public
        view
        returns(bool)
    {
        require(srcAmount < MAX_QTY);
        require(destAmount < MAX_QTY);

         
        ERC20 token;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            token = destToken;
            uint tokenBalance = token.balanceOf(this);
            if (
                tokenBalance < destAmount ||
                tokenBalance - destAmount < internalInventoryMin[token]
            ) {
                return false;
            }
        } else {
            token = srcToken;
            if (this.balance < destAmount) return false;
            if (token.balanceOf(this) + srcAmount > internalInventoryMax[token]) {
                return false;
            }
        }

        uint normalizedDestSrc = 10 ** 36 / rateDestSrc;

         
        if (rateSrcDest > normalizedDestSrc) return false;

        uint activationSpread = internalActivationMinSpreadBps[token];
        uint spread = uint(calculateSpreadBps(normalizedDestSrc, rateSrcDest));
        return spread >= activationSpread;
    }

     
    function calculateSpreadBps(
        uint _askRate,
        uint _bidRate
    )
        public
        pure
        returns(int)
    {
        int askRate = int(_askRate);
        int bidRate = int(_bidRate);
        return 10000 * 2 * (askRate - bidRate) / (askRate + bidRate);
    }

    function deductFee(
        uint amount
    )
        public
        view
        returns(uint)
    {
        return amount * (10000 - feeBps) / 10000;
    }

    function addPremium(
        ERC20 token,
        uint amount
    )
        public
        view
        returns(uint)
    {
        require(amount <= MAX_QTY);
        return amount * (10000 + internalPricePremiumBps[token]) / 10000;
    }

    function calcUniswapConversion(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
        internal
        view
        returns(uint destQty, uint rate)
    {
        UniswapExchange exchange;
        if (src == ETH_TOKEN_ADDRESS) {
            exchange = UniswapExchange(tokenExchange[address(dest)]);
            destQty = exchange.getEthToTokenInputPrice(
                deductFee(srcQty)
            );
        } else {
            exchange = UniswapExchange(tokenExchange[address(src)]);
            destQty = deductFee(
                exchange.getTokenToEthInputPrice(srcQty)
            );
        }

        rate = calcRateFromQty(
            srcQty,  
            destQty,  
            getDecimals(src),  
            getDecimals(dest)  
        );
    }
}