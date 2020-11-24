 

pragma solidity 0.5.12;   


 
 
 
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


interface ERC20Essential 
{

    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);

}




 
 
 
    
contract owned {
    address public owner;
    address public newOwner;


    event OwnershipTransferred(uint256 curTime, address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function onlyOwnerTransferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract BitpayerDEX is owned {
  using SafeMath for uint256;
  bool public safeGuard;  
  address public feeAccount;  
  uint public tradingFee = 30;  
  
   
  uint256 public refPercent = 10;   
  
  mapping (address => mapping (address => uint)) public tokens;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint)) public orderFills;  
  
   
  mapping (address => address) public referrers;
   
  mapping (address => uint) public referrerBonusBalance;
  
  event Order(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires,  address user);
  event Cancel(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(uint256 curTime, address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(uint256 curTime, address token, address user, uint amount, uint balance);
  event Withdraw(uint256 curTime, address token, address user, uint amount, uint balance);
  event OwnerWithdrawTradingFee(address indexed owner, uint256 amount);
  
   
  event ReferrerBonus(address indexed referer, address indexed trader, uint256 referralBonus, uint256 timestamp );
  event ReferrerBonusWithdrawn(address indexed referrer, uint256 indexed amount);

  

    constructor() public {
        feeAccount = msg.sender;
    }

    function changeSafeguardStatus() onlyOwner public
    {
        if (safeGuard == false)
        {
            safeGuard = true;
        }
        else
        {
            safeGuard = false;    
        }
    }

     
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }  



    
   
   


  function changeFeeAccount(address feeAccount_) public onlyOwner {
    feeAccount = feeAccount_;
  }

  function changetradingFee(uint tradingFee_) public onlyOwner{
     
    tradingFee = tradingFee_;
  }
  
  function availableTradingFeeOwner() public view returns(uint256){
       
      return tokens[address(0)][feeAccount];
  }
  
  function withdrawTradingFeeOwner() public onlyOwner returns (string memory){
      uint256 amount = availableTradingFeeOwner();
      require (amount > 0, 'Nothing to withdraw');
      
      tokens[address(0)][feeAccount] = 0;
      
      msg.sender.transfer(amount);
      
      emit OwnerWithdrawTradingFee(owner, amount);
      
  }

  function deposit() public payable {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    emit Deposit(now, address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

  function withdraw(uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(tokens[address(0)][msg.sender] >= amount);
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(amount);
    msg.sender.transfer(amount);
    emit Withdraw(now, address(0), msg.sender, amount, tokens[address(0)][msg.sender]);
  }

  function depositToken(address token, uint amount) public {
     
    require(token!=address(0));
    require(ERC20Essential(token).transferFrom(msg.sender, address(this), amount));
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    emit Deposit(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }
	
  function withdrawToken(address token, uint amount) public {
    require(!safeGuard,"System Paused by Admin");
    require(token!=address(0));
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
	  ERC20Essential(token).transfer(msg.sender, amount);
    emit Withdraw(now, token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) public view returns (uint) {
    return tokens[token][user];
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires) public {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires));
    orders[msg.sender][hash] = true;
    emit Order(now, tokenGet, amountGet, tokenGive, amountGive, expires, msg.sender);
  }


     
  function trade(address[4] memory addressArray, uint amountGet, uint amountGive, uint expires, uint8 v, bytes32 r, bytes32 s, uint amount) public {
    require(!safeGuard,"System Paused by Admin");
     
    bytes32 hash = keccak256(abi.encodePacked(this, addressArray[0], amountGet, addressArray[1], amountGive, expires));
    require((
      (orders[addressArray[2]][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == addressArray[2]) &&
      block.number <= expires &&
      orderFills[addressArray[2]][hash].add(amount) <= amountGet
    ));
    tradeBalances(addressArray[0], amountGet, addressArray[1], amountGive, addressArray[2], amount, addressArray[3]);
    orderFills[addressArray[2]][hash] = orderFills[addressArray[2]][hash].add(amount);
    
    
    emit Trade(now, addressArray[0], amount, addressArray[1], amountGive * amount / amountGet, addressArray[2], msg.sender);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount, address referrer) internal {
    
    uint tradingFeeXfer = calculatePercentage(amount,tradingFee);
    
     
    processReferrerBonus(referrer, tradingFeeXfer);

    tokens[tokenGet][msg.sender] = tokens[tokenGet][msg.sender].sub(amount.add(tradingFeeXfer));
    tokens[tokenGet][user] = tokens[tokenGet][user].add(amount.sub(tradingFeeXfer));
    tokens[address(0)][feeAccount] = tokens[address(0)][feeAccount].add(tradingFeeXfer);

    tokens[tokenGive][user] = tokens[tokenGive][user].sub(amountGive.mul(amount) / amountGet);
    tokens[tokenGive][msg.sender] = tokens[tokenGive][msg.sender].add(amountGive.mul(amount) / amountGet);
  }
  
  

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) public view returns(bool) {
    
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user, uint8 v, bytes32 r, bytes32 s) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires));
    uint available1;
    if (!(
      (orders[user][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user) &&
      block.number <= expires
    )) return 0;
    available1 = tokens[tokenGive][user].mul(amountGet) / amountGive;
    
    if (amountGet.sub(orderFills[user][hash])<available1) return amountGet.sub(orderFills[user][hash]);
    return available1;
    
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, address user) public view returns(uint) {
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires));
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint8 v, bytes32 r, bytes32 s) public {
    require(!safeGuard,"System Paused by Admin");
    bytes32 hash = keccak256(abi.encodePacked(this, tokenGet, amountGet, tokenGive, amountGive, expires));
    require((orders[msg.sender][hash] || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == msg.sender));
    orderFills[msg.sender][hash] = amountGet;
    emit Cancel(now, tokenGet, amountGet, tokenGive, amountGive, expires, msg.sender, v, r, s);
  }



 
 
 

function processReferrerBonus(address _referrer, uint256 _tradingFeeLocal) internal {
      
      address existingReferrer = referrers[msg.sender];
      
      if(_referrer != address(0) && existingReferrer != address(0) ){
        referrerBonusBalance[existingReferrer] += _tradingFeeLocal * refPercent / 100;
        emit ReferrerBonus(_referrer, msg.sender, _tradingFeeLocal * refPercent / 100, now );
      }
      else if(_referrer != address(0) && existingReferrer == address(0) ){
         
        referrerBonusBalance[_referrer] += _tradingFeeLocal * refPercent / 100;
        referrers[msg.sender] = _referrer;
        emit ReferrerBonus(_referrer, msg.sender, _tradingFeeLocal * refPercent / 100, now );
      }
  }
  
  function changeRefPercent(uint256 newRefPercent) public onlyOwner returns (string memory){
      require(newRefPercent <= 100, 'newRefPercent can not be more than 100');
      refPercent = newRefPercent;
      return "refPool fee updated successfully";
  }
  
   
    function claimReferrerBonus() public returns(bool) {
        
        address payable msgSender = msg.sender;
        
        uint256 referralBonus = referrerBonusBalance[msgSender];
        
        require(referralBonus > 0, 'Insufficient referrer bonus');
        referrerBonusBalance[msgSender] = 0;
        
        
         
        msgSender.transfer(referralBonus);
        
         
        emit ReferrerBonusWithdrawn(msgSender, referralBonus);
        
        return true;
    }








}