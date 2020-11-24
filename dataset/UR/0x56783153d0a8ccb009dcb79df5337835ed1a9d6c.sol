 

pragma solidity ^0.4.24;

 

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

 

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

 

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
}

 
contract Cosigner {
    uint256 public constant VERSION = 2;
    
     
    function url() public view returns (string);
    
     
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);
    
     
    function requestCosign(address engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
     
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
}

contract ERC721 {
    
   function name() public view returns (string _name);
   function symbol() public view returns (string _symbol);
   function totalSupply() public view returns (uint256 _totalSupply);
   function balanceOf(address _owner) public view returns (uint _balance);
    
   function ownerOf(uint256) public view returns (address owner);
   function approve(address, uint256) public returns (bool);
   function takeOwnership(uint256) public returns (bool);
   function transfer(address, uint256) public returns (bool);
   function setApprovalForAll(address _operator, bool _approved) public returns (bool);
   function getApproved(uint256 _tokenId) public view returns (address);
   function isApprovedForAll(address _owner, address _operator) public view returns (bool);
    
   function tokenMetadata(uint256 _tokenId) public view returns (string info);
    
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

     
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
} 

 
contract Oracle is Ownable {
    uint256 public constant VERSION = 3;

    event NewSymbol(bytes32 _currency, string _ticker);
    
    struct Symbol {
        string ticker;
        bool supported;
    }

    mapping(bytes32 => Symbol) public currencies;

     
    function url() public view returns (string);

     
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

     
    function addCurrency(string ticker) public onlyOwner returns (bytes32) {
        NewSymbol(currency, ticker);
        bytes32 currency = keccak256(ticker);
        currencies[currency] = Symbol(ticker, true);
        return currency;
    }

     
    function supported(bytes32 symbol) public view returns (bool) {
        return currencies[symbol].supported;
    }
}

contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}

contract TokenLockable is RpSafeMath, Ownable {
    mapping(address => uint256) public lockedTokens;

     
    function lockTokens(address token, uint256 amount) internal {
        lockedTokens[token] = safeAdd(lockedTokens[token], amount);
    }

     
    function unlockTokens(address token, uint256 amount) internal {
        lockedTokens[token] = safeSubtract(lockedTokens[token], amount);
    }

     
    function withdrawTokens(Token token, address to, uint256 amount) public onlyOwner returns (bool) {
        require(safeSubtract(token.balanceOf(this), lockedTokens[token]) >= amount);
        require(to != address(0));
        return token.transfer(to, amount);
    }
}

contract NanoLoanEngine is Ownable, TokenLockable {
    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal RCN_DECIMALS = 18;

    uint256 public constant VERSION = 232;
    string public constant VERSION_NAME = "Basalt";

    uint256 private activeLoans = 0;
    mapping(address => uint256) private lendersBalance;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function name() public view returns (string _name) {
        _name = "RCN - Nano loan engine - Basalt 232";
    }

    function symbol() public view returns (string _symbol) {
        _symbol = "RCN-NLE-232";
    }

     
    function totalSupply() public view returns (uint _totalSupply) {
        _totalSupply = activeLoans;
    }

     
    function balanceOf(address _owner) public view returns (uint _balance) {
        _balance = lendersBalance[_owner];
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalLoans = loans.length - 1;
            uint256 resultIndex = 0;

            uint256 loanId;

            for (loanId = 0; loanId <= totalLoans; loanId++) {
                if (loans[loanId].lender == _owner && loans[loanId].status == Status.lent) {
                    result[resultIndex] = loanId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
    function tokenMetadata(uint256 index) public view returns (string) {
        return loans[index].metadata;
    }

     
    function tokenMetadataHash(uint256 index) public view returns (bytes32) {
        return keccak256(loans[index].metadata);
    }

    Token public rcn;
    bool public deprecated;

    event CreatedLoan(uint _index, address _borrower, address _creator);
    event ApprovedBy(uint _index, address _address);
    event Lent(uint _index, address _lender, address _cosigner);
    event DestroyedBy(uint _index, address _address);
    event PartialPayment(uint _index, address _sender, address _from, uint256 _amount);
    event TotalPayment(uint _index);

    function NanoLoanEngine(Token _rcn) public {
        owner = msg.sender;
        rcn = _rcn;
         
        loans.length++;
    }
    enum Status { initial, lent, paid, destroyed }

    struct Loan {
        Status status;
        Oracle oracle;

        address borrower;
        address lender;
        address creator;
        address cosigner;
        
        uint256 amount;
        uint256 interest;
        uint256 punitoryInterest;
        uint256 interestTimestamp;
        uint256 paid;
        uint256 interestRate;
        uint256 interestRatePunitory;
        uint256 dueTime;
        uint256 duesIn;

        bytes32 currency;
        uint256 cancelableAt;
        uint256 lenderBalance;

        address approvedTransfer;
        uint256 expirationRequest;

        string metadata;
        mapping(address => bool) approbations;
    }

    mapping(bytes32 => uint256) public identifierToIndex;
    Loan[] private loans;

     
    function createLoan(Oracle _oracleContract, address _borrower, bytes32 _currency, uint256 _amount, uint256 _interestRate,
        uint256 _interestRatePunitory, uint256 _duesIn, uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256) {

        require(!deprecated);
        require(_cancelableAt <= _duesIn);
        require(_oracleContract != address(0) || _currency == 0x0);
        require(_borrower != address(0));
        require(_amount != 0);
        require(_interestRatePunitory != 0);
        require(_interestRate != 0);
        require(_expirationRequest > block.timestamp);

        var loan = Loan(Status.initial, _oracleContract, _borrower, 0x0, msg.sender, 0x0, _amount, 0, 0, 0, 0, _interestRate,
            _interestRatePunitory, 0, _duesIn, _currency, _cancelableAt, 0, 0x0, _expirationRequest, _metadata);

        uint index = loans.push(loan) - 1;
        CreatedLoan(index, _borrower, msg.sender);

        bytes32 identifier = getIdentifier(index);
        require(identifierToIndex[identifier] == 0);
        identifierToIndex[identifier] = index;

        if (msg.sender == _borrower) {
            approveLoan(index);
        }

        return index;
    }
    
    function ownerOf(uint256 index) public view returns (address owner) { owner = loans[index].lender; }
    function getTotalLoans() public view returns (uint256) { return loans.length; }
    function getOracle(uint index) public view returns (Oracle) { return loans[index].oracle; }
    function getBorrower(uint index) public view returns (address) { return loans[index].borrower; }
    function getCosigner(uint index) public view returns (address) { return loans[index].cosigner; }
    function getCreator(uint index) public view returns (address) { return loans[index].creator; }
    function getAmount(uint index) public view returns (uint256) { return loans[index].amount; }
    function getPunitoryInterest(uint index) public view returns (uint256) { return loans[index].punitoryInterest; }
    function getInterestTimestamp(uint index) public view returns (uint256) { return loans[index].interestTimestamp; }
    function getPaid(uint index) public view returns (uint256) { return loans[index].paid; }
    function getInterestRate(uint index) public view returns (uint256) { return loans[index].interestRate; }
    function getInterestRatePunitory(uint index) public view returns (uint256) { return loans[index].interestRatePunitory; }
    function getDueTime(uint index) public view returns (uint256) { return loans[index].dueTime; }
    function getDuesIn(uint index) public view returns (uint256) { return loans[index].duesIn; }
    function getCancelableAt(uint index) public view returns (uint256) { return loans[index].cancelableAt; }
    function getApprobation(uint index, address _address) public view returns (bool) { return loans[index].approbations[_address]; }
    function getStatus(uint index) public view returns (Status) { return loans[index].status; }
    function getLenderBalance(uint index) public view returns (uint256) { return loans[index].lenderBalance; }
    function getApproved(uint index) public view returns (address) {return loans[index].approvedTransfer; }
    function getCurrency(uint index) public view returns (bytes32) { return loans[index].currency; }
    function getExpirationRequest(uint index) public view returns (uint256) { return loans[index].expirationRequest; }
    function getInterest(uint index) public view returns (uint256) { return loans[index].interest; }

    function getIdentifier(uint index) public view returns (bytes32) {
        Loan memory loan = loans[index];
        return buildIdentifier(loan.oracle, loan.borrower, loan.creator, loan.currency, loan.amount, loan.interestRate,
            loan.interestRatePunitory, loan.duesIn, loan.cancelableAt, loan.expirationRequest, loan.metadata);
    }

     
    function buildIdentifier(Oracle oracle, address borrower, address creator, bytes32 currency, uint256 amount, uint256 interestRate,
        uint256 interestRatePunitory, uint256 duesIn, uint256 cancelableAt, uint256 expirationRequest, string metadata) view returns (bytes32) {
        return keccak256(this, oracle, borrower, creator, currency, amount, interestRate, interestRatePunitory, duesIn,
                        cancelableAt, expirationRequest, metadata); 
    }

     
    function isApproved(uint index) public view returns (bool) {
        Loan storage loan = loans[index];
        return loan.approbations[loan.borrower];
    }

     
    function approveLoan(uint index) public returns(bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.initial);
        loan.approbations[msg.sender] = true;
        ApprovedBy(index, msg.sender);
        return true;
    }

     
    function approveLoanIdentifier(bytes32 identifier) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        return approveLoan(index);
    }

     
    function registerApprove(bytes32 identifier, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        Loan storage loan = loans[index];
        require(loan.borrower == ecrecover(keccak256("\x19Ethereum Signed Message:\n32", identifier), v, r, s));
        loan.approbations[loan.borrower] = true;
        ApprovedBy(index, loan.borrower);
        return true;
    }

     
    function lend(uint index, bytes oracleData, Cosigner cosigner, bytes cosignerData) public returns (bool) {
        Loan storage loan = loans[index];

        require(loan.status == Status.initial);
        require(isApproved(index));
        require(block.timestamp <= loan.expirationRequest);

        loan.lender = msg.sender;
        loan.dueTime = safeAdd(block.timestamp, loan.duesIn);
        loan.interestTimestamp = block.timestamp;
        loan.status = Status.lent;

         
        Transfer(0x0, loan.lender, index);
        activeLoans += 1;
        lendersBalance[loan.lender] += 1;
        
        if (loan.cancelableAt > 0)
            internalAddInterest(loan, safeAdd(block.timestamp, loan.cancelableAt));

         
         
        uint256 transferValue = convertRate(loan.oracle, loan.currency, oracleData, loan.amount);
        require(rcn.transferFrom(msg.sender, loan.borrower, transferValue));
        
        if (cosigner != address(0)) {
             
             
             
            loan.cosigner = address(uint256(cosigner) + 2);
            require(cosigner.requestCosign(this, index, cosignerData, oracleData));
            require(loan.cosigner == address(cosigner));
        }
                
        Lent(index, loan.lender, cosigner);

        return true;
    }

     
    function cosign(uint index, uint256 cost) external returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent && (loan.dueTime - loan.duesIn) == block.timestamp);
        require(loan.cosigner != address(0));
        require(loan.cosigner == address(uint256(msg.sender) + 2));
        loan.cosigner = msg.sender;
        require(rcn.transferFrom(loan.lender, msg.sender, cost));
        return true;
    }

     
    function destroy(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status != Status.destroyed);
        require(msg.sender == loan.lender || (msg.sender == loan.borrower && loan.status == Status.initial));
        DestroyedBy(index, msg.sender);

         
        if (loan.status != Status.initial) {
            lendersBalance[loan.lender] -= 1;
            activeLoans -= 1;
            Transfer(loan.lender, 0x0, index);
        }

        loan.status = Status.destroyed;
        return true;
    }

     
    function destroyIdentifier(bytes32 identifier) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        return destroy(index);
    }

     
    function transfer(address to, uint256 index) public returns (bool) {
        Loan storage loan = loans[index];
        
        require(msg.sender == loan.lender || msg.sender == loan.approvedTransfer);
        require(to != address(0));
        loan.lender = to;
        loan.approvedTransfer = address(0);

         
        lendersBalance[msg.sender] -= 1;
        lendersBalance[to] += 1;
        Transfer(loan.lender, to, index);

        return true;
    }

     
    function takeOwnership(uint256 _index) public returns (bool) {
        return transfer(msg.sender, _index);
    }

     
    function transferFrom(address from, address to, uint256 index) public returns (bool) {
        require(loans[index].lender == from);
        return transfer(to, index);
    }

     
    function approve(address to, uint256 index) public returns (bool) {
        Loan storage loan = loans[index];
        require(msg.sender == loan.lender);
        loan.approvedTransfer = to;
        Approval(msg.sender, to, index);
        return true;
    }

     
    function getPendingAmount(uint index) public returns (uint256) {
        addInterest(index);
        return getRawPendingAmount(index);
    }

     
    function getRawPendingAmount(uint index) public view returns (uint256) {
        Loan memory loan = loans[index];
        return safeSubtract(safeAdd(safeAdd(loan.amount, loan.interest), loan.punitoryInterest), loan.paid);
    }

     
    function calculateInterest(uint256 timeDelta, uint256 interestRate, uint256 amount) internal pure returns (uint256 realDelta, uint256 interest) {
        if (amount == 0) {
            interest = 0;
            realDelta = timeDelta;
        } else {
            interest = safeMult(safeMult(100000, amount), timeDelta) / interestRate;
            realDelta = safeMult(interest, interestRate) / (amount * 100000);
        }
    }

     
    function internalAddInterest(Loan storage loan, uint256 timestamp) internal {
        if (timestamp > loan.interestTimestamp) {
            uint256 newInterest = loan.interest;
            uint256 newPunitoryInterest = loan.punitoryInterest;

            uint256 newTimestamp;
            uint256 realDelta;
            uint256 calculatedInterest;

            uint256 deltaTime;
            uint256 pending;

            uint256 endNonPunitory = min(timestamp, loan.dueTime);
            if (endNonPunitory > loan.interestTimestamp) {
                deltaTime = endNonPunitory - loan.interestTimestamp;

                if (loan.paid < loan.amount) {
                    pending = loan.amount - loan.paid;
                } else {
                    pending = 0;
                }

                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRate, pending);
                newInterest = safeAdd(calculatedInterest, newInterest);
                newTimestamp = loan.interestTimestamp + realDelta;
            }

            if (timestamp > loan.dueTime) {
                uint256 startPunitory = max(loan.dueTime, loan.interestTimestamp);
                deltaTime = timestamp - startPunitory;

                uint256 debt = safeAdd(loan.amount, newInterest);
                pending = min(debt, safeSubtract(safeAdd(debt, newPunitoryInterest), loan.paid));

                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRatePunitory, pending);
                newPunitoryInterest = safeAdd(newPunitoryInterest, calculatedInterest);
                newTimestamp = startPunitory + realDelta;
            }
            
            if (newInterest != loan.interest || newPunitoryInterest != loan.punitoryInterest) {
                loan.interestTimestamp = newTimestamp;
                loan.interest = newInterest;
                loan.punitoryInterest = newPunitoryInterest;
            }
        }
    }

     
    function addInterest(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent);
        internalAddInterest(loan, block.timestamp);
    }
    
     
    function pay(uint index, uint256 _amount, address _from, bytes oracleData) public returns (bool) {
        Loan storage loan = loans[index];

        require(loan.status == Status.lent);
        addInterest(index);
        uint256 toPay = min(getPendingAmount(index), _amount);
        PartialPayment(index, msg.sender, _from, toPay);

        loan.paid = safeAdd(loan.paid, toPay);

        if (getRawPendingAmount(index) == 0) {
            TotalPayment(index);
            loan.status = Status.paid;

             
            lendersBalance[loan.lender] -= 1;
            activeLoans -= 1;
            Transfer(loan.lender, 0x0, index);
        }

        uint256 transferValue = convertRate(loan.oracle, loan.currency, oracleData, toPay);
        require(transferValue > 0 || toPay < _amount);

        lockTokens(rcn, transferValue);
        require(rcn.transferFrom(msg.sender, this, transferValue));
        loan.lenderBalance = safeAdd(transferValue, loan.lenderBalance);

        return true;
    }

     
    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) public view returns (uint256) {
        if (oracle == address(0)) {
            return amount;
        } else {
            uint256 rate;
            uint256 decimals;
            
            (rate, decimals) = oracle.getRate(currency, data);

            require(decimals <= RCN_DECIMALS);
            return (safeMult(safeMult(amount, rate), (10**(RCN_DECIMALS-decimals)))) / PRECISION;
        }
    }

     
    function withdrawal(uint index, address to, uint256 amount) public returns (bool) {
        Loan storage loan = loans[index];
        require(msg.sender == loan.lender);
        loan.lenderBalance = safeSubtract(loan.lenderBalance, amount);
        require(rcn.transfer(to, amount));
        unlockTokens(rcn, amount);
        return true;
    }
    
     
    function setDeprecated(bool _deprecated) public onlyOwner {
        deprecated = _deprecated;
    }
}

 

library LrpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
            return a;
        } else { 
            return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
            return a;
        } else { 
            return b; 
        }
    }
}

 

contract ConverterRamp is Ownable {
    using LrpSafeMath for uint256;

    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    uint256 public constant AUTO_MARGIN = 1000001;
     
    uint256 public constant I_MARGIN_SPEND = 0;     
    uint256 public constant I_MAX_SPEND = 1;        
    uint256 public constant I_REBUY_THRESHOLD = 2;  
     
    uint256 public constant I_ENGINE = 0;      
    uint256 public constant I_INDEX = 1;       
     
    uint256 public constant I_PAY_AMOUNT = 2;  
    uint256 public constant I_PAY_FROM = 3;    
     
    uint256 public constant I_LEND_COSIGNER = 2;  

    event RequiredRebuy(address token, uint256 amount);
    event Return(address token, address to, uint256 amount);
    event OptimalSell(address token, uint256 amount);
    event RequiredRcn(uint256 required);
    event RunAutoMargin(uint256 loops, uint256 increment);

    function pay(
        TokenConverter converter,
        Token fromToken,
        bytes32[4] loanParams,
        bytes oracleData,
        uint256[3] convertRules
    ) external payable returns (bool) {
        Token rcn = NanoLoanEngine(address(loanParams[I_ENGINE])).rcn();

        uint256 initialBalance = rcn.balanceOf(this);
        uint256 requiredRcn = getRequiredRcnPay(loanParams, oracleData);
        emit RequiredRcn(requiredRcn);

        uint256 optimalSell = getOptimalSell(converter, fromToken, rcn, requiredRcn, convertRules[I_MARGIN_SPEND]);
        emit OptimalSell(fromToken, optimalSell);

        pullAmount(fromToken, optimalSell);
        uint256 bought = convertSafe(converter, fromToken, rcn, optimalSell);

         
        require(
            executeOptimalPay({
                params: loanParams,
                oracleData: oracleData,
                rcnToPay: bought
            }),
            "Error paying the loan"
        );

        require(
            rebuyAndReturn({
                converter: converter,
                fromToken: rcn,
                toToken: fromToken,
                amount: rcn.balanceOf(this) - initialBalance,
                spentAmount: optimalSell,
                convertRules: convertRules
            }),
            "Error rebuying the tokens"
        );

        require(rcn.balanceOf(this) == initialBalance, "Converter balance has incremented");
        return true;
    }

    function requiredLendSell(
        TokenConverter converter,
        Token fromToken,
        bytes32[3] loanParams,
        bytes oracleData,
        bytes cosignerData,
        uint256[3] convertRules
    ) external view returns (uint256) {
        Token rcn = NanoLoanEngine(address(loanParams[I_ENGINE])).rcn();
        return getOptimalSell(
            converter,
            fromToken,
            rcn,
            getRequiredRcnLend(loanParams, oracleData, cosignerData),
            convertRules[I_MARGIN_SPEND]
        );
    }

    function requiredPaySell(
        TokenConverter converter,
        Token fromToken,
        bytes32[4] loanParams,
        bytes oracleData,
        uint256[3] convertRules
    ) external view returns (uint256) {
        Token rcn = NanoLoanEngine(address(loanParams[I_ENGINE])).rcn();
        return getOptimalSell(
            converter,
            fromToken,
            rcn,
            getRequiredRcnPay(loanParams, oracleData),
            convertRules[I_MARGIN_SPEND]
        );
    }

    function lend(
        TokenConverter converter,
        Token fromToken,
        bytes32[3] loanParams,
        bytes oracleData,
        bytes cosignerData,
        uint256[3] convertRules
    ) external payable returns (bool) {
        Token rcn = NanoLoanEngine(address(loanParams[I_ENGINE])).rcn();
        uint256 initialBalance = rcn.balanceOf(this);
        uint256 requiredRcn = getRequiredRcnLend(loanParams, oracleData, cosignerData);
        emit RequiredRcn(requiredRcn);
        
        uint256 optimalSell = getOptimalSell(converter, fromToken, rcn, requiredRcn, convertRules[I_MARGIN_SPEND]);
        emit OptimalSell(fromToken, optimalSell);
        
        pullAmount(fromToken, optimalSell);
        uint256 bought = convertSafe(converter, fromToken, rcn, optimalSell);

         
        require(rcn.approve(address(loanParams[0]), bought), "Error approving lend token transfer");
        require(executeLend(loanParams, oracleData, cosignerData), "Error lending the loan");
        require(rcn.approve(address(loanParams[0]), 0), "Error removing approve");
        require(executeTransfer(loanParams, msg.sender), "Error transfering the loan");

        require(
            rebuyAndReturn({
                converter: converter,
                fromToken: rcn,
                toToken: fromToken,
                amount: rcn.balanceOf(this) - initialBalance,
                spentAmount: optimalSell,
                convertRules: convertRules
            }),
            "Error rebuying the tokens"
        );

        require(rcn.balanceOf(this) == initialBalance, "The contract balance should not change");
        
        return true;
    }

    function pullAmount(
        Token token,
        uint256 amount
    ) private {
        if (token == ETH_ADDRESS) {
            require(msg.value >= amount, "Error pulling ETH amount");
            if (msg.value > amount) {
                msg.sender.transfer(msg.value - amount);
            }
        } else {
            require(token.transferFrom(msg.sender, this, amount), "Error pulling Token amount");
        }
    }

    function transfer(
        Token token,
        address to,
        uint256 amount
    ) private {
        if (token == ETH_ADDRESS) {
            to.transfer(amount);
        } else {
            require(token.transfer(to, amount), "Error sending tokens");
        }
    }

    function rebuyAndReturn(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 amount,
        uint256 spentAmount,
        uint256[3] memory convertRules
    ) internal returns (bool) {
        uint256 threshold = convertRules[I_REBUY_THRESHOLD];
        uint256 bought = 0;

        if (amount != 0) {
            if (amount > threshold) {
                bought = convertSafe(converter, fromToken, toToken, amount);
                emit RequiredRebuy(toToken, amount);
                emit Return(toToken, msg.sender, bought);
                transfer(toToken, msg.sender, bought);
            } else {
                emit Return(fromToken, msg.sender, amount);
                transfer(fromToken, msg.sender, amount);
            }
        }

        uint256 maxSpend = convertRules[I_MAX_SPEND];
        require(spentAmount.safeSubtract(bought) <= maxSpend || maxSpend == 0, "Max spend exceeded");
        
        return true;
    }

    function getOptimalSell(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 requiredTo,
        uint256 extraSell
    ) internal returns (uint256 sellAmount) {
        uint256 sellRate = (10 ** 18 * converter.getReturn(toToken, fromToken, requiredTo)) / requiredTo;
        if (extraSell == AUTO_MARGIN) {
            uint256 expectedReturn = 0;
            uint256 optimalSell = applyRate(requiredTo, sellRate);
            uint256 increment = applyRate(requiredTo / 100000, sellRate);
            uint256 returnRebuy;
            uint256 cl;

            while (expectedReturn < requiredTo && cl < 10) {
                optimalSell += increment;
                returnRebuy = converter.getReturn(fromToken, toToken, optimalSell);
                optimalSell = (optimalSell * requiredTo) / returnRebuy;
                expectedReturn = returnRebuy;
                cl++;
            }
            emit RunAutoMargin(cl, increment);

            return optimalSell;
        } else {
            return applyRate(requiredTo, sellRate).safeMult(uint256(100000).safeAdd(extraSell)) / 100000;
        }
    }

    function convertSafe(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 amount
    ) internal returns (uint256 bought) {
        if (fromToken != ETH_ADDRESS) require(fromToken.approve(converter, amount), "Error approving token transfer");
        uint256 prevBalance = toToken != ETH_ADDRESS ? toToken.balanceOf(this) : address(this).balance;
        uint256 sendEth = fromToken == ETH_ADDRESS ? amount : 0;
        uint256 boughtAmount = converter.convert.value(sendEth)(fromToken, toToken, amount, 1);
        require(
            boughtAmount == (toToken != ETH_ADDRESS ? toToken.balanceOf(this) : address(this).balance) - prevBalance,
            "Bought amound does does not match"
        );
        if (fromToken != ETH_ADDRESS) require(fromToken.approve(converter, 0), "Error removing token approve");
        return boughtAmount;
    }

    function executeOptimalPay(
        bytes32[4] memory params,
        bytes oracleData,
        uint256 rcnToPay
    ) internal returns (bool) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        Oracle oracle = engine.getOracle(index);

        uint256 toPay;

        if (oracle == address(0)) {
            toPay = rcnToPay;
        } else {
            uint256 rate;
            uint256 decimals;
            bytes32 currency = engine.getCurrency(index);

            (rate, decimals) = oracle.getRate(currency, oracleData);
            toPay = ((rcnToPay * 1000000000000000000) / rate) / 10 ** (18 - decimals);
        }

        Token rcn = engine.rcn();
        require(rcn.approve(engine, rcnToPay), "Error on payment approve");
        require(engine.pay(index, toPay, address(params[I_PAY_FROM]), oracleData), "Error paying the loan");
        require(rcn.approve(engine, 0), "Error removing the payment approve");
        
        return true;
    }

    function executeLend(
        bytes32[3] memory params,
        bytes oracleData,
        bytes cosignerData
    ) internal returns (bool) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        return engine.lend(index, oracleData, Cosigner(address(params[I_LEND_COSIGNER])), cosignerData);
    }

    function executeTransfer(
        bytes32[3] memory params,
        address to
    ) internal returns (bool) {
        return NanoLoanEngine(address(params[I_ENGINE])).transfer(to, uint256(params[1]));
    }

    function applyRate(
        uint256 amount,
        uint256 rate
    ) internal pure returns (uint256) {
        return amount.safeMult(rate) / 10 ** 18;
    }

    function getRequiredRcnLend(
        bytes32[3] memory params,
        bytes oracleData,
        bytes cosignerData
    ) internal view returns (uint256 required) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        Cosigner cosigner = Cosigner(address(params[I_LEND_COSIGNER]));

        if (cosigner != address(0)) {
            required += cosigner.cost(engine, index, cosignerData, oracleData);
        }
        required += engine.convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, engine.getAmount(index));
    }
    
    function getRequiredRcnPay(
        bytes32[4] memory params,
        bytes oracleData
    ) internal view returns (uint256) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        uint256 amount = uint256(params[I_PAY_AMOUNT]);
        return engine.convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, amount);
    }

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        return _token.transfer(_to, _amount);
    }

    function withdrawEther(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _to.transfer(_amount);
    }

    function() external payable {}
    
}