 
pragma solidity ^0.5.11;
import './ownable.sol';
import './safemath.sol';
 
contract Vendor {
    uint public maxCoin;
    uint public feeRo;
    function getLv(uint _value) external view returns(uint);
    function getQueueLv(uint _value) external view returns(uint);
}
contract DB {
    string public sysCode;

    function createNode(address _owner, string memory _code, string memory _pCode, uint _nid) public;
    function createUser(address _owner, uint _frozenCoin, uint _freeCoin, uint8 _level, uint8 _queueLevel, uint32 _ctime, string memory _ip) public returns(uint);
    function updateCoinLevel(address _owner,uint _frozenCoin, uint _freeCoin, uint8 _level, uint8 _queueLevel, uint8 _c1,uint8 _c2,uint8 _c3, uint8 _c4) public;
    function updateBonusInvite(address _owner, uint _dayBonusCoin, uint _dayInviteCoin, uint _bonusCoin, uint _inviteCoin, uint8 _c1, uint8 _c2, uint8 _c3, uint8 _c4) public;
    function updateLockCoin(address _owner, uint8 _currentStamp, uint _lockedCoin, uint8 _c1, uint8 _c2) public;
    function createOrder(address _owner,uint _investCoin, uint32 _ctime, uint8 _frequency) public returns(uint);
    function updateOrder(uint _oid, address _owner, uint _investCoin, uint8 _frequency, uint32 _ctime, uint8 _c1, uint8 _c2, uint8 _c3) public;
    function overAndRestart() public returns(uint32);

    function getNodeMapping(address _owner) public view returns(uint, address, string memory, string memory, uint8);
    function getUserMapping(address _owner) public view returns(address, string memory,string memory,uint8,uint8,uint,uint,uint,uint,uint,uint,uint);
    function getCodeMapping(string memory _code) public view returns(address);
    function getNodeCounter(address _owner) public view returns(uint);
    function getIndexMapping(uint _nid) public view returns(address);
    function getPlatforms() public view returns(uint[11] memory rlt);

    function setCountAndCoin(uint _coin, uint _count) public;
    function getTrustAccount() public view returns(uint);
    function getLockAccount() public view returns(uint);
    function settleBonus(address _addr) public returns(uint);
    function settleRecommend(uint _start, uint _end) public;
}

contract Ev5 is Whitelist {
    string public EV5_NAME = "Ev5.win GameBoy";
     
    using SafeMath for uint;

     
    event InvestEvent(address indexed _addr, string _code, string _pCode, uint indexed _oid, uint _value, uint32 time);
    event TransferEvent(address indexed _from, address indexed _to, uint _value, uint32 time);

     
    uint ethWei = 1 ether;
    bool private reEntrancyMutex = false;
    address[3] private _addrs; 

     
    bool private _platformPower = true;
    uint private _openTime = 0;

     
    DB db;
    Vendor env;

     
    constructor () public {
        _addrs = [0xDe10dC3fE1303f09AB56F1e717a2d3993df35690, 0x0d2bD36Ecd9EBB959c8B1C5E87946eEd43c82dd1, 0x9732D32F4517A0A238441EcA4E45C1584A832fE0];
        db = DB(_addrs[0]);
        env = Vendor(_addrs[1]);
        _openTime = uint32(now);
    }
    function deposit() public payable {
    }

     
    modifier isOpen() {
        require(_openTime > 0 && _platformPower == true,"platform is repairing or wait to starting!");
        _;
    }
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry human only");
        _;
    }

    function _checkIsCreateNode(address _owner, string memory _code, string memory _pCode)
        private
    {
        if(db.getNodeCounter(_owner) == 0){
            require(!compareStr(_code, "") && db.getCodeMapping(_code) == address(0), "Empty Code Or Code Existed");
            require(compareStr(_pCode, db.sysCode()) || db.getCodeMapping(_pCode) != address(0),"Parent User Is Not Exist");
            require(db.getCodeMapping(_pCode) != _owner, "Parent User Is Not Owner");
             
            db.createNode(_owner, _code, _pCode, 0);
        }
    }
    function invest(string memory _code, string memory _pCode, string memory _ip)
        public
        payable
        isHuman()
        isOpen()
    {
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "Coin Must Integer");
        require(msg.value >= 1*ethWei && msg.value <= env.maxCoin()*ethWei, "Coin Must Between 1 to maxCoin");

        _checkIsCreateNode(msg.sender, _code, _pCode);

        uint8 level = uint8(env.getLv(msg.value));
        uint8 queueLevel = uint8(env.getQueueLv(msg.value));
        (address userAddress,,,,,uint frozenCoin,uint freeCoin,,,,,) = db.getUserMapping(msg.sender);
        if(userAddress == address(0)) {
            db.createUser(msg.sender, msg.value, 0, level, queueLevel, uint32(now), _ip);
        } else {
            require(frozenCoin.add(msg.value) <= env.maxCoin()*ethWei, "Max Coin is maxCoin ETH");
            frozenCoin = frozenCoin.add(msg.value);
            level = uint8(env.getLv(frozenCoin));
            queueLevel = uint8(env.getQueueLv(frozenCoin.add(freeCoin)));
            db.updateCoinLevel(msg.sender,frozenCoin,0,level,queueLevel,1,0,1,1);
        }

        uint oid = db.createOrder(msg.sender, msg.value,uint32(now), 0);
        db.setCountAndCoin(msg.value, 1);

        transferTo(_addrs[2], msg.value.mul(env.feeRo()).div(1000));
        emit InvestEvent(msg.sender, _code, _pCode, oid, msg.value, uint32(now));
    }

    function sendAwardBySelf()
        public
        isHuman()
        isOpen()
    {
        (,,,,,,,,uint _coin,,,) = db.getUserMapping(msg.sender);

        bool success = false;
        uint rltCoin = 0;
        (success,rltCoin) = isEnough(_coin, true);
        if(success == true){
            if(rltCoin > (ethWei/10)){
                transferTo(msg.sender, _coin);
                db.updateBonusInvite(msg.sender,0,0,0,0,1,1,0,0);
            }
        }else{
            _openTime = db.overAndRestart();
        }
    }

    function rePlayIn()
        public
        payable
        isHuman()
        isOpen()
    {
        (,string memory _code, string memory _pCode,,,uint frozenCoin,uint freeCoin,,,,,) = db.getUserMapping(msg.sender);
        require(frozenCoin.add(freeCoin) <= env.maxCoin()*ethWei, "Max Coin is maxCoin ETH");
        frozenCoin = frozenCoin.add(freeCoin);
        uint8 level = uint8(env.getLv(frozenCoin));
        uint8 queueLevel = uint8(env.getQueueLv(frozenCoin));
        db.updateCoinLevel(msg.sender,frozenCoin,0,level,queueLevel,1,1,1,1);

        uint oid = db.createOrder(msg.sender, freeCoin,uint32(now), 0);
        db.setCountAndCoin(freeCoin, 1);
        transferTo(_addrs[2], freeCoin.mul(env.feeRo()).div(1000));
        emit InvestEvent(msg.sender, _code, _pCode, oid, freeCoin, uint32(now));
    }

    function sendAward(uint _start ,uint _end)
        public
        payable
        onlyIfWhitelisted
    {
        for(uint i = _start; i <= _end; i++) {
            address _owner = db.getIndexMapping(i);
            if(_owner != address(0)){
                (,,,,,,,,uint _coin,,,) = db.getUserMapping(_owner);

                if(_coin >= (ethWei/10)){
                    transferTo(_owner, _coin);
                    db.updateBonusInvite(_owner,0,0,0,0,1,1,0,0);
                }
            }
        }
    }

    function isEnough(uint _coin, bool _isCal)
        private
        view
        returns (bool,uint)
    {
        uint balance = (_isCal == true) ? address(this).balance.sub(db.getTrustAccount()).sub(db.getLockAccount()) : address(this).balance;
        if(_coin >= balance){
            return (false, balance);
        }else{
            return (true, _coin);
        }
    }

    function transferTo(address _addr,uint _val) private {
        require(_addr != address(0));
        require(!reEntrancyMutex);
        reEntrancyMutex = true;
            address(uint160(_addr)).transfer(_val);
            emit TransferEvent(address(this), _addr, _val, uint32(now));
        reEntrancyMutex = false;
    }

    function userWithDraw()
        public
        payable
        isHuman()
        isOpen
        returns(bool)
    {
        require(!reEntrancyMutex);
        (,,,,,uint frozenCoin,uint freeCoin,uint lockedCoin,,,,) = db.getUserMapping(msg.sender);
        require(lockedCoin == 0, "Nothing To");

        bool success = false;
        uint rltCoin;
        (success,rltCoin) = isEnough(freeCoin, true);

        if(success == true){
            if(rltCoin > 0){
                transferTo(msg.sender, rltCoin);
                uint8 level = uint8(env.getLv(frozenCoin));
                uint8 queueLevel = uint8(env.getQueueLv(frozenCoin));
                db.updateCoinLevel(msg.sender,0,0,level,queueLevel,0,1,1,1);
            }
            return true;
        }else{
            _openTime = db.overAndRestart();
        }
        return false;
    }

    function userWithDrawPro()
        public
        payable
        isHuman()
        isOpen
        returns(bool)
    {
        require(!reEntrancyMutex);
        (,,,,,uint frozenCoin,uint freeCoin,uint lockedCoin,,,,) = db.getUserMapping(msg.sender);
        require(freeCoin == lockedCoin, "Nothing To");

        bool success = false;
        uint rltCoin;
        (success,rltCoin) = isEnough(freeCoin, false);

        if(success == true){
            if(rltCoin > 0){
                transferTo(msg.sender, rltCoin);
                uint8 level = uint8(env.getLv(frozenCoin));
                uint8 queueLevel = uint8(env.getQueueLv(frozenCoin));
                db.updateCoinLevel(msg.sender,0,0,level,queueLevel,0,1,1,1);
            }
            return true;
        }
        return false;
    }

    function settleBonus(address _addr)
        public
        onlyIfWhitelisted
        returns(uint)
    {
        return db.settleBonus(_addr);
    }

    function settleRecommend(uint _start, uint _end)
        public
        onlyIfWhitelisted
    {
        db.settleRecommend(_start, _end);
    }

    function getUserByCode(string memory _code) public view isOpen returns (bool){
        if (db.getCodeMapping(_code) != address(0)){
            return true;
        }
        return false;
    }
    function getUserInfo(address _owner) external view isOpen returns(address, string memory,string memory,uint8,uint8,uint,uint,uint,uint,uint,uint,uint){
        if(db.getNodeCounter(_owner) > 0){
            return (db.getUserMapping(_owner));
        }
        return (address(0),'','',0,0,0,0,0,0,0,0,0);
    }
    function getPlatforms() external view isOpen returns(uint,uint,uint){
        uint[11] memory ptm = db.getPlatforms();
        return (ptm[6],ptm[7],ptm[8]);
    }
    function getPlatformA() external view onlyOwner returns(bool,address,address,address,uint){
        return (_platformPower,_addrs[0],_addrs[1],_addrs[2],_openTime);
    }
    function setPlatformPower(bool r) external onlyOwner{
        _platformPower = r;
    }
    function setNewAddr(uint _addrId, address _addr) external onlyOwner{
        _addrs[_addrId] = _addr;
        db = DB(_addrs[0]);
        env = Vendor(_addrs[1]);
    }
}
