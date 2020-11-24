 

pragma solidity ^0.4.21;

 
library SafeMath {
 
  function Mul(uint a, uint b) internal pure returns (uint) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function Div(uint a, uint b) internal pure returns (uint) {
     
    uint256 c = a / b;
     
    return c;
  }

  function Sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  } 

  function Add(uint a, uint b) internal pure returns (uint) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  } 
}

 
contract ERC223ReceivingContract { 
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract Ownable {

   
  address public owner;
   
  address deployer;

   
  function Ownable() public {
    owner = msg.sender;
    deployer = msg.sender;
  }

   
  modifier onlyOwner() {
    require (msg.sender == owner || msg.sender == deployer);
      _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require (_newOwner != address(0));
    owner = _newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  uint256 public startTime;
  uint256 public endTime;
  uint256 private pauseTime;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
     
     
    if(startTime > 0){
        pauseTime = now;
    }
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
     
    if(endTime > 0 && pauseTime > startTime){
        uint256 pauseDuration = pauseTime - startTime;
        endTime = endTime + pauseDuration;
    }
    emit Unpause();
  }
}

 
contract ERC20 is Pausable {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public view returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

contract ECHO is ERC20 {

    using SafeMath for uint256;
     
    string public constant name = "ECHO token";
     
    string public constant symbol = "ECHO";
     
    bool public locked;
     
    uint8 public constant decimals = 18;
     
    uint256 public constant PRICE=4000;
     
    uint256 constant MAXCAP = 322500000e18;
     
    uint256 constant HARD_CAP = 8e7*1e18;
     
    address ethCollector;
     
    uint256 public totalWeiReceived;
     
    uint256 public saleType;
    

     
    mapping(address => mapping(address => uint256)) allowed;
     
    mapping(address => uint256) balances;
    
    function isSaleRunning() public view returns (bool){
        bool status = false;
         
         
         
         
        
         
        if(now >= startTime  && now <= 1525392000){
             
            status = true;
        }
    
         
        if(now >= 1527811200 && now <= endTime){
             
            status = true;
        }
        return status;
    }

    function countDownToEndCrowdsale() public view returns(uint256){
        assert(isSaleRunning());
        return endTime.Sub(now);
    }
     
    event StateChanged(bool);

    function ECHO() public{
        totalSupply = 0;
        startTime = 1522972800;  
        endTime = 1531094400;  
        locked = true;
        setEthCollector(0xc8522E0444a94Ec9a5A08242765e1196DF1EC6B5);
    }
     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier onlyUnlocked() { 
        require (!locked); 
        _; 
    }

    modifier validTimeframe(){
        require(isSaleRunning());
        _;
    }
    
    function setEthCollector(address _ethCollector) public onlyOwner{
        require(_ethCollector != address(0));
        ethCollector = _ethCollector;
    }

     
    function unlockTransfer() external onlyOwner{
        locked = false;
    }

     
    function isContract(address _address) private view returns(bool _isContract){
        assert(_address != address(0) );
        uint length;
         
        assembly{
            length := extcodesize(_address)
        }
        if(length > 0){
            return true;
        }
        else{
            return false;
        }
    }

     
    function balanceOf(address _owner) public view returns (uint256 _value){
        return balances[_owner];
    }

     
    function transfer(address _to, uint _value) onlyUnlocked onlyPayloadSize(2 * 32) public returns(bool _success) {
        require( _to != address(0) );
        bytes memory _empty;
        assert((balances[msg.sender] >= _value) && _value > 0 && _to != address(0));
        balances[msg.sender] = balances[msg.sender].Sub(_value);
        balances[_to] = balances[_to].Add(_value);
        if(isContract(_to)){
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint _value, bytes _data) onlyUnlocked onlyPayloadSize(3 * 32) public returns(bool _success) {
        assert((balances[msg.sender] >= _value) && _value > 0 && _to != address(0));
        balances[msg.sender] = balances[msg.sender].Sub(_value);
        balances[_to] = balances[_to].Add(_value);
        if(isContract(_to)){
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3*32) public onlyUnlocked returns (bool){
        bytes memory _empty;
        assert((_value > 0)
           && (_to != address(0))
           && (_from != address(0))
           && (allowed[_from][msg.sender] >= _value ));
       balances[_from] = balances[_from].Sub(_value);
       balances[_to] = balances[_to].Add(_value);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].Sub(_value);
       if(isContract(_to)){
           ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
           receiver.tokenFallback(msg.sender, _value, _empty);
       }
       emit Transfer(_from, _to, _value);
       return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool){
        if( _value > 0 && (balances[msg.sender] >= _value)){
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        else{
            return false;
        }
    }

    function mintAndTransfer(address beneficiary, uint256 tokensToBeTransferred) public validTimeframe onlyOwner {
        require(totalSupply.Add(tokensToBeTransferred) <= MAXCAP);
        totalSupply = totalSupply.Add(tokensToBeTransferred);
        balances[beneficiary] = balances[beneficiary].Add(tokensToBeTransferred);
        emit Transfer(0x0, beneficiary ,tokensToBeTransferred);
    }

    function getBonus(uint256 _tokensBought)public view returns(uint256){
        uint256 bonus = 0;
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        if(saleType == 1){
             
            if(now >= 1522972800 && now < 1523664000){
                 
                bonus = _tokensBought*20/100;
            }
            else if(now >= 1523664000 && now < 1524355200){
                 
                bonus = _tokensBought*10/100;
            }
            else if(now >= 1524355200 && now < 1525392000){
                 
                bonus = _tokensBought*5/100;
            }
        }
        if(saleType == 2){
             
            if(now >= 1527811200 && now < 1528588800){
                 
                bonus = _tokensBought*20/100;
            }
            else if(now >= 1528588800 && now < 1529280000){
                 
                bonus = _tokensBought*10/100;
            }
            else if(now >= 1529280000 && now < 1530403200){
                 
                bonus = _tokensBought*5/100;
            }
        }
        return bonus;
    }
    function buyTokens(address beneficiary) internal validTimeframe {
        uint256 tokensBought = msg.value.Mul(PRICE);
        tokensBought = tokensBought.Add(getBonus(tokensBought));
        balances[beneficiary] = balances[beneficiary].Add(tokensBought);
        totalSupply = totalSupply.Add(tokensBought);
       
        assert(totalSupply <= HARD_CAP);
        totalWeiReceived = totalWeiReceived.Add(msg.value);
        ethCollector.transfer(msg.value);
        emit Transfer(0x0, beneficiary, tokensBought);
    }

     
    function finalize() public onlyUnlocked onlyOwner {
         
         
        assert(!isSaleRunning() || (HARD_CAP.Sub(totalSupply)) <= 1e18);
        endTime = now;

         
        locked = false;
         
        emit StateChanged(true);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

     
    function drain() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}