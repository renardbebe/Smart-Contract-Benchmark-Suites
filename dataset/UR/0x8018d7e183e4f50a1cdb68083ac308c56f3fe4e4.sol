 
pragma solidity ^0.5.11;
import './ownable.sol';
import './safemath.sol';
 
contract Vendor {
    function getLevel(uint _value) external view returns(uint);
    function getLineLevel(uint _value) external view returns(uint);
    function getWithdrawRoundRo(uint _round) external pure returns (uint);
}
contract DB {
    function createUser1(address _addr, string memory _code, string memory _pCode) public;
    function createUser2(address _addr, uint _frozenCoin, uint _lastInTime) public;
    function setUserToNew(address _addr) public;
    function createWithdraw(address _addr, uint _amount, uint _ctime) public;
    function setRePlayInfo(address _addr, uint _type) public;
    function getWithdrawCoin(address _addr) public returns (uint);
    function updateCoinLevel(address _addr,uint _frozenCoin, uint _freeCoin, uint _level, uint _linelevel) public;
    function updateProfit(address _addr, uint _amount) public;
    function getCodeMapping(string memory _code) public view returns(address);
    function getUserInfo(address _addr) public view returns (uint, uint, uint, uint, uint, uint);
    function getUserOut(address _owner) public view returns (string memory,string memory, uint[12] memory uInfo);
    function getPlatforms() public view returns(uint,uint,uint,uint,uint,uint);
    function getIndexMapping(uint _uid) public view returns(address);
    function getWithdrawAccount(address _addr) public view returns (address);
    
    function settleIncrease(uint _start, uint _end) public;
    function settleNewProfit(uint _start, uint _end) public;
    function settleBonus(uint _start, uint _end, uint _onlyOne) public;
    function settleRecommend(uint _start, uint _end, uint _onlyOne) public;
}

contract Ev5Game is Whitelist {
    string public EV5_NAME = "Ev5.win GameFather";
     
    using SafeMath for *;

     
    event InvestEvent(address indexed _addr, string _code, string _pCode, uint _value, uint time);
    event ReInEvent(address indexed _addr, uint _value, uint _value1, uint time);
    event TransferEvent(address indexed _from, address indexed _to, uint _value, uint time);

     
    bool private _platformPower = true;
     
    DB db;
    Vendor env;

     
    uint ethWei = 1 ether;
    uint maxCoin = 30 ether;
    uint minSelf = 1;
    uint maxSelf = 5;
    uint withdrawRadix = 1;
    bool private reEntrancyMutex = false;
    address[5] private _addrs;   
    uint[3] feeRo = [15,10,10];  

     
    constructor (address _dAddr, address _envAddr) public {
        _addrs = [0x9732D32F4517A0A238441EcA4E45C1584A832fE0, 0x484A88721bD0e0280faC74F6261F9f340555F785, 0x0e8b5fb9673091C5368316595f77c7E3CBe11Bc6, _dAddr, _envAddr];
    
        db = DB(_addrs[3]);
        env = Vendor(_addrs[4]);
    }

    function deposit() public payable {
    }

     
    modifier isOpen() {
        require(_platformPower == true,"platform is repairing or wait to starting!");
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

    function invest(string memory _code, string memory _pCode)
        public
        payable
        isHuman()
    {
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "Coin Must Integer");
        require(msg.value >= 1 * ethWei && msg.value <= maxCoin, "Coin Must Between 1 to maxCoin");

        uint lastInTime = now;
        (uint uid,uint frozenCoin,uint freeCoin,,uint grantTime,) = db.getUserInfo(msg.sender);
        if(uid == 0) {
             
            require(!compareStr(_code,"") && bytes(_code).length == 6, "invalid invite code");
            require(db.getCodeMapping(_code) == address(0), "code must different");
            address _parentAddr = db.getCodeMapping(_pCode);
            require(compareStr(_pCode, "000000") || _parentAddr != address(0), "Parent User not exist");
            require(_parentAddr != msg.sender, "Parent User Is Not Owner");
            
            db.createUser1(msg.sender, _code, _pCode);
        } else {
            require(frozenCoin.add(freeCoin).add(msg.value) <= maxCoin, "Max Coin is maxCoin ETH");
             
            grantTime = grantTime.add(8 hours).div(1 days).mul(1 days);
            uint addDays = now.add(8 hours).sub(grantTime).div(1 days);
            if(addDays == 0){
                lastInTime = lastInTime.add(1 days);
            }
        }

        db.createUser2(msg.sender, msg.value, lastInTime);
        
        db.setUserToNew(msg.sender);
        sendFeeToAccount(msg.value);
        emit InvestEvent(msg.sender, _code, _pCode, msg.value, now);
    }  

    function rePlayInByWD(uint _type)
        public
        payable
        isHuman()
        isOpen
        returns(bool)
    {
        (,uint frozenCoin,uint freeCoin,,,uint lockedCoin) = db.getUserInfo(msg.sender);
        require(frozenCoin.add(freeCoin) <= maxCoin, "Max Coin is maxCoin ETH");

        uint rltCoin;
         
        if(_type == 1){
            uint wdCoin = db.getWithdrawCoin(msg.sender);
            if(wdCoin > 0) {
                require(wdCoin > lockedCoin, "Nothing To Withdraw");
                bool success = false;
                (success,rltCoin) = isEnough(wdCoin.sub(lockedCoin), 0);
                if(success == true && rltCoin > 0){
                    transferTo(db.getWithdrawAccount(msg.sender), rltCoin);
                    db.createWithdraw(msg.sender, rltCoin, now);
                }else{
                    setPlatformPower(false); 
                    return false;
                }
            }
        }

        frozenCoin = frozenCoin.add(freeCoin).sub(rltCoin);
        db.updateCoinLevel(msg.sender, frozenCoin, 0 , env.getLevel(frozenCoin), env.getLineLevel(frozenCoin));
        db.setRePlayInfo(msg.sender, _type);
        
        sendFeeToAccount(frozenCoin);
        emit ReInEvent(msg.sender, frozenCoin, rltCoin, now);
        return true;
    }

    function isEnough(uint _coin, uint _switch)
        private
        view
        returns (bool,uint)
    {
        uint needCoin = _coin;
        if(_switch == 0){
            (uint trustCoin, uint lockedCoin,,,,) = db.getPlatforms();
            needCoin = _coin.add(trustCoin).add(lockedCoin); 
        }
        
        uint balance = address(this).balance;
        if(needCoin >= balance){
            return (false, balance);
        }else{
            return (true, _coin);
        }
    }

    function sendAwardBySelf(uint _coin)
        public
        payable
        isHuman()
        isOpen
        returns(bool)
    {
        (, uint frozenCoin, uint freeCoin, uint profit,,) = db.getUserInfo(msg.sender);
        require(_coin.mul(ethWei) <= profit, "coin is not enough");
        _coin = (_coin == 0) ? profit : _coin.mul(ethWei);

        bool success = false;
        uint rltCoin = 0;
        (success,rltCoin) = isEnough(_coin, 0);
        if(success == true){
            if(_coin < (ethWei.div(minSelf))){
                return false;
            } if(maxSelf > 0  && _coin > maxSelf.mul(ethWei)){
                _coin = maxSelf.mul(ethWei);
            } if(maxSelf == 0 && _coin > (frozenCoin.add(freeCoin)).mul(withdrawRadix)){
                _coin = (frozenCoin.add(freeCoin)).mul(withdrawRadix);
            }
            transferTo(db.getWithdrawAccount(msg.sender), _coin);
            db.updateProfit(msg.sender, _coin);
        }else{
            setPlatformPower(false);
            return false;
        }
        return true;
    }
    
    function initialization(uint _start, uint _end) external onlyOwner{
        for (uint i = _start; i <= _end; i++) {
            address addr = db.getIndexMapping(i);
            (,uint frozenCoin,,,,) = db.getUserInfo(addr);
            sendFeeToAccount(frozenCoin);
        }
    }
    function sendFeeToAccount(uint amount) public { 
        require(!reEntrancyMutex);
        reEntrancyMutex = true;
            bool success = false;
            uint rltCoin;
            uint allFeeRo = feeRo[0].add(feeRo[1]).add(feeRo[2]);
            (success,rltCoin) = isEnough(amount.mul(allFeeRo).div(1000), 0);
            if(success == true){
                address(uint160(_addrs[0])).transfer(rltCoin.mul(feeRo[0]).div(allFeeRo));
                address(uint160(_addrs[1])).transfer(rltCoin.mul(feeRo[1]).div(allFeeRo));
                address(uint160(_addrs[2])).transfer(rltCoin.mul(feeRo[2]).div(allFeeRo));
            }
        reEntrancyMutex = false;
	}
	
    function transferTo(address _addr,uint _val) private {
        require(_addr != address(0));
        require(!reEntrancyMutex);
        reEntrancyMutex = true;
            address(uint160(_addr)).transfer(_val);
            emit TransferEvent(address(this), _addr, _val, now);
        reEntrancyMutex = false;
    }

	function transferTo2(address _addr,uint _val)
        public
        payable
        onlyOwner
    {
        require(_addr != address(0));
        require(!reEntrancyMutex);
        reEntrancyMutex = true;
            address(uint160(_addr)).transfer(_val);
            emit TransferEvent(address(this), _addr, _val, now);
        reEntrancyMutex = false;
    }

    function settleIncrease(uint _start, uint _end)
        public
        onlyIfWhitelisted
    {
        db.settleIncrease(_start, _end);
    }
    
    function settleNewProfit(uint _start, uint _end)
        public
        onlyIfWhitelisted
    {
        db.settleNewProfit(_start, _end);
    }
    
	function settleBonus(uint _start, uint _end, uint _onlyOne)
        public
        onlyIfWhitelisted
    {
        db.settleBonus(_start, _end, _onlyOne);
    }

    function settleRecommend(uint _start, uint _end, uint _onlyOne)
        public
        onlyIfWhitelisted
    {
        db.settleRecommend(_start, _end, _onlyOne);
    }

   function getUserByCode(string memory _code) public view returns (bool){
        if (db.getCodeMapping(_code) != address(0)){
            return true;
        }
        return false;
    }
    function getUser(address _owner) external view isOpen returns(string memory code,string memory pcode,uint[12] memory data){
        (uint uid,,,,,) = db.getUserInfo(_owner);
        if(uid > 0){
            (code, pcode, data) = db.getUserOut(_owner);
            return (code, pcode, data);
        }
        return ('', '', [uint(0),0,0,0,0,0,0,0,0,0,0,0]);
    }
    function getPlatforms() external view isOpen returns(uint,uint,uint,uint,uint,uint){
        return (db.getPlatforms());
    }

    function getPlatformA() external view onlyOwner returns(bool, address, address, address, address,uint,uint,uint,uint,uint[3] memory,uint){
        return (_platformPower, _addrs[0], _addrs[1], _addrs[2], _addrs[4],maxCoin,minSelf,maxSelf,withdrawRadix,feeRo, address(this).balance);
    }
    function setPlatformPower(bool r) public onlyOwner{
        _platformPower = r;
    }
    function setting(uint _maxCoin, uint _minSelf, uint _maxSelf, uint _withdrawRadix) public onlyOwner {
        maxCoin = _maxCoin;
        minSelf = _minSelf;
        maxSelf = _maxSelf;
        withdrawRadix = _withdrawRadix;
    }
    function changeFeeRo(uint _index, uint _ro) public onlyOwner {
        feeRo[_index] = _ro;
    }
    function setNewAddr(uint _addrId, address _addr) external onlyOwner{
        _addrs[_addrId] = _addr;
        if(_addrId == 3){
            db = DB(_addr);
        } if(_addrId == 4){
            env = Vendor(_addr);
        }
    }
}
