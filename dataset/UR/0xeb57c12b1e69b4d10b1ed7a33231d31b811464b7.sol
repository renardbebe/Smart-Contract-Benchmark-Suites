 

pragma solidity 0.4.24;

 

 

pragma solidity 0.4.24;


contract Restricted {

     
    mapping (address => mapping (bytes32 => bool)) public permissions;

    event PermissionGranted(address indexed agent, bytes32 grantedPermission);
    event PermissionRevoked(address indexed agent, bytes32 revokedPermission);

    modifier restrict(bytes32 requiredPermission) {
        require(permissions[msg.sender][requiredPermission], "msg.sender must have permission");
        _;
    }

    constructor(address permissionGranterContract) public {
        require(permissionGranterContract != address(0), "permissionGranterContract must be set");
        permissions[permissionGranterContract]["PermissionGranter"] = true;
        emit PermissionGranted(permissionGranterContract, "PermissionGranter");
    }

    function grantPermission(address agent, bytes32 requiredPermission) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        permissions[agent][requiredPermission] = true;
        emit PermissionGranted(agent, requiredPermission);
    }

    function grantMultiplePermissions(address agent, bytes32[] requiredPermissions) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        uint256 length = requiredPermissions.length;
        for (uint256 i = 0; i < length; i++) {
            grantPermission(agent, requiredPermissions[i]);
        }
    }

    function revokePermission(address agent, bytes32 requiredPermission) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        permissions[agent][requiredPermission] = false;
        emit PermissionRevoked(agent, requiredPermission);
    }

    function revokeMultiplePermissions(address agent, bytes32[] requiredPermissions) public {
        uint256 length = requiredPermissions.length;
        for (uint256 i = 0; i < length; i++) {
            revokePermission(agent, requiredPermissions[i]);
        }
    }

}

 

 
pragma solidity 0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0");  
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

     
    function roundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0");  
        uint256 halfB = (b % 2 == 0) ? (b / 2) : (b / 2 + 1);
        return (a % b >= halfB) ? (a / b + 1) : (a / b);
    }

     
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0");  
        return (a % b != 0) ? (a / b + 1) : (a / b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }    
}

 

 
pragma solidity 0.4.24;


interface TransferFeeInterface {
    function calculateTransferFee(address from, address to, uint amount) external view returns (uint256 fee);
}

 

 
pragma solidity 0.4.24;


interface ERC20Interface {
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed from, address indexed to, uint amount);

    function transfer(address to, uint value) external returns (bool);  
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address who) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint remaining);

}

 

 
pragma solidity 0.4.24;


interface TokenReceiver {
    function transferNotification(address from, uint256 amount, uint data) external;
}

 

 
pragma solidity 0.4.24;







contract AugmintTokenInterface is Restricted, ERC20Interface {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    bytes32 public peggedSymbol;
    uint8 public decimals;

    uint public totalSupply;
    mapping(address => uint256) public balances;  
    mapping(address => mapping (address => uint256)) public allowed;  

    TransferFeeInterface public feeAccount;
    mapping(bytes32 => bool) public delegatedTxHashesUsed;  

    event TransferFeesChanged(uint transferFeePt, uint transferFeeMin, uint transferFeeMax);
    event Transfer(address indexed from, address indexed to, uint amount);
    event AugmintTransfer(address indexed from, address indexed to, uint amount, string narrative, uint fee);
    event TokenIssued(uint amount);
    event TokenBurned(uint amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address to, uint value) external returns (bool);  
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);

    function delegatedTransfer(address from, address to, uint amount, string narrative,
                                    uint maxExecutorFeeInToken,  
                                    bytes32 nonce,  
                                     
                                    bytes signature,
                                    uint requestedExecutorFeeInToken  
                                ) external;

    function delegatedTransferAndNotify(address from, TokenReceiver target, uint amount, uint data,
                                    uint maxExecutorFeeInToken,  
                                    bytes32 nonce,  
                                     
                                    bytes signature,
                                    uint requestedExecutorFeeInToken  
                                ) external;

    function increaseApproval(address spender, uint addedValue) external;
    function decreaseApproval(address spender, uint subtractedValue) external;

    function issueTo(address to, uint amount) external;  
    function burn(uint amount) external;

    function transferAndNotify(TokenReceiver target, uint amount, uint data) external;

    function transferWithNarrative(address to, uint256 amount, string narrative) external;
    function transferFromWithNarrative(address from, address to, uint256 amount, string narrative) external;

    function setName(string _name) external;
    function setSymbol(string _symbol) external;

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address who) external view returns (uint);


}

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}

 

 
pragma solidity 0.4.24;






contract AugmintToken is AugmintTokenInterface {

    event FeeAccountChanged(TransferFeeInterface newFeeAccount);

    constructor(address permissionGranterContract, string _name, string _symbol, bytes32 _peggedSymbol, uint8 _decimals, TransferFeeInterface _feeAccount)
    public Restricted(permissionGranterContract) {
        require(_feeAccount != address(0), "feeAccount must be set");
        require(bytes(_name).length > 0, "name must be set");
        require(bytes(_symbol).length > 0, "symbol must be set");

        name = _name;
        symbol = _symbol;
        peggedSymbol = _peggedSymbol;
        decimals = _decimals;

        feeAccount = _feeAccount;

    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount, "");
        return true;
    }

     
    function delegatedTransfer(address from, address to, uint amount, string narrative,
                                     uint maxExecutorFeeInToken,  
                                     bytes32 nonce,  
                                      
                                     bytes signature,
                                     uint requestedExecutorFeeInToken  
                                     )
    external {
        bytes32 txHash = keccak256(abi.encodePacked(this, from, to, amount, narrative, maxExecutorFeeInToken, nonce));

        _checkHashAndTransferExecutorFee(txHash, signature, from, maxExecutorFeeInToken, requestedExecutorFeeInToken);

        _transfer(from, to, amount, narrative);
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        require(_spender != 0x0, "spender must be set");
        allowed[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) external {
        require(_spender != 0x0, "spender must be set");
        mapping (address => uint256) allowances = allowed[msg.sender];
        uint newValue = allowances[_spender].add(_addedValue);
        allowances[_spender] = newValue;
        emit Approval(msg.sender, _spender, newValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) external {
        require(_spender != 0x0, "spender must be set");
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _transferFrom(from, to, amount, "");
        return true;
    }

     
     
     
     
    function issueTo(address to, uint amount) external restrict("MonetarySupervisor") {
        balances[to] = balances[to].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Transfer(0x0, to, amount);
        emit AugmintTransfer(0x0, to, amount, "", 0);
    }

     
     
    function burn(uint amount) external {
        require(balances[msg.sender] >= amount, "balance must be >= amount");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, 0x0, amount);
        emit AugmintTransfer(msg.sender, 0x0, amount, "", 0);
    }

     
    function setFeeAccount(TransferFeeInterface newFeeAccount) external restrict("StabilityBoard") {
        feeAccount = newFeeAccount;
        emit FeeAccountChanged(newFeeAccount);
    }

     
    function transferAndNotify(TokenReceiver target, uint amount, uint data) external {
        _transfer(msg.sender, target, amount, "");

        target.transferNotification(msg.sender, amount, data);
    }

     
    function delegatedTransferAndNotify(address from, TokenReceiver target, uint amount, uint data,
                                     uint maxExecutorFeeInToken,  
                                     bytes32 nonce,  
                                      
                                     bytes signature,
                                     uint requestedExecutorFeeInToken  
                                     )
    external {
        bytes32 txHash = keccak256(abi.encodePacked(this, from, target, amount, data, maxExecutorFeeInToken, nonce));

        _checkHashAndTransferExecutorFee(txHash, signature, from, maxExecutorFeeInToken, requestedExecutorFeeInToken);

        _transfer(from, target, amount, "");
        target.transferNotification(from, amount, data);
    }


    function transferWithNarrative(address to, uint256 amount, string narrative) external {
        _transfer(msg.sender, to, amount, narrative);
    }

    function transferFromWithNarrative(address from, address to, uint256 amount, string narrative) external {
        _transferFrom(from, to, amount, narrative);
    }

     
    function setName(string _name) external restrict("StabilityBoard") {
        name = _name;
    }

     
    function setSymbol(string _symbol) external restrict("StabilityBoard") {
        symbol = _symbol;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function _checkHashAndTransferExecutorFee(bytes32 txHash, bytes signature, address signer,
                                                uint maxExecutorFeeInToken, uint requestedExecutorFeeInToken) private {
        require(requestedExecutorFeeInToken <= maxExecutorFeeInToken, "requestedExecutorFee must be <= maxExecutorFee");
        require(!delegatedTxHashesUsed[txHash], "txHash already used");
        delegatedTxHashesUsed[txHash] = true;

        address recovered = ECRecovery.recover(ECRecovery.toEthSignedMessageHash(txHash), signature);
        require(recovered == signer, "invalid signature");

        _transfer(signer, msg.sender, requestedExecutorFeeInToken, "Delegated transfer fee", 0);
    }

    function _transferFrom(address from, address to, uint256 amount, string narrative) private {
        uint fee = feeAccount.calculateTransferFee(from, to, amount);
        uint amountWithFee = amount.add(fee);

         
        require(balances[from] >= amountWithFee, "balance must be >= amount + fee");
        require(allowed[from][msg.sender] >= amountWithFee, "allowance must be >= amount + fee");

        _transfer(from, to, amount, narrative, fee);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amountWithFee);
    }

    function _transfer(address from, address to, uint transferAmount, string narrative) private {
        uint fee = feeAccount.calculateTransferFee(from, to, transferAmount);
        _transfer(from, to, transferAmount, narrative, fee);
    }

    function _transfer(address from, address to, uint transferAmount, string narrative, uint fee) private {
        require(to != 0x0, "to must be set");
        uint amountWithFee = transferAmount.add(fee);
         
        require(balances[from] >= amountWithFee, "balance must be >= amount + transfer fee");

        balances[from] = balances[from].sub(amountWithFee);
        balances[to] = balances[to].add(transferAmount);

        emit Transfer(from, to, transferAmount);

        if (fee > 0) {
            balances[feeAccount] = balances[feeAccount].add(fee);
            emit Transfer(from, feeAccount, fee);
        }

        emit AugmintTransfer(from, to, transferAmount, narrative, fee);
    }
}

 

 
pragma solidity 0.4.24;




contract SystemAccount is Restricted {
    event WithdrawFromSystemAccount(address tokenAddress, address to, uint tokenAmount, uint weiAmount,
                                    string narrative);

    constructor(address permissionGranterContract)
    public Restricted(permissionGranterContract) {}  

    function withdraw(AugmintToken tokenAddress, address to, uint tokenAmount, uint weiAmount, string narrative)
    external restrict("StabilityBoard") {
        tokenAddress.transferWithNarrative(to, tokenAmount, narrative);
        if (weiAmount > 0) {
            to.transfer(weiAmount);
        }
        emit WithdrawFromSystemAccount(tokenAddress, to, tokenAmount, weiAmount, narrative);
    }
}

 

 

pragma solidity 0.4.24;




contract AugmintReserves is Restricted {

    event ReserveMigration(address to, uint weiAmount);

    constructor(address permissionGranterContract)
    public Restricted(permissionGranterContract) {}  

    function () external payable {  
         
    }

    function burn(AugmintTokenInterface augmintToken, uint amount)
    external restrict("MonetarySupervisor") {
        augmintToken.burn(amount);
    }

    function migrate(address to, uint weiAmount)
    external restrict("StabilityBoard") {
        if (weiAmount > 0) {
            to.transfer(weiAmount);
        }
        emit ReserveMigration(to, weiAmount);
    }
}

 

 

pragma solidity 0.4.24;




contract InterestEarnedAccount is SystemAccount {

    constructor(address permissionGranterContract) public SystemAccount(permissionGranterContract) {}  

    function transferInterest(AugmintTokenInterface augmintToken, address locker, uint interestAmount)
    external restrict("MonetarySupervisor") {
        augmintToken.transfer(locker, interestAmount);
    }

}

 

 

pragma solidity 0.4.24;








contract MonetarySupervisor is Restricted, TokenReceiver {  
    using SafeMath for uint256;

    uint public constant PERCENT_100 = 1000000;

    AugmintTokenInterface public augmintToken;
    InterestEarnedAccount public interestEarnedAccount;
    AugmintReserves public augmintReserves;

    uint public issuedByStabilityBoard;  
    uint public burnedByStabilityBoard;  

    uint public totalLoanAmount;  
    uint public totalLockedAmount;  

     
    struct LtdParams {
        uint  lockDifferenceLimit;  
        uint  loanDifferenceLimit;  
         
        uint  allowedDifferenceAmount;
    }

    LtdParams public ltdParams;

     
    mapping(address => bool) public acceptedLegacyAugmintTokens;

    event LtdParamsChanged(uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount);

    event AcceptedLegacyAugmintTokenChanged(address augmintTokenAddress, bool newAcceptedState);

    event LegacyTokenConverted(address oldTokenAddress, address account, uint amount);

    event KPIsAdjusted(uint totalLoanAmountAdjustment, uint totalLockedAmountAdjustment);

    event SystemContractsChanged(InterestEarnedAccount newInterestEarnedAccount, AugmintReserves newAugmintReserves);

    constructor(address permissionGranterContract, AugmintTokenInterface _augmintToken,
        AugmintReserves _augmintReserves, InterestEarnedAccount _interestEarnedAccount,
        uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount)
    public Restricted(permissionGranterContract) {
        augmintToken = _augmintToken;
        augmintReserves = _augmintReserves;
        interestEarnedAccount = _interestEarnedAccount;

        ltdParams = LtdParams(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);
    }

    function issueToReserve(uint amount) external restrict("StabilityBoard") {
        issuedByStabilityBoard = issuedByStabilityBoard.add(amount);
        augmintToken.issueTo(augmintReserves, amount);
    }

    function burnFromReserve(uint amount) external restrict("StabilityBoard") {
        burnedByStabilityBoard = burnedByStabilityBoard.add(amount);
        augmintReserves.burn(augmintToken, amount);
    }

     
    function requestInterest(uint amountToLock, uint interestAmount) external {
         
        require(permissions[msg.sender]["Locker"], "msg.sender must have Locker permission");
        require(amountToLock <= getMaxLockAmountAllowedByLtd(), "amountToLock must be <= maxLockAmountAllowedByLtd");

        totalLockedAmount = totalLockedAmount.add(amountToLock);
         
        require(augmintToken.balanceOf(address(interestEarnedAccount)) >= interestAmount,
            "interestEarnedAccount balance must be >= interestAmount");
        interestEarnedAccount.transferInterest(augmintToken, msg.sender, interestAmount);  
    }

     
    function releaseFundsNotification(uint lockedAmount) external {
         
        require(permissions[msg.sender]["Locker"], "msg.sender must have Locker permission");
        totalLockedAmount = totalLockedAmount.sub(lockedAmount);
    }

     
    function issueLoan(address borrower, uint loanAmount) external {
          
        require(permissions[msg.sender]["LoanManager"],
            "msg.sender must have LoanManager permission");
        require(loanAmount <= getMaxLoanAmountAllowedByLtd(), "loanAmount must be <= maxLoanAmountAllowedByLtd");
        totalLoanAmount = totalLoanAmount.add(loanAmount);
        augmintToken.issueTo(borrower, loanAmount);
    }

    function loanRepaymentNotification(uint loanAmount) external {
         
        require(permissions[msg.sender]["LoanManager"],
            "msg.sender must have LoanManager permission");
        totalLoanAmount = totalLoanAmount.sub(loanAmount);
    }

     
    function loanCollectionNotification(uint totalLoanAmountCollected) external {
         
        require(permissions[msg.sender]["LoanManager"],
            "msg.sender must have LoanManager permission");
        totalLoanAmount = totalLoanAmount.sub(totalLoanAmountCollected);
    }

    function setAcceptedLegacyAugmintToken(address legacyAugmintTokenAddress, bool newAcceptedState)
    external restrict("StabilityBoard") {
        acceptedLegacyAugmintTokens[legacyAugmintTokenAddress] = newAcceptedState;
        emit AcceptedLegacyAugmintTokenChanged(legacyAugmintTokenAddress, newAcceptedState);
    }

    function setLtdParams(uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount)
    external restrict("StabilityBoard") {
        ltdParams = LtdParams(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);
        emit LtdParamsChanged(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);
    }

     
    function adjustKPIs(uint totalLoanAmountAdjustment, uint totalLockedAmountAdjustment)
    external restrict("StabilityBoard") {
        totalLoanAmount = totalLoanAmount.add(totalLoanAmountAdjustment);
        totalLockedAmount = totalLockedAmount.add(totalLockedAmountAdjustment);
        emit KPIsAdjusted(totalLoanAmountAdjustment, totalLockedAmountAdjustment);
    }

     
    function setSystemContracts(InterestEarnedAccount newInterestEarnedAccount, AugmintReserves newAugmintReserves)
    external restrict("StabilityBoard") {
        interestEarnedAccount = newInterestEarnedAccount;
        augmintReserves = newAugmintReserves;
        emit SystemContractsChanged(newInterestEarnedAccount, newAugmintReserves);
    }

     
    function transferNotification(address from, uint amount, uint   ) external {
        AugmintTokenInterface legacyToken = AugmintTokenInterface(msg.sender);
        require(acceptedLegacyAugmintTokens[legacyToken], "msg.sender must be allowed in acceptedLegacyAugmintTokens");

        legacyToken.burn(amount);
        augmintToken.issueTo(from, amount);
        emit LegacyTokenConverted(msg.sender, from, amount);
    }

     
    function getMaxLockAmount(uint minLockAmount, uint interestPt) external view returns (uint maxLock) {
        uint allowedByEarning = augmintToken.balanceOf(address(interestEarnedAccount)).mul(PERCENT_100).div(interestPt);
        uint allowedByLtd = getMaxLockAmountAllowedByLtd();
        maxLock = allowedByEarning < allowedByLtd ? allowedByEarning : allowedByLtd;
        maxLock = maxLock < minLockAmount ? 0 : maxLock;
    }

     
    function getMaxLoanAmount(uint minLoanAmount) external view returns (uint maxLoan) {
        uint allowedByLtd = getMaxLoanAmountAllowedByLtd();
        maxLoan = allowedByLtd < minLoanAmount ? 0 : allowedByLtd;
    }

     
    function getMaxLockAmountAllowedByLtd() public view returns(uint maxLockByLtd) {
        uint allowedByLtdDifferencePt = totalLoanAmount.mul(PERCENT_100).div(PERCENT_100
                                            .sub(ltdParams.lockDifferenceLimit));
        allowedByLtdDifferencePt = totalLockedAmount >= allowedByLtdDifferencePt ?
                                        0 : allowedByLtdDifferencePt.sub(totalLockedAmount);

        uint allowedByLtdDifferenceAmount =
            totalLockedAmount >= totalLoanAmount.add(ltdParams.allowedDifferenceAmount) ?
                0 : totalLoanAmount.add(ltdParams.allowedDifferenceAmount).sub(totalLockedAmount);

        maxLockByLtd = allowedByLtdDifferencePt > allowedByLtdDifferenceAmount ?
                                        allowedByLtdDifferencePt : allowedByLtdDifferenceAmount;
    }

     
    function getMaxLoanAmountAllowedByLtd() public view returns(uint maxLoanByLtd) {
        uint allowedByLtdDifferencePt = totalLockedAmount.mul(ltdParams.loanDifferenceLimit.add(PERCENT_100))
                                            .div(PERCENT_100);
        allowedByLtdDifferencePt = totalLoanAmount >= allowedByLtdDifferencePt ?
                                        0 : allowedByLtdDifferencePt.sub(totalLoanAmount);

        uint allowedByLtdDifferenceAmount =
            totalLoanAmount >= totalLockedAmount.add(ltdParams.allowedDifferenceAmount) ?
                0 : totalLockedAmount.add(ltdParams.allowedDifferenceAmount).sub(totalLoanAmount);

        maxLoanByLtd = allowedByLtdDifferencePt > allowedByLtdDifferenceAmount ?
                                        allowedByLtdDifferencePt : allowedByLtdDifferenceAmount;
    }
}

 

 
pragma solidity 0.4.24;




contract Rates is Restricted {
    using SafeMath for uint256;

    struct RateInfo {
        uint rate;  
        uint lastUpdated;
    }

     
     
    mapping(bytes32 => RateInfo) public rates;

    event RateChanged(bytes32 symbol, uint newRate);

    constructor(address permissionGranterContract) public Restricted(permissionGranterContract) {}  

    function setRate(bytes32 symbol, uint newRate) external restrict("RatesFeeder") {
        rates[symbol] = RateInfo(newRate, now);
        emit RateChanged(symbol, newRate);
    }

    function setMultipleRates(bytes32[] symbols, uint[] newRates) external restrict("RatesFeeder") {
        require(symbols.length == newRates.length, "symbols and newRates lengths must be equal");
        for (uint256 i = 0; i < symbols.length; i++) {
            rates[symbols[i]] = RateInfo(newRates[i], now);
            emit RateChanged(symbols[i], newRates[i]);
        }
    }

    function convertFromWei(bytes32 bSymbol, uint weiValue) external view returns(uint value) {
        require(rates[bSymbol].rate > 0, "rates[bSymbol] must be > 0");
        return weiValue.mul(rates[bSymbol].rate).roundedDiv(1000000000000000000);
    }

    function convertToWei(bytes32 bSymbol, uint value) external view returns(uint weiValue) {
         
        require(rates[bSymbol].rate > 0, "rates[bSymbol] must be > 0");
         
        return value.mul(1000000000000000000).roundedDiv(rates[bSymbol].rate);
    }

}

 

 
pragma solidity 0.4.24;







contract LoanManager is Restricted, TokenReceiver {
    using SafeMath for uint256;

    uint constant PPM_FACTOR = 1e6;
    uint constant WEI_FACTOR = 1e18;
    uint constant WEI_PER_PPM_FACTOR = WEI_FACTOR / PPM_FACTOR;  

    enum LoanState { Open, Repaid, DoNotUse, Collected }  

    struct LoanProduct {
        uint minDisbursedAmount;         
        uint32 term;                     
        uint32 discountRate;             
        uint32 initialCollateralRatio;   
        uint32 defaultingFeePt;          
        bool isActive;                   
        uint32 minCollateralRatio;       
    }

     
    struct LoanData {
        uint collateralAmount;       
        uint repaymentAmount;        
        address borrower;            
        uint32 productId;            
        LoanState state;             
        uint40 maturity;             
    }

    LoanProduct[] public products;

    LoanData[] public loans;
    mapping(address => uint[]) public accountLoans;   

    Rates public rates;  
    AugmintTokenInterface public augmintToken;  
    MonetarySupervisor public monetarySupervisor;

    event NewLoan(uint32 productId, uint loanId, address indexed borrower, uint collateralAmount, uint loanAmount,
        uint repaymentAmount, uint40 maturity, uint currentRate);

    event LoanChanged(uint loanId, address indexed borrower, uint collateralAmount,
        uint repaymentAmount, uint currentRate);

    event LoanProductActiveStateChanged(uint32 productId, bool newState);

    event LoanProductAdded(uint32 productId);

    event LoanRepaid(uint loanId, address indexed borrower, uint currentRate);

    event LoanCollected(uint loanId, address indexed borrower, uint collectedCollateral,
        uint releasedCollateral, uint defaultingFee, uint currentRate);

    event SystemContractsChanged(Rates newRatesContract, MonetarySupervisor newMonetarySupervisor);

    constructor(address permissionGranterContract, AugmintTokenInterface _augmintToken,
                    MonetarySupervisor _monetarySupervisor, Rates _rates)
    public Restricted(permissionGranterContract) {
        augmintToken = _augmintToken;
        monetarySupervisor = _monetarySupervisor;
        rates = _rates;
    }

    function addLoanProduct(uint32 term, uint32 discountRate, uint32 initialCollateralRatio, uint minDisbursedAmount,
                                uint32 defaultingFeePt, bool isActive, uint32 minCollateralRatio)
    external restrict("StabilityBoard") {
        uint _newProductId = products.push(
            LoanProduct(minDisbursedAmount, term, discountRate, initialCollateralRatio, defaultingFeePt, isActive, minCollateralRatio)
        ) - 1;

        uint32 newProductId = uint32(_newProductId);
        require(newProductId == _newProductId, "productId overflow");

        emit LoanProductAdded(newProductId);
    }

    function setLoanProductActiveState(uint32 productId, bool newState)
    external restrict ("StabilityBoard") {
        require(productId < products.length, "invalid productId");  
        products[productId].isActive = newState;
        emit LoanProductActiveStateChanged(productId, newState);
    }

    function newEthBackedLoan(uint32 productId, uint minRate) external payable {
        require(productId < products.length, "invalid productId");  
        LoanProduct storage product = products[productId];
        require(product.isActive, "product must be in active state");  

        uint currentRate = getCurrentRate();
        require(currentRate >= minRate, "current rate is below minimum");

         
        uint collateralValueInToken = _convertFromWei(currentRate, msg.value);
        uint repaymentAmount = collateralValueInToken.mul(PPM_FACTOR).div(product.initialCollateralRatio);

        uint loanAmount;
        (loanAmount, ) = calculateLoanValues(product, repaymentAmount);

        require(loanAmount >= product.minDisbursedAmount, "loanAmount must be >= minDisbursedAmount");

        uint expiration = now.add(product.term);
        uint40 maturity = uint40(expiration);
        require(maturity == expiration, "maturity overflow");

         
        uint loanId = loans.push(
            LoanData(msg.value, repaymentAmount, msg.sender, productId, LoanState.Open, maturity)
        ) - 1;

         
        accountLoans[msg.sender].push(loanId);

         
        monetarySupervisor.issueLoan(msg.sender, loanAmount);

        emit NewLoan(productId, loanId, msg.sender, msg.value, loanAmount, repaymentAmount, maturity, currentRate);
    }

    function addExtraCollateral(uint loanId) external payable {
        require(loanId < loans.length, "invalid loanId");
        LoanData storage loan = loans[loanId];
        require(loan.state == LoanState.Open, "loan state must be Open");
        LoanProduct storage product = products[loan.productId];
        require(product.minCollateralRatio > 0, "not a margin type loan");

        loan.collateralAmount = loan.collateralAmount.add(msg.value);

        emit LoanChanged(loanId, loan.borrower, loan.collateralAmount, loan.repaymentAmount, getCurrentRate());
    }

     
     
    function transferNotification(address, uint repaymentAmount, uint loanId) external {
        require(msg.sender == address(augmintToken), "msg.sender must be augmintToken");

        _repayLoan(loanId, repaymentAmount);
    }

    function collect(uint[] loanIds) external {
        uint currentRate = getCurrentRate();

         
        uint totalLoanAmountCollected;
        uint totalCollateralToCollect;
        uint totalDefaultingFee;
        for (uint i = 0; i < loanIds.length; i++) {
            (uint loanAmount, uint defaultingFee, uint collateralToCollect) = _collectLoan(loanIds[i], currentRate);
            totalLoanAmountCollected = totalLoanAmountCollected.add(loanAmount);
            totalDefaultingFee = totalDefaultingFee.add(defaultingFee);
            totalCollateralToCollect = totalCollateralToCollect.add(collateralToCollect);
        }

        if (totalCollateralToCollect > 0) {
            address(monetarySupervisor.augmintReserves()).transfer(totalCollateralToCollect);
        }

        if (totalDefaultingFee > 0) {
            address(augmintToken.feeAccount()).transfer(totalDefaultingFee);
        }

        monetarySupervisor.loanCollectionNotification(totalLoanAmountCollected); 

    }

     
    function setSystemContracts(Rates newRatesContract, MonetarySupervisor newMonetarySupervisor)
    external restrict("StabilityBoard") {
        rates = newRatesContract;
        monetarySupervisor = newMonetarySupervisor;
        emit SystemContractsChanged(newRatesContract, newMonetarySupervisor);
    }

    function getProductCount() external view returns (uint) {
        return products.length;
    }

     
     
    function getProducts(uint offset, uint16 chunkSize)
    external view returns (uint[9][]) {
        uint limit = SafeMath.min(offset.add(chunkSize), products.length);
        uint[9][] memory response = new uint[9][](limit.sub(offset));

        for (uint i = offset; i < limit; i++) {
            LoanProduct storage product = products[i];
            response[i - offset] = [i, product.minDisbursedAmount, product.term, product.discountRate,
                    product.initialCollateralRatio, product.defaultingFeePt,
                    monetarySupervisor.getMaxLoanAmount(product.minDisbursedAmount), product.isActive ? 1 : 0,
                    product.minCollateralRatio];
        }
        return response;
    }

    function getLoanCount() external view returns (uint) {
        return loans.length;
    }

     
    function getLoans(uint offset, uint16 chunkSize)
    external view returns (uint[12][]) {
        uint limit = SafeMath.min(offset.add(chunkSize), loans.length);
        uint[12][] memory response = new uint[12][](limit.sub(offset));
        uint currentRate = getCurrentRate();

        for (uint i = offset; i < limit; i++) {
            response[i - offset] = _getLoanTuple(i, currentRate);
        }
        return response;
    }

    function getLoanCountForAddress(address borrower) external view returns (uint) {
        return accountLoans[borrower].length;
    }

     
    function getLoansForAddress(address borrower, uint offset, uint16 chunkSize)
    external view returns (uint[12][]) {
        uint[] storage loansForAddress = accountLoans[borrower];
        uint limit = SafeMath.min(offset.add(chunkSize), loansForAddress.length);
        uint[12][] memory response = new uint[12][](limit.sub(offset));
        uint currentRate = getCurrentRate();

        for (uint i = offset; i < limit; i++) {
            response[i - offset] = _getLoanTuple(loansForAddress[i], currentRate);
        }
        return response;
    }

    function getLoanTuple(uint loanId) public view returns (uint[12] result) {
        return _getLoanTuple(loanId, getCurrentRate());
    }

    function _getLoanTuple(uint loanId, uint currentRate) internal view returns (uint[12] result) {
        require(loanId < loans.length, "invalid loanId");  
        LoanData storage loan = loans[loanId];
        LoanProduct storage product = products[loan.productId];

        uint loanAmount;
        uint interestAmount;
        (loanAmount, interestAmount) = calculateLoanValues(product, loan.repaymentAmount);
        uint disbursementTime = loan.maturity - product.term;

         
        uint marginCallRate = calculateMarginCallRate(product.minCollateralRatio, loan.repaymentAmount, loan.collateralAmount);

        result = [loanId, loan.collateralAmount, loan.repaymentAmount, uint(loan.borrower),
            loan.productId, uint(loan.state), loan.maturity, disbursementTime, loanAmount, interestAmount,
            marginCallRate, isCollectable(loan, currentRate) ? 1 : 0];
    }

    function calculateLoanValues(LoanProduct storage product, uint repaymentAmount)
    internal view returns (uint loanAmount, uint interestAmount) {
         
        loanAmount = repaymentAmount.mul(product.discountRate).ceilDiv(PPM_FACTOR);
        interestAmount = loanAmount > repaymentAmount ? 0 : repaymentAmount.sub(loanAmount);
    }

     
    function calculateMarginCallRate(uint32 minCollateralRatio, uint repaymentAmount, uint collateralAmount)
    internal pure returns (uint) {
        return uint(minCollateralRatio).mul(repaymentAmount).mul(WEI_PER_PPM_FACTOR).div(collateralAmount);
    }

    function isUnderMargin(LoanData storage loan, uint currentRate)
    internal view returns (bool) {
        uint32 minCollateralRatio = products[loan.productId].minCollateralRatio;
        uint marginCallRate = calculateMarginCallRate(minCollateralRatio, loan.repaymentAmount, loan.collateralAmount);
        return minCollateralRatio > 0 && marginCallRate > 0 && currentRate < marginCallRate;
    }

    function isCollectable(LoanData storage loan, uint currentRate)
    internal view returns (bool) {
        return loan.state == LoanState.Open && (now >= loan.maturity || isUnderMargin(loan, currentRate));
    }

     
    function getCurrentRate()
    internal view returns (uint) {
        (uint currentRate, ) = rates.rates(augmintToken.peggedSymbol());
        require(currentRate > 0, "No current rate available");
        return currentRate;
    }

     
    function _repayLoan(uint loanId, uint repaymentAmount) internal {
        require(loanId < loans.length, "invalid loanId");  
        LoanData storage loan = loans[loanId];
        require(loan.state == LoanState.Open, "loan state must be Open");
        require(repaymentAmount == loan.repaymentAmount, "repaymentAmount must be equal to tokens sent");
        require(now <= loan.maturity, "current time must be earlier than maturity");

        LoanProduct storage product = products[loan.productId];
        uint loanAmount;
        uint interestAmount;
        (loanAmount, interestAmount) = calculateLoanValues(product, loan.repaymentAmount);

        loans[loanId].state = LoanState.Repaid;

        if (interestAmount > 0) {
            augmintToken.transfer(monetarySupervisor.interestEarnedAccount(), interestAmount);
            augmintToken.burn(loanAmount);
        } else {
             
            augmintToken.burn(repaymentAmount);
        }

        monetarySupervisor.loanRepaymentNotification(loanAmount);  

        loan.borrower.transfer(loan.collateralAmount);  

        emit LoanRepaid(loanId, loan.borrower, getCurrentRate());
    }

    function _collectLoan(uint loanId, uint currentRate) private returns(uint loanAmount, uint defaultingFee, uint collateralToCollect) {
        LoanData storage loan = loans[loanId];
        require(isCollectable(loan, currentRate), "Not collectable");
        LoanProduct storage product = products[loan.productId];

        (loanAmount, ) = calculateLoanValues(product, loan.repaymentAmount);

        loan.state = LoanState.Collected;

         
         
        defaultingFee = _convertToWei(currentRate, loan.repaymentAmount.mul(product.defaultingFeePt).div(PPM_FACTOR));
        uint targetCollection = _convertToWei(currentRate, loan.repaymentAmount).add(defaultingFee);

        uint releasedCollateral;
        if (targetCollection < loan.collateralAmount) {
            releasedCollateral = loan.collateralAmount.sub(targetCollection);
            loan.borrower.transfer(releasedCollateral);
        }
        collateralToCollect = loan.collateralAmount.sub(releasedCollateral);
        if (defaultingFee >= collateralToCollect) {
            defaultingFee = collateralToCollect;
            collateralToCollect = 0;
        } else {
            collateralToCollect = collateralToCollect.sub(defaultingFee);
        }

        emit LoanCollected(loanId, loan.borrower, collateralToCollect.add(defaultingFee),
                releasedCollateral, defaultingFee, currentRate);
    }

    function _convertToWei(uint rate, uint tokenAmount) private pure returns(uint weiAmount) {
        return tokenAmount.mul(WEI_FACTOR).roundedDiv(rate);
    }

    function _convertFromWei(uint rate, uint weiAmount) private pure returns(uint tokenAmount) {
        return weiAmount.mul(rate).roundedDiv(WEI_FACTOR);
    }
}