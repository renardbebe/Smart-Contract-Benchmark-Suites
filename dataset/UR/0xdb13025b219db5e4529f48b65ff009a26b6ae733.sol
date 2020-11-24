 

pragma solidity ^0.4.25;

 
interface IERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner=0xE2d9b8259F74a46b5E3f74A30c7867be0a5f5185;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
 constructor() internal {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
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
 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}
contract Haltable is Ownable  {
    
  bool public halted;
  
   modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}
contract Ubricoin is IERC20,Ownable,ReentrancyGuard,Haltable{
  
  using SafeMath for uint256;

   
  string public name = 'Ubricoin';
  string public symbol = 'UBN';
  string public version = '2.0';
  uint256 public constant RATE = 1000;   
  
   
  uint256 public constant MIN_HOLDER_TOKENS = 10 ** uint256(decimals - 1);
  
   
  uint8   public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
  uint256 public totalSupply_;            
  uint256 public constant TOTAL_SUPPLY = 10000000000 * decimalFactor;  
  uint256 public constant SALES_SUPPLY =  1300000000 * decimalFactor;  
  
   
  uint256 public AVAILABLE_FOUNDER_SUPPLY  =  1500000000 * decimalFactor;  
  uint256 public AVAILABLE_AIRDROP_SUPPLY  =  2000000000 * decimalFactor;  
  uint256 public AVAILABLE_OWNER_SUPPLY    =  2000000000 * decimalFactor;  
  uint256 public AVAILABLE_TEAMS_SUPPLY    =  3000000000 * decimalFactor;  
  uint256 public AVAILABLE_BONUS_SUPPLY    =   200000000 * decimalFactor;  
  uint256 public claimedTokens = 0;
  
   
  address public constant AVAILABLE_FOUNDER_SUPPLY_ADDRESS = 0xAC762012330350DDd97Cc64B133536F8E32193a8;  
  address public constant AVAILABLE_AIRDROP_SUPPLY_ADDRESS = 0x28970854Bfa61C0d6fE56Cc9daAAe5271CEaEC09;  
  address public constant AVAILABLE_OWNER_SUPPLY_ADDRESS = 0xE2d9b8259F74a46b5E3f74A30c7867be0a5f5185;    
  address public constant AVAILABLE_BONUS_SUPPLY_ADDRESS = 0xDE59297Bf5D1D1b9d38D8F50e55A270eb9aE136e;    
  address public constant AVAILABLE_TEAMS_SUPPLY_ADDRESS = 0x9888375f4663891770DaaaF9286d97d44FeFC82E;    

   
  address[] public holders;
  

   
  address public icoAddress;
  mapping (address => uint256) balances;   
  mapping (address => mapping (address => uint256)) internal allowed;
  
   
  mapping (address => bool) public airdrops;
  
  mapping (address => uint256) public holderNumber;  
  
   
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);
   
  event Burn(address from, uint256 value); 
  event AirDropped ( address[] _recipient, uint256 _amount, uint256 claimedTokens);
  event AirDrop_many ( address[] _recipient, uint256[] _amount, uint256 claimedTokens);
  
 
     
  constructor () public  { 
      
         
        balances[AVAILABLE_FOUNDER_SUPPLY_ADDRESS] = AVAILABLE_FOUNDER_SUPPLY;
        holders.push(AVAILABLE_FOUNDER_SUPPLY_ADDRESS);
        emit Transfer(0x0, AVAILABLE_FOUNDER_SUPPLY_ADDRESS, AVAILABLE_FOUNDER_SUPPLY);

         
        balances[AVAILABLE_AIRDROP_SUPPLY_ADDRESS] = AVAILABLE_AIRDROP_SUPPLY;
        holders.push(AVAILABLE_AIRDROP_SUPPLY_ADDRESS);
        emit Transfer(0x0, AVAILABLE_AIRDROP_SUPPLY_ADDRESS, AVAILABLE_AIRDROP_SUPPLY);

         
        balances[AVAILABLE_OWNER_SUPPLY_ADDRESS] = AVAILABLE_OWNER_SUPPLY;
        holders.push(AVAILABLE_OWNER_SUPPLY_ADDRESS);
        emit Transfer(0x0, AVAILABLE_OWNER_SUPPLY_ADDRESS, AVAILABLE_OWNER_SUPPLY);

         
        balances[AVAILABLE_TEAMS_SUPPLY_ADDRESS] = AVAILABLE_TEAMS_SUPPLY;
        holders.push(AVAILABLE_TEAMS_SUPPLY_ADDRESS);
        emit Transfer(0x0, AVAILABLE_TEAMS_SUPPLY_ADDRESS, AVAILABLE_TEAMS_SUPPLY);
        
         
        balances[AVAILABLE_BONUS_SUPPLY_ADDRESS] = AVAILABLE_BONUS_SUPPLY;
        holders.push(AVAILABLE_BONUS_SUPPLY_ADDRESS);
        emit Transfer(0x0, AVAILABLE_BONUS_SUPPLY_ADDRESS, AVAILABLE_BONUS_SUPPLY);

        totalSupply_ = TOTAL_SUPPLY.sub(SALES_SUPPLY);
        
    }
    
    
  function () payable nonReentrant external  {
      
    require(msg.data.length == 0);
    require(msg.value > 0);
    
      uint256 tokens = msg.value.mul(RATE);  
      balances[msg.sender] = balances[msg.sender].add(tokens);
      totalSupply_ = totalSupply_.add(tokens);
      owner.transfer(msg.value);   
      
    }

     
  function setICO(address _icoAddress) public onlyOwner {
      
    require(_icoAddress != address(0));
    require(icoAddress  == address(0));
    require(totalSupply_ == TOTAL_SUPPLY.sub(SALES_SUPPLY));
      
        
       balances[_icoAddress] = SALES_SUPPLY;
       emit Transfer(0x0, _icoAddress, SALES_SUPPLY);

       icoAddress = _icoAddress;
       totalSupply_ = TOTAL_SUPPLY;
       
    }

     
  function totalSupply() public view returns (uint256) {
      
      return totalSupply_;
      
    }
    
     
  function balanceOf(address _owner) public view returns (uint256 balance) {
      
      return balances[_owner];
      
    }
  

    
  function allowance(address _owner, address _spender) public view returns (uint256 remaining ) {
      
      return allowed[_owner][_spender];
      
    }
    
     
  function _transfer(address _from, address _to, uint256 _value) internal {
      
    require(_to != 0x0);                  
    require(balances[_from] >= _value);   
    require(balances[_to] + _value >= balances[_to]);              
     
      uint256 previousBalances = balances[_from] + balances[_to];    
      balances[_from] -= _value;    
      balances[_to] += _value;      
      emit Transfer(_from, _to, _value);
      
       
      assert(balances[_from] + balances[_to] == previousBalances);  
      
    }
    
   
     
  function transfer(address _to, uint256 _value) public returns (bool success) {
      
       require(balances[msg.sender] > 0);                     
       require(balances[msg.sender] >= _value);   
       require(_to != address(0x0));              
       
       require(_value > 0);	
       require(_to != msg.sender);                
       require(_value <= balances[msg.sender]);

        
       balances[msg.sender] = balances[msg.sender].sub(_value);  
       balances[_to] = balances[_to].add(_value);                
       emit Transfer(msg.sender, _to, _value);                   
       return true;
       
    }
    
     
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      
    require(_to != address(0x0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);   

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      return true;
      
   }

     
  function approve(address _spender, uint256 _value) public returns (bool success) {
      
      allowed[msg.sender][_spender] = _value;
      emit  Approval(msg.sender, _spender, _value);
      return true;
      
    }
    
   
  function getHoldersCount() public view returns (uint256) {
      
        return holders.length;
    }
    
   
  function preserveHolders(address _from, address _to, uint256 _value) internal {
      
        if (balances[_from].sub(_value) < MIN_HOLDER_TOKENS) 
            removeHolder(_from);
        if (balances[_to].add(_value) >= MIN_HOLDER_TOKENS) 
            addHolder(_to);   
    }

   
  function removeHolder(address _holder) internal {
      
        uint256 _number = holderNumber[_holder];

        if (_number == 0 || holders.length == 0 || _number > holders.length)
            return;

        uint256 _index = _number.sub(1);
        uint256 _lastIndex = holders.length.sub(1);
        address _lastHolder = holders[_lastIndex];

        if (_index != _lastIndex) {
            holders[_index] = _lastHolder;
            holderNumber[_lastHolder] = _number;
        }

        holderNumber[_holder] = 0;
        holders.length = _lastIndex;
    } 

   
  function addHolder(address _holder) internal {
      
        if (holderNumber[_holder] == 0) {
            holders.push(_holder);
            holderNumber[_holder] = holders.length;
            
        }
    }

     
 function _burn(address account, uint256 value) external onlyOwner {
     
      require(balances[msg.sender] >= value);    
      balances[msg.sender] -= value;             
      totalSupply_ -= value;                     
      emit Burn(msg.sender, value);
       
      
      require(account != address(0x0));

      totalSupply_ = totalSupply_.sub(value);
      balances[account] = balances[account].sub(value);
      emit Transfer(account, address(0X0), value);
     
    }
    
     
  function _burnFrom(address account, uint256 value) external onlyOwner {
      
      require(balances[account] >= value);                
      require(value <= allowed[account][msg.sender]);     
      balances[account] -= value;                         
      allowed[account][msg.sender] -= value;              
      totalSupply_ -= value;                              
      emit Burn(account, value);
       
      
      allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
      emit Burn(account, value);
      emit Approval(account, msg.sender, allowed[account][msg.sender]);
      
    }
    
  function validPurchase() internal returns (bool) {
      
      bool lessThanMaxInvestment = msg.value <= 1000 ether;  
      return validPurchase() && lessThanMaxInvestment;
      
    }
    
     
  function mintToken(address target, uint256 mintedAmount) public onlyOwner {
      
      balances[target] += mintedAmount;
      totalSupply_ += mintedAmount;
      
      emit Transfer(0, owner, mintedAmount);
      emit Transfer(owner, target, mintedAmount);
      
    }
    
     
  function airDrop_many(address[] _recipient, uint256[] _amount) public onlyOwner {
        
        require(msg.sender == owner);
        require(_recipient.length == _amount.length);
        uint256 amount = _amount[i] * uint256(decimalFactor);
        uint256 airdropped;
    
        for (uint i=0; i < _recipient.length; i++) {
           if (!airdrops[_recipient[i]]) {
                airdrops[_recipient[i]] = true;
                require(Ubricoin.transfer(_recipient[i], _amount[i] * decimalFactor));
                 
                airdropped = airdropped.add(amount );
            } else{
                
                 emit FailedTransfer(_recipient[i], airdropped); 
        }
        
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
     
    claimedTokens = claimedTokens.add(airdropped);
    emit AirDrop_many(_recipient, _amount, claimedTokens);
    
        }
    }
    
    
  function airDrop(address[] _recipient, uint256 _amount) public onlyOwner {
      
        require(_amount > 0);
        uint256 airdropped;
        uint256 amount = _amount * uint256(decimalFactor);
        for (uint256 index = 0; index < _recipient.length; index++) {
            if (!airdrops[_recipient[index]]) {
                airdrops[_recipient[index]] = true;
                require(Ubricoin.transfer(_recipient[index], amount * decimalFactor ));
                airdropped = airdropped.add(amount );
            }else{
            
            emit FailedTransfer(_recipient[index], airdropped); 
        }
    }
        
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
     
    claimedTokens = claimedTokens.add(airdropped);
    emit AirDropped(_recipient, _amount, claimedTokens);
    
    }
    

}