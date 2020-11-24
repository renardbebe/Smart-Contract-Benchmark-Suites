 

 

pragma solidity 0.4.19;


library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }

}

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

 

contract MultiSig is ReentrancyGuard{
  
  using SafeMath for uint256;
  
   
  struct Transaction{
    address[3] signer;
    uint confirmations;
    uint256 eth;
  }
  
   
  Transaction private  pending;
    
   
  uint256 constant public required = 3;

  mapping(address => bool) private administrators;
 
   
  event Deposit(address _from, uint256 value);
  
   
  event Transfer(address indexed fristSigner, address indexed secondSigner, address indexed thirdSigner, address to,uint256 eth,bool success);
  
   
  event TransferConfirmed(address signer,uint256 amount,uint256 remainingConfirmations);
  
   
  event UpdateConfirmed(address indexed signer,address indexed newAddress,uint256 remainingConfirmations);
  
  
   
  event Violated(string action, address sender); 
  
   
  event KeyReplaced(address oldKey,address newKey);

  event EventTransferWasReset();
  event EventUpdateWasReset();
  
  
  function MultiSig() public {

    administrators[0x8E0c5A1b55d4E71B7891010EF504b11f19F4c466] = true;
    administrators[0x5e77156CD35574A1dAC125992B73b3C5a973a4eb] = true;
    administrators[0x604EdF8FE01db0AdafED4701F5De42b15067d23c] = true;
    administrators[0xed4C73Ad76D90715d648797Acd29A8529ED511A0] = true;

  }
  
   
  function transfer(address recipient, uint256 amount) external onlyAdmin nonReentrant {
    
     
    require( recipient != 0x00 );
    require( amount > 0 );
    require( this.balance >= amount);

    uint remaining;
    
     
    if(pending.confirmations == 0){
        
        pending.signer[pending.confirmations] = msg.sender;
        pending.eth = amount;
        pending.confirmations = pending.confirmations.add(1);
        remaining = required.sub(pending.confirmations);
        TransferConfirmed(msg.sender,amount,remaining);
        return;
    
    }
    
     
    if(pending.eth != amount){
        transferViolated("Incorrect amount of wei passed");
        return;
    }
    
     
    if(msg.sender == pending.signer[0]){
        transferViolated("Signer is spamming");
        return;
    }
    
    pending.signer[pending.confirmations] = msg.sender;
    pending.confirmations = pending.confirmations.add(1);
    remaining = required.sub(pending.confirmations);
    
     
    if( remaining == 0){
        if(msg.sender == pending.signer[1]){
            transferViolated("One of signers is spamming");
            return;
        }
    }
    
    TransferConfirmed(msg.sender,amount,remaining);
    
     
    if (pending.confirmations == 3){
        if(recipient.send(amount)){
            Transfer(pending.signer[0],pending.signer[1], pending.signer[2], recipient,amount,true);
        }else{
            Transfer(pending.signer[0],pending.signer[1], pending.signer[2], recipient,amount,false);
        }
        ResetTransferState();
    } 
  }
  
  function transferViolated(string error) private {
    Violated(error, msg.sender);
    ResetTransferState();
  }
  
  function ResetTransferState() internal
  {
      delete pending;
      EventTransferWasReset();
  }


   
  function abortTransaction() external onlyAdmin{
       ResetTransferState();
  }
  
   
  function() payable public {
     
    if (msg.value > 0)
      Deposit(msg.sender, msg.value);
  }

   
  function isAdministrator(address _addr) public constant returns (bool) {
    return administrators[_addr];
  }
  
   
  struct KeyUpdate{
    address[3] signer;
    uint confirmations;
    address oldAddress;
    address newAddress;
  }
  
  KeyUpdate private updating;
  
   
  function updateAdministratorKey(address _oldAddress, address _newAddress) external onlyAdmin {
    
     
    require(isAdministrator(_oldAddress));
    require( _newAddress != 0x00 );
    require(!isAdministrator(_newAddress));
    require( msg.sender != _oldAddress );
    
     
    uint256 remaining;
    
     
     
    if( updating.confirmations == 0){
        
        updating.signer[updating.confirmations] = msg.sender;
        updating.oldAddress = _oldAddress;
        updating.newAddress = _newAddress;
        updating.confirmations = updating.confirmations.add(1);
        remaining = required.sub(updating.confirmations);
        UpdateConfirmed(msg.sender,_newAddress,remaining);
        return;
        
    }
    
     
    if(updating.oldAddress != _oldAddress){
        Violated("Old addresses do not match",msg.sender);
        ResetUpdateState();
        return;
    }
    
    if(updating.newAddress != _newAddress){
        Violated("New addresses do not match",msg.sender);
        ResetUpdateState();
        return; 
    }
    
     
    if(msg.sender == updating.signer[0]){
        Violated("Signer is spamming",msg.sender);
        ResetUpdateState();
        return;
    }
        
    updating.signer[updating.confirmations] = msg.sender;
    updating.confirmations = updating.confirmations.add(1);
    remaining = required.sub(updating.confirmations);

    if( remaining == 0){
        if(msg.sender == updating.signer[1]){
            Violated("One of signers is spamming",msg.sender);
            ResetUpdateState();
            return;
        }
    }

    UpdateConfirmed(msg.sender,_newAddress,remaining);
    
     
    if( updating.confirmations == 3 ){
        KeyReplaced(_oldAddress, _newAddress);
        ResetUpdateState();
        delete administrators[_oldAddress];
        administrators[_newAddress] = true;
        return;
    }
  }
  
  function ResetUpdateState() internal
  {
      delete updating;
      EventUpdateWasReset();
  }

   
  function abortUpdate() external onlyAdmin{
      ResetUpdateState();
  }
  
   
  modifier onlyAdmin(){
      if( !administrators[msg.sender] ){
          revert();
      }
      _;
  }
}