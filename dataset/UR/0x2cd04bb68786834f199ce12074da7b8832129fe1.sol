 

pragma solidity 0.5.11;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


 
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


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


 
 
contract ChaiMath {
     
    uint256 constant RAY = 10**27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'math/add-overflow');
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'math/sub-overflow');
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'math/mul-overflow');
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
         
        z = mul(x, y) / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
         
        z = mul(x, RAY) / y;
    }
    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
         
        z = add(mul(x, RAY), sub(y, 1)) / y;
    }

     
    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)   
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}

contract GemLike {
    function approve(address, uint256) public;
    function transfer(address, uint256) public;
    function transferFrom(address, address, uint256) public;
    function deposit() public payable;
    function withdraw(uint256) public;
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint256) public payable;
    function exit(address, uint256) public;
}

contract PotLike {
    function pie(address) public view returns (uint256);
    function drip() public returns (uint256);
    function join(uint256) public;
    function exit(uint256) public;
    function rho() public view returns (uint256);
    function dsr() public view returns (uint256);
    function chi() public view returns (uint256);
}

contract VatLike {
    function can(address, address) public view returns (uint256);
    function ilks(bytes32) public view returns (uint256, uint256, uint256, uint256, uint256);
    function dai(address) public view returns (uint256);
    function urns(bytes32, address) public view returns (uint256, uint256);
    function hope(address) public;
    function move(address, address, uint256) public;
}

 

contract WrapperDai is ERC20, ERC20Detailed, Ownable, ChaiMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public TRANSFER_PROXY_V2 = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public daiJoin;
    address public pot;
    address public vat;
    mapping(address => bool) public isSigner;

    address public originalToken;
    uint256 public interestFee;

    uint256 public constant MAX_PERCENTAGE = 100;

    mapping(address => uint256) public depositLock;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public pieBalances;
    uint256 public totalPie;

    event InterestFeeSet(uint256 interestFee);
    event ExitExcessPie(uint256 pie);
    event WithdrawVatBalance(uint256 rad);

    event TransferPie(address indexed from, address indexed to, uint256 pie);

    event Deposit(address indexed sender, uint256 value, uint256 pie);
    event Withdraw(address indexed sender, uint256 pie, uint256 exitWad);

    constructor(
        address _originalToken,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 _interestFee,
        address _daiJoin,
        address _daiPot
    ) public Ownable() ERC20Detailed(name, symbol, decimals) {
        require(_interestFee <= MAX_PERCENTAGE);

        originalToken = _originalToken;
        interestFee = _interestFee;
        daiJoin = _daiJoin;
        pot = _daiPot;
        vat = address(DaiJoinLike(daiJoin).vat());

         
        VatLike(vat).hope(daiJoin);

         
        VatLike(vat).hope(pot);

         
        IERC20(originalToken).approve(address(daiJoin), uint256(-1));

        isSigner[msg.sender] = true;

        emit InterestFeeSet(interestFee);
    }

     
     
    function dai(address _account) external view returns (uint256) {
        return _dai(_account, _simulateChi());
    }

     
     
     
    function balanceOf(address account) public view returns (uint256) {
        return _dai(account, _simulateChi());
    }

     
     
    function _dai(address _account, uint _chi) internal view returns (uint256) {
        if (pieBalances[_account] == 0) {
            return 0;
        }

        uint256 principalPlusInterest = rmul(_chi, pieBalances[_account]);
        uint256 principal = deposited[_account];

        uint256 interest;
        uint256 interestToExchange;
        uint256 interestToUser;

        if (principalPlusInterest >= principal) {
            interest = sub(principalPlusInterest, principal);
            interestToExchange = mul(interest, interestFee) / MAX_PERCENTAGE;
            interestToUser = interest - interestToExchange;
        } else {
            interest = sub(principal, principalPlusInterest);
            interestToUser = 0;
        }

        return add(principal, interestToUser);
    }

     
    function _simulateChi() internal view returns (uint) {
        return (now > PotLike(pot).rho()) ? _simulateDrip() : PotLike(pot).chi();
    }

     
    function _getChi() internal returns (uint) {
        return (now > PotLike(pot).rho()) ? PotLike(pot).drip() : PotLike(pot).chi();
    }

     
    function _simulateDrip() internal view returns (uint256 tmp) {
        uint256 dsr = PotLike(pot).dsr();
        uint256 chi = PotLike(pot).chi();
        uint256 rho = PotLike(pot).rho();
        tmp = rmul(rpow(dsr, now - rho, RAY), chi);
    }

     
    function deposit(uint256 _value, uint256 _forTime) external returns (bool success) {
        require(_forTime >= 1);
        require(now + _forTime * 1 hours >= depositLock[msg.sender]);
        depositLock[msg.sender] = now + _forTime * 1 hours;

        _deposit(_value);
        return true;
    }

    function _deposit(uint256 _value) internal returns (bool success) {
        uint256 chi = _getChi();
        uint256 pie = rdiv(_value, chi);
        _mintPie(msg.sender, pie);
        deposited[msg.sender] = add(deposited[msg.sender], _value);

        IERC20(originalToken).transferFrom(msg.sender, address(this), _value);

        DaiJoinLike(daiJoin).join(address(this), _value);

        PotLike(pot).join(pie);
        emit Deposit(msg.sender, _value, pie);
        return true;
    }

     
    function withdraw(
        uint256 _value,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 signatureValidUntilBlock
    ) external returns (bool success) {
         
        if (depositLock[msg.sender] >= now) {
            require(block.number < signatureValidUntilBlock);
            require(
                isValidSignature(
                    keccak256(
                        abi.encodePacked(msg.sender, address(this), signatureValidUntilBlock)
                    ),
                    v,
                    r,
                    s
                ),
                'signature'
            );
            depositLock[msg.sender] = 0;
        }

        uint256 startPie = pieBalances[msg.sender];
        uint256 chi = _getChi();
        uint256 pie = rdivup(_value, chi);
        uint256 pieToLose;
        uint256 valueToLose;

        uint256 trueDai = _dai(msg.sender, chi);
        pieToLose = mul(startPie, _value) / trueDai;
        valueToLose = mul(deposited[msg.sender], pieToLose) / startPie;

        _burnPie(msg.sender, pieToLose);
        deposited[msg.sender] = sub(deposited[msg.sender], valueToLose);
        return _withdrawPie(pie);
    }

     
    function _withdrawPie(uint256 _pie) internal returns (bool success) {
        uint256 chi = (now > PotLike(pot).rho()) ? PotLike(pot).drip() : PotLike(pot).chi();
        PotLike(pot).exit(_pie);

         
         
        uint256 actualBal = VatLike(vat).dai(address(this)) / RAY;
        uint256 expectedOut = rmul(chi, _pie);
        uint256 toExit = expectedOut > actualBal ? actualBal : expectedOut;

        DaiJoinLike(daiJoin).exit(msg.sender, toExit);
        emit Withdraw(msg.sender, _pie, toExit);
        return true;
    }

     
     
     
    function withdrawBalanceDifference() external onlyOwner returns (bool success) {
        uint256 bal = IERC20(originalToken).balanceOf(address(this));
        require(bal > 0);
        IERC20(originalToken).safeTransfer(msg.sender, bal);
        return true;
    }

     
    function withdrawDifferentToken(address _differentToken) external onlyOwner returns (bool) {
        require(_differentToken != originalToken);
        require(IERC20(_differentToken).balanceOf(address(this)) > 0);
        IERC20(_differentToken).safeTransfer(
            msg.sender,
            IERC20(_differentToken).balanceOf(address(this))
        );
        return true;
    }

     
     
     
     

    function withdrawVatBalance(uint256 _rad) public onlyOwner returns (bool) {
        VatLike(vat).move(address(this), owner(), _rad);
        emit WithdrawVatBalance(_rad);
        return true;
    }

     
     
     
     
    function exitExcessPie() external onlyOwner returns (bool) {
        uint256 truePie = PotLike(pot).pie(address(this));
        uint256 excessPie = sub(truePie, totalPie);

        uint256 chi = (now > PotLike(pot).rho()) ? PotLike(pot).drip() : PotLike(pot).chi();
        PotLike(pot).exit(excessPie);

        emit ExitExcessPie(excessPie);
        return true;
    }

     
    function setInterestFee(uint256 _interestFee) external onlyOwner returns (bool) {
        require(_interestFee <= MAX_PERCENTAGE);

        interestFee = _interestFee;

        emit InterestFeeSet(interestFee);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        return false;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success)
    {
        require(isSigner[_to] || isSigner[_from]);
        assert(msg.sender == TRANSFER_PROXY_V2);

        uint256 startPie = pieBalances[_from];
        uint256 chi = _getChi();
        uint256 pie = rdivup(_value, chi);
        uint256 pieToLose;
        uint256 valueToLose;

        uint256 trueDai = _dai(_from, chi);
        pieToLose = mul(startPie, _value) / trueDai;
        valueToLose = mul(deposited[_from], pieToLose) / startPie;

        _burnPie(_from, pieToLose);
        deposited[_from] = sub(deposited[_from], valueToLose);

        _mintPie(_to, pie);
        deposited[_to] = add(deposited[_to], _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        if (_spender == TRANSFER_PROXY_V2) {
            return 2**256 - 1;
        } else {
            return 0;
        }
    }

    function _mintPie(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalPie = totalPie.add(amount);
        pieBalances[account] = pieBalances[account].add(amount);
        emit TransferPie(address(0), account, amount);
    }

    function _burnPie(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        totalPie = totalPie.sub(value);
        pieBalances[account] = pieBalances[account].sub(value);
        emit TransferPie(account, address(0), value);
    }

    function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    public
    view
    returns (bool)
    {
        return
        isSigner[ecrecover(
            keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)),
            v,
            r,
            s
        )];

    }

     
    function addSigner(address _newSigner) public {
        require(isSigner[msg.sender]);
        isSigner[_newSigner] = true;
    }

    function keccak(address _sender, address _wrapper, uint256 _validTill)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_sender, _wrapper, _validTill));
    }
}