 

pragma solidity >=0.5.11 <0.7.0;

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
    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Signable is Ownable{
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);
    
    Roles.Role private _signers;
 
    constructor ()  internal {
        addSigner(msg.sender);
    }
    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }
    
    function addSigner(address account) public onlyOwner {
        _addSigner(account);
    }

    function renounceSigner() public onlyOwner {
        _removeSigner(msg.sender);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}
contract Management is Ownable{
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);
    
    Roles.Role private _managers;
    
    enum State { Active,Locked}
    
    State public state;
    
    modifier inState(State _state) {
        require(state == _state,"Invalid state");
        _;
    }

    constructor ()  internal {
        addManager(msg.sender);
    }
    
    function setState(State _state) 
        public
        onlyManager
    {
        state = _state;
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

contract ECDSAMock is Signable {
    using ECDSA for bytes32;
    
    function recover(bytes32 hash, bytes memory signature) 
        public 
        pure 
        returns (address) 
    {
        return hash.recover(signature);
    }

    function isValidSigner(address _user,address _feerecipient,uint256 _amount,uint256 _fee,uint256 _signblock,uint256 _valid,bytes memory signature) 
        public 
        view 
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(_user,_feerecipient,_amount,_fee,_signblock,_valid));
         
        address signaddress = recover(hash,signature);
        return isSigner(signaddress);
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

contract FundToken {
    TokenCreator public creater;
    IERC20 private _usdtAddress;
    struct User {
        uint64 id;
        uint64 referrerId;
        address payable[] referrals;
        mapping(uint8 => uint64) levelExpired;
    }
    uint8 public constant REFERRER_1_LEVEL_LIMIT = 2;
    uint64 public constant PERIOD_LENGTH = 1 days;
    bool public onlyAmbassadors = true;
    address payable public ownerWallet;
    uint64 public lastUserId;
    mapping(uint8 => uint) public levelPrice;
    mapping(uint => uint8) public priceLevel;
    mapping(address => User) public users;
    mapping(uint64 => address payable) public userList;    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 constant internal magnitude = 2**64;
    event Registration(address indexed user, address referrer);
    event LevelBought(address indexed user, uint8 level);
    event GetMoneyForLevel(address indexed user, address indexed referral, uint8 level);
    event SendMoneyError(address indexed user, address indexed referral, uint8 level);
    event LostMoneyForLevel(address indexed user, address indexed referral, uint8 level);    
    event onWithdraw(address indexed customerAddress,uint256 ethereumWithdrawn);
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    constructor(IERC20 usdt)   
        public 
    {
        creater = TokenCreator(msg.sender);
        _usdtAddress = usdt;
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.approve.selector,msg.sender, 2**256-1));
    }
    
    function getCreater() 
        public 
        view 
        returns(address )
    {
        return address(creater);
    }
    
    function payForLevel(uint8 level, address user) private {
        address payable referrer;

        if (level%2 == 0) {
            referrer = userList[users[userList[users[user].referrerId]].referrerId];
        } else {
            referrer = userList[users[user].referrerId];
        }

        if(users[referrer].id == 0) {
            referrer = userList[1];
        } 

        if(users[referrer].levelExpired[level] >= now) {
            if (referrer.send(levelPrice[level])) {
                emit GetMoneyForLevel(referrer, msg.sender, level);
            } else {
                emit SendMoneyError(referrer, msg.sender, level);
            }
        } else {
            emit LostMoneyForLevel(referrer, msg.sender, level);

            payForLevel(level, referrer);
        }
    }   
    function regUser(uint64 referrerId) public  {
        require(users[msg.sender].id == 0, 'User exist');
        require(referrerId > 0 && referrerId <= lastUserId, 'Incorrect referrer Id');
        
        if(users[userList[referrerId]].referrals.length >= REFERRER_1_LEVEL_LIMIT) {
            address freeReferrer = findFreeReferrer(userList[referrerId]);
            referrerId = users[freeReferrer].id;
        }
            
        lastUserId++;

        users[msg.sender] = User({
            id: lastUserId,
            referrerId: referrerId,
            referrals: new address payable[](0) 
        });
        
        userList[lastUserId] = msg.sender;

        users[msg.sender].levelExpired[1] = uint64(now + PERIOD_LENGTH);

        users[userList[referrerId]].referrals.push(msg.sender);

        payForLevel(1, msg.sender);

        emit Registration(msg.sender, userList[referrerId]);
    }
    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referrals.length < REFERRER_1_LEVEL_LIMIT) 
            return _user;

        address[] memory referrals = new address[](256);
        address[] memory referralsBuf = new address[](256);

        referrals[0] = users[_user].referrals[0];
        referrals[1] = users[_user].referrals[1];

        uint32 j = 2;
        
        while(true) {
            for(uint32 i = 0; i < j; i++) {
                if(users[referrals[i]].referrals.length < 1) {
                    return referrals[i];
                }
            }
            
            for(uint32 i = 0; i < j; i++) {
                if (users[referrals[i]].referrals.length < REFERRER_1_LEVEL_LIMIT) {
                    return referrals[i];
                }
            }

            for(uint32 i = 0; i < j; i++) {
                referralsBuf[i] = users[referrals[i]].referrals[0];
                referralsBuf[j+i] = users[referrals[i]].referrals[1];
            }

            j = j*2;

            for(uint32 i = 0; i < j; i++) {
                referrals[i] = referralsBuf[i];
            }
        }
    }
    function withdraw()
        onlyStronghands()
        public
    {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
    }
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    function callOptionalReturn(IERC20 token, bytes memory data) 
        private 
    {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface BETGAME {
    function bet(uint256 amount,address beter,uint8 color,uint256 _round,uint256 orderid) external returns (bool);
}

contract TokenCreator is ECDSAMock ,Management{
    using SafeMath for uint256;
    using Address for address;
    uint256 public round;
    mapping(uint256 => uint256) public id;

    
    IERC20 private _usdtAddress;
    mapping(address => bool) private _games;
    mapping(bytes10 => address)  public referrals;

    
    struct userModel {
        address fundaddress;
        bytes10 referral;
        bytes10 referrerCode;
    }
    
    struct userInverstModel {
        uint256 totalinverstmoney;
        uint256 totalinverstcount;
        uint256 balance;
        uint256 freeze;
        uint256 candraw;
        uint256 lastinversttime;
        uint256 lastwithDrawtime;
        bool luckRewardRecived;
        uint256 luckRewardAmount;
    }
    

    mapping(address => mapping(uint256 => userInverstModel)) public userinverstinfo;

    mapping(address => userModel) public userinfo;
    struct inverstModel {
        uint256 lowest;
        uint256 highest;
        uint256 interval;
        uint256 basics;
    }
    
    struct drawithDrawModel {
        uint256 lowest;
        uint256 highest;
        uint256 interval;
    }
    drawithDrawModel public withDrawinfo;
    
    inverstModel public inverstinfo;
    mapping(bytes => bool) public signatures;
    

    modifier nonReentrant() {
        id[round] += 1;
        uint256 localCounter = id[round];
        _;
        require(localCounter == id[round], "ReentrancyGuard: reentrant call");
    }
    
    event Inverst(address indexed user,uint256  indexed amount,uint256 indexed round) ;
    event CreateFund(address indexed user,address indexed fund);
    event WithDraw(address indexed user,uint256 indexed amount,bytes indexed  signature);
    event DrawLuckReward(address indexed user,uint256 indexed amount ,uint256 indexed round);
    event BatchLuckRewards(address[] indexed lucks,uint256 indexed amount,uint256  indexed indexed round);
    event AllocationFunds(address indexed from,address indexed to,uint256 indexed amount);
    
    constructor() 
        public
    {
        _usdtAddress = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        round = 1;
        inverstinfo.lowest = 100 *10 ** 6;
        inverstinfo.highest = 5000 *10 ** 6;
        inverstinfo.basics = 100 * 10 ** 6;
        inverstinfo.interval = 1 days;
        withDrawinfo.lowest = 100 *10 ** 6;
        withDrawinfo.highest = 5000 *10 ** 6;
        withDrawinfo.interval = 1 days;
        userinfo[msg.sender].fundaddress = address(this);
        userinfo[msg.sender].referral = "king";
        userinfo[msg.sender].referrerCode = "king";
        referrals["king"] = msg.sender;
    }
 
    function reboot() 
        public 
        onlyManager 
    {
        round = round.add(1);
    }
    function InverstSet(uint256 lowest,uint256 highest,uint256 interval,uint256 _basics) 
        public 
        onlyOwner 
    {
        require(highest>lowest && highest>0);
        inverstinfo.lowest = lowest;
        inverstinfo.highest = highest;
        inverstinfo.interval = interval;
        inverstinfo.basics = _basics;
    }
    function setWithDrawInfo(uint256 lowest,uint256 highest,uint256 interval) 
        public 
        onlyOwner 
    {
        require(lowest>= lowest  ,"Invalid withdraw range");
        withDrawinfo.lowest = lowest;
        withDrawinfo.highest = highest;
        withDrawinfo.interval = interval;
    }
    function USDTSet(IERC20 _usdt) 
        public 
        onlyOwner 
    {
        require(Address.isContract(address(_usdt)),"Invalid address");
        _usdtAddress = _usdt;
    }
    function gameAdd(BETGAME _game) 
        public 
        onlyOwner 
    {
        require(Address.isContract(address(_game)),"Invalid address");
        _games[address(_game)] = true;
    }
    
    function createToken(address registrant,bytes10  referrer,bytes10  referrerCode)
        private
        inState(State.Active)
        returns(bool)
    {
        require(referrals[referrerCode] == address(0));
        userModel storage user = userinfo[registrant];
        require(referrals[referrer] != address(0) && user.fundaddress == address(0),"User already exists or recommendation code is invalid");
        FundToken fund = new FundToken(_usdtAddress);
        user.fundaddress = address(fund);
        user.referral = referrer;
        user.referrerCode = referrerCode;
        referrals[referrerCode] = registrant;
        emit CreateFund(registrant,address(fund));
        return true;
    }
    
    
    function inverst(uint256 amount,bytes10  referrer,bytes10  referrerCode) 
        public 
        inState(State.Active)
        nonReentrant 
        returns(bool)
    {
        userModel storage userfund = userinfo[msg.sender];
        if(userfund.fundaddress == address(0)){
            createToken(msg.sender,referrer,referrerCode);
        }
        userInverstModel storage user = userinverstinfo[msg.sender][round];
        uint256 inversttime = now;
        require(amount >= inverstinfo.lowest && amount <= inverstinfo.highest && amount.mod(inverstinfo.basics)==0,"Invalid investment amount");
        require(inversttime.sub(inverstinfo.interval) >= user.lastinversttime,"Invalid investment time");
 
        user.freeze = user.freeze.add(amount);
        user.totalinverstcount = user.totalinverstcount.add(1);
        user.totalinverstmoney = user.totalinverstmoney.add(amount);
        user.balance = user.balance.add(amount);
        user.lastinversttime = inversttime;
  
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,msg.sender, userfund.fundaddress, amount));
        emit Inverst(msg.sender,amount,round);
        return true;
    }
    
    function withDraw(address feerecipient,uint256 amount,uint256 fee,uint256 signblock,uint256 valid,bytes memory signature) 
        public 
        inState(State.Active)
    {
        require(!signatures[signature],"Duplicate signature");
        require(amount >= fee,'Invalid withdraw fee');
        userInverstModel storage user = userinverstinfo[msg.sender][round];
        userModel storage userfund = userinfo[msg.sender];
        require(userfund.fundaddress != address(0) &&_usdtAddress.balanceOf(userfund.fundaddress) >= amount,"Invalid user Or Insufficient balance");
        
        require(amount >=withDrawinfo.lowest && amount <= withDrawinfo.highest,"Invalid withdraw amount");
        require(user.lastwithDrawtime.add(withDrawinfo.interval) <= now,"Invalid withdraw time");
        require(user.candraw >= amount,"Insufficient  withdrawal balance");

        require(onlyValidSignature(feerecipient,amount,fee,signblock,valid,signature),"Invalid signature");
        user.lastwithDrawtime = now;
        user.candraw = user.candraw.sub(amount);
        user.balance = user.balance.sub(amount);

        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,userfund.fundaddress, msg.sender, amount.sub(fee)));
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,userfund.fundaddress, feerecipient, fee));
        signatures[signature] = true;
        emit WithDraw(msg.sender,amount,signature);
    }
    
    function allocationFundsIn(uint256 amount,address source, address destination)  
        public 
        onlyManager
        returns(bool)
    {
        userInverstModel storage souruser = userinverstinfo[source][round];
        userInverstModel storage destuser = userinverstinfo[destination][round];
        
        userModel storage sourceuserfund = userinfo[source];
        userModel storage destinationuserfund = userinfo[destination];
        
        require(souruser.freeze >= amount && amount >0,"Invalid allocation of amount");
        require(sourceuserfund.fundaddress != address(0) && destinationuserfund.fundaddress != address(0),"Invalid allocation user");
        
        require(_usdtAddress.balanceOf(sourceuserfund.fundaddress) >= amount,"Insufficient balance");
      
        souruser.freeze = souruser.freeze.sub(amount);
        souruser.balance = souruser.balance.sub(amount);
        
        destuser.candraw =destuser.candraw.add(amount);
        destuser.balance = destuser.balance.add(amount);
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,sourceuserfund.fundaddress, destinationuserfund.fundaddress, amount));
        emit AllocationFunds(source,destination,amount);
        return true;
    }
    
    function feewithDraw(uint256 amount,address luckuser,address sysuser) 
        public 
        onlyManager
        returns(bool)
    {
        userInverstModel storage user = userinverstinfo[luckuser][round];
        userModel storage userfund = userinfo[luckuser];
        require(amount >0 && _usdtAddress.balanceOf(userfund.fundaddress) >= amount,"Invalid fee amount");
        user.freeze = user.freeze.sub(amount);
        user.balance = user.balance.sub(amount);
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,userfund.fundaddress, sysuser, amount));
        return true;
    }
    
    function managerWithDraw(address sender, address recipient, uint256 amount) 
        public 
        onlyManager 
        returns(bool)
    {
        userModel storage user = userinfo[sender];
        require(_usdtAddress.balanceOf(user.fundaddress) >= amount,"Insufficient balance");
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,user.fundaddress, recipient, amount));
        return true;
    }
    
    function adminWithDraw(address recipient,uint256 amount)
        public
        onlyManager
        returns(bool)
    {
        require(_usdtAddress.balanceOf(address(this)) >= amount,"Insufficient balance");
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transfer.selector,recipient, amount));
        return true;
    }
    
    function luckReward(uint256 amount,address luckuser,uint256 _round) 
        public  
        onlyManager 
        returns(bool)
    {
        require(round == _round ,"Invalid round");
        userInverstModel storage user = userinverstinfo[luckuser][round];
        require(!user.luckRewardRecived && amount >0 && _usdtAddress.balanceOf(address(this))>= amount,"Insufficient balance Or User already received the award");

        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transfer.selector,luckuser, amount));
        user.luckRewardRecived = true;
        user.luckRewardAmount = amount;

        emit DrawLuckReward(luckuser,amount,round);
        return true;
    }
    
    function batchluckRewards(address[] memory lucks, uint256 amount,uint256 _round) 
        public  
        onlyManager 
        returns(bool)
    {
        require(round == _round ,"Invalid round");
        require(lucks.length.mul(amount) <= _usdtAddress.balanceOf(address(this)),"Insufficient contract balance");
        for(uint i=0;i<lucks.length;i++){
            userInverstModel storage user = userinverstinfo[lucks[i]][round];
            require(!user.luckRewardRecived,"User already received the award");
            callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transfer.selector,lucks[i], amount));
            user.luckRewardRecived = true;
            user.luckRewardAmount = amount;
        }
        emit BatchLuckRewards(lucks,amount,round);
        return true;
    }
    
    function bet(BETGAME _g,uint256 _round,uint256 _id,uint256 _amount,uint8 _color) 
        public
        inState(State.Active)
        returns(bool)
    {
        require(_games[address(_g)],"Invalid game");
        callOptionalReturn(_usdtAddress, abi.encodeWithSelector(_usdtAddress.transferFrom.selector,msg.sender, address(_g), _amount));
        require(_g.bet(_amount,msg.sender,_color,_round,_id),"Bet Failed");
        return true;
    }
    
    function  onlyValidSignature(address feerecipient,uint256 amount,uint256 fee ,uint256 signblock ,uint256 valid,bytes memory signature) 
        public 
        view 
        returns(bool)
    {
        require(block.number <= signblock.add(valid),"Invalid block");
        require(isValidSigner(msg.sender,feerecipient,amount,fee,signblock,valid,signature),"Invalid signature");
        return true;
    }

    function callOptionalReturn(IERC20 token, bytes memory data) 
        private 
    {
        require(address(_usdtAddress).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}