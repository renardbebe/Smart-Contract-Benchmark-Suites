 

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

 

contract ConversionRateWrapperInterface {
    function setQtyStepFunction(ERC20 token, int[] xBuy, int[] yBuy, int[] xSell, int[] ySell) public;
    function setImbalanceStepFunction(ERC20 token, int[] xBuy, int[] yBuy, int[] xSell, int[] ySell) public;
    function claimAdmin() public;
    function addOperator(address newOperator) public;
    function transferAdmin(address newAdmin) public;
    function addToken(ERC20 token) public;
    function setTokenControlInfo(
            ERC20 token,
            uint minimalRecordResolution,
            uint maxPerBlockImbalance,
            uint maxTotalImbalance
        ) public;
    function enableTokenTrade(ERC20 token) public;
    function getTokenControlInfo(ERC20 token) public view returns(uint, uint, uint);
}

contract WrapConversionRate is Withdrawable {

    ConversionRateWrapperInterface conversionRates;

     
    ERC20 public addTokenPendingToken;
    uint addTokenPendingMinimalResolution;  
    uint addTokenPendingMaxPerBlockImbalance;  
    uint addTokenPendingMaxTotalImbalance;
    address[] public addTokenApproveSignatures;
    
     
    ERC20[] public setTokenInfoPendingTokenList;
    uint[]  public setTokenInfoPendingPerBlockImbalance;  
    uint[]  public setTokenInfoPendingMaxTotalImbalance;
    address[] public setTokenInfoApproveSignatures;

    function WrapConversionRate(ConversionRateWrapperInterface _conversionRates, address _admin) public {
        require (_conversionRates != address(0));
        require (_admin != address(0));
        conversionRates = _conversionRates;
        admin = _admin;
    }

    function claimWrappedContractAdmin() public onlyAdmin {
        conversionRates.claimAdmin();
        conversionRates.addOperator(this);
    }

    function transferWrappedContractAdmin (address newAdmin) public onlyAdmin {
        conversionRates.transferAdmin(newAdmin);
    }

     
     
    function addTokenToApprove(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) public onlyOperator {
        require(minimalRecordResolution != 0);
        require(maxPerBlockImbalance != 0);
        require(maxTotalImbalance != 0);
        require(token != address(0));

         
        addTokenApproveSignatures.length = 0;
        addTokenPendingToken = token;
        addTokenPendingMinimalResolution = minimalRecordResolution;  
        addTokenPendingMaxPerBlockImbalance = maxPerBlockImbalance;  
        addTokenPendingMaxTotalImbalance = maxTotalImbalance;
         
    }

    function approveAddToken() public onlyOperator {
        for(uint i = 0; i < addTokenApproveSignatures.length; i++) {
            if (msg.sender == addTokenApproveSignatures[i]) require(false);
        }
        addTokenApproveSignatures.push(msg.sender);

        if (addTokenApproveSignatures.length == operatorsGroup.length) {
             
            performAddToken();
        }
 
    }

    function performAddToken() internal {
        conversionRates.addToken(addTokenPendingToken);

         
        conversionRates.setTokenControlInfo(
            addTokenPendingToken,
            addTokenPendingMinimalResolution,
            addTokenPendingMaxPerBlockImbalance,
            addTokenPendingMaxTotalImbalance
        );

         
        int[] memory zeroArr = new int[](1);
        zeroArr[0] = 0;

        conversionRates.setQtyStepFunction(addTokenPendingToken, zeroArr, zeroArr, zeroArr, zeroArr);
        conversionRates.setImbalanceStepFunction(addTokenPendingToken, zeroArr, zeroArr, zeroArr, zeroArr);

        conversionRates.enableTokenTrade(addTokenPendingToken);
    }

    function getAddTokenParameters() public view returns(ERC20 token, uint minimalRecordResolution, uint maxPerBlockImbalance, uint maxTotalImbalance) {
        token = addTokenPendingToken;
        minimalRecordResolution = addTokenPendingMinimalResolution;
        maxPerBlockImbalance = addTokenPendingMaxPerBlockImbalance;  
        maxTotalImbalance = addTokenPendingMaxTotalImbalance;
    }
    
     
     
    function tokenInfoSetPendingTokens(ERC20 [] tokens) public onlyOperator {
        setTokenInfoApproveSignatures.length = 0;
        setTokenInfoPendingTokenList = tokens;
    }

    function tokenInfoSetMaxPerBlockImbalanceList(uint[] maxPerBlockImbalanceValues) public onlyOperator {
        require(maxPerBlockImbalanceValues.length == setTokenInfoPendingTokenList.length);
        setTokenInfoApproveSignatures.length = 0;
        setTokenInfoPendingPerBlockImbalance = maxPerBlockImbalanceValues;
    }

    function tokenInfoSetMaxTotalImbalanceList(uint[] maxTotalImbalanceValues) public onlyOperator {
        require(maxTotalImbalanceValues.length == setTokenInfoPendingTokenList.length);
        setTokenInfoApproveSignatures.length = 0;
        setTokenInfoPendingMaxTotalImbalance = maxTotalImbalanceValues;
    }

    function approveSetTokenControlInfo() public onlyOperator {
        for(uint i = 0; i < setTokenInfoApproveSignatures.length; i++) {
            if (msg.sender == setTokenInfoApproveSignatures[i]) require(false);
        }
        setTokenInfoApproveSignatures.push(msg.sender);

        if (setTokenInfoApproveSignatures.length == operatorsGroup.length) {
             
            performSetTokenControlInfo();
        }
    }

    function performSetTokenControlInfo() internal {
        require(setTokenInfoPendingTokenList.length == setTokenInfoPendingPerBlockImbalance.length);
        require(setTokenInfoPendingTokenList.length == setTokenInfoPendingMaxTotalImbalance.length);

        uint minimalRecordResolution;
        uint rxMaxPerBlockImbalance;
        uint rxMaxTotalImbalance;

        for (uint i = 0; i < setTokenInfoPendingTokenList.length; i++) {
            (minimalRecordResolution, rxMaxPerBlockImbalance, rxMaxTotalImbalance) =
                conversionRates.getTokenControlInfo(setTokenInfoPendingTokenList[i]);
            require(minimalRecordResolution != 0);

            conversionRates.setTokenControlInfo(setTokenInfoPendingTokenList[i],
                                                minimalRecordResolution,
                                                setTokenInfoPendingPerBlockImbalance[i],
                                                setTokenInfoPendingMaxTotalImbalance[i]);
        }
    }

    function getControlInfoTokenlist() public view returns(ERC20[] tokens) {
        tokens = setTokenInfoPendingTokenList;
    }

    function getControlInfoMaxPerBlockImbalanceList() public view returns(uint[] maxPerBlockImbalanceValues) {
        maxPerBlockImbalanceValues = setTokenInfoPendingPerBlockImbalance;
    }

    function getControlInfoMaxTotalImbalanceList() public view returns(uint[] maxTotalImbalanceValues) {
        maxTotalImbalanceValues = setTokenInfoPendingMaxTotalImbalance;
    }
}