 

pragma solidity 0.4.18;

 

interface FeeBurnerInterface {
    function handleFees (uint tradeWeiAmount, address reserve, address wallet) public returns(bool);
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

 

interface BurnableToken {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function burnFrom(address _from, uint256 _value) public returns (bool);
}


contract FeeBurner is Withdrawable, FeeBurnerInterface, Utils {

    mapping(address=>uint) public reserveFeesInBps;
    mapping(address=>address) public reserveKNCWallet;  
    mapping(address=>uint) public walletFeesInBps;  
    mapping(address=>uint) public reserveFeeToBurn;
    mapping(address=>uint) public feePayedPerReserve;  
    mapping(address=>mapping(address=>uint)) public reserveFeeToWallet;
    address public taxWallet;
    uint public taxFeeBps = 0;  

    BurnableToken public knc;
    address public kyberNetwork;
    uint public kncPerETHRate = 300;

    function FeeBurner(address _admin, BurnableToken kncToken, address _kyberNetwork) public {
        require(_admin != address(0));
        require(kncToken != address(0));
        require(_kyberNetwork != address(0));
        kyberNetwork = _kyberNetwork;
        admin = _admin;
        knc = kncToken;
    }

    event ReserveDataSet(address reserve, uint feeInBps, address kncWallet);
    function setReserveData(address reserve, uint feesInBps, address kncWallet) public onlyAdmin {
        require(feesInBps < 100);  
        require(kncWallet != address(0));
        reserveFeesInBps[reserve] = feesInBps;
        reserveKNCWallet[reserve] = kncWallet;
        ReserveDataSet(reserve, feesInBps, kncWallet);
    }

    event WalletFeesSet(address wallet, uint feesInBps);
    function setWalletFees(address wallet, uint feesInBps) public onlyAdmin {
        require(feesInBps < 10000);  
        walletFeesInBps[wallet] = feesInBps;
        WalletFeesSet(wallet, feesInBps);
    }

    event TaxFeesSet(uint feesInBps);
    function setTaxInBps(uint _taxFeeBps) public onlyAdmin {
        require(_taxFeeBps < 10000);  
        taxFeeBps = _taxFeeBps;
        TaxFeesSet(_taxFeeBps);
    }

    event TaxWalletSet(address taxWallet);
    function setTaxWallet(address _taxWallet) public onlyAdmin {
        require(_taxWallet != address(0));
        taxWallet = _taxWallet;
        TaxWalletSet(_taxWallet);
    }

    function setKNCRate(uint rate) public onlyAdmin {
        require(rate <= MAX_RATE);
        kncPerETHRate = rate;
    }

    event AssignFeeToWallet(address reserve, address wallet, uint walletFee);
    event AssignBurnFees(address reserve, uint burnFee);

    function handleFees(uint tradeWeiAmount, address reserve, address wallet) public returns(bool) {
        require(msg.sender == kyberNetwork);
        require(tradeWeiAmount <= MAX_QTY);
        require(kncPerETHRate <= MAX_RATE);

        uint kncAmount = tradeWeiAmount * kncPerETHRate;
        uint fee = kncAmount * reserveFeesInBps[reserve] / 10000;

        uint walletFee = fee * walletFeesInBps[wallet] / 10000;
        require(fee >= walletFee);
        uint feeToBurn = fee - walletFee;

        if (walletFee > 0) {
            reserveFeeToWallet[reserve][wallet] += walletFee;
            AssignFeeToWallet(reserve, wallet, walletFee);
        }

        if (feeToBurn > 0) {
            AssignBurnFees(reserve, feeToBurn);
            reserveFeeToBurn[reserve] += feeToBurn;
        }

        return true;
    }

    event BurnAssignedFees(address indexed reserve, address sender, uint quantity);

    event SendTaxFee(address indexed reserve, address sender, address taxWallet, uint quantity);

     
    function burnReserveFees(address reserve) public {
        uint burnAmount = reserveFeeToBurn[reserve];
        uint taxToSend = 0;
        require(burnAmount > 2);
        reserveFeeToBurn[reserve] = 1;  
        if (taxWallet != address(0) && taxFeeBps != 0) {
            taxToSend = (burnAmount - 1) * taxFeeBps / 10000;
            require(burnAmount - 1 > taxToSend);
            burnAmount -= taxToSend;
            if (taxToSend > 0) {
                require(knc.transferFrom(reserveKNCWallet[reserve], taxWallet, taxToSend));
                SendTaxFee(reserve, msg.sender, taxWallet, taxToSend);
            }
        }
        require(knc.burnFrom(reserveKNCWallet[reserve], burnAmount - 1));

         
        feePayedPerReserve[reserve] += (taxToSend + burnAmount - 1);

        BurnAssignedFees(reserve, msg.sender, (burnAmount - 1));
    }

    event SendWalletFees(address indexed wallet, address reserve, address sender);

     
    function sendFeeToWallet(address wallet, address reserve) public {
        uint feeAmount = reserveFeeToWallet[reserve][wallet];
        require(feeAmount > 1);
        reserveFeeToWallet[reserve][wallet] = 1;  
        require(knc.transferFrom(reserveKNCWallet[reserve], wallet, feeAmount - 1));

        feePayedPerReserve[reserve] += (feeAmount - 1);
        SendWalletFees(wallet, reserve, msg.sender);
    }
}