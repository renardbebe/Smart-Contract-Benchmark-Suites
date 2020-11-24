 

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

 

interface ConversionRatesInterface {

    function recordImbalance(
        ERC20 token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public;

    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint);
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

 

interface SanityRatesInterface {
    function getSanityRate(ERC20 src, ERC20 dest) public view returns(uint);
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

 

interface MakerDao {
    function peek() public view returns (bytes32, bool);
}

contract DigixReserve is KyberReserveInterface, Withdrawable, Utils {

    ERC20 public digix;
    MakerDao public makerDaoContract;
    ConversionRatesInterface public conversionRatesContract;
    SanityRatesInterface public sanityRatesContract;
    address public kyberNetwork;
    uint maxBlockDrift = 300;
    mapping(bytes32=>bool) public approvedWithdrawAddresses;  
    uint public priceFeed;
    bool public tradeEnabled;
    uint constant internal POW_2_64 = 2 ** 64;
    uint constant internal etherWei = 10 ** 18;
    uint public buyTransferFee = 13;
    uint public sellTransferFee = 13;


    function DigixReserve(address _admin, address _kyberNetwork, ERC20 _digix) public{
        require(_admin != address(0));
        require(_digix != address(0));
        require(_kyberNetwork != address(0));
        admin = _admin;
        digix = _digix;
        setDecimals(digix);
        kyberNetwork = _kyberNetwork;
        sanityRatesContract = SanityRatesInterface(0);
        conversionRatesContract = ConversionRatesInterface(0x901d);
        tradeEnabled = true;
    }

    function () public payable {}

     
     
     
     
     
     
     
     
    function setPriceFeed(
        uint blockNumber,
        uint nonce,
        uint ask1KDigix,
        uint bid1KDigix,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) public
    {
        uint prevFeedBlock;
        uint prevNonce;
        uint prevAsk;
        uint prevBid;

        (prevFeedBlock, prevNonce, prevAsk, prevBid) = getPriceFeed();
        require(nonce > prevNonce);
        require(blockNumber + maxBlockDrift > block.number);
        require(blockNumber <= block.number);

        require(verifySignature(keccak256(blockNumber, nonce, ask1KDigix, bid1KDigix), v, r, s));

        priceFeed = encodePriceFeed(blockNumber, nonce, ask1KDigix, bid1KDigix);
    }

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) public view returns(uint) {
        if (!tradeEnabled) return 0;
        if (makerDaoContract == MakerDao(0)) return 0;
        uint feedBlock;
        uint nonce;
        uint ask1KDigix;
        uint bid1KDigix;
        blockNumber;

        (feedBlock, nonce, ask1KDigix, bid1KDigix) = getPriceFeed();
        if (feedBlock + maxBlockDrift <= block.number) return 0;

         
        bool isRateValid;
        bytes32 dollarsPerEtherWei;  
        (dollarsPerEtherWei, isRateValid) = makerDaoContract.peek();
        if (!isRateValid || uint(dollarsPerEtherWei) > MAX_RATE) return 0;

        uint rate;
        if (ETH_TOKEN_ADDRESS == src && digix == dest) {
             
            rate = 1000 * uint(dollarsPerEtherWei) * PRECISION / etherWei / ask1KDigix;
        } else if (digix == src && ETH_TOKEN_ADDRESS == dest) {
             
            rate = bid1KDigix * etherWei * PRECISION / uint(dollarsPerEtherWei) / 1000;
        } else {
            return 0;
        }

        if (rate > MAX_RATE) return 0;

        uint destQty = getDestQty(src, dest, srcQty, rate);

        if (getBalance(dest) < destQty) return 0;

 
 
 
 
        return rate;
    }

    function getPriceFeed() public view returns(uint feedBlock, uint nonce, uint ask1KDigix, uint bid1KDigix) {
        (feedBlock, nonce, ask1KDigix, bid1KDigix) = decodePriceFeed(priceFeed);
    }

    event TradeExecute(
        address indexed origin,
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

         
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS) {
                require(msg.value == srcAmount);
                require(ERC20(destToken) == digix);
            } else {
                require(ERC20(srcToken) == digix);
                require(msg.value == 0);
            }
        }

        uint destAmount = getDestQty(srcToken, destToken, srcAmount, conversionRate);
        uint adjustedAmount;
         
        require(destAmount > 0);

         
        if (srcToken != ETH_TOKEN_ADDRESS) {
             
            adjustedAmount = (srcAmount * (10000 - sellTransferFee) / 10000) - 1;
            require(srcToken.transferFrom(msg.sender, this, adjustedAmount));
        }

         
        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(destAmount);
        } else {
             
            adjustedAmount = (destAmount * 10000 / (10000 - buyTransferFee)) + 1;
            require(destToken.transfer(destAddress, adjustedAmount));
        }

        TradeExecute(msg.sender, srcToken, srcAmount, destToken, destAmount, destAddress);

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

    event WithdrawAddressApproved(ERC20 token, address addr, bool approve);

    function approveWithdrawAddress(ERC20 token, address addr, bool approve) public onlyAdmin {
        approvedWithdrawAddresses[keccak256(token, addr)] = approve;
        WithdrawAddressApproved(token, addr, approve);

        setDecimals(token);
    }

    event WithdrawFunds(ERC20 token, uint amount, address destination);

    function withdraw(ERC20 token, uint amount, address destination) public onlyOperator returns(bool) {
        require(approvedWithdrawAddresses[keccak256(token, destination)]);

        if (token == ETH_TOKEN_ADDRESS) {
            destination.transfer(amount);
        } else {
            require(token.transfer(destination, amount));
        }

        WithdrawFunds(token, amount, destination);

        return true;
    }

    function setMakerDaoContract(MakerDao daoContract) public onlyAdmin{
        require(daoContract != address(0));
        makerDaoContract = daoContract;
    }

    function setKyberNetworkAddress(address _kyberNetwork) public onlyAdmin{
        require(_kyberNetwork != address(0));
        kyberNetwork = _kyberNetwork;
    }

    function setMaxBlockDrift(uint numBlocks) public onlyAdmin {
        require(numBlocks > 1);
        maxBlockDrift = numBlocks;
    }

    function setBuyFeeBps(uint fee) public onlyAdmin {
        require(fee < 10000);
        buyTransferFee = fee;
    }

    function setSellFeeBps(uint fee) public onlyAdmin {
        require(fee < 10000);
        sellTransferFee = fee;
    }

    function getBalance(ERC20 token) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return this.balance;
        else
            return token.balanceOf(this);
    }

    function getDestQty(ERC20 src, ERC20 dest, uint srcQty, uint rate) public view returns(uint) {
        uint dstDecimals = getDecimals(dest);
        uint srcDecimals = getDecimals(src);
        return calcDstQty(srcQty, srcDecimals, dstDecimals, rate);
    }

    function decodePriceFeed(uint input) internal pure returns(uint blockNumber, uint nonce, uint ask1KDigix, uint bid1KDigix) {
        blockNumber = uint(uint64(input));
        nonce = uint(uint64(input / POW_2_64));
        ask1KDigix = uint(uint64(input / (POW_2_64 * POW_2_64)));
        bid1KDigix = uint(uint64(input / (POW_2_64 * POW_2_64 * POW_2_64)));
    }

    function encodePriceFeed(uint blockNumber, uint nonce, uint ask1KDigix, uint bid1KDigix) internal pure returns(uint) {
         
        require(blockNumber < POW_2_64);
        require(nonce < POW_2_64);
        require(ask1KDigix < POW_2_64);
        require(bid1KDigix < POW_2_64);

         
        uint result = blockNumber;
        result |= nonce * POW_2_64;
        result |= ask1KDigix * POW_2_64 * POW_2_64;
        result |= bid1KDigix * POW_2_64 * POW_2_64 * POW_2_64;

        return result;
    }

    function verifySignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(bool){
        address signer = ecrecover(hash, v, r, s);
        return operators[signer];
    }

}