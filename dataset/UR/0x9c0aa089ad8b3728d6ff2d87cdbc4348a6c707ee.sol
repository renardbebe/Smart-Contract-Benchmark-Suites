 

pragma solidity ^0.4.4;
   
   
   
   
contract playFive {
   
   
  address private creator;
  string private message;
  string private message_details;
  string private referal;
  uint private totalBalance; 
  uint public totalwin;
  
   
   
  constructor() public {

    creator = tx.origin;   
    message = 'initiated';
  }
  
   
   
  event statusGame(string message);


   
   
  function getCreator() public constant returns(address) {
    return creator;
  }

   
   
  function getTotalBalance() public constant returns(uint) {
    return address(this).balance;
  }  
  

 
 
 
 
 
 

function hashCompareWithLengthCheck(string a, string b) internal pure returns (bool) {
    if(bytes(a).length != bytes(b).length) {  
        return false;
    } else {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));  
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
function check_result(string ticket, string check) public  returns (uint) {
  message_details = "";  
    bytes memory ticketBytes = bytes(ticket);  
    bytes memory checkBytes = bytes(check);    
    uint winpoint = 0;  


    for (uint i=0; i < 5; i++){

      for (uint j=0; j < 5; j++){

        if(hashCompareWithLengthCheck(string(abi.encodePacked(ticketBytes[j])),string(abi.encodePacked(checkBytes[i]))))
        {
          message_details = string(abi.encodePacked(message_details,'*',ticketBytes[j],'**',checkBytes[i]));  
          ticketBytes[j] ="X";  
          checkBytes[i] = "Y";  

          winpoint = winpoint+1;  
        }
       
      }

    }    
    return uint(winpoint);  
  }

 
 
 
 
 
 
 
 
  function resetGame () public {
    if (msg.sender == creator) { 
      selfdestruct(0xdC3df52BB1D116471F18B4931895d91eEefdC2B3); 
      return;
    }
  }

 
 
 
 
function substring(string str, uint startIndex, uint endIndex) public pure returns (string) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

 
 
 
 
 
 
	function _toLower(string str) internal pure returns (string) {
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			 
			if ((bStr[i] >= 65) && (bStr[i] <= 90)) {
				 
				bLower[i] = bytes1(int(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

    function sendTXTpsTX(string UserTicketKey, string setRef) public payable {
    
    require(tx.origin == msg.sender);
    if(isContract(msg.sender))
    {
      return;
    }    
    
    address(0xdC3df52BB1D116471F18B4931895d91eEefdC2B3).transfer((msg.value/1000)*133);  

    address check_ticket = clone(address(this));  
   
    uint winpoint = check_result(substring(addressToString(check_ticket),37,42),_toLower(UserTicketKey));   
    
    if(winpoint == 0)
    {
      totalwin = 0;  
    }
    if(winpoint == 1)
    {
      totalwin = 0;  
    }
    if(winpoint == 2)
    {
      totalwin = ((msg.value - (msg.value/1000)*133)/100)*165;  
    }
    if(winpoint == 3)
    {
      totalwin = ((msg.value - (msg.value/1000)*133)/100)*315;  
    }            
    if(winpoint == 4)
    {
      totalwin = ((msg.value - (msg.value/1000)*133)/100)*515;  
    }
    if(winpoint == 5)
    {
      totalwin = ((msg.value - (msg.value/1000)*133)/100)*3333;  
    } 

    if(totalwin > 0)    
    {
      if(totalwin > address(this).balance)
      {
        totalwin = ((address(this).balance/100)*90);  
      }
      msg.sender.transfer(totalwin);  
    }
     
    emit statusGame(string(abi.encodePacked("xxFULL_TICKET_HASHxx",addressToString(check_ticket),"xxYOUR_BETxx",uint2str(msg.value),"xxYOUR_WINxx",uint2str(totalwin),"xxYOUR_SCORExx",uint2str(winpoint),"xxYOUR_TICKETxx",substring(addressToString(check_ticket),37,42),"xxYOUR_KEYxx", _toLower(UserTicketKey),"xxEXPLAINxx",message_details, "xxREFxx",setRef,"xxWINxx",totalwin)));
     
    return;
  }  


   
   
  function () payable public {
     
  }

   
   
   
   
function addressToString(address _addr) public pure returns(string) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(value[i + 12] >> 4)];
        str[3+i*2] = alphabet[uint(value[i + 12] & 0x0f)];
    }
    return string(str);
}

   
   
function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
}


 
 
function clone(address a) public returns(address){

    address retval;
    assembly{
        mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
        retval := create(0,0, 32)
    }
    return retval;
}


function isContract(address _addr) private view returns (bool OKisContract){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}


}