 

 
pragma solidity ^0.4.24;
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract EIP20Interface {
     
     
    uint256 public totalSupply;
     
     
    function balanceOf(address _owner) public view returns (uint256 balance);
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     
     
     
     
    function approve(address _spender, uint256 _value) public returns(bool success);
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,uint256 _value);
}

contract DTI is EIP20Interface,Ownable,SafeMath,Pausable{
     
    string public constant name ="Diamond Travel International Coin";
    string public constant symbol = "DTI";
    uint8 public constant decimals = 18;
    string  public version  = 'v0.1';
    uint256 public initialSupply = 6000000000;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

     
    mapping (address => bool) public FreezeAccount;

     
    mapping (address => uint) public jail;
    mapping (address => uint256) public updateTime;
    
     
    mapping (address => uint256) public LockedToken;

     
    uint256 public finaliseTime;

     
    address public walletOwnerAddress;

     
    uint256 public rate;

    event WithDraw(address indexed _from, address indexed _to,uint256 _value);
    event BuyToken(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed _from,uint256 _value);

    constructor() public{
        totalSupply = initialSupply*10**uint256(decimals);                         
        balances[msg.sender] = totalSupply;             
        walletOwnerAddress = msg.sender;
        rate = 50000;
    }

    modifier notFinalised() {
        require(finaliseTime == 0);
        _;
    }

    modifier NotFreeze() { 
        require (FreezeAccount[msg.sender] == false); 
        _; 
    }

     
    function addFreeze(address _addr) public onlyOwner whenNotPaused returns(bool res) {
        FreezeAccount[_addr] = true;
        return true;
    }

     
    function releaseFreeze(address _addr) public onlyOwner whenNotPaused returns(bool res) {
        FreezeAccount[_addr] = false;
        return true;
    }
    
    function balanceOf(address _account) public view returns (uint) {
        return balances[_account];
    }

    function _transfer(address _from, address _to, uint _value) internal whenNotPaused returns(bool) {
        require(_to != address(0x0)&&_value>0);
        require (canTransfer(_from, _value));
        require(balances[_from] >= _value);
        require(safeAdd(balances[_to],_value) > balances[_to]);

        uint previousBalances = safeAdd(balances[_from],balances[_to]);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        emit Transfer(_from, _to, _value);
        assert(safeAdd(balances[_from],balances[_to]) == previousBalances);
        return true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused NotFreeze returns (bool success){
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused NotFreeze returns (bool) {
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender],_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused NotFreeze returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     function increaseApproval(address _spender, uint _addedValue) public whenNotPaused NotFreeze returns (bool) {
        allowances[msg.sender][_spender] = safeAdd(allowances[msg.sender][_spender],_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
  }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused NotFreeze returns (bool) {
            uint oldValue = allowances[msg.sender][_spender];
            if (_subtractedValue > oldValue) {
              allowances[msg.sender][_spender] = 0;
            } else {
              allowances[msg.sender][_spender] = safeSub(oldValue,_subtractedValue);
            }
            emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
            return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
 
     
    function setFinaliseTime() onlyOwner notFinalised public returns(bool){
        finaliseTime = now;
        rate = 0;
        return true;
    }
      
    function Restart(uint256 newrate) onlyOwner public returns(bool){
        finaliseTime = 0;
        rate = newrate;
        return true;
    }

    function setRate(uint256 newrate) onlyOwner notFinalised public returns(bool) {
       rate = newrate;
       return true;
    }

     
   function changeRate() internal returns(uint256 _rate) {
        if(now <= 1541865600 || rate <= 40000){
            return rate;
        }
        uint256 _day = safeSub(now,1541865600)/1 days;
        uint256 changerate = safeMul(_day,500);
        if(changerate >= 10000){
            rate = 40000;
        }else{
            rate = safeSub(rate,changerate);
        }
        return rate;
    }

    function setWalletOwnerAddress(address _newaddress) onlyOwner public returns(bool) {
       walletOwnerAddress = _newaddress;
       return true;
    }

     
    function withdraw(address _to) internal returns(bool){
        require(_to.send(address(this).balance));
        emit WithDraw(msg.sender,_to,this.balance);
        return true;
    }

     
    function burn(uint256 value) public whenNotPaused NotFreeze returns(bool){
        require (balances[msg.sender] >= value);
        totalSupply = safeSub(totalSupply,value);
        balances[msg.sender] = safeSub(balances[msg.sender],value);
        emit Burn(msg.sender,value);
        return true;
    }
    
     
    function burnFrom(address _account,uint256 value)onlyOwner public returns(bool){
        require (balances[_account] >= value);
        totalSupply = safeSub(totalSupply,value);
        balances[_account] = safeSub(balances[_account],value);
        emit Burn(_account,value);
        return true;
    }


     
    function canTransfer(address _from, uint256 _value) internal view returns (bool success) {
        uint256 index;  
        uint256 locked;
        index = safeSub(now, updateTime[_from]) / 1 days;

        if(index >= 200){
            return true;
        }
        uint256 releasedtemp = safeMul(index,jail[_from])/200;
        if(releasedtemp >= LockedToken[_from]){
            return true;
        }
        locked = safeSub(LockedToken[_from],releasedtemp);
        require(safeSub(balances[_from], _value) >= locked);
        return true;
    } 

    function _buyToken(address _to,uint256 _value)internal notFinalised whenNotPaused{
        require(_to != address(0x0));

        uint256 index;
        uint256 locked;
       
        if(updateTime[_to] != 0){
            
            index = safeSub(now,updateTime[_to])/1 days;

            uint256 releasedtemp = safeMul(index,jail[_to])/200;
            if(releasedtemp >= LockedToken[_to]){
                LockedToken[_to] = 0;
            }else{
                LockedToken[_to] = safeSub(LockedToken[_to],releasedtemp);
            }
        }
        locked = safeSub(_value,_value/200);
        LockedToken[_to] = safeAdd(LockedToken[_to],locked);
        balances[_to] = safeAdd(balances[_to], _value);
        jail[_to] = safeAdd(jail[_to], _value);
        balances[walletOwnerAddress] = safeSub(balances[walletOwnerAddress],_value);
        
        updateTime[_to] = now;
        withdraw(walletOwnerAddress);
        emit BuyToken(msg.sender, _to, _value);
    }

    function() public payable{
        require(msg.value >= 0.0001 ether);
        uint256 _rate = changeRate();
        uint256 tokens = safeMul(msg.value,_rate);
        _buyToken(msg.sender,tokens);
    }
}