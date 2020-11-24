 

pragma solidity ^0.4.21;
  

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract StandardToken is Ownable{
    
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;
  
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  
  
  event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
    );

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }


  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract PausableToken is StandardToken{

  event TokensAreLocked(address _from, uint256 _timeout);
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused = false; 
  mapping (address => uint256) lockups;

  

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  modifier ifNotLocked(address _from){
        if (lockups[_from] != 0) {
            require(now >= lockups[_from]);
        }
        _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
    

    
  
 function lockTokens(address[] _holders, uint256[] _timeouts) public onlyOwner {
     require(_holders.length == _timeouts.length);
     require(_holders.length < 255);

     for (uint8 i = 0; i < _holders.length; i++) {
        address holder = _holders[i];
        uint256 timeout = _timeouts[i];

         
        require(lockups[holder] == 0);

        lockups[holder] = timeout;
        emit TokensAreLocked(holder, timeout);
     }
 }


  function transfer(address _to, uint256 _value) public whenNotPaused ifNotLocked(msg.sender)  returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from,address _to,uint256 _value)public whenNotPaused ifNotLocked(_from) returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }


  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
}

 
contract BurnableToken is StandardToken{

  event Burn(address indexed burner, uint256 value);
    
     
    function burnFrom(address _from, uint256 _value) public onlyOwner{
    
        require(_value <= balances[_from]);
         
         
        
        balances[_from] = balances[_from].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
    }
}

 
contract MintableToken is StandardToken{
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner());
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    require(_to != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract DividendPayingToken is PausableToken, BurnableToken, MintableToken{
    
    event PayedDividendEther(address receiver, uint256 amount);
    event PayedDividendFromReserve(address receiver, uint256 amount);
    
    uint256 EligibilityThreshold;
    
    address TokenReserveAddress;
    
    
    modifier isEligible(address _receiver){
        balanceOf(_receiver) >= EligibilityThreshold;
        _;
    }
    
    function setEligibilityThreshold(uint256 _value) public onlyOwner returns(bool) {
        EligibilityThreshold = _value;
        return true;
    }
    
    function setTokenReserveAddress(address _newAddress) public onlyOwner returns(bool) {
        TokenReserveAddress = _newAddress;
        return true;
    }
    
    function approvePayoutFromReserve(uint256 _value) public onlyOwner returns(bool) {
        allowed[TokenReserveAddress][msg.sender] = _value;
        emit Approval(TokenReserveAddress,msg.sender, _value);
        return true;
    }
    
    function payDividentFromReserve(address _to, uint256 _amount) public onlyOwner isEligible(_to) returns(bool){
        emit PayedDividendFromReserve(_to, _amount);
        return transferFrom(TokenReserveAddress,_to, _amount);
    } 
    
    function payDividendInEther(address _to, uint256 _amount) public onlyOwner isEligible(_to) returns(bool){
        require(address(this).balance >= _amount );
        _to.transfer(_amount);
        emit PayedDividendEther(_to, _amount);
        return true;
    }
    
    function depositEtherForDividends(uint256 _amount) public payable onlyOwner returns(bool){
        require(msg.value == _amount);
        return true;
    }
    
    function withdrawEther(uint256 _amount) public onlyOwner returns(bool){
        require(address(this).balance >= _amount );
        owner().transfer(_amount);
        return true;
    }
    
    
    
}

contract SET is DividendPayingToken{
    
    string public name = "Securosys";
    string public symbol = "SET";
    uint8 public decimals = 18;
}