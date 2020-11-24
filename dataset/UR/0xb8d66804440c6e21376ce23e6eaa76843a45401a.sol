 

pragma solidity 0.5.3;   


 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function subsafe(uint256 a, uint256 b) internal pure returns (uint256) {
    if(b <= a){
        return a - b;
    }else{
        return 0;
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}


contract DepositToken_10 {
    
    using SafeMath for uint;
    
    string public constant name = "DeposiToken";
    
    string public constant symbol = "DT10";
    
    uint32 public constant decimals = 15;
    
    uint public _money = 0;
    uint public _tokens = 0;
    uint public _sellprice;
    
     
    address payable public theStocksTokenContract;
    
     
    
    mapping (address => uint) private balances;
    
    event FullEventLog(
        address indexed user,
        bytes32 status,
        uint sellprice,
        uint buyprice, 
        uint time,
        uint tokens,
        uint ethers);
        
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value);
        
     
    constructor (address payable _tstc) public {
        uint s = 10**13;  
        _sellprice = s.mul(90).div(100);
        theStocksTokenContract = _tstc;
        
         
        uint _value = 1000 * 10**15; 
        
        _tokens += _value;
        balances[address(this)] += _value;
        
        emit Transfer(address(0x0), address(this), _value);
    }
    
     
    function totalSupply () public view returns (uint256 tokens) {
        return _tokens;
    }
    
     
    function balanceOf(address addr) public view returns(uint){
        return balances[addr];
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        address addressContract = address(this);
        require(_to == addressContract);
        sell(_value);
        success = true;
    }
    
     
    function () external payable {
        buy(address(0x0));
    }
    
    
     
     
     
    
     
    
     
    mapping (address => address payable) public referrers;
    
     
    mapping (address => uint) public referrerBonusBalance;
    
     
    event ReferrerBonus(address indexed referer, address indexed depositor, uint256 depositAmount , uint256 etherReceived, uint256 timestamp );
    
     
    event ReferralBonusClaim(address indexed referrar, uint256 bonus, uint256 timestamp);
     
    function distributeReferrerBonus(address payable _directReferrer, uint platformFee) internal returns (uint){
        
         
        uint finaPlatformFee = platformFee;
        
         
        uint _valueLevel1 = platformFee.mul(40).div(100);
        referrerBonusBalance[_directReferrer] += _valueLevel1;   
        finaPlatformFee = finaPlatformFee.sub(_valueLevel1);
        emit ReferrerBonus(_directReferrer, msg.sender, msg.value , _valueLevel1, now );
    
        
         
        if(referrers[_directReferrer] != address(0x0)){
             
            uint _valueLevel2 = platformFee.mul(10).div(100);
            referrerBonusBalance[referrers[_directReferrer]] += _valueLevel2;   
            finaPlatformFee = finaPlatformFee.sub(_valueLevel2);
            emit ReferrerBonus(referrers[_directReferrer], msg.sender, msg.value , _valueLevel2, now );
        }
        
         
        if(referrers[referrers[_directReferrer]] != address(0x0)){
             
            uint _valueLevel3 = platformFee.mul(10).div(100);
            referrerBonusBalance[referrers[referrers[_directReferrer]]] += _valueLevel3;   
            finaPlatformFee = finaPlatformFee.sub(_valueLevel3);
            emit ReferrerBonus(referrers[referrers[_directReferrer]], msg.sender, msg.value , _valueLevel3, now );
        }
        
         
        return finaPlatformFee;
    }
    
     
    function claimReferrerBonus() public {
        uint256 referralBonus = referrerBonusBalance[msg.sender];
        require(referralBonus > 0, 'Insufficient referrer bonus');
        referrerBonusBalance[msg.sender] = 0;
        msg.sender.transfer(referralBonus);
        emit ReferralBonusClaim(msg.sender,referralBonus,now);
    }
    
    
     
    function buy(address payable _referrer) public payable {
        uint _value = msg.value.mul(10**15).div(_sellprice.mul(100).div(90));
        
         
        _money = _money.add(msg.value.mul(95).div(100));
        
         
        uint platformFee = msg.value.mul(50).div(1000);
        
         
        uint finaPlatformFee; 
        
        
         
         
         
        if(_referrer != address(0x0) && referrers[msg.sender] != address(0x0)){
            finaPlatformFee = distributeReferrerBonus(referrers[msg.sender], platformFee);
        }
        
         
         
        else if(_referrer == address(0x0) && referrers[msg.sender] != address(0x0)){
            finaPlatformFee = distributeReferrerBonus(referrers[msg.sender], platformFee);
        }
        
         
         
        else if(_referrer != address(0x0) && referrers[msg.sender] == address(0x0)){
            finaPlatformFee = distributeReferrerBonus(_referrer, platformFee);
             
            referrers[msg.sender]=_referrer;
        }
        
         
         
        else {
            finaPlatformFee = platformFee;
        }
        
         
        (bool success, ) =    theStocksTokenContract.call.value(finaPlatformFee).gas(53000)("");
        
         
        require(success, 'Ether transfer to DA Token contract failed');
        
         
        _tokens = _tokens.add(_value);
        
         
        balances[msg.sender] = balances[msg.sender].add(_value);
        
         
        emit FullEventLog(msg.sender, "buy", _sellprice, _sellprice.mul(100).div(90), now, _value, msg.value);
        
        _sellprice = _money.mul(10**15).mul(98).div(_tokens).div(100);
        
        
        emit Transfer(address(this), msg.sender, _value);
    }

     
    function sell (uint256 countTokens) public {
         
        require(balances[msg.sender] >= countTokens);
        
        uint _value = countTokens.mul(_sellprice).div(10**15);
        
        _money = _money.sub(_value);
        
        _tokens = _tokens.subsafe(countTokens);
        
        balances[msg.sender] = balances[msg.sender].subsafe(countTokens);
        
        emit FullEventLog(msg.sender, "sell", _sellprice, _sellprice.mul(100).div(90), now, countTokens, _value);
        
        if(_tokens > 0) {
            _sellprice = _money.mul(10**15).mul(98).div(_tokens).div(100);
        }

    	emit Transfer(msg.sender, address(this), countTokens);
        msg.sender.transfer(_value);
    }
     
    function getPrice() public view returns (uint bid, uint ask) {
        bid = _sellprice.mul(100).div(90);
        ask = _sellprice;
    }
}