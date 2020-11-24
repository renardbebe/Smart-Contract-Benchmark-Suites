 

pragma solidity ^0.4.22;

 

 
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

interface SupplierInterface {

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        external
        payable
        returns(bool);

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}

 

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal quoters;
    address[] internal operatorsGroup;
    address[] internal quotersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    constructor() public {
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

    modifier onlyQuoter() {
        require(quoters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[]) {
        return operatorsGroup;
    }

    function getQuoters () external view returns(address[]) {
        return quotersGroup;
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

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]);  
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        emit OperatorAdded(newOperator, true);
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
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }

    event QuoterAdded (address newQuoter, bool isAdd);

    function addQuoter(address newQuoter) public onlyAdmin {
        require(!quoters[newQuoter]);  
        require(quotersGroup.length < MAX_GROUP_SIZE);

        emit QuoterAdded(newQuoter, true);
        quoters[newQuoter] = true;
        quotersGroup.push(newQuoter);
    }

    function removeQuoter (address alerter) public onlyAdmin {
        require(quoters[alerter]);
        quoters[alerter] = false;

        for (uint i = 0; i < quotersGroup.length; ++i) {
            if (quotersGroup[i] == alerter) {
                quotersGroup[i] = quotersGroup[quotersGroup.length - 1];
                quotersGroup.length--;
                emit QuoterAdded(alerter, false);
                break;
            }
        }
    }
}

 

 
contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

     
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

     
    function withdrawEther(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

 

 
contract Base {

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

 

contract WhiteListInterface {
    function getUserCapInWei(address user) external view returns (uint userCapWei);
}

 

interface ExpectedRateInterface {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);
}

 

contract MartletInstantlyTrader is Withdrawable, Base {

    uint public negligibleRateDiff = 10;  
    SupplierInterface[] public suppliers;
    mapping(address=>bool) public isSupplier;
    WhiteListInterface public whiteListContract;
    ExpectedRateInterface public expectedRateContract;
    mapping(address=>bool) validateCodeTokens;
    uint                  public maxGasPrice = 50 * 1000 * 1000 * 1000;  
    uint                  internal validBlkNum = 256; 
    bool                  public enabled = false;  
    mapping(bytes32=>uint) public info;  
    mapping(address=>mapping(bytes32=>bool)) public perSupplierListedPairs;
    uint    internal  quoteKey = 0;

    constructor (address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    event EtherReceival(address indexed sender, uint amount);

     
    function() public payable {
        require(isSupplier[msg.sender]);
        emit EtherReceival(msg.sender, msg.value);
    }
     

    event LogCode(bytes32 bs);
    event ExecuteTrade(address indexed sender, ERC20 src, ERC20 dest, uint actualSrcAmount, uint actualDestAmount);

     
     
     
     
     
     
     
     
     
     
     
     
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        uint rate100,
        uint sn,
        bytes32 code
        
    )
        public
        payable
        returns(uint)
    {
        require(enabled);
        require(validateTradeInput(src, srcAmount, dest, destAddress, rate100, sn, code));

        uint userSrcBalanceBefore;
        uint userDestBalanceBefore;

        userSrcBalanceBefore = getBalance(src, msg.sender);
        if (src == ETH_TOKEN_ADDRESS)
            userSrcBalanceBefore += msg.value;
        userDestBalanceBefore = getBalance(dest, destAddress);

         
         
        uint actualDestAmount = doTrade(src,
                                        srcAmount,
                                        dest,
                                        destAddress,
                                        maxDestAmount,
                                        minConversionRate,
                                        rate100
                                        );
        require(actualDestAmount > 0);
        require(checkBalance(src, dest, destAddress, userSrcBalanceBefore, userDestBalanceBefore, minConversionRate));
        return actualDestAmount;
}

function checkBalance(ERC20 src, ERC20 dest, address destAddress,
    uint userSrcBalanceBefore, 
    uint userDestBalanceBefore, 
    uint minConversionRate) internal view returns(bool)
{
    uint userSrcBalanceAfter = getBalance(src, msg.sender);
    uint userDestBalanceAfter = getBalance(dest, destAddress);

    if(userSrcBalanceAfter > userSrcBalanceBefore){
        return false;
    }
    if(userDestBalanceAfter < userDestBalanceBefore){
        return false;
    }

    return (userDestBalanceAfter - userDestBalanceBefore) >=
        calcDstQty((userSrcBalanceBefore - userSrcBalanceAfter), getDecimals(src), getDecimals(dest), minConversionRate);
}

    event AddSupplier(SupplierInterface supplier, bool add);

     
     
     
     
    function addSupplier(SupplierInterface supplier, bool add) public onlyAdmin {

        if (add) {
            require(!isSupplier[supplier]);
            suppliers.push(supplier);
            isSupplier[supplier] = true;
            emit AddSupplier(supplier, true);
        } else {
            isSupplier[supplier] = false;
            for (uint i = 0; i < suppliers.length; i++) {
                if (suppliers[i] == supplier) {
                    suppliers[i] = suppliers[suppliers.length - 1];
                    suppliers.length--;
                    emit AddSupplier(supplier, false);
                    break;
                }
            }
        }
    }

    event ListSupplierPairs(address supplier, ERC20 src, ERC20 dest, bool add);

     
     
     
     
     
     
    function listPairForSupplier(address supplier, ERC20 src, ERC20 dest, bool add) public onlyAdmin {
        (perSupplierListedPairs[supplier])[keccak256(src, dest)] = add;

        if (src != ETH_TOKEN_ADDRESS) {
            if (add) {
                src.approve(supplier, 2**255);  
                 
            } else {
                src.approve(supplier, 0);
            }
        }

        setDecimals(src);
        setDecimals(dest);

        emit ListSupplierPairs(supplier, src, dest, add);
    }

    function setParams(
        WhiteListInterface    _whiteList,
        ExpectedRateInterface _expectedRate,
        uint                  _maxGasPrice,
        uint                  _negligibleRateDiff,
        uint                  _validBlkNum
    )
        public
        onlyAdmin
    {
        require(_whiteList != address(0));
        require(_expectedRate != address(0));
        require(_negligibleRateDiff <= 100 * 100);  
        require( _validBlkNum > 1 && _validBlkNum < 256);
        
        whiteListContract = _whiteList;
        expectedRateContract = _expectedRate;
        maxGasPrice = _maxGasPrice;
        negligibleRateDiff = _negligibleRateDiff;
        validBlkNum = _validBlkNum;
    }

    function setEnable(bool _enable) public onlyAdmin {
        if (_enable) {
            require(whiteListContract != address(0));
            require(expectedRateContract != address(0));
        }
        enabled = _enable;
    }

    function setQuoteKey(uint _quoteKey) public onlyOperator{
        require(_quoteKey > 0, "quoteKey must greater than 0!");
        quoteKey = _quoteKey;
    }

    function getQuoteKey() public onlyOperator view returns(uint){
        return quoteKey;
    }

    function setInfo(bytes32 field, uint value) public onlyOperator {
        info[field] = value;
    }

     
     
    function getNumSuppliers() public view returns(uint) {
        return suppliers.length;
    }

     
     
     
    function getSuppliers() public view returns(SupplierInterface[]) {
        return suppliers;
    }

     
     
     
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

     
     
     
     
     
    function findBestRate(ERC20 src, ERC20 dest, uint srcQty) public view returns(uint, uint) {
        uint bestRate = 0;
        uint bestSupplier = 0;
        uint numRelevantSuppliers = 0;
        uint numSuppliers = suppliers.length;
        uint[] memory rates = new uint[](numSuppliers);
        uint[] memory supplierCandidates = new uint[](numSuppliers);

        for (uint i = 0; i < numSuppliers; i++) {
             
            if (!(perSupplierListedPairs[suppliers[i]])[keccak256(src, dest)]) continue;

            rates[i] = suppliers[i].getConversionRate(src, dest, srcQty, block.number);

            if (rates[i] > bestRate) {
                 
                bestRate = rates[i];
            }
        }

        if (bestRate > 0) {
            uint random = 0;
            uint smallestRelevantRate = (bestRate * 10000) / (10000 + negligibleRateDiff);

            for (i = 0; i < numSuppliers; i++) {
                if (rates[i] >= smallestRelevantRate) {
                    supplierCandidates[numRelevantSuppliers++] = i;
                }
            }

            if (numRelevantSuppliers > 1) {
                 
                random = uint(blockhash(block.number-1)) % numRelevantSuppliers;
            }

            bestSupplier = supplierCandidates[random];
            bestRate = rates[bestSupplier];
        }

        return (bestSupplier, bestRate);
    }
     

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty)
        public view
        returns (uint expectedRate, uint slippageRate)
    {
        require(expectedRateContract != address(0));
        return expectedRateContract.getExpectedRate(src, dest, srcQty);
    }

    function getUserCapInWei(address user) public view returns(uint) {
        return whiteListContract.getUserCapInWei(user);
    }

     

    function doTrade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        uint rate100
    )
        internal
        returns(uint)
    {
        require(tx.gasprice <= maxGasPrice);

        uint supplierInd;
        uint rate;

        (supplierInd, rate) = findBestRate(src, dest, srcAmount);
        SupplierInterface theSupplier = suppliers[supplierInd];
        require(rate > 0 && rate < MAX_RATE);
        if (validateCodeTokens[src] || validateCodeTokens[dest]){
            require(rate100 > 0 && rate100 >= minConversionRate && rate100 < MAX_RATE);
            rate = rate100;
        }
        else{
            require(rate >= minConversionRate);
        }

        uint actualSrcAmount = srcAmount;
        uint actualDestAmount = calcDestAmount(src, dest, actualSrcAmount, rate100);
        if (actualDestAmount > maxDestAmount) {
            actualDestAmount = maxDestAmount;
            actualSrcAmount = calcSrcAmount(src, dest, actualDestAmount, rate100);
            require(actualSrcAmount <= srcAmount);
        }

         
         
        uint ethAmount;
        if (src == ETH_TOKEN_ADDRESS) {
            ethAmount = actualSrcAmount;
        } else {
            ethAmount = actualDestAmount;
        }

        require(ethAmount <= getUserCapInWei(msg.sender));
        require(doSupplierTrade(src, actualSrcAmount, dest, destAddress, actualDestAmount, theSupplier, rate, true));

        if ((actualSrcAmount < srcAmount) && (src == ETH_TOKEN_ADDRESS)) {
            msg.sender.transfer(srcAmount - actualSrcAmount);
        }


        emit ExecuteTrade(msg.sender, src, dest, actualSrcAmount, actualDestAmount);
        return actualDestAmount;
    }

     
     
     
     
     
     
     
     
     
    function doSupplierTrade(
        ERC20 src,
        uint amount,
        ERC20 dest,
        address destAddress,
        uint expectedDestAmount,
        SupplierInterface supplier,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        uint callValue = 0;
        
        if (src == ETH_TOKEN_ADDRESS) {
            callValue = amount;
        } else {
             
            require(src.transferFrom(msg.sender, this, amount));
        }

         

        require(supplier.trade.value(callValue)(src, amount, dest, this, conversionRate, validate));
        emit SupplierTrade(callValue, src, amount, dest, this, conversionRate, validate);

        if (dest == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(expectedDestAmount);
        } else {
            require(dest.transfer(destAddress, expectedDestAmount));
        }

        return true;
    }

    event SupplierTrade(uint v, ERC20 src, uint amnt, ERC20 dest, address destAddress, uint conversionRate, bool validate);

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function setValidateCodeTokens(ERC20 token, bool add) public onlyAdmin{
        if (add){
            require(!validateCodeTokens[token]);
            validateCodeTokens[token] = true;
        }
        else{
            require(validateCodeTokens[token]);
            delete validateCodeTokens[token];
        }
    }

     
     
     
     
     
    function validateTradeInput(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint rate, uint sn, bytes32 code) internal view returns(bool) {
        if (validateCodeTokens[src] || validateCodeTokens[dest]){
            if(sn > block.number || block.number - sn > validBlkNum)
            {
                return false;
            }
            if(keccak256(rate, sn, quoteKey) != code){
                return false;
            }
        }
        if ((srcAmount >= MAX_QTY) || (srcAmount == 0) || (destAddress == 0))
            return false;

        if (src == ETH_TOKEN_ADDRESS) {
            if (msg.value != srcAmount)
                return false;
        } else {
            if ((msg.value != 0) || (src.allowance(msg.sender, this) < srcAmount))
                return false;
        }

        return true;
    }
}