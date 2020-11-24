 

pragma solidity ^ 0.4.19;
 
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    function Ownable()public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner)public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 
library SafeMath {
    function mul(uint256 a, uint256 b)internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b)internal pure returns(uint256) {
        assert(b > 0);  
        uint256 c = a / b;
         
        return c;
    }
    function sub(uint256 a, uint256 b)internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b)internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 
contract Pausable is Destructible {
    event Pause();
    event Unpause();
    bool public paused = false;
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
     
    modifier whenPaused() {
        require(paused);
        _;
    }
     
    function pause()onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
     
    function unpause()onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    uint256 public completeRemainingTokens;
    function balanceOf(address who)public view returns(uint256);
    function transfer(address to, uint256 value)public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract BasicToken is ERC20Basic,
Pausable {
    uint256 startPreSale; uint256 endPreSale; uint256 startSale; 
    uint256 endSale; 
    using SafeMath for uint256; mapping(address => uint256)balances; uint256 preICOReserveTokens; uint256 icoReserveTokens; 
    address businessReserveAddress; uint256 public timeLock = 1586217600;  
    uint256 public incentiveTokensLimit;
    modifier checkAdditionalTokenLock(uint256 value) {

        if (msg.sender == businessReserveAddress) {
            
            if ((now<endSale) ||(now < timeLock &&value>incentiveTokensLimit)) {
                revert();
            } else {
                _;
            }
        } else {
            _;
        }

    }
    
    function updateTimeLock(uint256 _timeLock) external onlyOwner {
        timeLock = _timeLock;
    }
    function updateBusinessReserveAddress(address _businessAddress) external onlyOwner {
        businessReserveAddress =_businessAddress;
    }
    
    function updateIncentiveTokenLimit(uint256 _incentiveTokens) external onlyOwner {
      incentiveTokensLimit = _incentiveTokens;
   }    
     
    function transfer(address _to, uint256 _value)public whenNotPaused checkAdditionalTokenLock(_value) returns(
        bool
    ) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner)public constant returns(uint256 balance) {
        return balances[_owner];
    }
}
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)public view returns(uint256);
    function transferFrom(address from, address to, uint256 value)public returns(
        bool
    );
    function approve(address spender, uint256 value)public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn()public {
        uint256 _value = balances[msg.sender];
         
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract StandardToken is ERC20,BurnableToken {
    mapping(address => mapping(address => uint256))internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value)public whenNotPaused checkAdditionalTokenLock(_value) returns(
        bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value)public checkAdditionalTokenLock(_value) returns(
        bool
    ) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender)public constant returns(
        uint256 remaining
    ) {
        return allowed[_owner][_spender];
    }
     
    function increaseApproval(address _spender, uint _addedValue)public checkAdditionalTokenLock(_addedValue) returns(
        bool success
    ) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue)public returns(
        bool success
    ) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}
contract SMRTCoin is StandardToken {
    string public constant name = "SMRT";
    uint public constant decimals = 18;
    string public constant symbol = "SMRT";
    using SafeMath for uint256; uint256 public weiRaised = 0; address depositWalletAddress; 
    event Buy(address _from, uint256 _ethInWei, string userId); 
    
    function SMRTCoin()public {
        owner = msg.sender;
        totalSupply = 600000000 * (10 ** decimals);
        preICOReserveTokens = 90000000 * (10 ** decimals);
        icoReserveTokens = 210000000 * (10 ** decimals);
        depositWalletAddress = 0x85a98805C17701504C252eAAB99f60C7c204A785;  
        businessReserveAddress = 0x73FEC20272a555Af1AEA4bF27D406683632c2a8c; 
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
        startPreSale = now;  
        endPreSale = 1524319200;  
        startSale = endPreSale + 1;
        endSale = startSale + 30 days;
    }
    function ()public {
        revert();
    }
     
    function buy(string userId)public payable whenNotPaused {
        require(msg.value > 0);
        require(msg.sender != address(0));
        weiRaised += msg.value;
        forwardFunds();
        emit Buy(msg.sender, msg.value, userId);
    }
     
    function getBonustokens(uint256 tokens)internal returns(uint256 bonusTokens) {
        require(now <= endSale);
        uint256 bonus;
        if (now <= endPreSale) {
            bonus = 50;
        } else if (now < startSale + 1 weeks) {
            bonus = 10;
        } else if (now < startSale + 2 weeks) {
            bonus = 5;
        }

        bonusTokens = ((tokens / 100) * bonus);
    }
    function CrowdSale(address recieverAddress, uint256 tokens)public onlyOwner {
        tokens =  tokens.add(getBonustokens(tokens));
        uint256 tokenLimit = (tokens.mul(20)).div(100);  
        incentiveTokensLimit  = incentiveTokensLimit.add(tokenLimit);
        if (now <= endPreSale && preICOReserveTokens >= tokens) {
            preICOReserveTokens = preICOReserveTokens.sub(tokens);
            transfer(businessReserveAddress, tokens);
            transfer(recieverAddress, tokens);
        } else if (now < endSale && icoReserveTokens >= tokens) {
            icoReserveTokens = icoReserveTokens.sub(tokens);
            transfer(businessReserveAddress, tokens);
            transfer(recieverAddress, tokens);
        }
        else{ 
            revert();
        }
    }
     
    function forwardFunds()internal {
        depositWalletAddress.transfer(msg.value);
    }
    function changeDepositWalletAddress(address newDepositWalletAddr)external onlyOwner {
        require(newDepositWalletAddr != 0);
        depositWalletAddress = newDepositWalletAddr;
    }
    function updateSaleTime(uint256 _startSale, uint256 _endSale)external onlyOwner {
        startSale = _startSale;
        endSale = _endSale;
    }

 

}