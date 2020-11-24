 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.12;


interface Cosigner {

    function cost(
        address engine,
        uint256 index,
        bytes calldata data,
        bytes calldata oracleData
    ) external view returns (uint256);

}

 

pragma solidity ^0.5.12;


interface IERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor()
        internal
    {
        _registerInterface(_InterfaceId_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can not register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.12;



 
contract Model is IERC165 {
     
     
     

     
    event Created(bytes32 indexed _id);

     
    event ChangedStatus(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

     
    event ChangedObligation(bytes32 indexed _id, uint256 _timestamp, uint256 _debt);

     
    event ChangedFrequency(bytes32 indexed _id, uint256 _timestamp, uint256 _frequency);

     
    event ChangedDueTime(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

     
    event ChangedFinalTime(bytes32 indexed _id, uint256 _timestamp, uint64 _dueTime);

     
    event AddedDebt(bytes32 indexed _id, uint256 _amount);

     
    event AddedPaid(bytes32 indexed _id, uint256 _paid);

     
    bytes4 internal constant MODEL_INTERFACE = 0xaf498c35;

    uint256 public constant STATUS_ONGOING = 1;
    uint256 public constant STATUS_PAID = 2;
    uint256 public constant STATUS_ERROR = 4;

     
     
     

     
    function modelId() external view returns (bytes32);

     
    function descriptor() external view returns (address);

     
    function isOperator(address operator) external view returns (bool canOperate);

     
    function validate(bytes calldata data) external view returns (bool isValid);

     
     
     

     
    function getStatus(bytes32 id) external view returns (uint256 status);

     
    function getPaid(bytes32 id) external view returns (uint256 paid);

     
    function getObligation(bytes32 id, uint64 timestamp) external view returns (uint256 amount, bool defined);

     
    function getClosingObligation(bytes32 id) external view returns (uint256 amount);

     
    function getDueTime(bytes32 id) external view returns (uint256 timestamp);

     
     
     

     
    function getFrequency(bytes32 id) external view returns (uint256 frequency);

     
    function getInstallments(bytes32 id) external view returns (uint256 installments);

     
    function getFinalTime(bytes32 id) external view returns (uint256 timestamp);

     
    function getEstimateObligation(bytes32 id) external view returns (uint256 amount);

     
     
     

     
    function create(bytes32 id, bytes calldata data) external returns (bool success);

     
    function addPaid(bytes32 id, uint256 amount) external returns (uint256 real);

     
    function addDebt(bytes32 id, uint256 amount) external returns (bool added);

     
     
     

     
    function run(bytes32 id) external returns (bool effect);
}

 

pragma solidity 0.5.12;



 
 
 
 
interface RateOracle {
    function readSample(bytes calldata _data) external returns (uint256 _tokens, uint256 _equivalent);
}

 

pragma solidity ^0.5.12;




interface DebtEngine {
    function debts(
        bytes32 _id
    ) external view returns(
        bool error,
        uint128 balance,
        Model model,
        address creator,
        RateOracle oracle
    );

    function create(
        Model _model,
        address _owner,
        address _oracle,
        bytes calldata _data
    ) external returns (bytes32 id);

    function create2(
        Model _model,
        address _owner,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external returns (bytes32 id);

    function create3(
        Model _model,
        address _owner,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external returns (bytes32 id);

    function buildId(
        address _creator,
        uint256 _nonce
    ) external view returns (bytes32);

    function buildId2(
        address _creator,
        address _model,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external view returns (bytes32);

    function buildId3(
        address _creator,
        uint256 _salt
    ) external view returns (bytes32);

    function pay(
        bytes32 _id,
        uint256 _amount,
        address _origin,
        bytes calldata _oracleData
    ) external returns (uint256 paid, uint256 paidToken);

    function payToken(
        bytes32 id,
        uint256 amount,
        address origin,
        bytes calldata oracleData
    ) external returns (uint256 paid, uint256 paidToken);

    function payBatch(
        bytes32[] calldata _ids,
        uint256[] calldata _amounts,
        address _origin,
        address _oracle,
        bytes calldata _oracleData
    ) external returns (uint256[] memory paid, uint256[] memory paidTokens);

    function payTokenBatch(
        bytes32[] calldata _ids,
        uint256[] calldata _tokenAmounts,
        address _origin,
        address _oracle,
        bytes calldata _oracleData
    ) external returns (uint256[] memory paid, uint256[] memory paidTokens);

    function withdraw(
        bytes32 _id,
        address _to
    ) external returns (uint256 amount);

    function withdrawPartial(
        bytes32 _id,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function withdrawBatch(
        bytes32[] calldata _ids,
        address _to
    ) external returns (uint256 total);

    function transferFrom(address _from, address _to, uint256 _assetId) external;

    function getStatus(bytes32 _id) external view returns (uint256);
}

 

pragma solidity 0.5.12;



contract LoanManager {
    IERC20 public token;

    function debtEngine() external view returns (DebtEngine);
    function getCurrency(uint256 _id) external view returns (bytes32);
    function getAmount(uint256 _id) external view returns (uint256);
    function getAmount(bytes32 _id) external view returns (uint256);
    function getOracle(uint256 _id) external view returns (address);

    function settleLend(
        bytes memory _requestData,
        bytes memory _loanData,
        address _cosigner,
        uint256 _maxCosignerCost,
        bytes memory _cosignerData,
        bytes memory _oracleData,
        bytes memory _creatorSig,
        bytes memory _borrowerSig
    ) public returns (bytes32 id);

    function lend(
        bytes32 _id,
        bytes memory _oracleData,
        address _cosigner,
        uint256 _cosignerLimit,
        bytes memory _cosignerData,
        bytes memory _callbackData
    ) public returns (bool);

}

 

pragma solidity 0.5.12;



interface TokenConverter {
    function convertFrom(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _minReceive
    ) external payable returns (uint256 _received);

    function convertTo(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount,
        uint256 _maxSpend
    ) external payable returns (uint256 _spend);

    function getPriceConvertFrom(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount
    ) external view returns (uint256 _receive);

    function getPriceConvertTo(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount
    ) external view returns (uint256 _spend);
}

 

pragma solidity ^0.5.12;



 
library SafeERC20 {
     
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        if (prevBalance < _value) {
             
            return false;
        }

        (bool success,) = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        if (!success || prevBalance - _value != _token.balanceOf(address(this))) {
             
            return false;
        }

        return true;
    }

     
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool)
    {
        uint256 prevBalance = _token.balanceOf(_from);

        if (prevBalance < _value) {
             
            return false;
        }

        if (_token.allowance(_from, address(this)) < _value) {
             
            return false;
        }

        (bool success,) = address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value)
        );

        if (!success || prevBalance - _value != _token.balanceOf(_from)) {
             
            return false;
        }

        return true;
    }

    
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        (bool success,) = address(_token).call(
            abi.encodeWithSignature("approve(address,uint256)",_spender, _value)
        );

        if (!success && _token.allowance(address(this), _spender) != _value) {
             
            return false;
        }

        return true;
    }

    
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            success = safeApprove(_token, _spender, 1);
        }

        return success;
    }
}

 

pragma solidity 0.5.12;






library SafeTokenConverter {
    IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function safeConvertFrom(
        TokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _minReceive
    ) internal returns (uint256 _received) {
        uint256 prevBalance = _selfBalance(_toToken);

        if (_fromToken == ETH_TOKEN_ADDRESS) {
            _converter.convertFrom.value(
                _fromAmount
            )(
                _fromToken,
                _toToken,
                _fromAmount,
                _minReceive
            );
        } else {
            require(_fromToken.safeApprove(address(_converter), _fromAmount), "error approving converter");
            _converter.convertFrom(
                _fromToken,
                _toToken,
                _fromAmount,
                _minReceive
            );

            require(_fromToken.clearApprove(address(_converter)), "error clearing approve");
        }

        _received = _selfBalance(_toToken).sub(prevBalance);
        require(_received >= _minReceive, "_minReceived not reached");
    }

    function safeConvertTo(
        TokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount,
        uint256 _maxSpend
    ) internal returns (uint256 _spend) {
        uint256 prevFromBalance = _selfBalance(_fromToken);
        uint256 prevToBalance = _selfBalance(_toToken);

        if (_fromToken == ETH_TOKEN_ADDRESS) {
            _converter.convertTo.value(
                _maxSpend
            )(
                _fromToken,
                _toToken,
                _toAmount,
                _maxSpend
            );
        } else {
            require(_fromToken.safeApprove(address(_converter), _maxSpend), "error approving converter");
            _converter.convertTo(
                _fromToken,
                _toToken,
                _toAmount,
                _maxSpend
            );

            require(_fromToken.clearApprove(address(_converter)), "error clearing approve");
        }

        _spend = prevFromBalance.sub(_selfBalance(_fromToken));
        require(_spend <= _maxSpend, "_maxSpend exceeded");
        require(_selfBalance(_toToken).sub(prevToBalance) >= _toAmount, "_toAmount not received");
    }

    function _selfBalance(IERC20 _token) private view returns (uint256) {
        if (_token == ETH_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return _token.balanceOf(address(this));
        }
    }
}

 

pragma solidity 0.5.12;


library Math {
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function divCeil(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, "div by zero");
        c = _a / _b;
        if (_a % _b != 0) {
            c = c + 1;
        }
    }
}

 

pragma solidity 0.5.12;













 
 
 
 
contract ConverterRamp is Ownable {
    using SafeTokenConverter for TokenConverter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Math for uint256;

     
    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event Return(address _token, address _to, uint256 _amount);
    event ReadedOracle(address _oracle, uint256 _tokens, uint256 _equivalent);

    DebtEngine public debtEngine;
    LoanManager public loanManager;
    IERC20 public token;

    constructor(LoanManager _loanManager) public {
        loanManager = _loanManager;
        token = _loanManager.token();
        debtEngine = _loanManager.debtEngine();
    }

    function pay(
        TokenConverter _converter,
        IERC20 _fromToken,
        uint256 _payAmount,
        uint256 _maxSpend,
        bytes32 _requestId,
        bytes calldata _oracleData
    ) external payable {
         
        DebtEngine _debtEngine = debtEngine;

         
        uint256 amount = getRequiredRcnPay(
            _debtEngine,
            _requestId,
            _payAmount,
            _oracleData
        );

         
        IERC20 _token = token;
        _pullConvertAndReturnExtra(
            _converter,
            _fromToken,
            _token,
            amount,
            _maxSpend
        );

         
         
         
        _approveOnlyOnce(_token, address(_debtEngine), amount);

         
        (, uint256 paidToken) = debtEngine.payToken(_requestId, amount, msg.sender, _oracleData);

         
         
         
        if (paidToken < amount) {
            _convertAndReturn(
                _converter,
                _token,
                _fromToken,
                amount - paidToken
            );
        }
    }

    function lend(
        TokenConverter _converter,
        IERC20 _fromToken,
        uint256 _maxSpend,
        address _cosigner,
        bytes32 _requestId,
        bytes memory _oracleData,
        bytes memory _cosignerData,
        bytes memory _callbackData
    ) public payable {
         
        LoanManager _loanManager = loanManager;

         
        uint256 amount = getRequiredRcnLend(
            _loanManager,
            _cosigner,
            _requestId,
            _oracleData,
            _cosignerData
        );

        IERC20 _token = token;
        _pullConvertAndReturnExtra(
            _converter,
            _fromToken,
            _token,
            amount,
            _maxSpend
        );

         
         
        _approveOnlyOnce(_token, address(_loanManager), amount);

        _loanManager.lend(
            _requestId,
            _oracleData,
            _cosigner,
            0,
            _cosignerData,
            _callbackData
        );

         
        debtEngine.transferFrom(address(this), msg.sender, uint256(_requestId));
    }

    function getLendCost(
        TokenConverter _converter,
        IERC20 _fromToken,
        address _cosigner,
        bytes32 _requestId,
        bytes calldata _oracleData,
        bytes calldata _cosignerData
    ) external returns (uint256) {
        uint256 amountRcn = getRequiredRcnLend(
            loanManager,
            _cosigner,
            _requestId,
            _oracleData,
            _cosignerData
        );

        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            amountRcn
        );
    }

     
    function getPayCost(
        TokenConverter _converter,
        IERC20 _fromToken,
        bytes32 _requestId,
        uint256 _amount,
        bytes calldata _oracleData
    ) external returns (uint256) {
        uint256 amountRcn = getRequiredRcnPay(
            debtEngine,
            _requestId,
            _amount,
            _oracleData
        );

        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            amountRcn
        );
    }

     
    function getRequiredRcnLend(
        LoanManager _loanManager,
        address _lenderCosignerAddress,
        bytes32 _requestId,
        bytes memory _oracleData,
        bytes memory _cosignerData
    ) internal returns (uint256) {

         
        uint256 amount = loanManager.getAmount(_requestId);

         
        Cosigner cosigner = Cosigner(_lenderCosignerAddress);

         
        if (_lenderCosignerAddress != address(0)) {
            amount = amount.add(cosigner.cost(address(_loanManager), uint256(_requestId), _cosignerData, _oracleData));
        }

         
        address oracle = loanManager.getOracle(uint256(_requestId));
        return getCurrencyToToken(oracle, amount, _oracleData);
    }

     
    function getRequiredRcnPay(
        DebtEngine _debtEngine,
        bytes32 _requestId,
        uint256 _amount,
        bytes memory _oracleData
    ) internal returns (uint256 _result) {
        (,,Model model,, RateOracle oracle) = _debtEngine.debts(_requestId);

         
        uint256 amount = Math.min(
            model.getClosingObligation(_requestId),
            _amount
        );

         
        return getCurrencyToToken(address(oracle), amount, _oracleData);
    }

     
     
    function getCurrencyToToken(
        address _oracle,
        uint256 _amount,
        bytes memory _oracleData
    ) internal returns (uint256) {
        if (_oracle == address(0)) {
            return _amount;
        }

        (uint256 tokens, uint256 equivalent) = RateOracle(_oracle).readSample(_oracleData);

        emit ReadedOracle(_oracle, tokens, equivalent);
        return tokens.mul(_amount).divCeil(equivalent);
    }

    function getPriceConvertTo(
        TokenConverter _converter,
        IERC20 _fromToken,
        uint256 _amount
    ) external view returns (uint256) {
        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            _amount
        );
    }

    function _convertAndReturn(
        TokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount
    ) private {
        uint256 buyBack = _converter.safeConvertFrom(
            _fromToken,
            _toToken,
            _amount,
            1
        );

        require(_toToken.safeTransfer(msg.sender, buyBack), "error sending extra");
    }

    function _pullConvertAndReturnExtra(
        TokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount,
        uint256 _maxSpend
    ) private {
         
        _pull(_fromToken, _maxSpend);

        uint256 spent = _converter.safeConvertTo(_fromToken, _toToken, _amount, _maxSpend);

        if (spent < _maxSpend) {
            _transfer(_fromToken, msg.sender, _maxSpend - spent);
        }
    }

    function _pull(
        IERC20 _token,
        uint256 _amount
    ) private {
        if (address(_token) == ETH_ADDRESS) {
            require(msg.value == _amount, "sent eth is not enought");
        } else {
            require(msg.value == 0, "method is not payable");
            require(_token.safeTransferFrom(msg.sender, address(this), _amount), "error pulling tokens");
        }
    }

    function _transfer(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) private {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            require(_token.safeTransfer(_to, _amount), "error sending tokens");
        }
    }

    function _approveOnlyOnce(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) private {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _amount) {
            if (allowance != 0) {
                _token.clearApprove(_spender);
            }

            _token.approve(_spender, uint(-1));
        }
    }

    function emergencyWithdraw(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

    function() external payable {
         
        require(tx.origin != msg.sender, "ramp: send eth rejected");
    }
}