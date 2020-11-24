 

pragma solidity ^0.5.8;


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

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

interface FundsInterface {
    function lender(bytes32) external view returns (address);
    function custom(bytes32) external view returns (bool);
    function deposit(bytes32, uint256) external;
    function decreaseTotalBorrow(uint256) external;
    function calcGlobalInterest() external;
}

interface SalesInterface {
    function saleIndexByLoan(bytes32, uint256) external returns(bytes32);
    function settlementExpiration(bytes32) external view returns (uint256);
    function accepted(bytes32) external view returns (bool);
    function next(bytes32) external view returns (uint256);
    function create(bytes32, address, address, address, address, bytes32, bytes32, bytes32, bytes32, bytes20) external returns(bytes32);
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant COL  = 10 ** 8;
    uint constant WAD  = 10 ** 18;
    uint constant RAY  = 10 ** 27;

    function cmul(uint x, uint y) public pure returns (uint z) {
        z = add(mul(x, y), COL / 2) / COL;
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function cdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, COL), y / 2) / y;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract Medianizer {
    function peek() public view returns (bytes32, bool);
    function read() public returns (bytes32);
    function poke() public;
    function poke(bytes32) public;
    function fund (uint256 amount, ERC20 token) public;
}

contract Loans is DSMath {
    FundsInterface funds;
    Medianizer med;
    SalesInterface sales;

    uint256 public constant APPROVE_EXP_THRESHOLD = 2 hours;    
    uint256 public constant ACCEPT_EXP_THRESHOLD = 2 days;      
    uint256 public constant LIQUIDATION_EXP_THRESHOLD = 7 days; 
    uint256 public constant SEIZURE_EXP_THRESHOLD = 2 days;     
    uint256 public constant LIQUIDATION_DISCOUNT = 930000000000000000; 

    mapping (bytes32 => Loan)         public loans;
    mapping (bytes32 => PubKeys)      public pubKeys;      
    mapping (bytes32 => SecretHashes) public secretHashes; 
    mapping (bytes32 => Bools)        public bools;        
    mapping (bytes32 => bytes32)      public fundIndex;    
    mapping (bytes32 => ERC20)        public tokes;        
    mapping (bytes32 => uint256)      public repayments;   
    uint256                           public loanIndex;    

    mapping (address => bytes32[])    public borrowerLoans;
    mapping (address => bytes32[])    public lenderLoans;

    ERC20 public token; 
    uint256 public decimals;

    address deployer;

    
    struct Loan {
    	address borrower;
        address lender;
        address arbiter;
        uint256 createdAt;
        uint256 loanExpiration;
        uint256 requestTimestamp;
        uint256 closedTimestamp;
        uint256 principal;
        uint256 interest;
        uint256 penalty;
        uint256 fee;
        uint256 collateral;
        uint256 liquidationRatio;
    }

    
    struct PubKeys {
        bytes   borrowerPubKey;
        bytes   lenderPubKey;
        bytes   arbiterPubKey;
    }

    
    struct SecretHashes {
    	bytes32    secretHashA1;
    	bytes32[3] secretHashAs;
    	bytes32    secretHashB1;
    	bytes32[3] secretHashBs;
    	bytes32    secretHashC1;
    	bytes32[3] secretHashCs;
        bytes32    withdrawSecret;
        bytes32    acceptSecret;
    	bool       set;
    }

    
    struct Bools {
    	bool funded;
    	bool approved;
    	bool withdrawn;
    	bool sale;
    	bool paid;
    	bool off;
    }

    event Create(bytes32 loan);

    function borrower(bytes32 loan) public view returns (address) {
        return loans[loan].borrower;
    }

    function lender(bytes32 loan) public view returns (address) {
        return loans[loan].lender;
    }

    function arbiter(bytes32 loan)  public view returns (address) {
        return loans[loan].arbiter;
    }

    function approveExpiration(bytes32 loan) public view returns (uint256) { 
        return add(loans[loan].createdAt, APPROVE_EXP_THRESHOLD);
    }

    

    function acceptExpiration(bytes32 loan) public view returns (uint256) { 
        return add(loans[loan].loanExpiration, ACCEPT_EXP_THRESHOLD);
    }

    function liquidationExpiration(bytes32 loan) public view returns (uint256) { 
        return add(loans[loan].loanExpiration, LIQUIDATION_EXP_THRESHOLD);
    }

    function seizureExpiration(bytes32 loan) public view returns (uint256) {
        return add(liquidationExpiration(loan), SEIZURE_EXP_THRESHOLD);
    }

    function principal(bytes32 loan) public view returns (uint256) {
        return loans[loan].principal;
    }

    function interest(bytes32 loan) public view returns (uint256) {
        return loans[loan].interest;
    }

    function fee(bytes32 loan) public view returns (uint256) {
        return loans[loan].fee;
    }

    function penalty(bytes32 loan) public view returns (uint256) {
        return loans[loan].penalty;
    }

    function collateral(bytes32 loan) public view returns (uint256) {
        return loans[loan].collateral;
    }

    function repaid(bytes32 loan) public view returns (uint256) { 
        return repayments[loan];
    }

    function liquidationRatio(bytes32 loan) public view returns (uint256) {
        return loans[loan].liquidationRatio;
    }

    function owedToLender(bytes32 loan) public view returns (uint256) { 
        return add(principal(loan), interest(loan));
    }

    function owedForLoan(bytes32 loan) public view returns (uint256) { 
        return add(owedToLender(loan), fee(loan));
    }

    function owedForLiquidation(bytes32 loan) public view returns (uint256) { 
        return add(owedForLoan(loan), penalty(loan));
    }

    function owing(bytes32 loan) public view returns (uint256) {
        return sub(owedForLoan(loan), repaid(loan));
    }

    function funded(bytes32 loan) public view returns (bool) {
        return bools[loan].funded;
    }

    function approved(bytes32 loan) public view returns (bool) {
        return bools[loan].approved;
    }

    function withdrawn(bytes32 loan) public view returns (bool) {
        return bools[loan].withdrawn;
    }

    function sale(bytes32 loan) public view returns (bool) {
        return bools[loan].sale;
    }

    function paid(bytes32 loan) public view returns (bool) {
        return bools[loan].paid;
    }

    function off(bytes32 loan) public view returns (bool) {
        return bools[loan].off;
    }

    function dmul(uint x) public view returns (uint256) {
        return mul(x, (10 ** sub(18, decimals)));
    }

    function ddiv(uint x) public view returns (uint256) {
        return div(x, (10 ** sub(18, decimals)));
    }

    function borrowerLoanCount(address borrower_) public view returns (uint256) {
        return borrowerLoans[borrower_].length;
    }

    function lenderLoanCount(address lender_) public view returns (uint256) {
        return lenderLoans[lender_].length;
    }

    function collateralValue(bytes32 loan) public view returns (uint256) { 
        (bytes32 val, bool set) = med.peek();
        require(set);
        uint256 price = uint(val);
        return cmul(price, collateral(loan)); 
    }

    function minCollateralValue(bytes32 loan) public view returns (uint256) {  
        return rmul(dmul(sub(principal(loan), repaid(loan))), liquidationRatio(loan));
    }

    function discountCollateralValue(bytes32 loan) public view returns (uint256) {
        return wmul(collateralValue(loan), LIQUIDATION_DISCOUNT);
    }

    function safe(bytes32 loan) public view returns (bool) { 
        return collateralValue(loan) >= minCollateralValue(loan);
    }

    constructor (FundsInterface funds_, Medianizer med_, ERC20 token_, uint256 decimals_) public {
        deployer = msg.sender;
    	funds    = funds_;
    	med      = med_;
        token    = token_;
        decimals = decimals_;
        require(token.approve(address(funds), 2**256-1));
    }

    
    function setSales(SalesInterface sales_) external {
        require(msg.sender == deployer);
        require(address(sales) == address(0));
        sales = sales_;
    }
    
    
    function create(
        uint256             loanExpiration_,
        address[3] calldata usrs_,
        uint256[7] calldata vals_,
        bytes32             fundIndex_
    ) external returns (bytes32 loan) {
        if (fundIndex_ != bytes32(0)) { require(funds.lender(fundIndex_) == usrs_[1]); }
        loanIndex = add(loanIndex, 1);
        loan = bytes32(loanIndex);
        loans[loan].createdAt        = now;
        loans[loan].loanExpiration   = loanExpiration_;
        loans[loan].borrower         = usrs_[0];
        loans[loan].lender           = usrs_[1];
        loans[loan].arbiter          = usrs_[2];
        loans[loan].principal        = vals_[0];
        loans[loan].interest         = vals_[1];
        loans[loan].penalty          = vals_[2];
        loans[loan].fee              = vals_[3];
        loans[loan].collateral       = vals_[4];
        loans[loan].liquidationRatio = vals_[5];
        loans[loan].requestTimestamp = vals_[6];
        fundIndex[loan]              = fundIndex_;
        secretHashes[loan].set       = false;
        borrowerLoans[usrs_[0]].push(bytes32(loanIndex));
        lenderLoans[usrs_[1]].push(bytes32(loanIndex));

        emit Create(loan);
    }

    
    function setSecretHashes(
    	bytes32             loan,
        bytes32[4] calldata borrowerSecretHashes,
        bytes32[4] calldata lenderSecretHashes,
        bytes32[4] calldata arbiterSecretHashes,
		bytes      calldata borrowerPubKey_,
        bytes      calldata lenderPubKey_,
        bytes      calldata arbiterPubKey_
	) external returns (bool) {
		require(!secretHashes[loan].set);
		require(msg.sender == loans[loan].borrower || msg.sender == loans[loan].lender || msg.sender == address(funds));
		secretHashes[loan].secretHashA1 = borrowerSecretHashes[0];
		secretHashes[loan].secretHashAs = [ borrowerSecretHashes[1], borrowerSecretHashes[2], borrowerSecretHashes[3] ];
		secretHashes[loan].secretHashB1 = lenderSecretHashes[0];
		secretHashes[loan].secretHashBs = [ lenderSecretHashes[1], lenderSecretHashes[2], lenderSecretHashes[3] ];
		secretHashes[loan].secretHashC1 = arbiterSecretHashes[0];
		secretHashes[loan].secretHashCs = [ arbiterSecretHashes[1], arbiterSecretHashes[2], arbiterSecretHashes[3] ];
		pubKeys[loan].borrowerPubKey    = borrowerPubKey_;
		pubKeys[loan].lenderPubKey      = lenderPubKey_;
        pubKeys[loan].arbiterPubKey       = arbiterPubKey_;
        secretHashes[loan].set          = true;
	}

    
	function fund(bytes32 loan) external {
		require(secretHashes[loan].set);
    	require(bools[loan].funded == false);
    	require(token.transferFrom(msg.sender, address(this), principal(loan)));
    	bools[loan].funded = true;
    }

    
    function approve(bytes32 loan) external { 
    	require(bools[loan].funded == true);
    	require(loans[loan].lender == msg.sender);
    	require(now                <= approveExpiration(loan));
    	bools[loan].approved = true;
    }

    
    function withdraw(bytes32 loan, bytes32 secretA1) external {
    	require(!off(loan));
    	require(bools[loan].funded == true);
    	require(bools[loan].approved == true);
        require(bools[loan].withdrawn == false);
    	require(sha256(abi.encodePacked(secretA1)) == secretHashes[loan].secretHashA1);
    	require(token.transfer(loans[loan].borrower, principal(loan)));
    	bools[loan].withdrawn = true;
        secretHashes[loan].withdrawSecret = secretA1;
    }

    
    function repay(bytes32 loan, uint256 amount) external {
    	require(!off(loan));
        require(!sale(loan));
    	require(bools[loan].withdrawn     == true);
    	require(now                       <= loans[loan].loanExpiration);
        require(add(amount, repaid(loan)) <= owedForLoan(loan));
    	require(token.transferFrom(msg.sender, address(this), amount));
    	repayments[loan] = add(amount, repayments[loan]);
    	if (repaid(loan) == owedForLoan(loan)) {
    		bools[loan].paid = true;
    	}
    }

    
    function refund(bytes32 loan) external {
    	require(!off(loan));
        require(!sale(loan));
    	require(now              >  acceptExpiration(loan));
    	require(bools[loan].paid == true);
    	require(msg.sender       == loans[loan].borrower);
        bools[loan].off = true;
        loans[loan].closedTimestamp = now;
    	require(token.transfer(loans[loan].borrower, owedForLoan(loan)));
        if (funds.custom(fundIndex[loan]) == false) {
            funds.decreaseTotalBorrow(loans[loan].principal);
            funds.calcGlobalInterest();
        }
    }

    
    function cancel(bytes32 loan, bytes32 secret) external {
        accept(loan, secret);
    }

    
    function accept(bytes32 loan, bytes32 secret) public {
        require(!off(loan));
        require(bools[loan].withdrawn == false   || bools[loan].paid == true);
        require(msg.sender == loans[loan].lender || msg.sender == loans[loan].arbiter);
        require(sha256(abi.encodePacked(secret)) == secretHashes[loan].secretHashB1 || sha256(abi.encodePacked(secret)) == secretHashes[loan].secretHashC1);
        require(now                              <= acceptExpiration(loan));
        require(bools[loan].sale                 == false);
        bools[loan].off = true;
        loans[loan].closedTimestamp = now;
        secretHashes[loan].acceptSecret = secret;
        if (bools[loan].withdrawn == false) {
            if (fundIndex[loan] == bytes32(0)) {
                require(token.transfer(loans[loan].lender, loans[loan].principal));
            } else {
                if (funds.custom(fundIndex[loan]) == false) {
                    funds.decreaseTotalBorrow(loans[loan].principal);
                }
                funds.deposit(fundIndex[loan], loans[loan].principal);
            }
        } else if (bools[loan].withdrawn == true) {
            if (fundIndex[loan] == bytes32(0)) {
                require(token.transfer(loans[loan].lender, owedToLender(loan)));
            } else {
                if (funds.custom(fundIndex[loan]) == false) {
                    funds.decreaseTotalBorrow(loans[loan].principal);
                }
                funds.deposit(fundIndex[loan], owedToLender(loan));
            }
            require(token.transfer(loans[loan].arbiter, fee(loan)));
        }
    }

    
    function liquidate(bytes32 loan, bytes32 secretHash, bytes20 pubKeyHash) external returns (bytes32 sale_) {
    	require(!off(loan));
        require(bools[loan].withdrawn == true);
        require(msg.sender != loans[loan].borrower && msg.sender != loans[loan].lender);
    	if (sales.next(loan) == 0) {
    		if (now > loans[loan].loanExpiration) {
	    		require(bools[loan].paid == false);
			} else {
				require(!safe(loan));
			}
            if (funds.custom(fundIndex[loan]) == false) {
                funds.decreaseTotalBorrow(loans[loan].principal);
                funds.calcGlobalInterest();
            }
		} else {
			require(sales.next(loan) < 3);
            require(now > sales.settlementExpiration(sales.saleIndexByLoan(loan, sales.next(loan) - 1))); 
            require(!sales.accepted(sales.saleIndexByLoan(loan, sales.next(loan) - 1))); 
		}
        require(token.balanceOf(msg.sender) >= ddiv(discountCollateralValue(loan)));
        require(token.transferFrom(msg.sender, address(sales), ddiv(discountCollateralValue(loan))));
        SecretHashes storage h = secretHashes[loan];
        uint256 i = sales.next(loan);
		sale_ = sales.create(loan, loans[loan].borrower, loans[loan].lender, loans[loan].arbiter, msg.sender, h.secretHashAs[i], h.secretHashBs[i], h.secretHashCs[i], secretHash, pubKeyHash);
        if (bools[loan].sale == false) { require(token.transfer(address(sales), repaid(loan))); }
		bools[loan].sale = true;
    }
}

interface CTokenInterface {
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function exchangeRateCurrent() external returns (uint);
    function getCash() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalReserves() external view returns (uint);
    function reserveFactorMantissa() external view returns (uint);

    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface CERC20Interface {
    function mint(uint mintAmount) external returns (uint); 
    function repayBorrow(uint repayAmount) external returns (uint); 
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); 
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface ERC20Interface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

contract Helpers is DSMath {

    address public comptroller;

    
    function getComptrollerAddress() public view returns (address) {
        
        
        
        return comptroller;
    }

    function enterMarket(address cErc20) internal {
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        address[] memory markets = troller.getAssetsIn(address(this));
        bool isEntered = false;
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == cErc20) {
                isEntered = true;
            }
        }
        if (!isEntered) {
            address[] memory toEnter = new address[](1);
            toEnter[0] = cErc20;
            troller.enterMarkets(toEnter);
        }
    }

    
    function setApproval(address erc20, uint srcAmt, address to) internal {
        ERC20Interface erc20Contract = ERC20Interface(erc20);
        uint tokenAllowance = erc20Contract.allowance(address(this), to);
        if (srcAmt > tokenAllowance) {
            erc20Contract.approve(to, 2**255);
        }
    }

}

contract ALCompound is Helpers {
    
    function mintCToken(address erc20, address cErc20, uint tokenAmt) internal {
        enterMarket(cErc20);
        ERC20Interface token = ERC20Interface(erc20);
        uint toDeposit = token.balanceOf(address(this));
        if (toDeposit > tokenAmt) {
            toDeposit = tokenAmt;
        }
        CERC20Interface cToken = CERC20Interface(cErc20);
        setApproval(erc20, toDeposit, cErc20);
        assert(cToken.mint(toDeposit) == 0);
    }

    
    function redeemUnderlying(address cErc20, uint tokenAmt) internal {
        CTokenInterface cToken = CTokenInterface(cErc20);
        setApproval(cErc20, 10**50, cErc20);
        uint toBurn = cToken.balanceOf(address(this));
        uint tokenToReturn = wmul(toBurn, cToken.exchangeRateCurrent());
        if (tokenToReturn > tokenAmt) {
            tokenToReturn = tokenAmt;
        }
        require(cToken.redeemUnderlying(tokenToReturn) == 0, "something went wrong");
    }

    
    function redeemCToken(address cErc20, uint cTokenAmt) internal {
        CTokenInterface cToken = CTokenInterface(cErc20);
        uint toBurn = cToken.balanceOf(address(this));
        if (toBurn > cTokenAmt) {
            toBurn = cTokenAmt;
        }
        setApproval(cErc20, toBurn, cErc20);
        require(cToken.redeem(toBurn) == 0, "something went wrong");
    }
}

contract Funds is DSMath, ALCompound {
    Loans loans;

    uint256 public constant DEFAULT_LIQUIDATION_RATIO = 1400000000000000000000000000;   
    uint256 public constant DEFAULT_LIQUIDATION_PENALTY = 1000000000937303470807876289; 
    uint256 public constant DEFAULT_MIN_LOAN_AMT = 10 ether; 
    uint256 public constant DEFAULT_MAX_LOAN_AMT = 2**256-1; 
    uint256 public constant DEFAULT_MIN_LOAN_DUR = 6 hours;  
    uint256 public constant NUM_SECONDS_IN_YEAR = 365 days;

    mapping (address => bytes32[]) public secretHashes;    
    mapping (address => uint256)   public secretHashIndex; 

    mapping (address => bytes)     public pubKeys;  
    
    mapping (bytes32 => Fund)      public funds;
    mapping (address => bytes32)   public fundOwner;
    mapping (bytes32 => Bools)     public bools;
    uint256                        public fundIndex;

    uint256 public lastGlobalInterestUpdated;
    uint256 public tokenMarketLiquidity;
    uint256 public cTokenMarketLiquidity;
    uint256 public marketLiquidity;
    uint256 public totalBorrow;
    uint256 public globalInterestRateNumerator;
    uint256 public lastUtilizationRatio;
    uint256 public globalInterestRate;
    uint256 public maxUtilizationDelta;
    uint256 public utilizationInterestDivisor;
    uint256 public maxInterestRateNumerator;
    uint256 public minInterestRateNumerator;
    uint256 public interestUpdateDelay;
    uint256 public defaultArbiterFee;

    ERC20 public token;
    uint256 public decimals;
    CTokenInterface public cToken;
    bool compoundSet;

    address deployer;

    
    struct Fund {
        address  lender;
        uint256  minLoanAmt;
        uint256  maxLoanAmt;
        uint256  minLoanDur;
        uint256  maxLoanDur;
        uint256  fundExpiry;
        uint256  interest;
        uint256  penalty;
        uint256  fee;
        uint256  liquidationRatio;
        address  arbiter;
        uint256  balance;
        uint256  cBalance;
    }

    struct Bools {
        bool     custom;
        bool     compoundEnabled;
    }

    event Create(bytes32 fund);

    constructor(
        ERC20   token_,
        uint256 decimals_
    ) public {
        deployer = msg.sender;
        token = token_;
        decimals = decimals_;
        utilizationInterestDivisor = 10531702972595856680093239305; 
        maxUtilizationDelta = 95310179948351216961192521; 
        globalInterestRateNumerator =  95310179948351216961192521; 
        maxInterestRateNumerator    = 182321557320989604265864303; 
        minInterestRateNumerator    =  24692612600038629323181834; 
        interestUpdateDelay = 86400; 
        defaultArbiterFee = 1000000000236936036262880196; 
        globalInterestRate = add(RAY, div(globalInterestRateNumerator, NUM_SECONDS_IN_YEAR)); 

        
        
        
        
    }

    
    function setLoans(Loans loans_) public {
        require(msg.sender == deployer);
        require(address(loans) == address(0));
        loans = loans_;
        require(token.approve(address(loans_), 2**256-1));
    }

    
    function setCompound(CTokenInterface cToken_, address comptroller_) public {
        require(msg.sender == deployer);
        require(!compoundSet);
        cToken = cToken_;
        comptroller = comptroller_;
        compoundSet = true;
    }

    
    
    
    
    
    
    

    
    function setUtilizationInterestDivisor(uint256 utilizationInterestDivisor_) external {
        require(msg.sender == deployer);
        utilizationInterestDivisor = utilizationInterestDivisor_;
    }

    
    function setMaxUtilizationDelta(uint256 maxUtilizationDelta_) external {
        require(msg.sender == deployer);
        maxUtilizationDelta = maxUtilizationDelta_;
    }

    
    function setGlobalInterestRateNumerator(uint256 globalInterestRateNumerator_) external {
        require(msg.sender == deployer);
        globalInterestRateNumerator = globalInterestRateNumerator_;
    }

    
    function setGlobalInterestRate(uint256 globalInterestRate_) external {
        require(msg.sender == deployer);
        globalInterestRate = globalInterestRate_;
    }

    
    function setMaxInterestRateNumerator(uint256 maxInterestRateNumerator_) external {
        require(msg.sender == deployer);
        maxInterestRateNumerator = maxInterestRateNumerator_;
    }

    
    function setMinInterestRateNumerator(uint256 minInterestRateNumerator_) external {
        require(msg.sender == deployer);
        minInterestRateNumerator = minInterestRateNumerator_;
    }

    
    function setInterestUpdateDelay(uint256 interestUpdateDelay_) external {
        require(msg.sender == deployer);
        interestUpdateDelay = interestUpdateDelay_;
    }

    
    function setDefaultArbiterFee(uint256 defaultArbiterFee_) external {
        require(msg.sender == deployer);
        require(defaultArbiterFee_ <= 1000000000315522921573372069); 
        defaultArbiterFee = defaultArbiterFee_;
    }
    

    
    function lender(bytes32 fund) public view returns (address) {
        return funds[fund].lender;
    }

    
    function minLoanAmt(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].minLoanAmt; }
        else                    { return div(DEFAULT_MIN_LOAN_AMT, (10 ** sub(18, decimals))); }
    }

    
    function maxLoanAmt(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].maxLoanAmt; }
        else                    { return DEFAULT_MAX_LOAN_AMT; }
    }

    
    function minLoanDur(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].minLoanDur; }
        else                    { return DEFAULT_MIN_LOAN_DUR; }
    }

    
    function maxLoanDur(bytes32 fund) public view returns (uint256) {
        return funds[fund].maxLoanDur;
    }

    
    function fundExpiry(bytes32 fund) public view returns (uint256) {
        return funds[fund].fundExpiry;
    }

    
    function interest(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].interest; }
        else                    { return globalInterestRate; }
    }

    
    function penalty(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].penalty; }
        else                    { return DEFAULT_LIQUIDATION_PENALTY; }
    }

    
    function fee(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].fee; }
        else                    { return defaultArbiterFee; }
    }

    
    function liquidationRatio(bytes32 fund) public view returns (uint256) {
        if (bools[fund].custom) { return funds[fund].liquidationRatio; }
        else                    { return DEFAULT_LIQUIDATION_RATIO; }
    }

    
    function arbiter(bytes32 fund)   public view returns (address) {
        return funds[fund].arbiter;
    }

    
    function balance(bytes32 fund) public returns (uint256) {
        if (bools[fund].compoundEnabled) {
            return wmul(funds[fund].cBalance, cToken.exchangeRateCurrent());
        } else {
            return funds[fund].balance;
        }
    }

    
    function custom(bytes32 fund) public view returns (bool) {
        return bools[fund].custom;
    }

    
    function secretHashesCount(address addr_) external view returns (uint256) {
        return secretHashes[addr_].length;
    }

    
    function create(
        uint256  maxLoanDur_,
        uint256  fundExpiry_,
        address  arbiter_,
        bool     compoundEnabled_,
        uint256  amount_
    ) external returns (bytes32 fund) { 
        require(funds[fundOwner[msg.sender]].lender != msg.sender || msg.sender == deployer); 
        require(ensureNotZero(maxLoanDur_) != 2**256-1 || ensureNotZero(fundExpiry_) != 2**256-1); 
        if (!compoundSet) { require(compoundEnabled_ == false); }
        fundIndex = add(fundIndex, 1);
        fund = bytes32(fundIndex);
        funds[fund].lender           = msg.sender;
        funds[fund].maxLoanDur       = ensureNotZero(maxLoanDur_);
        funds[fund].fundExpiry       = ensureNotZero(fundExpiry_);
        funds[fund].arbiter          = arbiter_;
        bools[fund].custom           = false;
        bools[fund].compoundEnabled  = compoundEnabled_;
        fundOwner[msg.sender]        = bytes32(fundIndex);
        if (amount_ > 0) { deposit(fund, amount_); }

        emit Create(fund);
    }

    
    function createCustom(
        uint256  minLoanAmt_,
        uint256  maxLoanAmt_,
        uint256  minLoanDur_,
        uint256  maxLoanDur_,
        uint256  fundExpiry_,
        uint256  liquidationRatio_,
        uint256  interest_,
        uint256  penalty_,
        uint256  fee_,
        address  arbiter_,
        bool     compoundEnabled_,
        uint256  amount_
    ) external returns (bytes32 fund) {
        require(funds[fundOwner[msg.sender]].lender != msg.sender || msg.sender == deployer); 
        require(ensureNotZero(maxLoanDur_) != 2**256-1 || ensureNotZero(fundExpiry_) != 2**256-1); 
        if (!compoundSet) { require(compoundEnabled_ == false); }
        fundIndex = add(fundIndex, 1);
        fund = bytes32(fundIndex);
        funds[fund].lender           = msg.sender;
        funds[fund].minLoanAmt       = minLoanAmt_;
        funds[fund].maxLoanAmt       = maxLoanAmt_;
        funds[fund].minLoanDur       = minLoanDur_;
        funds[fund].maxLoanDur       = ensureNotZero(maxLoanDur_);
        funds[fund].fundExpiry       = ensureNotZero(fundExpiry_);
        funds[fund].interest         = interest_;
        funds[fund].penalty          = penalty_;
        funds[fund].fee              = fee_;
        funds[fund].liquidationRatio = liquidationRatio_;
        funds[fund].arbiter          = arbiter_;
        bools[fund].custom           = true;
        bools[fund].compoundEnabled  = compoundEnabled_;
        fundOwner[msg.sender]        = bytes32(fundIndex);
        if (amount_ > 0) { deposit(fund, amount_); }

        emit Create(fund);
    }

    
    function deposit(bytes32 fund, uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount));
        if (bools[fund].compoundEnabled) {
            mintCToken(address(token), address(cToken), amount);
            uint256 cTokenToAdd = div(mul(amount, WAD), cToken.exchangeRateCurrent());
            funds[fund].cBalance = add(funds[fund].cBalance, cTokenToAdd);
            if (!custom(fund)) { cTokenMarketLiquidity = add(cTokenMarketLiquidity, cTokenToAdd); }
        } else {
            funds[fund].balance = add(funds[fund].balance, amount);
            if (!custom(fund)) { tokenMarketLiquidity = add(tokenMarketLiquidity, amount); }
        }
        if (!custom(fund)) { calcGlobalInterest(); }
    }

    
    function update(
        bytes32  fund,
        uint256  maxLoanDur_,
        uint256  fundExpiry_,
        address  arbiter_
    ) public {
        require(msg.sender == lender(fund));
        require(ensureNotZero(maxLoanDur_) != 2**256-1 || ensureNotZero(fundExpiry_) != 2**256-1); 
        funds[fund].maxLoanDur       = maxLoanDur_;
        funds[fund].fundExpiry       = fundExpiry_;
        funds[fund].arbiter          = arbiter_;
    }

    
    function updateCustom(
        bytes32  fund,
        uint256  minLoanAmt_,
        uint256  maxLoanAmt_,
        uint256  minLoanDur_,
        uint256  maxLoanDur_,
        uint256  fundExpiry_,
        uint256  interest_,
        uint256  penalty_,
        uint256  fee_,
        uint256  liquidationRatio_,
        address  arbiter_
    ) external {
        require(bools[fund].custom);
        update(fund, maxLoanDur_, fundExpiry_, arbiter_);
        funds[fund].minLoanAmt       = minLoanAmt_;
        funds[fund].maxLoanAmt       = maxLoanAmt_;
        funds[fund].minLoanDur       = minLoanDur_;
        funds[fund].interest         = interest_;
        funds[fund].penalty          = penalty_;
        funds[fund].fee              = fee_;
        funds[fund].liquidationRatio = liquidationRatio_;
    }

    
    function request(
        bytes32             fund,
        address             borrower_,
        uint256             amount_,
        uint256             collateral_,
        uint256             loanDur_,
        uint256             requestTimestamp_,
        bytes32[8] calldata secretHashes_,
        bytes      calldata pubKeyA_,
        bytes      calldata pubKeyB_
    ) external returns (bytes32 loanIndex) {
        require(msg.sender == lender(fund));
        require(amount_    <= balance(fund));
        require(amount_    >= minLoanAmt(fund));
        require(amount_    <= maxLoanAmt(fund));
        require(loanDur_   >= minLoanDur(fund));
        require(loanDur_   <= sub(fundExpiry(fund), now) && loanDur_ <= maxLoanDur(fund));

        loanIndex = createLoan(fund, borrower_, amount_, collateral_, loanDur_, requestTimestamp_);
        loanSetSecretHashes(fund, loanIndex, secretHashes_, pubKeyA_, pubKeyB_);
        loanUpdateMarketLiquidity(fund, amount_);
        loans.fund(loanIndex);
    }

    
    function withdraw(bytes32 fund, uint256 amount) external {
        withdrawTo(fund, amount, msg.sender);
    }

    
    function withdrawTo(bytes32 fund, uint256 amount, address recipient) public {
        require(msg.sender     == lender(fund));
        require(balance(fund)  >= amount);
        if (bools[fund].compoundEnabled) {
            uint256 cBalanceBefore = cToken.balanceOf(address(this));
            redeemUnderlying(address(cToken), amount);
            uint256 cBalanceAfter = cToken.balanceOf(address(this));
            uint256 cTokenToRemove = sub(cBalanceBefore, cBalanceAfter);
            funds[fund].cBalance = sub(funds[fund].cBalance, cTokenToRemove);
            require(token.transfer(recipient, amount));
            if (!custom(fund)) { cTokenMarketLiquidity = sub(cTokenMarketLiquidity, cTokenToRemove); }
        } else {
            funds[fund].balance = sub(funds[fund].balance, amount);
            require(token.transfer(recipient, amount));
            if (!custom(fund)) { tokenMarketLiquidity = sub(tokenMarketLiquidity, amount); }
        }
        if (!custom(fund)) { calcGlobalInterest(); }
    }

    
    function generate(bytes32[] calldata secretHashes_) external {
        for (uint i = 0; i < secretHashes_.length; i++) {
            secretHashes[msg.sender].push(secretHashes_[i]);
        }
    }

    
    function setPubKey(bytes calldata pubKey) external { 
        pubKeys[msg.sender] = pubKey;
    }

    
    function enableCompound(bytes32 fund) external {
        require(compoundSet);
        require(bools[fund].compoundEnabled == false);
        require(msg.sender == lender(fund));
        uint256 cBalanceBefore = cToken.balanceOf(address(this));
        mintCToken(address(token), address(cToken), funds[fund].balance);
        uint256 cBalanceAfter = cToken.balanceOf(address(this));
        uint256 cTokenToReturn = sub(cBalanceAfter, cBalanceBefore);
        tokenMarketLiquidity = sub(tokenMarketLiquidity, funds[fund].balance);
        cTokenMarketLiquidity = add(cTokenMarketLiquidity, cTokenToReturn);
        bools[fund].compoundEnabled = true;
        funds[fund].balance = 0;
        funds[fund].cBalance = cTokenToReturn;
    }

    
    function disableCompound(bytes32 fund) external {
        require(bools[fund].compoundEnabled);
        require(msg.sender == lender(fund));
        uint256 balanceBefore = token.balanceOf(address(this));
        redeemCToken(address(cToken), funds[fund].cBalance);
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 tokenToReturn = sub(balanceAfter, balanceBefore);
        tokenMarketLiquidity = add(tokenMarketLiquidity, tokenToReturn);
        cTokenMarketLiquidity = sub(cTokenMarketLiquidity, funds[fund].cBalance);
        bools[fund].compoundEnabled = false;
        funds[fund].cBalance = 0;
        funds[fund].balance = tokenToReturn;
    }

    
    function decreaseTotalBorrow(uint256 amount) external {
        require(msg.sender == address(loans));
        totalBorrow = sub(totalBorrow, amount);
    }

    
    function calcGlobalInterest() public {
        marketLiquidity = add(tokenMarketLiquidity, wmul(cTokenMarketLiquidity, cToken.exchangeRateCurrent()));

        if (now > (lastGlobalInterestUpdated + interestUpdateDelay)) {
            uint256 utilizationRatio;
            if (totalBorrow != 0) { utilizationRatio = rdiv(totalBorrow, add(marketLiquidity, totalBorrow)); }

            if (utilizationRatio > lastUtilizationRatio) {
                uint256 changeUtilizationRatio = sub(utilizationRatio, lastUtilizationRatio);
                globalInterestRateNumerator = min(maxInterestRateNumerator, add(globalInterestRateNumerator, rdiv(min(maxUtilizationDelta, changeUtilizationRatio), utilizationInterestDivisor)));
            } else {
                uint256 changeUtilizationRatio = sub(lastUtilizationRatio, utilizationRatio);
                globalInterestRateNumerator = max(minInterestRateNumerator, sub(globalInterestRateNumerator, rdiv(min(maxUtilizationDelta, changeUtilizationRatio), utilizationInterestDivisor)));
            }

            globalInterestRate = add(RAY, div(globalInterestRateNumerator, NUM_SECONDS_IN_YEAR));

            lastGlobalInterestUpdated = now;
            lastUtilizationRatio = utilizationRatio;
        }
    }

    
    function calcInterest(uint256 amount, uint256 rate, uint256 loanDur) public pure returns (uint256) {
        return sub(rmul(amount, rpow(rate, loanDur)), amount);
    }

    
    function ensureNotZero(uint256 value) public pure returns (uint256) {
        if (value == 0) { return 2**256-1; }
        else            { return value; }
    }

    
    function createLoan(
        bytes32  fund,
        address  borrower_,
        uint256  amount_,
        uint256  collateral_,
        uint256  loanDur_,
        uint256  requestTimestamp_
    ) private returns (bytes32 loanIndex) {
        loanIndex = loans.create(
            now + loanDur_,
            [ borrower_, lender(fund), funds[fund].arbiter],
            [ amount_, calcInterest(amount_, interest(fund), loanDur_), calcInterest(amount_, penalty(fund), loanDur_), calcInterest(amount_, fee(fund), loanDur_), collateral_, liquidationRatio(fund), requestTimestamp_],
            fund
        );
    }

    
    function loanSetSecretHashes(
        bytes32           fund,
        bytes32           loan,
        bytes32[8] memory secretHashes_,
        bytes      memory pubKeyA_,
        bytes      memory pubKeyB_
    ) private {
        loans.setSecretHashes(
            loan,
            [ secretHashes_[0], secretHashes_[1], secretHashes_[2], secretHashes_[3] ],
            [ secretHashes_[4], secretHashes_[5], secretHashes_[6], secretHashes_[7] ],
            getSecretHashesForLoan(arbiter(fund)),
            pubKeyA_,
            pubKeyB_,
            pubKeys[arbiter(fund)]
        );
    }

    
    function loanUpdateMarketLiquidity(bytes32 fund, uint256 amount) private {
        if (bools[fund].compoundEnabled) {
            uint256 cBalanceBefore = cToken.balanceOf(address(this));
            redeemUnderlying(address(cToken), amount);
            uint256 cBalanceAfter = cToken.balanceOf(address(this));
            uint256 cTokenToRemove = sub(cBalanceBefore, cBalanceAfter);
            funds[fund].cBalance = sub(funds[fund].cBalance, cTokenToRemove);
            if (!custom(fund)) { cTokenMarketLiquidity = sub(cTokenMarketLiquidity, cTokenToRemove); }
        } else {
            funds[fund].balance = sub(funds[fund].balance, amount);
            if (!custom(fund)) { tokenMarketLiquidity = sub(tokenMarketLiquidity, amount); }
        }
        if (!custom(fund)) {
            totalBorrow = add(totalBorrow, amount);
            calcGlobalInterest();
        }
    }

    
    function getSecretHashesForLoan(address addr) private returns (bytes32[4] memory) {
        secretHashIndex[addr] = add(secretHashIndex[addr], 4);
        return [
            secretHashes[addr][sub(secretHashIndex[addr], 4)],
            secretHashes[addr][sub(secretHashIndex[addr], 3)],
            secretHashes[addr][sub(secretHashIndex[addr], 2)],
            secretHashes[addr][sub(secretHashIndex[addr], 1)]
        ];
    }
}