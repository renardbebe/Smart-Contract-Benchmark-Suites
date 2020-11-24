 

pragma solidity ^0.5.1;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner = address(0);
    bool public stoped  = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Stoped(address setter ,bool newValue);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whenNotStoped() {
        require(!stoped);
        _;
    }

    function setStoped(bool _needStoped) public onlyOwner {
        require(stoped != _needStoped);
        stoped = _needStoped;
        emit Stoped(msg.sender,_needStoped);
    }


    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Cmoable is Ownable {
    address public cmo = address(0);

    event CmoshipTransferred(address indexed previousCmo, address indexed newCmo);

    modifier onlyCmo() {
        require(msg.sender == cmo);
        _;
    }

    function renounceCmoship() public onlyOwner {
        emit CmoshipTransferred(cmo, address(0));
        owner = address(0);
    }

    function transferCmoship(address newCmo) public onlyOwner {
        _transferCmoship(newCmo);
    }

    function _transferCmoship(address newCmo) internal {
        require(newCmo != address(0));
        emit CmoshipTransferred(cmo, newCmo);
        cmo = newCmo;
    }
}


contract BaseToken is Ownable, Cmoable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8  public decimals;
    uint256 public totalSupply;
    uint256 public initedSupply = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwnerOrCmo() {
        require(msg.sender == cmo || msg.sender == owner);
        _;
    }

    function _transfer(address _from, address _to, uint256 _value) internal whenNotStoped {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
    }
    
    function _approve(address _spender, uint256 _value) internal whenNotStoped returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return _approve(_spender, _value);
    }
}


contract BurnToken is BaseToken {
    uint256 public burnSupply = 0;
    event Burn(address indexed from, uint256 value);

    function _burn(address _from, uint256 _value) internal whenNotStoped returns(bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        burnSupply  = burnSupply.add(_value);
        emit Burn(_from, _value);
        return true;        
    }

    function burn(uint256 _value) public returns (bool success) {
        return _burn(msg.sender,_value);
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        return _burn(_from,_value);
    }
}

contract Cappedable is BaseToken {
    uint256 public cap = 0;
    uint256 public currentCapped = 0;
    uint256 public capBegintime = 0;
    uint256 public capPerday = 0;
    uint256 public capStartday = 0;

    mapping (uint256 => uint256) public mintedOfDay;

    event Minted(address indexed account, uint256 value);

    function mint(address to, uint256 value) public onlyOwnerOrCmo  returns (bool) {
        _mint(to, value);
        return true;
    }

    function _mint(address to, uint256 value)  internal whenNotStoped {
        require(to != address(0));
        require(now > capBegintime);
        if ( cap != 0 ) {
            require(currentCapped + value <= cap);
            if ( capPerday != 0 ) {
                require(currentCapped + value <= (( now/86400 - capStartday )+1).mul(capPerday));
            }
        }
        
        totalSupply   = totalSupply.add(value);
        currentCapped = currentCapped.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        mintedOfDay[now/86400+1] = mintedOfDay[now/86400+1].add(value);
        emit Minted(to, value);
    }
}

contract AirdropToken is BaseToken {
    uint256 public airMaxSupply = 0;
    uint256 public airSupply = 0;
    uint256 public airPerTime = 0;
    uint256 public airBegintime = 0;
    uint256 public airEndtime = 0;
    uint256 public airLimitCount = 0;

    mapping (address => uint256) public airCountOf;

    event Airdrop(address indexed from, uint256 indexed count, uint256 tokenValue);
    event AirdopSettingChanged(address indexed sender,uint256 _beginAt, uint256 _endAt, uint256 _perTime, uint256 _limitCount);


    function airdrop() internal whenNotStoped  
    {
        require(now >= airBegintime && now <= airEndtime);
        if (airMaxSupply > 0 )
        {
            require(airSupply + airPerTime <= airMaxSupply);
        }
        require(msg.value == 0);
        if (airLimitCount > 0 && airCountOf[msg.sender] >= airLimitCount) {
            revert();
        }
        airCountOf[msg.sender] = airCountOf[msg.sender].add(1);

        totalSupply = totalSupply.add(airPerTime);
        airSupply  = airSupply.add(airPerTime);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(airPerTime);
        emit Airdrop(msg.sender, airCountOf[msg.sender], airPerTime);
    }

    function changeAirdopSetting(uint256 _beginAt, uint256 _endAt, uint256 _perTime, uint256 _limitCount) public onlyOwnerOrCmo  {
        airBegintime = _beginAt;
        airEndtime   = _endAt;
        airPerTime   = _perTime;
        airLimitCount = _limitCount;
        emit AirdopSettingChanged(msg.sender,_beginAt, _endAt, _perTime, _limitCount);
    }
}

contract Investable is BaseToken {
    uint256 public investMaxSupply = 0;
    uint256 public investSupply = 0;
    uint256 public investBegintime = 0;
    uint256 public investEndtime = 0;
    uint256 public investRatio = 0;
    uint256 public investMin  = 0;
    address payable public investHolder = address(0x0);

    event Investabled(address indexed from, uint256 ethAmount, uint256 ratio, uint256 tokenValue);
    event InvestableSettingChanged(address indexed sender,uint256 _beginAt, uint256 _endAt, uint256 _ratio ,uint256 _min, address _holder);
    event InvestWithdraw(address indexed receiver, uint256 balance);

    function invest() internal {
        return _invest();
    }

    function _invest() internal whenNotStoped {
        
        require(now >= investBegintime && now <= investEndtime);
        require(msg.value >= investMin);

        uint256 _amount = msg.value.mul(investRatio).div(1000000000000000000);
        require(_amount > 0);
        if (investMaxSupply > 0 )
        {
            require(_amount + investSupply <= investMaxSupply);
        }

        totalSupply = totalSupply.add(_amount);
        investSupply  = investSupply.add(_amount);
        balanceOf[msg.sender] =  balanceOf[msg.sender].add(_amount);
        emit Investabled(msg.sender,msg.value,investRatio,_amount);
    }

    function changeInvestSetting(uint256 _beginAt, uint256 _endAt, uint256 _ratio ,uint256 _min, address payable _holder) public onlyOwnerOrCmo {
        
        require(_ratio > 0);
        investBegintime = _beginAt;
        investEndtime = _endAt;
        investRatio  = _ratio;
        investMin    = _min;
        investHolder = _holder;
        emit InvestableSettingChanged(msg.sender, _beginAt, _endAt, _ratio , _min, _holder);
    }

    function investWithdraw() public onlyOwnerOrCmo {

        require( !stoped || msg.sender == owner);
        
        uint256 amount = address(this).balance;
        investHolder.transfer(amount);
        emit InvestWithdraw(investHolder, amount);
    }
}

contract BatchableToken is BaseToken {
    uint8 public constant  arrayLimit = 100;
    
    event Multisended(address indexed proxyer,address indexed sender, uint256 total);
  
    function _batchSenderFrom(address payable _from, address[] memory _contributors, uint256[] memory _balances) internal whenNotStoped returns (bool success) 
    {
        uint256 total = 0;
        require(_contributors.length <= arrayLimit);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            _transfer(_from, _contributors[i], _balances[i]);
            total = total.add(_balances[i]);
        }
        emit Multisended(msg.sender, msg.sender, total);
        return true;
    }

    function batchSender(address[] memory _contributors, uint256[] memory _balances) public returns (bool success)  {
        return _batchSenderFrom(msg.sender,_contributors,_balances);
    }
}

 
contract LockToken is BaseToken {
    struct LockMeta {
        uint256 amount;
        uint256 endtime;
        bool    deleted;
    }

     
    event Locked(uint32 indexed _type, address indexed _who, uint256 _amounts, uint256 _endtimes);
    event Released(uint32 indexed _type, address indexed _who, uint256 _amounts);
     
    mapping (address => mapping(uint32 => uint256)) public lockedAmount;
      
    mapping (address => mapping(uint32 => LockMeta[])) public lockedDetail;

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value + lockedAmount[_from][2]);
        super._transfer(_from, _to, _value);
    }

    function lockRelease() public whenNotStoped {
        
        require(lockedAmount[msg.sender][3] != 0);

        uint256 fronzed_released = 0;
        uint256 dynamic_released = 0;

        if ( lockedAmount[msg.sender][0] != 0 )
        {
            for (uint256 i = 0; i < lockedDetail[msg.sender][0].length; i++) {

                LockMeta storage _meta = lockedDetail[msg.sender][0][i];
                if ( !_meta.deleted && _meta.endtime <= now)
                {
                    _meta.deleted = true;
                    fronzed_released = fronzed_released.add(_meta.amount);
                    emit Released(1, msg.sender, _meta.amount);
                }
            }
        }

        if ( lockedAmount[msg.sender][1] != 0 )
        {
            for (uint256 i = 0; i < lockedDetail[msg.sender][1].length; i++) {

                LockMeta storage _meta = lockedDetail[msg.sender][0][i];
                if ( !_meta.deleted && _meta.endtime <= now)
                {
                    _meta.deleted = true;
                    dynamic_released = dynamic_released.add(_meta.amount);
                    emit Released(2, msg.sender, _meta.amount);
                    
                }
            }
        }

        if ( fronzed_released > 0 || dynamic_released > 0 ) {
            lockedAmount[msg.sender][0] = lockedAmount[msg.sender][0].sub(fronzed_released);
            lockedAmount[msg.sender][1] = lockedAmount[msg.sender][1].sub(dynamic_released);
            lockedAmount[msg.sender][2] = lockedAmount[msg.sender][2].sub(dynamic_released).sub(fronzed_released);
        }
    }

     
    function lock(uint32 _type, address _who, uint256[] memory _amounts, uint256[] memory _endtimes) public  onlyOwnerOrCmo {
        require(_amounts.length == _endtimes.length);

        uint256 _total;

        if ( _type == 2 ) {
            if ( lockedDetail[_who][1].length > 0 )
            {
                emit Locked(0, _who, lockedAmount[_who][1], 0);
                delete lockedDetail[_who][1];
            }

            for (uint256 i = 0; i < _amounts.length; i++) {
                _total = _total.add(_amounts[i]);
                lockedDetail[_who][1].push(LockMeta({
                    amount: _amounts[i],
                    endtime: _endtimes[i],
                    deleted:false
                }));
                emit Locked(2, _who, _amounts[i], _endtimes[i]);
            }
            lockedAmount[_who][1] = _total;
            lockedAmount[_who][2] = lockedAmount[_who][0].add(_total);
            return;
        }


        if ( _type == 1 ) {
            if ( lockedDetail[_who][0].length > 0 )
            {
                revert();
            }

            for (uint256 i = 0; i < _amounts.length; i++) {
                _total = _total.add(_amounts[i]);
                lockedDetail[_who][0].push(LockMeta({
                    amount: _amounts[i],
                    endtime: _endtimes[i],
                    deleted:false
                }));
                emit Locked(1, _who, _amounts[i], _endtimes[i]);
            }
            lockedAmount[_who][0] = _total;
            lockedAmount[_who][2] = lockedAmount[_who][1].add(_total);
            return;
        }

        if ( _type == 0 ) {
            lockedAmount[_who][2] = lockedAmount[_who][2].sub(lockedAmount[_who][1]);
            emit Locked(0, _who, lockedAmount[_who][1], 0);
            delete lockedDetail[_who][1];
            
        }
    }
}

contract Proxyable is BaseToken, BatchableToken, BurnToken{

    mapping (address => bool) public disabledProxyList;

    function enableProxy() public whenNotStoped {

        disabledProxyList[msg.sender] = false;
    }

    function disableProxy() public whenNotStoped{
        disabledProxyList[msg.sender] = true;
    }

    function proxyBurnFrom(address _from, uint256 _value) public  onlyOwnerOrCmo returns (bool success) {
        
        require(!disabledProxyList[_from]);
        super._burn(_from, _value);
        return true;
    }

    function proxyTransferFrom(address _from, address _to, uint256 _value) public onlyOwnerOrCmo returns (bool success) {
        
        require(!disabledProxyList[_from]);
        super._transfer(_from, _to, _value);
        return true;
    }

  

    function proxyBatchSenderFrom(address payable _from, address[] memory _contributors, uint256[] memory _balances) public onlyOwnerOrCmo returns (bool success) {

        require(!disabledProxyList[_from]);
        super._batchSenderFrom(_from, _contributors,_balances);
        return true;
    } 
  
}

contract Pauseable is BaseToken, BurnToken {
    event Paused(address account, bool paused);
    
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function setPause(bool _needPause) public onlyOwnerOrCmo {
        require(paused != _needPause);
        paused = _needPause;
        emit Paused(msg.sender,_needPause);
    }
    
    function _transfer(address _from, address _to, uint _value) internal  whenNotPaused {
        return super._transfer(_from, _to, _value);
    }

    function _burn (address _from, uint256 _value) internal  whenNotPaused returns(bool success) {
        return super._burn(_from, _value);
    }
    
    function _approve(address spender, uint256 value) internal whenNotPaused returns (bool) {
        return super._approve(spender, value);
    }
}
 

contract BeautyUnderToken is BaseToken,Investable,Cappedable,BatchableToken,BurnToken,Pauseable,AirdropToken,LockToken,Proxyable {

    constructor() public {
        
        totalSupply  = 100000000000000;
        initedSupply = 100000000000000;
        name = 'Beauty Under Token';
        symbol = 'BUT';
        decimals = 6;
        balanceOf[0xc114968f565f0260b80bD626b5802629188C0251] = 100000000000000;
        emit Transfer(address(0), 0xc114968f565f0260b80bD626b5802629188C0251, 100000000000000);

         
        owner = 0xc114968f565f0260b80bD626b5802629188C0251;
        cmo   = 0xc114968f565f0260b80bD626b5802629188C0251;
        
        cap = 0;
        capPerday = 0;
        capBegintime = 1572920937;
        capStartday  = 18205;

         
        airMaxSupply = 10000000000;
        airPerTime   = 2000000;
        airBegintime = 1572920937;
        airEndtime   = 1580399999;
        airLimitCount = 1;

         
         
         
         
         
         
         

    }

    function() external payable 
    {
       
        if ( 0 == msg.value )
        {
            airdrop();
        }


        if ( 0 < msg.value ) {
            invest();
        }
    }
}