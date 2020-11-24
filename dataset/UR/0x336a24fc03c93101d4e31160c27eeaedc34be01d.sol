 

pragma solidity >=0.4.24  <0.6.0;
 
contract IERC20Token{
 
function name() public view returns(string memory);
function symbol() public view returns(string memory);
function decimals() public view returns(uint256);
function totalSupply() public view returns (uint256);
function balanceOf(address _owner) public view returns (uint256);
function allowance(address _owner, address _spender) public view returns (uint256);

function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
function approve(address _spender, uint256 _value) public returns (bool success);
 event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

}


 
library SafeMath {
     
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x,"SafeMath->mul got a exception");
        return z;
    }

     
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y,"SafeMath->sub got a exception");
        return _x - _y;
    }

     
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
         
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y,"SafeMath->mul got a exception");
        return z;
    }

       
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0,"SafeMath->div got a exception");
        uint256 c = _x / _y;

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library ConvertLib {
    function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount) {
        return amount * conversionRate;
    }
}


 
contract ERC20Token is IERC20Token {
  using SafeMath for uint256;

  mapping (address => uint256) _balances;

  mapping (address => mapping (address => uint256)) _allowed;

  uint256 _totalSupply;
  string private _name;
  string private _symbol;
  uint256 private _decimals;

   event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  constructor(string memory name, string memory symbol,uint256 total, uint256 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = total.mul(10**decimals);
    _balances[msg.sender] = _totalSupply;
  }

   
  function name() public view returns(string memory) {
    return _name;
  }

   
  function symbol() public view returns(string memory) {
    return _symbol;
  }

   
  function decimals() public view returns(uint) {
    return _decimals;
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender],"not enough balance!!");
    require(to != address(0),"params can't be empty(0)");

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0),"approve address can't be empty(0)!!!");

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from],"balance not enough!!");
    require(value <= _allowed[from][msg.sender],"allow not enough");
    require(to != address(0),"target address can't be empty(0)");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }
}

 
contract LockXL{
    using SafeMath for uint256;
    uint256 constant UNLOCK_DURATION = 100 * 24 * 60 * 60;  
    uint256 constant DAY_UINT = 1*24*60*60; 
    uint256 private _unlockStartTime;

    struct LockBody{
        address account;
        uint256 lockXLs;
        uint256 unlockXLs;  
        bool unlockDone;  
    }

    mapping (address=>LockBody) _lockBodies;

    event LockBodyInputLog(address indexed account,uint256 indexed lockXLs);

    constructor(uint256 unlockDurationTime) public {
        _unlockStartTime = now.add(unlockDurationTime);
    }

    function transferable(uint256 amount,uint256 balance) internal  returns(bool){
        if(_lockBodies[msg.sender].account == address(0)) return true;  
        LockBody storage lb = _lockBodies[msg.sender];
         
        uint256 curProgress = now.sub(_unlockStartTime);
        uint256 timeStamp = curProgress.div(DAY_UINT);  
        lb.unlockDone = timeStamp >= UNLOCK_DURATION;
        if(lb.unlockDone) return true;  

        uint256 unlockXLsPart = lb.lockXLs.mul(timeStamp).div(UNLOCK_DURATION);
        lb.unlockXLs = unlockXLsPart;
        if(balance.add(unlockXLsPart).sub(lb.lockXLs) > amount) return true;
        return false;
    }

     
     function LockInfo(address _acc) public view returns(address account,uint256 unlockStartTime,
      uint256 curUnlockProgess,uint256 unlockDuration,
      uint256 lockXLs,uint256 unlockXLs,uint256 remainlockXLs){
        account = _acc;
        unlockStartTime = _unlockStartTime;
        LockBody memory lb = _lockBodies[_acc];
         
        uint256 curProgress = now.sub(_unlockStartTime);
        curUnlockProgess = curProgress.div(DAY_UINT);
        lockXLs = lb.lockXLs;
        if(curUnlockProgess >= UNLOCK_DURATION){
            curUnlockProgess = UNLOCK_DURATION;
        }
        unlockXLs = lb.lockXLs.mul(curUnlockProgess).div(UNLOCK_DURATION);
        remainlockXLs = lb.lockXLs.sub(unlockXLs);
        unlockDuration = UNLOCK_DURATION;
     }


     
    function inputLockBody(uint256 _XLs) public {
        require(_XLs > 0,"xl amount == 0");
        address _account = address(tx.origin);  
        LockBody storage lb = _lockBodies[_account];
        if(lb.account != address(0)){
            lb.lockXLs = lb.lockXLs.add(_XLs);
        }else{
            _lockBodies[_account] = LockBody({account:_account,lockXLs:_XLs,unlockXLs:0,unlockDone:false});
        }
        emit LockBodyInputLog(_account,_XLs);
    }

}

contract Ownable{
    address private _owner;
    event OwnershipTransferred(address indexed prevOwner,address indexed newOwner);
    event WithdrawEtherEvent(address indexed receiver,uint256 indexed amount,uint256 indexed atime);
     
    modifier onlyOwner{
        require(msg.sender == _owner, "sender not eq owner");
        _;
    }
    constructor() internal{
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner can't be empty!");
        address prevOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(prevOwner,newOwner);
    }

     
    function rescueTokens(IERC20Token tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20Token _token = IERC20Token(tokenAddr);
        require(receiver != address(0),"receiver can't be empty!");
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount,"balance is not enough!");
        require(_token.transfer(receiver, amount),"transfer failed!!");
    }

     
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0),"address can't be empty");
        uint256 balance = address(this).balance;
        require(balance >= amount,"this balance is not enough!");
        to.transfer(amount);
       emit WithdrawEtherEvent(to,amount,now);
    }


}

 

contract UrgencyPause is Ownable{
    bool private _paused;
    mapping (address=>bool) private _manager;
    event Paused(address indexed account,bool indexed state);
    event ChangeManagerState(address indexed account,bool indexed state);
     
    modifier isManager(){
        require(_manager[msg.sender]==true,"not manager!!");
        _;
    }
    
    modifier notPaused(){
        require(!_paused,"the state is paused!");
        _;
    }
    constructor() public{
        _paused = false;
        _manager[msg.sender] = true;
    }

    function changeManagerState(address account,bool state) public onlyOwner {
        require(account != address(0),"null address!!");
        _manager[account] = state;
        emit ChangeManagerState(account,state);
    }

    function paused() public view returns(bool) {
        return _paused;
    }

    function setPaused(bool state) public isManager {
            _paused = state;
            emit Paused(msg.sender,_paused);
    }

}

contract XLand is ERC20Token,UrgencyPause,LockXL{
    using SafeMath for uint256;
    mapping(address=>bool) private _freezes;   
     
    event FreezeAccountStateChange(address indexed account, bool indexed isFreeze);
     
    modifier notFreeze(){
      require(_freezes[msg.sender]==false,"The account was freezed!!");
      _;
    }

    modifier transferableXLs(uint256 amount){
      require(super.transferable(amount,_balances[msg.sender]),"lock,can't be transfer!!");
      _;
    }
    
    constructor(string memory name, string memory symbol,uint256 total, uint8 decimals,uint256 unLockStatTime)
    public
    ERC20Token(name,symbol,total,decimals)
    LockXL(unLockStatTime){

    }

    function transfer(address to, uint256 value) public notPaused notFreeze transferableXLs(value) returns (bool){
        return super.transfer(to,value);
    }

    function approve(address spender, uint256 value) public notPaused notFreeze transferableXLs(value) returns (bool){
        return super.approve(spender,value);
    }

    function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public notPaused notFreeze
    returns (bool){
        return super.transferFrom(from,to,value);
    }

    function inputLockBody(uint256 amount) public {
        super.inputLockBody(amount);
    }
     
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public notPaused notFreeze
    returns (bool)
  {
    require(spender != address(0),"spender can't be empty(0)!!!");

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public notPaused notFreeze
    returns (bool)
  {
    require(spender != address(0),"spender can't be empty(0)!!!");

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
    
   
   
   
   
   

   
  function burn(uint256 amount) public onlyOwner {
    require(amount <= _balances[msg.sender],"balance not enough!!!");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

   
  function changeFreezeAccountState(address account,bool isFreeze) public onlyOwner{
    require(account != address(0),"account can't be empty!!");
    _freezes[account] = isFreeze;
    emit FreezeAccountStateChange(account,isFreeze);
  }

}