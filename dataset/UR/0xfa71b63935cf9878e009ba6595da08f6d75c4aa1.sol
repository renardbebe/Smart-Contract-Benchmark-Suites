 

pragma solidity 0.4.18;

 

 
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

 

 
contract ReentrancyGuard {

     
    uint256 private guardCounter = 1;

     
    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter);
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

 

interface KyberNetwork {
    function tradeWithHint(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes hint)
    external
    payable
    returns(uint);
}


contract KyberPayWrapper is Withdrawable, ReentrancyGuard {
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    struct PayData {
        ERC20 src;
        uint srcAmount;
        ERC20 dest;
        address destAddress;
        uint maxDestAmount;
        uint minConversionRate;
        address walletId;
        bytes paymentData;
        bytes hint;
        KyberNetwork kyberNetworkProxy;
    }

    function () public payable {}  

    event ProofOfPayment(address indexed _payer, address indexed _payee, address _token, uint _amount, bytes _data);

    function pay(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes paymentData,
        bytes hint,
        KyberNetwork kyberNetworkProxy
    ) public nonReentrant payable
    {

        require(src != address(0));
        require(dest != address(0));
        require(destAddress != address(0));

        if (src == ETH_TOKEN_ADDRESS) require(srcAmount == msg.value);

        PayData memory payData = PayData({
            src:src,
            srcAmount:srcAmount,
            dest:dest,
            destAddress:destAddress,
            maxDestAmount:maxDestAmount,
            minConversionRate:minConversionRate,
            walletId:walletId,
            paymentData:paymentData,
            hint:hint,
            kyberNetworkProxy:kyberNetworkProxy
        });

        uint paidAmount = (src == dest) ? doPayWithoutKyber(payData) : doPayWithKyber(payData);

         
        ProofOfPayment(msg.sender ,destAddress, dest, paidAmount, paymentData);
    }

    function doPayWithoutKyber(PayData memory payData) internal returns (uint paidAmount) {

        uint returnAmount;

        if (payData.srcAmount > payData.maxDestAmount) {
            paidAmount = payData.maxDestAmount;
            returnAmount = payData.srcAmount - payData.maxDestAmount;
        } else {
            paidAmount = payData.srcAmount;
            returnAmount = 0;
        }

        if (payData.src == ETH_TOKEN_ADDRESS) {
            payData.destAddress.transfer(paidAmount);

             
            if (returnAmount > 0) msg.sender.transfer(returnAmount);
        } else {
            require(payData.src.transferFrom(msg.sender, payData.destAddress, paidAmount));
        }
    }

    function doPayWithKyber(PayData memory payData) internal returns (uint paidAmount) {

        uint returnAmount;
        uint wrapperSrcBalanceBefore;
        uint destAddressBalanceBefore;
        uint wrapperSrcBalanceAfter;
        uint destAddressBalanceAfter;
        uint srcAmountUsed;

        if (payData.src != ETH_TOKEN_ADDRESS) {
            require(payData.src.transferFrom(msg.sender, address(this), payData.srcAmount));
            require(payData.src.approve(payData.kyberNetworkProxy, 0));
            require(payData.src.approve(payData.kyberNetworkProxy, payData.srcAmount));
        }

        (wrapperSrcBalanceBefore, destAddressBalanceBefore) = getBalances(
            payData.src,
            payData.dest,
            payData.destAddress
        );

        paidAmount = doTradeWithHint(payData);
        if (payData.src != ETH_TOKEN_ADDRESS) require(payData.src.approve(payData.kyberNetworkProxy, 0));

        (wrapperSrcBalanceAfter, destAddressBalanceAfter) = getBalances(payData.src, payData.dest, payData.destAddress);

         
        require(destAddressBalanceAfter > destAddressBalanceBefore);
        require(paidAmount == (destAddressBalanceAfter - destAddressBalanceBefore));

         
        require(wrapperSrcBalanceBefore >= wrapperSrcBalanceAfter);
        srcAmountUsed = wrapperSrcBalanceBefore - wrapperSrcBalanceAfter;

        require(payData.srcAmount >= srcAmountUsed);
        returnAmount = payData.srcAmount - srcAmountUsed;

         
        if (returnAmount > 0) {
            if (payData.src == ETH_TOKEN_ADDRESS) {
                msg.sender.transfer(returnAmount);
            } else {
                require(payData.src.transfer(msg.sender, returnAmount));
            }
        }
    }

    function doTradeWithHint(PayData memory payData) internal returns (uint paidAmount) {
        paidAmount = payData.kyberNetworkProxy.tradeWithHint.value(msg.value)({
            src:payData.src,
            srcAmount:payData.srcAmount,
            dest:payData.dest,
            destAddress:payData.destAddress,
            maxDestAmount:payData.maxDestAmount,
            minConversionRate:payData.minConversionRate,
            walletId:payData.walletId,
            hint:payData.hint
        });
    }

    function getBalances (ERC20 src, ERC20 dest, address destAddress)
        internal
        view
        returns (uint wrapperSrcBalance, uint destAddressBalance)
    {
        if (src == ETH_TOKEN_ADDRESS) {
            wrapperSrcBalance = address(this).balance;
        } else {
            wrapperSrcBalance = src.balanceOf(address(this));
        }

        if (dest == ETH_TOKEN_ADDRESS) {
            destAddressBalance = destAddress.balance;
        } else {
            destAddressBalance = dest.balanceOf(destAddress);
        }
    } 
}