 
contract DankFaucet is usingOraclize, DSAuth {
  using strings for *;

  DankToken public constant dankToken = DankToken(0x0cb8d0b37c7487b11d57f1f33defa2b1d3cfccfe);

   
  struct PhoneNumberRequest {
    address sender;
    bytes32 hashedPhoneNumber;
  }

   
  mapping(bytes32 => uint) public allocatedDank;

   
   
   
  mapping(bytes32 => PhoneNumberRequest) public phoneNumberRequests;

   
  uint public allotment;

   
   
  event NotEnoughETH(string description, uint ethRequired);

   
   
  event DankEvent(bytes32 hashedPhoneNumber, bool successful, string description);

   
  event OraclizeCall(bytes32 id, string msg);

   
  event DankReset(bytes32 hashedPhoneNumber);

   
  constructor(uint initialDank) public {
    allotment = initialDank;

     
     
     
  }

   
  function verifyAndAcquireDank(bytes32 hashedPhoneNumber, string encryptedPayload) public {
    if (oraclize_getPrice("URL") > address(this).balance) {
      emit NotEnoughETH("Oraclize query for phone number verification was NOT sent, add more ETH.", oraclize_getPrice("URL"));
    } else {
      bytes32 queryId = oraclize_query("nested", getOraclizeQuery(encryptedPayload));
      phoneNumberRequests[queryId] = PhoneNumberRequest(msg.sender, hashedPhoneNumber);
    }
  }

   
  function __callback(bytes32 queryId, string result) public {
    emit OraclizeCall(queryId, result);

    if (msg.sender != oraclize_cbAddress()) {
        revert("The sender's address does not match Oraclize's address.");
    }
    else {
      if (!result.toSlice().contains("\"success\":true".toSlice())) {
        revert("Wrong verification code");
      }
      else {
        PhoneNumberRequest storage phoneNumberRequest = phoneNumberRequests[queryId];
        uint previouslyAllocatedDank = allocatedDank[phoneNumberRequest.hashedPhoneNumber];

        if ((previouslyAllocatedDank <= 0) && (dankToken.balanceOf(address(this)) >= allotment)) {
          bool dankTransfered = dankToken.transfer(phoneNumberRequest.sender, allotment);
          if (dankTransfered) {
            allocatedDank[phoneNumberRequest.hashedPhoneNumber] = allotment;
            emit DankEvent(phoneNumberRequest.hashedPhoneNumber, dankTransfered, "DANK transfered");
          }
        }
        else {
          emit DankEvent(phoneNumberRequest.hashedPhoneNumber, false, "DANK already allocated.");
        }
      }
    }
  }

  function getOraclizeQuery(string payload) constant returns(string) {
    var parts = new strings.slice[](3);
    parts[0] = "[computation] ['QmdKK319Veha83h6AYgQqhx9YRsJ9MJE7y33oCXyZ4MqHE', 'GET', 'https://api.authy.com/protected/json/phones/verification/check', '${[decrypt] ".toSlice();
    parts[1] = payload.toSlice();
    parts[2] = "}']".toSlice();
    return "".toSlice().join(parts);
  }

   
  function getBalance() public view returns (uint256) {
      return address(this).balance;
  }

   
  function sendEth() public payable { }

   
  function resetAllocatedDankForPhoneNumber(bytes32 hashedPhoneNumber) auth {
    delete allocatedDank[hashedPhoneNumber];
    emit DankReset(hashedPhoneNumber);
  }

   
  function resetAllotment(uint initialDank) auth {
    allotment = initialDank;
  }

   
  function withdrawDank() auth {
    dankToken.transfer(msg.sender, dankToken.balanceOf(this));
  }

   
  function withdrawEth() auth {
    msg.sender.transfer(address(this).balance);
  }
}
