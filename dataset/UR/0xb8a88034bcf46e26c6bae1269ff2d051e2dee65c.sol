 

pragma solidity ^0.4.18;

 
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

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping (address => Snapshot[]) balances;
    mapping (address => uint256) userWithdrawalBlocks;
	
     
    struct Snapshot {
      uint128 fromBlock;
      uint128 value;
    }
	
	 
    Snapshot[] totalSupplyHistory;
    
     
    Snapshot[] balanceForDividendsHistory;
	
	 
	function transfer(address to, uint256 value) public returns (bool) {
        return doTransfer(msg.sender, to, value);
	}
	
	 
	function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
	   if (_amount == 0) {
		   return true;
	   }
     
	    
	   require((_to != 0) && (_to != address(this)));

	    
	    
	   var previousBalanceFrom = balanceOfAt(_from, block.number);
	   if (previousBalanceFrom < _amount) {
		   return false;
	   }

	    
	    
	   updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

	    
	    
	   var previousBalanceTo = balanceOfAt(_to, block.number);
	   require(previousBalanceTo + _amount >= previousBalanceTo);  
	   updateValueAtNow(balances[_to], previousBalanceTo + _amount);

	    
	   Transfer(_from, _to, _amount);

	   return true;
    }
    
	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balanceOfAt(_owner, block.number);
	}

     
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {
         
         
        if ((balances[_owner].length == 0)|| (balances[_owner][0].fromBlock > _blockNumber)) {
			return 0; 
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
         
         
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
			return 0;
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

     
    function getValueAt(Snapshot[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

      
    function updateValueAtNow(Snapshot[] storage checkpoints, uint _value) internal  {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
           Snapshot storage newCheckPoint = checkpoints[ checkpoints.length++ ];
           newCheckPoint.fromBlock =  uint128(block.number);
           newCheckPoint.value = uint128(_value);
        } else {
           Snapshot storage oldCheckPoint = checkpoints[checkpoints.length-1];
           oldCheckPoint.value = uint128(_value);
        }
    }
	
     
    function redeemedSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }
}

contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	  return doTransfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  
  bool public mintingFinished = false;

  string public name = "Honey Mining Token";		
  string public symbol = "HMT";		
  uint8 public decimals = 8;		

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) public canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
	uint curTotalSupply = redeemedSupply();
	require(curTotalSupply + _amount >= curTotalSupply);  
	uint previousBalanceTo = balanceOf(_to);
	require(previousBalanceTo + _amount >= previousBalanceTo);  
	updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_to], previousBalanceTo + _amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
  
   
  function recordDeposit(uint256 _amount) public {
	 updateValueAtNow(balanceForDividendsHistory, _amount);
  }
  
   
  function finishMinting() public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
   
  function awailableDividends(address userAddress) public view returns (uint256) {
      uint256 userLastWithdrawalBlock = userWithdrawalBlocks[userAddress];
      uint256 amountForWithdraw = 0;
      for(uint i = 0; i<=balanceForDividendsHistory.length-1; i++){
          Snapshot storage snapshot = balanceForDividendsHistory[i];
          if(userLastWithdrawalBlock < snapshot.fromBlock)
            amountForWithdraw = amountForWithdraw.add(balanceOfAt(userAddress, snapshot.fromBlock).mul(snapshot.value).div(totalSupplyAt(snapshot.fromBlock)));
      }
      return amountForWithdraw;
  }
  
   
  function recordWithdraw(address userAddress) public {
    userWithdrawalBlocks[userAddress] = balanceForDividendsHistory[balanceForDividendsHistory.length-1].fromBlock;
  }
}

contract HoneyMiningToken is Ownable {
    
  using SafeMath for uint256;

  MintableToken public token;
   
  uint256 public maxSupply = 300000000000000;
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
   
  event ReferralBonus(address indexed purchaser, address indexed beneficiary, uint amount);
  
    
  event DepositForDividends(uint256 indexed amount);
  
   
  event WithdrawDividends(address indexed holder, uint256 amount);

   
  event DevReward(address purchaser, uint amount);

  function HoneyMiningToken() public {
    token = new MintableToken();
  }

   
  function () public payable {buyTokens(0x0);}

   
  function buyTokens(address referrer) public payable {
    require(msg.sender != 0x0);
    require(msg.sender != referrer);
    require(validPurchase());
    
     
    uint256 amount = msg.value.div(10000000000);
    
     
    uint256 tokens = amount.mul(rate());
    require(tokens >= 100000000);
    uint256 devTokens = tokens.mul(30).div(100);
    if(referrer != 0x0){
       require(token.balanceOf(referrer) >= 100000000);
        
       uint256 refTokens = tokens.mul(25).div(1000);
        
       require(maxSupply.sub(redeemedSupply()) >= tokens.add(refTokens.mul(2)).add(devTokens));
       
        
       token.mint(msg.sender, tokens.add(refTokens));
       TokenPurchase(msg.sender, msg.sender, amount, tokens.add(refTokens));
       token.mint(referrer, refTokens);
       ReferralBonus(msg.sender, referrer, refTokens);
       
    } else{
        require(maxSupply.sub(redeemedSupply())>=tokens.add(devTokens));
         
        
         
        token.mint(msg.sender, tokens);
    
         
        TokenPurchase(msg.sender, msg.sender, amount, tokens);
    }
    token.mint(owner, devTokens);
    DevReward(msg.sender, devTokens);
    forwardFunds();
  }

   
  function validPurchase() internal constant returns (bool) {
    return !hasEnded() && msg.value != 0;
  }

   
  function hasEnded() public constant returns (bool) {
    return maxSupply <= redeemedSupply();
  }
  
   
  function checkBalance(address userAddress) public constant returns (uint){
      return token.balanceOf(userAddress);
  }
  
   
  function checkBalanceAt(address userAddress, uint256 targetBlock) public constant returns (uint){
      return token.balanceOfAt(userAddress, targetBlock);
  }
  
   
  function awailableDividends(address userAddress) public constant returns (uint){
    return token.awailableDividends(userAddress);
  }
  
   
  function redeemedSupply() public view returns (uint){
    return token.totalSupply();
  }
  
   
  function withdrawDividends() public {
    uint _amount = awailableDividends(msg.sender);
    require(_amount > 0);
    msg.sender.transfer(_amount);
    token.recordWithdraw(msg.sender);
    WithdrawDividends(msg.sender, _amount);
  }
  
   
  function depositForDividends() public payable onlyOwner {
      require(msg.value > 0);
      token.recordDeposit(msg.value);
      DepositForDividends(msg.value);
  }
  
  function stopSales() public onlyOwner{
   maxSupply = token.totalSupply();
  }
   
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }
  
  function rate() internal constant returns (uint) {
    if(redeemedSupply() < 1000000000000)
        return 675;
    else if (redeemedSupply() < 5000000000000)
        return 563;
    else
        return 450;
  }
}