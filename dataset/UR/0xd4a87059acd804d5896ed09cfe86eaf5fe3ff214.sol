 

 

pragma solidity ^0.4.23;

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);
}

 

pragma solidity ^0.4.23;

 
contract IERC20Token {
     
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 

pragma solidity ^0.4.23;


contract IPegSettings {

    function authorized(address _address) public view returns (bool) { _address; }
    
    function authorize(address _address, bool _auth) public;
    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public;

}

 

pragma solidity ^0.4.23;



contract IVault {

    function registry() public view returns (IContractRegistry);

    function auctions(address _borrower) public view returns (address) { _borrower; }
    function vaultExists(address _vault) public view returns (bool) { _vault; }
    function totalBorrowed(address _vault) public view returns (uint256) { _vault; }
    function rawBalanceOf(address _vault) public view returns (uint256) { _vault; }
    function rawDebt(address _vault) public view returns (uint256) { _vault; }
    function rawTotalBalance() public view returns (uint256);
    function rawTotalDebt() public view returns (uint256);
    function collateralBorrowedRatio() public view returns (uint256);
    function amountMinted() public view returns (uint256);

    function debtScalePrevious() public view returns (uint256);
    function debtScaleTimestamp() public view returns (uint256);
    function debtScaleRate() public view returns (int256);
    function balScalePrevious() public view returns (uint256);
    function balScaleTimestamp() public view returns (uint256);
    function balScaleRate() public view returns (int256);
    
    function liquidationRatio() public view returns (uint32);
    function maxBorrowLTV() public view returns (uint32);

    function borrowingEnabled() public view returns (bool);
    function biddingTime() public view returns (uint);

    function setType(bool _type) public;
    function create(address _vault) public;
    function setCollateralBorrowedRatio(uint _newRatio) public;
    function setAmountMinted(uint _amountMinted) public;
    function setLiquidationRatio(uint32 _liquidationRatio) public;
    function setMaxBorrowLTV(uint32 _maxBorrowLTV) public;
    function setDebtScalingRate(int256 _debtScalingRate) public;
    function setBalanceScalingRate(int256 _balanceScalingRate) public;
    function setBiddingTime(uint _biddingTime) public;
    function setRawTotalDebt(uint _rawTotalDebt) public;
    function setRawTotalBalance(uint _rawTotalBalance) public;
    function setRawBalanceOf(address _borrower, uint _rawBalance) public;
    function setRawDebt(address _borrower, uint _rawDebt) public;
    function setTotalBorrowed(address _borrower, uint _totalBorrowed) public;
    function debtScalingFactor() public view returns (uint256);
    function balanceScalingFactor() public view returns (uint256);
    function debtRawToActual(uint256 _raw) public view returns (uint256);
    function debtActualToRaw(uint256 _actual) public view returns (uint256);
    function balanceRawToActual(uint256 _raw) public view returns (uint256);
    function balanceActualToRaw(uint256 _actual) public view returns (uint256);
    function getVaults(address _vault, uint256 _balanceOf) public view returns(address[]);
    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public;
    function oracleValue() public view returns(uint256);
    function emitBorrow(address _borrower, uint256 _amount) public;
    function emitRepay(address _borrower, uint256 _amount) public;
    function emitDeposit(address _borrower, uint256 _amount) public;
    function emitWithdraw(address _borrower, address _to, uint256 _amount) public;
    function emitLiquidate(address _borrower) public;
    function emitAuctionStarted(address _borrower) public;
    function emitAuctionEnded(address _borrower, address _highestBidder, uint256 _highestBid) public;
    function setAuctionAddress(address _borrower, address _auction) public;
}

 

pragma solidity ^0.4.23;

contract IPegOracle {
    function getValue() public view returns (uint256);
}

 

pragma solidity ^0.4.23;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function setOwner(address _newOwner) public;
}

 

pragma solidity ^0.4.23;



 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

pragma solidity ^0.4.23;




contract IPegLogic {

    function adjustCollateralBorrowingRate() public;
    function isInsolvent(IVault _vault, address _borrower) public view returns (bool);
    function actualDebt(IVault _vault, address _address) public view returns(uint256);
    function excessCollateral(IVault _vault, address _borrower) public view returns (int256);
    function availableCredit(IVault _vault, address _borrower) public view returns (int256);
    function getCollateralToken(IVault _vault) public view returns(IERC20Token);
    function getDebtToken(IVault _vault) public view returns(ISmartToken);

}

 

pragma solidity ^0.4.23;


contract IAuctionActions {

    function startAuction(IVault _vault, address _borrower) public;
    function endAuction(IVault _vault, address _borrower) public;

}

 

pragma solidity ^0.4.23;

contract ContractIds {
    bytes32 public constant STABLE_TOKEN = "StableToken";
    bytes32 public constant COLLATERAL_TOKEN = "CollateralToken";

    bytes32 public constant PEGUSD_TOKEN = "PEGUSD";

    bytes32 public constant VAULT_A = "VaultA";
    bytes32 public constant VAULT_B = "VaultB";

    bytes32 public constant PEG_LOGIC = "PegLogic";
    bytes32 public constant PEG_LOGIC_ACTIONS = "LogicActions";
    bytes32 public constant AUCTION_ACTIONS = "AuctionActions";

    bytes32 public constant PEG_SETTINGS = "PegSettings";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant FEE_RECIPIENT = "StabilityFeeRecipient";
}

 

pragma solidity ^0.4.23;










contract Helpers is ContractIds {

    IContractRegistry public registry;

    constructor(IContractRegistry _registry) public {
        registry = _registry;
    }

    modifier authOnly() {
        require(settings().authorized(msg.sender));
        _;
    }

    modifier validate(IVault _vault, address _borrower) {
        require(address(_vault) == registry.addressOf(ContractIds.VAULT_A) || address(_vault) == registry.addressOf(ContractIds.VAULT_B));
        _vault.create(_borrower);
        _;
    }

    function stableToken() internal returns(ISmartToken) {
        return ISmartToken(registry.addressOf(ContractIds.STABLE_TOKEN));
    }

    function collateralToken() internal returns(ISmartToken) {
        return ISmartToken(registry.addressOf(ContractIds.COLLATERAL_TOKEN));
    }

    function PEGUSD() internal returns(IERC20Token) {
        return IERC20Token(registry.addressOf(ContractIds.PEGUSD_TOKEN));
    }

    function vaultA() internal returns(IVault) {
        return IVault(registry.addressOf(ContractIds.VAULT_A));
    }

    function vaultB() internal returns(IVault) {
        return IVault(registry.addressOf(ContractIds.VAULT_B));
    }

    function oracle() internal returns(IPegOracle) {
        return IPegOracle(registry.addressOf(ContractIds.ORACLE));
    }

    function settings() internal returns(IPegSettings) {
        return IPegSettings(registry.addressOf(ContractIds.PEG_SETTINGS));
    }

    function pegLogic() internal returns(IPegLogic) {
        return IPegLogic(registry.addressOf(ContractIds.PEG_LOGIC));
    }

    function auctionActions() internal returns(IAuctionActions) {
        return IAuctionActions(registry.addressOf(ContractIds.AUCTION_ACTIONS));
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public authOnly {
        _token.transfer(_to, _amount);
    }

}

 

pragma solidity ^0.4.23;

library SafeMath {
    function plus(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }

    function plus(int256 _a, int256 _b) internal pure returns (int256) {
        int256 c = _a + _b;
        assert((_b >= 0 && c >= _a) || (_b < 0 && c < _a));
        return c;
    }

    function minus(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    function minus(int256 _a, int256 _b) internal pure returns (int256) {
        int256 c = _a - _b;
        assert((_b >= 0 && c <= _a) || (_b < 0 && c > _a));
        return c;
    }

    function times(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function times(int256 _a, int256 _b) internal pure returns (int256) {
        if (_a == 0) {
            return 0;
        }
        int256 c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function toInt256(uint256 _a) internal pure returns (int256) {
        assert(_a <= 2 ** 255);
        return int256(_a);
    }

    function toUint256(int256 _a) internal pure returns (uint256) {
        assert(_a >= 0);
        return uint256(_a);
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function div(int256 _a, int256 _b) internal pure returns (int256) {
        return _a / _b;
    }
}

 

pragma solidity ^0.4.23;






contract LogicActions is Helpers {

    using SafeMath for uint256;
    using SafeMath for int256;

    IContractRegistry public registry;

    constructor(IContractRegistry _registry) public Helpers(_registry) {
        registry = _registry;
    }

    function deposit(IVault _vault, uint256 _amount) public validate(_vault, msg.sender) {
        IERC20Token vaultCollateralToken = pegLogic().getCollateralToken(_vault);
        vaultCollateralToken.transferFrom(msg.sender, address(_vault), _amount);
        _vault.setRawBalanceOf(
            msg.sender,
            _vault.rawBalanceOf(msg.sender).plus(_vault.balanceActualToRaw(_amount))
        );
        _vault.setRawTotalBalance(
            _vault.rawTotalBalance().plus(_vault.balanceActualToRaw(_amount))
        );
        pegLogic().adjustCollateralBorrowingRate();
        _vault.emitDeposit(msg.sender, _amount);
    }

    function withdraw(IVault _vault, address _to, uint256 _amount) public validate(_vault, msg.sender) {
        IPegLogic ipegLogic = pegLogic();
        require(_amount.toInt256() <= ipegLogic.excessCollateral(_vault, msg.sender), "Insufficient collateral balance");
        _vault.setRawBalanceOf(
            msg.sender,
            _vault.rawBalanceOf(msg.sender).minus(_vault.balanceActualToRaw(_amount))
        );
        _vault.setRawTotalBalance(
            _vault.rawTotalBalance().minus(_vault.balanceActualToRaw(_amount))
        );
        _vault.transferERC20Token(ipegLogic.getCollateralToken(_vault), _to, _amount);
        ipegLogic.adjustCollateralBorrowingRate();
        _vault.emitWithdraw(msg.sender, _to, _amount);
    }

    function borrow(IVault _vault, uint256 _amount) public validate(_vault, msg.sender) {
        IPegLogic ipegLogic = pegLogic();
        require(_amount.toInt256() <= ipegLogic.availableCredit(_vault, msg.sender), "Not enough available credit");
        require(_vault.borrowingEnabled(), "Borrowing disabled");
        address auctionAddress = _vault.auctions(msg.sender);
        require(auctionAddress == address(0), "Can't borrow when there's ongoing auction on your vault");
        _vault.setRawDebt(msg.sender, _vault.rawDebt(msg.sender).plus(_vault.debtActualToRaw(_amount)));
        _vault.setTotalBorrowed(msg.sender, _vault.totalBorrowed(msg.sender).plus(_amount));
        _vault.setRawTotalDebt(_vault.rawTotalDebt().plus(_vault.debtActualToRaw(_amount)));
        if (address(_vault) == address(vaultA())) {
            stableToken().issue(msg.sender, _amount);
        } else {
            vaultA().transferERC20Token(collateralToken(), msg.sender, _amount);
        }
        ipegLogic.adjustCollateralBorrowingRate();
        _vault.emitBorrow(msg.sender, _amount);
    }

    function doPay(IVault _vault, address _payor, address _borrower, uint256 _amount, bool _all) internal {
        ISmartToken vaultDebtToken = pegLogic().getDebtToken(_vault);
        if (address(_vault) == address(vaultA())) {
            vaultDebtToken.destroy(_payor, _amount);
        } else {
            vaultDebtToken.transferFrom(_payor, address(vaultA()), _amount);
        }
        _vault.setRawTotalDebt(_vault.rawTotalDebt().minus(_vault.debtActualToRaw(_amount)));

        if(_all) {
            _vault.setRawDebt(_borrower, 0);
            _vault.setTotalBorrowed(_borrower, 0);
        } else {
            _vault.setRawDebt(_borrower, _vault.rawDebt(_borrower).minus(_vault.debtActualToRaw(_amount)));
            _vault.setTotalBorrowed(_borrower, _vault.totalBorrowed(_borrower).minus(_amount));
        }
        pegLogic().adjustCollateralBorrowingRate();
        _vault.emitRepay(_borrower, _amount);
    }

    function repay(IVault _vault, address _borrower, uint256 _amount) public validate(_vault, _borrower) {
        doPay(_vault, msg.sender, _borrower, _amount, false);
    }

    function repayAuction(IVault _vault, address _borrower, uint256 _amount) public validate(_vault, _borrower)
    {
        require(_vault.auctions(_borrower) == msg.sender, "Invalid auction");
        doPay(_vault, msg.sender, msg.sender, _amount, true);
    }

    function repayAll(IVault _vault, address _borrower) public validate(_vault, _borrower) {
        uint256 _amount = pegLogic().actualDebt(_vault, _borrower);
        doPay(_vault, msg.sender, _borrower, _amount, true);
    }

}