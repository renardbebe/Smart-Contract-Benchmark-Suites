 

 

pragma solidity ^0.4.18;

 
 

contract KyberNetworkProxy {
  function getExpectedRate(address src, address dest, uint srcQty) public pure returns(uint expectedRate, uint slippageRate);
  function trade(address src, uint srcAmount, address dest, address destAddress, uint  maxDestAmount, uint minConversionRate, address walletId) public payable returns(uint);
  function swapTokenToToken(address src, uint srcAmount, address dest, uint minConversionRate) public pure;
  function swapEtherToToken(address token, uint minConversionRate) public payable returns(uint);
}

 

pragma solidity ^0.4.18;


 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

 

pragma solidity ^0.4.18;


 
contract Pausable is Ownable {

    event Paused();
    event Unpaused();

    bool public paused;

    function Pausable() internal {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        Paused();
    }

     
    function unpause() external onlyOwner whenPaused {
        paused = false;
        Unpaused();
    }
}

 

pragma solidity ^0.4.18;

contract ErrorReporter {

     
    event Failure(uint error, uint info, uint detail);

    enum Error {
        NO_ERROR,
        OPAQUE_ERROR,  
        UNAUTHORIZED,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW,
        DIVISION_BY_ZERO,
        BAD_INPUT,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_TRANSFER_FAILED,
        MARKET_NOT_SUPPORTED,
        SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_RATE_CALCULATION_FAILED,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_OUT_FAILED,
        INSUFFICIENT_LIQUIDITY,
        INSUFFICIENT_BALANCE,
        INVALID_COLLATERAL_RATIO,
        MISSING_ASSET_PRICE,
        EQUITY_INSUFFICIENT_BALANCE,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        ASSET_NOT_PRICED,
        INVALID_LIQUIDATION_DISCOUNT,
        INVALID_COMBINED_RISK_PARAMETERS,
        ZERO_ORACLE_ADDRESS,
        CONTRACT_PAUSED
    }

     
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        BORROW_ACCOUNT_SHORTFALL_PRESENT,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_AMOUNT_LIQUIDITY_SHORTFALL,
        BORROW_AMOUNT_VALUE_CALCULATION_FAILED,
        BORROW_CONTRACT_PAUSED,
        BORROW_MARKET_NOT_SUPPORTED,
        BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        BORROW_ORIGINATION_FEE_CALCULATION_FAILED,
        BORROW_TRANSFER_OUT_FAILED,
        EQUITY_WITHDRAWAL_AMOUNT_VALIDATION,
        EQUITY_WITHDRAWAL_CALCULATE_EQUITY,
        EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK,
        EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED,
        LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED,
        LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH,
        LIQUIDATE_CONTRACT_PAUSED,
        LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET,
        LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET,
        LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET,
        LIQUIDATE_FETCH_ASSET_PRICE_FAILED,
        LIQUIDATE_TRANSFER_IN_FAILED,
        LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTRACT_PAUSED,
        REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_ASSET_PRICE_CHECK_ORACLE,
        SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_ORACLE_OWNER_CHECK,
        SET_ORIGINATION_FEE_OWNER_CHECK,
        SET_PAUSED_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RISK_PARAMETERS_OWNER_CHECK,
        SET_RISK_PARAMETERS_VALIDATION,
        SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        SUPPLY_CONTRACT_PAUSED,
        SUPPLY_MARKET_NOT_SUPPORTED,
        SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED,
        SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        SUPPLY_TRANSFER_IN_FAILED,
        SUPPLY_TRANSFER_IN_NOT_POSSIBLE,
        SUPPORT_MARKET_FETCH_PRICE_FAILED,
        SUPPORT_MARKET_OWNER_CHECK,
        SUPPORT_MARKET_PRICE_CHECK,
        SUSPEND_MARKET_OWNER_CHECK,
        WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED,
        WITHDRAW_ACCOUNT_SHORTFALL_PRESENT,
        WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL,
        WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED,
        WITHDRAW_CAPACITY_CALCULATION_FAILED,
        WITHDRAW_CONTRACT_PAUSED,
        WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        WITHDRAW_TRANSFER_OUT_FAILED,
        WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE
    }


     
    function fail(Error err, FailureInfo info) internal returns (uint) {
        Failure(uint(err), uint(info), 0);

        return uint(err);
    }


     
    function failOpaque(FailureInfo info, uint opaqueError) internal returns (uint) {
        Failure(uint(Error.OPAQUE_ERROR), uint(info), opaqueError);

        return uint(Error.OPAQUE_ERROR);
    }

}

 

 
 
pragma solidity ^0.4.18;

 
contract EIP20NonStandardInterface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
     

     
     
     
     
    function transfer(address _to, uint256 _value) public;

     
     
     
     
     

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public;

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
 
pragma solidity ^0.4.18;

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

pragma solidity ^0.4.18;




 
contract SafeToken is ErrorReporter {

     
    function checkTransferIn(address asset, address from, uint amount) internal view returns (Error) {

        EIP20Interface token = EIP20Interface(asset);

        if (token.allowance(from, address(this)) < amount) {
            return Error.TOKEN_INSUFFICIENT_ALLOWANCE;
        }

        if (token.balanceOf(from) < amount) {
            return Error.TOKEN_INSUFFICIENT_BALANCE;
        }

        return Error.NO_ERROR;
    }

     
    function doTransferIn(address asset, address from, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transferFrom(from, address(this), amount);

        assembly {
            switch returndatasize()
                case 0 {                       
                    result := not(0)           
                }
                case 32 {                      
                    returndatacopy(0, 0, 32)
                    result := mload(0)         
                }
                default {                      
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_FAILED;
        }

        return Error.NO_ERROR;
    }

     
    function getCash(address asset) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(address(this));
    }

     
    function getBalanceOf(address asset, address from) internal view returns (uint) {
        EIP20Interface token = EIP20Interface(asset);

        return token.balanceOf(from);
    }

     
    function doTransferOut(address asset, address to, uint amount) internal returns (Error) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(asset);

        bool result;

        token.transfer(to, amount);

        assembly {
            switch returndatasize()
                case 0 {                       
                    result := not(0)           
                }
                case 32 {                      
                    returndatacopy(0, 0, 32)
                    result := mload(0)         
                }
                default {                      
                    revert(0, 0)
                }
        }

        if (!result) {
            return Error.TOKEN_TRANSFER_OUT_FAILED;
        }

        return Error.NO_ERROR;
    }
}

 

pragma solidity ^0.4.24;




contract LiquidPledging {
    function addGiverAndDonate(uint64 idReceiver, address donorAddress, address token, uint amount)
        public
    {}
}

contract SwapProxy is Pausable, SafeToken {
    address public ETH;
    address public vault;
    uint public maxSlippage;
    KyberNetworkProxy public kyberProxy;
    LiquidPledging public liquidPledging;

     
    function SwapProxy(address _liquidPledging, address _kyberProxy, address _ETH, address _vault, uint _maxSlippage) public {
      require(_maxSlippage < 100);
      if (_vault == address(0)){
        _vault = address(this);
      }
      liquidPledging = LiquidPledging(_liquidPledging);
      kyberProxy = KyberNetworkProxy(_kyberProxy);
      ETH = _ETH;
      vault = _vault;
      maxSlippage = _maxSlippage;
    }

    event SlippageUpdated(uint maxSlippage);
     
    function updateSlippage(uint _maxSlippage) public onlyOwner {
      require(_maxSlippage < 100);
      maxSlippage = _maxSlippage;
      SlippageUpdated(_maxSlippage);
    }

    event VaultUpdated(address vault);
     
    function updateVault(address _vault) public onlyOwner {
      vault = _vault;
      VaultUpdated(_vault);
    }

    event KyberUpdated(address kyber);
     
    function updateKyber(address _kyberProxy) public onlyOwner {
      kyberProxy = KyberNetworkProxy(_kyberProxy);
      KyberUpdated(_kyberProxy);
    }

    event LiquidPledgingUpdated(address liquidPledging);
     
    function updateLiquidPledging(address _liquidPledging) public onlyOwner {
      liquidPledging = LiquidPledging(_liquidPledging);
      LiquidPledgingUpdated(_liquidPledging);
    }

     
    function getConversionRates(address srcToken, uint srcQty, address destToken) public view returns (uint exchangeRate)
    {
      if(srcToken == address(0)){
          srcToken = ETH;
      }

      uint minConversionRate;
      uint slippageRate;
      (minConversionRate, slippageRate) = kyberProxy.getExpectedRate(srcToken, destToken, srcQty);
      require(minConversionRate > 0);
      return slippageRate;
    }

    event Swap(address sender, address srcToken, address destToken, uint srcAmount, uint destAmount);

     
    function fundWithETH(uint64 idReceiver, address token) public payable whenNotPaused {
      require(msg.value > 0, "ETH amount must be greater than 0");
      uint expectedRate;
      uint slippageRate;
      (expectedRate, slippageRate) = kyberProxy.getExpectedRate(ETH, token, msg.value);
      require(expectedRate > 0, "expectedRate must be greater than 0");
      uint slippagePercent = 100 - ((slippageRate * 100) / expectedRate);
      require(slippagePercent <= maxSlippage, "Slippage can not exceed max");
      uint maxDestinationAmount = getMaxDestinationAmount(expectedRate, msg.value);
      uint amount = kyberProxy.trade.value(msg.value)(ETH, msg.value, token, address(this), maxDestinationAmount, slippageRate, vault);
      require(amount > 0, "Token amount must be greater than 0");
      require(EIP20Interface(token).approve(address(liquidPledging), amount));
      liquidPledging.addGiverAndDonate(idReceiver, msg.sender, token, amount);

      Swap(msg.sender, ETH, token, msg.value, amount);
    }


     
    function fundWithToken(uint64 idReceiver, address token, uint amount, address receiverToken) public whenNotPaused {
      Error err = doTransferIn(token, msg.sender, amount);
      require(err == Error.NO_ERROR, "Transfer in failed");

      uint expectedRate;
      uint slippageRate;
      (expectedRate, slippageRate) = kyberProxy.getExpectedRate(token, receiverToken, amount);
      require(expectedRate > 0, "expectedRate must be greater than 0");
      uint slippagePercent = 100 - (slippageRate * 100) / expectedRate;
      require(slippagePercent <= maxSlippage, "slippage can not exceed max");
      require(EIP20Interface(token).approve(address(kyberProxy), 0));
      require(EIP20Interface(token).approve(address(kyberProxy), amount));

      uint maxDestinationAmount = getMaxDestinationAmount(expectedRate, amount);
      uint receiverAmount = kyberProxy.trade(token, amount, receiverToken, address(this), maxDestinationAmount, slippageRate, vault);
      require(receiverAmount > 0, "Receiver amount must be greater than 0");
      require(EIP20Interface(receiverToken).approve(address(liquidPledging), receiverAmount));
      liquidPledging.addGiverAndDonate(idReceiver, msg.sender, receiverToken, receiverAmount);
      Swap(msg.sender, token, receiverToken, amount, receiverAmount);
    }

    function getMaxDestinationAmount(uint expectedRate, uint amount) pure returns (uint256) {
      uint val = (expectedRate * amount) / 10**18;
      return val;
    }

    function transferOut(address asset, address to, uint amount) public onlyOwner {
      Error err = doTransferOut(asset, to, amount);
      require(err == Error.NO_ERROR);
    }

    function() payable external {}
}