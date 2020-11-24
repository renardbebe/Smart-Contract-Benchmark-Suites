 

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

contract ERC20Interface {
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
   
contract Token is ERC20Interface {
    
    using SafeMath for uint;
    
    string public constant symbol = "LNC";
    string public constant name = "Linker Coin";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 500000000000000000000000000;
    
     
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
  
     
     
    address public owner;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function IsFreezedAccount(address _addr) public constant returns (bool) {
        return frozenAccount[_addr];
    }

     
    function Token() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256 supply) {
        supply = _totalSupply;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        if (_to != 0x0   
            && IsFreezedAccount(msg.sender) == false
            && balances[msg.sender] >= _value 
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(address _from,address _to, uint256 _value) public returns (bool success) {
        if (_to != 0x0   
            && IsFreezedAccount(_from) == false
            && balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

      
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function FreezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
}
 
contract MyToken is Token {
    
     
    
    uint8 public constant decimalOfPrice = 10;   
    uint256 public constant multiplierOfPrice = 10000000000;
    uint256 public constant multiplier = 1000000000000000000;
    uint256 public lpAskPrice = 100000000000;  
    uint256 public lpBidPrice = 1;  
    uint256 public lpAskVolume = 0;  
    uint256 public lpBidVolume = 0;  
    uint256 public lpMaxVolume = 1000000000000000000000000;  
    
     
    uint256 public edgePerPosition = 1;  
    uint256 public lpTargetPosition;
    uint256 public lpFeeBp = 10;  
    
    bool public isLpStart = false;
    bool public isBurn = false;
    
    function MyToken() public {
        balances[msg.sender] = _totalSupply;
        lpTargetPosition = 200000000000000000000000000;
    }
    
    event Burn(address indexed from, uint256 value);
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        if (isBurn == true)
        {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            _totalSupply = _totalSupply.sub(_value);
            Burn(msg.sender, _value);
            return true;
        }
        else{
            return false;
        }
    }
    
    event SetBurnStart(bool _isBurnStart);
    function setBurnStart(bool _isBurnStart) onlyOwner public {
        isBurn = _isBurnStart;
    }

     
    event SetPrices(uint256 _lpBidPrice, uint256 _lpAskPrice, uint256 _lpBidVolume, uint256 _lpAskVolume);
    function setPrices(uint256 _lpBidPrice, uint256 _lpAskPrice, uint256 _lpBidVolume, uint256 _lpAskVolume) onlyOwner public{
        require(_lpBidPrice < _lpAskPrice);
        require(_lpBidVolume <= lpMaxVolume);
        require(_lpAskVolume <= lpMaxVolume);
        lpBidPrice = _lpBidPrice;
        lpAskPrice = _lpAskPrice;
        lpBidVolume = _lpBidVolume;
        lpAskVolume = _lpAskVolume;
        SetPrices(_lpBidPrice, _lpAskPrice, _lpBidVolume, _lpAskVolume);
    }
    
    event SetLpMaxVolume(uint256 _lpMaxVolume);
    function setLpMaxVolume(uint256 _lpMaxVolume) onlyOwner public {
        require(_lpMaxVolume < 1000000000000000000000000);
        lpMaxVolume = _lpMaxVolume;
        if (lpMaxVolume < lpBidVolume){
            lpBidVolume = lpMaxVolume;
        }
        if (lpMaxVolume < lpAskVolume){
            lpAskVolume = lpMaxVolume;
        }
        SetLpMaxVolume(_lpMaxVolume);
    }
    
    event SetEdgePerPosition(uint256 _edgePerPosition);
    function setEdgePerPosition(uint256 _edgePerPosition) onlyOwner public {
         
        edgePerPosition = _edgePerPosition;
        SetEdgePerPosition(_edgePerPosition);
    }
    
    event SetLPTargetPostion(uint256 _lpTargetPositionn);
    function setLPTargetPostion(uint256 _lpTargetPosition) onlyOwner public {
        require(_lpTargetPosition <totalSupply() );
        lpTargetPosition = _lpTargetPosition;
        SetLPTargetPostion(_lpTargetPosition);
    }
    
    event SetLpFee(uint256 _lpFeeBp);
    function setLpFee(uint256 _lpFeeBp) onlyOwner public {
        require(_lpFeeBp <= 100);
        lpFeeBp = _lpFeeBp;
        SetLpFee(lpFeeBp);
    }
    
    event SetLpIsStart(bool _isLpStart);
    function setLpIsStart(bool _isLpStart) onlyOwner public {
        isLpStart = _isLpStart;
    }
    
    function getLpBidPrice()public constant returns (uint256)
    { 
        uint256 lpPosition = balanceOf(owner);
            
        if (lpTargetPosition >= lpPosition)
        {
            return lpBidPrice;
        }
        else
        {
            return lpBidPrice.sub((((lpPosition.sub(lpTargetPosition)).div(multiplier)).mul(edgePerPosition)).div(multiplierOfPrice));
        }
    }
    
    function getLpAskPrice()public constant returns (uint256)
    {
        uint256 lpPosition = balanceOf(owner);
            
        if (lpTargetPosition <= lpPosition)
        {
            return lpAskPrice;
        }
        else
        {
            return lpAskPrice.add((((lpTargetPosition.sub(lpPosition)).div(multiplier)).mul(edgePerPosition)).div(multiplierOfPrice));
        }
    }
    
    function getLpIsWorking(int minSpeadBp) public constant returns (bool )
    {
        if (isLpStart == false)
            return false;
         
        if (lpAskVolume == 0 || lpBidVolume == 0)
        {
            return false;
        }
        
        int256 bidPrice = int256(getLpBidPrice());
        int256 askPrice = int256(getLpAskPrice());
        
        if (askPrice - bidPrice > minSpeadBp * (bidPrice + askPrice) / 2 / 10000)
        {
            return false;
        }
        
        return true;
    }
    
    function getAmountOfLinkerBuy(uint256 etherAmountOfSell) public constant returns (uint256)
    {
        return ((( multiplierOfPrice.mul(etherAmountOfSell) ).div(getLpAskPrice())).mul(uint256(10000).sub(lpFeeBp))).div(uint256(10000));
    }
    
    function getAmountOfEtherSell(uint256 linkerAmountOfBuy) public constant returns (uint256)
    {
        return (((getLpBidPrice().mul(linkerAmountOfBuy)).div(multiplierOfPrice)).mul(uint256(10000).sub(lpFeeBp))).div(uint256(10000));
    }
    
    function () public payable {
    }
    
    function buy() public payable returns (uint256){
        require (getLpIsWorking(500));                       
        uint256 amount = getAmountOfLinkerBuy(msg.value);    
        require(balances[owner] >= amount);                   
        balances[msg.sender] = balances[msg.sender].add(amount);                      
        balances[owner] = balances[owner].sub(amount);                            
        lpAskVolume = lpAskVolume.sub(amount);
        Transfer(owner, msg.sender, amount);                  
        return amount;                                    
    }
    
    function sell(uint256 amount)public returns (uint256) {    
        require (getLpIsWorking(500));
        require (balances[msg.sender] >= amount);            
        balances[owner] = balances[owner].add(amount);                            
        balances[msg.sender] = balances[msg.sender].sub(amount);                      
        lpBidVolume = lpBidVolume.sub(amount);
        uint256 linkerSendAmount = getAmountOfEtherSell(amount);
        
        msg.sender.transfer(linkerSendAmount);          
        Transfer(msg.sender, this, linkerSendAmount);        
        return linkerSendAmount;                                    
    }
    
    function transferEther(uint256 amount) onlyOwner public{
        msg.sender.transfer(amount);
        Transfer(msg.sender, this, amount);
    }
}

contract LNC_Manager is Token
{
    function MultiTransfer(address _tokenAddr, address[] dests, uint256[] values) onlyOwner public returns (bool)
    {
        uint256 i = 0;
        Token T = Token(_tokenAddr);
        bool isMissed = false;
        while (i < dests.length) {
            T.transfer(dests[i], values[i]);
            
            i += 1;
        }
        return(isMissed);
    }
    
    function IsMultiFreeze(address _tokenAddr, address[] dests, bool isFreeze) public view returns (uint256)
    {
        uint256 i = 0;
        uint256 n = 0;
         
        uint256 unfreezedAddress = 0;
        Token T = Token(_tokenAddr);
        while (i < dests.length && n < 20) 
        {
            if (T.IsFreezedAccount(dests[i]) == isFreeze)
            {
                unfreezedAddress = unfreezedAddress * 1000 + i + 1;
                n += 1;
            }
            i += 1;
        }
        
        return(unfreezedAddress); 
    }
    
     
}