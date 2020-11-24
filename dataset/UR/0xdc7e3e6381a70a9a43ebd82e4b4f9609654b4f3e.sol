 

 

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

 

pragma solidity ^0.5.0;



 
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

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
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

 

pragma solidity >=0.4.21 <0.6.0;

 





contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract KGCMortage is Ownable{
  using SafeMath for uint256;

  event LoanCreated(uint256 tid, address mortager,uint256  mortageKgcValue ,uint256 duration ,uint256 wantValue, uint256 interest, uint256 createdAt);
  event LoanCanceld(uint256 tid, uint256 createdAt);
  event LoanLended(uint256 tid,address lender,uint256 createdAt);
  event LoanPayed(uint256 tid, uint256 createdAt);
  event LoanForceGetMortaged(uint256 tid,address lender,uint256 createdAt);


  enum LoanStatus {
    STATUS_FRESH,
    STATUS_CANCELD,
    STATUS_LENDED,
    STATUS_MORTAGE_FORCE_TAKED ,
    STATUS_PAYBACKED 
  }

  struct LoanTrans {
    uint256 id;
    LoanStatus status;
    uint256 mortageKgcValue;
    uint256 duration;
    uint256 wantValue;
    uint256 interest;
    uint256 loanStartedAt;
    address mortager;
    address lender;
  }

   
  uint256 buffPeriod = 1 days; 

  uint256 public totalTrans;
  LoanTrans[] loanTrans;


  ERC20Interface kgcInstance; 



  constructor(address kgcAddress) public{
    kgcInstance = ERC20Interface(kgcAddress);
  }

  modifier validateTid(uint256 tid) {
    require( tid < totalTrans );
    _;
  }

  function createLoanApplication( uint256 mortageKgcValue , uint256 duration , uint256 wantValue, uint256 interest  )  public {
    address from = msg.sender;
     
    require(kgcInstance.transferFrom(from, address(this), mortageKgcValue));


    uint256 transId = totalTrans;
    LoanTrans memory trans = LoanTrans({
      id: transId,
      status :LoanStatus.STATUS_FRESH,
      mortageKgcValue : mortageKgcValue,
      duration : duration,
      wantValue : wantValue,
      interest : interest,
      mortager : from,
      loanStartedAt: 0,
      lender : address(0)
    });

    totalTrans = totalTrans.add(1);
    loanTrans.push(trans);

    emit LoanCreated(transId, from, mortageKgcValue, duration,wantValue,interest,now);
  }

  function lendTo(uint256 tid) public validateTid(tid) payable {
    LoanTrans storage trans =  loanTrans[tid];

     
    require(trans.status == LoanStatus.STATUS_FRESH);
    require(msg.value == trans.wantValue);

     
    trans.loanStartedAt = now;
    trans.status =  LoanStatus.STATUS_LENDED;
    trans.lender = msg.sender;

     
    address payable mortagerAddr = address(uint160(trans.mortager ));
    mortagerAddr.transfer( trans.wantValue ) ;

    emit LoanLended(tid, msg.sender, now);
  }


  function paybackTo(uint256 tid) public  validateTid(tid)  payable {
    LoanTrans storage trans =  loanTrans[tid];
    require(trans.status == LoanStatus.STATUS_LENDED);
    require(msg.value == trans.wantValue.add(trans.interest));
     
    address payable lenderAddr = address(uint160(trans.lender));
    lenderAddr.transfer(msg.value);
     
    require(kgcInstance.transfer(trans.mortager,trans.mortageKgcValue ));
     
    trans.status = LoanStatus.STATUS_PAYBACKED;

    emit LoanPayed(tid,now);

  }

  function forceGetMortage(uint256 tid) public validateTid(tid) {
    LoanTrans storage trans =  loanTrans[tid];
    require(msg.sender == trans.lender);
    require( now >   trans.loanStartedAt.add(trans.duration).add(buffPeriod ) );
    trans.status = LoanStatus.STATUS_MORTAGE_FORCE_TAKED;
    require(kgcInstance.transfer(trans.lender,trans.mortageKgcValue ));

    emit LoanForceGetMortaged(tid,trans.lender,now);
  }

  function cancelApplication(uint256 tid)  public validateTid(tid) {
    LoanTrans storage trans =  loanTrans[tid];
    require(trans.status == LoanStatus.STATUS_FRESH);
    require(msg.sender == trans.mortager);
    require(kgcInstance.transfer(trans.mortager,trans.mortageKgcValue ));
     
    trans.status = LoanStatus.STATUS_CANCELD;
    emit LoanCanceld(tid,now);
  }



  function getTrans(uint tid) public view returns(uint256 id,LoanStatus status,uint256 mortageKgcValue,uint256 duration, uint256 wantValue, uint256 interest, uint256 loanStartedAt, address mortager ,address lender){
    LoanTrans storage trans =  loanTrans[tid];
    id = trans.id;
    status = trans.status;
    mortageKgcValue = trans.mortageKgcValue;
    duration = trans.duration;
    wantValue = trans.wantValue;
    interest = trans.interest;
    loanStartedAt = trans.loanStartedAt;
    mortager = trans.mortager;
    lender = trans.lender;
  }

}