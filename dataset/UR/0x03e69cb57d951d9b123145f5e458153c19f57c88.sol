 

pragma solidity ^0.4.22;

 
contract TokenContract{
  function mint(address _to, uint256 _amount) public;
  function finishMinting () public;
  function setupMultisig (address _address) public;
}

 
contract GangMultisig {
  
   
  TokenContract public token;

   
   
  uint public lifeTime = 86400;  
  
   
  constructor (address _token, uint _needApprovesToConfirm, address[] _owners) public{
    require (_needApprovesToConfirm > 1 && _needApprovesToConfirm <= _owners.length);
    
     
    token = TokenContract(_token);

    addInitialOwners(_owners);

    needApprovesToConfirm = _needApprovesToConfirm;

     
    token.setupMultisig(address(this));
    
    ownersCount = _owners.length;
  }

   
  function addInitialOwners (address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++){
       
      require(!owners[_owners[i]]);
      owners[_owners[i]] = true;
    }
  }

   
  bool public mintingFinished = false;

   
  mapping (address => bool) public owners;

   
  mapping (address => uint32) public lastOwnersAction;
  
  modifier canCreate() { 
    require (lastOwnersAction[msg.sender] + lifeTime < now);
    lastOwnersAction[msg.sender] = uint32(now);
    _; 
  }
  

   
  modifier onlyOwners() { 
    require (owners[msg.sender]); 
    _; 
  }

   
  uint public ownersCount;

   
  uint public needApprovesToConfirm;

   
  struct SetNewMint {
    address spender;
    uint value;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

   
  SetNewMint public setNewMint;

  event NewMintRequestSetup(address indexed initiator, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewMintRequestCanceled();  

   
  function setNewMintRequest (address _spender, uint _value) public onlyOwners canCreate {
    require (setNewMint.creationTimestamp + lifeTime < uint32(now) || setNewMint.isExecute || setNewMint.isCanceled);

    require (!mintingFinished);

    address[] memory addr;

    setNewMint = SetNewMint(_spender, _value, 1, false, msg.sender, false, uint32(now), addr);
    setNewMint.confirmators.push(msg.sender);

    emit NewMintRequestSetup(msg.sender, _spender, _value);
  }

   
  function approveNewMintRequest () public onlyOwners {
    require (!setNewMint.isExecute && !setNewMint.isCanceled);
    require (setNewMint.creationTimestamp + lifeTime >= uint32(now));

    require (!mintingFinished);

    for (uint i = 0; i < setNewMint.confirmators.length; i++){
      require(setNewMint.confirmators[i] != msg.sender);
    }
      
    setNewMint.confirms++;
    setNewMint.confirmators.push(msg.sender);

    if(setNewMint.confirms >= needApprovesToConfirm){
      setNewMint.isExecute = true;

      token.mint(setNewMint.spender, setNewMint.value); 
    }
    emit NewMintRequestUpdate(msg.sender, setNewMint.confirms, setNewMint.isExecute);
  }

   
  function cancelMintRequest () public {
    require (msg.sender == setNewMint.initiator);    
    require (!setNewMint.isCanceled && !setNewMint.isExecute);

    setNewMint.isCanceled = true;
    emit NewMintRequestCanceled();
  }
   

   
  struct FinishMintingStruct {
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

   
  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestSetup(address indexed initiator);
  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event FinishMintingRequestCanceled();
  event FinishMintingApproveCanceled(address owner);

   
  function finishMintingRequestSetup () public onlyOwners canCreate{
    require ((finishMintingStruct.creationTimestamp + lifeTime < uint32(now) || finishMintingStruct.isCanceled) && !finishMintingStruct.isExecute);
    
    require (!mintingFinished);

    address[] memory addr;

    finishMintingStruct = FinishMintingStruct(1, false, msg.sender, false, uint32(now), addr);
    finishMintingStruct.confirmators.push(msg.sender);

    emit FinishMintingRequestSetup(msg.sender);
  }

   
  function ApproveFinishMintingRequest () public onlyOwners {
    require (!finishMintingStruct.isCanceled && !finishMintingStruct.isExecute);
    require (finishMintingStruct.creationTimestamp + lifeTime >= uint32(now));

    require (!mintingFinished);

    for (uint i = 0; i < finishMintingStruct.confirmators.length; i++){
      require(finishMintingStruct.confirmators[i] != msg.sender);
    }

    finishMintingStruct.confirmators.push(msg.sender);

    finishMintingStruct.confirms++;

    if(finishMintingStruct.confirms >= needApprovesToConfirm){
      token.finishMinting();
      finishMintingStruct.isExecute = true;
      mintingFinished = true;
    }
    
    emit FinishMintingRequestUpdate(msg.sender, finishMintingStruct.confirms, finishMintingStruct.isExecute);
  }
  
   
  function cancelFinishMintingRequest () public {
    require (msg.sender == finishMintingStruct.initiator);
    require (!finishMintingStruct.isCanceled);

    finishMintingStruct.isCanceled = true;
    emit FinishMintingRequestCanceled();
  }
   

   
  struct SetNewApproves {
    uint count;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

   
  SetNewApproves public setNewApproves;

  event NewNeedApprovesToConfirmRequestSetup(address indexed initiator, uint count);
  event NewNeedApprovesToConfirmRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewNeedApprovesToConfirmRequestCanceled();

   
  function setNewOwnersCountToApprove (uint _count) public onlyOwners canCreate {
    require (setNewApproves.creationTimestamp + lifeTime < uint32(now) || setNewApproves.isExecute || setNewApproves.isCanceled);

    require (_count > 1);

    address[] memory addr;

    setNewApproves = SetNewApproves(_count, 1, false, msg.sender,false, uint32(now), addr);
    setNewApproves.confirmators.push(msg.sender);

    emit NewNeedApprovesToConfirmRequestSetup(msg.sender, _count);
  }

   
  function approveNewOwnersCount () public onlyOwners {
    require (setNewApproves.count <= ownersCount);
    require (setNewApproves.creationTimestamp + lifeTime >= uint32(now));
    
    for (uint i = 0; i < setNewApproves.confirmators.length; i++){
      require(setNewApproves.confirmators[i] != msg.sender);
    }
    
    require (!setNewApproves.isExecute && !setNewApproves.isCanceled);
    
    setNewApproves.confirms++;
    setNewApproves.confirmators.push(msg.sender);

    if(setNewApproves.confirms >= needApprovesToConfirm){
      setNewApproves.isExecute = true;

      needApprovesToConfirm = setNewApproves.count;   
    }
    emit NewNeedApprovesToConfirmRequestUpdate(msg.sender, setNewApproves.confirms, setNewApproves.isExecute);
  }

   
  function cancelNewOwnersCountRequest () public {
    require (msg.sender == setNewApproves.initiator);    
    require (!setNewApproves.isCanceled && !setNewApproves.isExecute);

    setNewApproves.isCanceled = true;
    emit NewNeedApprovesToConfirmRequestCanceled();
  }
  
   

   
  struct NewOwner {
    address newOwner;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  NewOwner public addOwner;
   

  event AddOwnerRequestSetup(address indexed initiator, address newOwner);
  event AddOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event AddOwnerRequestCanceled();

   
  function setAddOwnerRequest (address _newOwner) public onlyOwners canCreate {
    require (addOwner.creationTimestamp + lifeTime < uint32(now) || addOwner.isExecute || addOwner.isCanceled);
    
    address[] memory addr;

    addOwner = NewOwner(_newOwner, 1, false, msg.sender, false, uint32(now), addr);
    addOwner.confirmators.push(msg.sender);

    emit AddOwnerRequestSetup(msg.sender, _newOwner);
  }

   
  function approveAddOwnerRequest () public onlyOwners {
    require (!addOwner.isExecute && !addOwner.isCanceled);
    require (addOwner.creationTimestamp + lifeTime >= uint32(now));

     
    require (!owners[addOwner.newOwner]);

    for (uint i = 0; i < addOwner.confirmators.length; i++){
      require(addOwner.confirmators[i] != msg.sender);
    }
    
    addOwner.confirms++;
    addOwner.confirmators.push(msg.sender);

    if(addOwner.confirms >= needApprovesToConfirm){
      addOwner.isExecute = true;

      owners[addOwner.newOwner] = true;
      ownersCount++;
    }

    emit AddOwnerRequestUpdate(msg.sender, addOwner.confirms, addOwner.isExecute);
  }

   
  function cancelAddOwnerRequest() public {
    require (msg.sender == addOwner.initiator);
    require (!addOwner.isCanceled && !addOwner.isExecute);

    addOwner.isCanceled = true;
    emit AddOwnerRequestCanceled();
  }
   

   
  NewOwner public removeOwners;
   

  event RemoveOwnerRequestSetup(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled();

   
  function removeOwnerRequest (address _removeOwner) public onlyOwners canCreate {
    require (removeOwners.creationTimestamp + lifeTime < uint32(now) || removeOwners.isExecute || removeOwners.isCanceled);

    address[] memory addr;
    
    removeOwners = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup(msg.sender, _removeOwner);
  }

   
  function approveRemoveOwnerRequest () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);

    require (owners[removeOwners.newOwner]);
    
    require (!removeOwners.isExecute && !removeOwners.isCanceled);
    require (removeOwners.creationTimestamp + lifeTime >= uint32(now));

    for (uint i = 0; i < removeOwners.confirmators.length; i++){
      require(removeOwners.confirmators[i] != msg.sender);
    }
    
    removeOwners.confirms++;
    removeOwners.confirmators.push(msg.sender);

    if(removeOwners.confirms >= needApprovesToConfirm){
      removeOwners.isExecute = true;

      owners[removeOwners.newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners.newOwner);
    }

    emit RemoveOwnerRequestUpdate(msg.sender, removeOwners.confirms, removeOwners.isExecute);
  }

  
   
  function cancelRemoveOwnerRequest () public {
    require (msg.sender == removeOwners.initiator);    
    require (!removeOwners.isCanceled && !removeOwners.isExecute);

    removeOwners.isCanceled = true;
    emit RemoveOwnerRequestCanceled();
  }
   

   
  NewOwner public removeOwners2;
   

  event RemoveOwnerRequestSetup2(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate2(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled2();

   
  function removeOwnerRequest2 (address _removeOwner) public onlyOwners canCreate {
    require (removeOwners2.creationTimestamp + lifeTime < uint32(now) || removeOwners2.isExecute || removeOwners2.isCanceled);

    address[] memory addr;
    
    removeOwners2 = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners2.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup2(msg.sender, _removeOwner);
  }

   
  function approveRemoveOwnerRequest2 () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);

    require (owners[removeOwners2.newOwner]);
    
    require (!removeOwners2.isExecute && !removeOwners2.isCanceled);
    require (removeOwners2.creationTimestamp + lifeTime >= uint32(now));

    for (uint i = 0; i < removeOwners2.confirmators.length; i++){
      require(removeOwners2.confirmators[i] != msg.sender);
    }
    
    removeOwners2.confirms++;
    removeOwners2.confirmators.push(msg.sender);

    if(removeOwners2.confirms >= needApprovesToConfirm){
      removeOwners2.isExecute = true;

      owners[removeOwners2.newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners2.newOwner);
    }

    emit RemoveOwnerRequestUpdate2(msg.sender, removeOwners2.confirms, removeOwners2.isExecute);
  }

   
  function cancelRemoveOwnerRequest2 () public {
    require (msg.sender == removeOwners2.initiator);    
    require (!removeOwners2.isCanceled && !removeOwners2.isExecute);

    removeOwners2.isCanceled = true;
    emit RemoveOwnerRequestCanceled2();
  }
   

   
  function _removeOwnersAproves(address _oldOwner) internal{
     
     
    if (setNewMint.initiator != address(0)){
       
      if (setNewMint.creationTimestamp + lifeTime >= uint32(now) && !setNewMint.isExecute && !setNewMint.isCanceled){
        if(setNewMint.initiator == _oldOwner){
          setNewMint.isCanceled = true;
          emit NewMintRequestCanceled();
        }else{
           
          for (uint i = 0; i < setNewMint.confirmators.length; i++){
            if (setNewMint.confirmators[i] == _oldOwner){
               
              setNewMint.confirmators[i] = address(0);
              setNewMint.confirms--;

               
              break;
            }
          }
        }
      }
    }

     
    if (finishMintingStruct.initiator != address(0)){
       
      if (finishMintingStruct.creationTimestamp + lifeTime >= uint32(now) && !finishMintingStruct.isExecute && !finishMintingStruct.isCanceled){
        if(finishMintingStruct.initiator == _oldOwner){
          finishMintingStruct.isCanceled = true;
          emit NewMintRequestCanceled();
        }else{
           
          for (i = 0; i < finishMintingStruct.confirmators.length; i++){
            if (finishMintingStruct.confirmators[i] == _oldOwner){
               
              finishMintingStruct.confirmators[i] = address(0);
              finishMintingStruct.confirms--;

               
              break;
            }
          }
        }     
      }
    }

     
    if (setNewApproves.initiator != address(0)){
       
      if (setNewApproves.creationTimestamp + lifeTime >= uint32(now) && !setNewApproves.isExecute && !setNewApproves.isCanceled){
        if(setNewApproves.initiator == _oldOwner){
          setNewApproves.isCanceled = true;

          emit NewNeedApprovesToConfirmRequestCanceled();
        }else{
           
          for (i = 0; i < setNewApproves.confirmators.length; i++){
            if (setNewApproves.confirmators[i] == _oldOwner){
               
              setNewApproves.confirmators[i] = address(0);
              setNewApproves.confirms--;

               
              break;
            }
          }
        }
      }
    }

     
    if (addOwner.initiator != address(0)){
       
      if (addOwner.creationTimestamp + lifeTime >= uint32(now) && !addOwner.isExecute && !addOwner.isCanceled){
        if(addOwner.initiator == _oldOwner){
          addOwner.isCanceled = true;
          emit AddOwnerRequestCanceled();
        }else{
           
          for (i = 0; i < addOwner.confirmators.length; i++){
            if (addOwner.confirmators[i] == _oldOwner){
               
              addOwner.confirmators[i] = address(0);
              addOwner.confirms--;

               
              break;
            }
          }
        }
      }
    }

     
    if (removeOwners.initiator != address(0)){
       
      if (removeOwners.creationTimestamp + lifeTime >= uint32(now) && !removeOwners.isExecute && !removeOwners.isCanceled){
        if(removeOwners.initiator == _oldOwner){
          removeOwners.isCanceled = true;
          emit RemoveOwnerRequestCanceled();
        }else{
           
          for (i = 0; i < removeOwners.confirmators.length; i++){
            if (removeOwners.confirmators[i] == _oldOwner){
               
              removeOwners.confirmators[i] = address(0);
              removeOwners.confirms--;

               
              break;
            }
          }
        }
      }
    }
  }
}