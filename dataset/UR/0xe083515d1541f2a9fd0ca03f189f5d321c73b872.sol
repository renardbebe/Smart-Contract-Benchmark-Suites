 

pragma solidity ^0.4.19;

contract Fizzy {
   
  struct Insurance {           
    bytes32 productId;            
    uint limitArrivalTime;     
    uint32 premium;            
    uint32 indemnity;          
    uint8 status;              
  }

  event InsuranceCreation(     
    bytes32 flightId,          
    uint32 premium,            
    uint32 indemnity,          
    bytes32 productId             
  );

   
  event InsuranceUpdate(       
    bytes32 productId,            
    bytes32 flightId,          
    uint32 premium,            
    uint32 indemnity,          
    uint8 status               
  );

  address creator;             

   
   
   
  mapping (bytes32 => Insurance[]) insuranceList;


   
   
   

   
  modifier onlyIfCreator {
    if (msg.sender == creator) _;
  }

   
  function Fizzy() public {
    creator = msg.sender;
  }


   
   
   

  function areStringsEqual (bytes32 a, bytes32 b) private pure returns (bool) {
     
    return keccak256(a) == keccak256(b);
  }


   
   
   

   
  function addNewInsurance(
    bytes32 flightId,
    uint limitArrivalTime,
    uint32 premium,
    uint32 indemnity,
    bytes32 productId)
  public
  onlyIfCreator {

    Insurance memory insuranceToAdd;
    insuranceToAdd.limitArrivalTime = limitArrivalTime;
    insuranceToAdd.premium = premium;
    insuranceToAdd.indemnity = indemnity;
    insuranceToAdd.productId = productId;
    insuranceToAdd.status = 0;

    insuranceList[flightId].push(insuranceToAdd);

     
    InsuranceCreation(flightId, premium, indemnity, productId);
  }

   
  function updateFlightStatus(
    bytes32 flightId,
    uint actualArrivalTime)
  public
  onlyIfCreator {

    uint8 newStatus = 1;

     
    for (uint i = 0; i < insuranceList[flightId].length; i++) {

       
      if (insuranceList[flightId][i].status == 0) {

        newStatus = 1;

         
         
        if (actualArrivalTime > insuranceList[flightId][i].limitArrivalTime) {
          newStatus = 2;
        }

         
        insuranceList[flightId][i].status = newStatus;

         
        InsuranceUpdate(
          insuranceList[flightId][i].productId,
          flightId,
          insuranceList[flightId][i].premium,
          insuranceList[flightId][i].indemnity,
          newStatus
        );
      }
    }
  }

   
  function manualInsuranceResolution(
    bytes32 flightId,
    uint8 newStatusId,
    bytes32 productId)
  public
  onlyIfCreator {

     
    for (uint i = 0; i < insuranceList[flightId].length; i++) {

       
      if (areStringsEqual(insuranceList[flightId][i].productId, productId)) {

         
        if (insuranceList[flightId][i].status == 0) {

           
          insuranceList[flightId][i].status = newStatusId;

           
          InsuranceUpdate(
            productId,
            flightId,
            insuranceList[flightId][i].premium,
            insuranceList[flightId][i].indemnity,
            newStatusId
          );

          return;
        }
      }
    }
  }

  function getInsurancesCount(bytes32 flightId) public view onlyIfCreator returns (uint) {
    return insuranceList[flightId].length;
  }

  function getInsurance(bytes32 flightId, uint index) public view onlyIfCreator returns (bytes32, uint, uint32, uint32, uint8) {
    Insurance memory ins = insuranceList[flightId][index];
    return (ins.productId, ins.limitArrivalTime, ins.premium, ins.indemnity, ins.status);
  }

}