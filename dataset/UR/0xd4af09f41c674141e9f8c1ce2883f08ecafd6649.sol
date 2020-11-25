 

pragma solidity 0.4.18;

contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28);  
    uint  constant internal MAX_RATE  = (PRECISION * 10**6);  
    uint  constant internal MAX_DECIMALS = 18;

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
         
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

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;

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

contract VolumeImbalanceRecorder is Withdrawable {

    uint constant internal SLIDING_WINDOW_SIZE = 5;
    uint constant internal POW_2_64 = 2 ** 64;

    struct TokenControlInfo {
        uint minimalRecordResolution;  
        uint maxPerBlockImbalance;  
        uint maxTotalImbalance;  
                             
    }

    mapping(address => TokenControlInfo) internal tokenControlInfo;

    struct TokenImbalanceData {
        int  lastBlockBuyUnitsImbalance;
        uint lastBlock;

        int  totalBuyUnitsImbalance;
        uint lastRateUpdateBlock;
    }

    mapping(address => mapping(uint=>uint)) public tokenImbalanceData;

    function VolumeImbalanceRecorder(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    function setTokenControlInfo(
        ERC20 token,
        uint minimalRecordResolution,
        uint maxPerBlockImbalance,
        uint maxTotalImbalance
    )
        public
        onlyAdmin
    {
        tokenControlInfo[token] =
            TokenControlInfo(
                minimalRecordResolution,
                maxPerBlockImbalance,
                maxTotalImbalance
            );
    }

    function getTokenControlInfo(ERC20 token) public view returns(uint, uint, uint) {
        return (tokenControlInfo[token].minimalRecordResolution,
                tokenControlInfo[token].maxPerBlockImbalance,
                tokenControlInfo[token].maxTotalImbalance);
    }

    function addImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        internal
    {
        uint currentBlockIndex = currentBlock % SLIDING_WINDOW_SIZE;
        int recordedBuyAmount = int(buyAmount / int(tokenControlInfo[token].minimalRecordResolution));

        int prevImbalance = 0;

        TokenImbalanceData memory currentBlockData =
            decodeTokenImbalanceData(tokenImbalanceData[token][currentBlockIndex]);

         
        if (currentBlockData.lastBlock == currentBlock) {
            if (uint(currentBlockData.lastRateUpdateBlock) == rateUpdateBlock) {
                 
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.totalBuyUnitsImbalance += recordedBuyAmount;
            } else {
                 
                prevImbalance = getImbalanceInRange(token, rateUpdateBlock, currentBlock);
                currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
                currentBlockData.lastBlockBuyUnitsImbalance += recordedBuyAmount;
                currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            }
        } else {
             
            int currentBlockImbalance;
            (prevImbalance, currentBlockImbalance) = getImbalanceSinceRateUpdate(token, rateUpdateBlock, currentBlock);

            currentBlockData.lastBlockBuyUnitsImbalance = recordedBuyAmount;
            currentBlockData.lastBlock = uint(currentBlock);
            currentBlockData.lastRateUpdateBlock = uint(rateUpdateBlock);
            currentBlockData.totalBuyUnitsImbalance = int(prevImbalance) + recordedBuyAmount;
        }

        tokenImbalanceData[token][currentBlockIndex] = encodeTokenImbalanceData(currentBlockData);
    }

    function setGarbageToVolumeRecorder(ERC20 token) internal {
        for (uint i = 0; i < SLIDING_WINDOW_SIZE; i++) {
            tokenImbalanceData[token][i] = 0x1;
        }
    }

    function getImbalanceInRange(ERC20 token, uint startBlock, uint endBlock) internal view returns(int buyImbalance) {
         
        require(startBlock <= endBlock);

        buyImbalance = 0;

        for (uint windowInd = 0; windowInd < SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock <= endBlock && perBlockData.lastBlock >= startBlock) {
                buyImbalance += int(perBlockData.lastBlockBuyUnitsImbalance);
            }
        }
    }

    function getImbalanceSinceRateUpdate(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int buyImbalance, int currentBlockImbalance)
    {
        buyImbalance = 0;
        currentBlockImbalance = 0;
        uint latestBlock = 0;
        int imbalanceInRange = 0;
        uint startBlock = rateUpdateBlock;
        uint endBlock = currentBlock;

        for (uint windowInd = 0; windowInd < SLIDING_WINDOW_SIZE; windowInd++) {
            TokenImbalanceData memory perBlockData = decodeTokenImbalanceData(tokenImbalanceData[token][windowInd]);

            if (perBlockData.lastBlock <= endBlock && perBlockData.lastBlock >= startBlock) {
                imbalanceInRange += perBlockData.lastBlockBuyUnitsImbalance;
            }

            if (perBlockData.lastRateUpdateBlock != rateUpdateBlock) continue;
            if (perBlockData.lastBlock < latestBlock) continue;

            latestBlock = perBlockData.lastBlock;
            buyImbalance = perBlockData.totalBuyUnitsImbalance;
            if (uint(perBlockData.lastBlock) == currentBlock) {
                currentBlockImbalance = perBlockData.lastBlockBuyUnitsImbalance;
            }
        }

        if (buyImbalance == 0) {
            buyImbalance = imbalanceInRange;
        }
    }

    function getImbalance(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int totalImbalance, int currentBlockImbalance)
    {

        int resolution = int(tokenControlInfo[token].minimalRecordResolution);

        (totalImbalance, currentBlockImbalance) =
            getImbalanceSinceRateUpdate(
                token,
                rateUpdateBlock,
                currentBlock);

        totalImbalance *= resolution;
        currentBlockImbalance *= resolution;
    }

    function getMaxPerBlockImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxPerBlockImbalance;
    }

    function getMaxTotalImbalance(ERC20 token) internal view returns(uint) {
        return tokenControlInfo[token].maxTotalImbalance;
    }

    function encodeTokenImbalanceData(TokenImbalanceData data) internal pure returns(uint) {
         
        require(data.lastBlockBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.lastBlockBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastBlock < POW_2_64);
        require(data.totalBuyUnitsImbalance < int(POW_2_64 / 2));
        require(data.totalBuyUnitsImbalance > int(-1 * int(POW_2_64) / 2));
        require(data.lastRateUpdateBlock < POW_2_64);

         
        uint result = uint(data.lastBlockBuyUnitsImbalance) & (POW_2_64 - 1);
        result |= data.lastBlock * POW_2_64;
        result |= (uint(data.totalBuyUnitsImbalance) & (POW_2_64 - 1)) * POW_2_64 * POW_2_64;
        result |= data.lastRateUpdateBlock * POW_2_64 * POW_2_64 * POW_2_64;

        return result;
    }

    function decodeTokenImbalanceData(uint input) internal pure returns(TokenImbalanceData) {
        TokenImbalanceData memory data;

        data.lastBlockBuyUnitsImbalance = int(int64(input & (POW_2_64 - 1)));
        data.lastBlock = uint(uint64((input / POW_2_64) & (POW_2_64 - 1)));
        data.totalBuyUnitsImbalance = int(int64((input / (POW_2_64 * POW_2_64)) & (POW_2_64 - 1)));
        data.lastRateUpdateBlock = uint(uint64((input / (POW_2_64 * POW_2_64 * POW_2_64))));

        return data;
    }
}

contract ConversionRates is VolumeImbalanceRecorder, Utils {

     
    struct StepFunction {
        int[] x;  
        int[] y;  
    }

    struct TokenData {
        bool listed;   
        bool enabled;  

         
        uint compactDataArrayIndex;
        uint compactDataFieldIndex;

         
         
        uint baseBuyRate;   
        uint baseSellRate;  
        StepFunction buyRateQtyStepFunction;  
        StepFunction sellRateQtyStepFunction; 
        StepFunction buyRateImbalanceStepFunction;  
        StepFunction sellRateImbalanceStepFunction;
    }

     
    uint public validRateDurationInBlocks = 10;  
    ERC20[] internal listedTokens;
    mapping(address=>TokenData) internal tokenData;
    bytes32[] internal tokenRatesCompactData;
    uint public numTokensInCurrentCompactData = 0;
    address public reserveContract;
    uint constant internal NUM_TOKENS_IN_COMPACT_DATA = 14;
    uint constant internal BYTES_14_OFFSET = (2 ** (8 * NUM_TOKENS_IN_COMPACT_DATA));

    function ConversionRates(address _admin) public VolumeImbalanceRecorder(_admin)
        { }  

    function addToken(ERC20 token) public onlyAdmin {

        require(!tokenData[token].listed);
        tokenData[token].listed = true;
        listedTokens.push(token);

        if (numTokensInCurrentCompactData == 0) {
            tokenRatesCompactData.length++;  
        }

        tokenData[token].compactDataArrayIndex = tokenRatesCompactData.length - 1;
        tokenData[token].compactDataFieldIndex = numTokensInCurrentCompactData;

        numTokensInCurrentCompactData = (numTokensInCurrentCompactData + 1) % NUM_TOKENS_IN_COMPACT_DATA;

        setGarbageToVolumeRecorder(token);
    }

    function setCompactData(bytes14[] buy, bytes14[] sell, uint blockNumber, uint[] indices) public onlyOperator {

        require(buy.length == sell.length);
        require(indices.length == buy.length);
        require(blockNumber <= 0xFFFFFFFF);

        uint bytes14Offset = BYTES_14_OFFSET;

        for (uint i = 0; i < indices.length; i++) {
            require(indices[i] < tokenRatesCompactData.length);
            uint data = uint(buy[i]) | uint(sell[i]) * bytes14Offset | (blockNumber * (bytes14Offset * bytes14Offset));
            tokenRatesCompactData[indices[i]] = bytes32(data);
        }
    }

    function setBaseRate(
        ERC20[] tokens,
        uint[] baseBuy,
        uint[] baseSell,
        bytes14[] buy,
        bytes14[] sell,
        uint blockNumber,
        uint[] indices
    )
        public
        onlyOperator
    {
        require(tokens.length == baseBuy.length);
        require(tokens.length == baseSell.length);
        require(sell.length == buy.length);
        require(sell.length == indices.length);

        for (uint ind = 0; ind < tokens.length; ind++) {
            require(tokenData[tokens[ind]].listed);
            tokenData[tokens[ind]].baseBuyRate = baseBuy[ind];
            tokenData[tokens[ind]].baseSellRate = baseSell[ind];
        }

        setCompactData(buy, sell, blockNumber, indices);
    }

    function setQtyStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(tokenData[token].listed);

        tokenData[token].buyRateQtyStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateQtyStepFunction = StepFunction(xSell, ySell);
    }

    function setImbalanceStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length == yBuy.length);
        require(xSell.length == ySell.length);
        require(tokenData[token].listed);

        tokenData[token].buyRateImbalanceStepFunction = StepFunction(xBuy, yBuy);
        tokenData[token].sellRateImbalanceStepFunction = StepFunction(xSell, ySell);
    }

    function setValidRateDurationInBlocks(uint duration) public onlyAdmin {
        validRateDurationInBlocks = duration;
    }

    function enableTokenTrade(ERC20 token) public onlyAdmin {
        require(tokenData[token].listed);
        require(tokenControlInfo[token].minimalRecordResolution != 0);
        tokenData[token].enabled = true;
    }

    function disableTokenTrade(ERC20 token) public onlyAlerter {
        require(tokenData[token].listed);
        tokenData[token].enabled = false;
    }

    function setReserveAddress(address reserve) public onlyAdmin {
        reserveContract = reserve;
    }

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public
    {
        require(msg.sender == reserveContract);

        if (rateUpdateBlock == 0) rateUpdateBlock = getRateUpdateBlock(token);

        return addImbalance(token, buyAmount, rateUpdateBlock, currentBlock);
    }

     
    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint) {
         
        if (!tokenData[token].enabled) return 0;
        if (tokenControlInfo[token].minimalRecordResolution == 0) return 0;  

         
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];

        uint updateRateBlock = getLast4Bytes(compactData);
        if (currentBlockNumber >= updateRateBlock + validRateDurationInBlocks) return 0;  
         
        int totalImbalance;
        int blockImbalance;
        (totalImbalance, blockImbalance) = getImbalance(token, updateRateBlock, currentBlockNumber);

         
        int imbalanceQty;
        int extraBps;
        int8 rateUpdate;
        uint rate;

        if (buy) {
             
            rate = tokenData[token].baseBuyRate;

             
            rateUpdate = getRateByteFromCompactData(compactData, token, true);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

             
            qty = getTokenQty(token, rate, qty);
            imbalanceQty = int(qty);
            totalImbalance += imbalanceQty;

             
            extraBps = executeStepFunction(tokenData[token].buyRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

             
            extraBps = executeStepFunction(tokenData[token].buyRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        } else {
             
            rate = tokenData[token].baseSellRate;

             
            rateUpdate = getRateByteFromCompactData(compactData, token, false);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

             
            imbalanceQty = -1 * int(qty);
            totalImbalance += imbalanceQty;

             
            extraBps = executeStepFunction(tokenData[token].sellRateQtyStepFunction, int(qty));
            rate = addBps(rate, extraBps);

             
            extraBps = executeStepFunction(tokenData[token].sellRateImbalanceStepFunction, totalImbalance);
            rate = addBps(rate, extraBps);
        }

        if (abs(totalImbalance + imbalanceQty) >= getMaxTotalImbalance(token)) return 0;
        if (abs(blockImbalance + imbalanceQty) >= getMaxPerBlockImbalance(token)) return 0;

        return rate;
    }
     

    function getBasicRate(ERC20 token, bool buy) public view returns(uint) {
        if (buy)
            return tokenData[token].baseBuyRate;
        else
            return tokenData[token].baseSellRate;
    }

    function getCompactData(ERC20 token) public view returns(uint, uint, byte, byte) {
        uint arrayIndex = tokenData[token].compactDataArrayIndex;
        uint fieldOffset = tokenData[token].compactDataFieldIndex;

        return (
            arrayIndex,
            fieldOffset,
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, true)),
            byte(getRateByteFromCompactData(tokenRatesCompactData[arrayIndex], token, false))
        );
    }

    function getTokenBasicData(ERC20 token) public view returns(bool, bool) {
        return (tokenData[token].listed, tokenData[token].enabled);
    }

     
    function getStepFunctionData(ERC20 token, uint command, uint param) public view returns(int) {
        if (command == 0) return int(tokenData[token].buyRateQtyStepFunction.x.length);
        if (command == 1) return tokenData[token].buyRateQtyStepFunction.x[param];
        if (command == 2) return int(tokenData[token].buyRateQtyStepFunction.y.length);
        if (command == 3) return tokenData[token].buyRateQtyStepFunction.y[param];

        if (command == 4) return int(tokenData[token].sellRateQtyStepFunction.x.length);
        if (command == 5) return tokenData[token].sellRateQtyStepFunction.x[param];
        if (command == 6) return int(tokenData[token].sellRateQtyStepFunction.y.length);
        if (command == 7) return tokenData[token].sellRateQtyStepFunction.y[param];

        if (command == 8) return int(tokenData[token].buyRateImbalanceStepFunction.x.length);
        if (command == 9) return tokenData[token].buyRateImbalanceStepFunction.x[param];
        if (command == 10) return int(tokenData[token].buyRateImbalanceStepFunction.y.length);
        if (command == 11) return tokenData[token].buyRateImbalanceStepFunction.y[param];

        if (command == 12) return int(tokenData[token].sellRateImbalanceStepFunction.x.length);
        if (command == 13) return tokenData[token].sellRateImbalanceStepFunction.x[param];
        if (command == 14) return int(tokenData[token].sellRateImbalanceStepFunction.y.length);
        if (command == 15) return tokenData[token].sellRateImbalanceStepFunction.y[param];

        revert();
    }
     

    function getRateUpdateBlock(ERC20 token) public view returns(uint) {
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];
        return getLast4Bytes(compactData);
    }

    function getListedTokens() public view returns(ERC20[]) {
        return listedTokens;
    }

    function getTokenQty(ERC20 token, uint ethQty, uint rate) internal view returns(uint) {
        uint dstDecimals = token.decimals();
        uint srcDecimals = 18;

        return calcDstQty(ethQty, srcDecimals, dstDecimals, rate);
    }

    function getLast4Bytes(bytes32 b) internal pure returns(uint) {
         
        return uint(b) / (BYTES_14_OFFSET * BYTES_14_OFFSET);
    }

    function getRateByteFromCompactData(bytes32 data, ERC20 token, bool buy) internal view returns(int8) {
        uint fieldOffset = tokenData[token].compactDataFieldIndex;
        uint byteOffset;
        if (buy)
            byteOffset = 32 - NUM_TOKENS_IN_COMPACT_DATA + fieldOffset;
        else
            byteOffset = 4 + fieldOffset;

        return int8(data[byteOffset]);
    }

    function executeStepFunction(StepFunction f, int x) internal pure returns(int) {
        uint len = f.y.length;
        for (uint ind = 0; ind < len; ind++) {
            if (x <= f.x[ind]) return f.y[ind];
        }

        return f.y[len-1];
    }

    function addBps(uint rate, int bps) internal pure returns(uint) {
        uint maxBps = 100 * 100;
        return (rate * uint(int(maxBps) + bps)) / maxBps;
    }

    function abs(int x) internal pure returns(uint) {
        if (x < 0)
            return uint(-1 * x);
        else
            return uint(x);
    }
}