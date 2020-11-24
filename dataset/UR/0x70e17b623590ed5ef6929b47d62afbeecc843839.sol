 

pragma solidity >=0.4.22 <0.7.0;

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
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
library ECDSA {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
contract Ownable {
    address  private  _owner;
 
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
}

contract Management is Ownable{
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    
    Roles.Role private _managers;
    


    constructor ()  internal {
        addManager(msg.sender);
    }
    
    modifier onlyManager()  {
        require(isManager(msg.sender), "Management: caller is not the manager");
        _;
    }
    
    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }
    
    function addManager(address account) public onlyOwner {
        _addManager(account);
    }

    function renounceManager() public onlyOwner {
        _removeManager(msg.sender);
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
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

contract DragonBallGT is Management{
    using Address for address;
    using SafeMath for uint256;
    
    IERC20 public _usdt;
    enum DragonBall {
        AllCorlor,
        Red,
        Orange,
        Yellow,
        Green,
        Blue,
        Indigo,
        Violet
    }
    
    struct BetMod{

        address beter;
        uint256 amount;
        uint256 betTime;
        DragonBall color;
        bool win;
        
    }
    mapping(uint256 => mapping(uint256 => BetMod)) public betinfo;

    enum GameState{Inprogress,Entertained}

    struct Record{
        bool Awarded;
        DragonBall color;
    }
    
    mapping(uint256=>Record) public winrecords; 
    
    enum State { Locked,Active}
    
    State public state;

    uint256 public startTime;
    uint256 public interval;

    event Bet(address indexed beter,uint256 indexed round,uint256 indexed id);
    
    constructor() public {

        state = State.Locked;
        interval = 3600;
        _usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }
    
    modifier inState(State _state) {
        require(state == _state,"Invalid state");
        _;
    }
     function USDTSet(IERC20 _usdtaddress) 
        public 
        onlyOwner 
    {
        require(Address.isContract(address(_usdtaddress)),"Invalid address");
        _usdt = _usdtaddress;
    }
    
    function setState(State _state) 
        public
        onlyManager
    {
        require(_state != state,"Invalid state");
        state = _state;
        if(_state == State.Locked){
            startTime = 0;
        }else{
            startTime = now.sub(now.mod(interval));
        }
    }
    
    
    function checkGameState(uint256 _time) public view returns(GameState _s,uint256 _r,uint256 _st,uint256 _ft,uint256 _et){
        require(_time >= startTime && startTime>0 ,"Game have already stopped");
        uint256 _interval = _time.sub(startTime);
        _s = GameState.Inprogress;
        if(_interval.div(interval.div(2)).mod(2) == 1){
            _s = GameState.Entertained;
        }
        _st = _time.sub(_time.mod(interval));
        _ft = _st.add(interval.div(2));
        _et = _st.add(interval);
        _r = _st;
    }
    
    function bet(uint256 amount,address beter,DragonBall color,uint256 _round,uint256 orderid) 
        public 
        inState(State.Active)
        onlyManager
        returns(bool)
    {
        (GameState _s,uint256 _r,,,) =  checkGameState(now);
        require(_round == _r,"Invalid Round");
        require(_s == GameState.Inprogress && color != DragonBall.AllCorlor,"currunt round has Entertained or Invalid Color");
        BetMod storage _b = betinfo[_r][orderid];
        require(_b.beter == address(0),"Invalid orderid");
        _b.beter = beter;
        _b.amount = amount;
        _b.color = color;
        _b.betTime = now;
        emit Bet(beter,_r,orderid);
        return true;
    }
    
    function lottery(uint256 _round,uint256[] memory _ids,uint256[] memory _rewards,DragonBall _color) 
        public 
        onlyManager
        returns(bool)
    {
        require(_ids.length == _rewards.length,"Invalid ids or reward length");
        Record storage r = winrecords[_round];
        if(!r.Awarded){
            r.Awarded = true;
            r.color = _color;
        }else{
            require(_color == r.color,"Invalid color");
        }
        for(uint256 i=0;i<_ids.length;i++){
            BetMod storage _b = betinfo[_round][_ids[i]];
            require(_b.color==_color && !_b.win ,"Invalid beter");
            callOptionalReturn(_usdt, abi.encodeWithSelector(_usdt.transfer.selector,_b.beter, _rewards[i]));
            _b.win = true;
        }
    }
    
    function managerWithDraw(address recipient, uint256 amount) 
        public 
        onlyManager 
        returns(bool)
    {
        require(_usdt.balanceOf(address(this)) >= amount,"Insufficient balance");
        callOptionalReturn(_usdt, abi.encodeWithSelector(_usdt.transfer.selector,address(this), recipient, amount));
        return true;
    } 
    
    function callOptionalReturn(IERC20 token, bytes memory data) 
        private 
    {
        require(address(_usdt).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    
}