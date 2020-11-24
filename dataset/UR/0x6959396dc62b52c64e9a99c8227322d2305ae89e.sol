 

pragma solidity ^0.4.23;

 

 
    contract Ownable {
      address public owner;
    
      event OwnershipRenounced(address indexed previousOwner);
      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
       
       
      constructor() public {
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
    
       
      function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
      }
    }

 

contract CeoOwner is Ownable{

	 
	 
	address public ceoAddress; 

	modifier onlyCEO() {
		require(msg.sender == ceoAddress);
		_;
	}

}

 

 
 contract ReentrancyGuard {

   
   bool private reentrancyLock = false;

   
   modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 

 
     library SafeMath {
      
       
      function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
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
      
       
      function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
      }
    }

 

contract CertificateCore is CeoOwner, ReentrancyGuard { 
   
    using SafeMath for uint256; 

    uint256 public constant KEY_CREATION_LIMIT = 10000;
    uint256 public totalSupplyOfKeys;
    uint256 public totalReclaimedKeys;
    
     
    mapping(address => uint256) public balanceOf; 

     
    mapping(address => bool) public allThePublicKeys;
    
     
    event DepositBonusEvent(address sender, uint256 amount); 
    
     
    event DepositCertificateSaleEvent(address sender, address publicKey, uint256 amount);

     
    event CertPayedOutEvent(address sender, address recpublicKey, uint256 payoutValue);
    

    constructor(address _ceoAddress) public{
        require(_ceoAddress != address(0));
        owner = msg.sender;
        ceoAddress = _ceoAddress;
    }
 
    
     
     
    function depositCertificateSale(address _publicKey, uint256 _amount) external payable onlyCEO{
        require(msg.sender != address(0));
        require(_amount > 0);
        require(msg.value == _amount);
        require(_publicKey != address(0));
        require(totalSupplyOfKeys < KEY_CREATION_LIMIT);
        require(totalReclaimedKeys < KEY_CREATION_LIMIT);
 
        require(!allThePublicKeys[_publicKey]);

        allThePublicKeys[_publicKey]=true;
        totalSupplyOfKeys ++;

        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
        
        emit DepositCertificateSaleEvent(msg.sender, _publicKey, _amount);
    }
    
     
     
    function depositBonus(uint256 _amount) external payable onlyCEO {
        require(_amount > 0);
        require(msg.value == _amount);
      
        require((totalSupplyOfKeys > 0) && (totalSupplyOfKeys < KEY_CREATION_LIMIT));
        require(totalReclaimedKeys < KEY_CREATION_LIMIT);
      
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
        
        emit DepositBonusEvent(msg.sender, _amount);
    }
    
     
    function payoutACert(bytes32 _msgHash, uint8 _v, bytes32 _r, bytes32 _s) external nonReentrant{
        require(msg.sender != address(0));
        require(address(this).balance > 0);
        require(totalSupplyOfKeys > 0);
        require(totalReclaimedKeys < KEY_CREATION_LIMIT);
         
        address _recoveredAddress = ecrecover(_msgHash, _v, _r, _s);
        require(allThePublicKeys[_recoveredAddress]);
    
        allThePublicKeys[_recoveredAddress]=false;

        uint256 _validKeys = totalSupplyOfKeys.sub(totalReclaimedKeys);
        uint256 _payoutValue = address(this).balance.div(_validKeys);

        msg.sender.transfer(_payoutValue);
        emit CertPayedOutEvent(msg.sender, _recoveredAddress, _payoutValue);
        
        totalReclaimedKeys ++;
    }
 
      
      
      
      
    function calculatePayout() view external returns(
        uint256 _etherValue
        ){
        uint256 _validKeys = totalSupplyOfKeys.sub(totalReclaimedKeys);
         
        if(_validKeys == 0){
            _etherValue = 0;
        }else{
            _etherValue = address(this).balance.div(_validKeys);
        }
    }
 
 
     
    function checkIfValidKey(address _publicKey) view external{  
        require(_publicKey != address(0));
        require(allThePublicKeys[_publicKey]);
    }

    function getBalance() view external returns(
         uint256 contractBalance
    ){
        contractBalance = address(this).balance;
    }
    
     
    function kill() external onlyOwner 
    { 
        selfdestruct(owner); 
    }
 
     
     
     
     
    
}

 

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

   
  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}