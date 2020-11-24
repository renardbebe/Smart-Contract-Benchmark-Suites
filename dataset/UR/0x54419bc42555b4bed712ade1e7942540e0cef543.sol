 

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


 

 
 
 
 

 
 
 
 

 
 

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
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

 

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract PotLike {
    function pie(address) public view returns (uint);
    function drip() public returns (uint);
    function join(uint) public;
    function exit(uint) public;
    function rho() public returns (uint);
    function chi() public returns (uint);
}

contract VatLike {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract WrapperLockDai is ERC20, ERC20Detailed, Ownable, DSMath {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public TRANSFER_PROXY_V2 = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public daiJoin;
    address public pot;
    mapping (address => uint256) public pieBalance; 
    uint public Pie;
    mapping (address => bool) public isSigner;

    address public originalToken;
    uint public interestFee;
    
    mapping (address => uint) public depositLock;

    uint constant public MAX_PERCENTAGE = 100;
    uint constant WAD_TO_RAY = 10 ** 9;

    event InterestFeeSet(uint interestFee);
    event Withdraw(uint pie, uint exitWad);
    event Test(address account, uint amount);

    constructor (address _originalToken, string memory name, string memory symbol, uint8 decimals, uint _interestFee, address _daiJoin, address _daiPot) public Ownable() ERC20Detailed(name, symbol, decimals) {
        require(_interestFee >= 0 && _interestFee <= MAX_PERCENTAGE);

        originalToken = _originalToken;
        interestFee = _interestFee;
        daiJoin = _daiJoin;
        pot = _daiPot;
        isSigner[msg.sender] = true;

        emit InterestFeeSet(interestFee);
    }

    function _mintPie(address account, uint pie) internal {
        pieBalance[account] = add(pieBalance[account], pie);
        Pie = add(Pie, pie);
    }

    function _burnPie(address account, uint pie) internal {
        pieBalance[account] = sub(pieBalance[account], pie);
        Pie = sub(Pie, pie);
    }
    
     

     
    function deposit(uint _value, uint _forTime) public returns (bool success) {
        require(_forTime >= 1);
        require(now + _forTime * 1 hours >= depositLock[msg.sender]);
        IERC20(originalToken).safeTransferFrom(msg.sender, address(this), _value);

        DaiJoinLike(daiJoin).dai().approve(daiJoin, _value);
        DaiJoinLike(daiJoin).join(address(this), _value);

        uint pie = _joinPot(_value);
        
        _mint(msg.sender, _value);
        _mintPie(msg.sender, pie);
        depositLock[msg.sender] = now + _forTime * 1 hours;
        return true;
    }

     
    function withdraw(
        uint _value,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint signatureValidUntilBlock
    )
        public
        returns
        (bool success)
    {
        if (now > depositLock[msg.sender]) {
            
        } else {
        require(block.number < signatureValidUntilBlock);
        require(isValidSignature(keccak256(abi.encodePacked(msg.sender, address(this), signatureValidUntilBlock)), v, r, s), "signature");
            
        depositLock[msg.sender] = 0;
        }
        uint pie = _getPiePercentage(msg.sender, _value);  
        uint exitWad = _exitPot(pie);  

        uint userInterest = _getInterestSplit(_value, exitWad);
        DaiJoinLike(daiJoin).exit(msg.sender, add(_value, userInterest));  

        _burn(msg.sender, _value);
        _burnPie(msg.sender, pie);
        
        emit Withdraw(pie, exitWad); 
        return true;
    }

     
    function _getPiePercentage(address account, uint amount) public returns (uint) {
        require(amount > 0);
        require(balanceOf(account) > 0);
        require(pieBalance[account] > 0);

        if (amount == balanceOf(account)) {
            return pieBalance[account];
        }

        uint rpercentage = rdiv(mul(amount, WAD_TO_RAY), mul(balanceOf(account), WAD_TO_RAY));
        uint pie = rmul(mul(pieBalance[account], WAD_TO_RAY), rpercentage) / WAD_TO_RAY;
        return pie;
    }

     
     
     
    function withdrawBalanceDifference() public onlyOwner returns (bool success) {
        uint bal = IERC20(originalToken).balanceOf(address(this));
        require (bal > 0);
        IERC20(originalToken).safeTransfer(msg.sender, bal);
        return true;
    }

     
    function withdrawDifferentToken(address _differentToken) public onlyOwner returns (bool) {
        require(_differentToken != originalToken);
        require(IERC20(_differentToken).balanceOf(address(this)) > 0);
        IERC20(_differentToken).safeTransfer(msg.sender, IERC20(_differentToken).balanceOf(address(this)));
        return true;
    }

     
     
    function withdrawVatBalance(uint _rad) public onlyOwner returns (bool) {
        DaiJoinLike(daiJoin).vat().move(address(this), owner(), _rad);
    }

     
    function exitExcessPie() public onlyOwner returns (bool) {
        uint truePie = PotLike(pot).pie(address(this));
        uint excessPie = sub(truePie, Pie);

        _exitPot(excessPie);
    }

     
    function setInterestFee(uint _interestFee) public onlyOwner returns (bool) {
        require(_interestFee >= 0 && _interestFee <= MAX_PERCENTAGE);

        interestFee = _interestFee;
        emit InterestFeeSet(interestFee);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        return false;
    }

     
     
    function _getInterestSplit(uint principal, uint plusInterest) internal returns(uint) {
        if (plusInterest <= principal) {
            return 0;
        }

        uint interest = sub(plusInterest, principal);

        if (interestFee == 0) {
            return interest;
        }

        if (interestFee == MAX_PERCENTAGE) {
            return 0;
        }

         
        uint userInterestPercentage = sub(MAX_PERCENTAGE, interestFee);
        uint userInterest = mul(interest, userInterestPercentage) / MAX_PERCENTAGE;
        return userInterest;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(isSigner[_to] || isSigner[_from]);
        assert(msg.sender == TRANSFER_PROXY_V2);
        depositLock[_to] = depositLock[_to] > now ? depositLock[_to] : now + 1 hours;
         
        uint pie = _getPiePercentage(_from, _value);
        _burnPie(_from, pie);

        _transfer(_from, _to, _value);  

         
            uint exitWad = _exitPot(pie);

             
            uint userInterest = _getInterestSplit(_value, exitWad);

            if (userInterest > 0) {
                 
                 

                uint interestPie = _joinPot(userInterest);
                _mint(_from, userInterest);
                _mintPie(_from, interestPie);
            }

             
            uint toPie = _joinPot(_value);
            _mintPie(_to, toPie);
         
    }

     
    function allowance(address _owner, address _spender) public view returns (uint) {
        if (_spender == TRANSFER_PROXY_V2) {
            return 2**256 - 1;
        }
    }

    function isValidSignature(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        view
        returns (bool)
    {
        return isSigner[ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            v,
            r,
            s
        )];
        
    }

     
    function addSigner(address _newSigner) public {
        require(isSigner[msg.sender]);
        isSigner[_newSigner] = true;
    }

    function keccak(address _sender, address _wrapper, uint _validTill) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_sender, _wrapper, _validTill));
    }

     
    function _joinPot(uint wad) internal returns (uint) {
         VatLike vat = DaiJoinLike(daiJoin).vat();

         
        uint chi = PotLike(pot).drip();

         
        uint pie = mul(wad, RAY) / chi;

         
        if (vat.can(address(this), address(pot)) == 0) {
            vat.hope(pot);
        }

         
        PotLike(pot).join(pie);
        return pie;
    }

     
    function _exitPot(uint pie) internal returns (uint) {
        VatLike vat = DaiJoinLike(daiJoin).vat();

         
        uint chi = PotLike(pot).drip();
        uint expectedWad = mul(pie, chi) / RAY;
        PotLike(pot).exit(pie);

         
         
        uint bal = DaiJoinLike(daiJoin).vat().dai(address(this));

         
        if (vat.can(address(this), address(daiJoin)) == 0) {
            vat.hope(daiJoin);
        }

         
        uint exitWad = bal >= mul(expectedWad, RAY) ? expectedWad : bal / RAY;
        return exitWad;
    }
}